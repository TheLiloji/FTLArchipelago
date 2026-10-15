# Opções

[English](Options.md) · [Français](Options.fr.md) · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
[Italiano](Options.it.md) · **Português**

As tuas opções cabem num pequeno ficheiro de texto, o **YAML**. Fazes-o uma vez, antes do jogo, e envias-o à
pessoa que gera o multiworld.

**Jogas com o Multiverse?** Vê [Multiverse](Multiverse.pt.md): a instalação e o que muda no teu YAML.

## Antes de começar

Precisas do **Archipelago 0.6.7**, com o `ftl.apworld` da
[página da release](https://github.com/TheLiloji/FTLArchipelago/releases/latest) na pasta `custom_worlds`. Sem
ele, o FTL não aparece na lista. Os guias de instalação ([Windows](Setup-Windows.pt.md),
[Linux](Setup-Linux.pt.md)) explicam cada passo.

## Algumas palavras que vais ver

| Palavra | Significado |
|---|---|
| check | algo que fazes no jogo e que envia um objeto: chegar a um setor, ganhar, uma conquista... |
| objeto (item) | o que um check dá a ti ou a outro jogador: uma nave, um sistema, uma arma, sucata... |
| seed | o jogo gerado, igual para todo o multiworld |
| slot | o teu lugar no multiworld, com o nome da linha `name:` do teu YAML |
| layout | uma versão de uma nave (« configuração » no jogo): Kestrel A, Kestrel B e Kestrel C são três layouts |
| progressive | um objeto que sobe um sistema um nível de cada vez que o recebes |
| Arquivos | objetos de que precisas além das vitórias para terminar |
| lógica | o que o gerador supõe que tens antes de te pedir um check |

## O mais simples: escolher um preset

Os presets são ficheiros YAML já feitos. Escolhe o que combina com o teu tempo:

| Preset | Tempo até ao objetivo | O que é |
|---|---|---|
| `first_game` | cerca de 3 h | **O teu primeiro jogo de Archipelago.** 1 vitória, Fácil conta, 3 naves do tipo A, 2 Arquivos em 3, sem armadilhas. As melhorias e os sistemas recebidos sobem a bordo sozinhos |
| `short_game` | cerca de 5 h | 2 vitórias em Normal ou Difícil, 4 layouts, 4 Arquivos em 5, todas as melhorias de um sistema de uma vez |
| `medium_game` | cerca de 10 h | as opções por omissão: 5 vitórias em Normal ou Difícil, 7 layouts, 10 Arquivos em 12 |
| `long_game` | 20 h ou mais | 10 vitórias, 14 layouts, 16 Arquivos em 20, instalar um sistema é um check |

Estão em `presets.zip` na [página da release](https://github.com/TheLiloji/FTLArchipelago/releases/latest). O
início de cada ficheiro diz quantos checks tem e quanto tempo demora, mais ou menos.

1. Abre o ficheiro num editor de texto.
2. Troca a linha `name:` pelo teu nome. Usa só letras sem acentos nem cedilha, algarismos, espaços, `-` e `_`, e
   16 caracteres no máximo: o painel de ligação do jogo não sabe escrever mais nada.
3. Envia o ficheiro à pessoa que gera o multiworld.

Os tempos valem para quem ganha em poucas partidas. Se o FTL é novo para ti, conta com mais.

## Fazer o teu próprio YAML

Abre o **ArchipelagoOptionsCreator** (na pasta do Archipelago), escolhe **FTL: Faster Than Light**, escreve o
teu nome e exporta o YAML. Cada opção tem uma descrição curta (em inglês): passa o rato por cima. Os valores por
omissão são os do preset `medium_game`.

Três erros frequentes:

- **Vitórias em Fácil.** Por omissão, só contam para o objetivo as vitórias em Normal e Difícil. Se jogas em
  Fácil, põe **Victory Difficulty** em `any` (no YAML também podes escrever `easy`).
- **Menos checks não quer dizer um jogo mais curto.** Desligar setores ou conquistas não retira os seus objetos:
  passam para a loja Archipelago, onde os compras com sucata. Para encurtar um jogo, baixa antes **Victories
  Required** e **Layouts in the Seed**.
- **Death Link.** Se o teu grupo joga com ele, liga-o. Com **Death Link Trigger** em `both` (por omissão), cada
  tripulante que perdes mata também os outros. Num multiworld grande ou num primeiro jogo, escolhe
  `ship_destroyed`: só conta uma partida perdida.

## O que fazem as opções

O Options Creator mostra-as em grupos:

- **Goal**: quantas vitórias, em que dificuldade, e quantos Arquivos. Os Arquivos podem estar em qualquer parte
  do multiworld, também no teu próprio mundo.
- **Game Size**: que layouts estão no jogo e quantos, e o que envia checks: setores, sistemas, conquistas,
  tripulação, combates ganhos, a loja Archipelago.
  **Excluded Ships and Layouts** retira as naves ou os layouts que nunca queres pilotar.
- **Playing with Others**: Death Link, Energy Link (uma reserva de combustível partilhada), Trap Link, e quantas
  armadilhas.
- **Advanced** (fechado no início): não precisas de mexer. A tua primeira nave, os Head Starts, a língua do mod
  (segue o FTL sozinha), que setores contam, como se desbloqueiam os tipos B e C, o que está bloqueado nas lojas,
  as opções abaixo, e quão exigente é a lógica.

Nos nomes aparecem dois tipos de loja. **Shop Weapons**, **Shop Drones**, **Shop Augments** e **Shop Unlock
Mode** são sobre as lojas do FTL. As opções **Archipelago Shop** são sobre a loja Archipelago: os pacotes
vendidos nos faróis LOJA AP, com objetos de outros jogadores.

## Novidades da 0.5

| Opção | O que faz |
|---|---|
| **Free Upgrades** | Os níveis de sistema recebidos são instalados de graça, logo e no início de cada partida. Só com Progressive System Upgrades (ligado por omissão) |
| **System Install** | Os sistemas cujo projeto recebeste sobem a bordo de graça: `run_start` no início de cada partida, `immediately` também assim que o projeto chega. A nave precisa de uma sala para ele |
| **Run Start Scrap** | Cada nova partida começa com esta percentagem de toda a sucata recebida em objetos. Entre 10 e 25 é um bom valor |
| **Combat Checks per Ship** | Com cada nave, os primeiros combates ganhos numa partida enviam checks. Esses combates dão menos sucata (**Combat Check Scrap**) |
| **Victory Collects the Layout** | O que uma vitória envia a mais: `sectors` (por omissão) os checks de setor do layout ainda por fazer, `everything` também as conquistas e os checks de sistemas e de combates da sua nave |
| **Sector Logic** | Novo valor `power`: antes dos setores distantes e da nave-almirante, a lógica espera camadas de escudo, armas e motores na nave que faz o check |

## Opções para especialistas

Algumas opções só existem no ficheiro YAML, porque quase ninguém precisa delas: escolher exatamente que naves
têm de ganhar (`goal: victory_selection` com `victory_layouts`), o mínimo de objetos de enchimento, e as cinco
opções `*_blueprint_logic` que afinam a lógica para escudos, sensores, enfermaria, motores e armas. A lista
completa, com todos os pormenores, está na
[página do jogo](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
(em inglês).
