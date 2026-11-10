<p align="center"><img src="docs/images/banner.png" alt="FTL Archipelago" width="620"></p>

<h1 align="center">FTL Archipelago</h1>

<p align="center">
<b>FTL: Faster Than Light</b> in an <a href="https://archipelago.gg">Archipelago</a> multiworld.<br>
Your ships, systems and weapons are scattered across your friends' games. Theirs are hidden in yours.
</p>

<h3 align="center">For the base game and for FTL: Multiverse <sup>beta</sup></h3>

<p align="center">
<a href="https://github.com/TheLiloji/FTLArchipelago/releases/latest"><b>Download</b></a> ·
<a href="https://github.com/TheLiloji/FTLArchipelago/releases/tag/v0.6.0-mv.1"><b>Download for Multiverse</b></a> ·
<a href="docs/wiki/Setup-Windows.md">Setup on Windows</a> ·
<a href="docs/wiki/Setup-Linux.md">Setup on Linux</a> ·
<a href="docs/wiki/Home.md">Wiki</a> ·
<a href="https://discord.gg/BVQnQu843Q">Discord</a>
</p>

<p align="center">Questions, bugs or just need help? <a href="https://discord.gg/BVQnQu843Q"><b>Join the Discord</b></a>, or open an
<a href="https://github.com/TheLiloji/FTLArchipelago/issues">issue</a> with your <code>FTL_HS.log</code>.</p>

| FTL: Faster Than Light | FTL: Multiverse <sup>beta</sup> |
|---|---|
| ![Main menu](docs/images/main-menu.jpg) | ![Multiverse main menu](docs/images/mv-main-menu.jpg) |
| 10 ships, 28 layouts, the full base game | all 55 Multiverse ships, the Magic Hat, endings and quests as checks. [More](#ftl-multiverse-beta) |

## How it plays

You start with one ship and almost nothing. The other ships, the systems, weapons, drones, augments and crew are
scattered across the multiworld. Every run you play sends checks to your friends: reaching a sector, winning a
fight, recruiting a race, an achievement, the Flagship. What they find for you arrives on its own, and losing a
run only costs the run.

| | |
|---|---|
| ![Locked ships in the hangar](docs/images/hangar.jpg) | ![The start-of-run menu](docs/images/start-menu.jpg) |
| ![The Archipelago shop](docs/images/shop.jpg) | ![The dashboard on TAB](docs/images/dashboard-links.jpg) |

## New in 0.6

- **Every seed has its own save**, and a Saves button to switch between them.
- **Fights, events and your reactor** can send checks.
- **Four new traps** (a hazard, an anti-ship battery, a Flagship power surge, O2 drain) and **two new events**.
- **Sector Skip, Sector Locks, Flagship Sabotage** and more options to change how a run feels.
- **The dashboard knows the logic**: a blue line marks what you can already do.
- A **solo preset**, and **Multiverse** is now its own game.

![Blood pacts in the Archipelago shop](docs/images/blood-pacts.jpg)

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
| ![Dashboard overview](docs/images/dashboard-links.jpg) | ![Checks ship by ship](docs/images/dashboard-checks.png) |
| ![Ships you own](docs/images/dashboard-ships.png) | ![Achievements on the checks page](docs/images/dashboard-achievements.jpg) |

## What you will run into

Every sector has an **AP STORE** that sells packages for the other players, plus deals and blood pacts: scrap now,
a trap or a dead crew member later. Other beacons hold Archipelago events: pirates holding a package, a Slug
selling real hints, an Engi who bets he can overclock your reactor, a rare arms dealer.

| | |
|---|---|
| ![The Engi overclock bet](docs/images/event-overclock.jpg) | ![The arms dealer](docs/images/event-arms-dealer.jpg) |

With **Sector Skip**, a sector you already know starts on an exit beacon: jump right away for scrap and one more
pick at the start of the run.

![Sector Skip: the first beacon is an exit](docs/images/sector-skip.jpg)

## In numbers

| | |
|---|---|
| Ships | 10, with 28 layouts |
| Checks | about 75 for a first game, 150 by default, several hundred with everything on |
| Options | more than 70, and 5 presets from 3 hours to 20 or more |
| In game | 11 traps, 7 Archipelago events, an AP STORE in every sector |
| Languages | 6 |
| With Multiverse | 55 ships, 18 crew races, a Magic Hat with 65 destinations |

Want chaos? Put this in your YAML and play with friends:

```yaml
  trap_chance: 30
  trap_link: true
  death_link: true
```

More ideas and every option in the [wiki](docs/wiki/Home.md).

## Getting started

1. Get `ArchipelagoFTL.ftl` and the Hyperspace library from the
   [release](https://github.com/TheLiloji/FTLArchipelago/releases) and follow the setup page for
   [Windows](docs/wiki/Setup-Windows.md) or [Linux](docs/wiki/Setup-Linux.md), in six languages.
2. Make your YAML, or take a [preset](presets). The host needs `ftl.apworld` and Archipelago 0.6.7.
3. Start FTL, fill in the panel at the bottom left and connect. No server? Try **Solo mode**.

## FTL: Multiverse <sup>beta</sup>

Archipelago also runs on top of **FTL: Multiverse 5.5** as its own game, **FTL Multiverse** (`ftl_mv.apworld` and
`FTLArchipelago-MV.ftl`, on the releases named `-mv`). Everything from the base mod is there, plus all the Multiverse
ships, the Magic Hat to reroute to the sector you choose, Multiverse endings and ship quests as checks, and the
AP STORE in the secret sectors too. A ship that starts without Oxygen gets it offered for free.

| | |
|---|---|
| ![Multiverse main menu](docs/images/mv-main-menu.jpg) | ![AP STORE and Archipelago beacons on a Multiverse map](docs/images/mv-sector-map.jpg) |
| ![Magic Hat destinations](docs/images/mv-magic-hat-secret.jpg) | ![Multiverse ships on the dashboard](docs/images/mv-ships.jpg) |

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

Building from source and running the tests: [docs/BUILDING.md](docs/BUILDING.md).
