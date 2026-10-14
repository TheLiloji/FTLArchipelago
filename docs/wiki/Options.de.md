# Optionen

[English](Options.md) · [Français](Options.fr.md) · **Deutsch** · [Español](Options.es.md) ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

Deine Optionen stehen in einer kleinen Textdatei, der **YAML**. Du erstellst sie einmal vor dem Spiel und
schickst sie der Person, die die Multiworld erzeugt.

**Du spielst mit Multiverse?** Siehe [Multiverse](Multiverse.de.md): Installation und was sich in deiner YAML ändert.

## Bevor du anfängst

Du brauchst **Archipelago 0.6.7**, mit der `ftl.apworld` von der
[Release-Seite](https://github.com/TheLiloji/FTLArchipelago/releases/latest) im Ordner `custom_worlds`.
Ohne sie fehlt FTL in der Liste. Die Installationsanleitungen ([Windows](Setup-Windows.de.md),
[Linux](Setup-Linux.de.md)) erklären jeden Schritt.

## Ein paar Begriffe

| Begriff | Bedeutung |
|---|---|
| Check | etwas, das du im Spiel tust und das einen Gegenstand verschickt: einen Sektor erreichen, gewinnen, eine Errungenschaft... |
| Gegenstand (Item) | was ein Check dir oder einem anderen Spieler gibt: ein Schiff, ein System, eine Waffe, Schrott... |
| Seed | das erzeugte Spiel, für alle in der Multiworld gleich |
| Slot | dein Platz in der Multiworld, benannt durch die Zeile `name:` deiner YAML |
| Layout | eine Version eines Schiffs: Kestrel A, Kestrel B und Kestrel C sind drei Layouts |
| progressive | ein Gegenstand, der ein System bei jedem Erhalt um eine Stufe erhöht |
| Archive | Gegenstände, die du zusätzlich zu deinen Siegen zum Abschluss brauchst |
| Logik | was der Generator annimmt, dass du hast, bevor er einen Check von dir verlangt |

## Am einfachsten: ein Preset nehmen

Presets sind fertige YAML-Dateien. Nimm das, das zu deiner Zeit passt:

| Preset | Zeit bis zum Ziel | Was es ist |
|---|---|---|
| `first_game` | etwa 3 Std. | **Dein erstes Archipelago-Spiel.** 1 Sieg, Leicht zählt, 3 Schiffe vom Typ A, 2 von 3 Archiven, keine Fallen. Erhaltene Verbesserungen und Systeme kommen von selbst an Bord |
| `short_game` | etwa 5 Std. | 2 Siege auf Normal oder Schwer, 4 Layouts, 4 von 5 Archiven, alle Stufen eines Systems auf einmal |
| `medium_game` | etwa 10 Std. | die Standardoptionen: 5 Siege auf Normal oder Schwer, 7 Layouts, 10 von 12 Archiven |
| `long_game` | 20 Std. oder mehr | 10 Siege, 14 Layouts, 16 von 20 Archiven, ein System einzubauen ist ein Check |

Sie liegen in `presets.zip` auf der [Release-Seite](https://github.com/TheLiloji/FTLArchipelago/releases/latest).
Oben in jeder Datei steht, wie viele Checks sie hat und wie lange sie ungefähr dauert.

1. Öffne die Datei in einem Texteditor.
2. Ersetze die Zeile `name:` durch deinen Namen. Nur Buchstaben ohne Umlaute oder Akzente, Ziffern,
   Leerzeichen, `-` und `_`, höchstens 16 Zeichen: Das Verbindungsfenster im Spiel kann nichts anderes tippen.
3. Schick die Datei der Person, die die Multiworld erzeugt.

Die Zeiten gelten für jemanden, der in wenigen Runs gewinnt. Wenn FTL neu für dich ist, rechne mit mehr.

## Eine eigene YAML erstellen

Öffne **ArchipelagoOptionsCreator** (im Archipelago-Ordner), wähle **FTL: Faster Than Light**, gib deinen
Namen ein und exportiere die YAML. Jede Option hat eine kurze Beschreibung (auf Englisch): Fahr mit der Maus
darüber. Die Standardwerte sind das Preset `medium_game`.

Drei häufige Fallen:

- **Siege auf Leicht.** Standardmäßig zählen nur Siege auf Normal und Schwer für dein Ziel. Wenn du auf Leicht
  spielst, stell **Victory Difficulty** auf `any` (in der YAML geht auch `easy`).
- **Weniger Checks heißt nicht kürzeres Spiel.** Wenn du Sektoren oder Errungenschaften abschaltest,
  verschwinden ihre Gegenstände nicht: Sie wandern in den Archipelago-Laden, wo du sie mit Schrott kaufst. Um
  ein Spiel zu verkürzen, senk lieber **Victories Required** und **Layouts in the Seed**.
- **Death Link.** Wenn deine Gruppe damit spielt, schalte es ein. Mit **Death Link Trigger** auf `both`
  (Standard) tötet jedes verlorene Crewmitglied auch die anderen. In einer großen Multiworld oder beim ersten
  Spiel nimm `ship_destroyed`: Dann zählt nur ein verlorener Run.

## Was die Optionen tun

Der Options Creator zeigt sie in Gruppen:

- **Goal**: wie viele Siege, auf welchem Schwierigkeitsgrad, und wie viele Archive. Archive können überall in
  der Multiworld liegen, auch in deiner eigenen Welt.
- **Game Size**: welche Layouts im Spiel sind und wie viele, und was Checks verschickt: Sektoren, Systeme,
  Errungenschaften, Crew, gewonnene Kämpfe, der Archipelago-Laden.
- **Playing with Others**: Death Link, Energy Link (ein geteilter Treibstoffvorrat), Trap Link und wie viele
  Fallen.
- **Advanced** (anfangs zugeklappt): Du musst hier nichts ändern. Dein erstes Schiff, die Head-Start-Items, die
  Sprache des Mods (sie folgt FTL von selbst), welche Sektoren zählen, wie Typ B und C freigeschaltet werden,
  was in Läden gesperrt ist, die Optionen unten und wie streng die Logik ist.

In den Namen tauchen zwei Arten von Läden auf. **Shop Weapons**, **Shop Drones**, **Shop Augments** und **Shop
Unlock Mode** betreffen die Läden von FTL. Die Optionen **Archipelago Shop** betreffen den Archipelago-Laden:
die Pakete an den ARCHIPELAGO-Baken, die Gegenstände anderer Spieler enthalten.

## Neu in 0.5

| Option | Was sie tut |
|---|---|
| **Free Upgrades** | Erhaltene Systemstufen werden kostenlos eingebaut, sofort und zu Beginn jedes Runs. Nur mit Progressive System Upgrades (standardmäßig an) |
| **System Install** | Systeme, deren Bauplan du erhalten hast, kommen kostenlos an Bord: `run_start` zu Beginn jedes Runs, `immediately` auch sobald der Bauplan eintrifft. Das Schiff braucht einen Raum dafür |
| **Run Start Scrap** | Jeder neue Run beginnt mit diesem Prozentsatz des gesamten erhaltenen Schrotts. 10 bis 25 ist ein guter Bereich |
| **Combat Checks per Ship** | Mit jedem Schiff verschicken die ersten gewonnenen Kämpfe eines Runs Checks. Diese Kämpfe bringen weniger Schrott (**Combat Check Scrap**) |
| **Victory Collects the Layout** | Was ein Sieg zusätzlich verschickt: `sectors` (Standard) die noch offenen Sektor-Checks des Layouts, `everything` auch die Errungenschaften, System- und Kampf-Checks seines Schiffs |
| **Sector Logic** | Neuer Wert `power`: Vor tiefen Sektoren und dem Flaggschiff erwartet die Logik Schildschichten, Waffen und Antrieb auf dem Schiff, das den Check macht |

## Expertenoptionen

Ein paar Optionen gibt es nur in der YAML-Datei, weil fast niemand sie braucht: genau festlegen, welche Schiffe
gewinnen müssen (`goal: victory_selection` mit `victory_layouts`), die Mindestmenge an Füllgegenständen, und
die fünf Optionen `*_blueprint_logic`, die die Logik für Schilde, Sensoren, Krankenstation, Antrieb und Waffen
feinjustieren. Die vollständige Liste mit allen Details steht auf der
[Spielseite](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
(auf Englisch).
