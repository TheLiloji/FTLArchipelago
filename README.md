# FTL Archipelago

An [Archipelago](https://archipelago.gg) randomizer for **FTL: Faster Than Light** (Advanced Edition), built on
[Hyperspace](https://github.com/FTL-Hyperspace/FTL-Hyperspace). The game really applies what you receive: ships
unlock, systems are capped, shop items appear, traps go off.

Status: works on **Linux** (FTL 1.6.13, Hyperspace 1.23.1), connected to a real Archipelago server.

## Known limitations

- **Windows is not supported.** The connection to the Archipelago server lives in a small C++ module added to
  Hyperspace, and that module has only been built for Linux so far.
- **A few options do nothing in game yet.** Progressive crew health, progressive skills, skill checks and
  death-type checks are accepted by the generator but not wired into the mod. Their option pages say so.
- **Prebuilt files are Linux only.** The GitHub release carries the patched Hyperspace library for FTL 1.6.13
  (Linux), `ArchipelagoFTL.ftl` and `ftl.apworld`; everything can also be built from source as below.

## What is in the repo

| Folder | What it is |
|---|---|
| `apworld/` | the Archipelago world (Python) |
| `mod/` | the FTL mod (Lua + XML, loaded by Hyperspace) |
| `hyperspace-patch/` | a small C++ module added to Hyperspace, it talks to the Archipelago server |
| `presets/` | ready-to-use player YAML files |
| `tests/` | `run_all.sh`, the entry point that runs every check |

## Checks (what you do in the game)

| Check | Example |
|---|---|
| Reach a sector with a ship layout | Kestrel Cruiser A: Reach sector 5 |
| Beat the flagship with a layout | Engi Cruiser B: Defeat the Flagship |
| Ship achievements | Kestrel Cruiser: Full Arsenal |
| General achievements | Achievement: Technophobia |
| Install a system (or each level) | Install Cloaking |
| First crew member of each race | First Zoltan aboard |
| Archipelago shop (one beacon per sector) | Archipelago Shop 7 |

## Items (what you receive)

| Item | What it does |
|---|---|
| Ship keys and layouts | unlock ships and their Type B / C in the hangar |
| System blueprints | allow buying a system in stores |
| Progressive system upgrades | raise the max level of a system |
| Weapons and drones (2 copies) | 1st: unlocked in stores and one given now, 2nd: in the start-of-run menu |
| Augments | unlocked in stores |
| Crew members (progressive) | 1st: joins your run, 2nd: in the start-of-run menu, 3rd: becomes an expert |
| Head starts and bonuses | a free system level or reactor power at the start of every run |
| Filler and traps | scrap, fuel, missiles, drone parts, and some traps |

The seed balances itself: if there are more items than checks, the Archipelago shop gets more slots; if there are
more checks than items, more filler is added.

## Dependencies

- **In game:** FTL: Faster Than Light 1.6.13 (Advanced Edition content on), the official
  [Hyperspace](https://github.com/FTL-Hyperspace/FTL-Hyperspace) 1.23.1 release, this project's patched
  Hyperspace library, and the `ArchipelagoFTL.ftl` mod, all applied with
  [ftlman](https://github.com/afishhh/ftlman).
- **To generate or host a seed:** [Archipelago](https://github.com/ArchipelagoMW/Archipelago) 0.6.7 or newer,
  with `ftl.apworld` dropped into its `custom_worlds` folder.
- **To build from source:** Docker (compiles the patched Hyperspace library) and clones of
  [FTL-Hyperspace](https://github.com/FTL-Hyperspace/FTL-Hyperspace),
  [apclientpp](https://github.com/black-sliver/apclientpp),
  [wswrap](https://github.com/black-sliver/wswrap) and
  [websocketpp](https://github.com/zaphoyd/websocketpp) in `vendor/`, plus Python 3.

## Install (Linux)

1. Install [ftlman](https://github.com/afishhh/ftlman), use it to install the official Hyperspace 1.23.1 into
   the game, and put `Hyperspace.ftl` (1.23.1) in `~/.local/share/ftl-mods/` as well.
2. Clone the four C++ dependencies listed above into `vendor/`.
3. Build the Hyperspace library with the Archipelago module and put it in place of the official one:
   `hyperspace-patch/build-linux.sh --install` (uses Docker).
4. Install the mod: `mod/install.sh`.
5. Build the world into the `custom_worlds` folder of Archipelago:
   `python3 apworld/tools/build_apworld.py --output <Archipelago>/custom_worlds/ftl.apworld`,
   then generate as usual (the `presets/` files are a good start).
6. Start FTL and fill the connection panel at the bottom left of the main menu.

Exact commands and troubleshooting: `apworld/ftl/docs/setup_en.md`.

## Setting up an Archipelago game

Pick one of the `presets/` YAML files, change its `name:` line, and generate as usual with `ftl.apworld`
installed. `apworld/ftl/docs/en_FTL Faster Than Light.md` explains what each option changes in game (it is
also what Archipelago's WebHost serves as this world's game page); `apworld/ftl/docs/setup_en.md` covers
installing everything and joining a room, including troubleshooting.

## Tests

- `mod/test/run.sh`: the Lua mod against a simulated Hyperspace, plus static checks (language keys, glyphs,
  events, wiring).
- `apworld/run_tests.sh`: the Archipelago world (clones Archipelago's sources on first run).
- `tests/run_all.sh`: both suites, the installed-mod check, presets and docs numbers. `FULL=1 tests/run_all.sh`
  adds the long ones (option sweep, real multiworlds with other games).

A check that cannot run (no `ftl.dat`, no `ftlman`, a missing Python module) prints `SKIPPED: <reason>` and is
listed at the end of the run as not verified, never counted as passed.

## Contributing

Contributions are welcome. The conventions: code, identifiers, logs and comments are in English (player-facing text goes through
`mod/lang/*.json` instead, edited with `python3 mod/tools/update_lang.py` then `python3 mod/gen_lang.py`,
never by hand); the tests above stay green; `apworld/ftl/docs/*.md` and this README get updated when behaviour
changes.

## Languages

The texts are written in French. The English, German, Spanish, Italian and Portuguese translations were made with
AI and may have mistakes.

## Credits

The first design of the items and locations comes from the [FTL Manual by Et0san](https://github.com/Et0san/Manual)
(MIT). The FTL Archipelago logo was drawn by Trapper444. Hyperspace is CC-BY-SA 4.0. See `apworld/ftl/LICENSE.md` and `mod/ArchipelagoFTL/CREDITS.md`.
