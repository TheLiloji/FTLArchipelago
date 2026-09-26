# FAQ and problems

## Where is the log?

`FTL_HS.log`, in the FTL folder on Windows and in its `data` folder on Linux. It is written again every time FTL
starts, so copy it right after a problem. Lines from the mod start with `[AP`.

When you report a problem, attach that file and say what you were doing.

## The connection panel is missing

Hyperspace is not loaded, or the mod was not applied. Check that the top right corner of the main menu shows
`HS-1.23.1`. If it does not, apply the mods again in ftlman (Hyperspace first). On Linux, start the game from
Steam, not `FTL.amd64`.

## The panel is there but connecting never works

Most likely the `Hyperspace.dll` (or `.so`) is the official one and not the Archipelago one. The log tells you:
it should contain `[AP-net] network module present`. Copy the Archipelago library into the game folder again.
Clicking Apply in ftlman can put the official one back.

## "No slot by that name on this server"

The slot name must match the YAML exactly, capital letters included.

The panel cannot type accents or symbols like `!` or `@`. Keep the slot name and the room password to letters,
digits and spaces.

Type the port in the Port field, not after the address: `archipelago.gg` and `38281`, not `archipelago.gg:38281`.

## "The server is not answering"

Check the address and the port. For a room on archipelago.gg the port changes when the room goes to sleep and
wakes up: look at the room page again.

## The game asks to wipe my profile

You joined a seed different from the last one. See
[The seed has changed](Playing.md#the-seed-has-changed). Your normal FTL profile is never touched, only the
Archipelago one, and a dated copy is kept next to it.

## I won but nothing was sent

- Was the run started while you were connected to this seed? A run started before connecting, or saved under
  another seed, does not count. The mod says so at the first jump.
- Does the seed ask for Normal or Hard wins? An easier win does not count for the goal.
- Did you already win with that ship? Each victory must use a different ship.
- Does the seed need Archives? The goal waits until you have enough of them.

## Steam put FTL back to 1.6.14 (Windows)

A Steam update can undo the switch to 1.6.9. Install Hyperspace again with ftlman, apply, and copy the
Archipelago `Hyperspace.dll` again.

## The game hangs on the loading screen

A known Hyperspace problem with a profile that was created but never played. Delete `ae_prof.sav` and any
`hs_*_prof.sav` from the save folder (after making a copy) and start again.

## My unlocks disappear between sessions

Steam Cloud is still on, or the mods were applied without Hyperspace.

## Can I play in my language?

Yes: English, French, Spanish, German, Italian and Portuguese. The mod follows FTL's language, or the
`mod_language` option of your YAML. Item and location names stay in English, because every player and tracker
shares them.
