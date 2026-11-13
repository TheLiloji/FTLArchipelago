#include "Archipelago.h"
#include "SaveFile.h"

#ifndef AP_NO_SCHEMA
#define AP_NO_SCHEMA
#endif
#include "apclient.hpp"

#include <algorithm>
#include <atomic>
#include <thread>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <fstream>
#include <map>
#include <vector>
#ifdef _WIN32
#include <direct.h>
#include <windows.h>
#else
#include <sys/stat.h>
#include <unistd.h>
extern char** environ;
#endif

namespace ArchipelagoFTL
{

namespace
{
#ifdef _WIN32
const char kPreviousGame[] = "FTLAP_PREVIOUS_GAME";

// A game relaunched by the one before it starts here, while the DLL loads, before FTL opens anything. A game still
// there after 12 s is stuck closing (seen: a frozen menu for a minute): its profile is already switched, it is ended.
struct PreviousGameWait
{
    PreviousGameWait()
    {
        char id[32];
        const DWORD length = GetEnvironmentVariableA(kPreviousGame, id, sizeof(id));
        if (length == 0 || length >= sizeof(id)) return;
        SetEnvironmentVariableA(kPreviousGame, nullptr);
        HANDLE previous = OpenProcess(SYNCHRONIZE | PROCESS_TERMINATE, FALSE, std::strtoul(id, nullptr, 10));
        if (previous == nullptr) return;
        if (WaitForSingleObject(previous, 12000) == WAIT_TIMEOUT) {
            TerminateProcess(previous, 0);
            WaitForSingleObject(previous, 3000);
        }
        CloseHandle(previous);
        Sleep(1000);
    }
};
PreviousGameWait previousGameWait;
#endif

// The game this client plays: the Multiverse build of the mod sets its own before connecting.
std::string kGameName = "FTL: Faster Than Light";

// AP network protocol bitmask: 1 (items from other worlds) | 2 (our own items sent back to
// us) | 4 (starting inventory). 7 asks for all three, i.e. full remote item handling.
const int kItemsHandling = 7;

std::string playerAlias(const APClient& ap, int slot)
{
    for (const auto& player : ap.get_players()) {
        if (player.team == ap.get_team_number() && player.slot == slot) return player.alias;
    }
    return "";
}
}

struct Client::Impl
{
    std::unique_ptr<APClient> ap;
    std::string uri;
    std::string slot;
    std::string password;
    bool connected = false;
    // The CA bundle given to the connection, and whether its TLS failure was already looked into.
    std::string certStore;
    std::atomic<bool> tlsDiagnosed{false};
    bool wantGoal = false;
    bool resetDone = false;

    std::deque<Event> events;
    std::mutex mutex;

    void push(Event e)
    {
        std::lock_guard<std::mutex> lock(mutex);
        events.push_back(std::move(e));
    }
};

// `new Impl()` rather than std::make_unique: this compiles as C++11 against the Hyperspace
// toolchain's libstdc++ (GCC 4.8 ABI), which predates make_unique (C++14).
Client::Client() : _impl(new Impl()) {}
Client::~Client() = default;

namespace {

// True when the file holds at least one PEM certificate (an empty or missing bundle is skipped).
bool HasCertificates(const std::string& path)
{
    std::ifstream f(path.c_str());
    if (!f.good()) return false;
    std::string line;
    for (int i = 0; i < 4000 && std::getline(f, line); ++i) {
        if (line.find("BEGIN CERTIFICATE") != std::string::npos) return true;
    }
    return false;
}

// Where the CA bundle came from, for the log: "" when none was found.
std::string certSource;

std::string CertStore()
{
#ifdef _WIN32
    certSource = "the Windows certificate store";
    return std::string();
#else
    // The environment first, as OpenSSL tools do. SSL_CERT_DIR alone is a folder: an empty path lets
    // OpenSSL's default lookup read it.
    const char* envFile = std::getenv("SSL_CERT_FILE");
    if (envFile != nullptr && *envFile && HasCertificates(envFile)) {
        certSource = std::string(envFile) + " (SSL_CERT_FILE)";
        return std::string(envFile);
    }
    const char* envDir = std::getenv("SSL_CERT_DIR");
    if (envDir != nullptr && *envDir) {
        certSource = std::string(envDir) + " (SSL_CERT_DIR)";
        return std::string();
    }
    // Then the host's bundle as a Steam Linux Runtime container shows it, then the usual places of the
    // Debian/Ubuntu, Fedora/RHEL, openSUSE and Arch families.
    static const char* kPaths[] = {
        "/run/host/etc/ssl/certs/ca-certificates.crt",
        "/run/host/etc/pki/tls/certs/ca-bundle.crt",
        "/run/host/etc/ssl/ca-bundle.pem",
        "/run/host/etc/ssl/cert.pem",
        "/etc/ssl/certs/ca-certificates.crt",
        "/etc/pki/tls/certs/ca-bundle.crt",
        "/etc/ssl/ca-bundle.pem",
        "/etc/ssl/cert.pem",
    };
    for (size_t i = 0; i < sizeof(kPaths) / sizeof(kPaths[0]); ++i) {
        if (HasCertificates(kPaths[i])) {
            certSource = kPaths[i];
            return std::string(kPaths[i]);
        }
    }
    certSource = "none found, OpenSSL's default paths";
    return std::string();
#endif
}

// A TLS handshake failed: says why, with OpenSSL's own words, by trying the handshake once more on the side.
// The websocket library only reports "TLS handshake failed".
std::string TlsDiagnosis(const std::string& uri, const std::string& store)
{
    namespace wa = websocketpp::lib::asio;
    std::string rest = uri;
    size_t scheme = rest.find("://");
    if (scheme != std::string::npos) rest = rest.substr(scheme + 3);
    rest = rest.substr(0, rest.find('/'));
    size_t colon = rest.rfind(':');
    std::string host = colon == std::string::npos ? rest : rest.substr(0, colon);
    std::string port = colon == std::string::npos ? "38281" : rest.substr(colon + 1);
    if (host.empty()) return "no host in " + uri;
    try {
        wa::io_service io;
        wa::ssl::context ctx(wa::ssl::context::sslv23);
        wa::error_code ec;
        if (!store.empty()) ctx.load_verify_file(store, ec);
        if (store.empty() || ec) ctx.set_default_verify_paths(ec);
        ctx.set_verify_mode(wa::ssl::verify_peer, ec);
        // The certificate the check stopped at: after a failed handshake OpenSSL keeps no chain to read.
        std::string failedAt;
        ctx.set_verify_callback([&failedAt](bool preverified, wa::ssl::verify_context& vctx) {
            if (!preverified && failedAt.empty()) {
                X509* cert = X509_STORE_CTX_get_current_cert(vctx.native_handle());
                char subject[256] = {0};
                char issuer[256] = {0};
                if (cert) {
                    X509_NAME_oneline(X509_get_subject_name(cert), subject, sizeof(subject) - 1);
                    X509_NAME_oneline(X509_get_issuer_name(cert), issuer, sizeof(issuer) - 1);
                }
                failedAt = std::string(subject) + " issued by " + issuer;
            }
            return preverified;
        }, ec);
        wa::ip::tcp::resolver resolver(io);
        wa::ip::tcp::resolver::query query(host, port);
        wa::ip::tcp::resolver::iterator endpoints = resolver.resolve(query, ec);
        if (ec) return "resolve " + host + ": " + ec.message();
        wa::ssl::stream<wa::ip::tcp::socket> stream(io, ctx);
        SSL_set_tlsext_host_name(stream.native_handle(), host.c_str());
        wa::connect(stream.lowest_layer(), endpoints, ec);
        if (ec) return "connect " + host + ":" + port + ": " + ec.message();
        stream.handshake(wa::ssl::stream_base::client, ec);
        long verify = SSL_get_verify_result(stream.native_handle());
        std::string out = "handshake with " + host + ":" + port + ": " + (ec ? ec.message() : std::string("ok"));
        out += ", certificate check: ";
        out += X509_verify_cert_error_string(verify);
        if (!failedAt.empty()) out += ", failed at: " + failedAt;
        out += ", " + std::string(OpenSSL_version(OPENSSL_VERSION));
        stream.lowest_layer().close(ec);
        return out;
    } catch (const std::exception& error) {
        return std::string("diagnosis failed: ") + error.what();
    }
}

std::string StatePath()
{
#ifdef _WIN32
    const char* base = std::getenv("APPDATA");
    if (!base) return std::string();
    std::string dir = std::string(base) + "\\ftl-archipelago";
    _mkdir(dir.c_str());
    return dir + "\\last_connection.txt";
#else
    const char* base = std::getenv("HOME");
    if (!base) return std::string();
    std::string dir = std::string(base) + "/.config";
    mkdir(dir.c_str(), 0755);
    dir += "/ftl-archipelago";
    mkdir(dir.c_str(), 0755);
    return dir + "/last_connection.txt";
#endif
}

void RememberConnection(const std::string& uri, const std::string& slot)
{
    const std::string path = StatePath();
    if (path.empty()) return;
    std::ofstream f(path.c_str(), std::ios::trunc);
    if (!f.good()) return;
    f << uri << "\n" << slot << "\n";
}

void RecallConnection(std::string& uri, std::string& slot)
{
    uri.clear();
    slot.clear();
    const std::string path = StatePath();
    if (path.empty()) return;
    std::ifstream f(path.c_str());
    if (!f.good()) return;
    std::getline(f, uri);
    std::getline(f, slot);
}

std::string StateStorePath()
{
    const std::string base = StatePath();
    if (base.empty()) return std::string();
    const size_t pos = base.find_last_of("/\\");
    if (pos == std::string::npos) return std::string();
    return base.substr(0, pos + 1) + "state.txt";
}

std::map<std::string, std::string> ReadState()
{
    std::map<std::string, std::string> values;
    const std::string path = StateStorePath();
    if (path.empty()) return values;
    std::ifstream f(path.c_str());
    if (!f.good()) return values;
    std::string line;
    while (std::getline(f, line)) {
        if (!line.empty() && line[line.size() - 1] == '\r') line.erase(line.size() - 1);
        const size_t pos = line.find('=');
        if (pos == std::string::npos || pos == 0) continue;
        values[line.substr(0, pos)] = line.substr(pos + 1);
    }
    return values;
}

void WriteState(const std::map<std::string, std::string>& values)
{
    const std::string path = StateStorePath();
    if (path.empty()) return;
    const std::string tmpPath = path + ".tmp";
    {
        std::ofstream f(tmpPath.c_str(), std::ios::trunc);
        if (!f.good()) return;
        for (std::map<std::string, std::string>::const_iterator i = values.begin();
             i != values.end(); ++i) {
            f << i->first << "=" << i->second << "\n";
        }
        f.flush();
        if (!f.good()) return;
    }
    std::remove(path.c_str());
    std::rename(tmpPath.c_str(), path.c_str());
}

bool CopyFileContent(const std::string& source, const std::string& dest)
{
    std::ifstream inFile(source.c_str(), std::ios::binary);
    if (!inFile.good()) return true;  // no such profile file yet (first run): nothing to back up, not an error
    std::ofstream outFile(dest.c_str(), std::ios::binary | std::ios::trunc);
    if (!outFile.good()) return false;
    outFile << inFile.rdbuf();
    outFile.flush();
    return outFile.good();
}

std::string Timestamp()
{
    char buffer[32];
    std::time_t now = std::time(nullptr);
    std::tm* local = std::localtime(&now);
    if (local == nullptr || std::strftime(buffer, sizeof(buffer), "%Y%m%d-%H%M%S", local) == 0) {
        return "no-date";
    }
    return buffer;
}

}

namespace
{
const char* kProfileFiles[][2] = { { "_prof.sav", "prof.sav" }, { "_prof_backup.sav", "prof_backup.sav" },
                                   { "_continue.sav", "continue.sav" } };
const size_t kProfileFileCount = sizeof(kProfileFiles) / sizeof(kProfileFiles[0]);
bool gWipeNewProfile = false;

bool FileExists(const std::string& path)
{
    std::ifstream f(path.c_str(), std::ios::binary);
    return f.good();
}

void MakeDir(const std::string& path)
{
#ifdef _WIN32
    _mkdir(path.c_str());
#else
    mkdir(path.c_str(), 0755);
#endif
}

bool ValidProfileId(const std::string& id)
{
    if (id.empty() || id.size() > 64) return false;
    for (size_t i = 0; i < id.size(); ++i) {
        const char c = id[i];
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_')) {
            return false;
        }
    }
    return true;
}

std::string ProfilesFolder()
{
    return FileHelper::getUserFolder() + "ap_profiles";
}

std::string CurrentProfileId(const std::map<std::string, std::string>& values)
{
    std::map<std::string, std::string>::const_iterator found = values.find("profile");
    return found == values.end() || found->second.empty() ? std::string("main") : found->second;
}

std::vector<std::string> SplitIds(const std::string& list)
{
    std::vector<std::string> ids;
    std::string current;
    for (size_t i = 0; i <= list.size(); ++i) {
        if (i == list.size() || list[i] == ',') {
            if (!current.empty() && std::find(ids.begin(), ids.end(), current) == ids.end()) ids.push_back(current);
            current.clear();
        } else {
            current += list[i];
        }
    }
    return ids;
}

std::string JoinIds(const std::vector<std::string>& ids)
{
    std::string list;
    for (size_t i = 0; i < ids.size(); ++i) {
        if (i > 0) list += ",";
        list += ids[i];
    }
    return list;
}
}

std::string Client::ProfileId() const
{
    return CurrentProfileId(ReadState());
}

std::vector<std::string> Client::ProfileIds() const
{
    const std::map<std::string, std::string> values = ReadState();
    std::map<std::string, std::string>::const_iterator found = values.find("profiles");
    std::vector<std::string> ids = SplitIds(found == values.end() ? std::string() : found->second);
    const std::string current = CurrentProfileId(values);
    if (std::find(ids.begin(), ids.end(), current) == ids.end()) ids.insert(ids.begin(), current);
    return ids;
}

bool Client::SwitchProfile(const std::string& id)
{
    if (!ValidProfileId(id)) return false;
    std::map<std::string, std::string> values = ReadState();
    if (id == CurrentProfileId(values)) {
        values.erase("profile_pending");
    } else {
        values["profile_pending"] = id;
    }
    WriteState(values);
    return true;
}

std::string Client::PendingProfile() const
{
    const std::map<std::string, std::string> values = ReadState();
    std::map<std::string, std::string>::const_iterator found = values.find("profile_pending");
    return found == values.end() ? std::string() : found->second;
}

bool Client::ArchiveProfile(const std::string& id)
{
    if (!ValidProfileId(id)) return false;
    std::map<std::string, std::string> values = ReadState();
    if (id == CurrentProfileId(values) || values["profile_pending"] == id) return false;
    const std::string folder = ProfilesFolder();
    MakeDir(folder);
    MakeDir(folder + "/archived");
    const std::string from = folder + "/" + id;
    const std::string to = folder + "/archived/" + id + "-" + Timestamp();
    if (FileExists(from + "/prof.sav") && std::rename(from.c_str(), to.c_str()) != 0) return false;
    std::vector<std::string> ids = SplitIds(values["profiles"]);
    ids.erase(std::remove(ids.begin(), ids.end(), id), ids.end());
    values["profiles"] = JoinIds(ids);
    for (std::map<std::string, std::string>::iterator i = values.begin(); i != values.end();) {
        if (i->first.compare(0, 8 + id.size() + 1, "profile." + id + ".") == 0) {
            values.erase(i++);
        } else {
            ++i;
        }
    }
    WriteState(values);
    return true;
}

void Client::DescribeProfile(const std::string& key, const std::string& value)
{
    if (key.empty() || key.find('=') != std::string::npos || key.find('.') != std::string::npos) return;
    std::map<std::string, std::string> values = ReadState();
    std::string clean = value;
    for (size_t i = 0; i < clean.size(); ++i) {
        if (clean[i] == '\n' || clean[i] == '\r') clean[i] = ' ';
    }
    const std::string id = CurrentProfileId(values);
    values["profile." + id + "." + key] = clean;
    // When this save was last played, as the menu shows it: the Lua side has no clock.
    char stamp[32];
    std::time_t now = std::time(nullptr);
    std::tm* local = std::localtime(&now);
    if (local != nullptr && std::strftime(stamp, sizeof(stamp), "%Y-%m-%d %H:%M", local) > 0) {
        values["profile." + id + ".last"] = stamp;
    }
    WriteState(values);
}

std::string Client::ProfileDetail(const std::string& id, const std::string& key) const
{
    const std::map<std::string, std::string> values = ReadState();
    std::map<std::string, std::string>::const_iterator found = values.find("profile." + id + "." + key);
    return found == values.end() ? std::string() : found->second;
}

void ApplyPendingProfile()
{
    gWipeNewProfile = false;
    std::map<std::string, std::string> values = ReadState();
    const std::string pending = values["profile_pending"];
    values.erase("profile_pending");
    const std::string current = CurrentProfileId(values);
    if (!ValidProfileId(pending) || pending == current || SaveFileHandler::instance == nullptr) {
        WriteState(values);
        return;
    }
    const std::string base = FileHelper::getUserFolder() + SaveFileHandler::instance->savePrefix;
    const std::string folder = ProfilesFolder();
    MakeDir(folder);
    const std::string away = folder + "/" + current + "/";
    MakeDir(away);
    // The current files first: a failed copy stops everything, the player keeps what they had.
    for (size_t i = 0; i < kProfileFileCount; ++i) {
        const std::string live = base + kProfileFiles[i][0];
        const std::string kept = away + kProfileFiles[i][1];
        if (FileExists(live)) {
            if (!CopyFileContent(live, kept)) {
                WriteState(values);
                return;
            }
        } else {
            std::remove(kept.c_str());
        }
    }
    const std::string target = folder + "/" + pending + "/";
    const bool known = FileExists(target + "prof.sav");
    for (size_t i = 0; i < kProfileFileCount; ++i) {
        const std::string live = base + kProfileFiles[i][0];
        const std::string stored = target + kProfileFiles[i][1];
        if (known && FileExists(stored)) {
            CopyFileContent(stored, live);
        } else if (i > 0 || known) {
            // Kept in the folder just above: the backup and the run of the other profile are not lost.
            std::remove(live.c_str());
        }
    }
    gWipeNewProfile = !known;
    std::vector<std::string> ids = SplitIds(values["profiles"]);
    if (std::find(ids.begin(), ids.end(), current) == ids.end()) ids.push_back(current);
    if (std::find(ids.begin(), ids.end(), pending) == ids.end()) ids.push_back(pending);
    values["profiles"] = JoinIds(ids);
    values["profile"] = pending;
    WriteState(values);
}

void FinishPendingProfile()
{
    if (!gWipeNewProfile) return;
    gWipeNewProfile = false;
    G_->GetScoreKeeper()->WipeProfile(true);
    G_->GetScoreKeeper()->Save(false);
}

bool Client::RequestProfileReset()
{
    if (SaveFileHandler::instance == nullptr) return false;
    const std::string base = FileHelper::getUserFolder() + SaveFileHandler::instance->savePrefix;
    const std::string suffix = ".before-" + Timestamp();
    const char* profileFiles[] = { "_prof.sav", "_prof_backup.sav" };
    for (size_t i = 0; i < sizeof(profileFiles) / sizeof(profileFiles[0]); ++i) {
        const std::string path = base + profileFiles[i];
        if (!CopyFileContent(path, path + suffix)) return false;
    }
    G_->GetScoreKeeper()->WipeProfile(true);
    G_->GetScoreKeeper()->Save(false);
    _impl->resetDone = true;
    return true;
}

void Client::RememberState(const std::string& key, const std::string& value)
{
    if (key.empty() || key.find('=') != std::string::npos) return;
    std::string clean = value;
    for (size_t i = 0; i < clean.size(); ++i) {
        if (clean[i] == '\n' || clean[i] == '\r') clean[i] = ' ';
    }
    std::map<std::string, std::string> values = ReadState();
    values[key] = clean;
    WriteState(values);
}

std::string Client::RecallState(const std::string& key) const
{
    const std::map<std::string, std::string> values = ReadState();
    std::map<std::string, std::string>::const_iterator found = values.find(key);
    if (found == values.end()) return std::string();
    return found->second;
}

bool Client::RelaunchWhenClosed()
{
#ifdef _WIN32
    char path[MAX_PATH];
    const DWORD len = GetModuleFileNameA(nullptr, path, MAX_PATH);
    if (len == 0 || len >= MAX_PATH) return false;
    const std::string exe(path);
    const std::string dir = exe.substr(0, exe.find_last_of("\\/"));

    // Always the game itself, even when Steam started it: Steam counts the game as running while its child lives,
    // so it refused every steam:// launch (seen on Windows, 3 out of 3). The new game waits for this one before it
    // does anything (see PreviousGameWait): no helper process, and no script for an antivirus to take for malware.
    SetEnvironmentVariableA(kPreviousGame, std::to_string(static_cast<unsigned long>(GetCurrentProcessId())).c_str());

    STARTUPINFOA startup;
    ZeroMemory(&startup, sizeof(startup));
    startup.cb = sizeof(startup);
    PROCESS_INFORMATION process;
    ZeroMemory(&process, sizeof(process));
    std::string command = "\"" + exe + "\"";
    const BOOL started = CreateProcessA(exe.c_str(), &command[0], nullptr, nullptr, FALSE, CREATE_NEW_PROCESS_GROUP,
                                        nullptr, dir.c_str(), &startup, &process);
    SetEnvironmentVariableA(kPreviousGame, nullptr);
    if (!started) return false;
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return true;
#else
    char path[4096];
    const ssize_t len = readlink("/proc/self/exe", path, sizeof(path) - 1);
    if (len <= 0) return false;
    path[len] = '\0';
    const std::string binaryPath(path);
    const std::string dir = binaryPath.substr(0, binaryPath.rfind('/'));
    const std::string launcher = dir + "/FTL";
    if (access(launcher.c_str(), X_OK) != 0) return false;

    const std::string pidStr = std::to_string(static_cast<long>(getpid()));
    const std::string script =
        "while kill -0 " + pidStr + " 2>/dev/null; do sleep 0.3; done; sleep 1; "
        "cd \"$1\" && exec \"$2\"";

    // Drop LD_PRELOAD: the "FTL" launcher script sets its own to preload this very .so, and
    // an inherited stale value (game moved/updated) would break the relaunch it is about to do.
    std::vector<std::string> envVars;
    for (char** cur = environ; cur != nullptr && *cur != nullptr; ++cur) {
        if (std::strncmp(*cur, "LD_PRELOAD=", 11) != 0) envVars.push_back(*cur);
    }
    std::vector<char*> envp;
    for (size_t i = 0; i < envVars.size(); ++i) envp.push_back(&envVars[i][0]);
    envp.push_back(nullptr);
    std::vector<std::string> cmdArgs = { "/bin/sh", "-c", script, "ftl-relaunch", dir, launcher };
    std::vector<char*> argv;
    for (size_t i = 0; i < cmdArgs.size(); ++i) argv.push_back(&cmdArgs[i][0]);
    argv.push_back(nullptr);

    const pid_t child = fork();
    if (child < 0) return false;
    if (child == 0) {
        setsid();
        const long maxFd = sysconf(_SC_OPEN_MAX);
        for (long fd = 3; fd < (maxFd > 0 ? maxFd : 4096); ++fd) {
            close(static_cast<int>(fd));
        }
        execve("/bin/sh", argv.data(), envp.data());
        _exit(127);
    }
    return true;
#endif
}

bool Client::ProfileResetRequested() const
{
    return _impl->resetDone;
}

std::string Client::LastUri() const
{
    std::string uri, slot;
    RecallConnection(uri, slot);
    return uri;
}

std::string Client::LastSlot() const
{
    std::string uri, slot;
    RecallConnection(uri, slot);
    return slot;
}

// FTL reads its own keyboard and Hyperspace's SDL never opens a window, so neither offers the clipboard:
// Windows is asked directly, Linux through the usual clipboard tools when one is installed.
std::string Client::Clipboard() const
{
    std::string text;
#ifdef _WIN32
    if (OpenClipboard(nullptr)) {
        HANDLE data = GetClipboardData(CF_UNICODETEXT);
        const wchar_t* wide = data ? static_cast<const wchar_t*>(GlobalLock(data)) : nullptr;
        if (wide != nullptr) {
            int size = WideCharToMultiByte(CP_UTF8, 0, wide, -1, nullptr, 0, nullptr, nullptr);
            if (size > 1) {
                text.resize(size - 1);
                WideCharToMultiByte(CP_UTF8, 0, wide, -1, &text[0], size, nullptr, nullptr);
            }
            GlobalUnlock(data);
        }
        CloseClipboard();
    }
#else
    // Wayland's tool only when the session is Wayland: elsewhere it would fall back on another session's clipboard.
    const char* command = getenv("WAYLAND_DISPLAY") != nullptr
        ? "(wl-paste --no-newline || xclip -o -selection clipboard || xsel -ob) 2>/dev/null"
        : "(xclip -o -selection clipboard || xsel -ob) 2>/dev/null";
    FILE* pipe = popen(command, "r");
    if (pipe != nullptr) {
        char buffer[256];
        size_t read = fread(buffer, 1, sizeof(buffer) - 1, pipe);
        pclose(pipe);
        text.assign(buffer, read);
    }
#endif
    size_t end = text.find_first_of("\r\n");
    if (end != std::string::npos) text.resize(end);
    if (text.size() > 200) text.resize(200);
    return text;
}

std::string Client::Platform() const
{
#ifdef _WIN32
    return "windows";
#else
    return "linux";
#endif
}

void Client::SetGame(const std::string& game)
{
    if (!game.empty()) kGameName = game;
}

bool Client::Connect(const std::string& uri, const std::string& slot, const std::string& password)
{
    Disconnect();

    _impl->uri = uri;
    _impl->slot = slot;
    _impl->password = password;

    try {
        std::string store = CertStore();
        {
            Event e;
            e.kind = "log";
            e.extra = "CA bundle: " + certSource;
            _impl->push(std::move(e));
        }
        _impl->certStore = store;
        _impl->tlsDiagnosed = false;
        _impl->ap.reset(new APClient("", kGameName, uri, store));
    } catch (const std::exception& error) {
        Event e;
        e.kind = "error";
        e.name = "socket";
        e.extra = error.what();
        _impl->push(std::move(e));
        return false;
    }

    APClient* ap = _impl->ap.get();
    Impl* impl = _impl.get();

    ap->set_socket_connected_handler([ap, impl]() {
        try {
            ap->ConnectSlot(impl->slot, impl->password, kItemsHandling,
                            {"DeathLink", "TrapLink"}, {0, 6, 7});
        } catch (const std::exception& err) {
            Event e;
            e.kind = "error";
            e.name = "handshake";
            e.extra = err.what();
            impl->push(std::move(e));
        }
    });

    ap->set_socket_error_handler([impl](const std::string& message) {
        Event e;
        e.kind = "error";
        e.name = "unreachable";
        e.extra = message;
        impl->push(std::move(e));
        // Once per connection: the reason of a failed TLS handshake, found on a thread of its own.
        if (message.find("TLS") != std::string::npos && !impl->tlsDiagnosed) {
            impl->tlsDiagnosed = true;
            std::string uri = impl->uri, store = impl->certStore;
            std::thread([impl, uri, store]() {
                Event d;
                d.kind = "log";
                d.extra = "TLS: " + TlsDiagnosis(uri, store);
                impl->push(std::move(d));
            }).detach();
        }
    });

    ap->set_socket_disconnected_handler([impl]() {
        impl->connected = false;
        Event e;
        e.kind = "disconnected";
        impl->push(std::move(e));
    });

    auto pushHint = [impl, ap](int receiver, int finder, int64_t item, int64_t location,
                               bool found, bool alreadyKnown) {
        const int me = ap->get_player_number();
        if (receiver != me && finder != me) return;
        Event e;
        e.kind = "hint";
        e.name = ap->get_item_name(item, ap->get_player_game(receiver));
        e.sender = ap->get_player_alias(receiver);
        e.other = ap->get_player_alias(finder);
        e.extra = ap->get_location_name(location, ap->get_player_game(finder));
        e.value = found ? 1 : 0;
        e.index = alreadyKnown ? 1 : 0;
        impl->push(std::move(e));
    };

    ap->set_print_json_handler([impl, ap, pushHint](const APClient::PrintJSONArgs& args) {
        // The in-game text client: what a player reads in a text client, items sent and joins left out.
        static const char* const shown[] = {"Chat", "ServerChat", "CommandResult", "AdminCommandResult", "Hint",
                                            "Countdown", "Goal", "Release", "Collect", "Tutorial"};
        for (const char* type : shown) {
            if (args.type != type) continue;
            Event chat;
            chat.kind = "chat";
            chat.name = args.type;
            try {
                chat.extra = ap->render_json(args.data, APClient::RenderFormat::TEXT);
            } catch (...) {
                chat.extra.clear();
            }
            if (!chat.extra.empty()) impl->push(std::move(chat));
            break;
        }
        if (args.type != "Hint" || args.item == nullptr || args.receiving == nullptr) return;
        pushHint(*args.receiving, args.item->player, args.item->item, args.item->location,
                 args.found != nullptr && *args.found, false);
    });

    ap->set_slot_connected_handler([impl, ap](const nlohmann::json& slotData) {
        impl->connected = true;
        RememberConnection(impl->uri, impl->slot);
        Event e;
        e.kind = "connected";
        e.extra = slotData.dump();
        e.name = ap->get_player_alias(ap->get_player_number());
        impl->push(std::move(e));
        // "_read_hints_<team>_<slot>" is the AP data storage key convention for a slot's
        // already-known hints; reading it here replays them as ordinary hint events on connect.
        ap->Get({ "_read_hints_" + std::to_string(ap->get_team_number()) + "_"
                  + std::to_string(ap->get_player_number()) });
    });

    ap->set_slot_refused_handler([impl](const std::list<std::string>& reasons) {
        Event e;
        e.kind = "refused";
        for (const auto& reason : reasons) {
            if (!e.extra.empty()) e.extra += ",";
            e.extra += reason;
        }
        impl->push(std::move(e));
    });

    ap->set_items_received_handler([impl, ap](const std::list<APClient::NetworkItem>& items) {
        for (const auto& item : items) {
            Event e;
            e.kind = "item";
            e.name = ap->get_item_name(item.item, kGameName);
            e.sender = playerAlias(*ap, item.player);
            e.value = item.item;
            e.index = item.index;
            impl->push(std::move(e));
        }
    });

    // On a first connection items can arrive before their names; ask for them again once the
    // names are known, the Lua side skips the indices it already handled.
    ap->set_data_package_changed_handler([ap](const nlohmann::json&) {
        ap->Sync();
    });

    ap->set_location_info_handler([impl, ap](const std::list<APClient::NetworkItem>& items) {
        for (const auto& item : items) {
            Event e;
            e.kind = "scout";
            e.name = ap->get_location_name(item.location, kGameName);
            e.sender = ap->get_player_alias(item.player);
            e.extra = ap->get_item_name(item.item, ap->get_player_game(item.player));
            e.value = static_cast<int64_t>(item.flags);
            e.index = item.location <= 0x7fffffff ? static_cast<int>(item.location) : -1;
            impl->push(std::move(e));
        }
    });

    ap->set_bounced_handler([impl, ap](const nlohmann::json& packet) {
        const auto data = packet.find("data");
        const bool hasData = data != packet.end();

        // Another FTL client on TrapLink says it is there (index 1 when it answers our own announce).
        if (hasData && data->is_object() && data->contains("ftl_traplink") && data->contains("source")) {
            Event e;
            e.kind = "trap_partner";
            e.sender = (*data)["source"].get<std::string>();
            e.index = (*data)["ftl_traplink"] == "reply" ? 1 : 0;
            e.value = data->value("slot", 0);
            if (e.sender != ap->get_player_alias(ap->get_player_number())) {
                impl->push(std::move(e));
            }
            return;
        }

        // A trap aimed at this slot alone, by another FTL client.
        if (hasData && data->is_object() && data->contains("ftl_trap") && data->contains("source")) {
            Event e;
            e.kind = "trap";
            e.sender = (*data)["source"].get<std::string>();
            e.name = (*data)["ftl_trap"].get<std::string>();
            impl->push(std::move(e));
            return;
        }

        const auto tags = packet.find("tags");
        if (tags == packet.end()) return;

        for (const auto& tag : *tags) {
            const std::string name = tag.get<std::string>();

            if (name == "DeathLink") {
                Event e;
                e.kind = "death";
                if (hasData) {
                    if (data->contains("source")) e.sender = (*data)["source"].get<std::string>();
                    if (data->contains("cause")) e.name = (*data)["cause"].get<std::string>();
                }
                if (e.sender != ap->get_player_alias(ap->get_player_number())) {
                    impl->push(std::move(e));
                }
            } else if (name == "TrapLink") {
                Event e;
                e.kind = "trap";
                if (hasData) {
                    if (data->contains("source")) e.sender = (*data)["source"].get<std::string>();
                    if (data->contains("trap_name")) e.name = (*data)["trap_name"].get<std::string>();
                }
                if (e.sender != ap->get_player_alias(ap->get_player_number())) {
                    impl->push(std::move(e));
                }
            }
        }
    });

    ap->set_retrieved_handler([impl, pushHint](const std::map<std::string, nlohmann::json>& values) {
        for (const auto& pair : values) {
            if (pair.first.rfind("_read_hints_", 0) == 0 && pair.second.is_array()) {
                for (const auto& hint : pair.second) {
                    if (!hint.is_object()) continue;
                    try {
                        pushHint(hint.value("receiving_player", -1),
                                 hint.value("finding_player", -1),
                                 hint.value("item", static_cast<int64_t>(0)),
                                 hint.value("location", static_cast<int64_t>(0)),
                                 hint.value("found", false), true);
                    } catch (const std::exception&) {
                        continue;
                    }
                }
                continue;
            }
            if (pair.first.rfind("EnergyLink", 0) != 0) continue;
            Event e;
            e.kind = "energy";
            e.name = pair.first;
            e.value = pair.second.is_number() ? pair.second.get<int64_t>() : 0;
            impl->push(std::move(e));
        }
    });

    ap->set_set_reply_handler([impl](const nlohmann::json& packet) {
        const auto key = packet.find("key");
        if (key == packet.end() || key->get<std::string>().rfind("EnergyLink", 0) != 0) return;

        const auto before = packet.find("original_value");
        const auto after = packet.find("value");
        if (before == packet.end() || after == packet.end()) return;

        Event e;
        e.kind = "energy";
        e.name = key->get<std::string>();
        e.value = after->get<int64_t>();
        e.index = static_cast<int>(before->get<int64_t>() - after->get<int64_t>());
        impl->push(std::move(e));
    });

    return true;
}

void Client::Disconnect()
{
    if (_impl->ap) {
        _impl->ap.reset();
    }
    _impl->connected = false;
}

bool Client::IsConnected() const
{
    return _impl->connected;
}

void Client::Push(Event e)
{
    _impl->push(std::move(e));
}

void Client::Poll()
{
    if (!_impl->ap) return;
    try {
        _impl->ap->poll();
    } catch (const std::exception& err) {
        Event e;
        e.kind = "error";
        e.name = "poll";
        e.extra = err.what();
        _impl->push(std::move(e));
    } catch (...) {
        Event e;
        e.kind = "error";
        e.name = "poll";
        _impl->push(std::move(e));
    }
}

std::vector<Event> Client::TakeEvents()
{
    std::lock_guard<std::mutex> lock(_impl->mutex);
    std::vector<Event> out(_impl->events.begin(), _impl->events.end());
    _impl->events.clear();
    return out;
}

bool Client::SendCheck(const std::string& locationName)
{
    if (!_impl->ap) return false;
    const int64_t id = _impl->ap->get_location_id(locationName);
    if (id == APClient::INVALID_NAME_ID) {
        Event e;
        e.kind = "error";
        e.name = "location";
        e.extra = locationName;
        _impl->push(std::move(e));
        return false;
    }
    return _impl->ap->LocationChecks({id});
}

bool Client::ScoutLocations(const std::vector<std::string>& locationNames)
{
    if (!_impl->ap) return false;
    std::list<int64_t> ids;
    for (const auto& name : locationNames) {
        const int64_t id = _impl->ap->get_location_id(name);
        if (id != APClient::INVALID_NAME_ID) ids.push_back(id);
    }
    if (ids.empty()) return false;
    return _impl->ap->LocationScouts(ids, 0);
}

bool Client::HintLocation(const std::string& locationName)
{
    if (!_impl->ap || !_impl->connected) return false;
    const int64_t id = _impl->ap->get_location_id(locationName);
    if (id == APClient::INVALID_NAME_ID) return false;
    return _impl->ap->LocationScouts(std::list<int64_t>{ id }, 2);
}

bool Client::SendGoal()
{
    if (!_impl->ap) return false;
    return _impl->ap->StatusUpdate(APClient::ClientStatus::GOAL);
}

bool Client::SendDeath(const std::string& cause)
{
    if (!_impl->ap) return false;
    const auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    nlohmann::json data = {
        {"time", static_cast<double>(now) / 1000.0},
        {"source", _impl->ap->get_player_alias(_impl->ap->get_player_number())},
        {"cause", cause},
    };
    return _impl->ap->Bounce(data, {}, {}, {{"DeathLink"}});
}

bool Client::SendTrap(const std::string& trapName)
{
    if (!_impl->ap) return false;
    const auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    nlohmann::json data = {
        {"time", static_cast<double>(now) / 1000.0},
        {"source", _impl->ap->get_player_alias(_impl->ap->get_player_number())},
        {"trap_name", trapName},
    };
    return _impl->ap->Bounce(data, {}, {}, {{"TrapLink"}});
}

// TrapLink goes to everyone on it. A pact promises one victim, and a slot only hears a Bounce with no tag if it is
// aimed at it, so this one reaches a single FTL client.
bool Client::SendTrapTo(int slot, const std::string& trapName)
{
    if (!_impl->ap) return false;
    nlohmann::json data = {
        {"source", _impl->ap->get_player_alias(_impl->ap->get_player_number())},
        {"ftl_trap", trapName},
    };
    return _impl->ap->Bounce(data, {}, {slot}, {});
}

bool Client::AnnounceTrapLink(bool reply)
{
    if (!_impl->ap) return false;
    nlohmann::json data = {
        {"source", _impl->ap->get_player_alias(_impl->ap->get_player_number())},
        {"slot", _impl->ap->get_player_number()},
        {"ftl_traplink", reply ? "reply" : "hello"},
    };
    // Sent by game, not by tag: other games on TrapLink would read it as a trap.
    return _impl->ap->Bounce(data, {"FTL: Faster Than Light", "FTL Multiverse"}, {}, {});
}

bool Client::EnergyDeposit(int64_t joules)
{
    if (!_impl->ap) return false;
    const std::string key = "EnergyLink" + std::to_string(_impl->ap->get_team_number());
    std::list<APClient::DataStorageOperation> ops = {
        {"add", joules},
        {"max", 0},
    };
    return _impl->ap->Set(key, 0, true, ops);
}

bool Client::EnergyRequest(int64_t joules)
{
    if (!_impl->ap) return false;
    const std::string key = "EnergyLink" + std::to_string(_impl->ap->get_team_number());
    std::list<APClient::DataStorageOperation> ops = {
        {"add", -joules},
        {"max", 0},
    };
    return _impl->ap->Set(key, 0, true, ops);
}

bool Client::SetTags(const std::vector<std::string>& tags)
{
    if (!_impl->ap || !_impl->connected) return false;
    const std::list<std::string> tagList(tags.begin(), tags.end());
    return _impl->ap->ConnectUpdate(false, 0, true, tagList);
}

bool Client::Say(const std::string& text)
{
    if (!_impl->ap) return false;
    return _impl->ap->Say(text);
}

std::vector<std::string> Client::CheckedLocations() const
{
    std::vector<std::string> names;
    if (!_impl->ap) return names;
    const auto checked = _impl->ap->get_checked_locations();
    names.reserve(checked.size());
    for (const int64_t id : checked) {
        std::string name = _impl->ap->get_location_name(id, kGameName);
        if (!name.empty()) names.push_back(std::move(name));
    }
    return names;
}

std::string Client::PlayerName(int slot) const
{
    if (!_impl->ap) return {};
    return _impl->ap->get_player_alias(slot);
}

Client& Instance()
{
    static Client client;
    return client;
}

}
