#!/usr/bin/env python3

from __future__ import annotations

import argparse
import sys
import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "ftl"

CONTAINER_VERSION = 7

EXCLUDED_PARTS = {"__pycache__"}
EXCLUDED_SUFFIXES = {".pyc", ".pyo"}


def files_to_pack() -> list[Path]:
    return sorted(
        path
        for path in PACKAGE.rglob("*")
        if path.is_file()
        and not EXCLUDED_PARTS.intersection(path.parts)
        and path.suffix not in EXCLUDED_SUFFIXES
    )


def container_manifest() -> bytes:
    manifest = json.loads((PACKAGE / "archipelago.json").read_text(encoding="utf-8"))
    for forbidden in ("version", "compatible_version"):
        if forbidden in manifest:
            raise SystemExit(
                f"apworld/ftl/archipelago.json must not define \"{forbidden}\": this field "
                "describes the container format and is only added at packaging time."
            )
    manifest["version"] = CONTAINER_VERSION
    manifest["compatible_version"] = CONTAINER_VERSION
    return json.dumps(manifest, indent=2, ensure_ascii=False).encode("utf-8")


def build(output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in files_to_pack():
            arcname = Path(PACKAGE.name) / path.relative_to(PACKAGE)
            if path.name == "archipelago.json" and path.parent == PACKAGE:
                zf.writestr(str(arcname), container_manifest())
            else:
                zf.write(path, str(arcname))
    print(f"written: {output}")


def verify() -> int:
    import tempfile

    problems: list[str] = []
    with tempfile.TemporaryDirectory() as tmp:
        target = Path(tmp) / "ftl.apworld"
        build(target)
        with zipfile.ZipFile(target) as zf:
            names = set(zf.namelist())
            manifest_arc = f"{PACKAGE.name}/archipelago.json"
            if manifest_arc not in names:
                problems.append(f"manifest missing from the package: {manifest_arc}")
            else:
                manifest = json.loads(zf.read(manifest_arc))
                for field in ("version", "compatible_version", "game", "world_version"):
                    if field not in manifest:
                        problems.append(f"the package manifest has no \"{field}\"")
            for essential in ("__init__.py", "options.py", "data.py", "items.py", "locations.py"):
                if f"{PACKAGE.name}/{essential}" not in names:
                    problems.append(f"module missing from the package: {essential}")

    if problems:
        print("build_apworld: problems", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        return 1
    print(f"build_apworld: the package builds and contains what it should "
          f"(container manifest v{CONTAINER_VERSION})")
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path.home() / ".local/opt/Archipelago/custom_worlds/ftl.apworld",
        help="path of the .apworld to write (default: custom_worlds of the local build)",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="build into a temp folder and check the package, without installing anything",
    )
    args = parser.parse_args()
    if args.check:
        raise SystemExit(verify())
    build(args.output)


if __name__ == "__main__":
    main()
