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
- [Multiverse](Multiverse.md): playing with FTL: Multiverse
- [Hosting a seed](Hosting-a-seed.md): generating and running a room with FTL in it
- [FAQ and problems](FAQ.md)

## New in 0.6

- **Every seed has its own save.** Join a new seed and your old save stays as it was. The Saves button switches
  between them.
- **More ways to send checks**: fights won in every sector, the Archipelago events, your reactor power.
- **Four new traps** that wait for your next fight: a hazard at the beacon, an anti-ship battery, a Flagship power
  surge. And one that drains the air of every room.
- **Two new events**: an Engi who bets on overclocking your reactor, and a rare arms dealer in pirate sectors.
- **Sector Skip, Sector Locks, Flagship Sabotage**: new options that change how a run feels.
- **The dashboard knows the logic**: a blue line marks the checks you can already do with what you have.
- **A solo preset**, about 7 hours, made for playing alone.
- **Multiverse is its own game**, so base game and Multiverse players can share a multiworld, and the Magic Hat
  takes you to the sector you choose.
- Universal Tracker works, and a lot of fixes from your reports.

Everything else is in the [release notes](https://github.com/TheLiloji/FTLArchipelago/releases/tag/v0.6.0).

## In numbers

| | |
|---|---|
| Ships | 10, with 28 layouts, each with its own sector checks |
| Checks | about 75 for a first game, 150 with the defaults, several hundred with everything on |
| Items | 37 weapons, 14 drones, 23 augments, 8 crew races, 16 systems, ship keys and layouts |
| Options | more than 70, 14 of them new in 0.6, and 5 presets from 3 hours to 20 or more |
| In game | 11 traps, 7 Archipelago events, an AP STORE in every sector, a dashboard on `TAB` |
| Languages | 6 |
| With Multiverse | 55 ships, 18 crew races, 26 achievements as checks, a Magic Hat with 65 destinations |

## How it plays

**You start with almost nothing.** One ship, few systems, and every other cruiser locked in the hangar.

![Locked ships in the hangar](../images/hangar.jpg)

**Every run you play sends items to the others.** Reaching a sector, installing a system, recruiting a new race,
winning a fight, earning an achievement or beating the Flagship are all checks.

**What they find for you arrives on its own.** A ship key opens a cruiser, a blueprint lets stores sell a system,
a weapon lands on your ship and shows up more in stores.

![Items arriving during a run](../images/in-game.jpg)

**Each new run starts stronger.** Head starts give free system levels, and the start-of-run menu lets you bring
one weapon, one drone and one crew member from everything you have collected.

![The start-of-run menu](../images/start-menu.jpg)

**Losing a run only costs the run.** Everything you received stays.

## Archipelago beacons

Every sector map has a beacon marked **AP STORE**. Its shop sells packages for the other players, and some
marked **FOR YOU**. Buying one sends it right away.

| | |
|---|---|
| ![Archipelago beacons](../images/map.jpg) | ![The Archipelago shop](../images/shop.jpg) |

The same shop sells **deals**: scrap now, and a trap in exchange. With Trap Link on it hits another player two
times out of three, otherwise it hits you in your next fight. The **blood pacts** on the second page pay more,
but sometimes one of your crew dies for good. Never your last one.

![Blood pacts in the Archipelago shop](../images/blood-pacts.jpg)

Other beacons hold small events of their own: a relay carrying packages, pirates holding a package (pay or
fight), a Zoltan checkpoint, a Slug selling real hints, a surge from another world, an Engi tech who wants to
overclock your reactor, and a rare arms dealer in pirate sectors. The ones that send packages say
**ARCHIPELAGO** on the map.

| | |
|---|---|
| ![The Engi overclock bet](../images/event-overclock.jpg) | ![The arms dealer](../images/event-arms-dealer.jpg) |

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

<p align="center"><img src="../images/saves.png" alt="The Archipelago saves window" width="640"></p>

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

![Sector Skip: the first beacon is an exit](../images/sector-skip.jpg)

Every option is explained in the [options page](Options.md), in six languages.

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

## Getting started

1. Download `ArchipelagoFTL.ftl` and the Hyperspace library for your system from the
   [release](https://github.com/TheLiloji/FTLArchipelago/releases), then follow the setup page for
   [Windows](Setup-Windows.md) or [Linux](Setup-Linux.md). Both pages exist in English,
   French, German, Spanish, Italian and Portuguese: pick your language at the top.
2. Make your YAML: the default options are the recommended ones, or pick a [preset](Options.md) for a
   shorter or longer game. Whoever generates the seed needs `ftl.apworld` and Archipelago 0.6.7.
3. Start FTL, type the server, the port and your slot name in the panel at the bottom left, and connect.
   Ctrl+V pastes the room's whole `/connect` line.

![Connection panel](../images/connect-panel.jpg)

No server? **Solo mode** plays a ready-made seed alone, one item per check. It does not use your YAML.
Universal Tracker works too, without your YAML.

More pages: [playing](Playing.md), [options](Options.md),
[hosting a seed](Hosting-a-seed.md), [FAQ](FAQ.md).

## FTL: Multiverse <sup>beta</sup>

Archipelago also runs on top of **FTL: Multiverse 5.5** as its own game, **FTL Multiverse** (`ftl_mv.apworld` and
`FTLArchipelago-MV.ftl`, on the releases named `-mv`). Everything from the base mod is there, plus all the Multiverse
ships, the Magic Hat to reroute to the sector you choose, Multiverse endings and ship quests as checks, and the
AP STORE in the secret sectors too. A ship that starts without Oxygen gets it offered for free.

| | |
|---|---|
| ![Multiverse main menu](../images/mv-main-menu.jpg) | ![AP STORE and Archipelago beacons on a Multiverse map](../images/mv-sector-map.jpg) |
| ![Magic Hat destinations](../images/mv-magic-hat-secret.jpg) | ![Multiverse ships on the dashboard](../images/mv-ships.jpg) |

Install Hyperspace, the two Multiverse zips (Assets, then Data), then `FTLArchipelago-MV.ftl` last in ftlman, and put
`ftl_mv.apworld` in `custom_worlds`.

## Languages

English, French, Spanish, German, Italian and Portuguese, following FTL's own language. See below for who
checked what. Fixes are welcome.

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
