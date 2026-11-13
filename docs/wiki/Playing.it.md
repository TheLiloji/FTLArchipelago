# Giocare

[English](Playing.md) · [Français](Playing.fr.md) · [Deutsch](Playing.de.md) · [Español](Playing.es.md) ·
**Italiano** · [Português](Playing.pt.md)

Questa pagina segue una partita dall'inizio alla fine: la connessione, l'hangar, una run, i fari Archipelago, il
pannello e l'obiettivo. Se la mod non è ancora installata, comincia dalla guida di installazione
([Windows](Setup-Windows.it.md), [Linux](Setup-Linux.it.md)).

## La tua prima partita in cinque passi

1. Avvia FTL, compila il pannello in basso a sinistra del menu principale e premi **Connect**.
2. Rispondi **Use its own save** se la mod lo chiede, così questo seed ha il suo salvataggio di FTL.
3. Clicca su **Nuova partita**: l'hangar si apre sulla tua nave iniziale. Scegli la difficoltà che chiede il tuo
   seed e premi **START**.
4. Gioca come al solito. Raggiungere settori, vincere combattimenti, reclutare equipaggio e gli obiettivi mandano
   check. Quello che gli altri trovano per te arriva da solo.
5. Premi **TAB** quando vuoi per vedere il tuo obiettivo, cosa resta da fare e cosa hai ricevuto.

Perdere una run costa solo la run: tieni tutto quello che hai ricevuto, e la run successiva parte più forte.

## Connettersi

![Pannello di connessione](../images/connect-panel.jpg)

Nel menu principale, compila il pannello in basso a sinistra:

| Campo | Cosa scrivere |
|---|---|
| Address | il server, per esempio `archipelago.gg`, o l'IP di chi ospita |
| Port | il numero dopo i due punti nell'indirizzo della stanza, per esempio `38281` |
| Slot name | il `name:` del tuo YAML, esattamente come è scritto |
| Password | solo se la stanza ne ha una |

Premi **Connect** o **INVIO**. **TAB** passa da un campo all'altro. **Ctrl+V** incolla l'indirizzo copiato dalla
pagina della tua stanza (come `archipelago.gg:38281`) e compila indirizzo e porta in una volta.

- I campi vengono ricordati per la prossima volta. La password, mai.
- Spunta **Connect automatically on launch** e la mod si riconnette a ogni avvio di FTL.
- Se la connessione cade, la mod riprova da sola. I check fatti nel frattempo aspettano e partono appena il
  collegamento torna.

Una volta connesso, il pannello mostra i tuoi check e un pulsante **Disconnect**, e l'obiettivo compare in alto:

![Menu principale una volta connesso](../images/main-menu.jpg)

### "The seed has changed"

![La domanda del cambio di seed](../images/seed-change.jpg)

FTL sa sbloccare una nave ma mai bloccarla di nuovo. Per questo ogni seed ha il suo salvataggio di FTL. Quando
entri in un nuovo seed, la mod chiede prima. **Use its own save** riavvia FTL su un salvataggio nuovo per quel
seed, e quello vecchio resta esattamente com'era. **No, keep it** resta sul salvataggio attuale, offline.

Il pulsante **Saves** del pannello li elenca: uno per seed, più il solo, con i check e l'ultima volta che hai
giocato. **Load** riavvia FTL su quel salvataggio, run in corso compresa. **Archive** mette da parte un
salvataggio nella cartella `ap_profiles/archived`, non si cancella niente. Il tuo salvataggio di FTL senza
Archipelago non viene mai toccato.

![La finestra dei salvataggi Archipelago](../images/saves.png)

## L'hangar

![Navi bloccate](../images/hangar.jpg)

Si possono scegliere solo le navi che possiedi. Le altre restano bloccate finché non arriva la loro chiave, e le
navi nuove compaiono la prossima volta che torni nell'hangar, mai a metà di una run. I layout di tipo B e C sono
oggetti a sé (salvo che il tuo seed dica altro). Nella lista delle navi, un layout che il seed ha lasciato fuori
è segnato **NOT IN SEED**: non si sblocca mai.

L'hangar si apre sulla tua nave iniziale. **RANDOM SHIP** e le frecce **< >** passano tra le navi che possiedi.
FTL mostra sempre la Kestrel A, anche quando non può contare: senza la sua chiave (opzione `kestrel_key`) è
segnata **NO KEY**, e fuori dal seed **NOT IN SEED**. Su una nave così, **START** è grigio e viene rifiutato con
un breve motivo, così non parte mai una run che non conterebbe niente.

Premi **TAB** nell'hangar per aprire il pannello sulla pagina Navi: le navi con più check rimasti vengono prima, e
quelle senza niente da fare vanno in fondo. **U** o il pulsante mostra o nasconde le navi che non possiedi. È un
buon modo per scegliere la tua prossima nave.

FTL non può sbloccare navi da solo: la mod lo rifiuta, e blocca di nuovo al menu principale una nave che FTL ha
sbloccato prima. Se una è comunque giocabile, è segnata **NOT RECEIVED**, e una run con lei non conta niente, né
check né vittoria.

**Quale difficoltà?** Di base contano per l'obiettivo solo le vittorie a Normale e Difficile. Il menu principale
e il pannello dicono cosa chiede il tuo seed. Una vittoria più facile manda comunque il suo check di vittoria.

## Il menu di inizio run

![Il menu di inizio run](../images/start-menu.jpg)

Armi e droni esistono due volte tra gli oggetti (di base in pacchetti di 3 armi o 2 droni), e i membri
dell'equipaggio arrivano in fino a tre passi. Appena hai ricevuto una seconda copia di qualcosa, all'inizio di
ogni nuova run si apre un menu: scegli **un'arma, un drone e un membro dell'equipaggio** da tutto ciò che hai
raccolto, e vengono con te per quella run.

- Con **System Install** su `run_start`, lo stesso menu offre anche i sistemi di cui hai ricevuto il progetto:
  scegli quelli che vuoi, quanti sono le stanze libere della tua nave.
- Con **Sector Skip**, ogni settore saltato ti dà una scelta in più qui.

Clicca su **Done** per chiuderlo, o salta e basta: il menu resta solo fino al primo salto. Se esci dal gioco
prima di scegliere, è ancora lì quando continui. Torna all'inizio di ogni run, quindi una buona seconda copia vale
qualcosa ogni volta.

## Durante una run

![Oggetti che arrivano durante una run](../images/in-game.jpg)

### Cosa manda un check

A seconda delle tue opzioni:

- **raggiungere un settore** con un layout (la maggior parte dei check viene da qui);
- **battere l'ammiraglia** con un layout;
- **il primo membro dell'equipaggio di ogni razza** che si unisce a te;
- **gli obiettivi**, della nave o generali. Partono al salto successivo;
- **installare un sistema**, o ciascuno dei suoi livelli (Systemsanity);
- **vincere combattimenti**: i primi di una run, o di ogni settore;
- **la potenza del reattore** a 10, 15, 20 e 25;
- **comprare un pacco** nel negozio Archipelago, e i pacchi degli eventi del relè e dei pirati.

Il pannello (TAB) elenca tutti i check del tuo seed, e segna in blu quelli che puoi già fare.

### Cosa ricevi

Quello che ricevi arriva da solo, al prossimo faro tranquillo se sei in combattimento:

- una **chiave di nave** o un **layout**: nell'hangar la prossima volta;
- un **progetto di sistema**: i negozi ora possono vendere quel sistema (o sale a bordo gratis, con System
  Install);
- un oggetto **Progressive** di sistema: un livello di potenziamento in più permesso (o installato gratis, con
  Free Upgrades);
- un'**arma o un drone**, prima copia: uno viene messo a bordo (nella stiva se i tuoi slot sono pieni; se anche la
  stiva è piena, aspetta che tu faccia spazio) e compare più spesso nei negozi. Seconda copia: entra nel menu di
  inizio run;
- un **potenziamento**: uno viene messo a bordo e compare più spesso nei negozi (se i tuoi tre slot sono pieni,
  aspetta che uno si liberi);
- un **membro dell'equipaggio**: il primo si unisce alla tua run (o aspetta un posto libero), il secondo va nel
  menu di inizio run, il terzo fa di quella voce del menu un esperto con un'abilità al massimo;
- un **Head Start**: un livello di sistema o una barra di reattore gratis all'inizio di ogni run successiva;
- un **Sector Pass** (con Sector Locks): l'uscita del settore 4, poi del 7, si apre per quel layout;
- un **Archivio**: un passo più vicino all'obiettivo;
- **riempitivo** (rottami, carburante, missili, parti di drone, riparazione dello scafo) e, se il seed ne ha,
  **trappole**.

Quando arriva molto in una volta (il release di un altro giocatore, la fine della partita), armi e droni arrivano
quattro per faro; il resto segue ai salti successivi.

Delle note in basso a sinistra ti dicono cosa è arrivato e cosa è partito. Svaniscono dopo qualche secondo, e
tutto resta nel pannello.

### Le trappole

Una trappola non distrugge mai la tua nave: lascia almeno 3 di scafo e 2 di carburante, non spegne mai del tutto
un sistema, e aspetta un faro tranquillo. La nota dice quale trappola è e chi l'ha mandata.

| Trappola | Cosa succede |
|---|---|
| Fire | scoppia un incendio in una stanza |
| Hull Breach | si apre una breccia in una stanza |
| Fuel Leak | perdi carburante |
| System Damage | un sistema subisce danni |
| Rebel Fleet | la flotta ribelle avanza di un salto |
| Hull Damage | il tuo scafo perde qualche punto |
| Boarding Party | un nemico sale a bordo |
| O2 Drain | tutte le stanze perdono l'aria in una volta (mai se il tuo sistema dell'ossigeno è fuori uso) |
| Anti-Ship Battery | aspetta il tuo prossimo combattimento: una batteria planetaria ti spara durante lo scontro |
| Power Surge | aspetta il tuo prossimo combattimento: il nemico lancia un sovraccarico dell'ammiraglia (più leggero nei settori 1 e 2) |
| Hazard | aspetta il tuo prossimo combattimento: il faro riceve una nebulosa, una tempesta ionica, asteroidi, un sole o una pulsar |

Le ultime tre se ne vanno a fine combattimento, e ne scatta solo una per combattimento.

### Sector Skip e Sector Locks

Due opzioni cambiano la mappa, se il tuo seed le ha:

- **Sector Skip**: nei settori da 1 a 4, se questo layout ha già raggiunto il settore successivo in una run
  precedente, il primo faro è un'uscita. Salta subito per avere 60 rottami e una scelta in più nel menu di inizio
  run, o esplora come al solito. I check del settore saltato aspettano un'altra run.

  ![Sector Skip: il primo faro è un'uscita](../images/sector-skip.jpg)

- **Sector Locks**: l'uscita del settore 4 resta chiusa finché questo layout non ha il suo primo Sector Pass, e
  quella del settore 7 fino al secondo. Il faro d'uscita dice cosa manca, e si apre appena arriva il pass.

### L'ammiraglia

Con **Flagship Sabotage**, un messaggio ti avvisa quando l'ammiraglia arriva indebolita, e di quanto (scafo,
scudi, armi). La vittoria parte appena l'ammiraglia è distrutta.

## I fari Archipelago

![I fari Archipelago sulla mappa](../images/map.jpg)

Ogni settore ha un faro segnato **AP STORE**, con il negozio Archipelago, e altri fari nascondono gli eventi
della mod. Di base solo i due che portano un pacco (il relè e i pirati) sono segnati **ARCHIPELAGO** sulla
mappa; l'opzione **Event Beacons** può segnarli tutti o nessuno.

### Il negozio Archipelago

![Il negozio Archipelago](../images/shop.jpg)

Ogni pacco è un oggetto del multiworld. Il nome sotto dice per chi è; **FOR YOU** vuol dire uno dei tuoi oggetti.
Comprare un pacco lo manda subito:

![Un pacco mandato](../images/shop-sent.jpg)

Il riempitivo costa da 10 a 25 rottami, gli oggetti utili da 30 a 65, e quelli importanti da 70 a 150. Un pacco
mandato non torna mai. Ogni settore vende i suoi pacchi: il negozio del settore 5 ha altri pacchi rispetto a
quello del settore 2, e costano di più. Con **Archipelago Shop by Sector**, un pacco è in vendita solo nel suo
settore, e il negozio dice in quale settore sono i prossimi.

Di base, i pacchi che vedi diventano indizi per i loro proprietari: sanno dove aspetta il loro oggetto.

Il negozio vende anche dei **patti**: rottami subito, e in cambio scatta una trappola, due volte su tre su un
altro giocatore (con Trap Link), una volta su tre su di te. Senza Trap Link, sempre su di te. Quando tocca a te,
colpisce nel tuo prossimo combattimento, non al faro tranquillo del negozio. I **patti di sangue** della seconda
pagina pagano di più, e aggiungono una probabilità (5, 10 o 20 %) che uno dei tuoi membri dell'equipaggio muoia
per sempre, baia di clonazione o no. Non prendono mai il tuo ultimo membro dell'equipaggio.

![Patti di sangue nel negozio Archipelago](../images/blood-pacts.jpg)

### Gli eventi

- **Un relè** che trasporta pacchi per altri giocatori. Paga 15 rottami per inoltrarne uno.
- **Dei pirati con un pacco**, spesso quello di un amico. Pagali 20 rottami, o combattili e mandalo gratis se
  vinci.
- **Un posto di controllo zoltan** che vende 3 carburante per 15 rottami. Con Energy Link costa 20 e aggiunge 1
  carburante alla riserva condivisa, oppure puoi prendere carburante dalla riserva.
- **Uno Slug** che vende un vero indizio Archipelago per 20 rottami. Se non resta niente da indicare, ti ridà i
  rottami.
- **Un'ondata da un altro mondo**, che puoi assorbire o rimandare come trappola (con Trap Link).
- **Un tecnico engi** (settori engi e civili) che scommette 30 rottami di riuscire a overcloccare il tuo
  reattore. Paga 75 rottami se regge, e costa danni allo scafo e ai motori se no. Puoi anche fargli provare i
  motori per 3 carburante, o semplicemente andartene.
- **Un trafficante d'armi**, raro, nei settori pirata: un'arma a caso per 45 rottami, o un potenziamento a caso
  per 4 carburante.

| | |
|---|---|
| ![La scommessa dell'overclock engi](../images/event-overclock.jpg) | ![Il trafficante d'armi](../images/event-arms-dealer.jpg) |

Con **Archipelago Event Checks**, i pacchi del relè e dei pirati sono check a sé ("Archipelago Event 1", 2...)
prima di tornare a vendere i pacchi del negozio. Nessuno di questi eventi può nasconderti un check: sono un extra,
mai obbligatori.

## Giocare con gli altri: i collegamenti

Funzionano solo se il tuo YAML li ha attivati. La prima pagina del pannello mostra quali sono attivi.

- **Death Link**: quando muori, muoiono anche gli altri, e viceversa. Il tuo seed dice cosa conta come tua morte
  (una run persa, un membro dell'equipaggio perso, o entrambi). Una morte ricevuta fa qualcosa di brutto (di base
  una breccia e un incendio in una stanza di sistema) ma non distrugge mai la tua nave né uccide il tuo ultimo
  membro dell'equipaggio. Clicca su Death Link nella prima pagina del pannello per spegnerlo o riaccenderlo, se il
  tuo seed lo permette.
- **Energy Link**: una riserva di carburante condivisa con tutti i giocatori di Energy Link. Il tuo carburante in
  più ci entra ai fari tranquilli (il 25 % si perde per strada), e quando scendi sotto 3 carburante la tua nave ne
  riprende un po', una volta per faro. Il pannello mostra quanto c'è nella riserva.
- **Trap Link**: quando qualcuno riceve una trappola, anche gli altri ne ricevono una. Una trappola di un altro
  gioco diventa la trappola di FTL più simile ("Ice Trap" spegne un sistema, una trappola di fuoco accende un
  incendio...).

## Il pannello

Premi **TAB** in una run o nell'hangar. In una run il gioco va in pausa finché è aperto. **Sinistra** /
**Destra** o da **1** a **5** cambiano pagina, la rotella del mouse scorre, **Esc** o **TAB** lo chiude.

| | |
|---|---|
| ![Panoramica](../images/dashboard-links.jpg) | ![Navi](../images/dashboard-ships.png) |
| **1 Panoramica**: il tuo obiettivo e a che punto sei, i check fatti per categoria, i tuoi collegamenti (Death Link, Energy Link, Trap Link), questa run (combattimenti con check rimasti, rottami per la prossima run, potenziamenti gratis), gli ultimi oggetti ricevuti e i tuoi indizi. | **2 Navi**: ogni layout del seed, tuo o no, e quanti check gli restano. **U** mostra solo quelli che possiedi. |
| ![Sistemi](../images/dashboard-systems.png) | ![Check](../images/dashboard-checks.png) |
| **3 Sistemi**: quali progetti hai, quanti livelli di potenziamento hai ricevuto per ogni sistema, e gli Head Start dati all'inizio di ogni run. | **4 Check**: tutti i check del seed, per categoria e nave per nave. Fatti in verde, e una **linea blu** sotto quelli che puoi già fare con quello che hai. Passa sopra una casella per vedere cos'è, e cosa ha dato una volta fatta. |

![Diario](../images/dashboard-journal.png)

**5 Diario**: ogni oggetto ricevuto, chi l'ha mandato, e cosa c'era in ogni pacchetto, colorato secondo la sua
classe Archipelago (progressione verde, utile blu, trappola rosso, riempitivo grigio). A destra, i tuoi indizi:
cosa gli altri hanno trovato per te, e dove aspettano i tuoi oggetti nei loro mondi. Un indizio resta lì finché
l'oggetto non viene trovato.

La pagina Check ha anche gli obiettivi con le loro icone del gioco, le vittorie con l'immagine di ogni nave, e le
razze dell'equipaggio che hai reclutato.

![Gli obiettivi nella pagina dei check](../images/dashboard-achievements.jpg)

**Dove andare adesso?** Apri la pagina Check e cerca le linee blu sulla nave che piloti. Nella pagina Navi,
quelle con più check rimasti vengono prima.

## L'obiettivo

Batti l'ammiraglia con un certo numero di navi (o layout) **diversi**. Il menu principale e il pannello lo dicono
per intero, per esempio "sconfiggi l'ammiraglia 2 volte, un layout diverso per ogni vittoria", ed elencano le
navi con cui hai già vinto. Una seconda vittoria con la stessa nave manda comunque il suo check di vittoria, solo
non conta di nuovo per l'obiettivo.

Alcuni seed chiedono anche degli **Archivi**: oggetti sparsi nel multiworld, anche nel tuo mondo. Ti servono sia
le vittorie che abbastanza Archivi. L'obiettivo parte da solo appena ci sono entrambi, anche se l'ultimo Archivio
arriva mentre sei nel menu.

Alcuni seed chiedono vittorie a Normale o Difficile. Una vittoria più facile manda comunque il suo check, ma non
conta per l'obiettivo.

## Modalità solo

Niente server? Clicca su **Solo mode** nel pannello di connessione. Usa un vero seed generato e ti dà uno dei suoi
oggetti per check. È sempre lo stesso seed demo fornito con la mod, non il tuo YAML, quindi le tue opzioni non
valgono. I tuoi progressi sono tenuti nel suo salvataggio, quindi puoi fermarti e tornare più tardi.
**Stop solo** lo mette da parte, e cliccare di nuovo su **Solo mode** chiede se continuare o ricominciare.

## Buono a sapersi

- **Perdere una run costa solo la run.** Gli oggetti restano, e gli Head Start rendono più forte la run
  successiva.
- **Una run iniziata prima di connetterti non conta.** Connettiti prima, poi inizia una nuova partita. Lo stesso
  per una run salvata con un altro seed: "Continua" la riporta, ma non conta niente, e rottami, carburante e
  trappole ricevuti nel frattempo aspettano la tua prossima vera run.
- **Tornare su un seed già giocato** non ridà i suoi rottami, carburante e trappole una seconda volta. Navi,
  progetti e livelli di potenziamento tornano com'erano.
- **I check degli obiettivi partono al salto successivo**, e gli obiettivi ottenuti prima di Archipelago non
  contano: ottienili di nuovo.
- **"Raggiungere il settore 1" richiede un salto.** Un check parte quando arrivi da qualche parte.
- **Le trappole ricevute non distruggono mai la tua nave.** Lasciano almeno 3 di scafo e 2 di carburante, e
  aspettano un faro tranquillo.
- **Le morti ricevute** (Death Link) non prendono mai il tuo ultimo punto di scafo né il tuo ultimo membro
  dell'equipaggio.
- **Mandi una morte** (Death Link) quando perdi la run o un membro dell'equipaggio, secondo le opzioni del seed.
  Un membro che la baia di clonazione riporta indietro non è una morte, salvo che il seed le conti. Congedare un
  membro dalla schermata dell'equipaggio, o perdere un drone, non conta.
- **I nomi di oggetti e luoghi restano in inglese** qualunque sia la lingua, perché tutti i giocatori e i tracker
  li condividono. Solo le frasi intorno sono tradotte.

## Se qualcosa non funziona

Guarda prima le [FAQ](FAQ.md) (in inglese). Se non aiutano, chiedi sul [Discord](https://discord.gg/BVQnQu843Q) o
apri una [issue](https://github.com/TheLiloji/FTLArchipelago/issues) con il tuo `FTL_HS.log` (nella cartella di
FTL su Windows, nella sua cartella `data` su Linux).
