#pragma once

#include <string>
#include <vector>
#include <deque>
#include <mutex>
#include <memory>
#include <cstdint>

namespace ArchipelagoFTL
{

struct Event
{
    std::string kind;
    std::string name;
    std::string sender;
    std::string extra;
    std::string other;
    int64_t value = 0;
    int index = -1;
};

class Client
{
public:
    Client();
    ~Client();

    bool Connect(const std::string& uri, const std::string& slot, const std::string& password);

    std::string LastUri() const;
    std::string LastSlot() const;

    bool RequestProfileReset();
    bool RelaunchWhenClosed();
    bool ProfileResetRequested() const;

    void RememberState(const std::string& key, const std::string& value);
    std::string RecallState(const std::string& key) const;
    void Disconnect();
    bool IsConnected() const;

    void Poll();

    std::vector<Event> TakeEvents();

    bool SendCheck(const std::string& locationName);
    bool ScoutLocations(const std::vector<std::string>& locationNames);
    bool HintLocation(const std::string& locationName);
    bool SendGoal();
    bool SendDeath(const std::string& cause);
    bool SendTrap(const std::string& trapName);
    bool EnergyDeposit(int64_t joules);
    bool EnergyRequest(int64_t joules);
    bool Say(const std::string& text);
    bool SetTags(const std::vector<std::string>& tags);

    std::vector<std::string> CheckedLocations() const;

    std::string PlayerName(int slot) const;

private:
    struct Impl;
    std::unique_ptr<Impl> _impl;
};

Client& Instance();

struct Archipelago {
    static Client& Instance() { return ::ArchipelagoFTL::Instance(); }
};

}
