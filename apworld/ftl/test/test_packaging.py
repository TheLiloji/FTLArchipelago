from __future__ import annotations

import dataclasses
import json
import pickle
import typing
import unittest
from pathlib import Path

from .. import data
from ..options import FTLOptions

MANIFEST = Path(__file__).parents[1] / "archipelago.json"


class TestSourceManifest(unittest.TestCase):

    @classmethod
    def setUpClass(cls) -> None:
        if not MANIFEST.is_file():  # pragma: no cover
            raise unittest.SkipTest("manifest unreadable: the world is not loaded as a folder")
        cls.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    def test_the_game_name_matches_the_world(self) -> None:
        self.assertEqual(self.manifest["game"], data.GAME_NAME)

    def test_the_container_fields_are_left_to_the_packager(self) -> None:
        for field in ("version", "compatible_version"):
            self.assertNotIn(
                field, self.manifest,
                f"'{field}' describes the container and belongs to build_apworld.py, not the "
                "source folder",
            )

    def test_the_world_version_has_three_numeric_parts(self) -> None:
        parts = self.manifest["world_version"].split(".")
        self.assertEqual(len(parts), 3, "world_version is written 'major.minor.patch'")
        for part in parts:
            self.assertTrue(part.isdigit(), part)

    def test_the_world_and_the_mod_carry_the_same_version(self) -> None:
        # A template states the world version it needs: a host with an older world must refuse the YAML instead
        # of dropping the options it does not know.
        main_lua = Path(__file__).resolve().parents[3] / "mod" / "ArchipelagoFTL" / "data" / "archipelago" / "main.lua"
        if not main_lua.is_file():  # pragma: no cover
            raise unittest.SkipTest("the mod is not next to the world")
        import re
        shown = re.search(r'MOD_VERSION = "([\d.]+)"', main_lua.read_text(encoding="utf-8")).group(1)
        self.assertEqual(self.manifest["world_version"], shown)


class TestOptionsSurvivePickle(unittest.TestCase):
    def test_every_default_can_be_pickled(self) -> None:
        hints = typing.get_type_hints(FTLOptions)
        for field in dataclasses.fields(FTLOptions):
            option = hints[field.name]
            with self.subTest(field.name):
                pickle.loads(pickle.dumps(option.from_any(option.default)))
