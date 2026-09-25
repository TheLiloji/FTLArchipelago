from __future__ import annotations

import re
import unittest
from pathlib import Path

APWORLD = Path(__file__).parents[1]

FRENCH = re.compile(
    r"[àâäçéèêëîïôöùûüœÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŒ«»]"
    r"|\b[ldnjcmstLDNJCMST]'"
)

RAISE = re.compile(r"raise\s+OptionError\s*\(", re.MULTILINE)


def option_errors() -> list[tuple[str, int, str]]:
    found: list[tuple[str, int, str]] = []
    for path in sorted(APWORLD.glob("*.py")):
        source = path.read_text(encoding="utf-8")
        for start in RAISE.finditer(source):
            depth, i = 0, start.end() - 1
            while i < len(source):
                if source[i] == "(":
                    depth += 1
                elif source[i] == ")":
                    depth -= 1
                    if depth == 0:
                        break
                i += 1
            body = source[start.end():i]
            text = " ".join(re.findall(r'"([^"]*)"', body) + re.findall(r"'([^']*)'", body))
            line = source[: start.start()].count("\n") + 1
            found.append((path.name, line, text))
    return found


class TestHostFacingMessagesAreEnglish(unittest.TestCase):

    def test_the_world_raises_option_errors(self) -> None:
        self.assertGreaterEqual(
            len(option_errors()), 5,
            "no OptionError found: the extraction is broken, not the world",
        )

    def test_no_option_error_speaks_french(self) -> None:
        offenders = [
            f"{filename}:{line} - {text[:80]}"
            for filename, line, text in option_errors()
            if FRENCH.search(text)
        ]
        self.assertEqual(
            [], offenders,
            "these OptionError messages show up on the multiworld host and must be in English",
        )
