# Options

**English** · [Français](Options.fr.md) · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

## The easy way: keep the defaults

The default options are the recommended ones. You only need to change your name:

1. Open **ArchipelagoOptionsCreator** (in the Archipelago folder), or the options page of the website that
   hosts the room.
2. Pick **FTL: Faster Than Light**, type your name, and export the YAML.

With the defaults, you win by beating the Flagship **5 times with 5 different ships, on Normal or Hard**, and
by collecting **10 of the 12 Archives** hidden in the other players' worlds. It is a game of several evenings,
around 10 hours to the goal.

If your group plays with **Death Link**, turn it on. By default the loss of a crew member counts as a death,
not only a lost run.

## Presets

Want something shorter or longer? Pick a preset by answering two questions: how much time do you have, and do
you know FTL well?

| | New to FTL | You know FTL well |
|---|---|---|
| **FTL among other games**, short sessions | `A1_multi_game_beginner` | `A2_multi_game_veteran` |
| **Two evenings** | `C1_two_evenings_beginner` | `C2_two_evenings_veteran` |
| **FTL on its own**, a long game | `B1_solo_beginner` | `B2_solo_veteran` |

They are in `presets.zip` on the [release page](https://github.com/TheLiloji/FTLArchipelago/releases/latest),
and in the **Preset** menu of the website's options page. The top of each file says how many checks it has
and roughly how long it takes. Change the `name:` line and you are done.

## What the options do

The Options Creator shows them in groups:

- **Goal**: how many victories, on which difficulty, and how many Archives.
- **Game Size**: which ship layouts are in the game, and what sends checks (sectors, systems, achievements,
  crew, the Archipelago shop). Fewer checks means a shorter game.
- **Playing with Others**: Death Link, Energy Link (a shared fuel reserve), Trap Link, and how many traps.
- **Advanced** (closed at first): your first ship, the Head Start items, the language of the mod (it follows FTL
  by itself), the range of sectors that count, how Type B and C unlock, what is locked in stores, and how hard
  the logic is. You do not need to touch these.

Every option has a short description: hover over it in the Options Creator.

## Expert options

A few options only exist in the YAML file, because almost nobody needs them: choosing exactly which ships must
win (`goal: victory_selection` with `victory_layouts`), the minimum amount of filler, and the five
`*_blueprint_logic` options that fine-tune the logic for shields, sensors, medbay, engines and weapons. The full
list, with every detail, is in the game page: `apworld/ftl/docs/en_FTL Faster Than Light.md`.
