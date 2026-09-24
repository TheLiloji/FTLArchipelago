#!/usr/bin/env python3

from __future__ import annotations

import logging
import os
import sys
import types
import unittest
from pathlib import Path

SOURCE = Path(os.environ.get("AP_SOURCE", "")).expanduser()
FROZEN = Path(os.environ.get("AP_ROOT", "~/.local/opt/Archipelago")).expanduser()

if not (SOURCE / "worlds" / "AutoWorld.py").is_file():
    sys.exit(
        f"Archipelago sources not found in {SOURCE}. "
        "Run apworld/run_tests.sh, which takes care of it."
    )

os.chdir(SOURCE)
sys.path.insert(0, str(SOURCE))

_stub = types.ModuleType("bsdiff4.core")
_stub.diff = _stub.patch = lambda *a, **k: b""
sys.modules["bsdiff4.core"] = _stub

if (FROZEN / "lib").is_dir():
    sys.path.append(str(FROZEN / "lib" / "library.zip"))
    sys.path.append(str(FROZEN / "lib"))

try:
    import Utils  # noqa: F401
except ImportError as error:  # pragma: no cover
    sys.exit(
        f"missing dependency ({error.name}).\n"
        f"Either the frozen build is missing from {FROZEN}, or it isn't enough; in that case:\n"
        f"    python3 -m pip install --user -r {SOURCE / 'requirements.txt'}"
    )

logging.disable(logging.ERROR)

TEST_PACKAGE = "worlds.ftl.test"


def main(argv: list[str]) -> int:
    loader = unittest.TestLoader()
    if argv:
        names = [
            name if name.startswith(TEST_PACKAGE) else f"{TEST_PACKAGE}.{name}"
            for name in argv
        ]
        suite = loader.loadTestsFromNames(names)
    else:
        suite = loader.discover(
            start_dir=str(SOURCE / "worlds" / "ftl" / "test"), top_level_dir=str(SOURCE)
        )
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
