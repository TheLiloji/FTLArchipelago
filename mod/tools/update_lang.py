import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lang"
LANGUAGES = ("en", "fr", "de", "es", "it", "pt")
KEY_RE = re.compile(r'^    "([^"]+)":')


def _start(lines):
    return next(i for i, line in enumerate(lines) if line.startswith('  "strings": {'))


def _last(lines, start):
    return max(i for i in range(start + 1, len(lines)) if KEY_RE.match(lines[i]))


def _remove(lines, key):
    start = _start(lines)
    kept = [line for line in lines if not re.match(r'^    "%s":' % re.escape(key), line)]
    end = _last(kept, start)
    kept[end] = re.sub(r",\s*$", "\n", kept[end])
    return kept


def _insert(lines, key, text):
    start = _start(lines)
    value = json.dumps(text, ensure_ascii=False)
    for i in range(start + 1, len(lines)):
        found = KEY_RE.match(lines[i])
        if found and found.group(1) > key:
            lines.insert(i, '    "%s": %s,\n' % (key, value))
            return lines
    end = _last(lines, start)
    lines[end] = re.sub(r"\s*$", ",\n", lines[end])
    lines.insert(end + 1, '    "%s": %s\n' % (key, value))
    return lines


def apply(language, additions=None, replacements=None, renames=None, removals=None):
    path = ROOT / f"{language}.json"
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    before = json.loads("".join(lines))
    expected = dict(before["strings"])
    for old_key, new_key in (renames or {}).items():
        text = expected.pop(old_key)
        lines = _insert(_remove(lines, old_key), new_key, text)
        expected[new_key] = text
    for key in removals or ():
        expected.pop(key)
        lines = _remove(lines, key)
    for key, text in (replacements or {}).items():
        if key not in expected:
            raise KeyError(f"{language}: {key} does not exist, use additions")
        lines = _insert(_remove(lines, key), key, text)
        expected[key] = text
    for key, text in (additions or {}).items():
        if key in expected:
            raise KeyError(f"{language}: {key} already exists, use replacements")
        lines = _insert(lines, key, text)
        expected[key] = text
    final = "".join(lines)
    after = json.loads(final)
    if after["strings"] != expected or after.get("language") != before.get("language"):
        raise ValueError(f"{language}: the resulting file does not match the requested change")
    path.write_text(final, encoding="utf-8")


def from_spec(spec):
    for language in LANGUAGES:
        per_language = {
            operation: {key: texts[language] for key, texts in content.items()}
            for operation, content in spec.items()
            if operation in ("additions", "replacements")
        }
        apply(
            language,
            additions=per_language.get("additions"),
            replacements=per_language.get("replacements"),
            renames=spec.get("renames"),
            removals=spec.get("removals"),
        )


if __name__ == "__main__":
    from_spec(json.loads(Path(sys.argv[1]).read_text(encoding="utf-8")))
    print("languages updated:", ", ".join(LANGUAGES))
