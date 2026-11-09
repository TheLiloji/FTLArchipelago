<p align="center"><img src="docs/images/banner.png" alt="FTL Archipelago" width="620"></p>

<h1 align="center">FTL Archipelago</h1>

<p align="center">
<b>FTL: Faster Than Light</b> in an <a href="https://archipelago.gg">Archipelago</a> multiworld.<br>
Your ships, systems and weapons are scattered across your friends' games. Theirs are hidden in yours.
</p>

<p align="center">
<a href="https://github.com/TheLiloji/FTLArchipelago/releases">Download</a> ·
<a href="docs/wiki/Setup-Windows.md">Setup on Windows</a> ·
<a href="docs/wiki/Setup-Linux.md">Setup on Linux</a> ·
<a href="docs/wiki/Home.md">Wiki</a> ·
<a href="https://discord.gg/BVQnQu843Q">Discord</a>
</p>

<p align="center">Questions, bugs or just need help? <a href="https://discord.gg/BVQnQu843Q"><b>Join the Discord</b></a>.</p>

> **Beta.** Played from start to goal on Windows and Linux. Found something odd? Open an
> [issue](https://github.com/TheLiloji/FTLArchipelago/issues) with your `FTL_HS.log`.

![Main menu](docs/images/main-menu.jpg)

## How it plays

**You start with almost nothing.** One ship, few systems, and every other cruiser locked in the hangar.

![Locked ships in the hangar](docs/images/hangar.jpg)

**Every run you play sends items to the others.** Reaching a sector, installing a system, recruiting a new race,
winning a fight, earning an achievement or beating the Flagship are all checks.

**What they find for you arrives on its own.** A ship key opens a cruiser, a blueprint lets stores sell a system,
a weapon lands on your ship and shows up more in stores.

![Items arriving during a run](docs/images/in-game.jpg)

**Each new run starts stronger.** Head starts give free system levels, and the start-of-run menu lets you bring
one weapon, one drone and one crew member from everything you have collected.

![The start-of-run menu](docs/images/start-menu.jpg)

**Losing a run only costs the run.** Everything you received stays.

## Archipelago beacons

Every sector map has a beacon marked **AP STORE**. Its shop sells packages for the other players, and some
marked **FOR YOU**. Buying one sends it right away.

| | |
|---|---|
| ![Archipelago beacons](docs/images/map.jpg) | ![The Archipelago shop](docs/images/shop.jpg) |

The same shop sells **deals**: scrap now, and a trap in exchange. With Trap Link on it hits another player two
times out of three, otherwise it hits you in your next fight. The **blood pacts** on the second page pay more,
but sometimes one of your crew dies for good. Never your last one.

![Blood pacts in the Archipelago shop](docs/images/blood-pacts.jpg)

Other beacons hold small events of their own: a relay carrying packages, pirates holding a package (pay or
fight), a Zoltan checkpoint, a Slug selling real hints, a surge from another world, an Engi tech who wants to
overclock your reactor, and a rare arms dealer in pirate sectors. The ones that send packages say
**ARCHIPELAGO** on the map.

| | |
|---|---|
| ![The Engi overclock bet](docs/images/event-overclock.jpg) | ![The arms dealer](docs/images/event-arms-dealer.jpg) |

## The dashboard

**Press `TAB`** in a run, or in the hangar: your goal, your checks ship by ship, what you received, your hints
and the links you play with. A blue line marks the checks you can already do with what you have.

| | |
|---|---|
| ![Dashboard overview](docs/images/dashboard-links.jpg) | ![Achievements on the checks page](docs/images/dashboard-achievements.jpg) |

## Playing with others

**Death Link, Energy Link, Trap Link** (optional): your deaths reach the other players and theirs hit you (a
breach and a fire by default, never enough to destroy your ship), a fuel reserve is shared with everyone, and
traps travel between games.

**Traps** (if the seed has them): fire, hull breach, fuel leak, system damage, hull damage, a boarding party,
the rebel fleet getting closer, every room losing its air, or for your next fight a hazard at the beacon, an
anti-ship battery or a Flagship power surge. They wait for the right moment and can never destroy your ship on
their own.

## Every seed has its own save

FTL can unlock a ship but never lock it again, so each seed and solo mode get their own FTL save. When you join
a new seed the mod asks first, and the old save stays exactly as it was. The **Saves** button lists them all.
Your normal FTL save is never touched.

<p align="center"><img src="docs/images/saves.png" alt="The Archipelago saves window" width="640"></p>

## How you win

Beat the Flagship with several **different** ship layouts (Kestrel A and Kestrel B count as two), on Normal or
Hard: five by default, the seed decides. You also need **Archives**, pieces scattered in the multiworld: 10 of
the 12 by default.
The main menu always shows where you stand.

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

## Make it your own

The default options are the recommended ones, and five presets go from a 3 hour first game to 20 hours or
more. If you want something else, a few options change how a run feels:

- **Sector Skip**: a layout that already reached the next sector can skip sectors 1 to 4. Their first beacon is
  an exit, and jumping right away gives 60 scrap and one more pick in the start-of-run menu.
- **Sector Locks**: each layout needs Sector Passes to leave sectors 4 and 7.
- **Fight checks** per run or per sector, **reactor checks**, more **event checks**.
- **Flagship Sabotage**: each Flagship phase arrives weakened, less hull, shields or weapons.
- **Progressive Unlocks the System**: the first upgrade of a system also unlocks it, so systems come sooner.

![Sector Skip: the first beacon is an exit](docs/images/sector-skip.jpg)

Every option is explained in the [options page](docs/wiki/Options.md), in six languages.

## Getting started

1. Download `ArchipelagoFTL.ftl` and the Hyperspace library for your system from the
   [release](https://github.com/TheLiloji/FTLArchipelago/releases), then follow the setup page for
   [Windows](docs/wiki/Setup-Windows.md) or [Linux](docs/wiki/Setup-Linux.md). Both pages exist in English,
   French, German, Spanish, Italian and Portuguese: pick your language at the top.
2. Make your YAML: the default options are the recommended ones, or pick a [preset](docs/wiki/Options.md) for a
   shorter or longer game. Whoever generates the seed needs `ftl.apworld` and Archipelago 0.6.7.
3. Start FTL, type the server, the port and your slot name in the panel at the bottom left, and connect.
   Ctrl+V pastes the room's whole `/connect` line.

![Connection panel](docs/images/connect-panel.jpg)

No server? **Solo mode** plays a ready-made seed alone, one item per check. It does not use your YAML.
Universal Tracker works too, without your YAML.

More in the wiki: [playing](docs/wiki/Playing.md), [options](docs/wiki/Options.md),
[Multiverse](docs/wiki/Multiverse.md),
[hosting a seed](docs/wiki/Hosting-a-seed.md), [FAQ](docs/wiki/FAQ.md).

## FTL: Multiverse

Archipelago also runs on top of **FTL: Multiverse 5.5** as its own game, **FTL Multiverse** (`ftl_mv.apworld` and
`FTLArchipelago-MV.ftl`, on the releases named `-mv`). Everything from the base mod is there, plus all the Multiverse
ships, the Magic Hat to reroute to the sector you choose, Multiverse endings and ship quests as checks, and the
AP STORE in the secret sectors too. A ship that starts without Oxygen gets it offered for free.

| | |
|---|---|
| ![Multiverse main menu](docs/images/mv-main-menu.jpg) | ![AP STORE and Archipelago beacons on a Multiverse map](docs/images/mv-sector-map.jpg) |
| ![Magic Hat destinations](docs/images/mv-magic-hat-secret.jpg) | ![Multiverse ships on the dashboard](docs/images/mv-ships.jpg) |

Install Hyperspace, the two Multiverse zips (Assets, then Data), then `FTLArchipelago-MV.ftl` last in ftlman, and put
`ftl_mv.apworld` in `custom_worlds`.

## Languages

English, French, Spanish, German, Italian and Portuguese, following FTL's own language. The French text was
written by hand and the Spanish was reviewed by Trapper444; the other translations were made with AI and may
have mistakes, fixes are welcome.

## Credits

The first design of the items and locations comes from the [FTL Manual by Et0san](https://github.com/Et0san/Manual)
(MIT). The FTL Archipelago logo was drawn by Trapper444, who also translated the mod into Spanish. Built on
[FTL: Hyperspace](https://github.com/FTL-Hyperspace/FTL-Hyperspace) (CC-BY-SA 4.0). See
`apworld/ftl/LICENSE.md` and `mod/ArchipelagoFTL/CREDITS.md`.

Building from source and running the tests: [docs/BUILDING.md](docs/BUILDING.md).
