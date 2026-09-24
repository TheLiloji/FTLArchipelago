
from __future__ import annotations

from .. import data, items
from .bases import FTLTestBase


class TestScrapTable(FTLTestBase):

    options = {}

    def scrap_items(self) -> list[data.Item]:
        return [item for item in data.ITEMS if item.resource == "scrap"]

    def test_both_scrap_items_exist_with_their_amounts(self) -> None:
        by_name = {item.name: item for item in self.scrap_items()}
        self.assertEqual(set(by_name), {"20 Scrap", "50 Scrap"})
        self.assertEqual(by_name["20 Scrap"].amount, 20)
        self.assertEqual(by_name["50 Scrap"].amount, 50)

    def test_the_amount_matches_the_name(self) -> None:

        for item in self.scrap_items():
            announced = int(item.name.split()[0])
            self.assertEqual(announced, item.amount, item.name)

    def test_scrap_is_filler_never_progression(self) -> None:
        for item in self.scrap_items():
            self.assertEqual(item.classification, "filler", item.name)

    def test_the_default_filler_is_a_real_item(self) -> None:
        self.assertIn(data.FILLER_ITEM_NAME, data.ITEMS_BY_NAME)
        self.assertEqual(self.world.get_filler_item_name(), data.FILLER_ITEM_NAME)
        created = self.world.create_item(data.FILLER_ITEM_NAME)
        self.assertEqual(created.name, data.FILLER_ITEM_NAME)
        self.assertIsNotNone(created.code)

    def test_scrap_is_declared_as_an_implemented_resource(self) -> None:
        self.assertIn("scrap", data.RESOURCES_IMPLEMENTED)

    def test_the_descriptor_says_filler_scrap_and_the_amount(self) -> None:

        descriptor = data.item_descriptor(data.ITEMS_BY_NAME["50 Scrap"])
        self.assertEqual(descriptor, {"k": "filler", "res": "scrap", "n": 50})


class TestScrapInASeed(FTLTestBase):

    options = {}

    def test_scrap_reaches_the_item_pool(self) -> None:
        pool = [item.name for item in self.multiworld.itempool]
        self.assertTrue(
            any(name.endswith("Scrap") for name in pool),
            "no scrap item in the default pool",
        )

    def test_slot_data_describes_every_scrap_item_of_the_seed(self) -> None:
        slot_data = self.world.fill_slot_data()
        descriptors = slot_data["items"]
        for item in self.multiworld.itempool:
            if item.player != self.player or not item.name.endswith("Scrap"):
                continue
            self.assertIn(item.name, descriptors, item.name)
            self.assertEqual(descriptors[item.name]["res"], "scrap")

    def test_filler_kind_is_announced_to_the_mod(self) -> None:
        slot_data = self.world.fill_slot_data()
        self.assertIn("filler", slot_data["kinds"])


class TestScrapWithoutFillerRoom(FTLTestBase):

    options = {
        "sectorsanity": "disabled",
        "ship_achievements": False,
        "general_achievements": "disabled",
        "cross_run_achievements": False,
        "shop_items": 0,
        "shop_checks": 0,
    }

    def test_the_seed_still_generates(self) -> None:
        addressed = self.addressed_locations()
        pool = [item for item in self.multiworld.itempool if item.player == self.player]
        self.assertEqual(len(pool), len(addressed))

    def test_the_default_filler_name_stays_valid_even_unused(self) -> None:
        self.assertEqual(self.world.create_item(data.FILLER_ITEM_NAME).name, data.FILLER_ITEM_NAME)
