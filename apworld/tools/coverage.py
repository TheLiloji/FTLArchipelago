#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path
from types import CodeType

HERE = Path(__file__).resolve().parent
APWORLD = HERE.parent / "ftl"


def executable_lines(path: Path) -> set[int]:

    code = compile(path.read_text(encoding="utf-8"), str(path), "exec")
    lines: set[int] = set()
    stack: list[CodeType] = [code]
    while stack:
        current = stack.pop()
        for _, _, line in current.co_lines():
            if line:
                lines.add(line)
        for const in current.co_consts:
            if isinstance(const, CodeType):
                stack.append(const)
    return lines


class Tracer:

    def __init__(self, root: Path):
        self.prefix = str(root) + "/"
        self.prefix_test = self.prefix + "test/"
        self.seen: dict[str, set[int]] = {}
        self.known: dict[str, bool] = {}

    def _ours(self, name: str) -> bool:
        decision = self.known.get(name)
        if decision is None:
            decision = (name.startswith(self.prefix)
                        and not name.startswith(self.prefix_test)
                        and name.endswith(".py"))
            self.known[name] = decision
            if decision:
                self.seen.setdefault(name, set())
        return decision

    def __call__(self, frame, event, arg):
        if event != "call":
            return None
        name = frame.f_code.co_filename
        if not self._ours(name):
            return None
        return self._line

    def _line(self, frame, event, arg):
        if event == "line":
            self.seen[frame.f_code.co_filename].add(frame.f_lineno)
        return self._line


def main(argv: list[str]) -> int:
    sys.path.insert(0, str(HERE))
    import run_tests  # noqa: E402

    root = Path(run_tests.SOURCE) / "worlds" / "ftl"
    tracer = Tracer(root)

    sys.settrace(tracer)
    try:
        code = run_tests.main(argv)
    finally:
        sys.settrace(None)

    files = sorted(p for p in root.glob("*.py"))
    total_seen = total_possible = 0
    missing: list[tuple[str, list[int]]] = []
    for file in files:
        possible = executable_lines(file)
        seen = tracer.seen.get(str(file), set()) & possible
        total_seen += len(seen)
        total_possible += len(possible)
        remaining = sorted(possible - seen)
        if remaining:
            missing.append((file.name, remaining))

    print()
    if total_seen == 0:
        print("BROKEN MEASUREMENT: no line traced. The tracer's filter does not recognize "
              "the apworld's files, this is not the test suite's fault.",
              file=sys.stderr)
        return 2
    print(f"Coverage: {total_seen}/{total_possible} apworld lines executed by the "
          f"tests ({total_seen * 100 // max(1, total_possible)}%)")
    source = {f.name: f.read_text(encoding="utf-8").splitlines() for f in files}
    for name, lines in missing:
        print()
        print(f"{name} - {len(lines)} line(s) never executed:")
        for number in lines:
            text = source[name][number - 1].strip()
            print(f"  {name}:{number}  {text[:90]}")
    print()
    return code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
