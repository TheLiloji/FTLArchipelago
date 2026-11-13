# Spielen

[English](Playing.md) · [Français](Playing.fr.md) · **Deutsch** · [Español](Playing.es.md) ·
[Italiano](Playing.it.md) · [Português](Playing.pt.md)

Diese Seite begleitet ein Spiel von Anfang bis Ende: die Verbindung, der Hangar, ein Run, die Archipelago-Baken,
das Dashboard und das Ziel. Wenn der Mod noch nicht installiert ist, fang mit der Installationsanleitung an
([Windows](Setup-Windows.de.md), [Linux](Setup-Linux.de.md)).

## Dein erstes Spiel in fünf Schritten

1. Starte FTL, füll das Feld unten links im Hauptmenü aus und drück **Connect**.
2. Antworte **Use its own save**, wenn der Mod fragt, damit dieser Seed seinen eigenen FTL-Spielstand bekommt.
3. Klick auf **Neues Spiel**: Der Hangar öffnet sich auf deinem Startschiff. Wähl die Schwierigkeit, die dein
   Seed verlangt, und drück **START**.
4. Spiel wie gewohnt. Sektoren erreichen, Kämpfe gewinnen, Crew anwerben und Errungenschaften schicken Checks.
   Was die anderen für dich finden, kommt von selbst.
5. Drück jederzeit **TAB**, um dein Ziel zu sehen, was noch zu tun ist und was du erhalten hast.

Einen Run zu verlieren kostet nur den Run: Du behältst alles, was du erhalten hast, und der nächste Run startet
stärker.

## Verbinden

![Verbindungsfeld](../images/connect-panel.jpg)

Füll im Hauptmenü das Feld unten links aus:

| Feld | Was eintippen |
|---|---|
| Address | der Server, zum Beispiel `archipelago.gg`, oder die IP der Person, die hostet |
| Port | die Zahl nach dem Doppelpunkt in der Raumadresse, zum Beispiel `38281` |
| Slot name | der `name:` deiner YAML, genau so geschrieben |
| Password | nur wenn der Raum eins hat |

Drück **Connect** oder **ENTER**. **TAB** springt zwischen den Feldern. **Strg+V** fügt die von deiner Raumseite
kopierte Adresse ein (wie `archipelago.gg:38281`) und füllt Adresse und Port auf einmal.

- Die Felder werden fürs nächste Mal gespeichert. Das Passwort nie.
- Hak **Connect automatically on launch** an, und der Mod verbindet sich bei jedem FTL-Start neu.
- Bricht die Verbindung ab, versucht es der Mod von selbst erneut. Checks, die du in der Zwischenzeit machst,
  warten und gehen raus, sobald die Verbindung zurück ist.

Einmal verbunden, zeigt das Feld deine Checks und einen Knopf **Disconnect**, und oben erscheint das Ziel:

![Hauptmenü nach dem Verbinden](../images/main-menu.jpg)

### „The seed has changed"

![Die Frage beim Seed-Wechsel](../images/seed-change.jpg)

FTL kann ein Schiff freischalten, aber nie wieder sperren. Deshalb bekommt jeder Seed seinen eigenen
FTL-Spielstand. Wenn du einem neuen Seed beitrittst, fragt der Mod zuerst. **Use its own save** startet FTL mit
einem frischen Spielstand für diesen Seed neu, und der alte bleibt genau so, wie er war. **No, keep it** bleibt
offline auf dem aktuellen Spielstand.

Der Knopf **Saves** im Feld listet sie auf: einer pro Seed, plus Solo, mit den Checks und wann zuletzt gespielt.
**Load** startet FTL mit diesem Spielstand neu, laufender Run inklusive. **Archive** legt einen Spielstand im
Ordner `ap_profiles/archived` beiseite, nichts wird gelöscht. Dein FTL-Spielstand ohne Archipelago wird nie
angefasst.

![Das Fenster der Archipelago-Spielstände](../images/saves.png)

## Der Hangar

![Gesperrte Schiffe](../images/hangar.jpg)

Nur Schiffe, die du besitzt, können gewählt werden. Die anderen bleiben gesperrt, bis ihr Schlüssel kommt, und
neue Schiffe erscheinen beim nächsten Besuch im Hangar, nie mitten in einem Run. Layouts vom Typ B und C sind
eigene Gegenstände (außer dein Seed sagt etwas anderes). In der Schiffsliste ist ein Layout, das der Seed
weggelassen hat, mit **NOT IN SEED** markiert: Es wird nie freigeschaltet.

Der Hangar öffnet sich auf deinem Startschiff. **RANDOM SHIP** und die Pfeile **< >** gehen durch die Schiffe,
die du besitzt. FTL zeigt immer die Kestrel A, auch wenn sie nicht zählen kann: Ohne ihren Schlüssel (Option
`kestrel_key`) ist sie mit **NO KEY** markiert, außerhalb des Seeds mit **NOT IN SEED**. Bei so einem Schiff ist
**START** ausgegraut und wird mit kurzer Begründung verweigert, damit nie ein Run beginnt, der für nichts zählt.

Drück **TAB** im Hangar, um das Dashboard auf der Schiffe-Seite zu öffnen: Die Schiffe mit den meisten offenen
Checks stehen oben, die ohne offene Checks unten. **U** oder der Knopf zeigt oder versteckt die Schiffe, die du
nicht besitzt. So wählst du gut dein nächstes Schiff.

FTL kann Schiffe nicht von selbst freischalten: Der Mod verweigert das und sperrt im Hauptmenü ein Schiff wieder,
das FTL vorher freigeschaltet hat. Ist eines trotzdem spielbar, ist es mit **NOT RECEIVED** markiert, und ein Run
damit zählt für nichts, keine Checks und kein Sieg.

**Welche Schwierigkeit?** Standardmäßig zählen nur Siege auf Normal und Schwer für das Ziel. Hauptmenü und
Dashboard sagen, was dein Seed verlangt. Ein leichterer Sieg schickt trotzdem seinen Sieg-Check.

## Das Startmenü des Runs

![Das Startmenü des Runs](../images/start-menu.jpg)

Waffen und Drohnen gibt es zweimal unter den Gegenständen (standardmäßig in Bündeln von 3 Waffen oder 2
Drohnen), und Crewmitglieder kommen in bis zu drei Stufen. Sobald du von etwas eine zweite Kopie erhalten hast,
öffnet sich ganz am Anfang jedes neuen Runs ein Menü: Wähl **eine Waffe, eine Drohne und ein Crewmitglied** aus
allem, was du gesammelt hast, und sie kommen für diesen Run mit.

- Mit **System Install** auf `run_start` bietet dasselbe Menü auch die Systeme an, deren Bauplan du erhalten
  hast: Wähl die, die du willst, so viele, wie dein Schiff freie Räume hat.
- Mit **Sector Skip** gibt dir jeder übersprungene Sektor hier eine Wahl mehr.

Klick auf **Done**, um es zu schließen, oder spring einfach: Das Menü bleibt nur bis zum ersten Sprung. Wenn du
das Spiel vor der Wahl verlässt, ist es beim Fortsetzen noch da. Es kommt am Anfang jedes Runs wieder, also ist
eine gute zweite Kopie jedes Mal etwas wert.

## Während eines Runs

![Gegenstände, die während eines Runs ankommen](../images/in-game.jpg)

### Was einen Check schickt

Je nach deinen Optionen:

- **einen Sektor erreichen** mit einem Layout (die meisten Checks kommen von hier);
- **das Flaggschiff besiegen** mit einem Layout;
- **das erste Crewmitglied jeder Spezies**, das sich dir anschließt;
- **Errungenschaften**, des Schiffs oder allgemeine. Sie gehen beim nächsten Sprung raus;
- **ein System einbauen**, oder jede seiner Stufen (Systemsanity);
- **Kämpfe gewinnen**: die ersten eines Runs, oder jedes Sektors;
- **Reaktorleistung** 10, 15, 20 und 25;
- **ein Paket kaufen** im Archipelago-Laden, und die Pakete der Relais- und Piraten-Events.

Das Dashboard (TAB) listet jeden Check deines Seeds und markiert blau die, die du schon machen kannst.

### Was du erhältst

Was du erhältst, kommt von selbst, an der nächsten ruhigen Bake, wenn du im Kampf bist:

- ein **Schiffsschlüssel** oder ein **Layout**: beim nächsten Mal im Hangar;
- ein **System-Bauplan**: Läden dürfen dieses System jetzt verkaufen (oder es kommt kostenlos an Bord, mit
  System Install);
- ein **Progressive**-Systemgegenstand: eine Verbesserungsstufe mehr erlaubt (oder kostenlos eingebaut, mit
  Free Upgrades);
- eine **Waffe oder Drohne**, erste Kopie: Ein Exemplar kommt an Bord (in den Frachtraum, wenn deine Plätze voll
  sind; ist der Frachtraum auch voll, wartet es, bis du Platz machst) und taucht öfter in Läden auf. Zweite
  Kopie: Sie kommt ins Startmenü des Runs;
- eine **Erweiterung**: Ein Exemplar kommt an Bord und taucht öfter in Läden auf (sind deine drei Plätze voll,
  wartet sie, bis einer frei wird);
- ein **Crewmitglied**: Das erste schließt sich deinem Run an (oder wartet auf einen freien Platz), das zweite
  kommt ins Startmenü des Runs, das dritte macht aus diesem Menüeintrag einen Experten mit einer gemeisterten
  Fähigkeit;
- ein **Head Start**: eine kostenlose Systemstufe oder ein Reaktorbalken am Anfang jedes künftigen Runs;
- ein **Sector Pass** (mit Sector Locks): Der Ausgang von Sektor 4, dann 7, öffnet sich für dieses Layout;
- ein **Archiv**: ein Schritt näher am Ziel;
- **Füller** (Schrott, Treibstoff, Raketen, Drohnenteile, Hüllenreparatur) und, wenn der Seed welche hat,
  **Fallen**.

Wenn viel auf einmal kommt (das Release eines anderen Spielers, das Spielende), kommen Waffen und Drohnen zu
viert pro Bake; der Rest folgt bei den nächsten Sprüngen.

Notizen unten links sagen dir, was ankam und was rausging. Sie verblassen nach ein paar Sekunden, und alles
bleibt im Dashboard.

### Fallen

Eine Falle zerstört nie dein Schiff: Sie lässt mindestens 3 Hülle und 2 Treibstoff, schaltet nie ein System ganz
ab und wartet auf eine ruhige Bake. Die Notiz sagt, welche Falle es ist und wer sie geschickt hat.

| Falle | Was passiert |
|---|---|
| Fire | in einem Raum bricht ein Feuer aus |
| Hull Breach | in einem Raum öffnet sich ein Hüllenbruch |
| Fuel Leak | du verlierst Treibstoff |
| System Damage | ein System nimmt Schaden |
| Rebel Fleet | die Rebellenflotte rückt einen Sprung näher |
| Hull Damage | deine Hülle verliert ein paar Punkte |
| Boarding Party | ein Feind kommt an Bord |
| O2 Drain | alle Räume verlieren auf einmal ihre Luft (nie, wenn dein Sauerstoffsystem ausgefallen ist) |
| Anti-Ship Battery | wartet auf deinen nächsten Kampf: eine Planetenbatterie schießt dabei auf dich |
| Power Surge | wartet auf deinen nächsten Kampf: der Gegner löst einen Energiestoß des Flaggschiffs aus (schwächer in den Sektoren 1 und 2) |
| Hazard | wartet auf deinen nächsten Kampf: die Bake bekommt einen Nebel, einen Ionensturm, Asteroiden, eine Sonne oder einen Pulsar |

Die letzten drei verschwinden am Ende des Kampfs, und pro Kampf löst nur eine aus.

### Sector Skip und Sector Locks

Zwei Optionen ändern die Karte, wenn dein Seed sie hat:

- **Sector Skip**: In den Sektoren 1 bis 4 ist die erste Bake ein Ausgang, wenn dieses Layout den nächsten
  Sektor in einem früheren Run schon erreicht hat. Spring sofort für 60 Schrott und eine Wahl mehr im Startmenü
  des Runs, oder erkunde wie gewohnt. Die Checks des übersprungenen Sektors warten auf einen anderen Run.

  ![Sector Skip: die erste Bake ist ein Ausgang](../images/sector-skip.jpg)

- **Sector Locks**: Der Ausgang von Sektor 4 bleibt zu, bis dieses Layout seinen ersten Sector Pass hat, der von
  Sektor 7 bis zum zweiten. Die Ausgangsbake sagt, was fehlt, und öffnet sich, sobald der Pass ankommt.

### Das Flaggschiff

Mit **Flagship Sabotage** sagt dir eine Meldung, wenn das Flaggschiff geschwächt ankommt, und wie stark (Hülle,
Schilde, Waffen). Der Sieg geht raus, sobald das Flaggschiff zerstört ist.

## Archipelago-Baken

![Archipelago-Baken auf der Karte](../images/map.jpg)

Jeder Sektor hat eine Bake mit **AP STORE**, mit dem Archipelago-Laden, und andere Baken enthalten die eigenen
Events des Mods. Standardmäßig sind nur die zwei, die ein Paket tragen (das Relais und die Piraten), auf der Karte
mit **ARCHIPELAGO** markiert; die Option **Event Beacons** kann alle oder keine markieren.

### Der Archipelago-Laden

![Der Archipelago-Laden](../images/shop.jpg)

Jedes Paket ist ein Gegenstand aus der Multiworld. Der Name darunter sagt, für wen es ist; **FOR YOU** heißt,
einer deiner eigenen Gegenstände. Ein Paket zu kaufen schickt es sofort:

![Ein verschicktes Paket](../images/shop-sent.jpg)

Füller kostet 10 bis 25 Schrott, nützliche Gegenstände 30 bis 65, wichtige 70 bis 150. Ein verschicktes Paket
kommt nie zurück. Jeder Sektor verkauft seine eigenen Pakete: Der Laden in Sektor 5 hat andere Pakete als der in
Sektor 2, und sie kosten mehr. Mit **Archipelago Shop by Sector** wird ein Paket nur in seinem Sektor verkauft,
und der Laden sagt, in welchem Sektor die nächsten sind.

Standardmäßig werden die Pakete, die du siehst, zu Hinweisen für ihre Besitzer: Sie wissen, wo ihr Gegenstand
wartet.

Der Laden verkauft auch **Pakte**: sofort Schrott, und dafür wird eine Falle ausgelöst, zwei von drei Malen bei
einem anderen Spieler (mit Trap Link), ein von drei Malen bei dir. Ohne Trap Link immer bei dir. Wenn es dich
trifft, schlägt sie in deinem nächsten Kampf zu, nicht an der ruhigen Laden-Bake. Die **Blutpakte** auf der
zweiten Seite zahlen mehr und fügen eine Chance (5, 10 oder 20 %) hinzu, dass eines deiner Crewmitglieder für
immer stirbt, Klonbucht oder nicht. Sie nehmen nie dein letztes Crewmitglied.

![Blutpakte im Archipelago-Laden](../images/blood-pacts.jpg)

### Die Events

- **Ein Relais** mit Paketen für andere Spieler. Zahl 15 Schrott, um eines weiterzuleiten.
- **Piraten mit einem Paket**, oft dem eines Freundes. Zahl ihnen 20 Schrott, oder kämpf gegen sie und schick es
  gratis, wenn du gewinnst.
- **Ein Zoltan-Kontrollpunkt**, der 3 Treibstoff für 15 Schrott verkauft. Mit Energy Link kostet es 20 und legt 1
  Treibstoff in die geteilte Reserve, oder du nimmst stattdessen Treibstoff aus der Reserve.
- **Ein Slug**, der für 20 Schrott einen echten Archipelago-Hinweis verkauft. Gibt es nichts mehr zu verraten,
  bekommst du den Schrott zurück.
- **Ein Energiestoß aus einer anderen Welt**, den du aufnehmen oder als Falle weiterschicken kannst (mit Trap
  Link).
- **Ein Engi-Techniker** (Engi- und Zivilsektoren), der 30 Schrott wettet, dass er deinen Reaktor übertakten
  kann. Hält es, zahlt es 75 Schrott, sonst kostet es Hüllen- und Antriebsschaden. Du kannst ihn auch für 3
  Treibstoff den Antrieb testen lassen, oder einfach gehen.
- **Ein Waffenhändler**, selten, in Piratensektoren: eine zufällige Waffe für 45 Schrott oder eine zufällige
  Erweiterung für 4 Treibstoff.

| | |
|---|---|
| ![Die Übertakten-Wette des Engi](../images/event-overclock.jpg) | ![Der Waffenhändler](../images/event-arms-dealer.jpg) |

Mit **Archipelago Event Checks** sind die Pakete des Relais und der Piraten eigene Checks („Archipelago Event 1",
2...), bevor sie wieder die Pakete des Ladens verkaufen. Keines dieser Events kann dir einen Check verstecken: Sie
sind ein Extra, nie Pflicht.

## Mit anderen spielen: die Verbindungen

Sie funktionieren nur, wenn deine YAML sie eingeschaltet hat. Die erste Seite des Dashboards zeigt, welche aktiv
sind.

- **Death Link**: Wenn du stirbst, sterben die anderen auch, und umgekehrt. Dein Seed sagt, was als dein Tod zählt
  (ein verlorener Run, ein verlorenes Crewmitglied oder beides). Ein empfangener Tod richtet etwas Schlimmes an
  (standardmäßig ein Hüllenbruch und ein Feuer in einem Systemraum), zerstört aber nie dein Schiff und tötet nie
  dein letztes Crewmitglied. Klick auf der ersten Seite des Dashboards auf Death Link, um es aus- oder
  einzuschalten, wenn dein Seed es erlaubt.
- **Energy Link**: eine Treibstoffreserve, geteilt mit allen Energy-Link-Spielern. Dein überschüssiger Treibstoff
  geht an ruhigen Baken hinein (25 % gehen unterwegs verloren), und wenn du unter 3 Treibstoff fällst, holt sich
  dein Schiff etwas zurück, einmal pro Bake. Das Dashboard zeigt, wie viel in der Reserve ist.
- **Trap Link**: Wenn jemand eine Falle bekommt, bekommen die anderen auch eine. Eine Falle aus einem anderen
  Spiel wird zur nächstliegenden FTL-Falle („Ice Trap" schaltet ein System aus, eine Feuerfalle legt ein
  Feuer...).

## Das Dashboard

Drück **TAB** in einem Run oder im Hangar. Im Run pausiert das Spiel, solange es offen ist. **Links** / **Rechts**
oder **1** bis **5** wechseln die Seite, das Mausrad scrollt, **Esc** oder **TAB** schließt es.

| | |
|---|---|
| ![Übersicht](../images/dashboard-links.jpg) | ![Schiffe](../images/dashboard-ships.png) |
| **1 Übersicht**: dein Ziel und wo du stehst, erledigte Checks pro Kategorie, deine Verbindungen (Death Link, Energy Link, Trap Link), dieser Run (übrige Kampf-Checks, Schrott für den nächsten Run, kostenlose Verbesserungen), die zuletzt erhaltenen Gegenstände und deine Hinweise. | **2 Schiffe**: jedes Layout des Seeds, besessen oder nicht, und wie viele Checks ihm noch fehlen. **U** zeigt nur die, die du besitzt. |
| ![Systeme](../images/dashboard-systems.png) | ![Checks](../images/dashboard-checks.png) |
| **3 Systeme**: welche Baupläne du hast, wie viele Verbesserungsstufen du für jedes System erhalten hast, und die Head Starts am Anfang jedes Runs. | **4 Checks**: jeder Check des Seeds, nach Kategorie und Schiff für Schiff. Erledigte in Grün, und eine **blaue Linie** unter denen, die du mit dem, was du hast, schon machen kannst. Zeig auf ein Feld, um zu sehen, was es ist und was es nach dem Erledigen gab. |

![Journal](../images/dashboard-journal.png)

**5 Journal**: jeder erhaltene Gegenstand, wer ihn geschickt hat und was in jedem Bündel war, gefärbt nach seiner
Archipelago-Klasse (Fortschritt grün, nützlich blau, Falle rot, Füller grau). Rechts deine Hinweise: was die
anderen für dich gefunden haben und wo deine Gegenstände in ihren Welten warten. Ein Hinweis bleibt dort, bis
der Gegenstand gefunden ist.

Die Checks-Seite hat auch die Errungenschaften mit ihren Spiel-Icons, die Siege mit dem Bild jedes Schiffs und
die Crew-Spezies, die du angeworben hast.

![Errungenschaften auf der Checks-Seite](../images/dashboard-achievements.jpg)

**Wohin als Nächstes?** Öffne die Checks-Seite und such die blauen Linien beim Schiff, das du fliegst. Auf der
Schiffe-Seite stehen die Schiffe mit den meisten offenen Checks oben.

## Das Ziel

Besiege das Flaggschiff mit einer Anzahl **verschiedener** Schiffe (oder Layouts). Hauptmenü und Dashboard sagen
es ausführlich, zum Beispiel „besiege das Flaggschiff 2 Mal, ein anderes Layout für jeden Sieg", und listen die
Schiffe, mit denen du schon gewonnen hast. Ein zweiter Sieg mit demselben Schiff schickt trotzdem dessen
Sieg-Check, er zählt nur nicht noch einmal für das Ziel.

Manche Seeds verlangen auch **Archive**: Gegenstände, verteilt in der Multiworld, auch in deiner eigenen Welt. Du
brauchst beides, die Siege und genug Archive. Das Ziel geht von selbst raus, sobald beides da ist, auch wenn das
letzte Archiv ankommt, während du im Menü sitzt.

Manche Seeds verlangen Siege auf Normal oder Schwer. Ein leichterer Sieg schickt trotzdem seinen Check, zählt aber
nicht für das Ziel.

## Solomodus

Kein Server? Klick auf **Solo mode** im Verbindungsfeld. Er nutzt einen echten erzeugten Seed und gibt dir pro
Check einen seiner Gegenstände. Es ist immer derselbe Demo-Seed, der mit dem Mod kommt, nicht deine YAML, also
gelten deine Optionen nicht. Dein Fortschritt wird in einem eigenen Spielstand gespeichert, du kannst also
aufhören und später weitermachen. **Stop solo** legt ihn beiseite, und ein erneuter Klick auf **Solo mode** fragt,
ob du weitermachen oder neu anfangen willst.

## Gut zu wissen

- **Einen Run zu verlieren kostet nur den Run.** Die Gegenstände bleiben, und Head Starts machen den nächsten Run
  stärker.
- **Ein Run, der vor dem Verbinden begonnen hat, zählt nicht.** Erst verbinden, dann ein neues Spiel starten.
  Dasselbe gilt für einen Run, der unter einem anderen Seed gespeichert wurde: „Fortsetzen" bringt ihn zurück,
  aber er zählt für nichts, und Schrott, Treibstoff und Fallen, die du in der Zeit erhältst, warten auf deinen
  nächsten echten Run.
- **Zu einem schon gespielten Seed zurückzukehren** gibt seinen Schrott, Treibstoff und seine Fallen nicht ein
  zweites Mal aus. Schiffe, Baupläne und Verbesserungsstufen kommen so zurück, wie sie waren.
- **Errungenschafts-Checks gehen beim nächsten Sprung raus**, und Errungenschaften von vor Archipelago zählen
  nicht: Verdien sie neu.
- **„Sektor 1 erreichen" braucht einen Sprung.** Ein Check geht raus, wenn du irgendwo ankommst.
- **Empfangene Fallen zerstören nie dein Schiff.** Sie lassen mindestens 3 Hülle und 2 Treibstoff und warten auf
  eine ruhige Bake.
- **Empfangene Tode** (Death Link) nehmen nie deinen letzten Hüllenpunkt oder dein letztes Crewmitglied.
- **Du schickst einen Tod** (Death Link), wenn du den Run oder ein Crewmitglied verlierst, je nach den Optionen des
  Seeds. Ein Crewmitglied, das die Klonbucht zurückbringt, ist kein Tod, außer der Seed zählt sie. Ein
  Crewmitglied im Crew-Bildschirm zu entlassen oder eine Drohne zu verlieren zählt nicht.
- **Namen von Gegenständen und Orten bleiben auf Englisch**, egal in welcher Sprache, weil alle Spieler und
  Tracker sie teilen. Nur die Sätze drumherum werden übersetzt.

## Wenn etwas nicht klappt

Schau zuerst in die [FAQ](FAQ.md) (auf Englisch). Hilft das nicht, frag auf dem
[Discord](https://discord.gg/BVQnQu843Q) oder öffne ein
[Issue](https://github.com/TheLiloji/FTLArchipelago/issues) mit deiner `FTL_HS.log` (unter Windows im
FTL-Ordner, unter Linux in seinem Ordner `data`).
