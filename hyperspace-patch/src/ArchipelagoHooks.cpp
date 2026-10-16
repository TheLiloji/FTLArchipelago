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
        // FTL needs one playable ship: the Kestrel A, and Multiverse's Kestrel, are never taken away.
        if (blueprint.empty() || blueprint == "PLAYER_SHIP_HARD" || blueprint == "PLAYER_SHIP_MVKESTREL") continue;
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

// Archipelago deals are augments only on paper: the mod takes them off the ship as soon as they are bought.
// Full augment slots must not refuse them, nor say so when the mouse is on them.
namespace
{
bool IsDeal(const std::string& name)
{
    return name.compare(0, 8, "AP_DEAL_") == 0;
}

bool IsDeal(const AugmentBlueprint* blueprint)
{
    return blueprint != nullptr && IsDeal(blueprint->name);
}
}

HOOK_METHOD(AugmentStoreBox, CanHold, () -> bool)
{
    LOG_HOOK("HOOK_METHOD -> AugmentStoreBox::CanHold -> Begin (ArchipelagoHooks.cpp)\n")
    if (IsDeal(blueprint)) return shopper != nullptr && !shopper->HasAugmentation(blueprint->name);
    return super();
}

HOOK_METHOD(AugmentStoreBox, MouseMove, (int mX, int mY) -> void)
{
    LOG_HOOK("HOOK_METHOD -> AugmentStoreBox::MouseMove -> Begin (ArchipelagoHooks.cpp)\n")
    if (IsDeal(blueprint)) return button.MouseMove(mX, mY, false);
    super(mX, mY);
}

// The purchase adds the augment, which a full ship refuses: the deal is added beside the slots, never counted.
HOOK_METHOD(ShipObject, AddAugmentation, (const std::string& name) -> bool)
{
    LOG_HOOK("HOOK_METHOD -> ShipObject::AddAugmentation -> Begin (ArchipelagoHooks.cpp)\n")
    if (!IsDeal(name)) return super(name);
    ShipInfo* info = G_->GetShipInfo(iShipId);
    const int count = info->augCount;
    info->augCount = 0;
    const bool added = super(name);
    info->augCount = count;
    return added;
}

// Archipelago packages are weapons only on paper too: a full ship (four weapons, full cargo) must still be able
// to buy one. The store then lets the button be pressed, keeps quiet about the full cargo, and the package goes
// straight to the mod instead of into a ship with no room for it.
namespace
{
bool IsPackage(const Blueprint* blueprint)
{
    return blueprint != nullptr && blueprint->name.compare(0, 8, "AP_GIFT_") == 0;
}

bool RoomForWeapon(Equipment* equipment)
{
    for (EquipmentBox* box : equipment->vEquipmentBoxes) {
        if (box != nullptr && box != equipment->overcapacityBox && box->IsEmpty() && box->CanHoldWeapon()) return true;
    }
    return false;
}

// The package box under the mouse, only ever compared, never read.
const StoreBox* pointedPackage = nullptr;
}

HOOK_METHOD(StoreBox, OnLoop, () -> void)
{
    LOG_HOOK("HOOK_METHOD -> StoreBox::OnLoop -> Begin (ArchipelagoHooks.cpp)\n")
    super();
    if (IsPackage(pBlueprint) && count > 0 && !desc.locked && !button.bActive) button.SetActive(true);
    if (button.bHover) pointedPackage = IsPackage(pBlueprint) ? this : nullptr;
    else if (pointedPackage == this) pointedPackage = nullptr;
}

// The full-cargo tooltip comes from the mouse handling: it is dropped there while a package is under the mouse.
HOOK_METHOD(MouseControl, SetTooltip, (const std::string& tooltip) -> void)
{
    LOG_HOOK("HOOK_METHOD -> MouseControl::SetTooltip -> Begin (ArchipelagoHooks.cpp)\n")
    if (pointedPackage != nullptr && tooltip == G_->GetTextLibrary()->GetText("max_weapons")) return;
    super(tooltip);
}

HOOK_METHOD(Equipment, AddWeapon, (WeaponBlueprint* bp, bool free, bool forceCargo) -> void)
{
    LOG_HOOK("HOOK_METHOD -> Equipment::AddWeapon -> Begin (ArchipelagoHooks.cpp)\n")
    if (!IsPackage(bp) || RoomForWeapon(this)) return super(bp, free, forceCargo);
    ArchipelagoFTL::Event e;
    e.kind = "package_bought";
    e.name = bp->name;
    ArchipelagoFTL::Instance().Push(std::move(e));
}
