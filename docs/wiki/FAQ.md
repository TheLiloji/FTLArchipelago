# FAQ and problems

## Where is the log?

`FTL_HS.log`, in the FTL folder on Windows and in its `data` folder on Linux. It is written again every time FTL
starts, so copy it right after a problem. Lines from the mod start with `[AP`.

When you report a problem, attach that file and say what you were doing.

## Slipstream says "Patching failed"

The mod needs [ftlman](https://github.com/afishhh/ftlman/releases/latest), it does not work with Slipstream Mod
Manager: it uses patch commands that only ftlman knows. Install the mods with ftlman as in the setup page for
[Windows](Setup-Windows.md) or [Linux](Setup-Linux.md).

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

## I changed the room password but the old one still works

A room started again from the same seed keeps its old password. Type `/option password <new password>` in the
server console to change it.

## The game asks to wipe my profile

You joined a seed different from the last one. See
[The seed has changed](Playing.md#the-seed-has-changed). Your normal FTL profile is never touched, only the
Archipelago one, and a dated copy is kept next to it.

## I won but nothing was sent

- Was the run started while you were connected to this seed? A run started before connecting, or saved under
  another seed, does not count. The mod says so at the first jump.
- Did Archipelago give you that ship? FTL can unlock a ship by itself, and a run with it does not count. The
  hangar marks it NOT RECEIVED and the mod says so when the run starts.
- Does the seed ask for Normal or Hard wins? An easier win does not count for the goal.
- Did you already win with that layout? Each victory must use a different ship layout (Kestrel A and Kestrel B
  count as two).
- Does the seed need Archives? The goal waits until you have enough of them.

## I left an AP STORE without buying a package

It is not lost. A package you did not buy stays in the shop and comes back at a later AP STORE. With
**Archipelago Shop per Ship**, it comes back at an AP STORE of a ship it belongs to.

## How many layouts does Layouts in the Seed give me?

It is the total number of layouts you can fly, your starting layout and the Kestrel Cruiser A included. With 7,
you get those two plus 5 more drawn at random. A Type B or C only comes with its ship's Type A.

## Does one Progressive upgrade count for every ship?

Yes, by default: one "Progressive Shields" raises the shields of all your ships. With **Progressive Upgrades per
Ship**, each upgrade belongs to one ship ("Kestrel Cruiser: Progressive Shields") and counts for all its layouts.

## I got a Progressive item but the system is still locked

A Progressive item raises how far a system can be upgraded, its blueprint unlocks it. They are two items, so you
can get levels before the system itself. Turn on **Progressive Unlocks the System** and the first Progressive item
unlocks the system too.

## Steam put FTL back to 1.6.14 (Windows)

A Steam update can undo the switch to 1.6.9. Install Hyperspace again with ftlman, apply, and copy the
Archipelago `Hyperspace.dll` again.

## I have FTL from Epic Games (Windows)

ftlman cannot switch the Epic version of FTL to 1.6.9, the only Windows version Hyperspace runs on. Put FTL 1.6.9
in place yourself, following [Hyperspace's own install guide](https://github.com/FTL-Hyperspace/FTL-Hyperspace), then follow the Windows setup as usual.

## Which Hyperspace file do I need?

On Windows, only `Hyperspace.dll`. The `Hyperspace.1.6.12.amd64.so` and `Hyperspace.1.6.13.amd64.so` files of the
release are for Linux: 1.6.13 for the Steam version, 1.6.12 for GOG and Humble.

## The console does not open on an AZERTY keyboard

Hyperspace opens its console with the `\` key, and reads the key itself, not the character. On a French keyboard
`\` is AltGr+8, which is the `8` key for the game, so the console never opens. Give the console another key in
**Options**, **Controls** (Insert works well). It is saved as `console=` in `settings.ini`.

## The game hangs on the loading screen

A known Hyperspace problem with a profile that was created but never played. Delete `ae_prof.sav` and any
`hs_*_prof.sav` from the save folder (after making a copy) and start again.

## My unlocks disappear between sessions

Steam Cloud is still on, or the mods were applied without Hyperspace.

## Can I play in my language?

Yes: English, French, Spanish, German, Italian and Portuguese. The mod follows FTL's language, or the
`mod_language` option of your YAML. Item and location names stay in English, because every player and tracker
shares them.
