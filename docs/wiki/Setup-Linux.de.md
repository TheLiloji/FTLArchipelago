# Installation unter Linux

[English](Setup-Linux.md) · [Français](Setup-Linux.fr.md) · **Deutsch** · [Español](Setup-Linux.es.md) ·
[Italiano](Setup-Linux.it.md) · [Português](Setup-Linux.pt.md)

*Diese Seite wurde mit KI übersetzt und kann Fehler enthalten. Im Zweifel gilt die englische Seite.*

Für die native Linux-Version von FTL auf Steam (1.6.13). Starte FTL dafür nicht über Proton: Die Linux-Bibliothek
unten lädt dort nicht. Dauert etwa zehn Minuten.

## Was du herunterladen musst

Lege alles in denselben Ordner, zum Beispiel `Downloads`.

- Aus dem [FTL-Archipelago-Release](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
  `ArchipelagoFTL.ftl` und `Hyperspace.1.6.13.amd64.so`.
- Aus dem [ftlman-Release](https://github.com/afishhh/ftlman/releases/latest):
  `ftlman-x86_64-unknown-linux-gnu.tar.gz`.
- Aus dem [Release von Hyperspace 1.23.1](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1):
  `FTL.Hyperspace.1.23.1-Linux.zip`.

## 1. Spielstände schützen

Schalte **Steam Cloud** für FTL aus (Rechtsklick, Eigenschaften, Allgemein) und kopiere deinen Spielstand-Ordner:

```sh
cp -r ~/.local/share/FasterThanLight ~/.local/share/FasterThanLight.backup
```

## 2. Entpacken

Öffne ein Terminal im Ordner mit den Downloads:

```sh
tar xzf ftlman-x86_64-unknown-linux-gnu.tar.gz
unzip FTL.Hyperspace.1.23.1-Linux.zip Hyperspace.ftl
cp Hyperspace.ftl ArchipelagoFTL.ftl ftlman/mods/
```

Jetzt liegt ftlman in `ftlman/ftlman`, und beide Mods sind in seinem Ordner `mods`.

## 3. Hyperspace und die Mod installieren

Im selben Terminal:

```sh
D=~/.steam/steam/steamapps/common/"FTL Faster Than Light"/data
ftlman/ftlman hyperspace-install 1.23.1 -d "$D"
ftlman/ftlman patch -d "$D" Hyperspace.ftl ArchipelagoFTL.ftl
```

`D` ist der Spielordner mit `FTL.amd64`. Liegt FTL in einer anderen Steam-Bibliothek, ändere diese erste Zeile.

Gib immer beide Mods an, Hyperspace zuerst. ftlman baut die Spieldaten jedes Mal neu auf, also würde nur
`ArchipelagoFTL.ftl` Hyperspace wieder entfernen.

## 4. Die Archipelago-Bibliothek einsetzen

Behalte die offizielle Bibliothek und setze die von Archipelago an ihre Stelle:

```sh
cp "$D/Hyperspace.1.6.13.amd64.so" "$D/Hyperspace.1.6.13.amd64.so.official"
cp Hyperspace.1.6.13.amd64.so "$D/"
```

## 5. Das Spiel starten

Starte FTL **über Steam** oder mit dem Skript `FTL` im Ordner `data`. Wer `FTL.amd64` direkt startet, lädt
Hyperspace nicht. Du solltest sehen:

![Hauptmenü nach der Installation](../images/connect-panel.jpg)

- `HS-1.23.1 x64` oben rechts,
- das Archipelago-Logo oben links,
- ein Feld **Connect to a multiworld** unten links.

Fehlt das Feld oder klappt die Verbindung nie, sieh in die [FAQ](FAQ.md) (auf Englisch).

## Auf eine neue Version aktualisieren

Lege die neue `ArchipelagoFTL.ftl` in `ftlman/mods/`, führe die `patch`-Zeile aus Schritt 3 erneut aus und dann
Schritt 4 mit der neuen `Hyperspace.1.6.13.amd64.so`.

Weiter: [Spielen](Playing.md) (auf Englisch).
