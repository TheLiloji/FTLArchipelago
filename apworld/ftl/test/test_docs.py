from __future__ import annotations

import re
import unittest
from pathlib import Path

from .. import data
from ..web_world import FTLWeb

DOCS = Path(__file__).parents[1] / "docs"
APWORLD = Path(__file__).parents[1]


def game_info_pages(language: str) -> list[Path]:
    wanted = f"{language}_{secure_name(data.GAME_NAME)}.md"
    return [path for path in DOCS.iterdir() if path.is_file() and secure_name(path.name) == wanted]


def secure_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]", "", "_".join(name.split()))


class TestDocumentationFiles(unittest.TestCase):
    def test_the_local_rule_agrees_with_werkzeug(self) -> None:
        try:
            from werkzeug.utils import secure_filename
        except ImportError:
            self.skipTest("Werkzeug missing: cannot compare the rule to its source")
        for sample in (data.GAME_NAME, f"en_{data.GAME_NAME}.md", "setup_en.md"):
            self.assertEqual(secure_name(sample), secure_filename(sample), sample)

    def test_game_info_page_exists_for_every_declared_language(self) -> None:
        safe_game = secure_name(data.GAME_NAME)
        for language in FTLWeb.game_info_languages:
            self.assertEqual(
                len(game_info_pages(language)), 1,
                f"the WebHost will serve `{language}_{safe_game}.md`; docs/ must contain "
                "exactly one file with that name once run through secure_filename",
            )

    def test_every_tutorial_points_at_a_real_file(self) -> None:
        self.assertTrue(FTLWeb.tutorials, "a world without a setup guide is incomplete")
        for tutorial in FTLWeb.tutorials:
            self.assertTrue(
                (DOCS / tutorial.file_name).is_file(),
                f"{tutorial.file_name} is declared in web_world.py but missing from docs/",
            )

    def test_the_credit_to_et0san_is_where_it_was_promised(self) -> None:
        pages = game_info_pages("en")
        self.assertEqual(len(pages), 1)
        for path in (pages[0], APWORLD / "LICENSE.md"):
            self.assertTrue(path.is_file(), path.name)
            self.assertIn("Et0san", path.read_text(encoding="utf-8"), path.name)
