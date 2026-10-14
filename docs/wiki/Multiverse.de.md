# Mit Multiverse spielen

[English](Multiverse.md) · [Français](Multiverse.fr.md) · **Deutsch** · [Español](Multiverse.es.md) ·
[Italiano](Multiverse.it.md) · [Português](Multiverse.pt.md)

Der Mod läuft auch mit **FTL: Multiverse 5.5.1**. Dessen Schiffe ersetzen die des Grundspiels, und auch seine
Sektoren bekommen ARCHIPELAGO-Baken. Es ist dieselbe `ftl.apworld`: Ein Multiverse-Spieler und ein
Grundspiel-Spieler können in derselben Multiworld sein.

## Installation

Folge der Installationsanleitung ([Windows](Setup-Windows.de.md), [Linux](Setup-Linux.de.md)) mit einer
Änderung: Hake in ftlman die Mods in dieser Reihenfolge an und klicke dann auf **Apply**.

1. Multiverse **Assets** (5.5)
2. Multiverse **Data** (5.5.1)
3. **ArchipelagoFTL**

Nimm die Multiverse-Version des Mods: das Release, dessen Name auf `-mv` endet, etwa `v0.5.0-mv.1`. Hyperspace
bleibt bei 1.23.1, wie in der Anleitung.

Multiverse und das Grundspiel teilen sich das Profil von FTL. Wenn du beides oder mehrere Seeds spielst, sichere
den Ordner `FasterThanLight` vor dem Wechsel (siehe „Spielstände sichern" in der Anleitung).

## Deine YAML

Schalte **Multiverse** ein. Im Options Creator ist es die erste Gruppe.

- Du startest immer mit dem **MV Kestrel Cruiser**: Starting Ship wird ignoriert.
- **Layouts in the Seed** zieht aus den 55 Schiffen von Multiverse und ihren Layouts. Alle anderen Schiffe kommen
  wie im Grundspiel aus Archipelago-Gegenständen.
- **Victory Layouts** nimmt die Namen von Multiverse, etwa „Union Cruiser B". Ein Schiff mit demselben Namen wie
  ein Schiff des Grundspiels wird mit „(MV)" geschrieben, etwa „Kestrel Cruiser (MV)".
- **Shop Weapons** und **Shop Drones** gehen bis 37 und 14: So viele der 120 Waffen und 25 Drohnen von
  Multiverse werden zufällig gezogen und von Archipelago verteilt, die anderen bleiben ganz normal in den Läden.
  **Shop Augments** kann alle 22 Erweiterungen von Multiverse nehmen.
- **Multiverse Achievement Checks** fügt 26 Errungenschaften von Multiverse (Accomplishments und Special Events)
  als Checks hinzu. Sie enthalten nur Füllgegenstände oder Fallen, weil manche lang oder selten sind.

Multiverse-Runs dauern länger als im Grundspiel: Rechne mit mehr Zeit, als die Presets angeben.

## Was sich im Spiel ändert

- Die Enden von Multiverse zählen als Siege, nicht nur das Flaggschiff.
- Multiverse-Varianten einer Rasse (Zoltan Monk, Separatist Engi, Lanius Welder...) zählen für den Check dieser
  Rasse, ebenso einzigartige Crewmitglieder dieser Rasse, wie Turzil der Engi. Multiverse-eigene Rassen zählen
  nicht.
- Das Ziel, das Dashboard (TAB) und der Archipelago-Laden funktionieren gleich.
