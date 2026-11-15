#!/usr/bin/env python3
"""Plays many generated seeds with a simulated average player, to estimate how long they take and find seeds that stall.

usage: seed_sim.py presets/first_game.yaml [more presets...] [--seeds 200] [--profile average] [--json out.json]

Each seed is really generated (fill included). Then a model player plays runs, one ship at a time, sector after
sector, until the goal. It is not FTL: it is a rough player who
  - picks the ship with the most to do (or the one that can win, once the goal needs a victory),
  - finds the sector checks, fights, events and reactor checks of each sector reached (they need no item, only the
    ship and its Sector Passes), and buys a package or so at each Archipelago store,
  - gets an achievement, a crew race or a system install by chance, and only once the logic says it is doable,
  - dies more often in a sector the logic says it is too weak for, and beats the Flagship more often when it is ready,
  - uses sector skip when the ship has nothing left to do in an early sector,
  - receives its items at once (a solo seed: nobody else holds them).
Time is counted in minutes per sector, set by the profile. The numbers are a model: they rank presets and seeds,
and a run of real players gives the scale (the "fast" profile is set on one 3 h solo test, see PROFILES).

Reported per preset: locations, sphere 1 size (Archipelago's own spheres), runs and hours to the goal (median, 10th
and 90th percentile), share of seeds over the time limit, longest stretch of runs that found nothing, and the seeds
that never reached the goal (to replay: --seeds 1 --first N).
"""

from __future__ import annotations

import argparse
import collections
import json
import random
import statistics
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Callable, Iterable

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]

SECTOR_COUNT = 8
SKIPPABLE_UP_TO = 4
STALL_RUNS = 3


@dataclass(frozen=True)
class Profile:
    """How a player plays, in minutes and odds. All numbers are guesses to tune against real games."""

    minutes_per_sector: float
    minutes_per_skipped_sector: float = 1.5
    minutes_per_boss: float = 10.0
    minutes_between_runs: float = 2.0
    # Odds of dying in a sector, when the logic says the ship is ready for it and when it does not.
    death_ready: float = 0.05
    death_unready: float = 0.25
    # Odds of beating the Flagship.
    win_ready: float = 0.7
    win_unready: float = 0.25
    # Archipelago packages bought at each store visit (the fraction is a chance of one more).
    buys_per_store: float = 1.0
    # Archipelago event checks found per sector (relay, pirates...).
    events_per_sector: float = 1.5
    # Per run, odds of getting a check that needs luck, once in logic and deep enough.
    achievement_chance: float = 0.2
    crew_chance: float = 0.6
    system_chance: float = 0.5


PROFILES: dict[str, Profile] = {
    # Tuned so that Tom's solo test (4 ships, 2 victories, sector locks and sector skip) takes about 3 h.
    "fast": Profile(minutes_per_sector=5.0, death_ready=0.03, death_unready=0.15, win_ready=0.85,
                    win_unready=0.4, buys_per_store=1.5, events_per_sector=2.0, achievement_chance=0.3,
                    crew_chance=0.7, system_chance=0.6),
    "average": Profile(minutes_per_sector=7.0),
    "beginner": Profile(minutes_per_sector=9.0, death_ready=0.08, death_unready=0.35, win_ready=0.5,
                        win_unready=0.15, buys_per_store=0.8, events_per_sector=1.2, achievement_chance=0.12,
                        crew_chance=0.5, system_chance=0.4),
}


# What makes a check happen in the model.
PHYSICAL = "physical"      # reaching the sector with that ship is enough
SHOP = "shop"              # bought at an Archipelago store
EVENT = "event"            # found at an Archipelago event, in order
LUCK = "luck"              # needs the logic and a dice roll each run
BOSS_LUCK = "boss_luck"    # same, rolled only when the Flagship falls ("Beat the boss on Easy")
VICTORY = "victory"        # beating the Flagship


@dataclass
class Check:
    name: str
    kind: str
    depth: int
    # The layouts able to do it; None: any ship.
    layouts: frozenset[str] | None
    item: object
    reachable: Callable[[object], bool]
    order: int = 0
    # 2 progression, 1 useful, 0 the rest: what a player picks first at a store.
    priority: int = 0
    # Odds per try for a luck check, when it is not the profile's own.
    chance: float | None = None
    # GROUP name, for "victory collects the layout".
    group: str = ""
    ship: str | None = None
    layout: str | None = None


@dataclass
class Seed:
    """What the model needs from a generated seed. The AP adapter builds it; tests build small fake ones."""

    checks: list[Check]
    layouts: list[str]
    state: object
    collect: Callable[[object, object], None]
    flyable: Callable[[object], list[str]]
    # Deepest sector this layout may enter (sector locks): 8 when nothing stops it.
    depth_limit: Callable[[object, str], int]
    ready: Callable[[object, str, int], bool]
    boss_ready: Callable[[object, str], bool]
    goal_done: Callable[[object, set], bool]
    # True while the goal still needs more victories (whatever the Archives say).
    victories_short: Callable[[set], bool] = lambda victories: not victories
    sector_skip: bool = False
    # off / sectors / everything, see VictoryCollectsLayout.
    victory_collects: str = "sectors"
    ship_of: dict[str, str] = field(default_factory=dict)
    shop_by_sector: bool = False
    # Packages one store shows at once (3 per page, see apShopPages in the mod's shopgift.lua).
    shop_window: int = 3
    sphere_sizes: list[int] = field(default_factory=list)


@dataclass
class Result:
    goal: bool
    runs: int
    minutes: float
    victories: int
    checks_done: int
    checks_total: int
    longest_dry_streak: int
    minutes_all: float | None = None
    stuck_reason: str = ""
    # When the goal was not reached: the checks still to do that the logic allows (what a player waits on).
    left_in_logic: list[str] = field(default_factory=list)
    # After 3 runs or more with nothing found: the check that ended the wait (check, item, runs waited).
    stalls: list[tuple[str, str, int]] = field(default_factory=list)


def _remaining_for(seed: Seed, done: set[str], layout: str, depth: int) -> list[Check]:
    return [check for check in seed.checks if check.name not in done
            and (check.layouts is None or layout in check.layouts)
            and check.depth <= depth and check.kind != VICTORY]


def _layout_score(seed: Seed, state, done: set[str], layout: str, profile: Profile) -> float:
    """What a run on this ship may bring that no other ship can: its sector checks and store packages, and its
    achievements in logic, counted by their odds."""
    limit = seed.depth_limit(state, layout)
    score = 0.0
    for check in _remaining_for(seed, done, layout, limit):
        if check.layouts is None:
            continue
        if check.kind in (PHYSICAL, SHOP):
            score += 1.0
        elif check.kind in (LUCK, BOSS_LUCK) and check.reachable(state):
            score += _luck_chance(check, profile)
    return score


def _luck_chance(check: Check, profile: Profile) -> float:
    if check.chance is not None:
        return check.chance
    return {"crew": profile.crew_chance, "system": profile.system_chance}.get(check.group, profile.achievement_chance)


def choose_layout(seed: Seed, state, done: set[str], victories: set[str], rng: random.Random,
                  profile: Profile) -> str | None:
    flyable = seed.flyable(state)
    if not flyable:
        return None
    # A ship ready for the Flagship that has not won yet comes first while the goal needs victories.
    if seed.victories_short(victories):
        winners = [layout for layout in flyable if layout not in victories
                   and seed.depth_limit(state, layout) >= SECTOR_COUNT and seed.boss_ready(state, layout)]
        if winners:
            return rng.choice(sorted(winners))
    scored = sorted(((_layout_score(seed, state, done, layout, profile), layout) for layout in flyable),
                    reverse=True)
    best = scored[0][0]
    if best == 0:
        # Nothing ship-specific left: a ship that has not won yet, else any.
        fresh = [layout for layout in flyable if layout not in victories
                 and seed.depth_limit(state, layout) >= SECTOR_COUNT]
        return rng.choice(sorted(fresh or flyable))
    return rng.choice(sorted(layout for score, layout in scored if score == best))


def _roll(rng: random.Random, chance: float) -> bool:
    return rng.random() < chance


def _amount(rng: random.Random, mean: float) -> int:
    whole = int(mean)
    return whole + (1 if rng.random() < mean - whole else 0)


def play(seed: Seed, profile: Profile, rng: random.Random, max_runs: int = 400,
         play_to_the_end: bool = False, trace: list[str] | None = None) -> Result:
    state = seed.state
    done: set[str] = set()
    victories: set[str] = set()
    reached: dict[str, int] = {}
    total = len(seed.checks)
    minutes = 0.0
    runs = 0
    goal_minutes: float | None = None
    goal_runs = 0
    dry, longest_dry = 0, 0
    events = sorted((check for check in seed.checks if check.kind == EVENT), key=lambda c: c.order)
    shop = sorted((check for check in seed.checks if check.kind == SHOP), key=lambda c: c.order)

    def take(check: Check) -> None:
        if dry >= STALL_RUNS and not (stalls and stalls[-1][2] == -runs):
            stalls.append((check.name, str(getattr(check.item, "name", check.item)), -runs))
        done.add(check.name)
        if check.item is not None:
            seed.collect(state, check.item)
        if trace is not None:
            item = getattr(check.item, "name", check.item)
            trace.append(f"  {minutes / 60:5.2f} h  {check.name}  ->  {item}")

    stalls: list[tuple[str, str, int]] = []
    stuck = ""
    while runs < max_runs:
        if seed.goal_done(state, victories) and goal_minutes is None:
            goal_minutes, goal_runs = minutes, runs
            if not play_to_the_end:
                break
        if len(done) >= total:
            break
        layout = choose_layout(seed, state, done, victories, rng, profile)
        if layout is None:
            stuck = "no ship to fly"
            break
        runs += 1
        minutes += profile.minutes_between_runs
        before = len(done)
        limit = seed.depth_limit(state, layout)
        if trace is not None:
            trace.append(f"run {runs} on {layout}, sector limit {limit}, boss ready {seed.boss_ready(state, layout)}")
        deepest = 0
        rolled: set[str] = set()
        for sector in range(1, SECTOR_COUNT + 1):
            if sector > limit:
                break
            # What only this sector gives: its checks for this ship, and its store when the shop goes by sector.
            todo_here = [check for check in _remaining_for(seed, done, layout, sector) if check.depth == sector
                         and ((check.kind == PHYSICAL and check.layouts is not None)
                              or (check.kind == SHOP and seed.shop_by_sector))]
            if (seed.sector_skip and sector <= SKIPPABLE_UP_TO and reached.get(layout, 0) > sector
                    and not todo_here):
                minutes += profile.minutes_per_skipped_sector
                deepest = sector
                continue
            minutes += profile.minutes_per_sector
            deepest = sector
            for check in _remaining_for(seed, done, layout, sector):
                if check.kind == PHYSICAL and check.depth == sector:
                    take(check)
                elif check.kind == LUCK and check.name not in rolled and check.reachable(state):
                    # One roll per run, in the first sector played where it is possible (skipped ones don't count).
                    rolled.add(check.name)
                    if _roll(rng, _luck_chance(check, profile)):
                        take(check)
            shown = [check for check in shop if check.name not in done
                     and (check.layouts is None or layout in check.layouts)
                     and (not seed.shop_by_sector or check.depth == sector)][:seed.shop_window]
            # The player sees what each package holds and buys the important ones first.
            shown.sort(key=lambda check: -check.priority)
            for offer in shown[:_amount(rng, profile.buys_per_store)]:
                take(offer)
            for _ in range(_amount(rng, profile.events_per_sector)):
                found = next((check for check in events if check.name not in done), None)
                if found is None:
                    break
                take(found)
            ready = seed.ready(state, layout, sector)
            if _roll(rng, profile.death_ready if ready else profile.death_unready):
                if trace is not None:
                    trace.append(f"  {minutes / 60:5.2f} h  died in sector {sector} ({'ready' if ready else 'too weak'})")
                break
            if sector == SECTOR_COUNT:
                minutes += profile.minutes_per_boss
                won = _roll(rng, profile.win_ready if seed.boss_ready(state, layout) else profile.win_unready)
                if trace is not None:
                    trace.append(f"  {minutes / 60:5.2f} h  Flagship {'beaten' if won else 'lost'}")
                if won:
                    victories.add(layout)
                    for check in seed.checks:
                        if check.name in done:
                            continue
                        if check.kind == VICTORY and check.layouts and layout in check.layouts:
                            take(check)
                        elif _collected_by_victory(seed, check, layout):
                            take(check)
                        elif (check.kind == BOSS_LUCK and (check.layouts is None or layout in check.layouts)
                              and check.reachable(state) and _roll(rng, _luck_chance(check, profile))):
                            take(check)
        reached[layout] = max(reached.get(layout, 0), deepest)
        if len(done) == before:
            dry += 1
            longest_dry = max(longest_dry, dry)
        else:
            if stalls and stalls[-1][2] == -runs:
                stalls[-1] = (stalls[-1][0], stalls[-1][1], dry)
            dry = 0
    else:
        stuck = f"over {max_runs} runs"

    if goal_minutes is None and seed.goal_done(state, victories):
        goal_minutes, goal_runs = minutes, runs
    reached_goal = goal_minutes is not None
    if not reached_goal and not stuck:
        stuck = "everything checked, goal still out of reach"
    return Result(
        goal=reached_goal,
        runs=goal_runs if reached_goal else runs,
        minutes=goal_minutes if reached_goal else minutes,
        victories=len(victories),
        checks_done=len(done),
        checks_total=total,
        longest_dry_streak=longest_dry,
        minutes_all=minutes if play_to_the_end and len(done) >= total else None,
        stuck_reason="" if reached_goal else stuck,
        stalls=[stall for stall in stalls if stall[2] > 0],
        left_in_logic=[] if reached_goal else sorted(
            check.name for check in seed.checks if check.name not in done and check.reachable(state)),
    )


def _collected_by_victory(seed: Seed, check: Check, layout: str) -> bool:
    if seed.victory_collects == "off":
        return False
    if check.group == "Sectors":
        return check.layout == layout
    if seed.victory_collects != "everything":
        return False
    if check.group in ("Ship achievements", "Ship systems", "Fights won", "Fights won per sector"):
        return check.ship is not None and check.ship == seed.ship_of.get(layout)
    return False


def percentile(values: list[float], share: float) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = min(len(ordered) - 1, max(0, round(share * (len(ordered) - 1))))
    return ordered[index]


def summarize(results: list[Result], limit_hours: float) -> dict:
    won = [r for r in results if r.goal]
    hours = [r.minutes / 60.0 for r in won]
    return {
        "seeds": len(results),
        "stuck": len(results) - len(won),
        "hours_median": round(statistics.median(hours), 2) if hours else None,
        "hours_p10": round(percentile(hours, 0.1), 2) if hours else None,
        "hours_p90": round(percentile(hours, 0.9), 2) if hours else None,
        "over_limit_%": round(100.0 * sum(1 for h in hours if h > limit_hours) / max(1, len(results)), 1),
        "runs_median": statistics.median(r.runs for r in won) if won else None,
        "checks_at_goal_median": statistics.median(r.checks_done for r in won) if won else None,
        "longest_dry_streak_max": max((r.longest_dry_streak for r in results), default=0),
        "longest_dry_streak_median": statistics.median(r.longest_dry_streak for r in results) if results else 0,
        # The checks that most often ended a wait of 3 runs or more, with how many times.
        "stall_enders": collections.Counter(stall[0] for r in results for stall in r.stalls).most_common(8),
    }


# ---------------------------------------------------------------------------------------------------------------
# The Archipelago side: generate a seed and turn it into a Seed.


GEN_STEPS = ("generate_early", "create_regions", "create_items", "set_rules",
             "connect_entrances", "generate_basic", "pre_fill")


def bootstrap() -> None:
    sys.path.insert(0, str(HERE))
    from curve import bootstrap as curve_bootstrap
    curve_bootstrap()
    import logging
    import types
    import warnings
    stub = types.ModuleType("bsdiff4.core")
    stub.diff = stub.patch = lambda *a, **k: b""
    sys.modules.setdefault("bsdiff4.core", stub)
    logging.disable(logging.ERROR)
    warnings.simplefilter("ignore")


def load_options(path: Path) -> dict:
    import yaml
    from worlds.ftl import data
    document = yaml.safe_load(path.read_text(encoding="utf-8"))
    return document[data.GAME_NAME]


def generate(options: dict, seed: int):
    from Fill import distribute_items_restrictive
    from test.general import setup_multiworld
    from worlds.AutoWorld import AutoWorldRegister, call_all
    from worlds.ftl import data
    world_type = AutoWorldRegister.world_types[data.GAME_NAME]
    multiworld = setup_multiworld(world_type, GEN_STEPS, seed=seed, options=options)
    distribute_items_restrictive(multiworld)
    call_all(multiworld, "post_fill")
    return multiworld


def _kind_of(entry, data) -> str:
    group = entry.group
    if group == data.GROUP_VICTORIES:
        return VICTORY
    if group == data.GROUP_SHOP_SLOTS:
        return SHOP
    if group == data.GROUP_EVENTS:
        return EVENT
    if group in (data.GROUP_SECTORS, data.GROUP_FIGHTS, data.GROUP_SECTOR_FIGHTS, data.GROUP_REACTOR):
        return PHYSICAL
    return LUCK


def shop_pages(slots: int, by_sector: bool, owners: int) -> int:
    """Same count as apShopPages in mod/ArchipelagoFTL/data/archipelago/shopgift.lua."""
    if by_sector or owners > 0:
        sectors = 7 if by_sector else 1
        return max(1, min(4, -(-slots // (sectors * max(1, owners) * 3))))
    if slots > 100:
        return 4
    if slots > 60:
        return 3
    if slots > 30:
        return 2
    return 1


def seed_from_multiworld(multiworld, with_spheres: bool = True) -> Seed:
    from worlds.ftl import data, rules
    from worlds.ftl import locations as locations_module
    from worlds.ftl.locations import region_name
    player = 1
    world = multiworld.worlds[player]
    options = world.options
    level = world.sector_logic_level
    by_sector = bool(options.shop_by_sector)
    layouts = list(world.selected_layouts)
    blueprints = [layout.blueprint for layout in layouts]
    layout_by_bp = {layout.blueprint: layout for layout in layouts}
    regions = {layout.blueprint: multiworld.get_region(region_name(layout), player) for layout in layouts}
    requirements = {layout.blueprint: rules.layout_requirements(world, layout) for layout in layouts}
    passes = {layout.blueprint: (rules.sector_pass_needs(world, layout, 1), rules.sector_pass_needs(world, layout, 2))
              for layout in layouts}
    milestones = rules.power_milestones_apply(level, options)

    checks: list[Check] = []
    for location in multiworld.get_locations(player):
        if location.address is None:
            continue
        entry = data.LOCATIONS_BY_NAME[location.name]
        kind = _kind_of(entry, data)
        if entry.shop_slot is not None:
            able = frozenset(owner.blueprint for owner in rules.shop_slot_owners(world, entry, layouts))
            able = None if len(able) == len(layouts) else able
        else:
            able = frozenset(layout.blueprint for layout in rules._layouts_able_to_try(options, entry))
            able = None if len(able) == len(layouts) else able
        chance = None
        if kind == LUCK and rules.location_needs_flagship(entry):
            kind = BOSS_LUCK
            # "Beat the boss on Easy / Normal / Hard": a player plays one difficulty, about one in two.
            chance = 0.5 if (entry.achievement or "").startswith("ACH_WIN_") else None
        group = {data.GROUP_CREW: "crew", data.GROUP_SYSTEMS: "system",
                 data.GROUP_SHIP_SYSTEMS: "system"}.get(entry.group, entry.group)
        checks.append(Check(
            name=location.name, kind=kind, depth=max(1, rules.location_depth(entry, by_sector)),
            layouts=able, item=location.item, reachable=location.can_reach,
            order=entry.shop_slot or entry.fight or 0, group=group, ship=entry.ship, layout=entry.layout,
            priority=2 if location.item.advancement else 1 if location.item.useful else 0, chance=chance,
        ))

    def has(state, names) -> bool:
        return rules._has_requirements(state, names, player)

    def flyable(state) -> list[str]:
        return [bp for bp in blueprints if regions[bp].can_reach(state)]

    def depth_limit(state, layout: str) -> int:
        one, two = passes[layout]
        if not one:
            return SECTOR_COUNT
        if not has(state, one):
            return 4
        if not has(state, two):
            return 7
        return SECTOR_COUNT

    def ready(state, layout: str, sector: int) -> bool:
        needed = rules.blueprints_for_sector(level, sector)
        if needed and not state.has_group(data.GROUP_BLUEPRINTS, player, needed):
            return False
        if milestones and sector >= 5:
            wanted = rules.power_wanted(options, 8 if sector >= 8 else 5, layout_by_bp[layout])
            return rules.meets_power(options, state, player, layout_by_bp[layout], wanted)
        return True

    def boss_ready(state, layout: str) -> bool:
        needed = rules.blueprints_for_flagship(level)
        if needed and not state.has_group(data.GROUP_BLUEPRINTS, player, needed):
            return False
        if milestones:
            return rules.meets_power(options, state, player, layout_by_bp[layout],
                                     rules.power_wanted(options, "boss", layout_by_bp[layout]))
        return True

    from worlds.ftl import options as options_module
    chosen = options_module.goal_layouts(options)
    candidates = set(chosen) if chosen is not None else set(blueprints)
    needed = len(candidates) if chosen is not None else options.victories_required.value
    archives = options_module.archives_required(options)

    def goal_done(state, victories: set) -> bool:
        if archives and not state.has(data.ARCHIVE_ITEM_NAME, player, archives):
            return False
        return len(victories & candidates) >= needed

    def victories_short(victories: set) -> bool:
        return len(victories & candidates) < needed

    def collect(state, item) -> None:
        state.collect(item, prevent_sweep=True)

    sphere_sizes: list[int] = []
    if with_spheres:
        for sphere in multiworld.get_spheres():
            size = sum(1 for location in sphere if location.player == player and location.address is not None)
            if size:
                sphere_sizes.append(size)

    collects = {0: "off", 1: "sectors", 2: "everything"}[options.victory_collects_layout.value]
    return Seed(
        checks=checks, layouts=blueprints, state=multiworld.state.copy(), collect=collect, flyable=flyable,
        depth_limit=depth_limit, ready=ready, boss_ready=boss_ready, goal_done=goal_done,
        victories_short=victories_short,
        sector_skip=bool(options.sector_skip), victory_collects=collects,
        ship_of={layout.blueprint: layout.ship for layout in layouts}, shop_by_sector=by_sector,
        shop_window=3 * shop_pages(sum(1 for check in checks if check.kind == SHOP), by_sector,
                                   len(locations_module.shop_owners(options))),
        sphere_sizes=sphere_sizes,
    )


def simulate_preset(options: dict, seeds: Iterable[int], profile: Profile, plays: int = 1,
                    play_to_the_end: bool = False, on_error: Callable[[int, Exception], None] | None = None):
    rows = []
    for number in seeds:
        try:
            multiworld = generate(options, number)
        except Exception as error:  # a generation failure is a finding too
            if on_error:
                on_error(number, error)
            rows.append({"seed": number, "error": f"{type(error).__name__}: {str(error)[-300:]}"})
            continue
        seed = seed_from_multiworld(multiworld)
        for play_index in range(plays):
            fresh = seed if play_index == 0 else seed_from_multiworld(multiworld, with_spheres=False)
            result = play(fresh, profile, random.Random(number * 1000 + play_index), play_to_the_end=play_to_the_end)
            rows.append({"seed": number, "play": play_index, "spheres": seed.sphere_sizes,
                         "locations": len(seed.checks), **asdict(result)})
    return rows


def report(name: str, rows: list[dict], limit_hours: float) -> dict:
    played = [row for row in rows if "error" not in row]
    results = [Result(**{key: row[key] for key in Result.__dataclass_fields__}) for row in played]
    summary = summarize(results, limit_hours)
    summary["preset"] = name
    summary["generation_errors"] = [row for row in rows if "error" in row]
    if played:
        summary["locations"] = statistics.median(row["locations"] for row in played)
        firsts = [row["spheres"][0] for row in played if row["spheres"]]
        summary["sphere_1_median"] = statistics.median(firsts) if firsts else None
        summary["spheres_median"] = statistics.median(len(row["spheres"]) for row in played)
        summary["stuck_seeds"] = sorted({(row["seed"], row["stuck_reason"]) for row in played if not row["goal"]})
    return summary


def print_summary(summary: dict, limit_hours: float) -> None:
    print(f"\n=== {summary['preset']}")
    if summary.get("locations") is None:
        print(f"  every generation failed: {summary['generation_errors'][:3]}")
        return
    print(f"  {summary['locations']:.0f} locations, sphere 1 = {summary['sphere_1_median']} checks, "
          f"{summary['spheres_median']:.0f} spheres (medians)")
    if summary["hours_median"] is not None:
        print(f"  goal in {summary['hours_median']} h (10%: {summary['hours_p10']} h, 90%: {summary['hours_p90']} h), "
              f"{summary['runs_median']} runs, {summary['checks_at_goal_median']} checks done at the goal")
    print(f"  over {limit_hours:g} h: {summary['over_limit_%']} % of the plays")
    print(f"  longest stretch of runs finding nothing: {summary['longest_dry_streak_median']} (median), "
          f"{summary['longest_dry_streak_max']} (worst)")
    if summary.get("stall_enders"):
        print("  waits of 3 runs or more were ended most often by: "
              + ", ".join(f"{name} ({count})" for name, count in summary["stall_enders"]))
    if summary.get("stuck_seeds"):
        print(f"  never reached the goal: {summary['stuck_seeds'][:10]}")
    if summary["generation_errors"]:
        print(f"  generation failed for {len(summary['generation_errors'])} seeds, first: "
              f"{summary['generation_errors'][0]}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("presets", nargs="+", type=Path)
    parser.add_argument("--seeds", type=int, default=100)
    parser.add_argument("--first", type=int, default=1, help="first seed number")
    parser.add_argument("--plays", type=int, default=1, help="plays per generated seed (other dice)")
    parser.add_argument("--profile", choices=sorted(PROFILES), default="average")
    parser.add_argument("--limit", type=float, default=3.0, help="hours, for the share of plays over it")
    parser.add_argument("--json", type=Path, help="write the summaries and every play here")
    parser.add_argument("--trace", action="store_true", help="print each run of the first seed, then stop")
    arguments = parser.parse_args(argv)

    bootstrap()
    profile = PROFILES[arguments.profile]
    print(f"{arguments.seeds} seeds per preset, profile {arguments.profile}: {profile}")
    out = []
    for path in arguments.presets:
        target = path if path.is_absolute() else ROOT / path
        options = load_options(target)
        if arguments.trace:
            lines: list[str] = []
            seed = seed_from_multiworld(generate(options, arguments.first))
            result = play(seed, profile, random.Random(arguments.first * 1000), trace=lines)
            print(f"\n=== {target.name}, seed {arguments.first}")
            print("\n".join(lines))
            print(result)
            continue
        rows = simulate_preset(options, range(arguments.first, arguments.first + arguments.seeds), profile,
                               plays=arguments.plays)
        summary = report(target.name, rows, arguments.limit)
        print_summary(summary, arguments.limit)
        out.append({"summary": summary, "plays": rows})
    if arguments.json:
        arguments.json.write_text(json.dumps(out, indent=1, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
