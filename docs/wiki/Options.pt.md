# Opções

[English](Options.md) · [Français](Options.fr.md) · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
[Italiano](Options.it.md) · **Português**

As tuas opções cabem num pequeno ficheiro de texto, o **YAML**. Fazes-o uma vez, antes do jogo, e envias-o à
pessoa que gera o multiworld. Esta página explica cada opção, uma a uma. Não precisas de a ler toda: escolhe um
preset e volta aqui quando quiseres mudar alguma coisa.

**Jogas com o Multiverse?** Vê [Multiverse](Multiverse.pt.md): a instalação e o que muda no teu YAML.

## Antes de começar

Precisas do **Archipelago 0.6.7**, com o `ftl.apworld` da
[página da release](https://github.com/TheLiloji/FTLArchipelago/releases/latest) na sua pasta `custom_worlds`.
Sem ele, o FTL não aparece na lista. Os guias de instalação ([Windows](Setup-Windows.pt.md),
[Linux](Setup-Linux.pt.md)) explicam cada passo.

## Algumas palavras que vais ver

| Palavra | Significado |
|---|---|
| check | algo que fazes no jogo e que envia um objeto: chegar a um setor, ganhar, uma conquista... |
| objeto (item) | o que um check dá a ti ou a outro jogador: uma nave, um sistema, uma arma, sucata... |
| seed | o jogo gerado, igual para todo o multiworld |
| slot | o teu lugar no multiworld, com o nome da linha `name:` do teu YAML |
| layout | uma versão de uma nave (« configuração » no jogo): Kestrel A, Kestrel B e Kestrel C são três layouts. Há 28, em 10 naves |
| progressive | um objeto que sobe um sistema um nível de cada vez que o recebes |
| planta (blueprint) | o objeto que te deixa ter um sistema (Camuflagem, Controlo de drones...) |
| run | uma tentativa, do primeiro farol à vitória ou à destruição da nave |
| Arquivos | objetos de que precisas além das vitórias para terminar |
| enchimento (filler) | objetos pequenos: sucata, combustível, mísseis, peças de drone |
| armadilha (trap) | um objeto mau: um incêndio, uma brecha, a frota rebelde que avança... |
| lógica | o que o gerador supõe que tens antes de te pedir um check |
| AP STORE | a loja Archipelago, um farol por setor, que vende os objetos do multiworld |

## O mais simples: escolher um preset

Os presets são ficheiros YAML já feitos. Escolhe o que combina com o teu tempo:

| Preset | Tempo até ao objetivo | O que é |
|---|---|---|
| `first_game` | cerca de 3 h | **O teu primeiro jogo de Archipelago.** 1 vitória, Fácil conta, 3 naves do tipo A, 2 Arquivos em 3, sem armadilhas. As melhorias e os sistemas recebidos sobem a bordo sozinhos |
| `short_game` | cerca de 5 h | 2 vitórias em Normal ou Difícil, 4 layouts, 4 Arquivos em 5, todas as melhorias de um sistema de uma vez |
| `medium_game` | cerca de 10 h | as opções por omissão: 5 vitórias em Normal ou Difícil, 7 layouts, 10 Arquivos em 12 |
| `long_game` | 20 h ou mais | 10 vitórias, 14 layouts, 16 Arquivos em 20, instalar um sistema é um check |
| `solo_game` | cerca de 7 h | **Sozinho no multiworld.** 3 vitórias, 5 layouts, combates contados por setor, salto de setor e Sector Passes, mais checks de eventos |

Estão em `presets.zip` na [página da release](https://github.com/TheLiloji/FTLArchipelago/releases/latest). O
início de cada ficheiro diz quantos checks tem e quanto tempo leva mais ou menos.

1. Abre o ficheiro num editor de texto.
2. Troca a linha `name:` pelo teu nome. Usa só letras sem acentos, algarismos, espaços, `-` e `_`, e 16
   caracteres no máximo: o painel de ligação do jogo não sabe escrever mais nada.
3. Envia o ficheiro à pessoa que gera o multiworld (o guia dela, em inglês: [Hosting a seed](Hosting-a-seed.md)).

Os tempos são para quem ganha em poucas runs. Se o FTL é novo para ti, conta com mais.

## Fazer o teu próprio YAML

Abre o **ArchipelagoOptionsCreator** (na pasta do Archipelago), escolhe **FTL: Faster Than Light**, escreve o
teu nome e exporta o YAML. Cada opção tem uma descrição curta (em inglês): passa o rato por cima. Os valores por
omissão são os do preset `medium_game`.

Também podes mudar um preset à mão. Cada opção é uma linha: o nome YAML, dois pontos, o valor. Por exemplo:

```yaml
name: OMeuNome
game: "FTL: Faster Than Light"
requires:
  version: 0.6.7
"FTL: Faster Than Light":
  victories_required: 3
  start_ship: rock_cruiser
  trap_chance: 10
```

Mantém os dois espaços antes de cada opção. Uma opção que não escreves fica com o valor por omissão.

## Três erros frequentes

- **Vitórias em Fácil.** Por omissão só contam para o teu objetivo as vitórias em Normal e Difícil. Se jogas em
  Fácil, põe **Victory Difficulty** em `any` (no YAML também serve `easy`).
- **Menos checks não é um jogo mais curto.** Desligar setores ou conquistas não tira os seus objetos: passam para
  a loja Archipelago, onde os compras com sucata. Para encurtar um jogo, baixa antes **Victories Required** e
  **Layouts in the Seed**.
- **Death Link.** Se o teu grupo joga com ele, liga-o. Com **Death Link Trigger** em `both` (por omissão), cada
  tripulante que perdes mata também os outros. Num multiworld grande ou para um primeiro jogo, escolhe
  `ship_destroyed`: só conta uma run perdida.

## Ideias para o teu YAML

Um jogo mais curto, sem mexer no resto:

```yaml
  victories_required: 2
  layout_count: 4
  sectorsanity_last_sector: 6
```

Uma segunda nave cedo, e objetos recebidos que servem logo:

```yaml
  early_ship_keys: 3
  free_upgrades: true
  system_install: run_start
  run_start_scrap: 15
```

Mais coisas para fazer em cada run:

```yaml
  combat_checks: 1
  combat_checks_mode: per_sector
  reactor_checks: true
  systemsanity: first_install
```

Caos entre amigos:

```yaml
  trap_chance: 30
  trap_link: true
  death_link: true
```

Uma seed mais dura, para quem conhece bem o FTL:

```yaml
  victory_difficulty: hard
  sector_logic: none
  shop_unlock_mode: locked
  sector_locks: true
```

## Todas as opções, grupo a grupo

Os grupos são os do criador de opções. Cada opção mostra o seu nome no criador de opções (em inglês), o seu nome
no YAML, os valores possíveis e o valor por omissão. Os grupos marcados *fechado* estão recolhidos no início no
criador de opções: não precisas deles para um primeiro jogo.

### Goal (o objetivo)

O que tens de fazer para terminar.

#### Victories Required

`victories_required` · 1 a 28 · por omissão `5`\
Quantas vezes tens de derrotar a nave-almirante, de cada vez com um layout **diferente** (Kestrel A e Kestrel B
contam como dois). É a opção que decide quanto tempo dura o teu jogo: 1 ou 2 para um primeiro jogo, 5 entre
amigos, 10 para um jogo longo.

#### Victory Difficulty

`victory_difficulty` · `any`, `normal`, `hard` · por omissão `normal`\
A dificuldade mínima de uma vitória para contar para o teu objetivo. `any` (ou `easy`) conta todas as vitórias,
`normal` conta Normal e Difícil, `hard` só Difícil. Uma vitória mais fácil envia na mesma o seu check, só não
conta para o objetivo.

#### Flagship Sabotage

`flagship_sabotage` · 0 a 5 · por omissão `0`\
O multiworld enfraquece a nave-almirante. Cada nível junta algo, e vale para cada fase do combate: 1 é casco
-10 %, 2 junta escudos -1, 3 passa a casco -20 %, 4 junta armas -1, 5 passa a casco -30 %. Uma mensagem diz-te o
nível quando a nave-almirante chega. Bom para um grupo que quer acabar mais depressa.

#### Archives

`archives` · 0 a 50 · por omissão `12`\
Quantos Arquivos estão escondidos no multiworld, no teu mundo ou no dos outros. Os Arquivos são objetos de que
precisas além das vitórias. 0 joga sem eles.

#### Archives Required

`archives_required` · 0 a 50 · por omissão `10`\
Quantos Arquivos precisas para terminar. Mantém-no um pouco abaixo de **Archives**, para que um Arquivo mal
colocado não te possa bloquear. Se for mais alto do que Archives, são precisos todos.

#### Victory Collects the Layout

`victory_collects_layout` · `off`, `sectors`, `everything` · por omissão `sectors`\
O que uma vitória envia a mais, entre os checks desse layout que ainda não fizeste. `off`: só a vitória.
`sectors`: também todos os checks de setor desse layout. `everything`: também as conquistas da sua nave, os seus
checks de sistema e os seus checks de combate. Útil quando ganhas com uma nave e não queres voltar a ela por causa
do setor 3.

### Ships (as naves)

Que naves há no jogo e como as consegues.

#### Starting Ship

`start_ship` · uma das 10 naves · por omissão `kestrel_cruiser`\
A nave com que começas, no tipo A. Os seus tipos B e C encontram-se como os das outras. Os valores são
`kestrel_cruiser`, `engi_cruiser`, `federation_cruiser`, `zoltan_cruiser`, `mantis_cruiser`, `slug_cruiser`,
`rock_cruiser`, `stealth_cruiser`, `lanius_cruiser` e `crystal_cruiser` (ou só `rock`, `mantis`...).

#### Ship Layouts

`ship_layouts` · `type_a_only`, `up_to_type_b`, `all_layouts` · por omissão `all_layouts`\
Que layouts podem estar no jogo: só o tipo A, os tipos A e B, ou todos.

#### Layouts in the Seed

`layout_count` · 1 a 28 · por omissão `7`\
Quantos layouts podes pilotar nesta seed, no total. A tua nave inicial e o Kestrel A contam, por isso 7 são esses
dois mais outros 5, tirados à sorte entre os que **Ship Layouts** permite. Um tipo B ou C só vem com o tipo A da
sua nave. Os layouts deixados de fora não têm chave nem check, e o hangar marca-os **NOT IN SEED**. Sobe para
Victories Required se for mais baixo.

#### Excluded Ships and Layouts

`excluded_layouts` · uma lista · por omissão vazia\
As naves ou os layouts que nunca queres na seed. Indica uma nave inteira (`"Engi Cruiser"`) ou um layout
(`"Engi Cruiser B"`, ou `"Engi B"`). Tirar um tipo A tira a nave toda. A tua nave inicial e o Kestrel A não podem
ser tirados. Exemplo: `excluded_layouts: ["Stealth Cruiser", "Lanius Cruiser C"]`.

#### Layout Unlocks

`layout_unlocks` · `items`, `vanilla`, `independent`, `progressive` · por omissão `items`\
Como os tipos B e C ficam disponíveis.
- `items`: cada layout é um objeto próprio, e também precisas da chave da nave para o pilotar.
- `vanilla`: como no FTL, ganhando as conquistas dessa nave. Sem objetos de layout.
- `independent`: cada layout é um objeto próprio e não precisa de mais nada, nem sequer da chave da nave.
- `progressive`: sem objetos de layout. A chave da nave vem uma vez por layout: a primeira cópia dá o tipo A, as
  seguintes o tipo B, depois o C.

#### Early Ship Keys

`early_ship_keys` · 0 a 9 · por omissão `1`\
Quantas chaves de nave, além da tua nave inicial e do Kestrel, são postas nos teus próprios primeiros checks. Uma
segunda nave chega cedo em vez de horas depois. O número de chaves não muda, só onde caem. 0 deixa-as cair em
qualquer lado.

#### Kestrel Needs Its Key

`kestrel_key` · `true` / `false` · por omissão `false`\
Quando não começas com o Kestrel, o Kestrel A precisa da sua chave como qualquer outra nave. O FTL mostra-o na
mesma no hangar, mas está marcado **NO KEY** e o START recusa-o até a chave chegar. Desligado, o Kestrel A é
sempre teu.

### Checks

O que envia checks. A maior parte dos teus checks vem dos setores.

#### Sectorsanity

`sectorsanity` · `disabled`, `milestones`, `full` · por omissão `full`\
Chegar a um setor com um layout envia um check. Cada layout tem os seus: o Rock A no setor 4 não é o mesmo check
que o Rock B no setor 4. `full`: cada setor. `milestones`: só os setores 5 e 8. `disabled`: nunca.

#### Sectorsanity First Sector

`sectorsanity_first_sector` · 1 a 8 · por omissão `2`\
O primeiro setor que envia um check. Os setores antes não enviam nada. Com todos os layouts em jogo, os setores 1
e 2 sozinhos são 56 checks que consegues só por descolar: subi-lo é a forma mais simples de aliviar uma seed
grande.

#### Sectorsanity Last Sector

`sectorsanity_last_sector` · 1 a 8 · por omissão `8`\
O último setor que envia um check. Um check no setor 8 custa uma run inteira, um no setor 4 chega sozinho. 5 ou 6
mantém as mesmas naves mas corta o fim longo da seed, a parte em que os outros ficam à tua espera.

#### Systemsanity

`systemsanity` · `disabled`, `first_install`, `every_level` · por omissão `disabled`\
Instalar um sistema envia um check. `first_install`: uma vez por sistema, 12 checks (Motores, Oxigénio, Pilotagem
e Controlo de armas não têm, todas as naves começam com eles). `every_level`: também cada nível de melhoria, 64
checks, um jogo muito mais longo.

#### Systemsanity per Ship

`systemsanity_per_ship` · `true` / `false` · por omissão `false`\
Com Systemsanity ligado, cada nave tem os seus próprios checks de instalação, como "Kestrel Cruiser: Install
Cloaking". Nunca para um sistema com que essa nave começa.

#### Ship Achievement Checks

`ship_achievements` · `true` / `false` · por omissão `true`\
As três conquistas de cada nave enviam um check, 30 no total. O FTL dá-as à nave, não ao layout: ganhá-las com o
tipo A, B ou C envia o mesmo check.

#### General Achievement Checks

`general_achievements` · `disabled`, `basic`, `most`, `all` · por omissão `most`\
Quais das 21 conquistas gerais enviam um check. `basic`: as fáceis, como chegar ao setor 8. `most`: também as
mais difíceis, ganhas ao longo de uma run. `all`: todas, também as muito difíceis.

#### Cross-Run Achievement Checks

`cross_run_achievements` · `true` / `false` · por omissão `false`\
As três conquistas que não se podem ganhar numa só run: "Rule Ten: Greed is Eternal" (10 000 de sucata em todos
os teus jogos), "Warlord" (1000 naves destruídas) e "Your Own Fleet" (todas as naves desbloqueadas). Deixa
desligado para uma seed curta: as duas primeiras podem nunca acontecer.

#### Crew Checks

`crew_checks` · `true` / `false` · por omissão `true`\
O primeiro tripulante de cada raça que se junta a ti envia um check: Humano, Engi, Zoltan, Mantis, Rock, Slug e
Lanius. 7 checks. A tripulação com que começas uma run não conta.

#### Archipelago Event Checks

`event_checks` · 0 a 20 · por omissão `5`\
Os pacotes dos eventos do retransmissor e dos piratas passam a ser checks próprios, "Archipelago Event 1", 2...
até este número. Quando estão todos feitos, os eventos voltam a vender pacotes da loja Archipelago. 0: os eventos
só vendem os pacotes da loja.

#### Reactor Checks

`reactor_checks` · `true` / `false` · por omissão `false`\
Melhorar o reator envia checks com potência 10, 15, 20 e 25, em qualquer run. A lógica espera-os por volta dos
setores 2, 4, 6 e 7.

#### Combat Checks per Ship

`combat_checks` · 0 a 10 · por omissão `0`\
Ganhar combates envia checks. Com cada nave, os primeiros combates que ganhas numa run (inimigo destruído ou a sua
tripulação morta) enviam "Fight 1 won", "Fight 2 won"... até este número. 0 desliga-os.

#### Combat Checks Mode

`combat_checks_mode` · `per_run`, `per_sector` · por omissão `per_run`\
Como se contam os combates. `per_run`: os primeiros combates de uma run, como acima. `per_sector`: os primeiros
combates de **cada** setor enviam o seu próprio check ("Sector 3 fight 1 won"), até **Fights per Sector**, por
isso uma run até ao setor 8 pode enviar checks por todo o lado. Neste modo Combat Checks per Ship só tem de
estar acima de 0.

#### Fights per Sector

`fights_per_sector` · 1 a 5 · por omissão `2`\
Com `per_sector`: quantos combates em cada setor enviam um check, para cada nave.

#### Combat Check Scrap (%)

`combat_check_scrap` · 0 a 100 · por omissão `50`\
Um combate que envia um check só dá esta parte da sua sucata. Os mísseis, o combustível e as peças de drone
ficam. Os combates que não enviam nada mantêm a recompensa toda.

### Systems and Upgrades (sistemas e melhorias) *(fechado)*

Como os sistemas e os seus níveis são bloqueados e depois devolvidos.

#### System Blueprints

`system_blueprints` · `true` / `false` · por omissão `true`\
As plantas de sistemas são objetos. Sem a planta de um sistema, as lojas não o vendem. Um sistema com que a tua
nave começa nunca é tirado: fica no nível 1 até a planta chegar. Desligado, todos os sistemas estão à venda.

#### Progressive System Upgrades

`progressive_systems` · `true` / `false` · por omissão `true`\
Cada objeto "Progressive" sobe até onde podes melhorar um sistema, até ao máximo do FTL. Continuas a pagar a
sucata, exceto com Free Upgrades. Por omissão um objeto conta para todas as naves: "Progressive Shields" sobe os
escudos de todas. Desligado, os sistemas melhoram como no FTL.

#### Progressive Upgrades per Ship

`progressive_systems_per_ship` · `true` / `false` · por omissão `false`\
As melhorias pertencem cada uma a uma nave, como "Kestrel Cruiser: Progressive Shields", e só contam a bordo
dessa nave, seja qual for o layout. Muitos mais objetos, por isso uma loja Archipelago maior.

#### Progressive Unlocks the System

`progressive_unlocks_system` · `true` / `false` · por omissão `false`\
O primeiro objeto Progressive de um sistema também o desbloqueia, por isso esse sistema não tem um objeto de
planta à parte. Menos objetos à espera: os sistemas chegam mais cedo.

#### Full System Upgrades

`full_system_upgrades` · `true` / `false` · por omissão `false`\
Cada objeto Progressive dá todos os níveis do seu sistema de uma vez. Menos objetos, uma progressão menos fina.

#### Free Upgrades

`free_upgrades` · `true` / `false` · por omissão `false`\
Os níveis de sistema que recebes são instalados de graça: logo, se estás numa run, e outra vez no início de cada
run. Desligado, um nível recebido só te deixa comprá-lo. Precisa de Progressive System Upgrades.

#### System Install

`system_install` · `store`, `run_start`, `immediately` · por omissão `store`\
Quando um sistema cuja planta recebeste sobe a bordo de graça, se a nave tiver uma sala para ele. `store`: nunca,
compras como no FTL. `run_start`: no início de cada run, pelo menu de início de run. `immediately`: também assim
que a planta chega durante uma run.

### Weapons, Drones, Augments, Crew (armas, drones, aumentos, tripulação) *(fechado)*

O que é bloqueado nas lojas do próprio FTL, e a tripulação como objetos.

#### Shop Weapons

`shop_weapons` · 0 a 37 · por omissão `37`\
Quantas das 37 armas do FTL passam a ser objetos. As outras ficam artigos normais das lojas. 0 deixa as armas em
paz.

#### Shop Drones

`shop_drones` · 0 a 14 · por omissão `14`\
O mesmo para os 14 drones. Os drones precisam do Controlo de drones para servirem de alguma coisa.

#### Shop Augments

`shop_augments` · 0 a 23 · por omissão `23`\
O mesmo para os 23 aumentos.

#### Weapon Bundle Size

`weapon_bundle_size` · 1 a 5 · por omissão `3`\
Quantas armas tem cada lote de armas. Um lote desbloqueia todas de uma vez. 1 quer dizer sem lotes: cada arma é um
objeto próprio. Lotes maiores são menos objetos, por isso uma loja Archipelago mais pequena.

#### Drone Bundle Size

`drone_bundle_size` · 1 a 5 · por omissão `2`\
O mesmo para os drones.

#### Augment Bundle Size

`augment_bundle_size` · 1 a 5 · por omissão `3`\
O mesmo para os aumentos.

#### Shop Unlock Mode

`shop_unlock_mode` · `rarity_boost`, `locked` · por omissão `rarity_boost`\
O que muda nas lojas do FTL quando recebes uma arma, um drone ou um aumento. `rarity_boost`: já estava à venda, e
agora aparece muito mais vezes. `locked`: não está à venda em lado nenhum até o receberes. Nos dois casos vale
para todas as runs seguintes.

#### Shop Item Delivery

`shop_item_delivery` · `true` / `false` · por omissão `true`\
Também recebes uma cópia logo, uma vez: a bordo se houver um espaço livre, senão no porão. Desligado, o objeto só
muda o que as lojas vendem.

#### Crew Members

`crew_members` · `true` / `false` · por omissão `true`\
Os tripulantes como objetos, um por raça, até três cópias. Primeira cópia: um junta-se à tua run. Segunda: a raça
entra no menu de início de run. Terceira: esse menu oferece um especialista com uma competência no máximo. Lanius
e Crystal ficam pelas duas.

### Archipelago Shop (a loja Archipelago) *(fechado)*

Os faróis AP STORE, um por setor, que vendem os objetos do multiworld em troca de sucata.

#### Archipelago Shop Checks (minimum)

`shop_checks` · 0 a 100 · por omissão `20`\
O número mais pequeno de pacotes na loja, para a seed toda. Se as tuas opções criam mais objetos do que checks,
juntam-se pacotes sozinhos (até 400) para que cada objeto tenha um lugar. Quanto maior a loja, mais pacotes mostra
cada farol: 3, 6, 9 ou 12.

#### Archipelago Shop by Sector

`shop_by_sector` · `true` / `false` · por omissão `false`\
Cada pacote pertence a um setor, de 1 a 7, e só é vendido na AP STORE desse setor. Os pacotes mais fundos custam
mais, e a lógica espera que chegues primeiro a esse setor.

#### Archipelago Shop per Ship

`shop_per_ship` · `off`, `per_class`, `per_layout` · por omissão `off`\
Cada pacote pertence a uma nave (`per_class`) ou a um layout (`per_layout`), e só é vendido enquanto a pilotas.
Não junta pacotes, reparte-os. Um pacote que não compraste volta mais tarde.

#### Archipelago Shop Hints

`shop_hints` · `off`, `seen` · por omissão `seen`\
`seen`: os pacotes que vês na loja passam a ser dicas, assim os donos sabem onde o seu objeto espera. `off`: a
loja fica o teu segredo.

#### Archipelago Shop Deal Scrap (%)

`shop_deal_scrap` · 0 a 200 · por omissão `100`\
Quanta sucata pagam os pactos e os pactos de sangue da loja, em percentagem. 0 desliga-os.

### Runs *(fechado)*

O que muda dentro de uma run.

#### Head Starts

`head_starts` · `true` / `false` · por omissão `true`\
Os objetos Head Start dão um nível de sistema de graça, ou uma barra de reator, no início de cada run seguinte.
Só ocupam os checks que sobram quando todos os outros objetos têm o seu lugar, por isso com as opções por omissão
chegam poucos ou nenhum.

#### Run Start Scrap (%)

`run_start_scrap` · 0 a 100 · por omissão `0`\
Cada nova run começa com esta parte de toda a sucata que recebeste em objetos. Os objetos de sucata continuam a
dar a sua sucata uma vez ao chegarem. De 10 a 25 é um bom intervalo.

#### Sector Skip

`sector_skip` · `true` / `false` · por omissão `false`\
Um layout que já chegou ao setor seguinte pode saltar os setores 1 a 4: o primeiro farol de um setor assim é uma
saída. Salta logo por 60 de sucata e uma escolha a mais no menu de início de run, ou explora como de costume. Os
checks do setor saltado esperam por outra run.

#### Sector Locks

`sector_locks` · `true` / `false` · por omissão `false`\
Cada layout precisa de Sector Passes para ir mais longe: o primeiro para sair do setor 4, o segundo para sair do
setor 7. Sem eles a saída fica fechada, e o jogo diz porquê. Dois objetos por layout.

#### Event Beacons

`event_beacons` · `marked`, `important`, `hidden` · por omissão `important`\
Que faróis de evento Archipelago mostram ARCHIPELAGO no mapa. A AP STORE mostra sempre. `marked`: todos os
eventos. `important`: só o retransmissor e os piratas, que levam um pacote. `hidden`: nenhum.

#### Sector Logic

`sector_logic` · `none`, `standard`, `strict`, `power` · por omissão `standard`\
O que o gerador espera da tua nave antes de te mandar longe. Nunca muda o que o jogo te deixa fazer.
- `none`: nada. Pode ser-te pedido que chegues à nave-almirante com muito pouco. Para jogadores experientes
  (`relaxed`, o nome antigo, continua a funcionar).
- `standard`: 2 plantas para o setor 4, 4 para o setor 6, 5 para a nave-almirante.
- `strict`: 3 plantas para o setor 3, 6 para o setor 5, 9 para o setor 7, 11 para a nave-almirante.
- `power`: olha para a nave que faz o check. O setor 5 pede 2 camadas de escudo, o setor 8 também Controlo de
  armas 5, a nave-almirante 3 camadas, Controlo de armas 6 e Motores 4.

#### Mod Language

`mod_language` · `game`, `english`, `french`, `spanish`, `german`, `italian`, `portuguese` · por omissão `game`\
A língua dos menus e das mensagens do mod. `game` segue o FTL sozinho. Os nomes dos objetos e dos locais ficam
sempre em inglês, porque todos os jogadores e trackers os partilham.

### Playing with Others (jogar com os outros)

As ligações com os outros jogadores. Todas desligadas por omissão.

#### Death Link

`death_link` · `true` / `false` · por omissão `false`\
Quando morres, os outros que jogam com Death Link morrem também, e vice-versa. Uma morte recebida nunca destrói a
tua nave e nunca mata o teu último tripulante.

#### Death Link Trigger

`death_link_trigger` · `ship_destroyed`, `crew_death`, `both` · por omissão `both`\
O que envia a tua morte. `ship_destroyed`: só uma run perdida, o melhor num multiworld grande. `crew_death`:
qualquer tripulante perdido. `both`: um ou outro. A tripulação morre muitas vezes, por isso `both` envia muito.

#### Death Link Cloned Crew

`death_link_cloned_crew` · `true` / `false` · por omissão `false`\
Se um tripulante que a baía de clonagem traz de volta conta como morte. Desligado, só conta um que não volta.

#### Death Link Toggle

`death_link_toggle` · `true` / `false` · por omissão `true`\
Podes desligar e voltar a ligar o Death Link durante o jogo, clicando nele na primeira página do painel TAB.
Desliga esta opção para um grupo que quer ficar ligado até ao fim.

#### Death Link Effect

`death_link_effect` · `major_incident`, `crew_member`, `hull_damage`, `fire`, `boarding`, `varied` · por omissão `major_incident`\
O que te faz a morte de outro jogador. `major_incident`: uma brecha e um incêndio numa sala de sistema, o mais
duro. `crew_member`: morre um tripulante. `hull_damage`: dano no casco. `fire`: um incêndio. `boarding`: um Mantis
inimigo sobe a bordo. `varied`: um dos quatro mais leves, à sorte.

#### Energy Link

`energy_link` · `true` / `false` · por omissão `false`\
Uma reserva de combustível partilhada com todos os jogadores de Energy Link, seja qual for o jogo deles. O teu
combustível a mais entra nos faróis calmos (com 25 % de perda), e recebes algum quando desces abaixo de 3.

#### Trap Link

`trap_link` · `true` / `false` · por omissão `false`\
As armadilhas são partilhadas com os outros jogadores de Trap Link: quando um de vocês recebe uma armadilha, os
outros recebem uma também, mesmo que a tua seed não tenha. Uma armadilha de outro jogo passa a ser a armadilha do
FTL mais parecida.

#### Trap Chance

`trap_chance` · 0 a 100 · por omissão `0`\
A parte dos objetos de enchimento que passam a ser armadilhas. Há 11 tipos: incêndio, brecha, fuga de
combustível, dano de sistema, frota rebelde, dano no casco, abordagem, esvaziamento de O2, e três que esperam pelo
teu próximo combate (uma bateria antinave, uma sobrecarga da nave-almirante, um perigo). As armadilhas esperam por
um farol calmo e nunca destroem a tua nave.

#### Crew Names

`crew_names` · `vanilla`, `multiworld`, `multiworld_and_team` · por omissão `multiworld`\
Os nomes da tripulação que se junta a ti durante uma run. `multiworld`: os nomes de slot dos outros jogadores,
depois os do FTL. `multiworld_and_team`: o mesmo, depois as pessoas que fizeram e testaram o mod. `vanilla`: os
nomes do FTL. A tua tripulação inicial mantém os seus nomes.

### Expert (só YAML)

Estas opções não estão no criador de opções, só no YAML. Quase ninguém precisa delas.

#### Goal

`goal` · `victory_count`, `victory_selection` · por omissão `victory_count`\
`victory_count`: ganhar com Victories Required layouts diferentes. `victory_selection`: ganhar com cada layout de
**Victory Layouts**, e só com esses.

#### Victory Layouts

`victory_layouts` · uma lista · por omissão vazia\
Com `victory_selection`, os layouts que têm de ganhar cada um. Exemplo:
`victory_layouts: ["Kestrel Cruiser A", "Mantis Cruiser B"]`. Têm de estar na seed.

#### Minimum Filler

`minimum_filler` · 0 a 100 · por omissão `20`\
O número mais pequeno de objetos de enchimento na tua seed.

#### Shields, Sensors, Medbay blueprint logic

`shields_blueprint_logic`, `sensors_blueprint_logic`, `medbay_blueprint_logic` · `required`, `upgrade_only`, `start_with` · por omissão `upgrade_only`\
`required`: uma nave que começa com esse sistema só entra na lógica quando tens a sua planta. `upgrade_only`: a
planta só é precisa para melhorar ou comprar o sistema. `start_with`: começas com a planta.

#### Engines, Weapon Control blueprint logic

`engines_blueprint_logic`, `weapons_blueprint_logic` · `anywhere`, `early`, `start_with` · por omissão `early`\
Todas as naves começam com estes dois sistemas, por isso só decidem quando chega a planta: em qualquer lado, cedo
nos teus próprios primeiros checks, ou desde o início.

A [página do jogo](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
(em inglês) explica com mais pormenor a lógica, as armadilhas e as ligações.
