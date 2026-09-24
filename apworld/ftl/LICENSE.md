# License and credits

## This apworld

Copyright (c) 2026 TheLiloji

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without
limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

## Credit: the FTL Manual world by Et0san

This world would not have the shape it has without **Manual FTL** by **Et0san**, released under the MIT
license.

- Repository: <https://github.com/Et0san/Manual> (branch `eto/manual_FTL`), a fork of
  [ManualForArchipelago/Manual](https://github.com/ManualForArchipelago/Manual) (MIT)
- Release used as a reference: *Manual FTL v1.0.0*, tag
  [`Manual-FTL-1.0.0`](https://github.com/Et0san/Manual/releases/tag/Manual-FTL-1.0.0), 21 April 2026
- Archipelago game name of that world: `Manual_FTL_eto`

**What is reused: the data and the breakdown.** Et0san worked out which parts of FTL make good Archipelago
content and how to cut them up, and that design is the starting point here:

- the ten ship keys, and the idea of gating ships behind items;
- the list of system blueprints, and the fact that a blueprint gates a whole system;
- sectorsanity as one check per sector *per layout*, eight sectors deep;
- one check per ship victory, and ship achievements attributed to the ship rather than to the layout;
- the split of FTL's twenty-one general achievements into "general achievements", "going the distance" and
  "ship and equipment feats", which is his editorial choice and is kept here as the three tiers of the
  `general_achievements` option;
- the shape of several options: a goal expressed as a number of different layouts, a starting ship, a
  sectorsanity switch, per-family achievement switches.

That inventory guided a data-extraction script, kept with the project's private working notes rather than
published, that reads FTL's own `ftl.dat` and cross-references it against Et0san's breakdown. Its output is
the block of tables at the top of `apworld/ftl/data.py`, marked "extracted from ftl.dat, do not edit by
hand": ship, system, achievement and shop identifiers straight from the game's data files, with the
achievement tiers and the ship/system split kept from that breakdown rather than retyped by hand.

**What is not reused: the code.** No file, function or line from Manual FTL or from the Manual template is
present in this apworld. The item and location tables are built from FTL's own `ftl.dat` (internal
identifiers such as `PLAYER_SHIP_ROCK_2`, `ACH_ROCK_FIRE` and `clonebay`, which a Manual world has no use
for), the options are written against `PerGameCommonOptions`, the logic is written as native Archipelago
rules and regions, and the in-game half is a Hyperspace Lua mod, which Manual FTL does not have.

The name `Manual_FTL_eto` is not used, and this world does not present itself as a continuation of his.

## Other components of this project

These are not part of the apworld, but they travel with it and have their own terms:

- **FTL: Hyperspace** (<https://github.com/FTL-Hyperspace/FTL-Hyperspace>), CC-BY-SA 4.0. The companion
  `.ftl` mod is written against its Lua API and requires it at runtime. It is distributed separately, by its
  own authors.
- **FTL: Faster Than Light** is a game by Subset Games. This project is an unofficial mod and is not
  affiliated with or endorsed by Subset Games. You need to own the game.
