# Setup on Windows

**English** · [Français](Setup-Windows.fr.md) · [Deutsch](Setup-Windows.de.md) · [Español](Setup-Windows.es.md) ·
[Italiano](Setup-Windows.it.md) · [Português](Setup-Windows.pt.md)

> [!WARNING]
> **Close FTL before you start**, and keep it closed until the last step. Windows locks the game files while FTL
> runs, and the install fails without saying so.

> [!IMPORTANT]
> Pick **Hyperspace 1.23.1** in ftlman, not a newer one. The Archipelago library is made for 1.23.1 only.

## What to download

1. From the [FTL Archipelago release](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
   `ArchipelagoFTL.ftl` and `Hyperspace.dll`.
2. [ftlman](https://github.com/afishhh/ftlman/releases/latest): the Windows zip. Unzip it into a folder of its
   own, for example `Documents\ftlman`.

That is all: ftlman downloads Hyperspace by itself.

## 1. Protect your saves

In Steam, right click FTL, **Properties**, **General**, and turn off **Steam Cloud**. Then copy the folder
`Documents\My Games\FasterThanLight` somewhere safe. The mod uses a profile of its own, the copy is just in case.

## 2. Check the FTL folder in ftlman

Start `ftlman.exe` and click **Settings**:

![Settings button](../images/ftlman-1-settings-button.png)

**FTL data directory** must point to the FTL folder, the one with `FTLGame.exe`. ftlman usually finds it by
itself. If it is empty or wrong, find the folder from Steam (right click FTL, **Manage**, **Browse local files**)
and paste its path there. Close the settings window.

![FTL data directory](../images/ftlman-2-ftl-folder.png)

## 3. Add the mod

Put `ArchipelagoFTL.ftl` in the `mods` folder next to `ftlman.exe` (create the folder if it is not there).
Click **Scan** (1): the mod shows up in the list (2).

![Scan](../images/ftlman-3-scan.png)

## 4. Choose Hyperspace 1.23.1

Open the **Hyperspace** menu (1) and pick **1.23.1** (2). Not 1.23.2, not "None".

![Hyperspace 1.23.1](../images/ftlman-4-hyperspace.png)

## 5. Apply

Click the mod so that it turns blue (1), then click **Apply** (2). If ftlman offers to switch FTL to version
1.6.9, accept: it is the only Windows version Hyperspace runs on, and your original game is kept as
`FTLGame_orig.exe`. Wait until ftlman is done, then close it.

![Apply](../images/ftlman-5-apply.png)

## 6. Put in the Archipelago library

> [!WARNING]
> **Do this after Apply, every time you click Apply.** Apply puts the official `Hyperspace.dll` back, and with it
> the mod cannot connect to a server.

Open the FTL folder (from Steam: right click FTL, **Manage**, **Browse local files**). Copy the `Hyperspace.dll`
you downloaded from the FTL Archipelago release into it, and choose **Replace the file**.

## 7. Start the game

Start FTL from Steam. On the main menu you should see the Archipelago logo at the top left and a
**Connect to a multiworld** panel at the bottom left:

![Main menu after installing](../images/connect-panel.jpg)

If the panel is missing, or connecting never works, see the [FAQ](FAQ.md).

## Updating to a new version

Close FTL. Put the new `ArchipelagoFTL.ftl` in ftlman's `mods` folder, click **Apply**, then copy the new
`Hyperspace.dll` into the FTL folder again.

Next: [Playing](Playing.md).
