from __future__ import annotations

import re
from dataclasses import dataclass, fields
from typing import Iterable

from Options import (
    Choice,
    DeathLink,
    DefaultOnToggle,
    OptionError,
    OptionGroup,
    OptionSet,
    PerGameCommonOptions,
    Range,
    StartInventoryPool,
    Toggle,
    Visibility,
)

from . import data


# Kept out of the Options Creator and the simple options page: still in the YAML and the advanced page.
EXPERT = Visibility.template | Visibility.complex_ui | Visibility.spoiler


def _option_key(display: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", display.lower()).strip("_")


class Goal(Choice):
    """What finishes your game.

    victory_count: beat the Flagship with Victories Required different ships.
    victory_selection: beat the Flagship with each ship listed in Victory Layouts.
    """

    display_name = "Goal"
    visibility = EXPERT
    option_victory_count = 0
    option_victory_selection = 1
    alias_ship_win_count = option_victory_count
    alias_ship_win_selection = option_victory_selection
    default = option_victory_count


class VictoriesRequired(Range):
    """How many times you must beat the Flagship to finish, each time with a different ship layout
    (Kestrel A and Kestrel B count as two).

    This is what decides how long your game is. 5 is a good length when you play with friends, 1 or 2 for a
    first game. Ignored when Goal is victory_selection.
    """

    display_name = "Victories Required"
    range_start = 1
    range_end = len(data.LAYOUTS)
    default = 5


_LAYOUT_BY_DISPLAY: dict[str, data.Layout] = {layout.display: layout for layout in data.LAYOUTS}
_LAYOUT_SHORT_NAMES: dict[str, data.Layout] = {
    f"{layout.display.split()[0]} {layout.letter}": layout for layout in data.LAYOUTS
}


class VictoryDifficulty(Choice):
    """The lowest difficulty a victory must be played on to count for your goal.

    any: every victory counts, Easy too. You can also write easy. Pick it if you usually play on Easy.
    normal: Normal or Hard.
    hard: only Hard.

    An easier victory still sends its check, it just does not count for the goal.
    """

    display_name = "Victory Difficulty"
    option_any = 0
    option_normal = 1
    option_hard = 2
    alias_easy = option_any
    default = option_normal


class Archives(Range):
    """How many Archives are hidden in the multiworld, in your own world or in the other players'.

    Archives are items you need on top of your victories to finish. 0 plays without them.
    """

    display_name = "Archives"
    range_start = 0
    range_end = data.MAX_ARCHIVES
    default = 12


class ArchivesRequired(Range):
    """How many Archives you need to finish.

    Keep it a little lower than Archives, so one Archive in a bad place cannot block you. If it is higher
    than Archives, every Archive is needed.
    """

    display_name = "Archives Required"
    range_start = 0
    range_end = data.MAX_ARCHIVES
    default = 10


class VictoryLayouts(OptionSet):
    __doc__ = (
        "Which ship layouts must each defeat the Flagship for your goal to be complete.\n"
        "\n"
        "    Only used when Goal is victory_selection.\n"
        "\n"
        "    Valid keys: "
        + ", ".join(f'"{layout.display}"' for layout in data.LAYOUTS)
        + ".\n"
        "\n"
        "    The short spelling the Manual FTL world used is accepted too, so "
        f'"{data.LAYOUTS[0].display.split()[0]} {data.LAYOUTS[0].letter}" reads the same as '
        f'"{data.LAYOUTS[0].display}".\n'
        "\n"
        "    Every layout you list must be part of the seed, so keep Ship Layouts wide enough to "
        "contain them."
    )

    display_name = "Victory Layouts"
    visibility = EXPERT
    valid_keys = sorted({*_LAYOUT_BY_DISPLAY, *_LAYOUT_SHORT_NAMES})
    default = frozenset()


_SHIP_BY_DISPLAY: dict[str, data.Ship] = {ship.display: ship for ship in data.SHIPS}


class ExcludedLayouts(OptionSet):
    __doc__ = (
        "Ships or layouts you never want in the seed: no key, no check, no victory with them.\n"
        "\n"
        "    Name a whole ship (\"Engi Cruiser\") or one layout (\"Engi Cruiser B\", or \"Engi B\"). Leaving out "
        "a Type A leaves out its whole ship, since the hangar opens a ship by its Type A.\n"
        "\n"
        f"    Your starting ship and the {data.LAYOUTS_BY_BLUEPRINT[data.ALWAYS_UNLOCKED_LAYOUTS[0]].display} are always "
        "in the seed and cannot be left out, nor can a layout listed in Victory Layouts.\n"
        "\n"
        "    Valid keys: "
        + ", ".join(f'"{ship.display}"' for ship in data.SHIPS)
        + ", and any layout name, like those of Victory Layouts."
    )

    display_name = "Excluded Ships and Layouts"
    valid_keys = sorted({*_SHIP_BY_DISPLAY, *_LAYOUT_BY_DISPLAY, *_LAYOUT_SHORT_NAMES})
    default = frozenset()


def excluded_layouts(options: "FTLOptions") -> frozenset[str]:
    """The blueprints of the layouts the player left out, a Type A taking its whole ship with it."""
    out: set[str] = set()
    for key in getattr(options, "excluded_layouts", ExcludedLayouts(frozenset())).value:
        ship = _SHIP_BY_DISPLAY.get(key)
        layout = _LAYOUT_BY_DISPLAY.get(key) or _LAYOUT_SHORT_NAMES.get(key)
        if layout is not None and layout.variant == 0:
            ship = data.SHIPS_BY_BLUEPRINT[layout.ship]
        if ship is not None:
            out.update(other.blueprint for other in data.LAYOUTS if other.ship == ship.blueprint)
        elif layout is not None:
            out.add(layout.blueprint)
    return frozenset(out)


_START_SHIP_DEFAULT = data.SHIPS_BY_BLUEPRINT[
    data.LAYOUTS_BY_BLUEPRINT[data.ALWAYS_UNLOCKED_LAYOUTS[0]].ship
]

StartShip = type(
    "StartShip",
    (Choice,),
    {
        "__module__": __name__,
        "__qualname__": "StartShip",
        "__doc__": (
            "The ship you start with. The Kestrel Cruiser is always unlocked too.\n\n"
            "    You get the Type A layout; Type B and C are found like the other ships'."
        ),
        "display_name": "Starting Ship",
        "default": _START_SHIP_DEFAULT.slot,
        **{f"option_{_option_key(ship.display)}": ship.slot for ship in data.SHIPS},
        **{f"alias_{_option_key(ship.display.split()[0])}": ship.slot for ship in data.SHIPS},
    },
)


class ShipLayouts(Choice):
    """Every ship has up to three layouts (Type A, B and C). Which ones are in the game.

    type_a_only: only Type A. A smaller game.
    up_to_type_b: Type A and B.
    all_layouts: all of them. The biggest game.
    """

    display_name = "Ship Layouts"
    option_type_a_only = 0
    option_up_to_type_b = 1
    option_all_layouts = 2
    default = option_all_layouts


class LayoutCount(Range):
    """How many ship layouts are in the seed, drawn at random among those Ship Layouts allows.

    Your starting ship and the Kestrel Cruiser A are always in, and a Type B or C only comes with its
    ship's Type A. The others are left out: no key, no check. Raised to Victories Required if lower.
    """

    display_name = "Layouts in the Seed"
    range_start = 1
    range_end = len(data.LAYOUTS)
    default = 7


class LayoutUnlocks(Choice):
    """How the Type B and Type C layouts become available.

    items: each layout is its own Archipelago item, and you also need the ship's key to fly it.
    vanilla: layouts unlock the way FTL does it, by earning that ship's achievements. No layout
    items are created, and owning a ship key puts every one of its layouts in logic.
    independent: each layout is its own item and needs nothing else: a Type B or C can be flown
    without the ship's key, which only gives the Type A.
    progressive: no layout items. The ship's key comes once per layout of that ship in the seed: the
    first copy gives the Type A, the next ones the following layouts in order (B, then C).
    """

    display_name = "Layout Unlocks"
    option_items = 0
    option_vanilla = 1
    option_independent = 2
    option_progressive = 3
    default = option_items


class EarlyShipKeys(Range):
    """How many ship keys, on top of your starting ship and the Kestrel, are placed in your own first checks.

    Those keys are drawn at random among the ships in the seed and land in checks you can reach from the
    very start, in your own world: a second ship comes early instead of hours later. The number of keys
    does not change, only where they land. With progressive layout unlocks, it is the first copy (Type A).
    0 lets every key land anywhere, like before.
    """

    display_name = "Early Ship Keys"
    range_start = 0
    range_end = len(data.SHIPS) - 1
    default = 1


class Sectorsanity(Choice):
    """Reaching a sector with a ship sends a check. Most checks come from here.

    disabled: never.
    milestones: only sectors 5 and 8.
    full: every sector. First and Last Sector, in the advanced options, set the range.
    """

    display_name = "Sectorsanity"
    option_disabled = 0
    option_milestones = 1
    option_full = 2
    alias_none = option_disabled
    alias_five_and_eight = option_milestones
    alias_all = option_full
    default = option_full


class SectorsanityFirstSector(Range):
    """The shallowest sector that is worth a check. Must not be higher than Sectorsanity Last Sector.

    Sectors below this one send nothing, whatever Sectorsanity says. Raising it is the cheapest
    way to trim a seed: with every layout in play, sectors 1 and 2 alone are 56 checks that you
    collect just by taking off.
    """

    display_name = "Sectorsanity First Sector"
    range_start = 1
    range_end = data.SECTOR_COUNT
    default = 2


class SectorsanityLastSector(Range):
    """The deepest sector that is worth a check.

    Sectors beyond this one send nothing. This is the option that decides how LONG your seed is,
    where Sectorsanity First Sector decides how much of the shallow filler it carries.

    Why it matters: a check at sector 8 costs a whole run to collect - forty-five minutes, and
    only if you survive. A check at sector 4 falls out of a run you were playing anyway. Lowering
    this to 5 or 6 keeps the same number of layouts in play while cutting the tail of the seed,
    which is the part that makes a multiworld wait for you.

    Leaving it at 8 is the full experience, and the right setting when FTL is your only game.
    """

    display_name = "Sectorsanity Last Sector"
    range_start = 1
    range_end = data.SECTOR_COUNT
    default = data.SECTOR_COUNT


class VictoryCollectsLayout(Choice):
    """What beating the Flagship with a layout also sends, among its checks still due.

    off: nothing more than the victory.
    sectors: every sector check of that layout.
    everything: its sector checks, and its ship's achievements, per-ship system checks and fight checks.
    """

    display_name = "Victory Collects the Layout"
    option_off = 0
    option_sectors = 1
    option_everything = 2
    alias_false = 0
    alias_true = 1
    default = option_sectors


class CombatChecks(Range):
    """Winning fights sends checks: with each ship, the first fights you win in a run (by destroying the enemy
    or killing its crew) send "Fight 1 won", "Fight 2 won"... up to this number. 0 turns them off.
    A fight that sends a check gives less scrap (see Combat Check Scrap); missiles, fuel and drone parts stay.
    """

    display_name = "Combat Checks per Ship"
    range_start = 0
    range_end = 10
    default = 0


class CombatCheckScrap(Range):
    """The percentage of a fight's scrap you still get when that fight sends a combat check.
    Fights that send nothing keep their full reward.
    """

    display_name = "Combat Check Scrap (%)"
    range_start = 0
    range_end = 100
    default = 50


class CrewChecks(DefaultOnToggle):
    """The first crew member of each race to join you sends a check: Human, Engi, Zoltan,
    Mantis, Rock, Slug and Lanius. 7 checks.
    """

    display_name = "Crew Checks"


class CrewMembers(DefaultOnToggle):
    """Crew members as progressive items, one per race, received like weapons.

    First copy: a crew member of that race joins your current run.
    Second copy: that race enters the Archipelago menu that opens at the first beacon of every run, where
    you may take one crew member per run.
    Third copy: the menu offers an expert instead, one skill mastered (Human pilot, Engi engines, Zoltan
    shields, Mantis combat, Rock repair, Slug weapons). Lanius and Crystal stop at two copies.
    """

    display_name = "Crew Members"


class Systemsanity(Choice):
    """Installing a system sends a check.

    disabled: never. The default: most ships start with half of the systems.
    first_install: once per system, 16 checks.
    every_level: every upgrade level too, 68 checks. A much longer game.
    """

    display_name = "Systemsanity"
    option_disabled = 0
    option_first_install = 1
    option_every_level = 2
    alias_none = option_disabled
    alias_install = option_first_install
    alias_levels = option_every_level
    default = option_disabled


class SystemsanityPerShip(Toggle):
    """With Systemsanity on: each ship has its own Install checks, like "Kestrel Cruiser: Install Cloaking".
    A ship never has a check for a system it can start with. The level checks of every_level stay shared.
    """

    display_name = "Systemsanity per Ship"


class ShipAchievementChecks(DefaultOnToggle):
    """Each ship's three achievements send a check, 30 in all.
    """

    display_name = "Ship Achievement Checks"


class GeneralAchievementChecks(Choice):
    """Which of the 21 general achievements send a check.

    disabled: none.
    basic: the easy ones, like reaching sector 8.
    most: also the harder ones earned over a run.
    all: every one, the very hard ones too.
    """

    display_name = "General Achievement Checks"
    option_disabled = 0
    option_basic = 1
    option_most = 2
    option_all = 3
    default = option_most


class CrossRunAchievementChecks(Toggle):
    """Whether the three achievements that cannot be earned inside a single run are checks.

    They are "Rule Ten: Greed is Eternal" (10,000 scrap across all games), "Warlord" (1000 ships
    destroyed across all playthroughs) and "Your Own Fleet" (unlock every ship). Leaving this off
    is strongly recommended for a short seed: the first two may simply never happen.
    """

    display_name = "Cross-Run Achievement Checks"


class SystemBlueprints(DefaultOnToggle):
    """Whether system blueprints are items.

    Without a system's blueprint, stores will not sell you that system, and a system your ship
    starts with stays at level 1 until Archipelago sends you the blueprint: it is never torn out,
    only capped.

    Turning this off also silences the five per-system blueprint logic options below, and leaves
    Sector Logic with only the power milestones to require, if Progressive System Upgrades is on.
    """

    display_name = "System Blueprints"


class ProgressiveSystems(DefaultOnToggle):
    """Whether progressive system upgrades are items.

    Each copy raises how far you may upgrade that system, up to the vanilla maximum.
    """

    display_name = "Progressive System Upgrades"


class ProgressiveSystemsPerShip(Toggle):
    """With Progressive System Upgrades on: the upgrades belong to one ship each, like "Kestrel Cruiser:
    Progressive Shields", and only raise that ship's systems. Many more items: when the shop would pass 400
    slots, the last copies of useful items are left out instead of refusing the seed.
    """

    display_name = "Progressive Upgrades per Ship"


class FullSystemUpgrades(Toggle):
    """Each Progressive system item gives every upgrade level of its system at once, instead of one level.

    Fewer items, so a smaller Archipelago shop, but a coarser progression.
    """

    display_name = "Full System Upgrades"


class FreeUpgrades(Toggle):
    """System upgrade levels you receive are installed for free: right away if you are in a run, and again at
    the start of every run. Off: a received level only lets you buy it at a store.
    Only matters with Progressive System Upgrades on.
    """

    display_name = "Free Upgrades"


class SystemInstall(Choice):
    """When a system whose blueprint you received is put aboard, for free, if your ship has a place for it.
    Only matters with System Blueprints on.

    store: never for free, you buy it at a store (the base game way).
    run_start: at the start of every run.
    immediately: at the start of every run, and as soon as the blueprint arrives during a run.
    """

    display_name = "System Install"
    option_store = 0
    option_run_start = 1
    option_immediately = 2
    default = option_store


class RunStartScrap(Range):
    """At the start of every run, you get this percentage of all the scrap items you received so far.
    Scrap items still give their scrap once when they arrive. Off by default (0). If you turn it on, 10 to 25
    is a good range.
    """

    display_name = "Run Start Scrap (%)"
    range_start = 0
    range_end = 100
    default = 0


class HeadStarts(DefaultOnToggle):
    """Head Start items give a free system level, or a reactor bar, at the start of every
    future run. They make each new run a little stronger.
    """

    display_name = "Head Starts"


class TrapChance(Range):
    """Percentage of filler items that become traps: fire, hull breach, boarding party and
    more. 0 means no traps.

    Traps wait for a quiet beacon and never destroy your ship on their own.
    """

    display_name = "Trap Chance"
    range_start = 0
    range_end = 100
    default = 0


class SectorLogic(Choice):
    """What the logic expects of your ship before sending you deep into the sectors.

    none: no requirement at all. Every sector and every victory is in logic as soon as the layout is, so the
    generator may expect you to reach the Flagship with little more than your starting ship. For experienced
    players. ("relaxed", its old name, still works.)
    standard: 2 system blueprints received for sector 4, 4 for sector 6, 5 for the Flagship.
    strict: 3 blueprints for sector 3, 6 for sector 5, 9 for sector 7, 11 for the Flagship.
    power: milestones on the ship that does the check, from its real start. Sector 5 needs 2 shield
    layers, sector 8 also Weapon Control 5, the Flagship 3 layers, Weapon Control 6 and Engines 4. A ship
    that starts without shields may use Engines 5 for one layer before the Flagship. Lower with Victory
    Difficulty "any", higher with "hard" (4 layers for the Flagship).

    With Progressive System Upgrades on, standard and strict also ask the power milestones on top of their
    blueprints, and become power if System Blueprints is off.

    This never changes what the game allows, only what the generator considers fair. standard and strict
    count blueprints without caring which, and do nothing more if both System Blueprints and Progressive
    System Upgrades are off. power reads upgrade levels, so it matters most with Progressive System Upgrades on.
    """

    display_name = "Sector Logic"
    option_none = 0
    alias_relaxed = 0
    option_standard = 1
    option_strict = 2
    option_power = 3
    default = option_standard


class _GatingBlueprintLogic(Choice):
    """Base class for the "this blueprint can gate a ship" option cursors.

    Do not add a user docstring here: Archipelago only exposes the classes listed in the
    dataclass, and each of them brings its own.
    """

    visibility = EXPERT
    option_required = 0
    option_upgrade_only = 1
    option_start_with = 2
    default = option_upgrade_only


class _PlacementBlueprintLogic(Choice):
    """Base class for the "this blueprint does not gate anything, it is placed early or not" cursors."""

    visibility = EXPERT
    option_anywhere = 0
    option_early = 1
    option_start_with = 2
    default = option_early


class ShieldsBlueprintLogic(_GatingBlueprintLogic):
    """Shields blueprint logic.

    required: a ship whose starting layout includes Shields is only in logic once you hold the
    blueprint. Ships built without the system - the Stealth Cruiser - stay available.
    upgrade_only: the blueprint is not needed to fly a ship that starts with Shields, only to
    raise the system above level 1 or to buy it in a store.
    start_with: you begin the multiworld holding the blueprint.
    """

    system = "shields"
    display_name = f"{data.SYSTEMS_BY_ID[system].display} blueprint logic"


class SensorsBlueprintLogic(_GatingBlueprintLogic):
    """Sensors blueprint logic.

    required: a ship whose starting layout includes Sensors is only in logic once you hold the
    blueprint. Layouts built without the system stay available: every Slug layout, the Mantis
    Cruiser A, the Lanius Cruiser B, the Engi Cruiser B and the Stealth Cruiser C.
    upgrade_only: the blueprint is not needed to fly a ship that starts with Sensors, only to
    raise the system above level 1 or to buy it in a store.
    start_with: you begin the multiworld holding the blueprint.
    """

    system = "sensors"
    display_name = f"{data.SYSTEMS_BY_ID[system].display} blueprint logic"


class MedbayBlueprintLogic(_GatingBlueprintLogic):
    """Medbay blueprint logic.

    required: a ship whose starting layout includes a Medbay is only in logic once you hold the
    blueprint. Ships that heal with a Clone Bay instead - the Lanius Cruiser among others - stay
    available.
    upgrade_only: the blueprint is not needed to fly a ship that starts with a Medbay, only to
    raise the system above level 1 or to buy it in a store.
    start_with: you begin the multiworld holding the blueprint.
    """

    system = "medbay"
    display_name = f"{data.SYSTEMS_BY_ID[system].display} blueprint logic"


class EnginesBlueprintLogic(_PlacementBlueprintLogic):
    """Engines blueprint logic.

    Every ship in FTL starts with Engines, so this blueprint can never gate a ship: it only
    decides whether you may upgrade the system. What it does control is how early you get it.

    anywhere: no restriction on where the blueprint is placed.
    early: the blueprint is placed in an early sphere, so your first runs can already grow.
    start_with: you begin the multiworld holding the blueprint.
    """

    system = "engines"
    display_name = f"{data.SYSTEMS_BY_ID[system].display} blueprint logic"


class WeaponsBlueprintLogic(_PlacementBlueprintLogic):
    """Weapon Control blueprint logic.

    Every ship in FTL starts with Weapon Control, so this blueprint can never gate a ship: it
    only decides whether you may upgrade the system. What it does control is how early you get
    it, and a capped weapons system is the harshest cap of all.

    anywhere: no restriction on where the blueprint is placed.
    early: the blueprint is placed in an early sphere, so your first runs can already grow.
    start_with: you begin the multiworld holding the blueprint.
    """

    system = "weapons"
    display_name = f"{data.SYSTEMS_BY_ID[system].display} blueprint logic"


BLUEPRINT_LOGIC_OPTIONS: tuple[type[Choice], ...] = (
    ShieldsBlueprintLogic,
    SensorsBlueprintLogic,
    MedbayBlueprintLogic,
    EnginesBlueprintLogic,
    WeaponsBlueprintLogic,
)


class ShopWeapons(Range):
    """How many of FTL's weapons are handed out by Archipelago instead of found in shops.

    The default is all of them: a weapon you have not received is not for sale anywhere. Lower it
    to leave part of the arsenal to ordinary shopping, or set 0 to leave weapons alone entirely.
    """

    display_name = "Shop Weapons"
    range_start = 0
    range_end = len(data.SHOP_ITEMS_BY_FAMILY["weapon"])
    default = len(data.SHOP_ITEMS_BY_FAMILY["weapon"])


class ShopDrones(Range):
    """How many drones are handed out by Archipelago instead of found in shops.

    Drones are the narrowest choice: they are useless until you own Drone Control, so a seed that
    leans on them should make sure that blueprint is reachable early.
    """

    display_name = "Shop Drones"
    range_start = 0
    range_end = len(data.SHOP_ITEMS_BY_FAMILY["drone"])
    default = len(data.SHOP_ITEMS_BY_FAMILY["drone"])


class ShopAugments(Range):
    """How many augmentations are handed out by Archipelago instead of found in shops."""

    display_name = "Shop Augments"
    range_start = 0
    range_end = len(data.SHOP_ITEMS_BY_FAMILY["augment"])
    default = len(data.SHOP_ITEMS_BY_FAMILY["augment"])


class _BundleSize(Range):
    range_start = 1
    range_end = 5


class WeaponBundleSize(_BundleSize):
    """How many weapons each Weapon Bundle holds. A bundle unlocks all of them at once.

    1 means no bundles: every weapon is its own item. Bigger bundles mean fewer items, so a smaller
    Archipelago shop.
    """

    display_name = "Weapon Bundle Size"
    default = 3


class DroneBundleSize(_BundleSize):
    """How many drones each Drone Bundle holds. 1 means no bundles."""

    display_name = "Drone Bundle Size"
    default = 2


class AugmentBundleSize(_BundleSize):
    """How many augments each Augment Bundle holds. 1 means no bundles."""

    display_name = "Augment Bundle Size"
    default = 3


class ShopUnlockMode(Choice):
    """What receiving a shop item does.

    rarity_boost: the item already appears in shops; receiving it makes it noticeably more
    common, and each extra copy more common still. Nothing is ever taken away from you.

    locked: the item is removed from every shop until you receive it. Harsher, and much more of
    a moment when it finally arrives - this is the mode where finding a Burst Laser II in a shop
    means another world sent it to you.
    """

    display_name = "Shop Unlock Mode"
    option_rarity_boost = 0
    option_locked = 1
    default = option_rarity_boost


class ShopItemDelivery(DefaultOnToggle):
    """Whether a shop item is also handed to you on the spot, once.

    On: the weapon lands in your cargo hold at the next safe beacon, as well as becoming
    available in shops forever. Off: it only changes what shops offer, and you still have to buy
    it.

    On is the default because an item you can only benefit from an hour later does not feel like
    a gift. Turn it off for a longer, more deliberate seed.
    """

    display_name = "Shop Item Delivery"


class ShopChecks(Range):
    """The smallest number of packages in the Archipelago shop, a special shop at one beacon
    per sector. Buying a package sends it to the player it belongs to.

    This is a total for the whole shop, not a number per ship. If your options create more items
    than there are checks, packages are added by themselves (up to 400) until every item has a
    place. With Archipelago Shop per Ship, the packages are then split between the ships.
    """

    display_name = "Archipelago Shop Checks (minimum)"
    range_start = 0
    range_end = 100
    default = 20


class ShopBySector(Toggle):
    """Each package of the Archipelago shop belongs to one sector, 1 to 7, and is only sold at the Archipelago
    beacon of that sector. The logic expects you to reach that sector first.

    Off (default): every Archipelago beacon sells from the whole shop.
    """

    display_name = "Archipelago Shop by Sector"


class ShopPerShip(Choice):
    """Each package of the Archipelago shop belongs to one ship, and is only sold while you fly it.
    This adds no packages: the shop's packages are split between the ships.

    off: every ship sees the whole shop.
    per_class: one owner per ship, whatever its layout (Kestrel).
    per_layout: one owner per layout (Kestrel B).
    """

    display_name = "Archipelago Shop per Ship"
    option_off = 0
    option_per_class = 1
    option_per_layout = 2
    default = option_off


class MinimumFiller(Range):
    """The minimum number of filler items (scrap, fuel, missiles, drone parts) in your seed.

    The seed balances itself: when your options create more checks than items, filler is added until
    every check holds something. This number is the floor.
    """

    display_name = "Minimum Filler"
    visibility = EXPERT
    range_start = 0
    range_end = 100
    default = 20


class EnergyLink(Toggle):
    """Share a fuel reserve with the other Energy Link players. Your extra fuel goes in, and
    you get some back when you are almost out.
    """

    display_name = "Energy Link"


class TrapLink(Toggle):
    """Traps are shared with the other Trap Link players: when one of you gets a trap, the
    others get one too, even if your own game has no traps.
    """

    display_name = "Trap Link"


class DeathLinkTrigger(Choice):
    """With Death Link on: what sends your death to the other players.

    ship_destroyed: only losing the run. Best in a big multiworld or for a first game.
    crew_death: losing any crew member.
    both: either one. Crew members die often, so this sends a lot of deaths.
    """

    display_name = "Death Link Trigger"
    option_ship_destroyed = 0
    option_crew_death = 1
    option_both = 2
    default = option_both
    alias_run_lost = option_ship_destroyed
    alias_hull_destroyed_only = option_ship_destroyed
    alias_any_crew_death = option_both


class DeathLinkClonedCrew(Toggle):
    """With Death Link on: whether a crew member the Clone Bay brings back counts as a death.

    Off: only a crew member who does not come back sends a death, for example when the Clone Bay has no
    power at the jump or the last crew member dies.
    On: every crew death is sent, even one the Clone Bay will undo.
    """

    display_name = "Death Link Cloned Crew"


class DeathLinkEffect(Choice):
    """With Death Link on: what a death from another player does to you. None of them can
    destroy your ship or kill your last crew member.

    major_incident: a breach and a fire in a system room. The hardest one.
    crew_member: one crew member dies.
    hull_damage: your hull takes damage.
    fire: a fire starts somewhere.
    boarding: one enemy Mantis comes aboard.
    varied: one of the four milder ones, at random each time.
    """

    display_name = "Death Link Effect"
    option_crew_member = 0
    option_hull_damage = 1
    option_fire = 2
    option_varied = 3
    option_major_incident = 4
    option_boarding = 5
    default = option_major_incident


class EventBeacons(Choice):
    """Which Archipelago event beacons say ARCHIPELAGO on the map. The AP STORE beacons always do.

    marked: every Archipelago event is labelled.
    important: only the events that carry a package (the package relay and the pirates) are labelled. The
    Zoltan toll, the Slug's hints and the surge from another world look like any beacon until you visit them.
    hidden: no Archipelago event is labelled: they all hide among the normal beacons.
    """

    display_name = "Event Beacons"
    option_marked = 0
    option_important = 1
    option_hidden = 2
    default = option_important


class CrewNames(Choice):
    """Names given to the crew members who join you during a run. Your starting crew keeps its names.

    vanilla: FTL's own names.
    multiworld: the other players of the multiworld first, by their slot names, then FTL's own names once
    each of them is aboard.
    multiworld_and_team: the same, then the people who made and tested this mod.
    """

    display_name = "Crew Names"
    option_vanilla = 0
    option_multiworld = 1
    option_multiworld_and_team = 2
    default = option_multiworld


class ModLanguage(Choice):
    """Language of the mod's messages, menus and shop.

    game: the same as FTL, chosen by itself. Recommended.
    The others force a language, for example to play FTL in English but read the mod in French.

    Item and location names always stay in English, because every player and tracker shares them.
    """

    display_name = "Mod Language"
    option_game = 0
    option_english = 1
    option_french = 2
    option_spanish = 3
    option_german = 4
    option_italian = 5
    option_portuguese = 6
    default = option_game

    MOD_CODES = {
        option_english: "en",
        option_french: "fr",
        option_spanish: "es",
        option_german: "de",
        option_italian: "it",
        option_portuguese: "pt",
    }


@dataclass
class FTLOptions(PerGameCommonOptions):
    start_inventory_from_pool: StartInventoryPool
    death_link: DeathLink
    death_link_trigger: DeathLinkTrigger
    death_link_cloned_crew: DeathLinkClonedCrew
    death_link_effect: DeathLinkEffect
    energy_link: EnergyLink
    trap_link: TrapLink

    mod_language: ModLanguage
    event_beacons: EventBeacons
    crew_names: CrewNames

    goal: Goal
    victories_required: VictoriesRequired
    victory_difficulty: VictoryDifficulty
    archives: Archives
    archives_required: ArchivesRequired
    victory_layouts: VictoryLayouts
    excluded_layouts: ExcludedLayouts
    start_ship: StartShip

    ship_layouts: ShipLayouts
    layout_count: LayoutCount
    layout_unlocks: LayoutUnlocks
    early_ship_keys: EarlyShipKeys

    sectorsanity: Sectorsanity
    sectorsanity_first_sector: SectorsanityFirstSector
    sectorsanity_last_sector: SectorsanityLastSector
    victory_collects_layout: VictoryCollectsLayout
    crew_checks: CrewChecks
    crew_members: CrewMembers
    systemsanity: Systemsanity
    systemsanity_per_ship: SystemsanityPerShip
    ship_achievements: ShipAchievementChecks
    general_achievements: GeneralAchievementChecks
    cross_run_achievements: CrossRunAchievementChecks

    system_blueprints: SystemBlueprints
    progressive_systems: ProgressiveSystems
    full_system_upgrades: FullSystemUpgrades
    free_upgrades: FreeUpgrades
    system_install: SystemInstall
    run_start_scrap: RunStartScrap
    combat_checks: CombatChecks
    combat_check_scrap: CombatCheckScrap
    progressive_systems_per_ship: ProgressiveSystemsPerShip
    head_starts: HeadStarts
    trap_chance: TrapChance
    shop_weapons: ShopWeapons
    shop_drones: ShopDrones
    shop_augments: ShopAugments
    weapon_bundle_size: WeaponBundleSize
    drone_bundle_size: DroneBundleSize
    augment_bundle_size: AugmentBundleSize
    shop_unlock_mode: ShopUnlockMode
    shop_item_delivery: ShopItemDelivery
    shop_checks: ShopChecks
    shop_by_sector: ShopBySector
    shop_per_ship: ShopPerShip
    minimum_filler: MinimumFiller

    sector_logic: SectorLogic
    shields_blueprint_logic: ShieldsBlueprintLogic
    sensors_blueprint_logic: SensorsBlueprintLogic
    medbay_blueprint_logic: MedbayBlueprintLogic
    engines_blueprint_logic: EnginesBlueprintLogic
    weapons_blueprint_logic: WeaponsBlueprintLogic



ftl_option_groups = [
    OptionGroup("Goal", [VictoriesRequired, VictoryDifficulty, Archives, ArchivesRequired]),
    OptionGroup(
        "Game Size",
        [ShipLayouts, LayoutCount, ExcludedLayouts, Sectorsanity, Systemsanity, ShipAchievementChecks, GeneralAchievementChecks,
         CrewChecks, CombatChecks, CombatCheckScrap, ShopChecks],
    ),
    OptionGroup(
        "Playing with Others",
        [DeathLink, DeathLinkTrigger, DeathLinkClonedCrew, DeathLinkEffect, EnergyLink, TrapLink, TrapChance,
         CrewNames],
    ),
    OptionGroup(
        "Advanced",
        [StartShip, HeadStarts, ModLanguage, EventBeacons, SectorsanityFirstSector, SectorsanityLastSector, VictoryCollectsLayout, LayoutUnlocks, EarlyShipKeys, CrossRunAchievementChecks,
         SystemBlueprints, ProgressiveSystems, FullSystemUpgrades, FreeUpgrades, SystemInstall, RunStartScrap, CrewMembers, ShopWeapons, ShopDrones, ShopAugments,
         WeaponBundleSize, DroneBundleSize, AugmentBundleSize,
         ShopUnlockMode, ShopItemDelivery, ShopBySector, ShopPerShip, SystemsanityPerShip,
         ProgressiveSystemsPerShip, SectorLogic],
        start_collapsed=True,
    ),
    OptionGroup(
        "Expert (YAML only)",
        [Goal, VictoryLayouts, MinimumFiller, *BLUEPRINT_LOGIC_OPTIONS],
        start_collapsed=True,
    ),
]


def mod_language(options: FTLOptions) -> str | None:
    return ModLanguage.MOD_CODES.get(options.mod_language.value)


def apply_sector_floor(options: FTLOptions, sectors: Iterable[int]) -> tuple[int, ...]:
    floor = options.sectorsanity_first_sector.value
    ceiling = options.sectorsanity_last_sector.value
    return tuple(sector for sector in sectors if floor <= sector <= ceiling)


def goal_layouts(options: FTLOptions) -> tuple[str, ...] | None:
    if options.goal != Goal.option_victory_selection:
        return None

    chosen: list[str] = []
    for key in sorted(options.victory_layouts.value):
        layout = _LAYOUT_BY_DISPLAY.get(key) or _LAYOUT_SHORT_NAMES.get(key)
        if layout is None:  # pragma: no cover
            raise OptionError(f"FTL: '{key}' is not a playable layout.")
        if layout.blueprint not in chosen:
            chosen.append(layout.blueprint)

    if not chosen:
        raise OptionError(
            "FTL: goal=victory_selection with no layout in victory_layouts. Pick at least one "
            "layout, or set goal back to victory_count."
        )
    return tuple(chosen)


def goal_victory_count(options: FTLOptions) -> int:
    layouts = goal_layouts(options)
    return len(layouts) if layouts is not None else options.victories_required.value


def archives_required(options: FTLOptions) -> int:
    return min(options.archives_required.value, options.archives.value)


def blueprint_logic(options: FTLOptions) -> dict[str, str]:
    if not options.system_blueprints:
        return {}
    return {
        option.system: getattr(options, _field_name(option)).current_key
        for option in BLUEPRINT_LOGIC_OPTIONS
    }


def blueprints_required_to_fly(options: FTLOptions) -> tuple[str, ...]:
    return tuple(
        system for system, value in blueprint_logic(options).items() if value == "required"
    )


def blueprints_gating_layout(options: FTLOptions, layout: data.Layout) -> tuple[str, ...]:
    start_systems = frozenset(layout.start_systems)
    return tuple(
        data.BLUEPRINT_ITEM_NAMES[system]
        for system in blueprints_required_to_fly(options)
        if system in start_systems
    )


def blueprints_in_start_inventory(
    options: FTLOptions,
    guaranteed_layouts: Iterable[data.Layout] = (),
) -> tuple[str, ...]:

    names = [
        data.BLUEPRINT_ITEM_NAMES[system]
        for system, value in blueprint_logic(options).items()
        if value == "start_with"
    ]
    for layout in guaranteed_layouts:
        names.extend(blueprints_gating_layout(options, layout))
    return tuple(dict.fromkeys(names))


def blueprints_placed_early(options: FTLOptions) -> tuple[str, ...]:
    return tuple(
        data.BLUEPRINT_ITEM_NAMES[system]
        for system, value in blueprint_logic(options).items()
        if value == "early"
    )


def _field_name(option: type[Choice]) -> str:
    return f"{option.system}_blueprint_logic"  # type: ignore[attr-defined]


def _check() -> None:
    declared = {field.name: field.type for field in fields(FTLOptions)}

    for option in BLUEPRINT_LOGIC_OPTIONS:
        system = getattr(option, "system")
        if system not in data.SYSTEMS_BY_ID:
            raise ValueError(
                f"{option.__name__} cites system {system!r}, which does not exist in ftl.dat"
            )
        field_name = _field_name(option)
        if declared.get(field_name) != option.__name__:
            raise ValueError(
                f"field {field_name!r} of FTLOptions should be type {option.__name__}, it "
                f"is {declared.get(field_name)!r}"
            )

    shorts = [ship.display.split()[0] for ship in data.SHIPS]
    if len(set(shorts)) != len(shorts):
        raise ValueError(f"ambiguous ship aliases: {sorted(shorts)}")

    for table, label in ((_LAYOUT_BY_DISPLAY, "long"), (_LAYOUT_SHORT_NAMES, "short")):
        if len(table) != len(data.LAYOUTS):
            raise ValueError(f"two layouts share the same {label} name")
    collisions = sorted(set(_LAYOUT_SHORT_NAMES) & set(_LAYOUT_BY_DISPLAY))
    for key in collisions:
        if _LAYOUT_SHORT_NAMES[key] is not _LAYOUT_BY_DISPLAY[key]:
            raise ValueError(f"layout name {key!r} refers to two different layouts")


_check()


def bundle_size(options: FTLOptions, family: str) -> int:
    return {
        "weapon": options.weapon_bundle_size.value,
        "drone": options.drone_bundle_size.value,
        "augment": options.augment_bundle_size.value,
    }[family]


def item_copies(options: FTLOptions, item: data.Item) -> int:
    if item.group == data.GROUP_SYSTEM_LEVELS and item.count and options.full_system_upgrades:
        return 1
    if item.group == data.GROUP_SHIP_KEYS and item.count and progressive_ship_keys(options):
        return max(1, len(progressive_layouts(options, item.ship)))
    return item.count


def progressive_ship_keys(options) -> bool:
    return options.layout_unlocks == options.layout_unlocks.option_progressive


def progressive_layouts(options, ship: str) -> tuple[data.Layout, ...]:
    """The layouts a progressive ship key gives, copy after copy: the seed's layouts of that ship, A first."""
    from . import locations
    return tuple(sorted((layout for layout in locations.selected_layouts(options) if layout.ship == ship),
                        key=lambda layout: layout.variant))
