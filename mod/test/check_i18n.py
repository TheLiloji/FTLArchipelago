#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

PLACEHOLDER = re.compile(r"\{(\w+)\}")

ROOT = Path(__file__).resolve().parent.parent
MODULES = ROOT / "ArchipelagoFTL" / "data" / "archipelago"
LANG = ROOT / "lang" / "en.json"

SKIP = {"testkeys.lua", "lang.lua", "i18n.lua", "solo_order.lua", "gifts_demo.lua"}

DISPLAY_CALLS = (
    "apNotifyStatus", "apNotifyItem", "apNotifyTrap", "apNotifyCheck",
    "easy_print", "easy_printAutoNewlines",
)
DISPLAY_FIELDS = re.compile(
    r"\.(title|shortTitle|description|tooltip|tip)\.data\s*=\s*(.+)$"
)

ALLOWED_LITERALS = {
    "\\n": "line break",
    " - ": "detail separator",
    " + ": "enumeration separator",
    ", ": "list separator",
    "  ": "alignment",
    ".": "truncation of a slot name that is too long",
    "": "empty string",
    "Archipelago": "proper noun",
    "AP - ": "identifier prefix, not a sentence",
}

KEY_CALL = re.compile(r'\bapT\(\s*"([^"]+)"')
STRING_LITERAL = re.compile(r'"((?:[^"\\]|\\.)*)"')


def lua_sources() -> list[Path]:
    return sorted(p for p in MODULES.glob("*.lua") if p.name not in SKIP)


def used_keys(english: dict[str, str]) -> dict[str, list[str]]:
    found: dict[str, list[str]] = {}
    looks_like_a_key = re.compile(r"^[a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+$")
    for path in sorted(MODULES.glob("*.lua")):
        if path.name == "lang.lua":
            continue
        source = path.read_text(encoding="utf-8")
        for key in KEY_CALL.findall(source):
            found.setdefault(key, []).append(path.name)
        for literal in STRING_LITERAL.findall(source):
            if literal in english and looks_like_a_key.match(literal):
                found.setdefault(literal, []).append(path.name)
    return found


def send_check_labels() -> list[str]:
    problems: list[str] = []
    for path in lua_sources():
        text = path.read_text(encoding="utf-8")
        for match in re.finditer(r"\bapSendCheck\s*\(", text):
            depth, i, args, current = 0, match.end() - 1, [], ""
            while i < len(text):
                c = text[i]
                if c == '"':
                    end = i + 1
                    while end < len(text) and (text[end] != '"' or text[end - 1] == "\\"):
                        end += 1
                    current += text[i:end + 1]
                    i = end + 1
                    continue
                if c == "(":
                    depth += 1
                    if depth == 1:
                        i += 1
                        continue
                elif c == ")":
                    depth -= 1
                    if depth == 0:
                        args.append(current)
                        break
                elif c == "," and depth == 1:
                    args.append(current)
                    current = ""
                    i += 1
                    continue
                current += c
                i += 1

            if len(args) < 2:
                continue
            label = args[1].strip()
            if label.startswith("apT(") or "apT(" in label:
                continue
            for literal in STRING_LITERAL.findall(label):
                if literal in ALLOWED_LITERALS:
                    continue
                line = text[: match.start()].count("\n") + 1
                problems.append(
                    f"{path.name}:{line}: apSendCheck's label has \"{literal}\" hardcoded, "
                    f"that is what the player reads when the seed does not name the location"
                )
    return problems


def hardcoded_display_strings() -> list[str]:
    problems: list[str] = []
    for path in lua_sources():
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            stripped = line.strip()
            if stripped.startswith("--"):
                continue

            interesting = any(call + "(" in line for call in DISPLAY_CALLS)
            field = DISPLAY_FIELDS.search(line)
            if not interesting and not field:
                continue

            fragment = field.group(2) if field and not interesting else line
            for literal in STRING_LITERAL.findall(fragment):
                if literal in ALLOWED_LITERALS:
                    continue
                if KEY_CALL.search(fragment) and re.fullmatch(r"[a-z0-9_.]+", literal):
                    continue
                if " " not in literal and not literal.endswith((".", "!", "?", ":")):
                    continue
                problems.append(f"{path.name}:{number}: hardcoded text \"{literal}\"")
    return problems


def bad_sentence_joins(languages: dict[str, dict[str, str]]) -> list[str]:
    COMPOSED = [("deathlink.received", "{effect}", "deathlink.effect."),
                ("trap.sprung", "{what}", "trap."),
                ("status.prefix", "{message}", None)]
    problems: list[str] = []
    for code, strings in sorted(languages.items()):
        for carrier, placeholder, prefix in COMPOSED:
            text = strings.get(carrier)
            if not text or placeholder not in text:
                continue
            before = text.split(placeholder)[0]
            if not before.rstrip().endswith((".", "!", "?")):
                continue
            if prefix is None:
                continue
            for key, fragment in strings.items():
                if key.startswith(prefix) and fragment[:1].islower():
                    problems.append(
                        f"{code}: \"{carrier}\" ends with a period before {placeholder}, "
                        f"and \"{key}\" starts lowercase"
                    )
                    break
    return problems


RESOURCE_WORDS = (" fuel", " scrap", " missiles", " drone parts", " hull repair", " crew member")


SENDS_TO_SERVER = ("apDeathLinkSend", "apNetSend", "SendDeath", "SendTrap")
KEYWORD_TABLE = re.compile(r'^\s*\{\s*"[^"]+"\s*,\s*"[^"]+"\s*\}\s*,?\s*$')


def concatenated_english(languages: dict[str, dict[str, str]]) -> list[str]:
    problems: list[str] = []
    for path in lua_sources():
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.strip().startswith("--"):
                continue
            if any(marker in line for marker in SENDS_TO_SERVER):
                continue
            if KEYWORD_TABLE.match(line):
                continue
            for literal in STRING_LITERAL.findall(line):
                lowered = literal.lower()
                if any(lowered.endswith(word) or lowered == word.strip()
                       for word in RESOURCE_WORDS):
                    problems.append(
                        f"{path.name}:{number}: \"{literal}\" is an english resource word "
                        "hardcoded, it will end up in front of the player"
                    )
    return problems


LITERAL_NOTIFICATION = re.compile(
    r'\b(apNotifyStatus|apNotifyItem|apNotifyTrap|apNotifyCheck)\(\s*"'
)


def literal_notifications() -> list[str]:
    found = []
    for path in sorted(MODULES.glob("*.lua")):
        if path.name in ("lang.lua",):
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if LITERAL_NOTIFICATION.search(line):
                found.append(
                    f"{path.name}:{number}: a notification to the player carries a hardcoded "
                    "string; it will show in only one language, even from an excluded module"
                )
    return found


def main() -> int:
    english = json.loads(LANG.read_text(encoding="utf-8"))["strings"]
    languages = {
        path.stem: json.loads(path.read_text(encoding="utf-8"))["strings"]
        for path in sorted(LANG.parent.glob("*.json"))
    }
    used = used_keys(english)
    failures: list[str] = []

    unknown = sorted(set(used) - set(english))
    for key in unknown:
        failures.append(
            f"key used but missing from lang/en.json: \"{key}\" "
            f"({', '.join(sorted(set(used[key])))})"
        )

    SUFFIX = ".one"
    variants = {k for k in english if k.endswith(SUFFIX)}
    for key in sorted(variants):
        base = key[: -len(SUFFIX)]
        if base not in english:
            failures.append(
                f"singular variant with no base key: \"{key}\" (\"{base}\" does not exist)"
            )
            continue
        if base not in used:
            failures.append(
                f"singular variant whose base is never used: \"{key}\""
            )
        extra = set(PLACEHOLDER.findall(english[key])) - set(PLACEHOLDER.findall(english[base]))
        if extra:
            failures.append(
                f"singular variant \"{key}\": parameter(s) {sorted(extra)} "
                f"missing from \"{base}\""
            )

    for code, table in sorted(languages.items()):
        for key, value in sorted(table.items()):
            if isinstance(value, str) and " - " in value:
                failures.append(
                    f"{code}: \"{key}\" uses \" - \" as an aside. "
                    "A comma, a colon or parentheses, not a dash."
                )

    dead = sorted(set(english) - set(used) - variants)
    for key in dead:
        failures.append(f"key declared but never used: \"{key}\"")

    for code, table in sorted(languages.items()):
        greeting = table.get("connect.keys", "")
        if re.search(r"\bS\b", greeting) is not None:
            failures.append(
                f"lang/{code}.json: \"connect.keys\" promises the S key, which the connect "
                "form swallows: solo mode starts from its button"
            )
        if "F10" in greeting:
            failures.append(
                f"lang/{code}.json: \"connect.keys\" names F10, but the test keys are only in debug builds"
            )

    failures.extend(hardcoded_display_strings())
    failures.extend(literal_notifications())
    failures.extend(send_check_labels())
    failures.extend(bad_sentence_joins(languages))
    failures.extend(concatenated_english(languages))

    if len(english) < 50 or len(used) < 30:
        failures.append(
            f"suspicious extraction: {len(english)} keys declared and {len(used)} used. "
            "The mod carries more than a hundred: this is the reader that's broken, not the mod."
        )

    if failures:
        print("check_i18n: issues", file=sys.stderr)
        for problem in failures:
            print(f"  {problem}", file=sys.stderr)
        return 1

    print(f"check_i18n: {len(english)} keys, all used, no hardcoded text on screen")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
