# Jogar

[English](Playing.md) · [Français](Playing.fr.md) · [Deutsch](Playing.de.md) · [Español](Playing.es.md) ·
[Italiano](Playing.it.md) · **Português**

Esta página segue um jogo do início ao fim: a ligação, o hangar, uma run, os faróis Archipelago, o painel e o
objetivo. Se o mod ainda não está instalado, começa pelo guia de instalação
([Windows](Setup-Windows.pt.md), [Linux](Setup-Linux.pt.md)).

## O teu primeiro jogo em cinco passos

1. Abre o FTL, preenche o painel em baixo à esquerda do menu principal e carrega em **Connect**.
2. Responde **Use its own save** se o mod perguntar, para que esta seed tenha o seu próprio jogo guardado do FTL.
3. Clica em **Novo jogo**: o hangar abre na tua nave inicial. Escolhe a dificuldade que a tua seed pede e carrega
   em **START**.
4. Joga como de costume. Chegar a setores, ganhar combates, recrutar tripulação e as conquistas enviam checks. O
   que os outros encontram para ti chega sozinho.
5. Carrega em **TAB** quando quiseres para ver o teu objetivo, o que falta fazer e o que recebeste.

Perder uma run só custa a run: ficas com tudo o que recebeste, e a run seguinte começa mais forte.

## Ligar-se

![Painel de ligação](../images/connect-panel.jpg)

No menu principal, preenche o painel em baixo à esquerda:

| Campo | O que escrever |
|---|---|
| Address | o servidor, por exemplo `archipelago.gg`, ou o IP de quem aloja |
| Port | o número depois dos dois pontos no endereço da sala, por exemplo `38281` |
| Slot name | o `name:` do teu YAML, exatamente como está escrito |
| Password | só se a sala tiver uma |

Carrega em **Connect** ou **ENTER**. **TAB** passa de um campo para outro. **Ctrl+V** cola o endereço copiado da
página da tua sala (como `archipelago.gg:38281`) e preenche o endereço e a porta de uma vez.

- Os campos ficam guardados para a próxima vez. A palavra-passe, nunca.
- Marca **Connect automatically on launch** e o mod volta a ligar-se sempre que o FTL abre.
- Se a ligação cair, o mod tenta outra vez sozinho. Os checks feitos entretanto esperam e saem assim que a
  ligação volta.

Uma vez ligado, o painel mostra os teus checks e um botão **Disconnect**, e o objetivo aparece em cima:

![Menu principal depois de ligado](../images/main-menu.jpg)

### "The seed has changed"

![A pergunta da mudança de seed](../images/seed-change.jpg)

O FTL sabe desbloquear uma nave mas nunca voltar a bloqueá-la. Por isso cada seed tem o seu próprio jogo guardado
do FTL. Quando entras numa seed nova, o mod pergunta primeiro. **Use its own save** reinicia o FTL num jogo
guardado novo para essa seed, e o antigo fica exatamente como estava. **No, keep it** fica no jogo guardado
atual, sem ligação.

O botão **Saves** do painel lista-os: um por seed, mais o modo solo, com os checks e a última vez que jogaste.
**Load** reinicia o FTL nesse jogo guardado, run em curso incluída. **Archive** põe um jogo guardado de lado na
pasta `ap_profiles/archived`, nada é apagado. O teu jogo guardado do FTL sem Archipelago nunca é tocado.

![A janela dos jogos guardados Archipelago](../images/saves.png)

## O hangar

![Naves bloqueadas](../images/hangar.jpg)

Só podes escolher as naves que tens. As outras ficam bloqueadas até a chave chegar, e as naves novas aparecem da
próxima vez que voltas ao hangar, nunca a meio de uma run. Os layouts do tipo B e C são objetos à parte (a não ser
que a tua seed diga outra coisa). Na lista de naves, um layout que a seed deixou de fora está marcado
**NOT IN SEED**: nunca é desbloqueado.

O hangar abre na tua nave inicial. **RANDOM SHIP** e as setas **< >** passam pelas naves que tens. O FTL mostra
sempre o Kestrel A, mesmo quando não pode contar: sem a sua chave (opção `kestrel_key`) está marcado **NO KEY**, e
fora da seed **NOT IN SEED**. Numa nave assim, o **START** fica cinzento e é recusado com uma razão curta, para
que nunca comece uma run que não contaria para nada.

Carrega em **TAB** no hangar para abrir o painel na página Naves: as naves com mais checks por fazer aparecem
primeiro, e as que já não têm nada vão para o fim. **U** ou o botão mostra ou esconde as naves que não tens. É uma
boa maneira de escolher a tua próxima nave.

O FTL não pode desbloquear naves sozinho: o mod recusa, e volta a bloquear no menu principal uma nave que o FTL
desbloqueou antes. Se alguma for jogável na mesma, está marcada **NOT RECEIVED**, e uma run com ela não conta para
nada, nem checks nem vitória.

**Que dificuldade?** Por omissão só contam para o objetivo as vitórias em Normal e Difícil. O menu principal e o
painel dizem o que a tua seed pede. Uma vitória mais fácil envia na mesma o seu check de vitória.

## O menu de início de run

![O menu de início de run](../images/start-menu.jpg)

As armas e os drones existem duas vezes entre os objetos (por omissão em lotes de 3 armas ou 2 drones), e os
tripulantes chegam em até três passos. Assim que recebeste uma segunda cópia de alguma coisa, abre-se um menu
logo no início de cada nova run: escolhe **uma arma, um drone e um tripulante** de tudo o que juntaste, e vêm
contigo nessa run.

- Com **System Install** em `run_start`, o mesmo menu também oferece os sistemas cuja planta recebeste: escolhe
  os que quiseres, tantos quantas as salas livres da tua nave.
- Com **Sector Skip**, cada setor que saltas dá mais uma escolha aqui.

Clica em **Done** para o fechar, ou salta simplesmente: o menu só fica até ao primeiro salto. Se sais do jogo
antes de escolher, ele continua lá quando continuas. Volta no início de cada run, por isso uma boa segunda cópia
vale alguma coisa de cada vez.

## Durante uma run

![Objetos que chegam durante uma run](../images/in-game.jpg)

### O que envia um check

Conforme as tuas opções:

- **chegar a um setor** com um layout (a maior parte dos checks vem daqui);
- **derrotar a nave-almirante** com um layout;
- **o primeiro tripulante de cada raça** que se junta a ti;
- **as conquistas**, da nave ou gerais. Saem no salto seguinte;
- **instalar um sistema**, ou cada um dos seus níveis (Systemsanity);
- **ganhar combates**: os primeiros de uma run, ou de cada setor;
- **a potência do reator** em 10, 15, 20 e 25;
- **comprar um pacote** na loja Archipelago, e os pacotes dos eventos do retransmissor e dos piratas.

O painel (TAB) lista todos os checks da tua seed, e marca a azul os que já podes fazer.

### O que recebes

O que recebes chega sozinho, no próximo farol calmo se estiveres em combate:

- uma **chave de nave** ou um **layout**: no hangar da próxima vez;
- uma **planta de sistema**: as lojas já podem vender esse sistema (ou sobe a bordo de graça, com System
  Install);
- um objeto **Progressive** de sistema: mais um nível de melhoria permitido (ou instalado de graça, com Free
  Upgrades);
- uma **arma ou drone**, primeira cópia: um vai para bordo (para o porão se os teus espaços estiverem cheios; se o
  porão também estiver cheio, espera que faças espaço) e aparece mais vezes nas lojas. Segunda cópia: entra no
  menu de início de run;
- um **aumento**: um vai para bordo e aparece mais vezes nas lojas (se os teus três espaços estiverem cheios,
  espera que um fique livre);
- um **tripulante**: o primeiro junta-se à tua run (ou espera por um lugar livre), o segundo vai para o menu de
  início de run, o terceiro faz dessa entrada do menu um especialista com uma competência no máximo;
- um **Head Start**: um nível de sistema ou uma barra de reator de graça no início de cada run seguinte;
- um **Sector Pass** (com Sector Locks): a saída do setor 4, depois a do 7, abre-se para esse layout;
- um **Arquivo**: um passo mais perto do objetivo;
- **enchimento** (sucata, combustível, mísseis, peças de drone, reparação do casco) e, se a seed tiver,
  **armadilhas**.

Quando chega muita coisa de uma vez (o release de outro jogador, o fim do jogo), as armas e os drones chegam
quatro por farol; o resto segue nos saltos seguintes.

Notas em baixo à esquerda dizem-te o que chegou e o que saiu. Desaparecem depois de alguns segundos, e tudo fica
no painel.

### As armadilhas

Uma armadilha nunca destrói a tua nave: deixa pelo menos 3 de casco e 2 de combustível, nunca desliga um sistema
por completo, e espera por um farol calmo. A nota diz que armadilha é e quem a enviou.

| Armadilha | O que acontece |
|---|---|
| Fire | começa um incêndio numa sala |
| Hull Breach | abre-se uma brecha numa sala |
| Fuel Leak | perdes combustível |
| System Damage | um sistema sofre dano |
| Rebel Fleet | a frota rebelde avança um salto |
| Hull Damage | o teu casco perde alguns pontos |
| Boarding Party | um inimigo sobe a bordo |
| O2 Drain | todas as salas perdem o ar de uma vez (nunca se o teu sistema de oxigénio estiver em baixo) |
| Anti-Ship Battery | espera pelo teu próximo combate: uma bateria planetária dispara contra ti durante o combate |
| Power Surge | espera pelo teu próximo combate: o inimigo lança uma sobrecarga da nave-almirante (mais leve nos setores 1 e 2) |
| Hazard | espera pelo teu próximo combate: o farol recebe uma nebulosa, uma tempestade iónica, asteroides, um sol ou um pulsar |

As três últimas vão-se embora no fim do combate, e só dispara uma por combate.

### Sector Skip e Sector Locks

Duas opções mudam o mapa, se a tua seed as tiver:

- **Sector Skip**: nos setores 1 a 4, se este layout já chegou ao setor seguinte numa run anterior, o primeiro
  farol é uma saída. Salta logo para ganhar 60 de sucata e mais uma escolha no menu de início de run, ou explora
  como de costume. Os checks do setor saltado esperam por outra run.

  ![Sector Skip: o primeiro farol é uma saída](../images/sector-skip.jpg)

- **Sector Locks**: a saída do setor 4 fica fechada até este layout ter o seu primeiro Sector Pass, e a do setor 7
  até ao segundo. O farol de saída diz o que falta, e abre-se assim que o passe chega.

### A nave-almirante

Com **Flagship Sabotage**, uma mensagem avisa-te quando a nave-almirante chega enfraquecida, e quanto (casco,
escudos, armas). A vitória sai assim que a nave-almirante é destruída.

## Os faróis Archipelago

![Os faróis Archipelago no mapa](../images/map.jpg)

Cada setor tem um farol marcado **AP STORE**, com a loja Archipelago, e outros faróis escondem os eventos do
próprio mod. Por omissão só os dois que levam um pacote (o retransmissor e os piratas) estão marcados
**ARCHIPELAGO** no mapa; a opção **Event Beacons** pode marcá-los todos ou nenhum.

### A loja Archipelago

![A loja Archipelago](../images/shop.jpg)

Cada pacote é um objeto do multiworld. O nome por baixo diz para quem é; **FOR YOU** quer dizer um dos teus
próprios objetos. Comprar um pacote envia-o logo:

![Um pacote enviado](../images/shop-sent.jpg)

O enchimento custa de 10 a 25 de sucata, os objetos úteis de 30 a 65, e os importantes de 70 a 150. Um pacote
enviado nunca volta. Cada setor vende os seus próprios pacotes: a loja do setor 5 tem outros pacotes que a do
setor 2, e custam mais. Com **Archipelago Shop by Sector**, um pacote só é vendido no seu setor, e a loja diz em
que setor estão os seguintes.

Por omissão, os pacotes que vês passam a ser dicas para os donos: sabem onde o seu objeto espera.

A loja também vende **pactos**: sucata logo, e em troca dispara uma armadilha, duas vezes em três noutro jogador
(com Trap Link), uma vez em três em ti. Sem Trap Link, és sempre tu. Quando és tu, atinge-te no próximo combate,
não no farol calmo da loja. Os **pactos de sangue** da segunda página pagam mais, e juntam uma probabilidade (5,
10 ou 20 %) de um dos teus tripulantes morrer de vez, com baía de clonagem ou sem ela. Nunca levam o teu último
tripulante.

![Pactos de sangue na loja Archipelago](../images/blood-pacts.jpg)

### Os eventos

- **Um retransmissor** que leva pacotes para outros jogadores. Paga 15 de sucata para reencaminhar um.
- **Piratas com um pacote**, muitas vezes o de um amigo. Paga-lhes 20 de sucata, ou luta contra eles e envia-o de
  graça se ganhares.
- **Um posto de controlo zoltan** que vende 3 de combustível por 15 de sucata. Com Energy Link custa 20 e junta 1
  de combustível à reserva partilhada, ou podes tirar combustível da reserva em vez disso.
- **Um Slug** que vende uma dica Archipelago verdadeira por 20 de sucata. Se não houver mais nada para indicar,
  devolve-te a sucata.
- **Uma onda vinda de outro mundo**, que podes absorver ou reenviar como armadilha (com Trap Link).
- **Um técnico engi** (setores engi e civis) que aposta 30 de sucata em como consegue fazer overclock ao teu
  reator. Paga 75 de sucata se aguentar, e custa dano no casco e nos motores se não. Também o podes deixar testar
  os motores por 3 de combustível, ou simplesmente ir embora.
- **Um traficante de armas**, raro, em setores piratas: uma arma à sorte por 45 de sucata, ou um aumento à sorte
  por 4 de combustível.

| | |
|---|---|
| ![A aposta do overclock engi](../images/event-overclock.jpg) | ![O traficante de armas](../images/event-arms-dealer.jpg) |

Com **Archipelago Event Checks**, os pacotes do retransmissor e dos piratas são checks próprios ("Archipelago
Event 1", 2...) antes de voltarem a vender os pacotes da loja. Nenhum destes eventos te pode esconder um check:
são um extra, nunca obrigatórios.

## Jogar com os outros: as ligações

Só funcionam se o teu YAML as ligou. A primeira página do painel mostra quais estão ativas.

- **Death Link**: quando morres, os outros morrem também, e vice-versa. A tua seed diz o que conta como a tua
  morte (uma run perdida, um tripulante perdido, ou os dois). Uma morte recebida faz algo mau (por omissão uma
  brecha e um incêndio numa sala de sistema) mas nunca destrói a tua nave nem mata o teu último tripulante. Clica
  em Death Link na primeira página do painel para o desligar ou voltar a ligar, se a tua seed o permitir.
- **Energy Link**: uma reserva de combustível partilhada com todos os jogadores de Energy Link. O teu combustível
  a mais entra nos faróis calmos (perdem-se 25 % pelo caminho), e quando desces abaixo de 3 de combustível a tua
  nave tira algum, uma vez por farol. O painel mostra quanto há na reserva.
- **Trap Link**: quando alguém recebe uma armadilha, os outros recebem uma também. Uma armadilha de outro jogo
  passa a ser a armadilha do FTL mais parecida ("Ice Trap" desliga um sistema, uma armadilha de fogo começa um
  incêndio...).

## O painel

Carrega em **TAB** numa run ou no hangar. Numa run o jogo fica em pausa enquanto está aberto. **Esquerda** /
**Direita** ou **1** a **5** mudam de página, a roda do rato faz scroll, **Esc** ou **TAB** fecha-o.

| | |
|---|---|
| ![Resumo](../images/dashboard-links.jpg) | ![Naves](../images/dashboard-ships.png) |
| **1 Resumo**: o teu objetivo e como vais, os checks feitos por categoria, as tuas ligações (Death Link, Energy Link, Trap Link), esta run (combates com check que faltam, sucata para a próxima run, melhorias de graça), os últimos objetos recebidos e as tuas dicas. | **2 Naves**: cada layout da seed, teu ou não, e quantos checks lhe faltam. **U** mostra só os que tens. |
| ![Sistemas](../images/dashboard-systems.png) | ![Checks](../images/dashboard-checks.png) |
| **3 Sistemas**: que plantas tens, quantos níveis de melhoria recebeste para cada sistema, e os Head Starts dados no início de cada run. | **4 Checks**: todos os checks da seed, por categoria e nave a nave. Feitos a verde, e uma **linha azul** por baixo dos que já podes fazer com o que tens. Passa o rato por uma casa para ver o que é, e o que deu depois de feita. |

![Diário](../images/dashboard-journal.png)

**5 Diário**: cada objeto recebido, quem o enviou, e o que havia em cada lote, colorido segundo a sua classe
Archipelago (progressão verde, útil azul, armadilha vermelho, enchimento cinzento). À direita, as tuas dicas: o
que os outros encontraram para ti, e onde os teus objetos esperam nos mundos deles. Uma dica fica lá até o objeto
ser encontrado.

A página Checks também tem as conquistas com os seus ícones do jogo, as vitórias com a imagem de cada nave, e as
raças de tripulação que recrutaste.

![As conquistas na página dos checks](../images/dashboard-achievements.jpg)

**Para onde ir a seguir?** Abre a página Checks e procura as linhas azuis na nave que pilotas. Na página Naves,
as que têm mais checks por fazer aparecem primeiro.

## O objetivo

Derrota a nave-almirante com um número de naves (ou layouts) **diferentes**. O menu principal e o painel dizem-no
por inteiro, por exemplo "derrotar a nave-almirante 2 vezes, um layout diferente para cada vitória", e listam as
naves com que já ganhaste. Uma segunda vitória com a mesma nave envia na mesma o seu check de vitória, só não
conta outra vez para o objetivo.

Algumas seeds pedem também **Arquivos**: objetos espalhados pelo multiworld, também no teu próprio mundo. Precisas
das vitórias e de Arquivos suficientes. O objetivo sai sozinho assim que tens as duas coisas, mesmo que o último
Arquivo chegue enquanto estás no menu.

Algumas seeds pedem vitórias em Normal ou Difícil. Uma vitória mais fácil envia na mesma o seu check, mas não
conta para o objetivo.

## Modo solo

Sem servidor? Clica em **Solo mode** no painel de ligação. Usa uma seed gerada a sério e dá-te um dos seus
objetos por check. É sempre a mesma seed de demonstração que vem com o mod, não o teu YAML, por isso as tuas opções
não se aplicam. O teu progresso fica guardado no seu próprio jogo guardado, por isso podes parar e voltar mais
tarde. **Stop solo** põe-no de lado, e clicar outra vez em **Solo mode** pergunta se queres continuar ou começar
do zero.

## É bom saber

- **Perder uma run só custa a run.** Os objetos ficam, e os Head Starts tornam a run seguinte mais forte.
- **Uma run começada antes de te ligares não conta.** Liga-te primeiro, depois começa um jogo novo. O mesmo para
  uma run guardada com outra seed: "Continuar" trá-la de volta, mas não conta para nada, e a sucata, o combustível
  e as armadilhas que recebes entretanto esperam pela tua próxima run a sério.
- **Voltar a uma seed já jogada** não volta a dar a sua sucata, combustível e armadilhas uma segunda vez. As
  naves, as plantas e os níveis de melhoria voltam como estavam.
- **Os checks de conquistas saem no salto seguinte**, e as conquistas ganhas antes do Archipelago não contam:
  ganha-as outra vez.
- **"Chegar ao setor 1" precisa de um salto.** Um check sai quando chegas a algum lado.
- **As armadilhas recebidas nunca destroem a tua nave.** Deixam pelo menos 3 de casco e 2 de combustível, e
  esperam por um farol calmo.
- **As mortes recebidas** (Death Link) nunca levam o teu último ponto de casco nem o teu último tripulante.
- **Envias uma morte** (Death Link) quando perdes a run ou um tripulante, conforme as opções da seed. Um
  tripulante que a baía de clonagem traz de volta não é uma morte, a não ser que a seed as conte. Dispensar um
  tripulante no ecrã da tripulação, ou perder um drone, não conta.
- **Os nomes dos objetos e dos locais ficam em inglês** seja qual for a língua, porque todos os jogadores e
  trackers os partilham. Só as frases à volta são traduzidas.

## Se algo não funcionar

Vê primeiro as [FAQ](FAQ.md) (em inglês). Se não ajudarem, pergunta no [Discord](https://discord.gg/BVQnQu843Q) ou
abre uma [issue](https://github.com/TheLiloji/FTLArchipelago/issues) com o teu `FTL_HS.log` (na pasta do FTL no
Windows, na sua pasta `data` no Linux).
