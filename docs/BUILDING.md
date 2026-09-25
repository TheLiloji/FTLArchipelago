# Building from source

Everything is in this repo: the world in `apworld/`, the mod in `mod/`, and the small C++ part added to
Hyperspace in `hyperspace-patch/`. The Hyperspace library is built in Hyperspace's own Docker container, for
both systems:

```sh
hyperspace-patch/build-linux.sh --install      # or build-windows.sh, from Git Bash
mod/install.sh                                 # builds the .ftl and applies it with ftlman
python3 apworld/tools/build_apworld.py --output <Archipelago>/custom_worlds/ftl.apworld
```

The build needs clones of [FTL-Hyperspace](https://github.com/FTL-Hyperspace/FTL-Hyperspace),
[apclientpp](https://github.com/black-sliver/apclientpp), [wswrap](https://github.com/black-sliver/wswrap) and
[websocketpp](https://github.com/zaphoyd/websocketpp) in `vendor/`, plus Docker and Python 3. On Windows, run
the scripts from Git Bash with Docker Desktop running and FTL closed, and give ftlman's path in `FTLMAN`.

`mod/build.sh --debug` (or `DEBUG=1 mod/install.sh`) keeps the test keys in the mod. Player builds leave them
out. `apworld/ftl/docs/setup_en.md` has the exact commands and more troubleshooting.

## Repo layout

| Folder | What it is |
|---|---|
| `apworld/` | the Archipelago world (Python) |
| `mod/` | the FTL mod (Lua and XML, loaded by Hyperspace) |
| `hyperspace-patch/` | the C++ module added to Hyperspace, it talks to the Archipelago server |
| `presets/` | ready-made player YAML files |
| `docs/` | the wiki pages and the screenshots |
| `tests/` | `run_all.sh`, which runs every check |

## Tests

- `mod/test/run.sh`: the Lua mod against a fake Hyperspace, plus checks on language keys, fonts, events and
  wiring.
- `apworld/run_tests.sh`: the world (fetches Archipelago's sources the first time).
- `tests/run_all.sh`: both, plus the installed mod and the numbers in the presets and docs.
  `FULL=1 tests/run_all.sh` adds the long ones.

A check that cannot run prints `SKIPPED` with the reason and is never counted as passed.

## Conventions

Code, logs and comments are in English. Text shown to the player lives in `mod/lang/*.json`: edit it with
`python3 mod/tools/update_lang.py`, then run `python3 mod/gen_lang.py`. Keep the tests green and update the
docs when behaviour changes.
