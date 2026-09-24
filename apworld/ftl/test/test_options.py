
from __future__ import annotations

import logging
from pathlib import Path

from Options import OptionError

from .. import data, items, locations, options, rules
from .bases import FTLTestBase

LANG_DIR = Path(__file__).resolve().parents[3] / "mod" / "lang"


def _a_ship_that_is_not_given_for_free(world) -> data.Ship:

    free = {world.start_ship.blueprint}
    free.update(
        data.LAYOUTS_BY_BLUEPRINT[blueprint].ship for blueprint in data.ALWAYS_UNLOCKED_LAYOUTS
    )
    return next(
        ship for ship in data.SHIPS if ship.layout_count > 1 and ship.blueprint not in free
    )


class TestMinimalSeed(FTLTestBase):

    options = {
        "minimum_filler": 0,
        "shop_weapons": 0,
        "shop_drones": 0,
        "shop_augments": 0,
        "crew_members": False,
        "head_starts": False,
        "ship_layouts": "type_a_only",
        "sectorsanity": "disabled",
        "ship_achievements": False,
        "general_achievements": "disabled",
        "cross_run_achievements": False,
        "systemsanity": "disabled",
        "crew_checks": False,
        "system_blueprints": False,
        "progressive_systems": False,
        "shop_checks": 0,
        "victories_required": 3,
    }

    def test_only_the_victories_remain(self) -> None:
        groups = {
            data.LOCATIONS_BY_NAME[location.name].group
            for location in self.addressed_locations()
        }
        self.assertEqual(groups, {data.GROUP_VICTORIES})
        self.assertEqual(len(self.addressed_locations()), len(data.SHIPS))

    def test_pool_size_still_matches(self) -> None:
        self.assertEqual(len(self.multiworld.itempool), len(self.addressed_locations()))

    def test_ship_keys_won_the_arbitration(self) -> None:

        pooled = {item.name for item in self.multiworld.itempool}
        pooled.update(self.world.precollected_item_names)
        for ship in data.SHIPS:
            self.assertIn(data.SHIP_KEY_NAMES[ship.blueprint], pooled)


class TestArchives(FTLTestBase):

    options = {
        "archives": 4,
        "archives_required": 4,
        "victories_required": 1,
        "sectorsanity": "full",
        "shop_checks": 20,
    }

    def test_every_archive_is_in_the_pool(self) -> None:
        names = [item.name for item in self.multiworld.itempool]
        self.assertEqual(names.count(data.ARCHIVE_ITEM_NAME), 4)

    def test_the_goal_needs_them_all(self) -> None:
        state = self.multiworld.get_all_state(False)
        self.assertTrue(self.multiworld.completion_condition[self.player](state))

        without = self.multiworld.get_all_state(False)
        without.remove(self.world.create_item(data.ARCHIVE_ITEM_NAME))
        self.assertFalse(
            self.multiworld.completion_condition[self.player](without),
            "one archive is missing: the game must not be winnable",
        )

    def test_the_mod_is_told_how_many(self) -> None:
        self.assertEqual(self.world.fill_slot_data()["goal"]["archives"], 4)


class TestArchiveHunt(FTLTestBase):

    options = {
        "archives": 8,
        "archives_required": 5,
        "victories_required": 1,
        "sectorsanity": "full",
        "shop_checks": 20,
    }

    def test_the_multiworld_hides_more_than_the_goal_asks(self) -> None:
        names = [item.name for item in self.multiworld.itempool]
        self.assertEqual(names.count(data.ARCHIVE_ITEM_NAME), 8)

    def test_the_mod_is_told_what_the_goal_asks(self) -> None:
        self.assertEqual(self.world.fill_slot_data()["goal"]["archives"], 5)

    def test_a_mod_that_ignores_archives_is_refused(self) -> None:
        self.assertIn(
            "archive", self.world.fill_slot_data()["kinds_required"],
            "a mod that cannot count archives must refuse the seed, not play it unfinishable",
        )

    def test_three_missing_archives_still_win(self) -> None:
        state = self.multiworld.get_all_state(False)
        for _ in range(3):
            state.remove(self.world.create_item(data.ARCHIVE_ITEM_NAME))
        self.assertTrue(
            self.multiworld.completion_condition[self.player](state),
            "five archives out of eight are enough: that is the whole point of the margin",
        )

    def test_four_missing_archives_do_not(self) -> None:
        state = self.multiworld.get_all_state(False)
        for _ in range(4):
            state.remove(self.world.create_item(data.ARCHIVE_ITEM_NAME))
        self.assertFalse(
            self.multiworld.completion_condition[self.player](state),
            "below five, the game is not winnable",
        )


class TestArchivesRequiredAboveTotal(FTLTestBase):

    options = {
        "archives": 3,
        "archives_required": 40,
        "victories_required": 1,
        "sectorsanity": "full",
        "shop_checks": 20,
    }

    def test_the_goal_is_lowered_to_what_exists(self) -> None:
        self.assertEqual(self.world.fill_slot_data()["goal"]["archives"], 3)

    def test_the_seed_is_still_winnable(self) -> None:
        state = self.multiworld.get_all_state(False)
        self.assertTrue(self.multiworld.completion_condition[self.player](state))


class TestEverythingEnabled(FTLTestBase):

    options = {
        "shop_checks": 60,
        "ship_layouts": "all_layouts",
        "sectorsanity": "full",
        "sectorsanity_first_sector": 1,
        "ship_achievements": True,
        "general_achievements": "all",
        "cross_run_achievements": True,
        "systemsanity": "every_level",
        "system_blueprints": True,
        "progressive_systems": True,
        "head_starts": True,
        "trap_chance": 50,
        "sector_logic": "strict",
        "victories_required": 3,
    }

    def test_every_location_of_the_table_exists(self) -> None:
        unused_shop_slots = data.MAX_SHOP_SLOTS - self.world.options.shop_checks.value
        self.assertEqual(len(self.addressed_locations()), len(data.LOCATIONS) - unused_shop_slots)

    def test_pool_size_still_matches(self) -> None:
        self.assertEqual(len(self.multiworld.itempool), len(self.addressed_locations()))

    def test_filler_was_added_and_some_of_it_is_trapped(self) -> None:
        traps = [
            item for item in self.multiworld.itempool
            if data.ITEMS_BY_NAME[item.name].group == data.GROUP_TRAPS
        ]
        filler = [
            item for item in self.multiworld.itempool
            if data.ITEMS_BY_NAME[item.name].group == data.GROUP_FILLER
        ]
        self.assertTrue(filler)
        self.assertTrue(traps)

    def test_strict_logic_actually_gates_the_deep_sectors(self) -> None:

        blueprints = tuple(data.BLUEPRINT_ITEM_NAMES.values())
        self.collect_all_but(blueprints)
        deep = next(
            location for location in self.addressed_locations()
            if data.LOCATIONS_BY_NAME[location.name].sector == data.SECTOR_COUNT
        )
        self.assertFalse(deep.can_reach(self.multiworld.state), deep.name)


class TestVanillaLayoutUnlocks(FTLTestBase):

    options = {"layout_unlocks": "vanilla", "ship_layouts": "all_layouts"}

    def test_no_layout_item_is_created(self) -> None:
        created = {item.name for item in self.multiworld.itempool}
        self.assertEqual(created & set(data.LAYOUT_ITEM_NAMES.values()), set())

    def test_the_ship_key_alone_opens_every_layout_of_that_ship(self) -> None:
        ship = _a_ship_that_is_not_given_for_free(self.world)
        self.collect_by_name(data.SHIP_KEY_NAMES[ship.blueprint])
        for layout in data.LAYOUTS:
            if layout.ship == ship.blueprint:
                self.assertTrue(
                    self.can_reach_region(locations.region_name(layout)), layout.blueprint
                )


class TestLayoutItems(FTLTestBase):

    options = {"layout_unlocks": "items", "ship_layouts": "all_layouts"}

    def test_the_ship_key_alone_does_not_open_type_b(self) -> None:
        ship = _a_ship_that_is_not_given_for_free(self.world)
        layout_b = next(
            layout for layout in data.LAYOUTS
            if layout.ship == ship.blueprint and layout.variant == 1
        )
        self.collect_all_but(data.LAYOUT_ITEM_NAMES[layout_b.blueprint])
        self.assertTrue(self.can_reach_region(locations.region_name(
            data.LAYOUTS_BY_BLUEPRINT[ship.blueprint]
        )))
        self.assertFalse(self.can_reach_region(locations.region_name(layout_b)))


class TestSectorsanityFirstSector(FTLTestBase):

    FIRST = 4

    options = {
        "sectorsanity": "full",
        "sectorsanity_first_sector": FIRST,
        "ship_layouts": "type_a_only",
    }

    def test_the_shallow_sectors_send_nothing(self) -> None:
        sectors = {
            data.LOCATIONS_BY_NAME[location.name].sector
            for location in self.addressed_locations()
            if data.LOCATIONS_BY_NAME[location.name].group == data.GROUP_SECTORS
        }
        self.assertEqual(sectors, set(range(self.FIRST, data.SECTOR_COUNT + 1)))


_GATING_SYSTEMS = ("shields", "sensors", "medbay")

_KESTREL = data.SHIPS_BY_BLUEPRINT[
    data.LAYOUTS_BY_BLUEPRINT[data.ALWAYS_UNLOCKED_LAYOUTS[0]].ship
]


class TestGatingBlueprintLogic(FTLTestBase):

    options = {
        **{f"{system}_blueprint_logic": "required" for system in _GATING_SYSTEMS},
        "start_ship": _KESTREL.slot,
        "system_blueprints": True,
    }

    def test_the_sliders_are_really_set(self) -> None:

        for system in _GATING_SYSTEMS:
            option = getattr(self.world.options, f"{system}_blueprint_logic")
            self.assertEqual(option.current_key, "required")

    def test_blueprints_gating_an_always_free_ship_are_handed_over(self) -> None:
        given = set(self.world.precollected_item_names)
        free_layout = data.LAYOUTS_BY_BLUEPRINT[data.ALWAYS_UNLOCKED_LAYOUTS[0]]
        for system in _GATING_SYSTEMS:
            if system in free_layout.start_systems:
                self.assertIn(
                    data.BLUEPRINT_ITEM_NAMES[system], given,
                    f"{free_layout.blueprint} starts with {system} and stays playable no matter "
                    "what: its blueprint must be given, otherwise sphere 1 is empty",
                )

    def test_a_blueprint_given_at_the_start_is_not_also_in_the_pool(self) -> None:
        pooled = [item.name for item in self.multiworld.itempool]
        for name in self.world.precollected_item_names:
            if name in set(data.BLUEPRINT_ITEM_NAMES.values()):
                self.assertNotIn(name, pooled)


_CHOSEN_VICTORIES = tuple(
    layout for layout in data.LAYOUTS
    if layout.variant > 0 and layout.ship != _KESTREL.blueprint
)[:2]


class TestVictorySelection(FTLTestBase):

    options = {
        "goal": "victory_selection",
        "victory_layouts": [layout.display for layout in _CHOSEN_VICTORIES],
        "ship_layouts": "all_layouts",
        "start_ship": _KESTREL.slot,
    }

    def test_finishing_other_layouts_is_not_enough(self) -> None:

        withheld = data.LAYOUT_ITEM_NAMES[_CHOSEN_VICTORIES[0].blueprint]
        self.collect_all_but(withheld)
        self.assertFalse(self.can_reach_location(self.world.goal_location_name))

        self.collect_by_name(withheld)
        self.assertTrue(self.can_reach_location(self.world.goal_location_name))


class TestVictorySelectionOutsideTheSeed(FTLTestBase):

    options = {
        "goal": "victory_selection",
        "victory_layouts": [_CHOSEN_VICTORIES[0].display],
        "ship_layouts": "type_a_only",
    }
    auto_construct = False

    def test_generation_is_refused_with_a_readable_message(self) -> None:
        with self.assertRaises(OptionError) as raised:
            self.world_setup()
        self.assertIn(_CHOSEN_VICTORIES[0].display, str(raised.exception))


class TestGoalBeyondReach(FTLTestBase):

    options = {"ship_layouts": "type_a_only", "victories_required": len(data.SHIPS) + 1}
    auto_construct = False

    def test_generation_is_refused_with_a_readable_message(self) -> None:
        with self.assertRaises(OptionError) as raised:
            self.world_setup()
        self.assertIn("victories_required", str(raised.exception))


class TestVictorySelectionWithoutAnyLayout(FTLTestBase):

    options = {"goal": "victory_selection", "victory_layouts": []}
    auto_construct = False

    def test_generation_is_refused_with_a_readable_message(self) -> None:
        with self.assertRaises(OptionError) as raised:
            self.world_setup()
        message = str(raised.exception)
        self.assertIn("victory_layouts", message)
        self.assertIn("victory_count", message)


class TestPlandoNamesAnItemThatDoesNotExist(FTLTestBase):

    def test_an_unknown_name_is_refused_by_name(self) -> None:
        with self.assertRaises(OptionError) as raised:
            self.world.create_item("Kestrel Deluxe Edition")
        self.assertIn("Kestrel Deluxe Edition", str(raised.exception))

    def test_a_real_name_still_works(self) -> None:
        item = self.world.create_item(data.FILLER_ITEM_NAME)
        self.assertEqual(item.name, data.FILLER_ITEM_NAME)


class TestPlandoBeforeTheWorldHasPlanned(FTLTestBase):

    def test_a_blueprint_falls_back_to_the_table_classification(self) -> None:
        name = next(iter(sorted(data.BLUEPRINT_ITEM_NAMES.values())))
        expected = data.ITEMS_BY_NAME[name].classification
        plan = self.world.logic
        del self.world.logic
        try:
            self.assertEqual(items.effective_classification(self.world, data.ITEMS_BY_NAME[name]),
                             expected)
        finally:
            self.world.logic = plan


class TestThePlanDoesChangeClassifications(FTLTestBase):

    options = {"sector_logic": "relaxed", "systemsanity": "disabled", "ship_achievements": False}

    def test_some_blueprint_is_useful_with_the_plan_and_progression_without(self) -> None:
        changed = [
            name for name in sorted(data.BLUEPRINT_ITEM_NAMES.values())
            if items.effective_classification(self.world, data.ITEMS_BY_NAME[name])
            != data.ITEMS_BY_NAME[name].classification
        ]
        self.assertTrue(changed,
                        "the plan changes no blueprint's classification: the fallback would "
                        "then have no reason to exist")


class TestSectorsanityMilestones(FTLTestBase):

    options = {"sectorsanity": "milestones"}

    def test_only_the_milestone_sectors_carry_checks(self) -> None:
        self.assertEqual(locations.selected_sectors(self.world.options),
                         locations.MILESTONE_SECTORS)

    def test_the_floor_still_applies_on_top(self) -> None:
        chosen = set(locations.selected_sectors(self.world.options))
        self.assertTrue(chosen <= set(locations.MILESTONE_SECTORS))


class TestPlannedOptionsAreAnnouncedAtGeneration(FTLTestBase):

    options = {"skill_checks": "per_skill"}
    auto_construct = False

    def test_the_option_is_named_in_the_warning(self) -> None:
        previous = logging.root.manager.disable
        logging.disable(logging.NOTSET)
        try:
            with self.assertLogs("FTL", level="WARNING") as log:
                self.world_setup()
        finally:
            logging.disable(previous)
        self.assertTrue(any("skill_checks" in line for line in log.output),
                        f"no warning names the option: {log.output}")
        self.assertEqual(options.enabled_planned_options(self.world.options), ("skill_checks",))


class TestOptionsLeftAloneSayNothing(FTLTestBase):

    def test_nothing_is_announced_by_default(self) -> None:
        self.assertEqual(options.enabled_planned_options(self.world.options), ())


class TestTheVictoryItemIsCreatedByName(FTLTestBase):

    def test_it_is_progression_and_carries_no_code(self) -> None:
        item = self.world.create_item(data.VICTORY_ITEM_NAME)
        self.assertEqual(item.name, data.VICTORY_ITEM_NAME)
        self.assertIsNone(item.code, "an event item must not carry any id")
        self.assertTrue(item.advancement)


class TestVictoriesBehindLockedShips(FTLTestBase):

    options = {
        "minimum_filler": 0,
        "shop_weapons": 0,
        "shop_drones": 0,
        "shop_augments": 0,
        "crew_members": False,
        "head_starts": False,
        "goal": "victory_selection",
        "victory_layouts": ["Federation Cruiser A", "Lanius Cruiser A", "Rock Cruiser B"],
        "start_ship": "mantis_cruiser",
        "ship_layouts": "up_to_type_b",
        "layout_unlocks": "items",
        "sectorsanity": "disabled",
        "shop_checks": 0,
        "ship_achievements": False,
        "general_achievements": "basic",
        "cross_run_achievements": True,
        "system_blueprints": True,
        "progressive_systems": False,
        "sector_logic": "standard",
    }

    def test_the_logic_was_loosened_out_loud(self) -> None:
        self.assertLess(self.world.logic.sector_logic, self.world.options.sector_logic.value)
        self.assertTrue(self.world.logic.warnings, "a silent downgrade would be a surprise")

    def test_the_victories_are_not_the_only_way_to_find_a_blueprint(self) -> None:

        level = self.world.logic.sector_logic
        free = [
            location for location in self.world.created_locations
            if rules.blueprints_required(level, location) == 0
        ]
        self.assertGreater(len(free), len(self.world.logic.starting_blueprints))


class TestModLanguage(FTLTestBase):

    options = {}

    def test_the_default_leaves_the_choice_to_the_game(self) -> None:
        self.assertIsNone(self.world.fill_slot_data()["language"])

    def test_every_offered_language_maps_to_a_mod_language_file(self) -> None:
        carried = {path.stem for path in LANG_DIR.glob("*.json")}
        for value, code in options.ModLanguage.MOD_CODES.items():
            self.assertIn(code, carried, f"{code} (value {value}) does not exist in mod/lang/")

    def test_the_option_lists_exactly_game_plus_the_carried_languages(self) -> None:
        choices = set(options.ModLanguage.options) - {"game"}
        self.assertEqual(len(choices), len(options.ModLanguage.MOD_CODES))


class TestModLanguageForced(FTLTestBase):
    options = {"mod_language": "french"}

    def test_the_chosen_language_reaches_the_mod(self) -> None:
        self.assertEqual(self.world.fill_slot_data()["language"], "fr")


class TestSectorCeiling(FTLTestBase):

    options = {"sectorsanity": "full", "sectorsanity_first_sector": 2,
               "sectorsanity_last_sector": 5}

    def test_no_sector_check_beyond_the_ceiling(self) -> None:
        deep = [
            location for location in self.addressed_locations()
            if (entry := data.LOCATIONS_BY_NAME.get(location.name))
            and entry.group == data.GROUP_SECTORS
            and entry.sector is not None
            and not 2 <= entry.sector <= 5
        ]
        self.assertEqual(deep, [])

    def test_the_kept_sectors_are_exactly_the_interval(self) -> None:
        kept = {
            entry.sector
            for location in self.addressed_locations()
            if (entry := data.LOCATIONS_BY_NAME.get(location.name))
            and entry.group == data.GROUP_SECTORS
        }
        self.assertEqual(kept, {2, 3, 4, 5})

    def test_victories_are_untouched(self) -> None:
        victories = [
            location for location in self.addressed_locations()
            if (entry := data.LOCATIONS_BY_NAME.get(location.name))
            and entry.group == data.GROUP_VICTORIES
        ]
        self.assertTrue(victories)


class TestSectorCeilingBelowFloor(FTLTestBase):

    options = {"sectorsanity": "full", "sectorsanity_first_sector": 6,
               "sectorsanity_last_sector": 3}

    def test_no_sector_check_at_all(self) -> None:
        sectors = [
            location for location in self.addressed_locations()
            if (entry := data.LOCATIONS_BY_NAME.get(location.name))
            and entry.group == data.GROUP_SECTORS
        ]
        self.assertEqual(sectors, [])

    def test_the_seed_still_generates(self) -> None:
        pool = [item for item in self.multiworld.itempool if item.player == self.player]
        self.assertEqual(len(pool), len(self.addressed_locations()))


class TestSectorCeilingDefaultChangesNothing(FTLTestBase):

    options = {"sectorsanity": "full", "sectorsanity_first_sector": 1}

    def test_every_sector_is_still_a_check(self) -> None:
        kept = {
            entry.sector
            for location in self.addressed_locations()
            if (entry := data.LOCATIONS_BY_NAME.get(location.name))
            and entry.group == data.GROUP_SECTORS
        }
        self.assertEqual(kept, set(range(1, data.SECTOR_COUNT + 1)))


class TestStructurallyBlockedSeed(FTLTestBase):

    options = {
        "minimum_filler": 0,
        "shop_weapons": 0,
        "shop_drones": 0,
        "shop_augments": 0,
        "crew_members": False,
        "head_starts": False,
        "sectorsanity": "full",
        "sectorsanity_first_sector": 5,
        "sectorsanity_last_sector": 8,
        "ship_layouts": "type_a_only",
        "ship_achievements": False,
        "general_achievements": "basic",
        "cross_run_achievements": True,
        "shop_checks": 0,
        "sector_logic": "strict",
        "systemsanity": "disabled",
        "system_blueprints": True,
        "layout_unlocks": "vanilla",
        "start_ship": "crystal_cruiser",
    }

    def test_it_generates_at_all(self) -> None:
        addressed = self.addressed_locations()
        pool = [item for item in self.multiworld.itempool if item.player == self.player]
        self.assertEqual(len(pool), len(addressed))

    def test_the_guard_says_what_it_did(self) -> None:
        self.assertTrue(self.world.logic.warnings, "no warning was logged")

    def test_the_logic_was_loosened_rather_than_the_seed_refused(self) -> None:
        self.assertLess(
            self.world.logic.sector_logic,
            self.world.options.sector_logic.option_strict,
        )


class TestTheGuardLeavesNormalSeedsAlone(FTLTestBase):

    options = {"sector_logic": "strict"}

    def test_strict_stays_strict(self) -> None:
        self.assertEqual(
            self.world.logic.sector_logic,
            self.world.options.sector_logic.option_strict,
        )
        self.assertEqual(self.world.logic.extra_ship_keys, ())
        self.assertEqual(self.world.logic.warnings, ())


class TestArchivesSurvivePoolTrimming(FTLTestBase):

    options = {
        "archives": 40,
        "archives_required": 40,
        "victories_required": 1,
        "shop_checks": 0,
        "sectorsanity": "milestones",
    }

    def test_no_archive_is_trimmed(self) -> None:
        names = [item.name for item in self.multiworld.itempool]
        self.assertEqual(
            names.count(data.ARCHIVE_ITEM_NAME), 40,
            "the goal expects 40: trimming one would make the seed unfinishable",
        )

    def test_the_seed_is_still_winnable(self) -> None:
        state = self.multiworld.get_all_state(False)
        self.assertTrue(self.multiworld.completion_condition[self.player](state))


class TestSystemUpgradesAddUp(FTLTestBase):

    options = {
        "system_blueprints": True,
        "progressive_systems": True,
        "systemsanity": "every_level",
        "shop_checks": 30,
        "sectorsanity": "full",
    }

    def test_a_blueprint_opens_level_one_only(self) -> None:
        for system in data.SYSTEMS:
            descriptor = data.item_descriptor(data.ITEMS_BY_NAME[f"{system.display} blueprint"])
            self.assertEqual(descriptor.get("n"), 0,
                             f"{system.display}: the blueprint must not raise the cap")

    def test_upgrades_reach_the_maximum_and_not_beyond(self) -> None:
        names = [item.name for item in self.multiworld.itempool] + list(self.world.precollected_item_names)
        for system in data.SYSTEMS:
            received = names.count(f"Progressive {system.display}")
            self.assertLessEqual(1 + received, system.max_level,
                                 f"{system.display}: an upgrade past the maximum is useless")

    def test_the_mod_knows_blueprints_and_caps_are_on(self) -> None:
        slot = self.world.fill_slot_data()
        self.assertTrue(slot["system_blueprints"])
        self.assertTrue(slot["system_caps"])


class TestNoBlueprintsNoCaps(FTLTestBase):

    options = {"system_blueprints": False, "progressive_systems": False}

    def test_the_mod_is_told_both_are_off(self) -> None:
        slot = self.world.fill_slot_data()
        self.assertFalse(slot["system_blueprints"], "otherwise the mod refuses to sell any system")
        self.assertFalse(slot["system_caps"], "otherwise the mod caps everything at level 1")


class TestCrewChecks(FTLTestBase):

    def test_seven_races_are_checks_by_default_and_crystal_is_not(self) -> None:
        crew = [location.name for location in self.addressed_locations()
                if data.LOCATIONS_BY_NAME[location.name].group == data.GROUP_CREW]
        self.assertEqual(len(crew), 7)
        self.assertIn("First Zoltan aboard", crew)
        self.assertFalse(any("Crystal" in name for name in crew))


class TestCrewChecksOff(FTLTestBase):
    options = {"crew_checks": False}

    def test_no_race_is_a_check(self) -> None:
        self.assertFalse([location for location in self.addressed_locations()
                          if data.LOCATIONS_BY_NAME[location.name].group == data.GROUP_CREW])


class TestCrewMembers(FTLTestBase):

    def test_each_race_is_progressive_with_an_expert_tier(self) -> None:
        names = [item.name for item in self.multiworld.itempool]
        self.assertEqual(names.count("Progressive Zoltan Crew"), 3, "normal, menu, expert")
        self.assertEqual(names.count("Progressive Lanius Crew"), 2, "no Lanius expert")
        self.assertNotIn("Zoltan Shield Expert", names, "the old items stay out of the pool")

    def test_the_mod_is_told_the_race_the_expert_skill_and_the_tiers(self) -> None:
        descriptor = self.world.fill_slot_data()["items"]["Progressive Zoltan Crew"]
        self.assertEqual(descriptor, {"k": "crew", "race": "energy", "skill": "shields", "tiers": 3})


class TestCrewMembersOff(FTLTestBase):
    options = {"crew_members": False}

    def test_no_crew_member_is_in_the_pool(self) -> None:
        self.assertFalse([item for item in self.multiworld.itempool
                          if data.ITEMS_BY_NAME[item.name].group == data.GROUP_CREW_MEMBERS])


class TestWeaponsComeTwice(FTLTestBase):
    options = {"sectorsanity": "full", "shop_checks": 60, "general_achievements": "all"}

    def test_a_weapon_has_two_copies_and_an_augment_one(self) -> None:
        names = [item.name for item in self.multiworld.itempool]
        weapon = next(item for item in data.ITEMS if item.family == "weapon")
        augment = next(item for item in data.ITEMS if item.family == "augment")
        self.assertEqual(names.count(weapon.name), 2, "the weapon, then its slot at the run start menu")
        self.assertEqual(names.count(augment.name), 1)


def _filler_count(test: FTLTestBase) -> int:
    return len([item for item in test.multiworld.itempool
                if data.ITEMS_BY_NAME[item.name].group in (data.GROUP_FILLER, data.GROUP_TRAPS)])


def _real_items_expected(test: FTLTestBase) -> int:
    return items.items_wanting_a_place(test.world)


class TestMoreItemsThanChecksGrowsTheShop(FTLTestBase):
    options = {"sectorsanity": "milestones"}

    def test_the_shop_grows_and_filler_stays_at_its_floor(self) -> None:
        self.assertGreater(self.world.options.shop_checks.value, 20, "the shop grew")
        self.assertGreaterEqual(_filler_count(self), 20, "the minimum is respected")
        self.assertLessEqual(_filler_count(self), 24,
                             "and almost nothing above it: only items given at the start free up a slot")

    def test_no_item_is_left_out(self) -> None:
        places = {item.name for item in self.multiworld.itempool}
        places.update(self.world.precollected_item_names)
        for item in self.world.enabled_items:
            if item.count and item.group not in (data.GROUP_FILLER, data.GROUP_TRAPS, data.GROUP_ARCHIVES):
                self.assertIn(item.name, places, "every item has its place")


class TestMoreChecksThanItemsAddsFiller(FTLTestBase):
    options = {"sectorsanity": "full", "sectorsanity_first_sector": 1, "general_achievements": "all",
               "systemsanity": "every_level", "shop_weapons": 0, "shop_drones": 0, "shop_augments": 0,
               "crew_members": False}

    def test_the_shop_stays_at_its_floor_and_filler_fills_the_gap(self) -> None:
        self.assertEqual(self.world.options.shop_checks.value, 20, "the shop stays at its minimum")
        self.assertGreater(_filler_count(self), 20, "filler makes up the gap")


class TestTheFloorsAreSettings(FTLTestBase):
    options = {"sectorsanity": "milestones", "minimum_filler": 40, "shop_checks": 35}

    def test_both_floors_are_respected(self) -> None:
        self.assertGreaterEqual(self.world.options.shop_checks.value, 35)
        self.assertGreaterEqual(_filler_count(self), 40)
