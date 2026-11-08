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
    // The Archipelago game name sent at the next Connect. The base game's by default.
    void SetGame(const std::string& game);

    std::string LastUri() const;
    std::string LastSlot() const;
    // The system clipboard's text (first line only, at most 200 bytes), or "" when there is none.
    std::string Clipboard() const;
    // While on, the characters FTL reads from the keyboard (with the player's layout, as when naming a
    // ship) are kept for TakeText instead of reaching the game. TakeText empties them, as UTF-8.
    void CaptureText(bool on);
    std::string TakeText();
    // "windows" or "linux": the Lua sandbox has no way to tell.
    std::string Platform() const;

    bool RequestProfileReset();
    bool RelaunchWhenClosed();
    bool ProfileResetRequested() const;

    // Save profiles: each seed (and solo) keeps its own copy of FTL's profile and run save, in
    // <user folder>/ap_profiles/<id>/. A switch is done at the next launch, before FTL reads the profile:
    // the current files are copied away first, nothing is ever deleted (an archived profile is only moved).
    std::string ProfileId() const;
    std::vector<std::string> ProfileIds() const;
    bool SwitchProfile(const std::string& id);
    std::string PendingProfile() const;
    bool ArchiveProfile(const std::string& id);
    void DescribeProfile(const std::string& key, const std::string& value);
    std::string ProfileDetail(const std::string& id, const std::string& key) const;

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
    bool SendTrapTo(int slot, const std::string& trapName);
    // TrapLink never says who is on it: FTL clients tell each other, through a bounce only FTL games receive.
    bool AnnounceTrapLink(bool reply);
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
    // What a store must not sell for now, by blueprint name: left out of the store's random picks, and greyed out
    // where a store shows it anyway (guaranteed systems, Multiverse's fixed store lists).
    void SetShopLock(const std::string& name, bool locked);
    void ClearShopLocks();
    void SetShopLockTip(const std::string& text);

    // FTL's own achievements (difficulty it was earned on, -1 if not), which Hyperspace's tracker of
    // custom achievements does not hold.
    int AchievementStatus(const std::string& name) const;
    // Hides (or shows again) the map label an event's beaconType gives it. False when no such event.
    bool HideBeaconLabel(const std::string& eventName, bool hidden);

    void Push(Event e);

private:
    struct Impl;
    std::unique_ptr<Impl> _impl;
};

Client& Instance();

// Used by the ScoreKeeper::OnInit hook: put the profile asked for in place before FTL reads it, then give a new
// profile a clean start once FTL has.
void ApplyPendingProfile();
void FinishPendingProfile();

// Used by the hooks: whether this unlock may go through, and telling Lua about one that did not.
bool ShipUnlockAllowed(const std::string& blueprint);
void ShipUnlockDenied(const std::string& blueprint);
bool ShopLocked(const std::string& name);
const std::string& ShopLockTip();

struct Archipelago {
    static Client& Instance() { return ::ArchipelagoFTL::Instance(); }
};

}
