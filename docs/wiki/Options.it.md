# Opzioni

[English](Options.md) · [Français](Options.fr.md) · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
**Italiano** · [Português](Options.pt.md)

Le tue opzioni stanno in un piccolo file di testo, lo **YAML**. Lo fai una volta, prima della partita, e lo mandi
alla persona che genera il multiworld. Questa pagina spiega ogni opzione, una per una. Non serve leggerla tutta:
prendi un preset e torna qui quando vuoi cambiare qualcosa.

## Prima di iniziare

Ti serve **Archipelago 0.6.7**, con il `ftl.apworld` della
[pagina della release](https://github.com/TheLiloji/FTLArchipelago/releases/latest) nella sua cartella
`custom_worlds`. Senza, FTL non compare nell'elenco. Le guide di installazione ([Windows](Setup-Windows.it.md),
[Linux](Setup-Linux.it.md)) spiegano ogni passaggio.

## Qualche parola che incontrerai

| Parola | Significato |
|---|---|
| check | qualcosa che fai nel gioco e che manda un oggetto: raggiungere un settore, vincere, un obiettivo... |
| oggetto (item) | ciò che un check dà a te o a un altro giocatore: una nave, un sistema, un'arma, rottami... |
| seed | la partita generata, uguale per tutto il multiworld |
| slot | il tuo posto nel multiworld, con il nome della riga `name:` del tuo YAML |
| layout | una versione di una nave (« configurazione » nel gioco): Kestrel A, Kestrel B e Kestrel C sono tre layout. Ce ne sono 28, su 10 navi |
| progressive | un oggetto che alza un sistema di un livello ogni volta che lo ricevi |
| progetto (blueprint) | l'oggetto che ti permette di avere un sistema (Occultamento, Controllo droni...) |
| run | un tentativo, dal primo faro alla vittoria o alla distruzione della nave |
| Archivi | oggetti che ti servono oltre alle vittorie per finire |
| riempitivo (filler) | oggetti piccoli: rottami, carburante, missili, parti di drone |
| trappola (trap) | un oggetto cattivo: un incendio, una breccia, la flotta ribelle che avanza... |
| logica | ciò che il generatore presume tu abbia prima di chiederti un check |
| AP STORE | il negozio Archipelago, un faro per settore, che vende gli oggetti del multiworld |

## La via più semplice: scegliere un preset

I preset sono file YAML già pronti. Scegli quello adatto al tempo che hai:

| Preset | Tempo fino all'obiettivo | Cos'è |
|---|---|---|
| `first_game` | circa 3 h | **La tua prima partita Archipelago.** 1 vittoria, Facile conta, 3 navi di tipo A, 2 Archivi su 3, niente trappole. I potenziamenti e i sistemi ricevuti salgono a bordo da soli |
| `short_game` | circa 5 h | 2 vittorie a Normale o Difficile, 4 layout, 4 Archivi su 5, tutti i potenziamenti di un sistema in una volta |
| `medium_game` | circa 10 h | le opzioni predefinite: 5 vittorie a Normale o Difficile, 7 layout, 10 Archivi su 12 |
| `long_game` | 20 h o più | 10 vittorie, 14 layout, 16 Archivi su 20, installare un sistema è un check |
| `solo_game` | circa 7 h | **Da solo nel multiworld.** 3 vittorie, 5 layout, combattimenti contati per settore, salto di settore e Sector Pass, più check di eventi |

Sono in `presets.zip` sulla [pagina della release](https://github.com/TheLiloji/FTLArchipelago/releases/latest).
L'inizio di ogni file dice quanti check ha e quanto dura più o meno.

1. Apri il file in un editor di testo.
2. Sostituisci la riga `name:` con il tuo nome. Usa solo lettere senza accenti, cifre, spazi, `-` e `_`, e al
   massimo 16 caratteri: il pannello di connessione del gioco non sa scrivere altro.
3. Manda il file alla persona che genera il multiworld (la sua guida, in inglese: [Hosting a seed](Hosting-a-seed.md)).

I tempi valgono per chi vince in poche run. Se FTL è nuovo per te, conta di più.

## Creare il tuo YAML

Apri **ArchipelagoOptionsCreator** (nella cartella di Archipelago), scegli **FTL: Faster Than Light**, scrivi
il tuo nome ed esporta lo YAML. Ogni opzione ha una breve descrizione (in inglese): passaci sopra con il mouse.
I valori predefiniti sono quelli del preset `medium_game`.

Puoi anche modificare un preset a mano. Ogni opzione è una riga: il nome YAML, due punti, il valore. Per esempio:

```yaml
name: IlMioNome
game: "FTL: Faster Than Light"
requires:
  version: 0.6.7
"FTL: Faster Than Light":
  victories_required: 3
  start_ship: rock_cruiser
  trap_chance: 10
```

Lascia i due spazi davanti a ogni opzione. Un'opzione che non scrivi prende il suo valore predefinito.

## Tre errori frequenti

- **Vittorie a Facile.** Di base contano per l'obiettivo solo le vittorie a Normale e Difficile. Se giochi a
  Facile, metti **Victory Difficulty** su `any` (nello YAML va bene anche `easy`).
- **Meno check non vuol dire una partita più corta.** Disattivare settori o obiettivi non toglie i loro oggetti:
  passano al negozio Archipelago, dove li compri con i rottami. Per accorciare una partita, abbassa piuttosto
  **Victories Required** e **Layouts in the Seed**.
- **Death Link.** Se il tuo gruppo ci gioca, attivalo. Con **Death Link Trigger** su `both` (predefinito), ogni
  membro dell'equipaggio che perdi uccide anche gli altri. In un multiworld grande o per una prima partita,
  scegli `ship_destroyed`: conta solo una run persa.

## Idee per il tuo YAML

Una partita più corta, senza toccare il resto:

```yaml
  victories_required: 2
  layout_count: 4
  sectorsanity_last_sector: 6
```

Una seconda nave presto, e oggetti ricevuti che servono subito:

```yaml
  early_ship_keys: 3
  free_upgrades: true
  system_install: run_start
  run_start_scrap: 15
```

Più cose da fare in ogni run:

```yaml
  combat_checks: 1
  combat_checks_mode: per_sector
  reactor_checks: true
  systemsanity: first_install
```

Caos tra amici:

```yaml
  trap_chance: 30
  trap_link: true
  death_link: true
```

Un seed più duro, per chi conosce bene FTL:

```yaml
  victory_difficulty: hard
  sector_logic: none
  shop_unlock_mode: locked
  sector_locks: true
```

## Tutte le opzioni, gruppo per gruppo

I gruppi sono quelli del creatore di opzioni. Ogni opzione mostra il suo nome nel creatore di opzioni (in
inglese), il suo nome nello YAML, i valori possibili e il valore predefinito. I gruppi segnati *chiuso* sono
ripiegati all'inizio nel creatore di opzioni: non ti servono per una prima partita.

### Goal (l'obiettivo)

Quello che devi fare per finire.

#### Victories Required

`victories_required` · da 1 a 28 · predefinito `5`\
Quante volte devi battere l'ammiraglia, ogni volta con un layout **diverso** (Kestrel A e Kestrel B contano per
due). È l'opzione che decide quanto dura la tua partita: 1 o 2 per una prima partita, 5 tra amici, 10 per una
partita lunga.

#### Victory Difficulty

`victory_difficulty` · `any`, `normal`, `hard` · predefinito `normal`\
La difficoltà minima di una vittoria perché conti per il tuo obiettivo. `any` (o `easy`) conta tutte le
vittorie, `normal` conta Normale e Difficile, `hard` solo Difficile. Una vittoria più facile manda comunque il
suo check, solo non conta per l'obiettivo.

#### Flagship Sabotage

`flagship_sabotage` · da 0 a 5 · predefinito `0`\
Il multiworld indebolisce l'ammiraglia. Ogni livello aggiunge qualcosa, e vale per ogni fase dello scontro: 1 è
scafo -10 %, 2 aggiunge scudi -1, 3 porta a scafo -20 %, 4 aggiunge armi -1, 5 porta a scafo -30 %. Un messaggio
ti dice il livello quando arriva l'ammiraglia. Buono per un gruppo che vuole finire prima.

#### Archives

`archives` · da 0 a 50 · predefinito `12`\
Quanti Archivi sono nascosti nel multiworld, nel tuo mondo o in quello degli altri. Gli Archivi sono oggetti che
ti servono oltre alle vittorie. 0 gioca senza.

#### Archives Required

`archives_required` · da 0 a 50 · predefinito `10`\
Quanti Archivi ti servono per finire. Tienilo un po' più basso di **Archives**, così un Archivio messo male non
può bloccarti. Se è più alto di Archives, servono tutti.

#### Victory Collects the Layout

`victory_collects_layout` · `off`, `sectors`, `everything` · predefinito `sectors`\
Cosa manda in più una vittoria, tra i check di quel layout che non hai ancora fatto. `off`: solo la vittoria.
`sectors`: anche tutti i check di settore di quel layout. `everything`: anche gli obiettivi della sua nave, i
suoi check di sistema e i suoi check di combattimento. Utile quando vinci con una nave e non vuoi tornarci per il
settore 3.

### Ships (le navi)

Quali navi sono nella partita e come le ottieni.

#### Starting Ship

`start_ship` · una delle 10 navi · predefinito `kestrel_cruiser`\
La nave con cui inizi, in tipo A. I suoi tipi B e C si trovano come quelli delle altre. I valori sono
`kestrel_cruiser`, `engi_cruiser`, `federation_cruiser`, `zoltan_cruiser`, `mantis_cruiser`, `slug_cruiser`,
`rock_cruiser`, `stealth_cruiser`, `lanius_cruiser` e `crystal_cruiser` (o solo `rock`, `mantis`...).

#### Ship Layouts

`ship_layouts` · `type_a_only`, `up_to_type_b`, `all_layouts` · predefinito `all_layouts`\
Quali layout possono essere nella partita: solo il tipo A, i tipi A e B, o tutti.

#### Layouts in the Seed

`layout_count` · da 1 a 28 · predefinito `7`\
Quanti layout puoi pilotare in questo seed, in tutto. La tua nave iniziale e la Kestrel A contano, quindi 7 vuol
dire queste due più altre 5, estratte a caso tra quelle che **Ship Layouts** permette. Un tipo B o C arriva solo
con il tipo A della sua nave. I layout lasciati fuori non hanno né chiave né check, e l'hangar li segna
**NOT IN SEED**. Sale a Victories Required se è più basso.

#### Excluded Ships and Layouts

`excluded_layouts` · una lista · predefinito vuoto\
Le navi o i layout che non vuoi mai nel seed. Nomina una nave intera (`"Engi Cruiser"`) o un layout
(`"Engi Cruiser B"`, o `"Engi B"`). Togliere un tipo A toglie tutta la sua nave. La tua nave iniziale e la
Kestrel A non si possono togliere. Esempio: `excluded_layouts: ["Stealth Cruiser", "Lanius Cruiser C"]`.

#### Layout Unlocks

`layout_unlocks` · `items`, `vanilla`, `independent`, `progressive` · predefinito `items`\
Come diventano disponibili i tipi B e C.
- `items`: ogni layout è un oggetto a sé, e ti serve anche la chiave della nave per pilotarlo.
- `vanilla`: come in FTL, ottenendo gli obiettivi di quella nave. Nessun oggetto di layout.
- `independent`: ogni layout è un oggetto a sé e non ha bisogno d'altro, nemmeno della chiave della nave.
- `progressive`: nessun oggetto di layout. La chiave della nave arriva una volta per layout: la prima copia dà il
  tipo A, le successive il tipo B, poi il C.

#### Early Ship Keys

`early_ship_keys` · da 0 a 9 · predefinito `1`\
Quante chiavi di nave, oltre alla tua nave iniziale e alla Kestrel, vengono messe nei tuoi primi check. Una
seconda nave arriva presto invece che ore dopo. Il numero di chiavi non cambia, solo dove cadono. 0 le lascia
cadere ovunque.

#### Kestrel Needs Its Key

`kestrel_key` · `true` / `false` · predefinito `false`\
Quando non inizi con la Kestrel, la Kestrel A ha bisogno della sua chiave come ogni altra nave. FTL la mostra
comunque nell'hangar, ma è segnata **NO KEY** e START la rifiuta finché non arriva la chiave. Disattivato, la
Kestrel A è sempre tua.

### Checks

Cosa manda dei check. La maggior parte dei tuoi check viene dai settori.

#### Sectorsanity

`sectorsanity` · `disabled`, `milestones`, `full` · predefinito `full`\
Raggiungere un settore con un layout manda un check. Ogni layout ha i suoi: la Rock A al settore 4 non è lo
stesso check della Rock B al settore 4. `full`: ogni settore. `milestones`: solo i settori 5 e 8. `disabled`:
mai.

#### Sectorsanity First Sector

`sectorsanity_first_sector` · da 1 a 8 · predefinito `2`\
Il primo settore che manda un check. I settori prima non mandano niente. Con tutti i layout in gioco, i settori 1
e 2 da soli fanno 56 check che ottieni solo decollando: alzarlo è il modo più semplice di alleggerire un seed
grande.

#### Sectorsanity Last Sector

`sectorsanity_last_sector` · da 1 a 8 · predefinito `8`\
L'ultimo settore che manda un check. Un check al settore 8 costa una run intera, uno al settore 4 arriva da solo.
5 o 6 tiene le stesse navi ma taglia la lunga coda del seed, la parte in cui gli altri ti aspettano.

#### Systemsanity

`systemsanity` · `disabled`, `first_install`, `every_level` · predefinito `disabled`\
Installare un sistema manda un check. `first_install`: una volta per sistema, 12 check (Motori, Ossigeno,
Pilotaggio e Controllo armi non ne hanno, ogni nave parte con loro). `every_level`: anche ogni livello di
potenziamento, 64 check, una partita molto più lunga.

#### Systemsanity per Ship

`systemsanity_per_ship` · `true` / `false` · predefinito `false`\
Con Systemsanity attivo, ogni nave ha i suoi check di installazione, come "Kestrel Cruiser: Install Cloaking".
Mai per un sistema con cui quella nave parte.

#### Ship Achievement Checks

`ship_achievements` · `true` / `false` · predefinito `true`\
I tre obiettivi di ogni nave mandano un check, 30 in tutto. FTL li dà alla nave, non al layout: ottenerli con il
tipo A, B o C manda lo stesso check.

#### General Achievement Checks

`general_achievements` · `disabled`, `basic`, `most`, `all` · predefinito `most`\
Quali dei 21 obiettivi generali mandano un check. `basic`: quelli facili, come raggiungere il settore 8. `most`:
anche quelli più difficili, ottenuti nel corso di una run. `all`: tutti, anche quelli molto difficili.

#### Cross-Run Achievement Checks

`cross_run_achievements` · `true` / `false` · predefinito `false`\
I tre obiettivi che non si possono ottenere in una sola run: "Rule Ten: Greed is Eternal" (10.000 rottami in
tutte le tue partite), "Warlord" (1000 navi distrutte) e "Your Own Fleet" (tutte le navi sbloccate). Lascialo
spento per un seed corto: i primi due potrebbero non arrivare mai.

#### Crew Checks

`crew_checks` · `true` / `false` · predefinito `true`\
Il primo membro dell'equipaggio di ogni razza che si unisce a te manda un check: Umano, Engi, Zoltan, Mantis,
Rock, Slug e Lanius. 7 check. L'equipaggio con cui inizi una run non conta.

#### Archipelago Event Checks

`event_checks` · da 0 a 20 · predefinito `5`\
I pacchi degli eventi del relè e dei pirati diventano check a sé, "Archipelago Event 1", 2... fino a questo
numero. Quando sono tutti fatti, gli eventi tornano a vendere pacchi del negozio Archipelago. 0: gli eventi
vendono solo i pacchi del negozio.

#### Reactor Checks

`reactor_checks` · `true` / `false` · predefinito `false`\
Potenziare il reattore manda check a potenza 10, 15, 20 e 25, in qualsiasi run. La logica se li aspetta verso i
settori 2, 4, 6 e 7.

#### Combat Checks per Ship

`combat_checks` · da 0 a 10 · predefinito `0`\
Vincere combattimenti manda check. Con ogni nave, i primi combattimenti che vinci in una run (nemico distrutto o
il suo equipaggio ucciso) mandano "Fight 1 won", "Fight 2 won"... fino a questo numero. 0 li spegne.

#### Combat Checks Mode

`combat_checks_mode` · `per_run`, `per_sector` · predefinito `per_run`\
Come si contano i combattimenti. `per_run`: i primi combattimenti di una run, come sopra. `per_sector`: i primi
combattimenti di **ogni** settore mandano il loro check ("Sector 3 fight 1 won"), fino a **Fights per Sector**,
quindi una run fino al settore 8 può mandare check ovunque. In questa modalità Combat Checks per Ship deve solo
essere sopra 0.

#### Fights per Sector

`fights_per_sector` · da 1 a 5 · predefinito `2`\
Con `per_sector`: quanti combattimenti in ogni settore mandano un check, per ogni nave.

#### Combat Check Scrap (%)

`combat_check_scrap` · da 0 a 100 · predefinito `50`\
Un combattimento che manda un check dà solo questa parte dei suoi rottami. Missili, carburante e parti di drone
restano. I combattimenti che non mandano niente tengono tutta la ricompensa.

### Systems and Upgrades (sistemi e potenziamenti) *(chiuso)*

Come i sistemi e i loro livelli vengono bloccati e poi restituiti.

#### System Blueprints

`system_blueprints` · `true` / `false` · predefinito `true`\
I progetti dei sistemi sono oggetti. Senza il progetto di un sistema, i negozi non lo vendono. Un sistema con cui
parte la tua nave non viene mai tolto: resta al livello 1 finché non arriva il progetto. Spento, ogni sistema è
in vendita.

#### Progressive System Upgrades

`progressive_systems` · `true` / `false` · predefinito `true`\
Ogni oggetto "Progressive" alza fin dove puoi potenziare un sistema, fino al massimo di FTL. Paghi comunque i
rottami, salvo con Free Upgrades. Di base un oggetto vale per tutte le navi: "Progressive Shields" alza gli scudi
di tutte. Spento, i sistemi si potenziano come in FTL.

#### Progressive Upgrades per Ship

`progressive_systems_per_ship` · `true` / `false` · predefinito `false`\
I potenziamenti appartengono ciascuno a una nave, come "Kestrel Cruiser: Progressive Shields", e contano solo a
bordo di quella nave, qualunque sia il layout. Molti più oggetti, quindi un negozio Archipelago più grande.

#### Progressive Unlocks the System

`progressive_unlocks_system` · `true` / `false` · predefinito `false`\
Il primo oggetto Progressive di un sistema lo sblocca anche, quindi quel sistema non ha un oggetto progetto a
parte. Meno oggetti da aspettare: i sistemi arrivano prima.

#### Full System Upgrades

`full_system_upgrades` · `true` / `false` · predefinito `false`\
Ogni oggetto Progressive dà tutti i livelli del suo sistema in una volta. Meno oggetti, una progressione meno fine.

#### Free Upgrades

`free_upgrades` · `true` / `false` · predefinito `false`\
I livelli di sistema che ricevi vengono installati gratis: subito se sei in una run, e di nuovo all'inizio di
ogni run. Spento, un livello ricevuto ti permette solo di comprarlo. Serve Progressive System Upgrades.

#### System Install

`system_install` · `store`, `run_start`, `immediately` · predefinito `store`\
Quando un sistema di cui hai ricevuto il progetto sale a bordo gratis, se la nave ha una stanza per lui. `store`:
mai, lo compri come in FTL. `run_start`: all'inizio di ogni run, dal menu di inizio run. `immediately`: anche
appena il progetto arriva durante una run.

### Weapons, Drones, Augments, Crew (armi, droni, potenziamenti, equipaggio) *(chiuso)*

Cosa viene bloccato nei negozi di FTL, e l'equipaggio come oggetti.

#### Shop Weapons

`shop_weapons` · da 0 a 37 · predefinito `37`\
Quante delle 37 armi di FTL diventano oggetti. Le altre restano normali articoli dei negozi. 0 lascia stare le
armi.

#### Shop Drones

`shop_drones` · da 0 a 14 · predefinito `14`\
Lo stesso per i 14 droni. I droni hanno bisogno del Controllo droni per servire a qualcosa.

#### Shop Augments

`shop_augments` · da 0 a 23 · predefinito `23`\
Lo stesso per i 23 potenziamenti.

#### Weapon Bundle Size

`weapon_bundle_size` · da 1 a 5 · predefinito `3`\
Quante armi contiene ogni pacchetto di armi. Un pacchetto le sblocca tutte in una volta. 1 vuol dire niente
pacchetti: ogni arma è un oggetto a sé. Pacchetti più grandi vogliono dire meno oggetti, quindi un negozio
Archipelago più piccolo.

#### Drone Bundle Size

`drone_bundle_size` · da 1 a 5 · predefinito `2`\
Lo stesso per i droni.

#### Augment Bundle Size

`augment_bundle_size` · da 1 a 5 · predefinito `3`\
Lo stesso per i potenziamenti.

#### Shop Unlock Mode

`shop_unlock_mode` · `rarity_boost`, `locked` · predefinito `rarity_boost`\
Cosa cambia nei negozi di FTL quando ricevi un'arma, un drone o un potenziamento. `rarity_boost`: era già in
vendita, e ora compare molto più spesso. `locked`: non è in vendita da nessuna parte finché non lo ricevi. In
tutti e due i casi vale per tutte le run successive.

#### Shop Item Delivery

`shop_item_delivery` · `true` / `false` · predefinito `true`\
Ricevi anche una copia subito, una volta: a bordo se c'è uno slot libero, altrimenti nella stiva. Spento,
l'oggetto cambia solo cosa vendono i negozi.

#### Crew Members

`crew_members` · `true` / `false` · predefinito `true`\
I membri dell'equipaggio come oggetti, uno per razza, fino a tre copie. Prima copia: uno si unisce alla tua run.
Seconda: la razza entra nel menu di inizio run. Terza: quel menu offre un esperto con un'abilità al massimo.
Lanius e Crystal si fermano a due.

### Archipelago Shop (il negozio Archipelago) *(chiuso)*

I fari AP STORE, uno per settore, che vendono gli oggetti del multiworld in cambio di rottami.

#### Archipelago Shop Checks (minimum)

`shop_checks` · da 0 a 100 · predefinito `20`\
Il numero più piccolo di pacchi nel negozio, per tutto il seed. Se le tue opzioni creano più oggetti che check,
si aggiungono pacchi da soli (fino a 400) perché ogni oggetto abbia un posto. Più il negozio è grande, più pacchi
mostra ogni faro: 3, 6, 9 o 12.

#### Archipelago Shop by Sector

`shop_by_sector` · `true` / `false` · predefinito `false`\
Ogni pacco appartiene a un settore, da 1 a 7, ed è in vendita solo all'AP STORE di quel settore. I pacchi più
profondi costano di più, e la logica si aspetta che tu raggiunga prima quel settore.

#### Archipelago Shop per Ship

`shop_per_ship` · `off`, `per_class`, `per_layout` · predefinito `off`\
Ogni pacco appartiene a una nave (`per_class`) o a un layout (`per_layout`), ed è in vendita solo mentre la
piloti. Non aggiunge pacchi, li divide. Un pacco che non hai comprato torna più tardi.

#### Archipelago Shop Hints

`shop_hints` · `off`, `seen` · predefinito `seen`\
`seen`: i pacchi che vedi nel negozio diventano indizi, così i loro proprietari sanno dove aspetta il loro
oggetto. `off`: il negozio resta il tuo segreto.

#### Archipelago Shop Deal Scrap (%)

`shop_deal_scrap` · da 0 a 200 · predefinito `100`\
Quanti rottami pagano i patti e i patti di sangue del negozio, in percentuale. 0 li spegne.

### Runs *(chiuso)*

Cosa cambia dentro una run.

#### Head Starts

`head_starts` · `true` / `false` · predefinito `true`\
Gli oggetti Head Start danno un livello di sistema gratis, o una barra di reattore, all'inizio di ogni run
successiva. Prendono solo i check che restano quando tutti gli altri oggetti hanno il loro posto, quindi con le
opzioni predefinite ne arrivano pochi o nessuno.

#### Run Start Scrap (%)

`run_start_scrap` · da 0 a 100 · predefinito `0`\
Ogni nuova run parte con questa parte di tutti i rottami ricevuti come oggetti. Gli oggetti di rottami danno
comunque i loro rottami una volta all'arrivo. Da 10 a 25 è un buon intervallo.

#### Sector Skip

`sector_skip` · `true` / `false` · predefinito `false`\
Un layout che ha già raggiunto il settore successivo può saltare i settori da 1 a 4: il primo faro di un settore
così è un'uscita. Salta subito per 60 rottami e una scelta in più nel menu di inizio run, o esplora come al
solito. I check del settore saltato aspettano un'altra run.

#### Sector Locks

`sector_locks` · `true` / `false` · predefinito `false`\
Ogni layout ha bisogno dei Sector Pass per andare più lontano: il primo per lasciare il settore 4, il secondo per
lasciare il settore 7. Senza, l'uscita resta chiusa, e il gioco dice perché. Due oggetti per layout.

#### Event Beacons

`event_beacons` · `marked`, `important`, `hidden` · predefinito `important`\
Quali fari di evento Archipelago mostrano ARCHIPELAGO sulla mappa. L'AP STORE lo mostra sempre. `marked`: tutti
gli eventi. `important`: solo il relè e i pirati, che portano un pacco. `hidden`: nessuno.

#### Sector Logic

`sector_logic` · `none`, `standard`, `strict`, `power` · predefinito `standard`\
Cosa il generatore si aspetta dalla tua nave prima di mandarti lontano. Non cambia mai cosa il gioco ti lascia
fare.
- `none`: niente. Può capitare che tu debba raggiungere l'ammiraglia con pochissimo. Per giocatori esperti
  (`relaxed`, il suo vecchio nome, funziona ancora).
- `standard`: 2 progetti per il settore 4, 4 per il settore 6, 5 per l'ammiraglia.
- `strict`: 3 progetti per il settore 3, 6 per il settore 5, 9 per il settore 7, 11 per l'ammiraglia.
- `power`: guarda la nave che fa il check. Il settore 5 chiede 2 strati di scudo, il settore 8 anche Controllo
  armi 5, l'ammiraglia 3 strati, Controllo armi 6 e Motori 4.

#### Mod Language

`mod_language` · `game`, `english`, `french`, `spanish`, `german`, `italian`, `portuguese` · predefinito `game`\
La lingua dei menu e dei messaggi della mod. `game` segue FTL da sola. I nomi di oggetti e luoghi restano sempre
in inglese, perché tutti i giocatori e i tracker li condividono.

### Playing with Others (giocare con gli altri)

I collegamenti con gli altri giocatori. Tutti spenti di base.

#### Death Link

`death_link` · `true` / `false` · predefinito `false`\
Quando muori, muoiono anche gli altri che giocano con Death Link, e viceversa. Una morte ricevuta non distrugge
mai la tua nave e non uccide mai il tuo ultimo membro dell'equipaggio.

#### Death Link Trigger

`death_link_trigger` · `ship_destroyed`, `crew_death`, `both` · predefinito `both`\
Cosa manda la tua morte. `ship_destroyed`: solo una run persa, il meglio in un multiworld grande. `crew_death`:
qualsiasi membro dell'equipaggio perso. `both`: l'uno o l'altro. L'equipaggio muore spesso, quindi `both` ne
manda molte.

#### Death Link Cloned Crew

`death_link_cloned_crew` · `true` / `false` · predefinito `false`\
Se un membro dell'equipaggio che la baia di clonazione riporta indietro conta come morte. Spento, conta solo uno
che non torna.

#### Death Link Toggle

`death_link_toggle` · `true` / `false` · predefinito `true`\
Puoi spegnere e riaccendere Death Link durante la partita, cliccandoci sopra nella prima pagina del pannello TAB.
Spegni questa opzione per un gruppo che vuole restare legato fino alla fine.

#### Death Link Effect

`death_link_effect` · `major_incident`, `crew_member`, `hull_damage`, `fire`, `boarding`, `varied` · predefinito `major_incident`\
Cosa ti fa la morte di un altro giocatore. `major_incident`: una breccia e un incendio in una stanza di sistema,
il più duro. `crew_member`: muore un membro dell'equipaggio. `hull_damage`: danni allo scafo. `fire`: un
incendio. `boarding`: un Mantis nemico sale a bordo. `varied`: uno dei quattro più leggeri, a caso.

#### Energy Link

`energy_link` · `true` / `false` · predefinito `false`\
Una riserva di carburante condivisa con tutti i giocatori di Energy Link, qualunque sia il loro gioco. Il tuo
carburante in più ci entra ai fari tranquilli (con il 25 % di perdita), e ne ricevi un po' quando scendi sotto 3.

#### Trap Link

`trap_link` · `true` / `false` · predefinito `false`\
Le trappole sono condivise con gli altri giocatori di Trap Link: quando uno di voi riceve una trappola, anche gli
altri ne ricevono una, anche se il tuo seed non ne ha. Una trappola di un altro gioco diventa la trappola di FTL
più simile.

#### Trap Chance

`trap_chance` · da 0 a 100 · predefinito `0`\
La parte degli oggetti riempitivi che diventano trappole. Ce ne sono 11 tipi: incendio, breccia, perdita di
carburante, danni ai sistemi, flotta ribelle, danni allo scafo, abbordaggio, svuotamento dell'O2, e tre che
aspettano il tuo prossimo combattimento (una batteria anti-nave, un sovraccarico dell'ammiraglia, un pericolo).
Le trappole aspettano un faro tranquillo e non distruggono mai la tua nave.

#### Crew Names

`crew_names` · `vanilla`, `multiworld`, `multiworld_and_team` · predefinito `multiworld`\
I nomi dell'equipaggio che si unisce a te durante una run. `multiworld`: i nomi di slot degli altri giocatori,
poi quelli di FTL. `multiworld_and_team`: lo stesso, poi le persone che hanno fatto e testato la mod. `vanilla`:
i nomi di FTL. Il tuo equipaggio iniziale tiene i suoi nomi.

### Expert (solo YAML)

Queste opzioni non sono nel creatore di opzioni, solo nello YAML. Quasi nessuno ne ha bisogno.

#### Goal

`goal` · `victory_count`, `victory_selection` · predefinito `victory_count`\
`victory_count`: vincere con Victories Required layout diversi. `victory_selection`: vincere con ogni layout di
**Victory Layouts**, e solo con quelli.

#### Victory Layouts

`victory_layouts` · una lista · predefinito vuoto\
Con `victory_selection`, i layout che devono vincere ciascuno. Esempio:
`victory_layouts: ["Kestrel Cruiser A", "Mantis Cruiser B"]`. Devono essere nel seed.

#### Minimum Filler

`minimum_filler` · da 0 a 100 · predefinito `20`\
Il numero più piccolo di oggetti riempitivi nel tuo seed.

#### Shields, Sensors, Medbay blueprint logic

`shields_blueprint_logic`, `sensors_blueprint_logic`, `medbay_blueprint_logic` · `required`, `upgrade_only`, `start_with` · predefinito `upgrade_only`\
`required`: una nave che parte con quel sistema entra nella logica solo quando hai il suo progetto.
`upgrade_only`: il progetto serve solo per potenziare o comprare il sistema. `start_with`: parti con il progetto.

#### Engines, Weapon Control blueprint logic

`engines_blueprint_logic`, `weapons_blueprint_logic` · `anywhere`, `early`, `start_with` · predefinito `early`\
Ogni nave parte con questi due sistemi, quindi decidono solo quando arriva il progetto: ovunque, presto nei tuoi
primi check, o fin dall'inizio.

La [pagina del gioco](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
(in inglese) spiega più nel dettaglio la logica, le trappole e i collegamenti.
