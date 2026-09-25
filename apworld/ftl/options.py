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
)

from . import data


def _option_key(display: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", display.lower()).strip("_")


class Goal(Choice):
    """What finishes your game.

    victory_count: destroy the Flagship with any Victories Required different ship layouts.
    victory_selection: destroy the Flagship with each of the layouts you listed in Victory
    Layouts, and only those.
    """

    display_name = "Goal"
    option_victory_count = 0
    option_victory_selection = 1
    alias_ship_win_count = option_victory_count
    alias_ship_win_selection = option_victory_selection
    default = option_victory_count


class VictoriesRequired(Range):
    """How many different ship layouts you must defeat the Flagship with.

    Only used when Goal is victory_count. Layouts that your Ship Layouts option leaves out of
    the seed cannot be used for this, so generation fails if you ask for more victories than
    there are layouts in the multiworld.
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
    """The difficulty a victory must be played on to count towards the goal.

    any: every victory counts, whatever difficulty you flew on.
    normal: easy runs still send their check, but only Normal and Hard count for the goal.
    hard: only Hard counts.

    The mod enforces this when you beat the Flagship: it reads the difficulty of the run. The
    victory check is always sent - it is a location like any other - but a run below the bar does
    not bring you closer to the goal.
    """

    display_name = "Victory Difficulty"
    option_any = 0
    option_normal = 1
    option_hard = 2
    default = option_any


class Archives(Range):
    """How many Archipelago Archives exist in the multiworld.

    Archives are a second currency, in the spirit of Tunic's golden trophies: they are items like
    any other, scattered through the other players' worlds, and the Flagship is not enough on its
    own. Set 0 to play without them - victories alone finish the seed.

    You do not need all of them: "Archives Required" says how many finish the seed. The extras are
    slack, so a single unlucky placement cannot strand the goal.
    """

    display_name = "Archives"
    range_start = 0
    range_end = data.MAX_ARCHIVES
    default = 0


class ArchivesRequired(Range):
    """How many Archives your goal asks for.

    Higher than the number that exist is lowered to it. Equal to it means every single Archive is
    required, which is the harshest setting: one Archive behind a long chain gates the whole seed.
    """

    display_name = "Archives Required"
    range_start = 0
    range_end = data.MAX_ARCHIVES
    default = 0


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
    valid_keys = sorted({*_LAYOUT_BY_DISPLAY, *_LAYOUT_SHORT_NAMES})
    default = frozenset()


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
            "Which ship you begin the multiworld with. Its key is handed to you for free.\n\n"
            "    The Kestrel Cruiser is always unlocked on top of your choice: FTL grants it to "
            "every profile and no mod can take it away.\n\n"
            "    Only the Type A layout comes with the key; Type B and Type C follow your "
            "Layout Unlocks option like any other ship's.\n\n"
            "    If a blueprint logic option would lock a ship you are given for free, you "
            "start with that blueprint too, whatever you set the option to. Otherwise there "
            "would be nothing left to fly."
        ),
        "display_name": "Starting Ship",
        "default": _START_SHIP_DEFAULT.slot,
        **{f"option_{_option_key(ship.display)}": ship.slot for ship in data.SHIPS},
        **{f"alias_{_option_key(ship.display.split()[0])}": ship.slot for ship in data.SHIPS},
    },
)


class ShipLayouts(Choice):
    """Which ship layouts take part in the multiworld.

    type_a_only: only the Type A layout of every ship. The smallest, fastest seed.
    up_to_type_b: Type A and Type B layouts.
    all_layouts: every playable layout, Type C included.
    """

    display_name = "Ship Layouts"
    option_type_a_only = 0
    option_up_to_type_b = 1
    option_all_layouts = 2
    default = option_all_layouts


class LayoutUnlocks(Choice):
    """How the Type B and Type C layouts become available.

    items: each layout is its own Archipelago item, independent of the ship key.
    vanilla: layouts unlock the way FTL does it, by earning that ship's achievements. No layout
    items are created, and owning a ship key puts every one of its layouts in logic.
    """

    display_name = "Layout Unlocks"
    option_items = 0
    option_vanilla = 1
    default = option_items


class Sectorsanity(Choice):
    """Whether reaching a sector with a given layout is a check.

    disabled: no sector checks at all. Expect a small seed.
    milestones: only the two sectors FTL itself celebrates, sector 5 and sector 8.
    full: every sector from 1 to 8, for every layout in the seed. This is where most of the
    checks live.

    Use Sectorsanity First Sector to drop the shallow sectors without losing the deep ones.
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
    """The shallowest sector that is worth a check.

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


class CrewChecks(DefaultOnToggle):
    """One check the first time each race joins your crew during a run: Human, Engi, Zoltan, Mantis,
    Rock, Slug and Lanius.

    The crew you start a run with does not count: the check fires when someone new comes aboard, from
    an event, a store or a rescue. Crystal crew are left out, they only come from a rare secret quest.
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
    """Whether installing and upgrading a system is a check.

    "First install" gives one check per system, sixteen in all: the run where you finally buy
    Cloaking pays for itself. "Every level" adds one check per level of every system, sixty-eight
    in all - a much longer seed, and one where every upgrade you buy sends something out.

    Logic follows the game: a system you do not start with needs its blueprint first, and a level
    needs enough Progressive upgrades for that system to allow it.
    """

    display_name = "Systemsanity"
    option_disabled = 0
    option_first_install = 1
    option_every_level = 2
    alias_none = option_disabled
    alias_install = option_first_install
    alias_levels = option_every_level
    default = option_first_install


class ShipAchievementChecks(DefaultOnToggle):
    """Whether each ship's three achievements are checks.

    FTL grants a ship achievement to the ship, not to the layout: earning it with Type A, B or C
    sends the same check.
    """

    display_name = "Ship Achievement Checks"


class GeneralAchievementChecks(Choice):
    """Which of the twenty-one general achievements are checks.

    disabled: none of them.
    basic: only the straightforward ones (reach sector 5, reach sector 8, win the game...).
    most: the above plus the "going the distance" run-long challenges.
    all: every general achievement, including the hardest one-off feats.

    This is the Manual FTL world's three rows of achievements, folded into one option: "most" is
    its going_the_distance, "all" adds its ship_and_equipment_feats.
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

    Without a system's blueprint, that system stays stuck at level 1: you can still install it in
    a store, but it never goes past the first bar until Archipelago sends you the blueprint. A
    ship that starts with the system keeps it: it is never torn out, only capped.

    Turning this off also silences the five per-system blueprint logic options below, and leaves
    Sector Logic with nothing to require.
    """

    display_name = "System Blueprints"


class ProgressiveSystems(DefaultOnToggle):
    """Whether progressive system upgrades are items.

    Each copy raises how far you may upgrade that system, up to the vanilla maximum.
    """

    display_name = "Progressive System Upgrades"


class HeadStarts(DefaultOnToggle):
    """Whether head start items are in the pool.

    A head start gives one free level of a system - or one bar of reactor power - at the
    beginning of every future run. This is what keeps an item useful in a roguelike: without it,
    anything you receive during a run you are about to lose is wasted.
    """

    display_name = "Head Starts"


class TrapChance(Range):
    """Percentage of the filler items that are replaced by traps.

    Traps are applied at the next safe beacon, never in the middle of a fight.
    """

    display_name = "Trap Chance"
    range_start = 0
    range_end = 100
    default = 0


class SectorLogic(Choice):
    """How many system blueprints the logic expects before sending you deep into the sectors.

    relaxed: none. Every sector and every victory is in logic as soon as the layout is.
    standard: deep sectors and the Flagship expect a couple of system blueprints first.
    strict: the logic assumes you want a real ship before sector 3, and a complete one for the
    Flagship.

    This never changes what the game allows, only what the generator considers fair. It counts
    blueprints without caring which, and has no effect if System Blueprints is off. The five
    options below are the opposite: they care about one system each and ignore how many you own.
    """

    display_name = "Sector Logic"
    option_relaxed = 0
    option_standard = 1
    option_strict = 2
    default = option_standard


class _GatingBlueprintLogic(Choice):
    """Base class for the "this blueprint can gate a ship" option cursors.

    Do not add a user docstring here: Archipelago only exposes the classes listed in the
    dataclass, and each of them brings its own.
    """

    option_required = 0
    option_upgrade_only = 1
    option_start_with = 2
    default = option_upgrade_only


class _PlacementBlueprintLogic(Choice):
    """Base class for the "this blueprint does not gate anything, it is placed early or not" cursors."""

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
    """The minimum number of Archipelago shop slots in your seed.

    A shop that sells items *for other players* appears at one beacon in every sector, marked
    ARCHIPELAGO on the map. Buying one of its goods costs you scrap and sends that item to
    whoever it belongs to - that is the check.

    The seed balances itself: when your options create more items than checks, shop slots are added
    until every item has a place, so nothing is ever left out. This number is the floor. The bigger the
    shop, the more packages each ARCHIPELAGO beacon offers (3, 6, 9 or 12).
    """

    display_name = "Archipelago Shop Checks (minimum)"
    range_start = 0
    range_end = 100
    default = 20


class MinimumFiller(Range):
    """The minimum number of filler items (scrap, fuel, missiles, drone parts) in your seed.

    The seed balances itself: when your options create more checks than items, filler is added until
    every check holds something. This number is the floor.
    """

    display_name = "Minimum Filler"
    range_start = 0
    range_end = 100
    default = 20


class EnergyLink(Toggle):
    """Whether to share a fuel reserve with the other players in the multiworld.

    Fuel is the one FTL resource whose absence does not kill you outright - it strands you, and
    being stranded is one of the game's most frustrating deaths. A shared reserve is exactly the
    thing that fixes it.

    Your surplus fuel is deposited automatically at safe beacons, minus a 25% handling loss so
    the reserve cannot be used as a personal vault. When you drop below three fuel, your ship
    asks the reserve for more - once per beacon, so one desperate player cannot drain it.

    Energy is shared with every EnergyLink player in the multiworld, whatever game they play.
    """

    display_name = "Energy Link"


class TrapLink(Toggle):
    """Whether traps are shared with the other players who enabled Trap Link.

    When you receive a trap, everyone else with Trap Link receives one too, and theirs reach
    you - even if your own seed contains no traps at all.

    Off by default, deliberately: a player discovering this world should not be hit by the traps
    of someone they have never met.
    """

    display_name = "Trap Link"


class DeathLinkTrigger(Choice):
    """What counts as your death, for the purposes of Death Link.

    FTL has more than one kind of death, so this is a choice rather than a fixed rule.

    ship_destroyed: your run ends - the hull is gone, or your whole crew is.
    crew_death: any single crew member dies, even if the run goes on.
    both: either of those. This is the default.

    Be aware of what "both" means in practice: you lose crew members far more often than you
    lose runs, so most of the deaths you send will come from that half. If your multiworld finds
    that too noisy, ship_destroyed is the quiet setting.
    """

    display_name = "Death Link Trigger"
    option_ship_destroyed = 0
    option_crew_death = 1
    option_both = 2
    default = option_both
    alias_run_lost = option_ship_destroyed
    alias_hull_destroyed_only = option_ship_destroyed
    alias_any_crew_death = option_both


class DeathLinkEffect(Choice):
    """What a death link received from another world does to your ship.

    None of these can kill you. Losing a run in FTL costs an hour, so a death link that destroys
    your ship would turn the multiworld into a punishment; the mod never takes your hull below 1
    and never kills your last crew member.

    major_incident: a breach AND a fire in one of your system rooms, and that system takes
    damage. This is the default, and it is by far the harshest of them all - it cannot destroy
    your ship, but a breach and a fire in your shield room mid-fight can absolutely lose you the
    run. That is the point.
    crew_member: one random crew member dies. Never the last one.
    hull_damage: your hull takes damage.
    fire: a fire starts in a random room.
    boarding: a single hostile Mantis appears aboard. It never spawns if you are down to one
    crew member, because that duel is a coin flip and losing it ends the run.
    varied: one of the four milder effects, drawn afresh at every death. Never the major
    incident - whoever wants that one asks for it by name.

    If the chosen effect cannot apply - a lone survivor, a hull already at 1 - the mod falls back
    to a *milder* one rather than letting the death pass unnoticed. A fallback never escalates.
    """

    display_name = "Death Link Effect"
    option_crew_member = 0
    option_hull_damage = 1
    option_fire = 2
    option_varied = 3
    option_major_incident = 4
    option_boarding = 5
    default = option_major_incident


class ModLanguage(Choice):
    """The language the in-game mod speaks: messages, dashboard, Archipelago shop.

    game: follow whatever language FTL itself is set to. This is the default, and it is right
    for almost everyone.
    Anything else forces that language, whatever FTL is set to. Useful if you play FTL in
    English out of habit but would rather read the Archipelago parts in your own language.

    This setting never touches item or location NAMES. Those are global identifiers shared with
    the server, with the other players' clients and with every tracker; translating them would
    break hints between worlds. Only the sentences around them change language.

    A language the mod does not carry yet falls back to English, one string at a time, so a
    partial translation is always better than none.
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
    death_link_effect: DeathLinkEffect
    energy_link: EnergyLink
    trap_link: TrapLink

    mod_language: ModLanguage

    goal: Goal
    victories_required: VictoriesRequired
    victory_difficulty: VictoryDifficulty
    archives: Archives
    archives_required: ArchivesRequired
    victory_layouts: VictoryLayouts
    start_ship: StartShip

    ship_layouts: ShipLayouts
    layout_unlocks: LayoutUnlocks

    sectorsanity: Sectorsanity
    sectorsanity_first_sector: SectorsanityFirstSector
    sectorsanity_last_sector: SectorsanityLastSector
    crew_checks: CrewChecks
    crew_members: CrewMembers
    systemsanity: Systemsanity
    ship_achievements: ShipAchievementChecks
    general_achievements: GeneralAchievementChecks
    cross_run_achievements: CrossRunAchievementChecks

    system_blueprints: SystemBlueprints
    progressive_systems: ProgressiveSystems
    head_starts: HeadStarts
    trap_chance: TrapChance
    shop_weapons: ShopWeapons
    shop_drones: ShopDrones
    shop_augments: ShopAugments
    shop_unlock_mode: ShopUnlockMode
    shop_item_delivery: ShopItemDelivery
    shop_checks: ShopChecks
    minimum_filler: MinimumFiller

    sector_logic: SectorLogic
    shields_blueprint_logic: ShieldsBlueprintLogic
    sensors_blueprint_logic: SensorsBlueprintLogic
    medbay_blueprint_logic: MedbayBlueprintLogic
    engines_blueprint_logic: EnginesBlueprintLogic
    weapons_blueprint_logic: WeaponsBlueprintLogic



ftl_option_groups = [
    OptionGroup("Goal", [Goal, VictoriesRequired, VictoryDifficulty, Archives, ArchivesRequired,
                         VictoryLayouts]),
    OptionGroup("Presentation", [ModLanguage]),
    OptionGroup("Ships", [StartShip, ShipLayouts, LayoutUnlocks]),
    OptionGroup(
        "Checks",
        [
            Sectorsanity,
            SectorsanityFirstSector,
            SectorsanityLastSector,
            ShipAchievementChecks,
            GeneralAchievementChecks,
            CrossRunAchievementChecks,
        ],
    ),
    OptionGroup(
        "Item Pool",
        [SystemBlueprints, ProgressiveSystems, HeadStarts, TrapChance],
    ),
    OptionGroup(
        "Shop Items",
        [ShopWeapons, ShopDrones, ShopAugments, ShopUnlockMode, ShopItemDelivery,
         ShopChecks],
    ),
    OptionGroup(
        "Links",
        [DeathLinkTrigger, DeathLinkEffect, EnergyLink, TrapLink],
    ),
    OptionGroup("Logic", [SectorLogic, *BLUEPRINT_LOGIC_OPTIONS]),
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
