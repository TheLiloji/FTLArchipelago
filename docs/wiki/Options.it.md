# Opzioni

[English](Options.md) · [Français](Options.fr.md) · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
**Italiano** · [Português](Options.pt.md)

Le tue opzioni stanno in un piccolo file di testo, lo **YAML**. Lo prepari una volta, prima della partita, e lo
mandi alla persona che genera il multiworld.

**Giochi con Multiverse?** Vedi [Multiverse](Multiverse.it.md): l'installazione e cosa cambia nel tuo YAML.

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
| layout | una versione di una nave (« configurazione » nel gioco): Kestrel A, Kestrel B e Kestrel C sono tre layout |
| progressive | un oggetto che alza un sistema di un livello ogni volta che lo ricevi |
| Archivi | oggetti che ti servono oltre alle vittorie per finire |
| logica | ciò che il generatore presume tu abbia prima di chiederti un check |

## La via più semplice: scegliere un preset

I preset sono file YAML già pronti. Scegli quello adatto al tempo che hai:

| Preset | Tempo fino all'obiettivo | Cos'è |
|---|---|---|
| `first_game` | circa 3 h | **La tua prima partita Archipelago.** 1 vittoria, Facile conta, 3 navi di tipo A, 2 Archivi su 3, niente trappole. I potenziamenti e i sistemi ricevuti salgono a bordo da soli |
| `short_game` | circa 5 h | 2 vittorie a Normale o Difficile, 4 layout, 4 Archivi su 5, tutti i potenziamenti di un sistema in una volta |
| `medium_game` | circa 10 h | le opzioni predefinite: 5 vittorie a Normale o Difficile, 7 layout, 10 Archivi su 12 |
| `long_game` | 20 h o più | 10 vittorie, 14 layout, 16 Archivi su 20, installare un sistema è un check |

Sono in `presets.zip` sulla [pagina della release](https://github.com/TheLiloji/FTLArchipelago/releases/latest).
L'inizio di ogni file dice quanti check ha e quanto dura più o meno.

1. Apri il file in un editor di testo.
2. Sostituisci la riga `name:` con il tuo nome. Usa solo lettere senza accenti, cifre, spazi, `-` e `_`, e al
   massimo 16 caratteri: il pannello di connessione del gioco non sa scrivere altro.
3. Manda il file alla persona che genera il multiworld.

I tempi valgono per chi vince in poche partite. Se FTL è nuovo per te, conta di più.

## Creare il tuo YAML

Apri **ArchipelagoOptionsCreator** (nella cartella di Archipelago), scegli **FTL: Faster Than Light**, scrivi
il tuo nome ed esporta lo YAML. Ogni opzione ha una breve descrizione (in inglese): passaci sopra con il mouse.
I valori predefiniti sono quelli del preset `medium_game`.

Tre errori frequenti:

- **Vittorie a Facile.** Di base contano per l'obiettivo solo le vittorie a Normale e Difficile. Se giochi a
  Facile, metti **Victory Difficulty** su `any` (nello YAML va bene anche `easy`).
- **Meno check non vuol dire una partita più corta.** Disattivare settori o obiettivi non toglie i loro oggetti:
  passano nel negozio Archipelago, dove li compri con i rottami. Per accorciare una partita, abbassa piuttosto
  **Victories Required** e **Layouts in the Seed**.
- **Death Link.** Se il tuo gruppo ci gioca, attivalo. Con **Death Link Trigger** su `both` (predefinito), ogni
  membro dell'equipaggio perso uccide anche gli altri. In un multiworld grande o per una prima partita, scegli
  `ship_destroyed`: conta solo una partita persa.

## Cosa fanno le opzioni

L'Options Creator le mostra in gruppi:

- **Goal**: quante vittorie, a quale difficoltà, e quanti Archivi. Gli Archivi possono essere ovunque nel
  multiworld, anche nel tuo mondo.
- **Game Size**: quali layout ci sono nella partita e quanti, e cosa manda check: settori, sistemi, obiettivi,
  equipaggio, combattimenti vinti, il negozio Archipelago.
  **Excluded Ships and Layouts** toglie le navi o i layout che non vuoi mai pilotare.
- **Playing with Others**: Death Link, Energy Link (una riserva di carburante condivisa), Trap Link, e quante
  trappole.
- **Advanced** (chiuso all'inizio): non serve toccarlo. La tua prima nave, gli Head Start, la lingua della mod
  (segue FTL da sola), quali settori contano, come si sbloccano i tipi B e C, cosa è bloccato nei negozi, le
  opzioni qui sotto, e quanto è severa la logica.

Nei nomi compaiono due tipi di negozio. **Shop Weapons**, **Shop Drones**, **Shop Augments** e **Shop Unlock
Mode** riguardano i negozi di FTL. Le opzioni **Archipelago Shop** riguardano il negozio Archipelago: i pacchi
venduti ai beacon NEGOZIO AP, con oggetti di altri giocatori.

## Novità della 0.5

| Opzione | Cosa fa |
|---|---|
| **Free Upgrades** | I livelli di sistema ricevuti vengono installati gratis, subito e all'inizio di ogni partita. Solo con Progressive System Upgrades (attivo di base) |
| **System Install** | I sistemi di cui hai ricevuto il progetto salgono a bordo gratis: `run_start` all'inizio di ogni partita, `immediately` anche appena arriva il progetto. La nave deve avere una stanza per il sistema |
| **Run Start Scrap** | Ogni nuova partita inizia con questa percentuale di tutti i rottami ricevuti come oggetti. Tra 10 e 25 va bene |
| **Combat Checks per Ship** | Con ogni nave, i primi combattimenti vinti in una partita mandano check. Quei combattimenti danno meno rottami (**Combat Check Scrap**) |
| **Victory Collects the Layout** | Cosa manda in più una vittoria: `sectors` (predefinito) i check di settore del layout ancora da fare, `everything` anche gli obiettivi e i check di sistemi e di combattimenti della sua nave |
| **Sector Logic** | Nuovo valore `power`: prima dei settori lontani e della nave ammiraglia, la logica si aspetta strati di scudo, armi e motori sulla nave che fa il check |

## Opzioni per esperti

Alcune opzioni esistono solo nel file YAML, perché quasi nessuno ne ha bisogno: scegliere esattamente quali navi
devono vincere (`goal: victory_selection` con `victory_layouts`), il minimo di oggetti di riempimento, e le
cinque opzioni `*_blueprint_logic` che regolano la logica per scudi, sensori, infermeria, motori e armi.
L'elenco completo, con ogni dettaglio, è sulla
[pagina del gioco](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
(in inglese).
