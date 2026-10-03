#!/usr/bin/env python3
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MAIN = ROOT / "mod/ArchipelagoFTL/data/archipelago/main.lua"
METADATA = ROOT / "mod/ArchipelagoFTL/mod-appendix/metadata.xml"


def parts(version):
    return tuple(int(part) for part in version.split("."))


def newest_tag():
    try:
        tags = subprocess.run(["git", "-C", str(ROOT), "tag", "--list", "v*"],
                              capture_output=True, text=True, check=True).stdout.split()
    except (OSError, subprocess.CalledProcessError):
        return None
    versions = [tag[1:] for tag in tags if re.fullmatch(r"v\d+\.\d+\.\d+", tag)]
    return max(versions, key=parts) if versions else None


def main():
    shown = re.search(r'MOD_VERSION = "([\d.]+)"', MAIN.read_text(encoding="utf-8")).group(1)
    packaged = re.search(r"<version><!\[CDATA\[\s*([\d.]+)\s*\]\]>", METADATA.read_text(encoding="utf-8")).group(1)
    if shown != packaged:
        print(f"check_version: main.lua says {shown}, metadata.xml says {packaged}")
        return 1
    released = newest_tag()
    if released is None:
        print("SKIPPED: no git tags here, the version is not compared to the last release")
    elif parts(shown) < parts(released):
        print(f"check_version: the mod says {shown}, older than the release v{released}")
        return 1
    print(f"check_version: the mod is version {shown}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
