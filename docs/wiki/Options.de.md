# Optionen

[English](Options.md) · [Français](Options.fr.md) · **Deutsch** · [Español](Options.es.md) ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

*Diese Seite wurde mit KI übersetzt und kann Fehler enthalten. Im Zweifel gilt die englische Seite.*

## Am einfachsten: die Standardwerte behalten

Die Standardoptionen sind die empfohlenen. Du musst nur deinen Namen ändern:

1. Öffne **ArchipelagoOptionsCreator** (im Archipelago-Ordner) oder die Optionsseite der Website, die den Raum
   hostet.
2. Wähle **FTL: Faster Than Light**, gib deinen Namen ein und exportiere die YAML-Datei.

Mit den Standardwerten gewinnst du, wenn du das Flaggschiff **5 Mal mit 5 verschiedenen Schiffen auf Normal
oder Schwer** besiegst und **10 der 12 Archive** sammelst, die in den Welten der anderen Spieler versteckt sind.
Das ist ein Spiel für mehrere Abende, etwa 10 Stunden bis zum Ziel.

Wenn deine Gruppe mit **Death Link** spielt, schalte es ein. Standardmäßig zählt auch der Verlust eines
Crewmitglieds als Tod, nicht nur ein verlorener Lauf.

## Presets

Lieber kürzer oder länger? Wähle ein Preset, indem du zwei Fragen beantwortest: Wie viel Zeit hast du, und
kennst du FTL gut?

| | Neu bei FTL | Du kennst FTL gut |
|---|---|---|
| **FTL neben anderen Spielen**, kurze Sitzungen | `A1_multi_game_beginner` | `A2_multi_game_veteran` |
| **Zwei Abende** | `C1_two_evenings_beginner` | `C2_two_evenings_veteran` |
| **Nur FTL**, ein langes Spiel | `B1_solo_beginner` | `B2_solo_veteran` |

Sie liegen in `presets.zip` auf der [Release-Seite](https://github.com/TheLiloji/FTLArchipelago/releases/latest)
und im Menü **Preset** der Optionsseite der Website. Oben in jeder Datei steht, wie viele Checks sie hat und wie
lange sie ungefähr dauert. Ändere die Zeile `name:` und fertig.

## Was die Optionen tun

Der Options Creator zeigt sie in Gruppen:

- **Goal**: wie viele Siege, auf welcher Schwierigkeit, und wie viele Archive.
- **Game Size**: welche Schiffsvarianten im Spiel sind und was Checks sendet (Sektoren, Systeme, Erfolge,
  Crew, der Archipelago-Laden). Weniger Checks heißt ein kürzeres Spiel.
- **Playing with Others**: Death Link, Energy Link (ein gemeinsamer Treibstoffvorrat), Trap Link und wie viele
  Fallen.
- **Advanced** (zuerst geschlossen): dein erstes Schiff, die Head-Start-Gegenstände, die Sprache des Mods (er
  folgt FTL von selbst), welche Sektoren zählen, wie Typ B und C freigeschaltet werden, was in Läden gesperrt ist
  und wie streng die Logik ist. Das musst du nicht anfassen.

Jede Option hat eine kurze Beschreibung: fahre im Options Creator mit der Maus darüber. Die Beschreibungen sind
auf Englisch, wie überall in Archipelago.

## Expertenoptionen

Einige Optionen gibt es nur in der YAML-Datei, weil fast niemand sie braucht: genau festlegen, welche Schiffe
gewinnen müssen (`goal: victory_selection` mit `victory_layouts`), die Mindestmenge an Füllgegenständen und die
fünf Optionen `*_blueprint_logic`, die die Logik für Schilde, Sensoren, Krankenstation, Triebwerke und Waffen
fein einstellen. Die vollständige Liste mit allen Details steht auf der Spielseite (auf Englisch):
`apworld/ftl/docs/en_FTL Faster Than Light.md`.
