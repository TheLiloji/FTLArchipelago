# Jogar com o Multiverse

[English](Multiverse.md) · [Français](Multiverse.fr.md) · [Deutsch](Multiverse.de.md) · [Español](Multiverse.es.md) ·
[Italiano](Multiverse.it.md) · **Português**

O mod também funciona com o **FTL: Multiverse 5.5.1**. As naves dele substituem as do jogo base, e os setores
dele também têm faróis ARCHIPELAGO. É o mesmo `ftl.apworld`: um jogador do Multiverse e um do jogo base podem
estar no mesmo multiworld.

## Instalação

Segue o guia de instalação ([Windows](Setup-Windows.pt.md), [Linux](Setup-Linux.pt.md)) com uma mudança: no
ftlman, marca os mods por esta ordem e depois clica em **Apply**.

1. Multiverse **Assets** (5.5)
2. Multiverse **Data** (5.5.1)
3. **ArchipelagoFTL**

Usa a versão Multiverse do mod: a release cujo nome acaba em `-mv`, como `v0.5.0-mv.1`. O Hyperspace continua
na 1.23.1, como no guia.

O Multiverse e o jogo base partilham o perfil do FTL. Se jogas os dois, ou várias seeds, guarda a pasta
`FasterThanLight` antes de trocar (vê «Proteger seus saves» no guia).

## O teu YAML

Liga **Multiverse**. No Options Creator é o primeiro grupo.

- Começas sempre com o **MV Kestrel Cruiser**: Starting Ship é ignorado.
- **Layouts in the Seed** escolhe entre as 55 naves do Multiverse e as suas configurações. Todas as outras naves
  chegam como objetos Archipelago, como no jogo base.
- **Victory Layouts** usa os nomes do Multiverse, como «Union Cruiser B». Uma nave com o mesmo nome de uma do jogo
  base escreve-se com «(MV)», como «Kestrel Cruiser (MV)».
- **Shop Weapons** e **Shop Drones** vão até 37 e 14: essa quantidade das 120 armas e 25 drones do Multiverse é
  sorteada e distribuída pelo Archipelago, e as restantes continuam à venda nas lojas. **Shop Augments** pode
  ficar com os 22 aumentos do Multiverse.
- **Multiverse Achievement Checks** junta 26 conquistas do Multiverse (Accomplishments e Special Events) como
  checks. Só têm enchimento ou armadilhas, porque algumas são longas ou raras.

As partidas do Multiverse são mais longas do que as do jogo base: conta com mais tempo do que dizem os presets.

## O que muda no jogo

- Os finais do Multiverse contam como vitórias, não só a nave-almirante.
- As variantes de uma raça no Multiverse (Zoltan Monk, Separatist Engi, Lanius Welder...) contam para o check
  dessa raça, assim como os tripulantes únicos dessa raça, como Turzil, o Engi. As raças próprias do
  Multiverse também têm o seu check (Crystal, Orchid, Shell, Leech, Phantom, Spider, Lizard). As raras (Cognitive,
  Siren, Pony, Obelisk) só têm enchimento: ali não te espera nada necessário.
- O objetivo, o painel (TAB) e a loja Archipelago funcionam da mesma forma. A página de naves do painel mostra sob cada nave a raça da maior parte da sua tripulação.
- Cada personagem do Multiverse que se junta à tua tripulação (Turzil, Tully...) dá uma dica grátis, uma vez por seed.
