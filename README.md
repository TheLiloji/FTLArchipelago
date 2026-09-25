# FTL Archipelago

Play **FTL: Faster Than Light** in an [Archipelago](https://archipelago.gg) multiworld. Your ships, systems and
shop items are shuffled with the other players' games: you unlock them by receiving items, and you send items
to your friends by reaching sectors, winning fights and buying packages in a special shop.

**This is a beta.** It works on Windows and Linux and has been played from start to goal, but expect rough edges.
Please report anything odd (see [Reporting a problem](#reporting-a-problem)).

![Main menu with the Archipelago goal and connection panel](docs/images/main-menu.jpg)

## What changes in the game

- **Ships are locked** until you receive their key. The hangar only shows what you own.
- **Systems need a blueprint** before a store will sell them, and each upgrade level is an item.
- **Weapons, drones and augments** you receive become more common in stores, and one copy is put on your ship.
- **ARCHIPELAGO beacons** on the map hold a shop with packages for other players, or one of four small events.
- **A dashboard** (press `TAB` in a run) shows your goal, your checks, what you received and your hints.
- **The goal:** beat the Flagship with a few different ships. Archives, a second currency, can be added on top.

| | |
|---|---|
| ![Locked ships in the hangar](docs/images/hangar.jpg) | ![ARCHIPELAGO beacons on the map](docs/images/map.jpg) |
| Ships you have not received stay locked. | Each sector has ARCHIPELAGO beacons. |
| ![The Archipelago shop](docs/images/shop.jpg) | ![The dashboard](docs/images/dashboard.png) |
| Packages for other players, and some FOR YOU. | `TAB` opens the dashboard and pauses the game. |

Losing a run only costs you the run. Everything you received stays, so the next run starts stronger.

## Download

Get the files from the [latest release](https://github.com/TheLiloji/FTLArchipelago/releases):

| File | Who needs it |
|---|---|
| `ArchipelagoFTL.ftl` | every player: the mod itself |
| `Hyperspace.dll` | players on Windows |
| `Hyperspace.1.6.13.amd64.so` | players on Linux |
| `ftl.apworld` | whoever generates the seed |
| `presets.zip` | ready-made player settings (YAML) |

You also need two things that are not part of this project:

- [ftlman](https://github.com/afishhh/ftlman/releases), the FTL mod manager.
- `Hyperspace.ftl` 1.23.1, from the [Hyperspace release page](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1).

The `Hyperspace.dll` / `.so` from this project is Hyperspace 1.23.1 with one small extra part that talks to the
Archipelago server. The official one cannot connect.

## Install

Step by step with pictures in the wiki: [Windows](docs/wiki/Installing-on-Windows.md),
[Linux](docs/wiki/Installing-on-Linux.md). The short version:

1. In Steam, turn off Steam Cloud for FTL, and make a copy of your save folder.
2. With ftlman, install Hyperspace 1.23.1. On Windows this also switches FTL to version 1.6.9, which is expected.
3. Put `Hyperspace.ftl` and `ArchipelagoFTL.ftl` in ftlman's mods folder, Hyperspace first, and apply.
4. Close ftlman and copy this project's `Hyperspace.dll` (Windows) or `Hyperspace.1.6.13.amd64.so` (Linux) into
   the game folder (its `data` folder on Linux), over the one that is there.
5. Start FTL from Steam. The main menu should show the Archipelago logo and a connection panel.

If you apply mods again later in ftlman, copy the library again afterwards.

## Play

![Connection panel](docs/images/connect-panel.jpg)

Fill in the server address, the port and your slot name, then press `Connect`. The mod remembers them for next
time, except the password. Then start a new game and play: checks are sent as you go.

No server? `Solo mode` plays a real generated seed alone, handing out one item per check.

More in the wiki: [how to play](docs/wiki/Playing.md), [the options](docs/wiki/Options.md),
[hosting a seed](docs/wiki/Hosting-a-seed.md) and [common problems](docs/wiki/FAQ.md).

## Reporting a problem

Open an [issue](https://github.com/TheLiloji/FTLArchipelago/issues) and attach `FTL_HS.log` from the game folder
(on Linux, from its `data` folder). It is written again each time FTL starts, so copy it right after the
problem. Say which seed options you used if it looks seed related.

## Known limits

- A few options do nothing in game yet: progressive crew health, progressive skills, skill checks and
  death-type checks. Their descriptions say so.
- FTL has to stay on version 1.6.9 on Windows, the only one Hyperspace runs on.
- The package tooltip in the Archipelago shop still shows weapon stats. Ignore them, it is a package.

## Building from source

Everything is in this repo: the world in `apworld/`, the mod in `mod/`, and the small C++ part added to
Hyperspace in `hyperspace-patch/`. The library is built in Hyperspace's own Docker container, for both systems:

```sh
hyperspace-patch/build-linux.sh --install      # or build-windows.sh, from Git Bash
mod/install.sh                                 # builds the .ftl and applies it with ftlman
python3 apworld/tools/build_apworld.py --output <Archipelago>/custom_worlds/ftl.apworld
```

The build needs clones of [FTL-Hyperspace](https://github.com/FTL-Hyperspace/FTL-Hyperspace),
[apclientpp](https://github.com/black-sliver/apclientpp), [wswrap](https://github.com/black-sliver/wswrap) and
[websocketpp](https://github.com/zaphoyd/websocketpp) in `vendor/`. `mod/build.sh --debug` (or
`DEBUG=1 mod/install.sh`) keeps the test keys in the mod; player builds leave them out.
`apworld/ftl/docs/setup_en.md` has the exact commands and more troubleshooting.

Tests: `mod/test/run.sh` runs the mod against a fake Hyperspace, `apworld/run_tests.sh` tests the world, and
`tests/run_all.sh` runs both. A check that cannot run prints `SKIPPED` with the reason and is never counted as
passed.

Code, logs and comments are in English. Text shown to the player lives in `mod/lang/*.json` and goes through
`python3 mod/tools/update_lang.py`, then `python3 mod/gen_lang.py`.

## Languages

The mod speaks English, French, Spanish, German, Italian and Portuguese, and follows the language FTL is set to.
The French text was written by hand. The other translations were made with AI and may have mistakes: fixes are
welcome.

## Credits

The first design of the items and locations comes from the [FTL Manual by Et0san](https://github.com/Et0san/Manual)
(MIT). The FTL Archipelago logo was drawn by Trapper444. Hyperspace is CC-BY-SA 4.0. See
`apworld/ftl/LICENSE.md` and `mod/ArchipelagoFTL/CREDITS.md`.
