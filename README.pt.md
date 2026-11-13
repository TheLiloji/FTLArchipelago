<p align="center"><img src="docs/images/banner.png" alt="FTL Archipelago" width="620"></p>

<h1 align="center">FTL Archipelago</h1>

<p align="center">
<b>FTL: Faster Than Light</b> em um multiworld do <a href="https://archipelago.gg">Archipelago</a>.<br>
Suas naves, sistemas e armas estão escondidos nos jogos dos seus amigos. Os deles estão escondidos no seu.
</p>

<h3 align="center">Para o jogo base e para FTL: Multiverse <sup>beta</sup></h3>

<p align="center">
<a href="README.md">English</a> · <a href="README.fr.md">Français</a> · <a href="README.de.md">Deutsch</a> ·
<a href="README.es.md">Español</a> · <a href="README.it.md">Italiano</a> · <b>Português</b>
</p>

<p align="center">
<a href="https://github.com/TheLiloji/FTLArchipelago/releases/latest"><b>Baixar</b></a> ·
<a href="https://github.com/TheLiloji/FTLArchipelago/releases/tag/v0.6.0-mv.1"><b>Baixar para Multiverse</b></a><br>
Instalação: <a href="docs/wiki/Setup-Windows.pt.md">Windows</a> · <a href="docs/wiki/Setup-Linux.pt.md">Linux</a><br>
Guias: <a href="docs/wiki/Playing.pt.md">Jogar</a> · <a href="docs/wiki/Options.pt.md">Opções</a> · <a href="docs/wiki/FAQ.md">FAQ</a> · <a href="https://discord.gg/BVQnQu843Q">Discord</a>
</p>

<p align="center">Precisa de ajuda? Pergunte no <a href="https://discord.gg/BVQnQu843Q"><b>Discord</b></a>, ou abra uma
<a href="https://github.com/TheLiloji/FTLArchipelago/issues">issue</a> com o seu <code>FTL_HS.log</code>.</p>

> Sou francês. Esta página foi escrita em francês e depois traduzida para o português com IA.

| FTL: Faster Than Light | FTL: Multiverse <sup>beta</sup> |
|---|---|
| ![Menu principal](docs/images/main-menu.jpg) | ![Menu principal do Multiverse](docs/images/mv-main-menu.jpg) |
| 10 naves, 28 layouts, o jogo base inteiro | as 55 naves do Multiverse, o chapéu mágico, os finais e as missões como checks. [Mais](#ftl-multiverse-beta) |

## Como se joga

Você começa com uma nave e quase nada. As outras naves, os sistemas, as armas, os drones, os aumentos e a
tripulação estão espalhados pelo multiworld. Cada partida envia checks para os seus amigos: chegar a um setor,
vencer um combate, recrutar uma raça, uma conquista, a nau capitânia. O que eles encontram para você chega
sozinho, e perder uma partida custa só a partida.

| | |
|---|---|
| ![Naves bloqueadas no hangar](docs/images/hangar.jpg) | ![O menu de início de partida](docs/images/start-menu.jpg) |
| ![A loja do Archipelago](docs/images/shop.jpg) | ![AP STORE e beacons do Archipelago no mapa](docs/images/map.jpg) |

## Novidades da 0.6

- **Cada seed tem o seu próprio save**, e um botão Saves para trocar entre eles.
- **Combates, eventos e o seu reator** podem enviar checks.
- **Quatro armadilhas novas** (um perigo no beacon, uma bateria antinave, uma sobrecarga da nau capitânia, perda de
  oxigênio) e **dois eventos novos**.
- **Sector Skip, Sector Locks, Flagship Sabotage** e mais opções para mudar o ritmo de uma partida.
- **O painel conhece a lógica**: uma linha azul marca o que você já pode fazer.
- Um **preset para jogar sozinho**, e o **Multiverse** agora é um jogo à parte.

Todos os detalhes nas [notas da versão](https://github.com/TheLiloji/FTLArchipelago/releases/tag/v0.6.0).

## Tudo em uma tecla: o painel

Aperte **TAB**, durante uma partida ou no hangar. O jogo pausa e todo o seu jogo no multiworld aparece de uma vez:

- **O seu objetivo** e onde você está.
- **Cada check, nave por nave e setor por setor.** Uma linha azul marca os que você já pode fazer com o que tem,
  então você sempre sabe para onde ir.
- **Cada item recebido**, quem enviou e o que havia em cada pacote.
- **As suas dicas**: o que os outros encontraram para você, e onde os seus itens esperam nos mundos deles.
- **As conquistas** com os ícones do jogo, **as vitórias** com a imagem de cada nave, **as raças** recrutadas.
- **Os seus links**: Death Link, Trap Link e o combustível da reserva compartilhada do Energy Link.

| | |
|---|---|
| ![Visão geral do painel](docs/images/dashboard-links.jpg) | ![Os checks nave por nave](docs/images/dashboard-checks.png) |
| ![As suas naves](docs/images/dashboard-ships.png) | ![As conquistas na página de checks](docs/images/dashboard-achievements.jpg) |

## O que você vai encontrar

Cada setor tem uma **AP STORE** que vende pacotes para os outros jogadores, além de acordos e pactos de sangue:
sucata agora, uma armadilha ou um tripulante morto depois. Outros beacons escondem eventos do Archipelago:
piratas segurando um pacote, um Slug que vende dicas de verdade, um Engi que aposta que consegue forçar o seu
reator, um traficante de armas raro.

![Pactos de sangue na loja do Archipelago](docs/images/blood-pacts.jpg)

| | |
|---|---|
| ![A aposta do Engi](docs/images/event-overclock.jpg) | ![O traficante de armas](docs/images/event-arms-dealer.jpg) |

Com o **Sector Skip**, um setor que você já conhece começa em um beacon de saída: salte na hora para ganhar sucata
e uma escolha a mais no início da partida.

![Sector Skip: o primeiro beacon é uma saída](docs/images/sector-skip.jpg)

## Em números

| | |
|---|---|
| Naves | 10, com 28 layouts |
| Checks | cerca de 75 para um primeiro jogo, 150 por padrão, várias centenas com tudo ligado |
| Opções | mais de 70, e 5 presets de 3 horas a 20 ou mais |
| No jogo | 11 armadilhas, 7 eventos do Archipelago, uma AP STORE em cada setor |
| Idiomas | 6 |
| Com Multiverse | 55 naves, 18 raças, um chapéu mágico com 65 destinos |

Quer caos? Coloque isto no seu YAML e jogue com amigos:

```yaml
  trap_chance: 30
  trap_link: true
  death_link: true
```

Mais ideias e todas as opções na [página de opções](docs/wiki/Options.pt.md).

## Para começar

1. Baixe `ArchipelagoFTL.ftl` e a biblioteca Hyperspace da
   [release](https://github.com/TheLiloji/FTLArchipelago/releases) e siga a página de instalação para
   [Windows](docs/wiki/Setup-Windows.pt.md) ou [Linux](docs/wiki/Setup-Linux.pt.md).
2. Faça o seu YAML, ou use um [preset](presets). O host precisa de `ftl.apworld` e do Archipelago 0.6.7.
3. Abra o FTL, preencha o painel no canto inferior esquerdo e conecte. Sem servidor? Experimente o **modo solo**.

## FTL: Multiverse <sup>beta</sup>

O Archipelago também roda sobre o **FTL: Multiverse 5.5**, como um jogo à parte, **FTL Multiverse**
(`ftl_mv.apworld` e `FTLArchipelago-MV.ftl`, nas releases que terminam em `-mv`). Tem tudo do mod base, mais todas
as naves do Multiverse, o chapéu mágico para ir ao setor que você escolher, os finais e as missões de nave como
checks, e a AP STORE também nos setores secretos. Uma nave que começa sem Oxigênio ganha ele de presente.

| | |
|---|---|
| ![AP STORE e beacons do Archipelago em um mapa do Multiverse](docs/images/mv-sector-map.jpg) | ![Os destinos do chapéu mágico](docs/images/mv-magic-hat-secret.jpg) |
| ![As dezoito raças do Multiverse no painel](docs/images/dashboard-first-crew-mv.png) | ![Naves do Multiverse no painel](docs/images/mv-ships.jpg) |

Instale o Hyperspace, os dois zips do Multiverse (Assets, depois Data), depois `FTLArchipelago-MV.ftl` por último
no ftlman, e coloque `ftl_mv.apworld` em `custom_worlds`. Mais na
[página do Multiverse](https://github.com/TheLiloji/FTLArchipelago/blob/mv-next/docs/wiki/Multiverse.pt.md).

## Uso de IA

O FTL Archipelago foi feito com a ajuda de IA para:

- **a biblioteca Hyperspace** (`Hyperspace.dll` e os arquivos `.so`), que adiciona a camada de rede para o FTL
  conversar com o servidor do Archipelago
- **parte dos testes**, automáticos e partidas jogadas no Linux e no Windows antes de cada beta
- **as traduções**: tudo é escrito primeiro em francês e depois traduzido com IA. O inglês é revisado pela
  comunidade, o alemão pelo Yunus e o espanhol pelo Trapper444. Italiano e português ainda são só IA, correções
  são bem-vindas.

Assumo total responsabilidade pelo projeto e pelo seu código: entendo como tudo funciona, inclusive as partes em
que a IA ajudou, e eu mesmo mantenho, depuro e dou suporte.

## Obrigado

**Onde tudo começou.** Antes deste mod existir, **File_Missing** e **eto** já estavam levando o FTL ao Archipelago
com o [FTL Multiverse Archipelago](https://github.com/Filemissing/FTLMultiverseArchipelago). File_Missing começou
esse projeto e o Discord do FTL Archipelago, e eto pesquisou a API do Hyperspace. O
[FTL Manual](https://github.com/Et0san/Manual) do eto foi o ponto de partida dos itens e das locations deste mod.
Eles receberam este mod de braços abertos. Obrigado aos dois.

**Traduções e arte.** **Trapper444** pelo espanhol, pelo logo e pelo chapéu mágico do Multiverse, baseado no
ArchiHat dele. **Yunus** pelo alemão.

**Testes.** **Tom Regor**, por todos os testes e logs, pelos syncs que ele organiza, e por ideias como a armadilha
O2 Drain e o marcador de lógica. **Trapper444** e **Rhythm**, pelos testes do Multiverse e pelos relatos sobre
lógica e equilíbrio. **ottomaatti**, que pôs umas dez pessoas a jogar o mod numa LAN e me mandou um relato detalhado.

**Primeiros testers.** **Cigogne** e **SynthKat67**, que enfrentaram os primeiros problemas logo nos primeiros
dias (lojas vazias, renomear um tripulante disparava o Death Link), e **Astron**, presente desde o início com
muitos testes e retornos.

**Relatos de bugs.** **threeandthree** (TLS no Steam Linux), **Mulac** (loja bloqueada), **Richard99** (diário),
**Nowi** (Death Link), **Mrs. Maple** (GOG no Linux), **Jam** (armas inimigas fortes demais), **Wyndrose**,
**fletchy** e **Mongolico** (crashes e logs).

**No Discord do Archipelago.** **roobyroo**, pela recepção calorosa e pela ajuda com as regras.

**Ideias e ajuda.** **studkid**, pelas conversas de design (lógica, nomes da loja, saves) e pela ajuda aos
jogadores na instalação. **TheLegendaryDuck** pela ideia da armadilha de bateria antinave, que virou uma armadilha de verdade do mod, e
**Kholdstare** pelas ideias de desbloqueio por setor.

E todo mundo no Discord que joga, entra nos syncs de teste, relata bugs e vota nas ideias: este mod não seria o
que é sem vocês.

## Créditos

O primeiro design dos itens e das locations vem do [FTL Manual do Et0san](https://github.com/Et0san/Manual)
(MIT). Construído sobre o [FTL: Hyperspace](https://github.com/FTL-Hyperspace/FTL-Hyperspace) (CC-BY-SA 4.0).
Veja `apworld/ftl/LICENSE.md` e `mod/ArchipelagoFTL/CREDITS.md`.

Compilar a partir do código e rodar os testes: [docs/BUILDING.md](docs/BUILDING.md).
