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

    // Ships come from Archipelago only. While the lock is on, FTL's own unlocks (events, achievements,
    // Hyperspace unlock rules) are refused and reported as "unlock_denied" events.
    void SetShipLock(bool on);
    bool UnlockShip(const std::string& blueprint, bool silent);
    // Locks again every listed layout the profile has, then saves the profile once. Returns how many.
    int LockShips(const std::vector<std::string>& blueprints);

    // FTL's own achievements (difficulty it was earned on, -1 if not), which Hyperspace's tracker of
    // custom achievements does not hold.
    int AchievementStatus(const std::string& name) const;

    void Push(Event e);

private:
    struct Impl;
    std::unique_ptr<Impl> _impl;
};

Client& Instance();

// Used by the hooks: whether this unlock may go through, and telling Lua about one that did not.
bool ShipUnlockAllowed(const std::string& blueprint);
void ShipUnlockDenied(const std::string& blueprint);

struct Archipelago {
    static Client& Instance() { return ::ArchipelagoFTL::Instance(); }
};

}
