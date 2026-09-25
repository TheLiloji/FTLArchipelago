# Installation unter Windows

[English](Setup-Windows.md) · [Français](Setup-Windows.fr.md) · **Deutsch** · [Español](Setup-Windows.es.md) ·
[Italiano](Setup-Windows.it.md) · [Português](Setup-Windows.pt.md)

*Diese Seite wurde mit KI übersetzt und kann Fehler enthalten. Im Zweifel gilt die englische Seite.*

Dauert etwa zehn Minuten. Du brauchst FTL von Steam (oder GOG) mit den Inhalten der Advanced Edition, die in
jeder heute verkauften Version enthalten sind.

## Was du herunterladen musst

Lege alles in denselben Ordner, zum Beispiel `Downloads`.

- Aus dem [FTL-Archipelago-Release](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
  `ArchipelagoFTL.ftl` und `Hyperspace.dll`.
- Aus dem [ftlman-Release](https://github.com/afishhh/ftlman/releases/latest):
  `ftlman-x86_64-pc-windows-gnu.zip`.
- Aus dem [Release von Hyperspace 1.23.1](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1):
  `FTL.Hyperspace.1.23.1-Windows.zip`.

Entpacke beide Zip-Dateien. Du bekommst einen Ordner `ftlman` mit `ftlman.exe` und einem leeren Ordner `mods`
darin, und `Hyperspace.ftl` aus dem Hyperspace-Zip.

## 1. Spielstände schützen

- Rechtsklick auf FTL in Steam, **Eigenschaften**, **Allgemein**, und **Steam Cloud** ausschalten. Sonst kann
  Steam beim Spielen einen alten Spielstand zurückspielen.
- Kopiere den Ordner `Documents\My Games\FasterThanLight` an einen sicheren Ort.

Die Mod nutzt ein eigenes Profil, dein normaler FTL-Fortschritt bleibt unberührt. Die Kopie ist nur zur
Sicherheit.

## 2. Hyperspace mit ftlman installieren

Starte `ftlman.exe`. Meist findet es das Spiel selbst; sonst zeig ihm den FTL-Ordner (den mit `FTLGame.exe`, zum
Beispiel `C:\Program Files (x86)\Steam\steamapps\common\FTL Faster Than Light`).

Installiere **Hyperspace 1.23.1** aus ftlman. Bei einer Steam-Version stellt ftlman FTL zuerst auf Version 1.6.9
um und behält das Original als `FTLGame_orig.exe`. Das ist normal: 1.6.9 ist die einzige Windows-Version, auf der
Hyperspace läuft.

## 3. Die Mod hinzufügen

Kopiere `Hyperspace.ftl` und `ArchipelagoFTL.ftl` in den Ordner `mods` im Ordner `ftlman`. Hake in ftlman beide
an, Hyperspace **über** ArchipelagoFTL, und klicke auf **Apply**. Schließe ftlman danach.

## 4. Die Archipelago-Bibliothek einsetzen

Im FTL-Ordner liegt jetzt eine `Hyperspace.dll`. Benenne sie in `Hyperspace.dll.official` um (um sie zu
behalten) und kopiere dann die `Hyperspace.dll` aus dem FTL-Archipelago-Release an ihre Stelle.

FTL muss dabei geschlossen sein: Windows sperrt die Datei, solange das Spiel läuft.

Wenn du in ftlman später noch einmal auf Apply klickst, kopiere danach die Archipelago-`Hyperspace.dll` erneut.

## 5. Das Spiel starten

Starte FTL über Steam. Du solltest sehen:

![Hauptmenü nach der Installation](../images/connect-panel.jpg)

- `HS-1.23.1` oben rechts,
- das Archipelago-Logo oben links,
- ein Feld **Connect to a multiworld** unten links.

Fehlt das Feld oder klappt die Verbindung nie, sieh in die [FAQ](FAQ.md) (auf Englisch).

## Auf eine neue Version aktualisieren

Lege die neue `ArchipelagoFTL.ftl` in den Ordner `mods` von ftlman, klicke wieder auf **Apply** und kopiere dann
die neue `Hyperspace.dll` über die im FTL-Ordner.

Weiter: [Spielen](Playing.md) (auf Englisch).
