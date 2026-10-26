# Options

**English** · [Français](Options.fr.md) · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

Your options live in a small text file, the **YAML**. You make it once, before the game, and send it to the
person who generates the multiworld.

## Before you start

You need **Archipelago 0.6.7** installed, with `ftl.apworld` from the
[release page](https://github.com/TheLiloji/FTLArchipelago/releases/latest) in its `custom_worlds` folder.
Without it, FTL is not in the list. The setup guides ([Windows](Setup-Windows.md), [Linux](Setup-Linux.md))
explain each step.

## A few words you will see

| Word | Meaning |
|---|---|
| check | something you do in the game that sends an item: reaching a sector, winning, an achievement... |
| item | what a check gives to you or to another player: a ship, a system, a weapon, scrap... |
| seed | the generated game, the same for everyone in the multiworld |
| slot | your place in the multiworld, named by the `name:` line of your YAML |
| layout | a version of a ship: Kestrel A, Kestrel B and Kestrel C are three layouts |
| progressive | an item that raises a system by one level each time you receive it |
| Archives | items you need on top of your victories to finish |
| logic | what the generator expects you to have before it asks you to do a check |

## The easy way: pick a preset

Presets are ready-made YAML files. Pick the one for the time you have:

| Preset | Time to the goal | What it is |
|---|---|---|
| `first_game` | about 3 h | **Your first Archipelago game.** 1 victory, Easy counts, 3 Type A ships, 2 Archives out of 3, no traps. Upgrades and systems you receive come aboard by themselves |
| `short_game` | about 5 h | 2 victories on Normal or Hard, 4 ship layouts, 4 Archives out of 5, every upgrade of a system at once |
| `medium_game` | about 10 h | the default options: 5 victories on Normal or Hard, 7 ship layouts, 10 Archives out of 12 |
| `long_game` | 20 h or more | 10 victories, 14 ship layouts, 16 Archives out of 20, installing a system is a check |

They are in `presets.zip` on the [release page](https://github.com/TheLiloji/FTLArchipelago/releases/latest).
The top of each file says how many checks it has and roughly how long it takes.

1. Open the file in a text editor.
2. Change the `name:` line to your name. Use only letters without accents, digits, spaces, `-` and `_`, and
   at most 16 characters: the game's connection panel cannot type anything else.
3. Send the file to the person who generates the multiworld.

The times are for a player who wins in a few runs. If FTL is new to you, count more.

## Making your own YAML

Open **ArchipelagoOptionsCreator** (in the Archipelago folder), pick **FTL: Faster Than Light**, type your
name and export the YAML. Every option has a short description: hover over it. The defaults are the
`medium_game` preset.

Three things players often get wrong:

- **Victories on Easy.** By default only Normal and Hard victories count for your goal. If you play on Easy,
  set **Victory Difficulty** to `any` (you can also write `easy` in the YAML).
- **Fewer checks is not a shorter game.** Turning sectors or achievements off does not remove their items:
  they move to the Archipelago shop, where you buy them with scrap. To shorten a game, lower **Victories
  Required** and **Layouts in the Seed** instead.
- **Death Link.** If your group plays with it, turn it on. With **Death Link Trigger** set to `both` (the
  default), every crew member you lose kills the others too. In a big multiworld or for a first game, choose
  `ship_destroyed`: only a lost run counts.

## What the options do

The Options Creator shows them in groups:

- **Goal**: how many victories, on which difficulty, how many Archives, and what a victory also sends.
  Archives can be anywhere in the multiworld, in your own world too.
- **Ships**: your first ship, which layouts are in the game and how many, how Type B and C unlock, and the
  early ship keys. **Excluded Ships and Layouts** leaves out the ships or layouts you never want to fly.
- **Checks**: what sends checks: sectors, systems, achievements, crew, fights won.
- **Systems and Upgrades** (closed at first): system blueprints, progressive levels, free upgrades and how
  received systems come aboard.
- **Weapons, Drones, Augments, Crew** (closed at first): what is locked in FTL's stores, bundles, and crew
  members as items.
- **Archipelago Shop** (closed at first): how many packages, whether they are split by sector or by ship, and
  whether the packages you see become hints for their owners.
- **Runs** (closed at first): the Head Start items, scrap at the start of a run, which event beacons are
  marked, how hard the logic is, and the language of the mod (it follows FTL by itself).
- **Playing with Others**: Death Link, Energy Link (a shared fuel reserve), Trap Link, and how many traps.

You do not need to touch the closed groups for a first game.

Two kinds of shop appear in the names. **Shop Weapons**, **Shop Drones**, **Shop Augments** and **Shop Unlock
Mode** are about FTL's own stores. **Archipelago Shop** options are about the Archipelago shop: the
packages sold at the AP STORE beacons, which hold other players' items.

## New in 0.5

| Option | What it does |
|---|---|
| **Free Upgrades** | System levels you receive are installed for free, right away and at the start of every run. Only with Progressive System Upgrades on (the default) |
| **System Install** | Systems whose blueprint you received come aboard for free: `run_start` at the start of every run, `immediately` also as soon as the blueprint arrives. The ship needs a room for it |
| **Run Start Scrap** | Each new run starts with this percentage of all the scrap items you received. 10 to 25 is a good range |
| **Combat Checks per Ship** | With each ship, the first fights you win in a run send checks. Those fights give less scrap (**Combat Check Scrap**) |
| **Victory Collects the Layout** | What a victory also sends: `sectors` (the default) sends the layout's sector checks still due, `everything` also its ship's achievements, system checks and fight checks |
| **Sector Logic** | New value `power`: before deep sectors and the Flagship, the logic expects shield layers, weapons and engines on the ship that does the check |

## New in 0.6

| Option | What it does |
|---|---|
| **Crew Names** | Crew who join you during a run take the other players' names: `multiworld` (the default), `multiworld_and_team` (then the names of the people who made and tested the mod), or `vanilla` (FTL's names) |
| **Archipelago Shop Hints** | `seen` (the default): the packages you see at an Archipelago beacon become hints, so their owners know where their item waits. `off` keeps the shop secret |
| **Trap Chance** | Three new traps that wait for your next fight: an anti-ship battery, a Flagship power surge (lighter in sectors 1 and 2), or a hazard (nebula, ion storm, asteroids, sun or pulsar). The battery and the hazard go away when the fight is over |
| **Sector Logic** | `relaxed` is now called `none`: the logic expects nothing, you may have to win with very little. For experienced players. `relaxed` still works in old YAMLs |
| **Combat Checks Mode** | `per_run` (the default): the first fights of a run send checks. `per_sector`: the first fights of each sector send their own, up to **Fights per Sector** (1 to 5, default 2) |
| **Archipelago Event Checks** | 0 to 20 (default 5): the packages of the relay and pirate events become checks of their own, "Archipelago Event 1", 2... before the events take the shop's packages |
| **Reactor Checks** | Off by default. Reactor power 10, 15, 20 and 25 send checks |
| **Flagship Sabotage** | 0 to 5 (default 0): each Flagship phase arrives weakened. Hull -10 %, then shields -1, hull -20 %, weapons -1, hull -30 % |
| **Archipelago Shop Deal Scrap** | 0 to 200 % (default 100): what the shop's deals pay. 0 turns them off |
| **Kestrel Needs Its Key** | Off by default. When you do not start with the Kestrel, the Kestrel A needs its key like any ship. FTL still shows it in the hangar: a run with it sends nothing until the key comes in |
| **Sector Locks** | Off by default. Each layout needs Sector Passes: the first to leave sector 4, the second to leave sector 7. Without them the exit stays shut and says why. Two items per layout |
| **Sector Skip** | Off by default. A layout that already reached the next sector may skip sectors 1 to 4: their first beacon is an exit, and jumping on at once gives 30 scrap |

## Expert options

A few options only exist in the YAML file, because almost nobody needs them: choosing exactly which ships must
win (`goal: victory_selection` with `victory_layouts`), the minimum amount of filler, and the five
`*_blueprint_logic` options that fine-tune the logic for shields, sensors, medbay, engines and weapons. The full
list, with every detail, is on the
[game page](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md).
