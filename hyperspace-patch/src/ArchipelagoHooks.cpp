// Ship unlocks and FTL achievements, kept apart from Archipelago.cpp so the network headers never meet
// Hyperspace's own.
#include "Global.h"
#include "ShipUnlocks.h"
#include "Archipelago.h"

#include <algorithm>

namespace ArchipelagoFTL
{

namespace
{
bool shipLock = false;
std::string allowedShip;

std::pair<int, int> vanillaIdAndVariant(const std::string& blueprint)
{
    std::string base = blueprint;
    int variant = 0;
    if (base.size() > 2 && base.compare(base.size() - 2, 2, "_2") == 0) variant = 1;
    if (base.size() > 2 && base.compare(base.size() - 2, 2, "_3") == 0) variant = 2;
    if (variant > 0) base = base.substr(0, base.size() - 2);
    int id = G_->GetScoreKeeper()->GetShipId(base).first;
    return std::make_pair(id, variant);
}
}

bool ShipUnlockAllowed(const std::string& blueprint)
{
    return !shipLock || (!allowedShip.empty() && blueprint == allowedShip);
}

void ShipUnlockDenied(const std::string& blueprint)
{
    Event e;
    e.kind = "unlock_denied";
    e.name = blueprint;
    Instance().Push(std::move(e));
}

void Client::SetShipLock(bool on)
{
    shipLock = on;
}

bool Client::UnlockShip(const std::string& blueprint, bool silent)
{
    if (blueprint.empty()) return false;
    allowedShip = blueprint;
    CustomShipUnlocks::instance->UnlockShip(blueprint, silent, true, false);
    allowedShip.clear();
    return CustomShipUnlocks::instance->GetCustomShipUnlocked(blueprint);
}

int Client::LockShips(const std::vector<std::string>& blueprints)
{
    CustomShipUnlocks* unlocks = CustomShipUnlocks::instance;
    ScoreKeeper* scores = G_->GetScoreKeeper();
    int locked = 0;
    for (const auto& blueprint : blueprints) {
        // FTL needs one playable ship: the Kestrel A is never taken away.
        if (blueprint.empty() || blueprint == "PLAYER_SHIP_HARD") continue;
        bool changed = false;
        auto& list = unlocks->customUnlockedShips;
        auto it = std::find(list.begin(), list.end(), blueprint);
        if (it != list.end()) {
            list.erase(it);
            changed = true;
        }
        std::pair<int, int> id = vanillaIdAndVariant(blueprint);
        if (id.first >= 0 && id.first < (int)scores->unlocked.size()
            && id.second < (int)scores->unlocked[id.first].size() && scores->unlocked[id.first][id.second]) {
            scores->unlocked[id.first][id.second] = false;
            changed = true;
        }
        if (changed) ++locked;
    }
    if (locked > 0) scores->Save(false);
    return locked;
}

int Client::AchievementStatus(const std::string& name) const
{
    AchievementTracker* tracker = G_->GetAchievementTracker();
    if (tracker == nullptr) return -1;
    for (CAchievement* ach : tracker->achievements) {
        if (ach != nullptr && ach->name_id == name) return ach->unlocked ? ach->difficulty : -1;
    }
    return -1;
}

}

// Events and achievements unlock vanilla ships here. Loading the profile calls it too, with nothing to save
// and no popup: that one is let through.
HOOK_METHOD(ScoreKeeper, UnlockShip, (int shipId, int shipType, bool save, bool hidePopup) -> void)
{
    LOG_HOOK("HOOK_METHOD -> ScoreKeeper::UnlockShip -> Begin (ArchipelagoHooks.cpp)\n")
    if (!save && hidePopup) return super(shipId, shipType, save, hidePopup);
    std::string blueprint = shipId >= 0 && shipId < 100 ? GetShipBlueprint(shipId) : "";
    if (shipType == 1) blueprint += "_2";
    if (shipType == 2) blueprint += "_3";
    if (!ArchipelagoFTL::ShipUnlockAllowed(blueprint)) {
        ArchipelagoFTL::ShipUnlockDenied(blueprint);
        return;
    }
    super(shipId, shipType, save, hidePopup);
}
