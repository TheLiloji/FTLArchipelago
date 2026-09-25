# Setup on Windows

**English** · [Français](Setup-Windows.fr.md) · [Deutsch](Setup-Windows.de.md) · [Español](Setup-Windows.es.md) ·
[Italiano](Setup-Windows.it.md) · [Português](Setup-Windows.pt.md)

Takes about ten minutes. You need FTL from Steam (or GOG), with the Advanced Edition content, which every copy
sold today has.

## What to download

Put everything in the same folder, for example `Downloads`.

- From the [FTL Archipelago release](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
  `ArchipelagoFTL.ftl` and `Hyperspace.dll`.
- From the [ftlman release](https://github.com/afishhh/ftlman/releases/latest):
  `ftlman-x86_64-pc-windows-gnu.zip`.
- From the [Hyperspace 1.23.1 release](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1):
  `FTL.Hyperspace.1.23.1-Windows.zip`.

Unzip both zips. You get a `ftlman` folder, with `ftlman.exe` and an empty `mods` folder inside, and
`Hyperspace.ftl` from the Hyperspace zip.

## 1. Protect your saves

- In Steam, right click FTL, **Properties**, **General**, and turn off **Steam Cloud**. Otherwise Steam can put
  an old save back while you play.
- Copy the folder `Documents\My Games\FasterThanLight` somewhere safe.

The mod uses a profile of its own, so your normal FTL progress is not touched. The copy is just in case.

## 2. Install Hyperspace with ftlman

Start `ftlman.exe`. It usually finds the game by itself; if not, point it to the FTL folder (the one with
`FTLGame.exe`, for example `C:\Program Files (x86)\Steam\steamapps\common\FTL Faster Than Light`).

Install **Hyperspace 1.23.1** from ftlman. On a Steam copy, ftlman first switches FTL to version 1.6.9 and keeps
the original as `FTLGame_orig.exe`. That is normal: 1.6.9 is the only Windows version Hyperspace runs on.

## 3. Add the mod

Copy `Hyperspace.ftl` and `ArchipelagoFTL.ftl` into the `mods` folder, the one inside the `ftlman` folder. In
ftlman, tick both, with Hyperspace **above** ArchipelagoFTL, and click **Apply**. Close ftlman once it is done.

## 4. Swap in the Archipelago library

In the FTL folder there is now a `Hyperspace.dll`. Rename it to `Hyperspace.dll.official` (to keep it), then copy
the `Hyperspace.dll` from the FTL Archipelago release in its place.

FTL must be closed for this: Windows locks the file while the game runs.

If you ever click Apply again in ftlman, copy the Archipelago `Hyperspace.dll` again afterwards.

## 5. Start the game

Start FTL from Steam. You should see:

![Main menu after installing](../images/connect-panel.jpg)

- `HS-1.23.1` in the top right corner,
- the Archipelago logo at the top left,
- a **Connect to a multiworld** panel at the bottom left.

If the panel is missing, or connecting never works, see the [FAQ](FAQ.md).

## Updating to a new version

Put the new `ArchipelagoFTL.ftl` in ftlman's `mods` folder, click **Apply** again, then copy the new
`Hyperspace.dll` over the one in the FTL folder.

Next: [Playing](Playing.md).
