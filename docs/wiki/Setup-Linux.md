# Setup on Linux

**English** · [Français](Setup-Linux.fr.md) · [Deutsch](Setup-Linux.de.md) · [Español](Setup-Linux.es.md) ·
[Italiano](Setup-Linux.it.md) · [Português](Setup-Linux.pt.md)

This is for the native Linux version of FTL from Steam (1.6.13). Do not run FTL through Proton for this: the
Linux library below will not load there. Takes about ten minutes.

## What to download

Put everything in the same folder, for example `Downloads`.

- From the [FTL Archipelago release](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
  `ArchipelagoFTL.ftl` and `Hyperspace.1.6.13.amd64.so`.
- From the [ftlman release](https://github.com/afishhh/ftlman/releases/latest):
  `ftlman-x86_64-unknown-linux-gnu.tar.gz`.
- From the [Hyperspace 1.23.1 release](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1):
  `FTL.Hyperspace.1.23.1-Linux.zip`.

## 1. Protect your saves

Turn off **Steam Cloud** for FTL (right click, Properties, General), then copy your save folder:

```sh
cp -r ~/.local/share/FasterThanLight ~/.local/share/FasterThanLight.backup
```

## 2. Unpack

Open a terminal in the folder with the downloads:

```sh
tar xzf ftlman-x86_64-unknown-linux-gnu.tar.gz
unzip FTL.Hyperspace.1.23.1-Linux.zip Hyperspace.ftl
cp Hyperspace.ftl ArchipelagoFTL.ftl ftlman/mods/
```

You now have ftlman in `ftlman/ftlman`, and both mods in its `mods` folder.

## 3. Install Hyperspace and the mod

Still in the same terminal:

```sh
D=~/.steam/steam/steamapps/common/"FTL Faster Than Light"/data
ftlman/ftlman hyperspace-install 1.23.1 -d "$D"
ftlman/ftlman patch -d "$D" Hyperspace.ftl ArchipelagoFTL.ftl
```

`D` is the game folder that holds `FTL.amd64`. If FTL is in another Steam library, change that first line.

Always give both mods, Hyperspace first. ftlman rebuilds the game data from scratch each time, so applying only
`ArchipelagoFTL.ftl` would remove Hyperspace.

## 4. Swap in the Archipelago library

Keep the official library and put the Archipelago one in its place:

```sh
cp "$D/Hyperspace.1.6.13.amd64.so" "$D/Hyperspace.1.6.13.amd64.so.official"
cp Hyperspace.1.6.13.amd64.so "$D/"
```

## 5. Start the game

Start FTL **from Steam**, or with the `FTL` script in the `data` folder. Starting `FTL.amd64` directly skips
Hyperspace. You should see:

![Main menu after installing](../images/connect-panel.jpg)

- `HS-1.23.1 x64` in the top right corner,
- the Archipelago logo at the top left,
- a **Connect to a multiworld** panel at the bottom left.

If the panel is missing, or connecting never works, see the [FAQ](FAQ.md).

## Updating to a new version

Put the new `ArchipelagoFTL.ftl` in `ftlman/mods/`, run the `patch` line of step 3 again, then step 4 with the
new `Hyperspace.1.6.13.amd64.so`.

Next: [Playing](Playing.md).
