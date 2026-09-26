# Opções

[English](Options.md) · [Français](Options.fr.md) · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
[Italiano](Options.it.md) · **Português**

*Esta página foi traduzida com IA e pode ter erros. Em caso de dúvida, vale a página em inglês.*

## O mais fácil: manter os valores padrão

As opções padrão são as recomendadas. Você só precisa mudar o seu nome:

1. Abra o **ArchipelagoOptionsCreator** (na pasta do Archipelago), ou a página de opções do site que hospeda a
   partida.
2. Escolha **FTL: Faster Than Light**, digite o seu nome e exporte o YAML.

Com os valores padrão, você vence derrotando a nave-mãe **5 vezes com 5 naves diferentes, no Normal ou
Difícil**, e juntando **10 dos 12 Arquivos** escondidos nos mundos dos outros jogadores. É uma partida de várias
noites, cerca de 10 horas até o objetivo.

Se o seu grupo joga com **Death Link**, ative. Por padrão, perder um tripulante também conta como uma morte, não
só perder a partida.

## Presets

Quer algo mais curto ou mais longo? Escolha um preset respondendo a duas perguntas: quanto tempo você tem, e
você conhece bem o FTL?

| | Novo no FTL | Você conhece bem o FTL |
|---|---|---|
| **FTL entre outros jogos**, sessões curtas | `A1_multi_game_beginner` | `A2_multi_game_veteran` |
| **Duas noites** | `C1_two_evenings_beginner` | `C2_two_evenings_veteran` |
| **Só FTL**, uma partida longa | `B1_solo_beginner` | `B2_solo_veteran` |

Eles estão em `presets.zip` na [página de releases](https://github.com/TheLiloji/FTLArchipelago/releases/latest),
e no menu **Preset** da página de opções do site. No topo de cada arquivo está quantos checks ele tem e quanto
tempo leva, mais ou menos. Mude a linha `name:` e pronto.

## O que as opções fazem

O Options Creator mostra as opções em grupos:

- **Goal**: quantas vitórias, em qual dificuldade, e quantos Arquivos.
- **Game Size**: quais versões das naves entram na partida, e o que envia checks (setores, sistemas,
  conquistas, tripulação, a loja Archipelago). Menos checks é uma partida mais curta.
- **Playing with Others**: Death Link, Energy Link (uma reserva de combustível compartilhada), Trap Link, e
  quantas armadilhas.
- **Advanced** (fechado no começo): sua primeira nave, os itens Head Start, o idioma do mod (ele segue o do FTL
  sozinho), quais setores contam, como os Tipos B e C são liberados, o que fica bloqueado nas lojas e o quanto a
  lógica é rígida. Você não precisa mexer.

Cada opção tem uma descrição curta: passe o mouse por cima no Options Creator. As descrições estão em inglês,
como em todo o Archipelago.

## Opções para especialistas

Algumas opções só existem no arquivo YAML, porque quase ninguém precisa delas: escolher exatamente quais naves
devem vencer (`goal: victory_selection` com `victory_layouts`), o mínimo de itens de preenchimento, e as cinco
opções `*_blueprint_logic` que ajustam a lógica de escudos, sensores, enfermaria, motores e armas. A lista
completa, com todos os detalhes, está na página do jogo (em inglês):
`apworld/ftl/docs/en_FTL Faster Than Light.md`.
