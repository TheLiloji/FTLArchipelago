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

- **Goal**: how many victories, on which difficulty, and how many Archives. Archives can be anywhere in the
  multiworld, in your own world too.
- **Game Size**: which ship layouts are in the game and how many, and what sends checks: sectors, systems,
  achievements, crew, fights won, the Archipelago shop.
  **Excluded Ships and Layouts** leaves out the ships or layouts you never want to fly.
- **Playing with Others**: Death Link, Energy Link (a shared fuel reserve), Trap Link, and how many traps.
- **Advanced** (closed at first): you do not need to touch these. Your first ship, the Head Start items, the
  language of the mod (it follows FTL by itself), the range of sectors that count, how Type B and C unlock,
  what is locked in stores, the options below, and how hard the logic is.

Two kinds of shop appear in the names. **Shop Weapons**, **Shop Drones**, **Shop Augments** and **Shop Unlock
Mode** are about FTL's own stores. **Archipelago Shop** options are about the Archipelago shop: the
packages sold at the ARCHIPELAGO beacons, which hold other players' items.

## New in 0.5

| Option | What it does |
|---|---|
| **Free Upgrades** | System levels you receive are installed for free, right away and at the start of every run. Only with Progressive System Upgrades on (the default) |
| **System Install** | Systems whose blueprint you received come aboard for free: `run_start` at the start of every run, `immediately` also as soon as the blueprint arrives. The ship needs a room for it |
| **Run Start Scrap** | Each new run starts with this percentage of all the scrap items you received. 10 to 25 is a good range |
| **Combat Checks per Ship** | With each ship, the first fights you win in a run send checks. Those fights give less scrap (**Combat Check Scrap**) |
| **Victory Collects the Layout** | What a victory also sends: `sectors` (the default) sends the layout's sector checks still due, `everything` also its ship's achievements, system checks and fight checks |
| **Sector Logic** | New value `power`: before deep sectors and the Flagship, the logic expects shield layers, weapons and engines on the ship that does the check |

## Expert options

A few options only exist in the YAML file, because almost nobody needs them: choosing exactly which ships must
win (`goal: victory_selection` with `victory_layouts`), the minimum amount of filler, and the five
`*_blueprint_logic` options that fine-tune the logic for shields, sensors, medbay, engines and weapons. The full
list, with every detail, is on the
[game page](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md).
