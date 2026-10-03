from __future__ import annotations

from BaseClasses import CollectionState

from .. import data, locations, rules
from .bases import FTLTestBase


def _fresh_state(test: FTLTestBase) -> CollectionState:
    state = CollectionState(test.multiworld)
    for item in test.multiworld.precollected_items[test.player]:
        state.collect(item, prevent_sweep=True)
    return state


def _collect(test: FTLTestBase, state: CollectionState, names) -> None:
    for name in names:
        state.collect(test.world.create_item(name), prevent_sweep=True)


def _reachable_layouts(test: FTLTestBase, state: CollectionState) -> list[data.Layout]:
    return [
        layout for layout in locations.selected_layouts(test.world.options)
        if state.can_reach_region(locations.region_name(layout), test.player)
    ]


def _open_layout(test: FTLTestBase, state: CollectionState, layout: data.Layout) -> None:
    _collect(test, state, rules.layout_requirements(test.world, layout))


class TestInstallingASystemNeedsAShipOrABlueprint(FTLTestBase):

    options = {"layout_count": 28, "systemsanity": "first_install", "sector_logic": "standard"}

    def test_a_system_no_reachable_ship_carries_waits_for_its_blueprint(self) -> None:
        state = _fresh_state(self)
        at_start = {s for layout in _reachable_layouts(self, state) for s in layout.start_systems}
        absent = next(system for system in data.SYSTEMS if system.system_id not in at_start
                      and system.system_id in data.BLUEPRINT_ITEM_NAMES)
        location = self.multiworld.get_location(f"Install {absent.display}", self.player)

        self.assertFalse(location.can_reach(state),
                         "no reachable ship has it at the start and no blueprint is there")

        _collect(self, state, [data.BLUEPRINT_ITEM_NAMES[absent.system_id]])
        with_slot = any(absent.system_id in layout.empty_slots
                        for layout in _reachable_layouts(self, state))
        self.assertEqual(location.can_reach(state), with_slot,
                         "with the blueprint, any reachable ship with room for it is enough")

    def test_a_ship_that_starts_with_it_is_enough(self) -> None:
        state = _fresh_state(self)
        stealth = data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_STEALTH"]
        _open_layout(self, state, stealth)
        cloaking = self.multiworld.get_location("Install Cloaking", self.player)
        self.assertTrue(cloaking.can_reach(state), "the Stealth A starts with cloaking")


class TestArtilleryIsNeverBought(FTLTestBase):

    options = {"layout_count": 28, "systemsanity": "first_install", "sector_logic": "standard"}

    def test_only_the_federation_cruiser_installs_it(self) -> None:
        state = _fresh_state(self)
        kestrel = data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_HARD"]
        _open_layout(self, state, kestrel)
        _collect(self, state, [data.BLUEPRINT_ITEM_NAMES["artillery"]])
        artillery = self.multiworld.get_location("Install Artillery Beam", self.player)
        if any("artillery" in layout.start_systems for layout in _reachable_layouts(self, state)):
            self.skipTest("a Federation ship is already reachable in this seed")
        self.assertFalse(artillery.can_reach(state),
                         "no shop sells artillery: the blueprint alone is not enough")


class TestFullArsenalCountsTheSystemsTheKestrelCanTake(FTLTestBase):

    options = {"layout_count": 28, "ship_achievements": True, "sector_logic": "standard", "systemsanity": "disabled"}

    def test_three_extra_systems_and_not_two(self) -> None:
        state = _fresh_state(self)
        kestrel = data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_HARD"]
        _open_layout(self, state, kestrel)
        arsenal = self.multiworld.get_location("Kestrel Cruiser: Full Arsenal", self.player)

        _collect(self, state, [data.BLUEPRINT_ITEM_NAMES["drones"],
                               data.BLUEPRINT_ITEM_NAMES["teleporter"]])
        self.assertFalse(arsenal.can_reach(state), "eight at the start plus two makes ten, not eleven")

        _collect(self, state, [data.BLUEPRINT_ITEM_NAMES["clonebay"]])
        self.assertFalse(arsenal.can_reach(state),
                         "the clone bay replaces the medbay: it does not add a system")

        _collect(self, state, [data.BLUEPRINT_ITEM_NAMES["cloaking"]])
        self.assertTrue(arsenal.can_reach(state), "the third system makes eleven")


class TestAdvancedMasteryNeedsTheThreeSystems(FTLTestBase):

    options = {"layout_count": 28, "ship_achievements": True, "sector_logic": "standard", "systemsanity": "disabled"}

    def test_the_lanius_a_needs_mind_control_and_the_battery(self) -> None:
        state = _fresh_state(self)
        lanius = data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_ANAEROBIC"]
        _open_layout(self, state, lanius)
        mastery = self.multiworld.get_location("Lanius Cruiser: Advanced Mastery", self.player)

        _collect(self, state, [data.BLUEPRINT_ITEM_NAMES["mind"]])
        self.assertFalse(mastery.can_reach(state), "the battery is still missing")
        _collect(self, state, [data.BLUEPRINT_ITEM_NAMES["battery"]])
        self.assertTrue(mastery.can_reach(state))


class TestTheZoltanPowerFeatNeedsEveryLevel(FTLTestBase):

    options = {"layout_count": 28, "ship_achievements": True, "sector_logic": "standard", "systemsanity": "disabled",
               "progressive_systems": True}

    def test_the_upgrades_are_progression_and_all_of_them_are_needed(self) -> None:
        location = self.multiworld.get_location(
            "Zoltan Cruiser: Givin' her all she's got, Captain!", self.player)
        needed = [f"Progressive {data.SYSTEMS_BY_ID[s].display}"
                  for s in rules.SYSTEMS_AN_ACHIEVEMENT_MAXES["ACH_ENERGY_POWER"]]
        for name in needed:
            self.assertTrue(self.world.create_item(name).advancement,
                            f"{name} must be progression, otherwise the logic does not see it")

        state = self.multiworld.get_all_state(False)
        self.assertTrue(location.can_reach(state))
        state.remove(self.world.create_item(needed[0]))
        self.assertFalse(location.can_reach(state), "one level less, and 29 power is out of reach")


class TestWithoutBlueprintsASlotIsEnough(FTLTestBase):

    options = {"systemsanity": "first_install", "system_blueprints": False}

    def test_a_ship_with_room_for_it_can_buy_it(self) -> None:
        state = _fresh_state(self)
        kestrel = data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_HARD"]
        _open_layout(self, state, kestrel)
        cloaking = self.multiworld.get_location("Install Cloaking", self.player)
        self.assertTrue(cloaking.can_reach(state),
                        "without blueprints, any shop sells cloaking to the Kestrel which has room for it")


class TestSystemsanityPerShip(FTLTestBase):
    options = {"layout_count": 28, "systemsanity": "first_install", "systemsanity_per_ship": True}

    def names(self) -> set[str]:
        return {location.name for location in self.world.created_locations}

    def test_each_ship_has_its_own_install_checks(self) -> None:
        self.assertIn("Kestrel Cruiser: Install Cloaking", self.names())
        self.assertIn("Stealth Cruiser: Install Shields", self.names())
        self.assertNotIn("Install Cloaking", self.names())

    def test_a_ship_never_counts_a_system_it_can_start_with(self) -> None:
        self.assertNotIn("Kestrel Cruiser: Install Shields", self.names())
        self.assertNotIn("Kestrel Cruiser: Install Clone Bay", self.names(), "the Kestrel C starts with it")
        self.assertNotIn("Stealth Cruiser: Install Cloaking", self.names())

    def test_the_check_waits_for_the_blueprint(self) -> None:
        location = self.multiworld.get_location("Kestrel Cruiser: Install Cloaking", self.player)
        state = self.multiworld.state.copy()
        self.assertFalse(location.can_reach(state))
        state.collect(self.world.create_item("Cloaking blueprint"), True)
        self.assertTrue(location.can_reach(state))


class TestSystemsanityPerShipOff(FTLTestBase):
    options = {"systemsanity": "first_install"}

    def test_the_install_checks_stay_shared(self) -> None:
        names = {location.name for location in self.world.created_locations}
        self.assertIn("Install Cloaking", names)
        self.assertFalse(any(location.group == data.GROUP_SHIP_SYSTEMS
                             for location in self.world.created_locations))


class TestProgressiveUpgradesPerShip(FTLTestBase):
    options = {"layout_count": 1, "start_ship": "kestrel_cruiser", "victories_required": 1,
               "progressive_systems_per_ship": True, "systemsanity": "every_level"}

    def test_each_ship_has_its_own_upgrades(self) -> None:
        names = {item.name: item for item in self.world.enabled_items}
        self.assertNotIn("Progressive Shields", names)
        self.assertEqual(names["Kestrel Cruiser: Progressive Shields"].count, 7)
        self.assertNotIn("Engi Cruiser: Progressive Shields", names, "the Engi is not in this seed")
        descriptor = data.item_descriptor(names["Kestrel Cruiser: Progressive Shields"])
        self.assertEqual(descriptor, {"k": "cap", "sys": "shields", "ship": "PLAYER_SHIP_HARD"})

    def test_only_the_starting_ship_s_upgrades_carry_the_level_checks(self) -> None:
        from ..items import effective_classification
        kestrel = data.ITEMS_BY_NAME["Kestrel Cruiser: Progressive Shields"]
        self.assertEqual(effective_classification(self.world, kestrel), "progression")

    def test_a_level_check_waits_for_that_ship_s_upgrades(self) -> None:
        location = self.multiworld.get_location("Shields level 3", self.player)
        state = self.multiworld.get_all_state(False)
        state.remove(self.world.create_item("Kestrel Cruiser: Progressive Shields"))
        for _ in range(6):
            state.remove(self.world.create_item("Kestrel Cruiser: Progressive Shields"))
        self.assertFalse(location.can_reach(state))
        state.collect(self.world.create_item("Kestrel Cruiser: Progressive Shields"), True)
        state.collect(self.world.create_item("Kestrel Cruiser: Progressive Shields"), True)
        self.assertTrue(location.can_reach(state))


class TestProgressiveUpgradesPerShipOnABigSeed(FTLTestBase):
    options = {"layout_count": 28, "progressive_systems_per_ship": True, "weapon_bundle_size": 1, "drone_bundle_size": 1, "augment_bundle_size": 1}

    def test_the_shop_stops_at_its_limit_instead_of_refusing_the_seed(self) -> None:
        self.assertEqual(self.world.options.shop_checks.value, data.MAX_SHOP_SLOTS)
        self.assertEqual(len(self.multiworld.itempool), len(self.addressed_locations()))


class TestProgressiveUpgradesPerShipStayUseful(FTLTestBase):
    options = {"layout_count": 28, "start_ship": "kestrel_cruiser", "progressive_systems_per_ship": True,
               "systemsanity": "every_level"}

    def test_the_other_ships_upgrades_are_not_progression(self) -> None:
        from ..items import effective_classification
        kestrel = data.ITEMS_BY_NAME["Kestrel Cruiser: Progressive Shields"]
        rock = data.ITEMS_BY_NAME["Rock Cruiser: Progressive Shields"]
        self.assertEqual(effective_classification(self.world, kestrel), "progression")
        self.assertEqual(effective_classification(self.world, rock), "useful")


class TestProgressiveUpgradesPerShipNeedTheSameShip(FTLTestBase):
    options = {"layout_count": 28, "start_ship": "kestrel_cruiser", "progressive_systems_per_ship": True,
               "systemsanity": "every_level", "system_blueprints": True}

    def test_the_kestrel_s_upgrades_do_not_count_on_the_stealth(self) -> None:
        location = self.multiworld.get_location("Cloaking level 2", self.player)
        state = CollectionState(self.multiworld)
        for name in ("Stealth Cruiser Key", "Kestrel Cruiser: Progressive Cloaking"):
            state.collect(self.world.create_item(name), True)
        self.assertFalse(location.can_reach(state), "the Kestrel still needs the Cloaking blueprint")
        state.collect(self.world.create_item("Cloaking blueprint"), True)
        self.assertTrue(location.can_reach(state))
