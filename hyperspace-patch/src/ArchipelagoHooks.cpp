// Ship unlocks and FTL achievements, kept apart from Archipelago.cpp so the network headers never meet
// Hyperspace's own.
#include "Global.h"
#include "ShipUnlocks.h"
#include "CustomShipSelect.h"
#include "CustomEvents.h"
#include "Archipelago.h"

#include <algorithm>
#include <map>
#include <set>
#include <utility>
#include <vector>

namespace ArchipelagoFTL
{

namespace
{
bool textCapture = false;
std::string typedText;
bool shipLock = false;
std::string allowedShip;
std::set<std::string> shopLocks;
std::string shopLockTip;

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

void Client::SetShopLock(const std::string& name, bool locked)
{
    if (locked) shopLocks.insert(name);
    else shopLocks.erase(name);
}

void Client::ClearShopLocks()
{
    shopLocks.clear();
}

void Client::SetShopLockTip(const std::string& text)
{
    shopLockTip = text;
}

bool ShopLocked(const std::string& name)
{
    return shopLocks.count(name) > 0;
}

const std::string& ShopLockTip()
{
    return shopLockTip;
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

void Client::CaptureText(bool on)
{
    // FTL only reads typed text while one of its text fields is started: the capture keeps one of its own.
    static TextInput* field = nullptr;
    if (field == nullptr) field = new TextInput(256, TextInput::ALLOW_ANY, "");
    if (on && !textCapture) field->Start();
    if (!on && textCapture) field->Stop();
    textCapture = on;
    typedText.clear();
}

std::string Client::TakeText()
{
    std::string text;
    text.swap(typedText);
    return text;
}

bool Client::HideBeaconLabel(const std::string& eventName, bool hidden)
{
    // The label belongs to the event's beaconType: kept aside while hidden, put back when shown again.
    static std::map<std::string, BeaconType*> kept;
    CustomEvent* event = CustomEventsParser::GetInstance()->GetCustomEvent(eventName);
    if (event == nullptr) return false;
    if (hidden && event->beacon != nullptr) {
        kept[eventName] = event->beacon;
        event->beacon = nullptr;
    } else if (!hidden) {
        auto found = kept.find(eventName);
        if (found != kept.end()) event->beacon = found->second;
    }
    return true;
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

// A save profile chosen in the menu is put in place before FTL reads it (see Client::SwitchProfile).
HOOK_METHOD(ScoreKeeper, OnInit, () -> void)
{
    LOG_HOOK("HOOK_METHOD -> ScoreKeeper::OnInit -> Begin (ArchipelagoHooks.cpp)\n")
    ArchipelagoFTL::ApplyPendingProfile();
    super();
    ArchipelagoFTL::FinishPendingProfile();
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

bool BoxLocked(StoreBox* box)
{
    return box->pBlueprint != nullptr && ArchipelagoFTL::ShopLocked(box->pBlueprint->name);
}
}

HOOK_METHOD(StoreBox, OnLoop, () -> void)
{
    LOG_HOOK("HOOK_METHOD -> StoreBox::OnLoop -> Begin (ArchipelagoHooks.cpp)\n")
    super();
    if (IsPackage(pBlueprint) && count > 0 && !desc.locked && !button.bActive) button.SetActive(true);
    if (count > 0 && BoxLocked(this)) button.SetActive(false);
    if (button.bHover) pointedPackage = IsPackage(pBlueprint) ? this : nullptr;
    else if (pointedPackage == this) pointedPackage = nullptr;
}

// A rarity of 0 for every weapon crashes FTL: rewards and enemies draw from the same pool, and an empty one ends
// the game while the map is built. So locked items keep their rarity, and are only left out while a store draws
// its boxes. A store with too few items to fill its boxes gets a locked one or two, greyed out above.
namespace
{
bool storeDrawing = false;

template <class Blueprints>
class LockedLeftOut
{
public:
    LockedLeftOut(Blueprints& blueprints, int count)
    {
        if (!storeDrawing) return;
        int open = 0;
        for (auto& entry : blueprints) {
            if (entry.second.desc.rarity > 0 && !ArchipelagoFTL::ShopLocked(entry.first)) ++open;
        }
        int spare = std::max(0, count + 1 - open);
        for (auto& entry : blueprints) {
            int& rarity = entry.second.desc.rarity;
            if (rarity <= 0 || !ArchipelagoFTL::ShopLocked(entry.first)) continue;
            if (spare > 0) {
                --spare;
                continue;
            }
            hidden.push_back(std::make_pair(&rarity, rarity));
            rarity = 0;
        }
    }

    ~LockedLeftOut()
    {
        for (auto& entry : hidden) *entry.first = entry.second;
    }

private:
    std::vector<std::pair<int*, int>> hidden;
};
}

HOOK_METHOD_PRIORITY(Store, CreateStoreBoxes, -1000, (int category, Equipment* equip) -> void)
{
    LOG_HOOK("HOOK_METHOD -> Store::CreateStoreBoxes -> Begin (ArchipelagoHooks.cpp)\n")
    storeDrawing = true;
    {
        // The store itself picks its systems by rarity, with none needed: the locked ones just go. Those it always
        // offers ignore this, and are greyed out below.
        LockedLeftOut<decltype(G_->GetBlueprints()->systemBlueprints)> systems(G_->GetBlueprints()->systemBlueprints, -1);
        super(category, equip);
    }
    storeDrawing = false;
}

HOOK_METHOD(BlueprintManager, GetRandomWeapon, (int count, bool demo_lock) -> std::vector<WeaponBlueprint*>)
{
    LOG_HOOK("HOOK_METHOD -> BlueprintManager::GetRandomWeapon -> Begin (ArchipelagoHooks.cpp)\n")
    LockedLeftOut<decltype(weaponBlueprints)> leftOut(weaponBlueprints, count);
    return super(count, demo_lock);
}

HOOK_METHOD(BlueprintManager, GetRandomDrone, (int count, bool demo_lock) -> std::vector<DroneBlueprint*>)
{
    LOG_HOOK("HOOK_METHOD -> BlueprintManager::GetRandomDrone -> Begin (ArchipelagoHooks.cpp)\n")
    LockedLeftOut<decltype(droneBlueprints)> leftOut(droneBlueprints, count);
    return super(count, demo_lock);
}

HOOK_METHOD(BlueprintManager, GetRandomAugment, (int count, bool demo_lock) -> std::vector<AugmentBlueprint*>)
{
    LOG_HOOK("HOOK_METHOD -> BlueprintManager::GetRandomAugment -> Begin (ArchipelagoHooks.cpp)\n")
    LockedLeftOut<decltype(augmentBlueprints)> leftOut(augmentBlueprints, count);
    return super(count, demo_lock);
}

HOOK_METHOD(StoreBox, MouseClick, (int x, int y) -> void)
{
    LOG_HOOK("HOOK_METHOD -> StoreBox::MouseClick -> Begin (ArchipelagoHooks.cpp)\n")
    if (!BoxLocked(this)) super(x, y);
}

// Only the boxes of the page shown are drawn: the others loop too, under the same mouse position.
HOOK_METHOD(StoreBox, OnRender, () -> void)
{
    LOG_HOOK("HOOK_METHOD -> StoreBox::OnRender -> Begin (ArchipelagoHooks.cpp)\n")
    super();
    if (count <= 0 || !BoxLocked(this)) return;
    const Point mouse = G_->GetMouseControl()->position;
    const Globals::Rect& area = button.hitbox;
    if (mouse.x >= area.x && mouse.x < area.x + area.w && mouse.y >= area.y && mouse.y < area.y + area.h) {
        G_->GetMouseControl()->SetTooltip(ArchipelagoFTL::ShopLockTip());
    }
}

// A system's box has no pBlueprint to go by: its type names it.
HOOK_METHOD(SystemStoreBox, CanHold, () -> bool)
{
    LOG_HOOK("HOOK_METHOD -> SystemStoreBox::CanHold -> Begin (ArchipelagoHooks.cpp)\n")
    return !ArchipelagoFTL::ShopLocked(ShipSystem::SystemIdToName(type)) && super();
}

HOOK_METHOD(SystemStoreBox, Activate, () -> void)
{
    LOG_HOOK("HOOK_METHOD -> SystemStoreBox::Activate -> Begin (ArchipelagoHooks.cpp)\n")
    if (!ArchipelagoFTL::ShopLocked(ShipSystem::SystemIdToName(type))) super();
}

HOOK_METHOD(SystemStoreBox, MouseMove, (int mX, int mY) -> void)
{
    LOG_HOOK("HOOK_METHOD -> SystemStoreBox::MouseMove -> Begin (ArchipelagoHooks.cpp)\n")
    super(mX, mY);
    const Globals::Rect& area = button.hitbox;
    if (count > 0 && ArchipelagoFTL::ShopLocked(ShipSystem::SystemIdToName(type)) && mX >= area.x
        && mX < area.x + area.w && mY >= area.y && mY < area.y + area.h) {
        G_->GetMouseControl()->SetTooltip(ArchipelagoFTL::ShopLockTip());
    }
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

// FTL's hangar never asks whether a base game ship's Type A is unlocked: seeing the ship means having it. With
// independent layouts a Type B or C can come without it, so a Type A not unlocked is greyed out like a locked
// B or C, and the hangar moves to the ship's first unlocked layout instead of showing it.
namespace
{
bool LayoutUnlocked(int shipType, int variant)
{
    if (shipType >= 100) {
        std::string name = CustomShipSelect::GetInstance()->GetShipBlueprint(shipType);
        return !name.empty() && CustomShipUnlocks::instance->GetCustomShipUnlocked(name, variant);
    }
    return G_->GetScoreKeeper()->GetShipUnlocked(shipType, variant);
}
}

HOOK_METHOD(ShipBuilder, SwitchShip, (int shipType, int shipVariant) -> void)
{
    LOG_HOOK("HOOK_METHOD -> ShipBuilder::SwitchShip -> Begin (ArchipelagoHooks.cpp)\n")
    if (shipVariant == 0 && !LayoutUnlocked(shipType, 0)) {
        for (int variant = 1; variant <= 2; ++variant) {
            if (LayoutUnlocked(shipType, variant)) {
                shipVariant = variant;
                break;
            }
        }
    }
    super(shipType, shipVariant);
    if (!LayoutUnlocked(currentShipId, 0)) {
        typeA.bActive = false;
        typeA.bRenderOff = true;
        typeA.bRenderSelected = false;
    }
}

// The chat of the dashboard takes what FTL reads as typed text: the SDL key codes the Lua sees only name
// the keys of a US keyboard, so an AZERTY player got "&" for "1".
HOOK_METHOD_PRIORITY(CApp, OnTextInput, 1000, (int charCode) -> void)
{
    LOG_HOOK("HOOK_METHOD_PRIORITY -> CApp::OnTextInput -> Begin (ArchipelagoHooks.cpp)\n")
    if (!ArchipelagoFTL::textCapture) {
        super(charCode);
        return;
    }
    unsigned int c = (unsigned int)charCode;
    if (c < 32 || c == 127 || c > 0x10FFFF || ArchipelagoFTL::typedText.size() > 256) return;
    std::string& out = ArchipelagoFTL::typedText;
    if (c < 0x80) {
        out += (char)c;
    } else if (c < 0x800) {
        out += (char)(0xC0 | (c >> 6));
        out += (char)(0x80 | (c & 0x3F));
    } else if (c < 0x10000) {
        out += (char)(0xE0 | (c >> 12));
        out += (char)(0x80 | ((c >> 6) & 0x3F));
        out += (char)(0x80 | (c & 0x3F));
    } else {
        out += (char)(0xF0 | (c >> 18));
        out += (char)(0x80 | ((c >> 12) & 0x3F));
        out += (char)(0x80 | ((c >> 6) & 0x3F));
        out += (char)(0x80 | (c & 0x3F));
    }
}
