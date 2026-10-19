from __future__ import annotations

from BaseClasses import CollectionState

from .. import data, rules
from .bases import FTLTestBase

KESTREL_A = data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_HARD"]
MANTIS_B = data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_MANTIS_2"]
STEALTH_A = data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_STEALTH"]


def _state_with(test: FTLTestBase, layout: data.Layout, names=()) -> CollectionState:
    state = CollectionState(test.multiworld)
    for item in test.multiworld.precollected_items[test.player]:
        state.collect(item, prevent_sweep=True)
    for name in (*rules.layout_requirements(test.world, layout), *names):
        state.collect(test.world.create_item(name), prevent_sweep=True)
    return state


def _reach(test: FTLTestBase, layout: data.Layout, check: str, state: CollectionState) -> bool:
    return test.multiworld.get_location(f"{layout.display}: {check}", test.player).can_reach(state)


def _times(name: str, count: int) -> list[str]:
    return [name] * count


class TestPowerMilestonesOnTheShipThatDoesTheCheck(FTLTestBase):

    options = {"layout_count": 28, "sector_logic": "power"}

    def test_the_option_is_kept(self) -> None:
        self.assertEqual(self.world.sector_logic_level, rules.SectorLogic.option_power)

    def test_sector_5_waits_for_two_shield_layers(self) -> None:
        state = _state_with(self, KESTREL_A)
        self.assertTrue(_reach(self, KESTREL_A, "Reach sector 4", state), "sector 4 has no milestone")
        self.assertFalse(_reach(self, KESTREL_A, "Reach sector 5", state), "the Kestrel starts with one layer")
        state = _state_with(self, KESTREL_A, ["Progressive Shields"])
        self.assertFalse(_reach(self, KESTREL_A, "Reach sector 5", state), "3 shield levels are still one layer")
        state = _state_with(self, KESTREL_A, _times("Progressive Shields", 2))
        self.assertTrue(_reach(self, KESTREL_A, "Reach sector 5", state))

    def test_a_ship_that_starts_with_two_layers_meets_sector_5_at_once(self) -> None:
        state = _state_with(self, MANTIS_B)
        self.assertTrue(_reach(self, MANTIS_B, "Reach sector 5", state), "the Mantis B starts with 4 shield levels")
        self.assertFalse(_reach(self, MANTIS_B, "Reach sector 8", state), "but with weapons 1")

    def test_sector_8_also_needs_weapons_5(self) -> None:
        shields = _times("Progressive Shields", 2)
        state = _state_with(self, KESTREL_A, shields + _times("Progressive Weapon Control", 1))
        self.assertFalse(_reach(self, KESTREL_A, "Reach sector 8", state))
        state = _state_with(self, KESTREL_A, shields + _times("Progressive Weapon Control", 2))
        self.assertTrue(_reach(self, KESTREL_A, "Reach sector 8", state))

    def test_the_flagship_needs_three_layers_weapons_6_and_engines_4(self) -> None:
        enough = (_times("Progressive Shields", 4) + _times("Progressive Weapon Control", 3)
                  + _times("Progressive Engines", 2))
        self.assertTrue(_reach(self, KESTREL_A, "Defeat the Flagship", _state_with(self, KESTREL_A, enough)))
        for missing in ("Progressive Shields", "Progressive Weapon Control", "Progressive Engines"):
            short = list(enough)
            short.remove(missing)
            self.assertFalse(_reach(self, KESTREL_A, "Defeat the Flagship", _state_with(self, KESTREL_A, short)),
                             f"one {missing} short")

    def test_a_shieldless_ship_trades_one_layer_for_engines_5_before_the_flagship(self) -> None:
        state = _state_with(self, STEALTH_A, ["Progressive Engines"])
        self.assertFalse(_reach(self, STEALTH_A, "Reach sector 5", state), "no shields at all: one layer is still due")
        state = _state_with(self, STEALTH_A, ["Shields blueprint", "Progressive Shields"])
        self.assertFalse(_reach(self, STEALTH_A, "Reach sector 5", state), "one layer, but engines 4")
        state = _state_with(self, STEALTH_A, ["Shields blueprint", "Progressive Shields", "Progressive Engines"])
        self.assertTrue(_reach(self, STEALTH_A, "Reach sector 5", state))

    def test_the_flagship_asks_the_same_of_a_shieldless_ship(self) -> None:
        engines_and_weapons = _times("Progressive Engines", 1) + _times("Progressive Weapon Control", 4)
        state = _state_with(self, STEALTH_A, engines_and_weapons + ["Shields blueprint"]
                            + _times("Progressive Shields", 4))
        self.assertFalse(_reach(self, STEALTH_A, "Defeat the Flagship", state), "a bought system starts at level 1")
        state.collect(self.world.create_item("Progressive Shields"), prevent_sweep=True)
        self.assertTrue(_reach(self, STEALTH_A, "Defeat the Flagship", state))

    def test_a_victory_counts_for_the_goal_only_on_a_ship_ready_for_the_flagship(self) -> None:
        goal = self.multiworld.completion_condition[self.player]
        all_keys = [name for layout in self.world.selected_layouts
                    for name in rules.layout_requirements(self.world, layout)]
        state = _state_with(self, KESTREL_A, all_keys)
        self.assertFalse(goal(state), "every ship is open, none is upgraded")

    def test_the_upgrades_it_reads_are_progression(self) -> None:
        for name in ("Progressive Shields", "Progressive Weapon Control", "Progressive Engines",
                     "Shields blueprint"):
            self.assertTrue(self.world.create_item(name).advancement, name)
        self.assertIn("Shields blueprint", self.world.logic.progression_blueprints)


class TestPowerMilestonesFollowVictoryDifficulty(FTLTestBase):

    options = {"layout_count": 28, "sector_logic": "power", "victory_difficulty": "hard"}

    def test_the_flagship_needs_four_layers_on_hard(self) -> None:
        upgrades = _times("Progressive Weapon Control", 4) + _times("Progressive Engines", 2)
        state = _state_with(self, KESTREL_A, upgrades + _times("Progressive Shields", 5))
        self.assertFalse(_reach(self, KESTREL_A, "Defeat the Flagship", state))
        state = _state_with(self, KESTREL_A, upgrades + _times("Progressive Shields", 6))
        self.assertTrue(_reach(self, KESTREL_A, "Defeat the Flagship", state))


class TestPowerMilestonesAreGentlerWhenEasyWinsCount(FTLTestBase):

    options = {"layout_count": 28, "sector_logic": "power", "victory_difficulty": "any"}

    def test_the_flagship_needs_two_layers(self) -> None:
        upgrades = _times("Progressive Shields", 2) + _times("Progressive Weapon Control", 2)
        state = _state_with(self, KESTREL_A, upgrades)
        self.assertFalse(_reach(self, KESTREL_A, "Defeat the Flagship", state), "engines 2 of 3")
        state = _state_with(self, KESTREL_A, upgrades + ["Progressive Engines"])
        self.assertTrue(_reach(self, KESTREL_A, "Defeat the Flagship", state))


class TestPowerMilestonesWithUpgradesPerShip(FTLTestBase):

    options = {"layout_count": 28, "sector_logic": "power", "progressive_systems_per_ship": True}

    def test_only_the_ships_own_upgrades_count(self) -> None:
        kestrel = data.SHIPS_BY_BLUEPRINT[KESTREL_A.ship].display
        mantis = data.SHIPS_BY_BLUEPRINT["PLAYER_SHIP_MANTIS"].display
        state = _state_with(self, KESTREL_A, _times(f"{mantis}: Progressive Shields", 2))
        self.assertFalse(_reach(self, KESTREL_A, "Reach sector 5", state), "the Mantis upgrades are not the Kestrel's")
        state = _state_with(self, KESTREL_A, _times(f"{kestrel}: Progressive Shields", 2))
        self.assertTrue(_reach(self, KESTREL_A, "Reach sector 5", state))
        self.assertTrue(self.world.create_item(f"{kestrel}: Progressive Engines").advancement)


class TestPowerMilestonesWithFullSystemUpgrades(FTLTestBase):

    options = {"layout_count": 28, "sector_logic": "power", "full_system_upgrades": True}

    def test_one_item_per_system_is_enough(self) -> None:
        state = _state_with(self, KESTREL_A, ["Progressive Shields", "Progressive Weapon Control",
                                              "Progressive Engines"])
        self.assertTrue(_reach(self, KESTREL_A, "Defeat the Flagship", state))


class TestPowerMilestonesWithoutProgressiveUpgrades(FTLTestBase):

    options = {"layout_count": 28, "sector_logic": "power", "progressive_systems": False}

    def test_levels_bought_with_scrap_are_never_waited_for(self) -> None:
        self.assertTrue(_reach(self, KESTREL_A, "Defeat the Flagship", _state_with(self, KESTREL_A)))

    def test_a_shieldless_ship_still_waits_for_its_shields_blueprint(self) -> None:
        self.assertFalse(_reach(self, STEALTH_A, "Defeat the Flagship", _state_with(self, STEALTH_A)))
        self.assertTrue(_reach(self, STEALTH_A, "Defeat the Flagship",
                               _state_with(self, STEALTH_A, ["Shields blueprint"])))


class TestPowerLogicWithoutBlueprints(FTLTestBase):

    options = {"layout_count": 28, "sector_logic": "power", "system_blueprints": False}

    def test_power_is_kept_without_blueprints(self) -> None:
        self.assertEqual(self.world.sector_logic_level, rules.SectorLogic.option_power)
        state = _state_with(self, STEALTH_A, ["Progressive Shields", "Progressive Engines"])
        self.assertTrue(_reach(self, STEALTH_A, "Reach sector 5", state), "shields are bought without a blueprint")


class TestStandardStaysTheDefault(FTLTestBase):

    def test_existing_seeds_keep_their_logic(self) -> None:
        self.assertEqual(self.world.options.sector_logic.value, rules.SectorLogic.option_standard)
        self.assertEqual(self.world.sector_logic_level, rules.SectorLogic.option_standard)


class TestStandardAddsTheMilestonesWithProgressiveUpgrades(FTLTestBase):

    options = {"layout_count": 28}

    def test_five_blueprints_and_one_shield_layer_are_not_enough_for_the_flagship(self) -> None:
        blueprints = [name for name in data.BLUEPRINT_ITEM_NAMES.values()
                      if name not in rules.layout_requirements(self.world, KESTREL_A)][:5]
        state = _state_with(self, KESTREL_A, blueprints)
        self.assertFalse(_reach(self, KESTREL_A, "Defeat the Flagship", state), "the Kestrel has one layer")
        enough = (_times("Progressive Shields", 4) + _times("Progressive Weapon Control", 3)
                  + _times("Progressive Engines", 2))
        self.assertFalse(_reach(self, KESTREL_A, "Defeat the Flagship", _state_with(self, KESTREL_A, enough)),
                         "the blueprints are still due")
        self.assertTrue(_reach(self, KESTREL_A, "Defeat the Flagship",
                               _state_with(self, KESTREL_A, blueprints + enough)))

    def test_sector_5_waits_for_two_shield_layers(self) -> None:
        blueprints = [name for name in data.BLUEPRINT_ITEM_NAMES.values()
                      if name not in rules.layout_requirements(self.world, KESTREL_A)][:2]
        self.assertFalse(_reach(self, KESTREL_A, "Reach sector 5", _state_with(self, KESTREL_A, blueprints)))
        state = _state_with(self, KESTREL_A, blueprints + _times("Progressive Shields", 2))
        self.assertTrue(_reach(self, KESTREL_A, "Reach sector 5", state))

    def test_the_upgrades_it_reads_are_progression(self) -> None:
        for name in ("Progressive Shields", "Progressive Weapon Control", "Progressive Engines"):
            self.assertTrue(self.world.create_item(name).advancement, name)


class TestStrictAddsTheMilestonesToo(FTLTestBase):

    options = {"layout_count": 28, "sector_logic": "strict"}

    def test_the_flagship_needs_shield_layers(self) -> None:
        if self.world.sector_logic_level != rules.SectorLogic.option_strict:
            self.skipTest("strict was lowered for this seed")
        blueprints = [name for name in data.BLUEPRINT_ITEM_NAMES.values()
                      if name not in rules.layout_requirements(self.world, KESTREL_A)][:11]
        self.assertFalse(_reach(self, KESTREL_A, "Defeat the Flagship", _state_with(self, KESTREL_A, blueprints)))


class TestStandardWithoutProgressiveUpgradesOnlyCountsBlueprints(FTLTestBase):

    options = {"layout_count": 28, "progressive_systems": False}

    def test_no_milestone_when_levels_are_bought_with_scrap(self) -> None:
        self.assertEqual(rules.power_upgrade_names(self.world.options), frozenset())
        blueprints = [name for name in data.BLUEPRINT_ITEM_NAMES.values()
                      if name not in rules.layout_requirements(self.world, KESTREL_A)][:5]
        self.assertTrue(_reach(self, KESTREL_A, "Defeat the Flagship", _state_with(self, KESTREL_A, blueprints)))


class TestStandardWithoutBlueprintsBecomesPower(FTLTestBase):

    options = {"layout_count": 28, "system_blueprints": False}

    def test_capped_levels_still_get_their_milestones(self) -> None:
        self.assertEqual(self.world.sector_logic_level, rules.SectorLogic.option_power)
        self.assertFalse(_reach(self, KESTREL_A, "Reach sector 5", _state_with(self, KESTREL_A)))


class TestRelaxedWithoutBlueprintsStaysRelaxed(FTLTestBase):
    """none asks for nothing: no blueprints to count must not turn it into power (whose shields need a
    blueprint the pool no longer has). Written with its old name, relaxed, which old YAMLs still use."""

    options = {"layout_count": 28, "sector_logic": "relaxed", "system_blueprints": False}

    def test_relaxed_is_kept(self) -> None:
        self.assertEqual(self.world.sector_logic_level, rules.SectorLogic.option_none)


MV_KESTREL = data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_MVKESTREL"]


class TestPowerMilestonesOnMultiverseShips(FTLTestBase):

    options = {"multiverse": True, "sector_logic": "power"}

    def test_a_multiverse_ship_is_judged_from_its_own_start(self) -> None:
        self.assertEqual(data.LAYOUT_START_LEVELS[MV_KESTREL.blueprint],
                         {"shields": 2, "weapons": 3, "engines": 2})
        state = _state_with(self, MV_KESTREL)
        self.assertTrue(_reach(self, MV_KESTREL, "Reach sector 4", state))
        self.assertFalse(_reach(self, MV_KESTREL, "Reach sector 5", state), "the MV Kestrel starts with one layer")
        state = _state_with(self, MV_KESTREL, _times("Progressive Shields", 2))
        self.assertTrue(_reach(self, MV_KESTREL, "Reach sector 5", state))

    def test_every_multiverse_layout_has_its_start_levels(self) -> None:
        for layout in data.MV_LAYOUTS:
            self.assertIn(layout.blueprint, data.LAYOUT_START_LEVELS)
