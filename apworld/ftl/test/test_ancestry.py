from __future__ import annotations

from .. import data
from .bases import FTLTestBase


class TestAncestryNeedsRockC(FTLTestBase):
    options = {"layout_count": 28, "ship_achievements": True, "ship_layouts": "all_layouts"}

    def test_ancestry_is_sold_by_the_rock_c(self) -> None:
        location = self.multiworld.get_location("Rock Cruiser: Ancestry", self.player)
        self.assertEqual(location.parent_region.name, data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_ROCK_3"].display,
                         "without the Rock C's Crystal crew member the secret sector is mostly luck")

    def test_the_other_rock_achievements_stay_with_any_layout(self) -> None:
        location = self.multiworld.get_location("Rock Cruiser: Is it warm in here?", self.player)
        self.assertEqual(location.parent_region.name, data.LAYOUTS_BY_BLUEPRINT["PLAYER_SHIP_ROCK"].display)


class TestAncestryWithoutRockC(FTLTestBase):
    options = {"layout_count": 28, "ship_achievements": True, "ship_layouts": "up_to_type_b"}

    def test_no_rock_c_no_ancestry_check(self) -> None:
        names = {location.name for location in self.multiworld.get_locations(self.player)}
        self.assertNotIn("Rock Cruiser: Ancestry", names)
        self.assertIn("Rock Cruiser: Is it warm in here?", names)
