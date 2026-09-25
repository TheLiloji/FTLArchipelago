#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LANG_DIR = ROOT / "lang"
OUT = ROOT / "ArchipelagoFTL" / "data" / "archipelago" / "lang.lua"

CANONICAL = "en"
PLACEHOLDER = re.compile(r"\{(\w+)\}")


def lua_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
        .replace("\r", "")
    )
    return f'"{escaped}"'


def load() -> dict[str, dict]:
    files = sorted(LANG_DIR.glob("*.json"))
    if not files:
        raise SystemExit(f"no language file in {LANG_DIR}")
    languages: dict[str, dict] = {}
    for path in files:
        payload = json.loads(path.read_text(encoding="utf-8"))
        code = payload["language"]["code"]
        if code != path.stem:
            raise SystemExit(f"{path.name}: the declared code is \"{code}\", not \"{path.stem}\"")
        languages[code] = payload
    if CANONICAL not in languages:
        raise SystemExit(f"{CANONICAL}.json is required: it is the fallback language")
    return languages


def verify(languages: dict[str, dict]) -> list[str]:
    english = languages[CANONICAL]["strings"]
    warnings: list[str] = []
    for code, payload in sorted(languages.items()):
        if code == CANONICAL:
            continue
        strings = payload["strings"]
        unknown = sorted(set(strings) - set(english))
        if unknown:
            raise SystemExit(
                f"{code}.json: these keys do not exist in english, "
                f"that is a typo - {', '.join(unknown)}"
            )
        for key, translated in sorted(strings.items()):
            expected = set(PLACEHOLDER.findall(english[key]))
            found = set(PLACEHOLDER.findall(translated))
            if expected != found:
                raise SystemExit(
                    f"{code}.json, key \"{key}\": parameters {sorted(found)} "
                    f"instead of {sorted(expected)}"
                )
        missing = sorted(set(english) - set(strings))
        if missing:
            warnings.append(
                f"{code}: {len(missing)}/{len(english)} keys not translated, "
                f"falling back to english ({', '.join(missing[:4])}"
                + (", ...)" if len(missing) > 4 else ")")
            )
    return warnings


def render(languages: dict[str, dict]) -> str:
    english = languages[CANONICAL]["strings"]
    lines = [
        "_G.apLangTables = {}",
        "_G.apLangNames = {}",
        "_G.apLangFromGame = {}",
        "",
    ]
    for code, payload in sorted(languages.items()):
        meta = payload["language"]
        strings = payload["strings"]
        lines.append(f"_G.apLangNames[{lua_string(code)}] = {lua_string(meta['name'])}")
        for game_code in meta.get("ftl_codes", []):
            lines.append(
                f"_G.apLangFromGame[{lua_string(game_code)}] = {lua_string(code)}"
            )
        lines.append(f"_G.apLangTables[{lua_string(code)}] = {{")
        for key in sorted(strings):
            lines.append(f"    [{lua_string(key)}] = {lua_string(strings[key])},")
        lines.append("}")
        lines.append("")
    codes = ", ".join(sorted(languages))
    lines.append(f'log("[AP-lang] {len(languages)} languages loaded: {codes}")')
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    languages = load()
    for warning in verify(languages):
        print(f"  {warning}", file=sys.stderr)
    content = render(languages)

    if "--check" in sys.argv:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != content:
            print(
                f"{OUT.relative_to(ROOT.parent)} is stale: "
                "rerun python3 mod/gen_lang.py",
                file=sys.stderr,
            )
            return 1
        print(f"lang.lua up to date ({len(languages)} languages)")
        return 0

    OUT.write_text(content, encoding="utf-8", newline="\n")
    print(f"{OUT.relative_to(ROOT.parent)}: {len(languages)} languages")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
