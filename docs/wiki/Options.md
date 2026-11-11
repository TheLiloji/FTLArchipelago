# Options

**English** · [Français](Options.fr.md) · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

Your options live in a small text file, the **YAML**. You make it once, before the game, and send it to the
person who generates the multiworld. This page explains every option, one by one. You do not need to read it
all: take a preset, and come back here when you want to change something.

**Playing with Multiverse?** See [Multiverse](Multiverse.md): installing it and what changes in your YAML.

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
| layout | a version of a ship: Kestrel A, Kestrel B and Kestrel C are three layouts. There are 28 in all, on 10 ships |
| progressive | an item that raises a system by one level each time you receive it |
| blueprint | the item that lets you have a system at all (Cloaking, Drone Control...) |
| run | one attempt, from the first beacon to a victory or a destroyed ship |
| Archives | items you need on top of your victories to finish |
| filler | small items: scrap, fuel, missiles, drone parts |
| trap | a bad item: a fire, a breach, the rebel fleet a jump closer... |
| logic | what the generator expects you to have before it asks you to do a check |
| AP STORE | the Archipelago shop, one beacon per sector, which sells the multiworld's items |

## The easy way: pick a preset

Presets are ready-made YAML files. Pick the one for the time you have:

| Preset | Time to the goal | What it is |
|---|---|---|
| `first_game` | about 3 h | **Your first Archipelago game.** 1 victory, Easy counts, 3 Type A ships, 2 Archives out of 3, no traps. Upgrades and systems you receive come aboard by themselves |
| `short_game` | about 5 h | 2 victories on Normal or Hard, 4 ship layouts, 4 Archives out of 5, every upgrade of a system at once |
| `medium_game` | about 10 h | the default options: 5 victories on Normal or Hard, 7 ship layouts, 10 Archives out of 12 |
| `long_game` | 20 h or more | 10 victories, 14 ship layouts, 16 Archives out of 20, installing a system is a check |
| `solo_game` | about 7 h | **Alone in the multiworld.** 3 victories, 5 ship layouts, fights checked per sector, sector skip and Sector Passes, more event checks |

They are in `presets.zip` on the [release page](https://github.com/TheLiloji/FTLArchipelago/releases/latest).
The top of each file says how many checks it has and roughly how long it takes.

1. Open the file in a text editor.
2. Change the `name:` line to your name. Use only letters without accents, digits, spaces, `-` and `_`, and
   at most 16 characters: the game's connection panel cannot type anything else.
3. Send the file to the person who generates the multiworld (their guide: [Hosting a seed](Hosting-a-seed.md)).

The times are for a player who wins in a few runs. If FTL is new to you, count more.

## Making your own YAML

Open **ArchipelagoOptionsCreator** (in the Archipelago folder), pick **FTL: Faster Than Light**, type your
name and export the YAML. Every option has a short description: hover over it. The defaults are the
`medium_game` preset.

You can also edit a preset by hand. Each option is one line: the YAML name, a colon, the value. For example:

```yaml
name: MyName
game: "FTL: Faster Than Light"
requires:
  version: 0.6.7
"FTL: Faster Than Light":
  victories_required: 3
  start_ship: rock_cruiser
  trap_chance: 10
```

Keep the two spaces in front of each option. An option you do not write takes its default.

## Three things players often get wrong

- **Victories on Easy.** By default only Normal and Hard victories count for your goal. If you play on Easy,
  set **Victory Difficulty** to `any` (you can also write `easy` in the YAML).
- **Fewer checks is not a shorter game.** Turning sectors or achievements off does not remove their items:
  they move to the Archipelago shop, where you buy them with scrap. To shorten a game, lower **Victories
  Required** and **Layouts in the Seed** instead.
- **Death Link.** If your group plays with it, turn it on. With **Death Link Trigger** set to `both` (the
  default), every crew member you lose kills the others too. In a big multiworld or for a first game, choose
  `ship_destroyed`: only a lost run counts.

## Ideas for your YAML

A shorter game, without changing the rest:

```yaml
  victories_required: 2
  layout_count: 4
  sectorsanity_last_sector: 6
```

A second ship fast, and received items that count right away:

```yaml
  early_ship_keys: 3
  free_upgrades: true
  system_install: run_start
  run_start_scrap: 15
```

More to do in each run:

```yaml
  combat_checks: 1
  combat_checks_mode: per_sector
  reactor_checks: true
  systemsanity: first_install
```

Chaos with friends:

```yaml
  trap_chance: 30
  trap_link: true
  death_link: true
```

A harder seed, for players who know FTL well:

```yaml
  victory_difficulty: hard
  sector_logic: none
  shop_unlock_mode: locked
  sector_locks: true
```

## Every option, group by group

The groups are the ones of the Options Creator. Each option shows its name in the Options Creator, its name in
the YAML, the values it takes and its default. The groups marked *closed* are folded at first in the Options
Creator: you do not need them for a first game.

### Goal

What you must do to finish.

#### Victories Required

`victories_required` · 1 to 28 · default `5`\
How many times you must beat the Flagship, each time with a **different** layout (Kestrel A and Kestrel B count
as two). This is the option that decides how long your game is: 1 or 2 for a first game, 5 with friends, 10 for
a long game.

#### Victory Difficulty

`victory_difficulty` · `any`, `normal`, `hard` · default `normal`\
The lowest difficulty a victory must be played on to count for your goal. `any` (or `easy`) counts every
victory, `normal` counts Normal and Hard, `hard` only Hard. An easier victory still sends its check, it just does
not count for the goal.

#### Flagship Sabotage

`flagship_sabotage` · 0 to 5 · default `0`\
The multiworld weakens the Flagship. Each level adds something, and it applies to every phase of the fight:
1 is hull -10 %, 2 adds shields -1, 3 makes it hull -20 %, 4 adds weapons -1, 5 makes it hull -30 %. A message
tells you the level when the Flagship arrives. Good for a group that wants to finish faster.

#### Archives

`archives` · 0 to 50 · default `12`\
How many Archives are hidden in the multiworld, in your world or in the other players'. Archives are items you
need on top of your victories. 0 plays without them.

#### Archives Required

`archives_required` · 0 to 50 · default `10`\
How many Archives you need to finish. Keep it a bit lower than **Archives**, so one Archive in a bad place
cannot block you. If it is higher than Archives, every Archive is needed.

#### Victory Collects the Layout

`victory_collects_layout` · `off`, `sectors`, `everything` · default `sectors`\
What a victory also sends, among the checks of that layout you have not done yet. `off`: only the victory.
`sectors`: also every sector check of that layout. `everything`: also its ship's achievements, its system checks
and its fight checks. Useful when you win with a ship and do not want to come back to it for sector 3.

### Ships

Which ships are in the game and how you get them.

#### Starting Ship

`start_ship` · one of the 10 ships · default `kestrel_cruiser`\
The ship you start with, as a Type A. Its Type B and C are found like the others'. The values are
`kestrel_cruiser`, `engi_cruiser`, `federation_cruiser`, `zoltan_cruiser`, `mantis_cruiser`, `slug_cruiser`,
`rock_cruiser`, `stealth_cruiser`, `lanius_cruiser` and `crystal_cruiser` (or just `rock`, `mantis`...).

#### Ship Layouts

`ship_layouts` · `type_a_only`, `up_to_type_b`, `all_layouts` · default `all_layouts`\
Which layouts can be in the game: only Type A, Type A and B, or all of them.

#### Layouts in the Seed

`layout_count` · 1 to 28 · default `7`\
How many layouts you can fly in this seed, in total. Your starting ship and the Kestrel A count in it, so 7
means those two plus 5 more, drawn at random among those **Ship Layouts** allows. A Type B or C only comes with
its ship's Type A. The layouts left out have no key and no check, and the hangar marks them **NOT IN SEED**. It
is raised to Victories Required if it is lower.

#### Excluded Ships and Layouts

`excluded_layouts` · a list · default empty\
Ships or layouts you never want in the seed. Name a whole ship (`"Engi Cruiser"`) or one layout
(`"Engi Cruiser B"`, or `"Engi B"`). Leaving out a Type A leaves out its whole ship. Your starting ship and the
Kestrel A cannot be left out. Example: `excluded_layouts: ["Stealth Cruiser", "Lanius Cruiser C"]`.

#### Layout Unlocks

`layout_unlocks` · `items`, `vanilla`, `independent`, `progressive` · default `items`\
How Type B and C become available.
- `items`: each layout is its own item, and you also need the ship's key to fly it.
- `vanilla`: like in FTL, by earning that ship's achievements. No layout items.
- `independent`: each layout is its own item and needs nothing else, not even the ship's key.
- `progressive`: no layout items. The ship's key comes once per layout: the first copy gives Type A, the next
  ones Type B, then C.

#### Early Ship Keys

`early_ship_keys` · 0 to 9 · default `1`\
How many ship keys, on top of your starting ship and the Kestrel, are put in your own first checks. A second
ship comes early instead of hours later. The number of keys does not change, only where they land. 0 lets them
land anywhere.

#### Kestrel Needs Its Key

`kestrel_key` · `true` / `false` · default `false`\
When you do not start with the Kestrel, the Kestrel A needs its key like any other ship. FTL still shows it in
the hangar, but it is marked **NO KEY** and START refuses it until the key comes in. Off, the Kestrel A is always
yours.

### Checks

What sends checks. Most of your checks come from sectors.

#### Sectorsanity

`sectorsanity` · `disabled`, `milestones`, `full` · default `full`\
Reaching a sector with a layout sends a check. Each layout has its own: the Rock A at sector 4 is not the same
check as the Rock B at sector 4. `full`: every sector. `milestones`: only sectors 5 and 8. `disabled`: never.

#### Sectorsanity First Sector

`sectorsanity_first_sector` · 1 to 8 · default `2`\
The first sector that sends a check. Sectors below it send nothing. With every layout in play, sectors 1 and 2
alone are 56 checks you get just by taking off, so raising this is the easiest way to trim a big seed.

#### Sectorsanity Last Sector

`sectorsanity_last_sector` · 1 to 8 · default `8`\
The last sector that sends a check. A check at sector 8 costs a whole run, a check at sector 4 comes on its own.
5 or 6 keeps the same ships but cuts the long end of the seed, the part where the others wait for you.

#### Systemsanity

`systemsanity` · `disabled`, `first_install`, `every_level` · default `disabled`\
Installing a system sends a check. `first_install`: once per system, 12 checks (Engines, Oxygen, Piloting and
Weapon Control have none, every ship starts with them). `every_level`: each upgrade level too, 64 checks, a much
longer game.

#### Systemsanity per Ship

`systemsanity_per_ship` · `true` / `false` · default `false`\
With Systemsanity on, each ship has its own install checks, like "Kestrel Cruiser: Install Cloaking". Never for a
system that ship starts with.

#### Ship Achievement Checks

`ship_achievements` · `true` / `false` · default `true`\
Each ship's three achievements send a check, 30 in all. FTL gives them to the ship, not to the layout: earning
one with Type A, B or C sends the same check.

#### General Achievement Checks

`general_achievements` · `disabled`, `basic`, `most`, `all` · default `most`\
Which of the 21 general achievements send a check. `basic`: the easy ones, like reaching sector 8. `most`: also
the harder ones earned over a run. `all`: every one, the very hard ones too.

#### Cross-Run Achievement Checks

`cross_run_achievements` · `true` / `false` · default `false`\
The three achievements you cannot earn in one run: "Rule Ten: Greed is Eternal" (10,000 scrap in all your
games), "Warlord" (1000 ships destroyed) and "Your Own Fleet" (every ship unlocked). Leave it off for a short
seed: the first two may never happen.

#### Crew Checks

`crew_checks` · `true` / `false` · default `true`\
The first crew member of each race to join you sends a check: Human, Engi, Zoltan, Mantis, Rock, Slug and
Lanius. 7 checks. The crew you start a run with does not count.

#### Archipelago Event Checks

`event_checks` · 0 to 20 · default `5`\
The packages of the relay and pirate events become checks of their own, "Archipelago Event 1", 2... up to this
number. Once they are all done, the events go back to selling packages of the Archipelago shop. 0: the events
only sell the shop's packages.

#### Reactor Checks

`reactor_checks` · `true` / `false` · default `false`\
Upgrading the reactor sends checks at power 10, 15, 20 and 25, in any run. The logic expects them around sectors
2, 4, 6 and 7.

#### Combat Checks per Ship

`combat_checks` · 0 to 10 · default `0`\
Winning fights sends checks. With each ship, the first fights you win in a run (enemy destroyed or its crew
killed) send "Fight 1 won", "Fight 2 won"... up to this number. 0 turns them off.

#### Combat Checks Mode

`combat_checks_mode` · `per_run`, `per_sector` · default `per_run`\
How fights are counted. `per_run`: the first fights of a run, as above. `per_sector`: the first fights of
**each** sector send their own check ("Sector 3 fight 1 won"), up to **Fights per Sector**, so a run to sector
8 can send checks everywhere. In this mode Combat Checks per Ship only needs to be above 0.

#### Fights per Sector

`fights_per_sector` · 1 to 5 · default `2`\
With `per_sector`: how many fights in each sector send a check, for each ship.

#### Combat Check Scrap (%)

`combat_check_scrap` · 0 to 100 · default `50`\
A fight that sends a check gives only this part of its scrap. Missiles, fuel and drone parts stay. Fights that
send nothing keep their full reward.

### Systems and Upgrades *(closed)*

How systems and their levels are locked and given back.

#### System Blueprints

`system_blueprints` · `true` / `false` · default `true`\
System blueprints are items. Without a system's blueprint, stores do not sell it. A system your ship starts
with is never taken away: it stays at level 1 until the blueprint arrives. Off, every system is for sale.

#### Progressive System Upgrades

`progressive_systems` · `true` / `false` · default `true`\
Each "Progressive" item raises how far you may upgrade a system, up to FTL's maximum. You still pay the scrap,
unless Free Upgrades is on. By default one item counts for every ship: "Progressive Shields" raises the shields
of all of them. Off, systems upgrade as in FTL.

#### Progressive Upgrades per Ship

`progressive_systems_per_ship` · `true` / `false` · default `false`\
The upgrades belong to one ship each, like "Kestrel Cruiser: Progressive Shields", and only count aboard that
ship, whatever the layout. Many more items, so a bigger Archipelago shop.

#### Progressive Unlocks the System

`progressive_unlocks_system` · `true` / `false` · default `false`\
The first Progressive item of a system also unlocks it, so that system has no separate blueprint item. Fewer
items to wait for: systems come sooner.

#### Full System Upgrades

`full_system_upgrades` · `true` / `false` · default `false`\
Each Progressive item gives every level of its system at once. Fewer items, a coarser progression.

#### Free Upgrades

`free_upgrades` · `true` / `false` · default `false`\
System levels you receive are installed for free: right away if you are in a run, and again at the start of
every run. Off, a received level only lets you buy it. Needs Progressive System Upgrades.

#### System Install

`system_install` · `store`, `run_start`, `immediately` · default `store`\
When a system whose blueprint you received comes aboard for free, if the ship has a room for it. `store`: never,
you buy it like in FTL. `run_start`: at the start of every run, from the start-of-run menu. `immediately`: also
as soon as the blueprint arrives during a run.

### Weapons, Drones, Augments, Crew *(closed)*

What is locked in FTL's own stores, and crew as items.

#### Shop Weapons

`shop_weapons` · 0 to 37 · default `37`\
How many of FTL's 37 weapons become items. The others stay normal store items. 0 leaves weapons alone.

#### Shop Drones

`shop_drones` · 0 to 14 · default `14`\
The same for the 14 drones. Drones need Drone Control to be any use.

#### Shop Augments

`shop_augments` · 0 to 23 · default `23`\
The same for the 23 augments.

#### Weapon Bundle Size

`weapon_bundle_size` · 1 to 5 · default `3`\
How many weapons each Weapon Bundle holds. A bundle unlocks all of them at once. 1 means no bundles: each weapon
is its own item. Bigger bundles mean fewer items, so a smaller Archipelago shop.

#### Drone Bundle Size

`drone_bundle_size` · 1 to 5 · default `2`\
The same for drones.

#### Augment Bundle Size

`augment_bundle_size` · 1 to 5 · default `3`\
The same for augments.

#### Shop Unlock Mode

`shop_unlock_mode` · `rarity_boost`, `locked` · default `rarity_boost`\
What receiving a weapon, drone or augment does to FTL's stores. `rarity_boost`: it was already for sale, and now
shows up much more often. `locked`: it is not for sale anywhere until you receive it. Either way, it lasts for
every future run.

#### Shop Item Delivery

`shop_item_delivery` · `true` / `false` · default `true`\
You also get one copy on the spot, once: on board if a slot is free, otherwise in the cargo hold. Off, the item
only changes what stores sell.

#### Crew Members

`crew_members` · `true` / `false` · default `true`\
Crew members as items, one per race, up to three copies. First copy: one joins your run. Second: the race enters
the start-of-run menu. Third: that menu offers an expert with one skill mastered. Lanius and Crystal stop at two.

### Archipelago Shop *(closed)*

The AP STORE beacons, one per sector, which sell the multiworld's items for scrap.

#### Archipelago Shop Checks (minimum)

`shop_checks` · 0 to 100 · default `20`\
The smallest number of packages in the shop, for the whole seed. If your options create more items than
checks, packages are added on their own (up to 400) so every item has a place. The bigger the shop, the more
packages each beacon shows: 3, 6, 9 or 12.

#### Archipelago Shop by Sector

`shop_by_sector` · `true` / `false` · default `false`\
Each package belongs to one sector, 1 to 7, and is only sold at that sector's AP STORE. Deeper packages cost
more, and the logic expects you to reach that sector first.

#### Archipelago Shop per Ship

`shop_per_ship` · `off`, `per_class`, `per_layout` · default `off`\
Each package belongs to one ship (`per_class`) or one layout (`per_layout`), and is only sold while you fly it.
It adds no packages, it splits them. A package you did not buy comes back later.

#### Archipelago Shop Hints

`shop_hints` · `off`, `seen` · default `seen`\
`seen`: the packages you see in the shop become hints, so their owners know where their item waits. `off`: the
shop stays your secret.

#### Archipelago Shop Deal Scrap (%)

`shop_deal_scrap` · 0 to 200 · default `100`\
How much scrap the shop's deals and blood pacts pay, in percent. 0 turns them off.

### Runs *(closed)*

What changes inside a run.

#### Head Starts

`head_starts` · `true` / `false` · default `true`\
Head Start items give a free system level, or a reactor bar, at the start of every future run. They only take
checks left over once every other item has its place, so with the default options few or none come.

#### Run Start Scrap (%)

`run_start_scrap` · 0 to 100 · default `0`\
Each new run starts with this part of all the scrap items you have received. Scrap items still give their
scrap once when they arrive. 10 to 25 is a good range.

#### Sector Skip

`sector_skip` · `true` / `false` · default `false`\
A layout that already reached the next sector may skip sectors 1 to 4: the first beacon of such a sector is an
exit. Jump at once for 60 scrap and one more pick in the start-of-run menu, or explore as usual. The skipped
sector's checks wait for another run.

#### Sector Locks

`sector_locks` · `true` / `false` · default `false`\
Each layout needs Sector Passes to go deeper: the first to leave sector 4, the second to leave sector 7. Without
them the exit stays shut, and the game says why. Two items per layout.

#### Event Beacons

`event_beacons` · `marked`, `important`, `hidden` · default `important`\
Which Archipelago event beacons say ARCHIPELAGO on the map. The AP STORE always does. `marked`: every event.
`important`: only the relay and the pirates, which carry a package. `hidden`: none.

#### Sector Logic

`sector_logic` · `none`, `standard`, `strict`, `power` · default `standard`\
What the generator expects your ship to have before it sends you deep. It never changes what the game lets you
do.
- `none`: nothing. You may be expected to reach the Flagship with very little. For experienced players
  (`relaxed`, its old name, still works).
- `standard`: 2 blueprints for sector 4, 4 for sector 6, 5 for the Flagship.
- `strict`: 3 blueprints for sector 3, 6 for sector 5, 9 for sector 7, 11 for the Flagship.
- `power`: looks at the ship that does the check. Sector 5 needs 2 shield layers, sector 8 also Weapon Control
  5, the Flagship 3 layers, Weapon Control 6 and Engines 4.

#### Mod Language

`mod_language` · `game`, `english`, `french`, `spanish`, `german`, `italian`, `portuguese` · default `game`\
The language of the mod's menus and messages. `game` follows FTL by itself. Item and location names always stay
in English, because every player and tracker shares them.

### Playing with Others

The links with the other players. All off by default.

#### Death Link

`death_link` · `true` / `false` · default `false`\
When you die, the others who play with Death Link die too, and the other way round. A death you receive never
destroys your ship and never kills your last crew member.

#### Death Link Trigger

`death_link_trigger` · `ship_destroyed`, `crew_death`, `both` · default `both`\
What sends your death. `ship_destroyed`: only a lost run, best in a big multiworld. `crew_death`: any crew
member lost. `both`: either. Crew die often, so `both` sends a lot.

#### Death Link Cloned Crew

`death_link_cloned_crew` · `true` / `false` · default `false`\
Whether a crew member the Clone Bay brings back counts as a death. Off, only a crew member who does not come
back counts.

#### Death Link Toggle

`death_link_toggle` · `true` / `false` · default `true`\
You can turn Death Link off and on during the game, by clicking it on the first page of the TAB dashboard. Turn
this off for a group that wants everyone tied together until the end.

#### Death Link Effect

`death_link_effect` · `major_incident`, `crew_member`, `hull_damage`, `fire`, `boarding`, `varied` · default `major_incident`\
What a death from another player does to you. `major_incident`: a breach and a fire in a system room, the
hardest. `crew_member`: one crew member dies. `hull_damage`: hull damage. `fire`: a fire. `boarding`: an enemy
Mantis comes aboard. `varied`: one of the four milder ones at random.

#### Energy Link

`energy_link` · `true` / `false` · default `false`\
A fuel reserve shared with every Energy Link player, whatever game they play. Your extra fuel goes in at quiet
beacons (with a 25 % loss), and you get some back when you drop below 3.

#### Trap Link

`trap_link` · `true` / `false` · default `false`\
Traps are shared with the other Trap Link players: when one of you gets a trap, the others get one too, even if
your own seed has none. A trap from another game is matched to the closest FTL trap.

#### Trap Chance

`trap_chance` · 0 to 100 · default `0`\
The part of filler items that become traps. There are 11 kinds: fire, hull breach, fuel leak, system damage,
rebel fleet, hull damage, boarding party, O2 drain, and three that wait for your next fight (an anti-ship
battery, a Flagship power surge, a hazard). Traps wait for a quiet beacon and never destroy your ship.

#### Crew Names

`crew_names` · `vanilla`, `multiworld`, `multiworld_and_team` · default `multiworld`\
Names of the crew who join you during a run. `multiworld`: the other players' slot names, then FTL's.
`multiworld_and_team`: the same, then the people who made and tested the mod. `vanilla`: FTL's names. Your
starting crew keeps its names.

### Expert (YAML only)

These options are not in the Options Creator, only in the YAML. Almost nobody needs them.

#### Goal

`goal` · `victory_count`, `victory_selection` · default `victory_count`\
`victory_count`: win with Victories Required different layouts. `victory_selection`: win with each layout
listed in **Victory Layouts**, and only those.

#### Victory Layouts

`victory_layouts` · a list · default empty\
With `victory_selection`, the layouts that must each win. Example:
`victory_layouts: ["Kestrel Cruiser A", "Mantis Cruiser B"]`. They must be in the seed.

#### Minimum Filler

`minimum_filler` · 0 to 100 · default `20`\
The smallest number of filler items in your seed.

#### Shields, Sensors, Medbay blueprint logic

`shields_blueprint_logic`, `sensors_blueprint_logic`, `medbay_blueprint_logic` · `required`, `upgrade_only`, `start_with` · default `upgrade_only`\
`required`: a ship that starts with that system is only in logic once you have its blueprint. `upgrade_only`:
the blueprint is only needed to upgrade or buy the system. `start_with`: you start with the blueprint.

#### Engines, Weapon Control blueprint logic

`engines_blueprint_logic`, `weapons_blueprint_logic` · `anywhere`, `early`, `start_with` · default `early`\
Every ship starts with these two systems, so they only decide how early the blueprint comes: anywhere, early
in your own first checks, or at the start.

The [game page](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
explains how the logic, the traps and the links work in more depth.
