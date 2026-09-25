from __future__ import annotations

from BaseClasses import CollectionState
from Fill import distribute_items_restrictive
from test.bases import WorldTestBase

from .. import FTLWorld, data


class FTLTestBase(WorldTestBase):
    game = data.GAME_NAME
    world: FTLWorld

    def addressed_locations(self):
        return [
            location for location in self.multiworld.get_locations(self.player)
            if location.address is not None
        ]

    def event_locations(self):
        return [
            location for location in self.multiworld.get_locations(self.player)
            if location.address is None
        ]

    def test_the_seed_can_be_beaten_by_playing_it(self) -> None:
        if not self.run_default_tests:
            self.skipTest("class without options: nothing generated to check")
        if not getattr(self, "auto_construct", True):
            self.skipTest("class testing a generation refusal: no world built")
        distribute_items_restrictive(self.multiworld)
        state = CollectionState(self.multiworld)
        state.sweep_for_advancements()
        self.assertTrue(
            self.multiworld.has_beaten_game(state, self.player),
            "the goal stays out of reach starting from nothing: the seed cannot be finished",
        )
