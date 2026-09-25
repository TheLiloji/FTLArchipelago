# Installing on Linux

This is for the native Linux version of FTL from Steam (1.6.13). Do not run FTL through Proton for this: the
Linux library below will not load there.

## What to download

- From the [FTL Archipelago release](https://github.com/TheLiloji/FTLArchipelago/releases): `ArchipelagoFTL.ftl`
  and `Hyperspace.1.6.13.amd64.so`.
- [ftlman](https://github.com/afishhh/ftlman/releases), the Linux build.
- `Hyperspace.ftl` from the [Hyperspace 1.23.1 release](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1).

## 1. Protect your saves

Turn off **Steam Cloud** for FTL (right click, Properties, General), then copy your save folder:

```sh
cp -r ~/.local/share/FasterThanLight ~/.local/share/FasterThanLight.backup
```

## 2. Install Hyperspace

The game files are in `~/.steam/steam/steamapps/common/FTL Faster Than Light/data`. With ftlman, install
Hyperspace 1.23.1 there, from the window or from a terminal:

```sh
D=~/.steam/steam/steamapps/common/"FTL Faster Than Light"/data
ftlman hyperspace-install 1.23.1 -d "$D"
```

## 3. Add the mod

Apply both mods, Hyperspace first:

```sh
ftlman patch -d "$D" Hyperspace.ftl ArchipelagoFTL.ftl
```

Always give both. ftlman rebuilds the game data from scratch each time, so applying only `ArchipelagoFTL.ftl`
would remove Hyperspace.

## 4. Swap in the Archipelago library

Keep the official library and put the Archipelago one in its place:

```sh
cp "$D/Hyperspace.1.6.13.amd64.so" "$D/Hyperspace.1.6.13.amd64.so.official"
cp Hyperspace.1.6.13.amd64.so "$D/"
```

## 5. Start the game

Start FTL **from Steam**, or with the `FTL` script in the `data` folder. Starting `FTL.amd64` directly skips
Hyperspace.

The main menu should show `HS-1.23.1 x64` in the top right corner, the Archipelago logo at the top left and the
connection panel at the bottom left.

Next: [Playing](Playing.md).
