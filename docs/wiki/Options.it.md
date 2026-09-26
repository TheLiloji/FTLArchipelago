# Opzioni

[English](Options.md) · [Français](Options.fr.md) · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
**Italiano** · [Português](Options.pt.md)

*Questa pagina è stata tradotta con l'IA e può contenere errori. In caso di dubbio, vale la pagina in inglese.*

## Il modo più semplice: tenere i valori predefiniti

Le opzioni predefinite sono quelle consigliate. Devi solo cambiare il tuo nome:

1. Apri **ArchipelagoOptionsCreator** (nella cartella di Archipelago), o la pagina delle opzioni del sito che
   ospita la partita.
2. Scegli **FTL: Faster Than Light**, scrivi il tuo nome ed esporta lo YAML.

Con i valori predefiniti vinci battendo l'ammiraglia **5 volte con 5 navi diverse, a Normale o Difficile**, e
raccogliendo **10 dei 12 Archivi** nascosti nei mondi degli altri giocatori. È una partita da più serate, circa
10 ore fino all'obiettivo.

Se il tuo gruppo gioca con il **Death Link**, attivalo. Di base anche la perdita di un membro dell'equipaggio
conta come una morte, non solo una partita persa.

## Preset

Vuoi qualcosa di più corto o più lungo? Scegli un preset rispondendo a due domande: quanto tempo hai, e conosci
bene FTL?

| | Nuovo su FTL | Conosci bene FTL |
|---|---|---|
| **FTL tra altri giochi**, sessioni brevi | `A1_multi_game_beginner` | `A2_multi_game_veteran` |
| **Due serate** | `C1_two_evenings_beginner` | `C2_two_evenings_veteran` |
| **Solo FTL**, una partita lunga | `B1_solo_beginner` | `B2_solo_veteran` |

Sono in `presets.zip` nella [pagina delle release](https://github.com/TheLiloji/FTLArchipelago/releases/latest),
e nel menu **Preset** della pagina delle opzioni del sito. In cima a ogni file c'è quanti check ha e quanto dura
più o meno. Cambia la riga `name:` ed è pronto.

## A cosa servono le opzioni

L'Options Creator le mostra in gruppi:

- **Goal**: quante vittorie, a quale difficoltà, e quanti Archivi.
- **Game Size**: quali versioni delle navi sono in partita, e cosa manda check (settori, sistemi, obiettivi,
  equipaggio, il negozio Archipelago). Meno check vuol dire una partita più corta.
- **Playing with Others**: Death Link, Energy Link (una riserva di carburante condivisa), Trap Link, e quante
  trappole.
- **Advanced** (chiuso all'inizio): la tua prima nave, gli oggetti Head Start, la lingua della mod (segue quella
  di FTL da sola), quali settori contano, come si sbloccano i Tipi B e C, cosa è bloccato nei negozi e quanto è
  severa la logica. Non serve toccarlo.

Ogni opzione ha una breve descrizione: passaci sopra col mouse nell'Options Creator. Le descrizioni sono in
inglese, come in tutto Archipelago.

## Opzioni per esperti

Alcune opzioni esistono solo nel file YAML, perché quasi nessuno ne ha bisogno: scegliere esattamente quali navi
devono vincere (`goal: victory_selection` con `victory_layouts`), il minimo di oggetti di riempimento, e le
cinque opzioni `*_blueprint_logic` che regolano la logica di scudi, sensori, infermeria, motori e armi. La lista
completa, con tutti i dettagli, è nella pagina del gioco (in inglese):
`apworld/ftl/docs/en_FTL Faster Than Light.md`.
