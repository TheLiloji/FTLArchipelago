# Options

Your YAML file decides how big the seed is and how hard it gets. The easy way is to start from a preset and
change the `name:` line. Every option is also explained on the player options page of the Archipelago website
that hosts the world, and in `apworld/ftl/docs/en_FTL Faster Than Light.md`.

## Presets

They are in the `presets` folder of the repo, and in `presets.zip` in the release.

| Preset | For |
|---|---|
| `A1_multi_game_beginner` | FTL is one game among several, you are new to FTL |
| `A2_multi_game_veteran` | same, you know FTL well (traps and Death Link on) |
| `B1_solo_beginner` | FTL alone, a long seed with every ship layout |
| `B2_solo_veteran` | same, with chosen victories, strict logic and traps |
| `C1_two_evenings_beginner` | FTL alone in a multiworld, about two evenings |
| `C2_two_evenings_veteran` | same, harder |

The comment at the top of each file gives its size and a rough play time.

## The ones that matter most

**Size of the seed**

- `sectorsanity`, `sectorsanity_first_sector`, `sectorsanity_last_sector`: reaching a sector with a given ship
  is a check. Most checks come from here. Starting at sector 2 or 3 removes the easy early ones.
- `ship_layouts`: only Type A ships, or B and C too. More layouts means more checks and more ships to find.
- `systemsanity`: installing a system is a check (`first_install`), or every level too (`every_level`).
- `shop_checks`: how many packages the Archipelago shop holds at least.

**The goal**

- `goal`: `victory_count` (any N different ships) or `victory_selection` (the ships you list in
  `victory_layouts`).
- `victories_required`: how many different ships must beat the Flagship.
- `victory_difficulty`: `any`, or ask for Normal or Hard wins.
- `archives` and `archives_required`: add Archives, spread in the other worlds. Leave a few more than required,
  for example 12 and 8.

**How much is locked**

- `system_blueprints`: systems need a blueprint before stores sell them.
- `progressive_systems`: upgrade levels are items too.
- `shop_unlock_mode`: `rarity_boost` (received weapons become more common, nothing is removed) or `locked`
  (a weapon is missing from stores until you receive it). `locked` is harsher.
- `shop_item_delivery`: put one copy of a received weapon or drone on your ship right away.

**How hard the logic is**

- `sector_logic`: `relaxed` sends you deep early, `strict` expects a real ship first.
- The five `*_blueprint_logic` options decide whether a ship that starts with shields, sensors, a medbay,
  engines or weapons needs that blueprint before logic sends it far.

**Links with other players**

- `death_link`: your deaths reach the others and theirs reach you. `death_link_trigger` picks which deaths count
  (losing the run, losing a crew member, or both) and `death_link_effect` what a received death does.
- `energy_link`: a fuel reserve shared with every Energy Link player.
- `trap_link`: traps are shared with the other Trap Link players.

## Options that do nothing yet

A few options are listed as planned features: progressive crew health, progressive skills, skill checks and
death-type checks. The generator accepts them but the game ignores them for now. Leave them at their default.
