from __future__ import annotations

from BaseClasses import CollectionState

from .. import data
from .bases import FTLTestBase


def _pool_names(test: FTLTestBase) -> list[str]:
    return [item.name for item in test.multiworld.itempool if item.player == test.player]


class TestTheFirstProgressiveUnlocksTheSystem(FTLTestBase):

    options = {"progressive_unlocks_system": True}

    def test_no_blueprint_item_for_a_system_that_has_a_progressive_one(self) -> None:
        pool = _pool_names(self)
        for source, blueprint in self.world.system_unlocks.items():
            self.assertNotIn(blueprint, pool, f"{blueprint} is given by {source}")
        self.assertTrue(any(name in pool for name in self.world.system_unlocks), "the Progressive items stay")

    def test_the_first_copy_counts_as_the_blueprint_once(self) -> None:
        source, blueprint = next(iter(sorted(self.world.system_unlocks.items())))
        state = CollectionState(self.multiworld)
        self.assertFalse(state.has(blueprint, self.player))
        first = self.world.create_item(source)
        state.collect(first, prevent_sweep=True)
        self.assertTrue(state.has(blueprint, self.player), "the first copy unlocks the system")
        state.collect(self.world.create_item(source), prevent_sweep=True)
        self.assertEqual(state.count(blueprint, self.player), 1, "a second copy is a level, not a blueprint")
        state.remove(first)
        self.assertTrue(state.has(blueprint, self.player), "one copy left: still unlocked")
        state.remove(self.world.create_item(source))
        self.assertFalse(state.has(blueprint, self.player), "none left: locked again")

    def test_a_blueprint_wanted_early_is_its_progressive_item(self) -> None:
        early = self.multiworld.local_early_items[self.player]
        for blueprint in self.world.logic.early_blueprints:
            if blueprint in self.world.system_unlocks.values():
                self.assertNotIn(blueprint, early, "no such item in the pool")
                self.assertTrue(any(self.world.system_unlocks.get(name) == blueprint for name in early))

    def test_the_progressive_items_are_progression(self) -> None:
        for item in self.multiworld.itempool:
            if item.player == self.player and item.name in self.world.system_unlocks:
                self.assertTrue(item.advancement, item.name)

    def test_the_mod_is_told(self) -> None:
        slot_data = self.world.fill_slot_data()
        self.assertIn(data.KIND_CAP_UNLOCK, slot_data["kinds_required"], "an older mod refuses the seed")
        source = next(iter(self.world.system_unlocks))
        self.assertTrue(slot_data["items"][source]["ub"])
        self.assertEqual(slot_data["logic"]["unlocks"], dict(sorted(self.world.system_unlocks.items())))


class TestPerShipProgressiveItemsUnlockTheSystemToo(FTLTestBase):

    options = {"progressive_unlocks_system": True, "progressive_systems_per_ship": True}

    def test_one_ship_s_upgrade_unlocks_the_system_for_all(self) -> None:
        by_blueprint: dict[str, list[str]] = {}
        for source, blueprint in self.world.system_unlocks.items():
            by_blueprint.setdefault(blueprint, []).append(source)
        blueprint, sources = next((b, s) for b, s in sorted(by_blueprint.items()) if len(s) > 1)
        state = CollectionState(self.multiworld)
        for source in sources[:2]:
            state.collect(self.world.create_item(source), prevent_sweep=True)
        self.assertEqual(state.count(blueprint, self.player), 1, "two ships' upgrades, still one blueprint")
        self.assertNotIn(blueprint, _pool_names(self))


class TestTheOptionIsOffByDefault(FTLTestBase):

    def test_blueprints_stay_items(self) -> None:
        self.assertEqual(self.world.system_unlocks, {})
        self.assertIn(data.BLUEPRINT_ITEM_NAMES["cloaking"], _pool_names(self) + [
            item.name for item in self.multiworld.precollected_items[self.player]])


class TestNothingChangesWithoutBlueprints(FTLTestBase):

    options = {"progressive_unlocks_system": True, "system_blueprints": False}

    def test_no_unlock_when_blueprints_are_not_items(self) -> None:
        self.assertEqual(self.world.system_unlocks, {})
