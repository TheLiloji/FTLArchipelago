#include "Archipelago.h"
#include "SaveFile.h"

#ifndef AP_NO_SCHEMA
#define AP_NO_SCHEMA
#endif
#include "apclient.hpp"

#include <algorithm>
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
#else
#include <sys/stat.h>
#include <unistd.h>
extern char** environ;
#endif

namespace ArchipelagoFTL
{

namespace
{
const char* kGameName = "FTL: Faster Than Light";

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

std::string CertStore()
{
#ifdef _WIN32
    return std::string();
#else
    // No single canonical CA bundle path across Linux distros; probe the common ones so TLS
    // verification works on both Debian/Ubuntu-family and Fedora/RHEL-family systems.
    static const char* kPaths[] = {
        "/etc/ssl/certs/ca-certificates.crt",
        "/etc/pki/tls/certs/ca-bundle.crt",
        "/etc/ssl/ca-bundle.pem",
        "/etc/ssl/cert.pem",
    };
    for (size_t i = 0; i < sizeof(kPaths) / sizeof(kPaths[0]); ++i) {
        std::ifstream f(kPaths[i]);
        if (f.good()) return std::string(kPaths[i]);
    }
    return std::string();
#endif
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
    return false;
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

bool Client::Connect(const std::string& uri, const std::string& slot, const std::string& password)
{
    Disconnect();

    _impl->uri = uri;
    _impl->slot = slot;
    _impl->password = password;

    try {
        _impl->ap.reset(new APClient("", kGameName, uri, CertStore()));
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
                            {"DeathLink", "TrapLink"}, {0, 5, 0});
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

    ap->set_print_json_handler([pushHint](const APClient::PrintJSONArgs& args) {
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
        const auto tags = packet.find("tags");
        if (tags == packet.end()) return;

        const auto data = packet.find("data");
        const bool hasData = data != packet.end();

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
