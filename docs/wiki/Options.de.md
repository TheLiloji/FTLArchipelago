# Optionen

[English](Options.md) · [Français](Options.fr.md) · **Deutsch** · [Español](Options.es.md) ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

Deine Optionen stehen in einer kleinen Textdatei, der **YAML**. Du erstellst sie einmal vor dem Spiel und
schickst sie der Person, die die Multiworld erzeugt. Diese Seite erklärt jede Option einzeln. Du musst nicht
alles lesen: Nimm ein Preset und komm hierher zurück, wenn du etwas ändern willst.

## Bevor du anfängst

Du brauchst **Archipelago 0.6.7**, mit der `ftl.apworld` von der
[Release-Seite](https://github.com/TheLiloji/FTLArchipelago/releases/latest) im Ordner `custom_worlds`.
Ohne sie steht FTL nicht in der Liste. Die Installationsanleitungen ([Windows](Setup-Windows.de.md),
[Linux](Setup-Linux.de.md)) erklären jeden Schritt.

## Ein paar Begriffe

| Begriff | Bedeutung |
|---|---|
| Check | etwas, das du im Spiel tust und das einen Gegenstand verschickt: einen Sektor erreichen, gewinnen, eine Errungenschaft... |
| Gegenstand (Item) | was ein Check dir oder einem anderen Spieler gibt: ein Schiff, ein System, eine Waffe, Schrott... |
| Seed | das erzeugte Spiel, für alle in der Multiworld gleich |
| Slot | dein Platz in der Multiworld, benannt durch die Zeile `name:` deiner YAML |
| Layout | eine Version eines Schiffs: Kestrel A, Kestrel B und Kestrel C sind drei Layouts. Es gibt 28, auf 10 Schiffen |
| progressive | ein Gegenstand, der ein System bei jedem Erhalt um eine Stufe erhöht |
| Bauplan (Blueprint) | der Gegenstand, mit dem du ein System überhaupt haben darfst (Tarnung, Drohnensteuerung...) |
| Archive | Gegenstände, die du zusätzlich zu deinen Siegen zum Abschluss brauchst |
| Füller (Filler) | kleine Gegenstände: Schrott, Treibstoff, Raketen, Drohnenteile |
| Falle (Trap) | ein schlechter Gegenstand: ein Feuer, ein Hüllenbruch, die Rebellenflotte rückt vor... |
| Logik | was der Generator annimmt, dass du hast, bevor er einen Check von dir verlangt |
| AP STORE | der Archipelago-Laden, eine Bake pro Sektor, die die Gegenstände der Multiworld verkauft |

## Am einfachsten: ein Preset nehmen

Presets sind fertige YAML-Dateien. Nimm das, das zu deiner Zeit passt:

| Preset | Zeit bis zum Ziel | Was es ist |
|---|---|---|
| `first_game` | etwa 3 Std. | **Dein erstes Archipelago-Spiel.** 1 Sieg, Leicht zählt, 3 Schiffe vom Typ A, 2 von 3 Archiven, keine Fallen. Erhaltene Verbesserungen und Systeme kommen von selbst an Bord |
| `short_game` | etwa 5 Std. | 2 Siege auf Normal oder Schwer, 4 Layouts, 4 von 5 Archiven, alle Stufen eines Systems auf einmal |
| `medium_game` | etwa 10 Std. | die Standardoptionen: 5 Siege auf Normal oder Schwer, 7 Layouts, 10 von 12 Archiven |
| `long_game` | 20 Std. oder mehr | 10 Siege, 14 Layouts, 16 von 20 Archiven, ein System einzubauen ist ein Check |
| `solo_game` | etwa 7 Std. | **Allein in der Multiworld.** 3 Siege, 5 Layouts, Kämpfe pro Sektor, Sektorsprung und Sector Passes, mehr Event-Checks |

Sie liegen in `presets.zip` auf der [Release-Seite](https://github.com/TheLiloji/FTLArchipelago/releases/latest).
Oben in jeder Datei steht, wie viele Checks sie hat und wie lange sie ungefähr dauert.

1. Öffne die Datei in einem Texteditor.
2. Ersetze die Zeile `name:` durch deinen Namen. Nur Buchstaben ohne Umlaute oder Akzente, Ziffern,
   Leerzeichen, `-` und `_`, höchstens 16 Zeichen: Das Verbindungsfenster im Spiel kann nichts anderes tippen.
3. Schick die Datei der Person, die die Multiworld erzeugt (ihre Anleitung, auf Englisch: [Hosting a seed](Hosting-a-seed.md)).

Die Zeiten gelten für jemanden, der in wenigen Runs gewinnt. Wenn FTL neu für dich ist, rechne mit mehr.

## Eine eigene YAML erstellen

Öffne **ArchipelagoOptionsCreator** (im Archipelago-Ordner), wähle **FTL: Faster Than Light**, gib deinen
Namen ein und exportiere die YAML. Jede Option hat eine kurze Beschreibung (auf Englisch): Fahr mit der Maus
darüber. Die Standardwerte sind das Preset `medium_game`.

Du kannst ein Preset auch von Hand ändern. Jede Option ist eine Zeile: der YAML-Name, ein Doppelpunkt, der Wert.
Zum Beispiel:

```yaml
name: MeinName
game: "FTL: Faster Than Light"
requires:
  version: 0.6.7
"FTL: Faster Than Light":
  victories_required: 3
  start_ship: rock_cruiser
  trap_chance: 10
```

Behalte die zwei Leerzeichen vor jeder Option. Eine Option, die du nicht schreibst, nimmt ihren Standardwert.

## Drei häufige Fallen

- **Siege auf Leicht.** Standardmäßig zählen nur Siege auf Normal und Schwer für dein Ziel. Wenn du auf Leicht
  spielst, stell **Victory Difficulty** auf `any` (in der YAML geht auch `easy`).
- **Weniger Checks heißt nicht kürzeres Spiel.** Wenn du Sektoren oder Errungenschaften abschaltest,
  verschwinden ihre Gegenstände nicht: Sie wandern in den Archipelago-Laden, wo du sie mit Schrott kaufst. Um
  ein Spiel zu kürzen, senk lieber **Victories Required** und **Layouts in the Seed**.
- **Death Link.** Wenn deine Gruppe damit spielt, schalte es ein. Mit **Death Link Trigger** auf `both` (der
  Standard) tötet jedes verlorene Crewmitglied auch die anderen. In einer großen Multiworld oder für ein erstes
  Spiel nimm `ship_destroyed`: Nur ein verlorener Run zählt.

## Ideen für deine YAML

Ein kürzeres Spiel, ohne den Rest zu ändern:

```yaml
  victories_required: 2
  layout_count: 4
  sectorsanity_last_sector: 6
```

Schnell ein zweites Schiff, und erhaltene Gegenstände, die sofort zählen:

```yaml
  early_ship_keys: 3
  free_upgrades: true
  system_install: run_start
  run_start_scrap: 15
```

Mehr zu tun in jedem Run:

```yaml
  combat_checks: 1
  combat_checks_mode: per_sector
  reactor_checks: true
  systemsanity: first_install
```

Chaos mit Freunden:

```yaml
  trap_chance: 30
  trap_link: true
  death_link: true
```

Ein härterer Seed, für Leute, die FTL gut kennen:

```yaml
  victory_difficulty: hard
  sector_logic: none
  shop_unlock_mode: locked
  sector_locks: true
```

## Alle Optionen, Gruppe für Gruppe

Die Gruppen sind die des Options Creators. Jede Option zeigt ihren Namen im Options Creator (auf Englisch), ihren
Namen in der YAML, die möglichen Werte und ihren Standardwert. Die Gruppen mit *zugeklappt* sind im Options
Creator anfangs eingeklappt: Für ein erstes Spiel brauchst du sie nicht.

### Goal (das Ziel)

Was du tun musst, um fertig zu werden.

#### Victories Required

`victories_required` · 1 bis 28 · Standard `5`\
Wie oft du das Flaggschiff besiegen musst, jedes Mal mit einem **anderen** Layout (Kestrel A und Kestrel B zählen
als zwei). Diese Option entscheidet, wie lang dein Spiel ist: 1 oder 2 für ein erstes Spiel, 5 mit Freunden, 10
für ein langes Spiel.

#### Victory Difficulty

`victory_difficulty` · `any`, `normal`, `hard` · Standard `normal`\
Die niedrigste Schwierigkeit, auf der ein Sieg gespielt sein muss, damit er für dein Ziel zählt. `any` (oder
`easy`) zählt jeden Sieg, `normal` zählt Normal und Schwer, `hard` nur Schwer. Ein leichterer Sieg schickt
trotzdem seinen Check, er zählt nur nicht für das Ziel.

#### Flagship Sabotage

`flagship_sabotage` · 0 bis 5 · Standard `0`\
Die Multiworld schwächt das Flaggschiff. Jede Stufe fügt etwas hinzu, und das gilt für jede Phase des Kampfs:
1 ist Hülle -10 %, 2 dazu Schilde -1, 3 macht Hülle -20 %, 4 dazu Waffen -1, 5 macht Hülle -30 %. Eine Meldung
nennt die Stufe, wenn das Flaggschiff ankommt. Gut für eine Gruppe, die schneller fertig werden will.

#### Archives

`archives` · 0 bis 50 · Standard `12`\
Wie viele Archive in der Multiworld versteckt sind, in deiner Welt oder bei den anderen. Archive sind
Gegenstände, die du zusätzlich zu deinen Siegen brauchst. 0 spielt ohne.

#### Archives Required

`archives_required` · 0 bis 50 · Standard `10`\
Wie viele Archive du zum Abschluss brauchst. Halte den Wert etwas unter **Archives**, damit dich ein schlecht
platziertes Archiv nicht blockieren kann. Ist er höher als Archives, brauchst du jedes Archiv.

#### Victory Collects the Layout

`victory_collects_layout` · `off`, `sectors`, `everything` · Standard `sectors`\
Was ein Sieg zusätzlich schickt, unter den Checks dieses Layouts, die du noch nicht gemacht hast. `off`: nur den
Sieg. `sectors`: auch jeden Sektor-Check dieses Layouts. `everything`: auch die Errungenschaften seines Schiffs,
seine System-Checks und seine Kampf-Checks. Praktisch, wenn du mit einem Schiff gewinnst und nicht für Sektor 3
zu ihm zurückkehren willst.

### Ships (die Schiffe)

Welche Schiffe im Spiel sind und wie du sie bekommst.

#### Starting Ship

`start_ship` · eines der 10 Schiffe · Standard `kestrel_cruiser`\
Das Schiff, mit dem du anfängst, als Typ A. Seine Typen B und C findest du wie die der anderen. Die Werte sind
`kestrel_cruiser`, `engi_cruiser`, `federation_cruiser`, `zoltan_cruiser`, `mantis_cruiser`, `slug_cruiser`,
`rock_cruiser`, `stealth_cruiser`, `lanius_cruiser` und `crystal_cruiser` (oder einfach `rock`, `mantis`...).

#### Ship Layouts

`ship_layouts` · `type_a_only`, `up_to_type_b`, `all_layouts` · Standard `all_layouts`\
Welche Layouts im Spiel sein können: nur Typ A, Typ A und B, oder alle.

#### Layouts in the Seed

`layout_count` · 1 bis 28 · Standard `7`\
Wie viele Layouts du in diesem Seed insgesamt fliegen kannst. Dein Startschiff und die Kestrel A zählen mit,
also heißt 7 diese zwei plus 5 weitere, zufällig gezogen aus denen, die **Ship Layouts** erlaubt. Ein Typ B oder
C kommt nur mit dem Typ A seines Schiffs. Die weggelassenen Layouts haben keinen Schlüssel und keinen Check, und
der Hangar markiert sie mit **NOT IN SEED**. Der Wert wird auf Victories Required angehoben, wenn er niedriger ist.

#### Excluded Ships and Layouts

`excluded_layouts` · eine Liste · Standard leer\
Schiffe oder Layouts, die du nie im Seed haben willst. Nenn ein ganzes Schiff (`"Engi Cruiser"`) oder ein Layout
(`"Engi Cruiser B"` oder `"Engi B"`). Ein weggelassener Typ A nimmt sein ganzes Schiff mit. Dein Startschiff und
die Kestrel A können nicht weggelassen werden. Beispiel:
`excluded_layouts: ["Stealth Cruiser", "Lanius Cruiser C"]`.

#### Layout Unlocks

`layout_unlocks` · `items`, `vanilla`, `independent`, `progressive` · Standard `items`\
Wie Typ B und C verfügbar werden.
- `items`: Jedes Layout ist ein eigener Gegenstand, und du brauchst auch den Schlüssel des Schiffs, um es zu
  fliegen.
- `vanilla`: wie in FTL, über die Errungenschaften dieses Schiffs. Keine Layout-Gegenstände.
- `independent`: Jedes Layout ist ein eigener Gegenstand und braucht nichts weiter, nicht einmal den Schlüssel
  des Schiffs.
- `progressive`: keine Layout-Gegenstände. Der Schlüssel des Schiffs kommt einmal pro Layout: Die erste Kopie
  gibt Typ A, die nächsten Typ B, dann C.

#### Early Ship Keys

`early_ship_keys` · 0 bis 9 · Standard `1`\
Wie viele Schiffsschlüssel, zusätzlich zu deinem Startschiff und der Kestrel, in deine eigenen ersten Checks
gelegt werden. Ein zweites Schiff kommt früh statt Stunden später. Die Zahl der Schlüssel ändert sich nicht, nur
wo sie landen. 0 lässt sie überall landen.

#### Kestrel Needs Its Key

`kestrel_key` · `true` / `false` · Standard `false`\
Wenn du nicht mit der Kestrel anfängst, braucht die Kestrel A ihren Schlüssel wie jedes andere Schiff. FTL zeigt
sie trotzdem im Hangar, aber sie ist mit **NO KEY** markiert und START verweigert sie, bis der Schlüssel da ist.
Aus, gehört dir die Kestrel A immer.

### Checks

Was Checks schickt. Die meisten deiner Checks kommen aus den Sektoren.

#### Sectorsanity

`sectorsanity` · `disabled`, `milestones`, `full` · Standard `full`\
Einen Sektor mit einem Layout zu erreichen schickt einen Check. Jedes Layout hat seine eigenen: Die Rock A in
Sektor 4 ist nicht derselbe Check wie die Rock B in Sektor 4. `full`: jeder Sektor. `milestones`: nur die Sektoren
5 und 8. `disabled`: nie.

#### Sectorsanity First Sector

`sectorsanity_first_sector` · 1 bis 8 · Standard `2`\
Der erste Sektor, der einen Check schickt. Die Sektoren davor schicken nichts. Mit allen Layouts im Spiel sind
allein die Sektoren 1 und 2 schon 56 Checks, die du nur durch Abheben bekommst: Den Wert anzuheben ist der
einfachste Weg, einen großen Seed zu verkleinern.

#### Sectorsanity Last Sector

`sectorsanity_last_sector` · 1 bis 8 · Standard `8`\
Der letzte Sektor, der einen Check schickt. Ein Check in Sektor 8 kostet einen ganzen Run, ein Check in Sektor 4
kommt von selbst. 5 oder 6 behält dieselben Schiffe, schneidet aber das lange Ende des Seeds ab, den Teil, in dem
die anderen auf dich warten.

#### Systemsanity

`systemsanity` · `disabled`, `first_install`, `every_level` · Standard `disabled`\
Ein System einzubauen schickt einen Check. `first_install`: einmal pro System, 12 Checks (Antrieb, Sauerstoff,
Steuerung und Waffenkontrolle haben keinen, jedes Schiff startet damit). `every_level`: auch jede
Verbesserungsstufe, 64 Checks, ein viel längeres Spiel.

#### Systemsanity per Ship

`systemsanity_per_ship` · `true` / `false` · Standard `false`\
Mit Systemsanity hat jedes Schiff seine eigenen Einbau-Checks, wie „Kestrel Cruiser: Install Cloaking". Nie für
ein System, mit dem dieses Schiff startet.

#### Ship Achievement Checks

`ship_achievements` · `true` / `false` · Standard `true`\
Die drei Errungenschaften jedes Schiffs schicken einen Check, 30 insgesamt. FTL vergibt sie an das Schiff, nicht
an das Layout: Mit Typ A, B oder C verdient, ist es derselbe Check.

#### General Achievement Checks

`general_achievements` · `disabled`, `basic`, `most`, `all` · Standard `most`\
Welche der 21 allgemeinen Errungenschaften einen Check schicken. `basic`: die leichten, wie Sektor 8 erreichen.
`most`: auch die schwereren, die man im Lauf eines Runs verdient. `all`: alle, auch die sehr schweren.

#### Cross-Run Achievement Checks

`cross_run_achievements` · `true` / `false` · Standard `false`\
Die drei Errungenschaften, die man nicht in einem Run verdienen kann: „Rule Ten: Greed is Eternal" (10.000 Schrott
über alle Spiele), „Warlord" (1000 zerstörte Schiffe) und „Your Own Fleet" (alle Schiffe freigeschaltet). Für
einen kurzen Seed aus lassen: Die ersten zwei passieren vielleicht nie.

#### Crew Checks

`crew_checks` · `true` / `false` · Standard `true`\
Das erste Crewmitglied jeder Spezies, das sich dir anschließt, schickt einen Check: Mensch, Engi, Zoltan, Mantis,
Rock, Slug und Lanius. 7 Checks. Die Crew, mit der du einen Run startest, zählt nicht.

#### Archipelago Event Checks

`event_checks` · 0 bis 20 · Standard `5`\
Die Pakete der Relais- und Piraten-Events werden eigene Checks, „Archipelago Event 1", 2... bis zu dieser Zahl.
Sind alle erledigt, verkaufen die Events wieder Pakete aus dem Archipelago-Laden. 0: Die Events verkaufen nur die
Pakete des Ladens.

#### Reactor Checks

`reactor_checks` · `true` / `false` · Standard `false`\
Den Reaktor zu verbessern schickt Checks bei Leistung 10, 15, 20 und 25, in jedem Run. Die Logik erwartet sie
etwa in den Sektoren 2, 4, 6 und 7.

#### Combat Checks per Ship

`combat_checks` · 0 bis 10 · Standard `0`\
Gewonnene Kämpfe schicken Checks. Mit jedem Schiff schicken die ersten gewonnenen Kämpfe eines Runs (Gegner
zerstört oder seine Crew getötet) „Fight 1 won", „Fight 2 won"... bis zu dieser Zahl. 0 schaltet sie ab.

#### Combat Checks Mode

`combat_checks_mode` · `per_run`, `per_sector` · Standard `per_run`\
Wie Kämpfe gezählt werden. `per_run`: die ersten Kämpfe eines Runs, wie oben. `per_sector`: Die ersten Kämpfe
**jedes** Sektors schicken ihren eigenen Check („Sector 3 fight 1 won"), bis zu **Fights per Sector**, also kann
ein Run bis Sektor 8 überall Checks schicken. In diesem Modus muss Combat Checks per Ship nur über 0 liegen.

#### Fights per Sector

`fights_per_sector` · 1 bis 5 · Standard `2`\
Mit `per_sector`: wie viele Kämpfe in jedem Sektor einen Check schicken, für jedes Schiff.

#### Combat Check Scrap (%)

`combat_check_scrap` · 0 bis 100 · Standard `50`\
Ein Kampf, der einen Check schickt, gibt nur diesen Anteil seines Schrotts. Raketen, Treibstoff und Drohnenteile
bleiben. Kämpfe, die nichts schicken, behalten ihre volle Belohnung.

### Systems and Upgrades (Systeme und Verbesserungen) *(zugeklappt)*

Wie Systeme und ihre Stufen gesperrt und zurückgegeben werden.

#### System Blueprints

`system_blueprints` · `true` / `false` · Standard `true`\
System-Baupläne sind Gegenstände. Ohne den Bauplan eines Systems verkaufen Läden es nicht. Ein System, mit dem
dein Schiff startet, wird nie ausgebaut: Es bleibt auf Stufe 1, bis der Bauplan kommt. Aus, ist jedes System zu
kaufen.

#### Progressive System Upgrades

`progressive_systems` · `true` / `false` · Standard `true`\
Jeder „Progressive"-Gegenstand erhöht, wie weit du ein System verbessern darfst, bis zum Maximum von FTL. Du
zahlst weiter den Schrott, außer mit Free Upgrades. Standardmäßig zählt ein Gegenstand für alle Schiffe:
„Progressive Shields" erhöht die Schilde aller. Aus, verbessern sich Systeme wie in FTL.

#### Progressive Upgrades per Ship

`progressive_systems_per_ship` · `true` / `false` · Standard `false`\
Die Verbesserungen gehören je einem Schiff, wie „Kestrel Cruiser: Progressive Shields", und zählen nur an Bord
dieses Schiffs, egal welches Layout. Viel mehr Gegenstände, also ein größerer Archipelago-Laden.

#### Progressive Unlocks the System

`progressive_unlocks_system` · `true` / `false` · Standard `false`\
Der erste Progressive-Gegenstand eines Systems schaltet es auch frei, also hat dieses System keinen eigenen
Bauplan-Gegenstand. Weniger Gegenstände zum Warten: Systeme kommen früher.

#### Full System Upgrades

`full_system_upgrades` · `true` / `false` · Standard `false`\
Jeder Progressive-Gegenstand gibt alle Stufen seines Systems auf einmal. Weniger Gegenstände, ein gröberer
Fortschritt.

#### Free Upgrades

`free_upgrades` · `true` / `false` · Standard `false`\
Erhaltene Systemstufen werden kostenlos eingebaut: sofort, wenn du in einem Run bist, und wieder am Anfang jedes
Runs. Aus, darfst du eine erhaltene Stufe nur kaufen. Braucht Progressive System Upgrades.

#### System Install

`system_install` · `store`, `run_start`, `immediately` · Standard `store`\
Wann ein System, dessen Bauplan du erhalten hast, kostenlos an Bord kommt, wenn das Schiff einen Raum dafür hat.
`store`: nie, du kaufst es wie in FTL. `run_start`: am Anfang jedes Runs, über das Startmenü des Runs.
`immediately`: auch sobald der Bauplan während eines Runs ankommt.

### Weapons, Drones, Augments, Crew (Waffen, Drohnen, Erweiterungen, Crew) *(zugeklappt)*

Was in FTLs eigenen Läden gesperrt ist, und die Crew als Gegenstände.

#### Shop Weapons

`shop_weapons` · 0 bis 37 · Standard `37`\
Wie viele der 37 Waffen von FTL zu Gegenständen werden. Die anderen bleiben normale Ladenware. 0 lässt die
Waffen in Ruhe.

#### Shop Drones

`shop_drones` · 0 bis 14 · Standard `14`\
Dasselbe für die 14 Drohnen. Drohnen brauchen die Drohnensteuerung, um etwas zu nützen.

#### Shop Augments

`shop_augments` · 0 bis 23 · Standard `23`\
Dasselbe für die 23 Erweiterungen.

#### Weapon Bundle Size

`weapon_bundle_size` · 1 bis 5 · Standard `3`\
Wie viele Waffen jedes Waffenbündel enthält. Ein Bündel schaltet alle auf einmal frei. 1 heißt keine Bündel:
Jede Waffe ist ein eigener Gegenstand. Größere Bündel heißen weniger Gegenstände, also ein kleinerer
Archipelago-Laden.

#### Drone Bundle Size

`drone_bundle_size` · 1 bis 5 · Standard `2`\
Dasselbe für Drohnen.

#### Augment Bundle Size

`augment_bundle_size` · 1 bis 5 · Standard `3`\
Dasselbe für Erweiterungen.

#### Shop Unlock Mode

`shop_unlock_mode` · `rarity_boost`, `locked` · Standard `rarity_boost`\
Was das Erhalten einer Waffe, Drohne oder Erweiterung an FTLs Läden ändert. `rarity_boost`: Sie war schon zu
kaufen und taucht jetzt viel öfter auf. `locked`: Sie ist nirgends zu kaufen, bis du sie erhältst. In beiden
Fällen gilt das für jeden künftigen Run.

#### Shop Item Delivery

`shop_item_delivery` · `true` / `false` · Standard `true`\
Du bekommst auch einmal sofort ein Exemplar: an Bord, wenn ein Platz frei ist, sonst in den Frachtraum. Aus,
ändert der Gegenstand nur, was Läden verkaufen.

#### Crew Members

`crew_members` · `true` / `false` · Standard `true`\
Crewmitglieder als Gegenstände, eines pro Spezies, bis zu drei Kopien. Erste Kopie: Eines schließt sich deinem
Run an. Zweite: Die Spezies kommt ins Startmenü des Runs. Dritte: Dieses Menü bietet einen Experten mit einer
gemeisterten Fähigkeit. Lanius und Crystal hören bei zwei auf.

### Archipelago Shop (der Archipelago-Laden) *(zugeklappt)*

Die AP-STORE-Baken, eine pro Sektor, die die Gegenstände der Multiworld gegen Schrott verkaufen.

#### Archipelago Shop Checks (minimum)

`shop_checks` · 0 bis 100 · Standard `20`\
Die kleinste Zahl an Paketen im Laden, für den ganzen Seed. Erzeugen deine Optionen mehr Gegenstände als Checks,
kommen von selbst Pakete hinzu (bis zu 400), damit jeder Gegenstand einen Platz hat. Je größer der Laden, desto
mehr Pakete zeigt jede Bake: 3, 6, 9 oder 12.

#### Archipelago Shop by Sector

`shop_by_sector` · `true` / `false` · Standard `false`\
Jedes Paket gehört zu einem Sektor, 1 bis 7, und wird nur im AP STORE dieses Sektors verkauft. Tiefere Pakete
kosten mehr, und die Logik erwartet, dass du diesen Sektor zuerst erreichst.

#### Archipelago Shop per Ship

`shop_per_ship` · `off`, `per_class`, `per_layout` · Standard `off`\
Jedes Paket gehört zu einem Schiff (`per_class`) oder einem Layout (`per_layout`) und wird nur verkauft, während
du es fliegst. Es kommen keine Pakete hinzu, sie werden aufgeteilt. Ein Paket, das du nicht gekauft hast, kommt
später wieder.

#### Archipelago Shop Hints

`shop_hints` · `off`, `seen` · Standard `seen`\
`seen`: Die Pakete, die du im Laden siehst, werden zu Hinweisen, damit ihre Besitzer wissen, wo ihr Gegenstand
wartet. `off`: Der Laden bleibt dein Geheimnis.

#### Archipelago Shop Deal Scrap (%)

`shop_deal_scrap` · 0 bis 200 · Standard `100`\
Wie viel Schrott die Pakte und Blutpakte des Ladens zahlen, in Prozent. 0 schaltet sie ab.

### Runs *(zugeklappt)*

Was sich innerhalb eines Runs ändert.

#### Head Starts

`head_starts` · `true` / `false` · Standard `true`\
Head-Start-Gegenstände geben am Anfang jedes künftigen Runs eine kostenlose Systemstufe oder einen Reaktorbalken.
Sie nehmen nur Checks, die übrig sind, wenn alle anderen Gegenstände ihren Platz haben, also kommen mit den
Standardoptionen wenige oder keine.

#### Run Start Scrap (%)

`run_start_scrap` · 0 bis 100 · Standard `0`\
Jeder neue Run startet mit diesem Anteil allen Schrotts, den du als Gegenstände erhalten hast. Schrott-Gegenstände
geben ihren Schrott trotzdem einmal bei Ankunft. 10 bis 25 ist ein guter Bereich.

#### Sector Skip

`sector_skip` · `true` / `false` · Standard `false`\
Ein Layout, das den nächsten Sektor schon erreicht hat, darf die Sektoren 1 bis 4 überspringen: Die erste
Bake eines solchen Sektors ist ein Ausgang. Spring sofort für 60 Schrott und eine Wahl mehr im Startmenü
des Runs, oder erkunde wie gewohnt. Die Checks des übersprungenen Sektors warten auf einen anderen Run.

#### Sector Locks

`sector_locks` · `true` / `false` · Standard `false`\
Jedes Layout braucht Sector Passes, um tiefer zu kommen: den ersten, um Sektor 4 zu verlassen, den zweiten für
Sektor 7. Ohne sie bleibt der Ausgang zu, und das Spiel sagt warum. Zwei Gegenstände pro Layout.

#### Event Beacons

`event_beacons` · `marked`, `important`, `hidden` · Standard `important`\
Welche Archipelago-Event-Baken auf der Karte ARCHIPELAGO zeigen. Der AP STORE tut es immer. `marked`: alle
Events. `important`: nur das Relais und die Piraten, die ein Paket tragen. `hidden`: keins.

#### Sector Logic

`sector_logic` · `none`, `standard`, `strict`, `power` · Standard `standard`\
Was der Generator von deinem Schiff erwartet, bevor er dich tief schickt. Es ändert nie, was das Spiel dir
erlaubt.
- `none`: nichts. Es kann sein, dass du das Flaggschiff mit sehr wenig erreichen sollst. Für erfahrene Spieler
  (`relaxed`, der alte Name, geht weiter).
- `standard`: 2 Baupläne für Sektor 4, 4 für Sektor 6, 5 für das Flaggschiff.
- `strict`: 3 Baupläne für Sektor 3, 6 für Sektor 5, 9 für Sektor 7, 11 für das Flaggschiff.
- `power`: schaut auf das Schiff, das den Check macht. Sektor 5 braucht 2 Schildschichten, Sektor 8 dazu
  Waffenkontrolle 5, das Flaggschiff 3 Schichten, Waffenkontrolle 6 und Antrieb 4.

#### Mod Language

`mod_language` · `game`, `english`, `french`, `spanish`, `german`, `italian`, `portuguese` · Standard `game`\
Die Sprache der Menüs und Meldungen des Mods. `game` folgt FTL von selbst. Namen von Gegenständen und Orten
bleiben immer auf Englisch, weil alle Spieler und Tracker sie teilen.

### Playing with Others (mit anderen spielen)

Die Verbindungen mit den anderen Spielern. Standardmäßig alle aus.

#### Death Link

`death_link` · `true` / `false` · Standard `false`\
Wenn du stirbst, sterben die anderen, die mit Death Link spielen, auch, und umgekehrt. Ein empfangener Tod
zerstört nie dein Schiff und tötet nie dein letztes Crewmitglied.

#### Death Link Trigger

`death_link_trigger` · `ship_destroyed`, `crew_death`, `both` · Standard `both`\
Was deinen Tod schickt. `ship_destroyed`: nur ein verlorener Run, am besten in einer großen Multiworld.
`crew_death`: jedes verlorene Crewmitglied. `both`: beides. Crew stirbt oft, also schickt `both` viel.

#### Death Link Cloned Crew

`death_link_cloned_crew` · `true` / `false` · Standard `false`\
Ob ein Crewmitglied, das die Klonbucht zurückbringt, als Tod zählt. Aus, zählt nur eines, das nicht zurückkommt.

#### Death Link Toggle

`death_link_toggle` · `true` / `false` · Standard `true`\
Du kannst Death Link während des Spiels aus- und wieder einschalten, mit einem Klick auf der ersten Seite des
TAB-Dashboards. Schalte das aus für eine Gruppe, die bis zum Ende verbunden bleiben will.

#### Death Link Effect

`death_link_effect` · `major_incident`, `crew_member`, `hull_damage`, `fire`, `boarding`, `varied` · Standard `major_incident`\
Was der Tod eines anderen Spielers bei dir anrichtet. `major_incident`: ein Hüllenbruch und ein Feuer in einem
Systemraum, das Härteste. `crew_member`: ein Crewmitglied stirbt. `hull_damage`: Hüllenschaden. `fire`: ein
Feuer. `boarding`: ein feindlicher Mantis kommt an Bord. `varied`: einer der vier milderen, zufällig.

#### Energy Link

`energy_link` · `true` / `false` · Standard `false`\
Eine Treibstoffreserve, geteilt mit allen Energy-Link-Spielern, egal welches Spiel sie spielen. Dein
überschüssiger Treibstoff geht an ruhigen Baken hinein (mit 25 % Verlust), und du bekommst etwas zurück,
wenn du unter 3 fällst.

#### Trap Link

`trap_link` · `true` / `false` · Standard `false`\
Fallen werden mit den anderen Trap-Link-Spielern geteilt: Bekommt einer von euch eine Falle, bekommen die anderen
auch eine, selbst wenn dein Seed keine hat. Eine Falle aus einem anderen Spiel wird zur nächstliegenden FTL-Falle.

#### Trap Chance

`trap_chance` · 0 bis 100 · Standard `0`\
Der Anteil der Füller-Gegenstände, die zu Fallen werden. Es gibt 11 Arten: Feuer, Hüllenbruch, Treibstoffleck,
Systemschaden, Rebellenflotte, Hüllenschaden, Enterkommando, O2-Verlust, und drei, die auf deinen nächsten Kampf
warten (eine Anti-Schiff-Batterie, ein Energiestoß des Flaggschiffs, eine Gefahr). Fallen warten auf eine ruhige
Bake und zerstören nie dein Schiff.

#### Crew Names

`crew_names` · `vanilla`, `multiworld`, `multiworld_and_team` · Standard `multiworld`\
Die Namen der Crew, die sich dir während eines Runs anschließt. `multiworld`: die Slot-Namen der anderen Spieler,
dann die von FTL. `multiworld_and_team`: dasselbe, dann die Leute, die den Mod gemacht und getestet haben.
`vanilla`: die Namen von FTL. Deine Startcrew behält ihre Namen.

### Expert (nur YAML)

Diese Optionen sind nicht im Options Creator, nur in der YAML. Fast niemand braucht sie.

#### Goal

`goal` · `victory_count`, `victory_selection` · Standard `victory_count`\
`victory_count`: mit Victories Required verschiedenen Layouts gewinnen. `victory_selection`: mit jedem in
**Victory Layouts** gelisteten Layout gewinnen, und nur mit diesen.

#### Victory Layouts

`victory_layouts` · eine Liste · Standard leer\
Mit `victory_selection` die Layouts, die jeweils gewinnen müssen. Beispiel:
`victory_layouts: ["Kestrel Cruiser A", "Mantis Cruiser B"]`. Sie müssen im Seed sein.

#### Minimum Filler

`minimum_filler` · 0 bis 100 · Standard `20`\
Die kleinste Zahl an Füller-Gegenständen in deinem Seed.

#### Shields, Sensors, Medbay blueprint logic

`shields_blueprint_logic`, `sensors_blueprint_logic`, `medbay_blueprint_logic` · `required`, `upgrade_only`, `start_with` · Standard `upgrade_only`\
`required`: Ein Schiff, das mit diesem System startet, ist erst in der Logik, wenn du seinen Bauplan hast.
`upgrade_only`: Der Bauplan wird nur gebraucht, um das System zu verbessern oder zu kaufen. `start_with`: Du
startest mit dem Bauplan.

#### Engines, Weapon Control blueprint logic

`engines_blueprint_logic`, `weapons_blueprint_logic` · `anywhere`, `early`, `start_with` · Standard `early`\
Jedes Schiff startet mit diesen zwei Systemen, also entscheiden sie nur, wie früh der Bauplan kommt: irgendwo,
früh in deinen eigenen ersten Checks, oder von Anfang an.

Die [Seite des Spiels](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
(auf Englisch) erklärt die Logik, die Fallen und die Verbindungen genauer.
