# Playing with Multiverse

**English** · [Français](Multiverse.fr.md) · [Deutsch](Multiverse.de.md) · [Español](Multiverse.es.md) ·
[Italiano](Multiverse.it.md) · [Português](Multiverse.pt.md)

The mod also plays with **FTL: Multiverse 5.5.1**. Its ships replace the base game's, and its sectors get
ARCHIPELAGO beacons too. It is its own game in Archipelago, **FTL Multiverse**, with its own world file
`ftl_mv.apworld` (next to `ftl.apworld` if you have both). A Multiverse player and a base game player can be in the
same multiworld. If you still have an old `ftlmv.apworld` in `custom_worlds`, remove it: Archipelago would see the
game twice.

## Installing

Follow the setup guide ([Windows](Setup-Windows.md), [Linux](Setup-Linux.md)), with one change: in ftlman, tick
the mods in this order, then click **Apply**.

1. Multiverse **Assets** (5.5)
2. Multiverse **Data** (5.5.1)
3. **FTLArchipelago-MV** (`FTLArchipelago-MV.ftl`)

Use the Multiverse build of the mod: the release whose name ends in `-mv`, like `v0.6.0-mv.1`. Hyperspace is
1.23.1, as in the guide.

Multiverse and the base game share FTL's profile. If you play both, or several seeds, save the
`FasterThanLight` folder before switching (see "Protect your saves" in the setup guide).

## Your YAML

Set **Multiverse** to on. In the Options Creator it is the first group.

- You always start with the **MV Kestrel Cruiser**: Starting Ship is ignored.
- **Layouts in the Seed** draws among Multiverse's 55 ships and their layouts. Every other ship comes from
  Archipelago items, like in the base game.
- **Victory Layouts** takes Multiverse's names, like "Union Cruiser B". A ship that has the same name as a base
  game ship is written with "(MV)", like "Kestrel Cruiser (MV)".
- **Shop Weapons** and **Shop Drones** go up to 37 and 14: that many of Multiverse's 120 weapons and 25 drones
  are drawn at random and handed out by Archipelago, and the others stay for sale in stores as usual. **Shop
  Augments** can take all 22 of Multiverse's augments.
- **Magic Hat** (on by default, `by_group`): the Magic Hat's sector jumps become items. Once one is received,
  the reroute menu offers the destinations it opens. `by_sector` gives one item per destination (65 items),
  `disabled` leaves the hat as Multiverse makes it. Based on ArchiHat by Trapper444.
- **Multiverse Achievement Checks** adds 26 of Multiverse's achievements (Accomplishments and Special Events) as
  checks. They only ever hold filler or traps, since some are long or rare.

Multiverse runs are longer than base game runs: count more time than the presets say.

## What changes in game

- Multiverse endings count as victories, not only the Flagship.
- Multiverse kinds of a race (Zoltan Monk, Separatist Engi, Lanius Welder...) count for that race's crew check.
  So do unique crew members of that race, like Turzil the Engi. Multiverse's own races have
  their check too (Crystal, Orchid, Shell, Leech, Phantom, Spider, Lizard). The rare ones (Cognitive, Siren, Pony,
  Obelisk) only ever hold filler: nothing you need waits there.
- The goal, the dashboard (TAB) and the Archipelago shop work the same way. The Ships page of the dashboard shows under each ship the race of most of its crew.
- Each Multiverse character who joins your crew (Turzil, Tully...) gives one free hint, once per seed.
