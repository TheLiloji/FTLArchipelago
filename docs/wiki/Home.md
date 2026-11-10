# FTL Archipelago wiki

FTL Archipelago puts **FTL: Faster Than Light** into an [Archipelago](https://archipelago.gg) multiworld. The
things FTL normally makes you unlock over many hours (ships, systems, weapons) are shuffled with the other
players' games. You get them from your friends, and you send them theirs by playing.

| FTL: Faster Than Light | FTL: Multiverse <sup>beta</sup> |
|---|---|
| ![Main menu](../images/main-menu.jpg) | ![Multiverse main menu](../images/mv-main-menu.jpg) |
| 10 ships, 28 layouts, the full base game | all 55 Multiverse ships, the Magic Hat, endings and quests as checks. [More](#ftl-multiverse-beta) |

## Pages

- [Setup on Windows](Setup-Windows.md)
- [Setup on Linux](Setup-Linux.md)
- [Playing](Playing.md): the main menu, the hangar, the map, the shop, the dashboard and the goal
- [Options](Options.md): what to put in your YAML, and the ready-made presets
- [Hosting a seed](Hosting-a-seed.md): generating and running a room with FTL in it
- [FAQ and problems](FAQ.md)

## How it plays

You start with one ship and almost nothing. The other ships, the systems, weapons, drones, augments and crew are
scattered across the multiworld. Every run you play sends checks to your friends: reaching a sector, winning a
fight, recruiting a race, an achievement, the Flagship. What they find for you arrives on its own, and losing a
run only costs the run.

| | |
|---|---|
| ![Locked ships in the hangar](../images/hangar.jpg) | ![The start-of-run menu](../images/start-menu.jpg) |
| ![The Archipelago shop](../images/shop.jpg) | ![AP STORE and Archipelago beacons on the map](../images/map.jpg) |

## New in 0.6

- **Every seed has its own save**, and a Saves button to switch between them.
- **Fights, events and your reactor** can send checks.
- **Four new traps** (a hazard, an anti-ship battery, a Flagship power surge, O2 drain) and **two new events**.
- **Sector Skip, Sector Locks, Flagship Sabotage** and more options to change how a run feels.
- **The dashboard knows the logic**: a blue line marks what you can already do.
- A **solo preset**, and **Multiverse** is now its own game.

All the details in the [release notes](https://github.com/TheLiloji/FTLArchipelago/releases/tag/v0.6.0).

## Everything in one key: the dashboard

Press **TAB**, in a run or in the hangar. The game pauses and your whole game in the multiworld is there at a
glance:

- **Your goal** and where you stand.
- **Every check, ship by ship and sector by sector.** A blue line marks the ones you can already do with what you
  have, so you always know where to go next.
- **Every item you received**, who sent it, and what was inside each bundle.
- **Your hints**: what the others found for you, and where your items wait in their worlds.
- **Achievements** with their game icons, **victories** with each ship's picture, the **crew races** you recruited.
- **Your links**: Death Link, Trap Link, and the fuel in the shared Energy Link reserve.

| | |
|---|---|
| ![Dashboard overview](../images/dashboard-links.jpg) | ![Checks ship by ship](../images/dashboard-checks.png) |
| ![Ships you own](../images/dashboard-ships.png) | ![Achievements on the checks page](../images/dashboard-achievements.jpg) |

## What you will run into

Every sector has an **AP STORE** that sells packages for the other players, plus deals and blood pacts: scrap now,
a trap or a dead crew member later. Other beacons hold Archipelago events: pirates holding a package, a Slug
selling real hints, an Engi who bets he can overclock your reactor, a rare arms dealer.

![Blood pacts in the Archipelago shop](../images/blood-pacts.jpg)

| | |
|---|---|
| ![The Engi overclock bet](../images/event-overclock.jpg) | ![The arms dealer](../images/event-arms-dealer.jpg) |

With **Sector Skip**, a sector you already know starts on an exit beacon: jump right away for scrap and one more
pick at the start of the run.

![Sector Skip: the first beacon is an exit](../images/sector-skip.jpg)

## In numbers

| | |
|---|---|
| Ships | 10, with 28 layouts |
| Checks | about 75 for a first game, 150 by default, several hundred with everything on |
| Options | more than 70, and 5 presets from 3 hours to 20 or more |
| In game | 11 traps, 7 Archipelago events, an AP STORE in every sector |
| Languages | 6 |
| With Multiverse | 55 ships, 18 crew races, a Magic Hat with 65 destinations |

### A few YAMLs to try

Put these lines under `"FTL: Faster Than Light":` in your YAML, on top of a preset or the defaults.

**Chaos night**: traps fly between you and your friends, deals pay more, and nobody dies alone.

```yaml
  trap_chance: 30
  trap_link: true
  death_link: true
  shop_deal_scrap: 150
```

**Fight club**: every sector pays for the first fights you win in it.

```yaml
  combat_checks: 1
  combat_checks_mode: per_sector
  fights_per_sector: 3
```

**Speedrun**: skip the sectors you already know, and face a Flagship the multiworld has sabotaged.

```yaml
  sector_skip: true
  flagship_sabotage: 3
  victories_required: 3
```

**The long way**: every layout earns its way deep, one layout at a time, and only Hard victories count.

```yaml
  sector_locks: true
  kestrel_key: true
  layout_unlocks: progressive
  victory_difficulty: hard
```

**Alone**: take [`solo_game.yaml`](../../presets/solo_game.yaml), a seed built for one player, about 7 hours.

Every option in the [options page](Options.md).

## Checks

| What you do | Example | How many |
|---|---|---|
| Reach a sector with a ship layout | Kestrel Cruiser A: Reach sector 5 | 8 per layout, up to 224 |
| Beat the Flagship with a layout | Engi Cruiser B: Defeat the Flagship | 1 per layout, up to 28 |
| Install a system | Install Cloaking | 12, or 64 counting every level |
| Recruit the first crew member of a race | First Zoltan aboard | 7 |
| Earn a ship achievement | Kestrel Cruiser: Full Arsenal | 30 |
| Earn a general achievement | Achievement: Technophobia | up to 21 |
| Win fights with a ship, in a run or in each sector | Kestrel Cruiser: Fight 2 won | off by default, up to 10 per ship |
| Send a package from a relay or pirate event | Archipelago Event 3 | 5 by default, up to 20 |
| Reach a reactor power in a run | Reactor Power 15 | 4, off by default |
| Buy a package in the Archipelago shop | Archipelago Shop 7 | 20 or more |

Your YAML decides which of these are in the seed: about 75 checks with the `first_game` preset, 150 with the
defaults or `solo_game`, 185 with `long_game`, and 300 or more if you turn everything on.

## Items

| Item | How many | What it does |
|---|---|---|
| Ship keys | 10 | unlock a cruiser (Type A) in the hangar |
| Layouts B and C | 18 | unlock the other layouts of a cruiser |
| System blueprints | 16 | stores can now sell that system |
| Progressive system upgrades | one per level | raise how far a system can be upgraded |
| Head starts | 16 | a free level of that system at the start of every run |
| Reactor Power | 8 | one more reactor bar at the start of every run |
| Weapons | 37, in bundles of 3, twice each | 1st copy: each one on board and more common in stores. 2nd: in the start-of-run menu |
| Drones | 14, in bundles of 2, twice each | same as weapons |
| Augments | 23, in bundles of 3 | each one on board and more common in stores |
| Crew members | 8 races | 1st: joins your run. 2nd: in the start-of-run menu. 3rd: becomes an expert |
| Sector Passes | 2 per layout, if the seed uses them | open the exits of sectors 4 and 7 |
| Archives | 0 to 50 | needed for the goal, if the seed uses them |
| Filler | | scrap, fuel, missiles, drone parts, hull repair, a new crew member |
| Traps | 11 kinds | see above |

## Getting started

1. Get `ArchipelagoFTL.ftl` and the Hyperspace library from the
   [release](https://github.com/TheLiloji/FTLArchipelago/releases) and follow the setup page for
   [Windows](Setup-Windows.md) or [Linux](Setup-Linux.md), in six languages.
2. Make your YAML, or take a [preset](../../presets). The host needs `ftl.apworld` and Archipelago 0.6.7.
3. Start FTL, fill in the panel at the bottom left and connect. No server? Try **Solo mode**.

## FTL: Multiverse <sup>beta</sup>

Archipelago also runs on top of **FTL: Multiverse 5.5** as its own game, **FTL Multiverse** (`ftl_mv.apworld` and
`FTLArchipelago-MV.ftl`, on the releases named `-mv`). Everything from the base mod is there, plus all the Multiverse
ships, the Magic Hat to reroute to the sector you choose, Multiverse endings and ship quests as checks, and the
AP STORE in the secret sectors too. A ship that starts without Oxygen gets it offered for free.

| | |
|---|---|
| ![AP STORE and Archipelago beacons on a Multiverse map](../images/mv-sector-map.jpg) | ![Magic Hat destinations](../images/mv-magic-hat-secret.jpg) |
| ![The eighteen Multiverse races on the dashboard](../images/dashboard-first-crew-mv.png) | ![Multiverse ships on the dashboard](../images/mv-ships.jpg) |

Install Hyperspace, the two Multiverse zips (Assets, then Data), then `FTLArchipelago-MV.ftl` last in ftlman, and put
`ftl_mv.apworld` in `custom_worlds`. More in the
[Multiverse page](https://github.com/TheLiloji/FTLArchipelago/blob/mv-next/docs/wiki/Multiverse.md).

## How this mod is made

FTL Archipelago was made with the help of AI for:

- **the Hyperspace library** (`Hyperspace.dll` and the `.so` files), which adds the network layer so FTL can talk
  to the Archipelago server
- **part of the tests**, automatic ones and runs played on Linux and Windows before each beta
- **the translations**: everything is written in French first, then translated with AI. The English is checked
  by the community, the German by Yunus and the Spanish by Trapper444. Italian and Portuguese are still AI only,
  fixes are welcome.

A precise recap of what was made with AI, from the git history and the wiki, will come after 1.0.

## Thanks

**Where it started.** Before this mod existed, **File_Missing** and **eto** were already bringing FTL to
Archipelago with [FTL Multiverse Archipelago](https://github.com/Filemissing/FTLMultiverseArchipelago).
File_Missing started that project and this Discord server, and eto did the research on the Hyperspace API. eto's
[FTL Manual](https://github.com/Et0san/Manual) was the starting point of this mod's items and locations. They
welcomed this mod with open arms when it showed up. Thank you both.

**Translations and art.** **Trapper444** for the Spanish, the logo and the Multiverse Magic Hat, based on his
ArchiHat. **Yunus** for the German.

**Testing.** **Tom Regor**, for all his testing and logs, the multiworld syncs he runs, and ideas like the O2 Drain
Trap and the in logic marker. **Trapper444** and **Rhythm**, for the Multiverse tests and the reports on logic and
balance.

**Ideas and help.** **studkid**, for the design talks (logic, shop names, saves) and for helping players set up.

And everyone on the Discord who plays, joins the test syncs, reports bugs and votes on ideas: this mod would not be what it is without
you.

## Credits

The first design of the items and locations comes from the [FTL Manual by Et0san](https://github.com/Et0san/Manual)
(MIT). Built on
[FTL: Hyperspace](https://github.com/FTL-Hyperspace/FTL-Hyperspace) (CC-BY-SA 4.0). See
`apworld/ftl/LICENSE.md` and `mod/ArchipelagoFTL/CREDITS.md`.

Building from source and running the tests: [docs/BUILDING.md](../BUILDING.md).
