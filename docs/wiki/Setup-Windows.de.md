# Installation unter Windows

[English](Setup-Windows.md) · [Français](Setup-Windows.fr.md) · **Deutsch** · [Español](Setup-Windows.es.md) ·
[Italiano](Setup-Windows.it.md) · [Português](Setup-Windows.pt.md)

*Diese Seite wurde mit KI übersetzt und kann Fehler enthalten. Im Zweifel gilt die englische Seite.*

> [!WARNING]
> **Schließe FTL, bevor du anfängst**, und lass es bis zum letzten Schritt geschlossen. Windows sperrt die
> Spieldateien, solange FTL läuft, und die Installation schlägt fehl, ohne etwas zu sagen.

> [!IMPORTANT]
> Wähle in ftlman **Hyperspace 1.23.1**, keine neuere Version. Die Archipelago-Bibliothek ist nur für 1.23.1
> gemacht.

## Was du herunterladen musst

1. Aus dem [FTL-Archipelago-Release](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
   `ArchipelagoFTL.ftl` und `Hyperspace.dll`.
2. [ftlman](https://github.com/afishhh/ftlman/releases/latest): das Windows-Zip. Entpacke es in einen eigenen
   Ordner, zum Beispiel `Documents\ftlman`.

Das ist alles: ftlman lädt Hyperspace selbst herunter.

## 1. Spielstände sichern

Rechtsklick auf FTL in Steam, **Eigenschaften**, **Allgemein**, und schalte **Steam Cloud** aus. Kopiere dann
den Ordner `Documents\My Games\FasterThanLight` an einen sicheren Ort. Der Mod nutzt ein eigenes Profil, die
Kopie ist nur zur Sicherheit.

## 2. Den FTL-Ordner in ftlman prüfen

Starte `ftlman.exe` und klicke auf **Settings**:

![Settings](../images/ftlman-1-settings-button.png)

**FTL data directory** muss auf den FTL-Ordner zeigen, den mit `FTLGame.exe`. Meist findet ftlman ihn selbst.
Ist das Feld leer oder falsch, öffne den Ordner über Steam (Rechtsklick auf FTL, **Verwalten**, **Lokale Dateien
durchsuchen**) und füge seinen Pfad hier ein. Schließe das Einstellungsfenster.

![FTL data directory](../images/ftlman-2-ftl-folder.png)

## 3. Den Mod hinzufügen

Lege `ArchipelagoFTL.ftl` in den Ordner `mods` neben `ftlman.exe` (lege ihn an, falls er fehlt). Klicke auf
**Scan** (1): der Mod erscheint in der Liste (2).

![Scan](../images/ftlman-3-scan.png)

## 4. Hyperspace 1.23.1 wählen

Öffne das Menü **Hyperspace** (1) und wähle **1.23.1** (2). Nicht 1.23.2, nicht „None“.

![Hyperspace 1.23.1](../images/ftlman-4-hyperspace.png)

## 5. Anwenden

Klicke auf den Mod, bis er blau wird (1), dann auf **Apply** (2). Bietet ftlman an, FTL auf Version 1.6.9 zu
stellen, nimm an: es ist die einzige Windows-Version, auf der Hyperspace läuft, und dein Originalspiel bleibt als
`FTLGame_orig.exe` erhalten. Warte, bis ftlman fertig ist, und schließe es.

![Apply](../images/ftlman-5-apply.png)

## 6. Die Archipelago-Bibliothek einsetzen

> [!WARNING]
> **Nach Apply erledigen, jedes Mal, wenn du Apply klickst.** Apply setzt die offizielle `Hyperspace.dll` zurück,
> und damit kann der Mod keine Verbindung zu einem Server aufbauen.

Öffne den FTL-Ordner (in Steam: Rechtsklick auf FTL, **Verwalten**, **Lokale Dateien durchsuchen**). Kopiere die
heruntergeladene `Hyperspace.dll` aus dem FTL-Archipelago-Release hinein und wähle **Datei ersetzen**.

## 7. Das Spiel starten

Starte FTL über Steam. Im Hauptmenü solltest du oben links das Archipelago-Logo sehen und unten links ein Feld
**Mit einem Multiworld verbinden**:

![Main menu](../images/connect-panel.jpg)

Fehlt das Feld oder klappt die Verbindung nie, sieh in die [FAQ](FAQ.md) (Englisch).

## Auf eine neue Version aktualisieren

Schließe FTL. Lege die neue `ArchipelagoFTL.ftl` in den Ordner `mods` von ftlman, klicke auf **Apply** und
kopiere danach die neue `Hyperspace.dll` wieder in den FTL-Ordner.

Weiter: [Playing](Playing.md) (Englisch).
