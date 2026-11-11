# Jouer

[English](Playing.md) · **Français** · [Deutsch](Playing.de.md) · [Español](Playing.es.md) ·
[Italiano](Playing.it.md) · [Português](Playing.pt.md)

Cette page suit une partie du début à la fin : la connexion, le hangar, une run, les balises Archipelago, le
tableau de bord et le but. Si le mod n'est pas encore installé, commence par le guide d'installation
([Windows](Setup-Windows.fr.md), [Linux](Setup-Linux.fr.md)).

## Ta première partie en cinq étapes

1. Lance FTL, remplis le panneau en bas à gauche du menu principal et appuie sur **Connect**.
2. Réponds **Use its own save** si le mod te le demande, pour que cette seed ait sa propre sauvegarde FTL.
3. Clique sur **Nouvelle partie** : le hangar s'ouvre sur ton vaisseau de départ. Choisis la difficulté que ta
   seed demande et appuie sur **START**.
4. Joue comme d'habitude. Atteindre des secteurs, gagner des combats, recruter de l'équipage et les succès
   envoient des checks. Ce que les autres trouvent pour toi arrive tout seul.
5. Appuie sur **TAB** à tout moment pour voir ton but, ce qu'il reste à faire et ce que tu as reçu.

Perdre une run ne coûte que la run : tu gardes tout ce que tu as reçu, et la run suivante commence plus forte.

## Se connecter

![Panneau de connexion](../images/connect-panel.jpg)

Au menu principal, remplis le panneau en bas à gauche :

| Champ | Quoi taper |
|---|---|
| Address | le serveur, par exemple `archipelago.gg`, ou l'IP de la personne qui héberge |
| Port | le nombre après les deux-points dans l'adresse de la room, par exemple `38281` |
| Slot name | le `name:` de ton YAML, exactement comme il est écrit |
| Password | seulement si la room en a un |

Appuie sur **Connect** ou **ENTRÉE**. **TAB** passe d'un champ à l'autre. **Ctrl+V** colle l'adresse copiée
depuis la page de ta room (comme `archipelago.gg:38281`) et remplit l'adresse et le port d'un coup.

- Les champs sont gardés pour la prochaine fois. Le mot de passe, jamais.
- Coche **Connect automatically on launch** et le mod se reconnecte à chaque lancement de FTL.
- Si la connexion tombe, le mod réessaie tout seul. Les checks faits entre-temps attendent et partent dès que le
  lien revient.

Une fois connecté, le panneau montre tes checks et un bouton **Disconnect**, et le but s'affiche en haut :

![Menu principal une fois connecté](../images/main-menu.jpg)

### « The seed has changed »

![La question du changement de seed](../images/seed-change.jpg)

FTL sait débloquer un vaisseau mais jamais le reverrouiller. Donc chaque seed a sa propre sauvegarde FTL. Quand
tu rejoins une nouvelle seed, le mod demande d'abord. **Use its own save** relance FTL sur une sauvegarde neuve
pour cette seed, et l'ancienne reste exactement comme elle était. **No, keep it** reste sur la sauvegarde
actuelle, hors ligne.

Le bouton **Saves** du panneau les liste : une par seed, plus le solo, avec les checks et la dernière fois que tu
as joué. **Load** relance FTL sur cette sauvegarde, run en cours comprise. **Archive** met une sauvegarde de côté
dans le dossier `ap_profiles/archived`, rien n'est effacé. Ta sauvegarde FTL sans Archipelago n'est jamais
touchée.

![La fenêtre des sauvegardes Archipelago](../images/saves.png)

## Le hangar

![Vaisseaux verrouillés](../images/hangar.jpg)

Seuls les vaisseaux que tu possèdes peuvent être choisis. Les autres restent verrouillés jusqu'à l'arrivée de
leur clé, et les nouveaux vaisseaux apparaissent la prochaine fois que tu reviens au hangar, jamais au milieu
d'une run. Les layouts de type B et C sont des objets à part (sauf si ta seed dit autre chose). Dans la liste des
vaisseaux, un layout que la seed a laissé de côté est marqué **NOT IN SEED** : il ne se débloque jamais.

Le hangar s'ouvre sur ton vaisseau de départ. **RANDOM SHIP** et les flèches **< >** passent par les vaisseaux que
tu possèdes. FTL montre toujours le Kestrel A, même quand il ne peut pas compter : sans sa clé (option
`kestrel_key`) il est marqué **NO KEY**, et hors de la seed **NOT IN SEED**. Sur un tel vaisseau, **START** est
grisé et refusé avec une courte raison, pour qu'une run qui ne compterait pour rien ne commence jamais.

Appuie sur **TAB** dans le hangar pour ouvrir le tableau de bord sur sa page Vaisseaux : les vaisseaux avec le
plus de checks restants passent en premier, et ceux qui n'ont plus rien vont en bas. **U** ou le bouton montre ou
cache les vaisseaux que tu n'as pas. C'est un bon moyen de choisir ton prochain vaisseau.

FTL ne peut pas débloquer de vaisseaux tout seul : le mod le refuse, et reverrouille au menu principal un
vaisseau que FTL a débloqué avant. Si l'un d'eux est quand même jouable, il est marqué **NOT RECEIVED**, et une
run avec lui ne compte pour rien, ni checks ni victoire.

**Quelle difficulté ?** Par défaut, seules les victoires en Normal et Difficile comptent pour le but. Le menu
principal et le tableau de bord disent ce que ta seed demande. Une victoire plus facile envoie quand même son
check de victoire.

## Le menu de début de run

![Le menu de début de run](../images/start-menu.jpg)

Les armes et les drones existent deux fois parmi les objets (par défaut en lots de 3 armes ou 2 drones), et les
membres d'équipage viennent en trois étapes au plus. Dès que tu as reçu une deuxième copie de quelque chose, un
menu s'ouvre au tout début de chaque nouvelle run : choisis **une arme, un drone et un membre d'équipage** parmi
tout ce que tu as récupéré, et ils t'accompagnent pour cette run.

- Avec **System Install** à `run_start`, le même menu propose aussi les systèmes dont tu as reçu le plan :
  choisis ceux que tu veux, autant que ton vaisseau a de salles libres.
- Avec **Sector Skip**, chaque secteur sauté te donne un choix de plus ici.

Clique sur **Done** pour le fermer, ou saute simplement : le menu ne reste que jusqu'au premier saut. Si tu
quittes le jeu avant de choisir, il est toujours là quand tu continues. Il revient au début de chaque run, donc
une bonne deuxième copie vaut quelque chose à chaque fois.

## Pendant une run

![Des objets qui arrivent pendant une run](../images/in-game.jpg)

### Ce qui envoie un check

Selon tes options :

- **atteindre un secteur** avec un layout (la plupart des checks viennent de là) ;
- **battre le vaisseau amiral** avec un layout ;
- **le premier membre d'équipage de chaque race** qui te rejoint ;
- **les succès**, du vaisseau ou généraux. Ils partent au saut qui suit ;
- **installer un système**, ou chacun de ses niveaux (Systemsanity) ;
- **gagner des combats** : les premiers d'une run, ou de chaque secteur ;
- **la puissance du réacteur** à 10, 15, 20 et 25 ;
- **acheter un colis** dans la boutique Archipelago, et les colis des événements du relais et des pirates.

Le tableau de bord (TAB) liste tous les checks de ta seed, et marque en bleu ceux que tu peux déjà faire.

### Ce que tu reçois

Ce que tu reçois arrive tout seul, à la prochaine balise calme si tu es en combat :

- une **clé de vaisseau** ou un **layout** : dans le hangar la prochaine fois ;
- un **plan de système** : les magasins peuvent maintenant vendre ce système (ou il vient à bord gratuitement,
  avec System Install) ;
- un objet **Progressive** de système : un niveau d'amélioration de plus autorisé (ou installé gratuitement,
  avec Free Upgrades) ;
- une **arme ou un drone**, première copie : un exemplaire est mis à bord (dans la soute si tes emplacements sont
  pleins ; si la soute est pleine aussi, il attend que tu fasses de la place) et il apparaît plus souvent dans
  les magasins. Deuxième copie : il rejoint le menu de début de run ;
- une **augmentation** : un exemplaire est mis à bord et elle apparaît plus souvent dans les magasins (si tes
  trois emplacements sont pleins, elle attend qu'un se libère) ;
- un **membre d'équipage** : le premier rejoint ta run (ou attend une place libre), le deuxième va dans le menu de
  début de run, le troisième fait de cette entrée du menu un expert avec une compétence au maximum ;
- un **Head Start** : un niveau de système ou une barre de réacteur gratuits au début de chaque run suivante ;
- un **Sector Pass** (avec Sector Locks) : la sortie du secteur 4, puis du 7, s'ouvre pour ce layout ;
- une **Archive** : un pas de plus vers le but ;
- du **remplissage** (ferraille, carburant, missiles, pièces de drone, réparation de coque) et, si la seed en a,
  des **pièges**.

Quand beaucoup arrive d'un coup (le release d'un autre joueur, la fin de partie), les armes et les drones
arrivent quatre par balise ; le reste suit aux sauts suivants.

Des notes en bas à gauche te disent ce qui est arrivé et ce qui est parti. Elles s'effacent après quelques
secondes, et tout est gardé dans le tableau de bord.

### Les pièges

Un piège ne détruit jamais ton vaisseau : il laisse au moins 3 de coque et 2 de carburant, ne coupe jamais
complètement un système, et attend une balise calme. La note dit quel piège c'est et qui l'a envoyé.

| Piège | Ce qui se passe |
|---|---|
| Fire | un incendie se déclare dans une salle |
| Hull Breach | une brèche s'ouvre dans une salle |
| Fuel Leak | tu perds du carburant |
| System Damage | un système prend des dégâts |
| Rebel Fleet | la flotte rebelle avance d'un saut |
| Hull Damage | ta coque perd quelques points |
| Boarding Party | un ennemi monte à bord |
| O2 Drain | toutes les salles perdent leur air d'un coup (jamais si ton système d'oxygène est en panne) |
| Anti-Ship Battery | attend ton prochain combat : une batterie planétaire te tire dessus pendant ce combat |
| Power Surge | attend ton prochain combat : l'ennemi lance une surcharge du vaisseau amiral (plus légère aux secteurs 1 et 2) |
| Hazard | attend ton prochain combat : la balise reçoit une nébuleuse, une tempête ionique, des astéroïdes, un soleil ou un pulsar |

Les trois derniers s'en vont à la fin du combat, et un seul se déclenche par combat.

### Sector Skip et Sector Locks

Deux options changent la carte, si ta seed les a :

- **Sector Skip** : aux secteurs 1 à 4, si ce layout a déjà atteint le secteur suivant dans une run précédente,
  la première balise est une sortie. Saute tout de suite pour avoir 60 ferrailles et un choix de plus dans le
  menu de début de run, ou explore comme d'habitude. Les checks du secteur sauté attendent une autre run.

  ![Sector Skip : la première balise est une sortie](../images/sector-skip.jpg)

- **Sector Locks** : la sortie du secteur 4 reste fermée tant que ce layout n'a pas son premier Sector Pass, et
  celle du secteur 7 jusqu'au second. La balise de sortie dit ce qui manque, et s'ouvre dès que le pass arrive.

### Le vaisseau amiral

Avec **Flagship Sabotage**, un message te prévient quand le vaisseau amiral arrive affaibli, et de combien (coque,
boucliers, armes). La victoire part dès que le vaisseau amiral est détruit.

## Les balises Archipelago

![Les balises Archipelago sur la carte](../images/map.jpg)

Chaque secteur a une balise marquée **AP STORE**, avec la boutique Archipelago, et d'autres balises cachent les
événements du mod. Par défaut, seuls les deux qui portent un colis (le relais et les pirates) sont marqués
**ARCHIPELAGO** sur la carte ; l'option **Event Beacons** peut les marquer tous ou aucun.

### La boutique Archipelago

![La boutique Archipelago](../images/shop.jpg)

Chaque colis est un objet du multiworld. Le nom en dessous dit pour qui il est ; **FOR YOU** veut dire un de tes
propres objets. Acheter un colis l'envoie tout de suite :

![Un colis envoyé](../images/shop-sent.jpg)

Le remplissage coûte 10 à 25 ferrailles, les objets utiles 30 à 65, et les importants 70 à 150. Un colis envoyé
ne revient jamais. Chaque secteur vend ses propres colis : la boutique du secteur 5 a d'autres colis que celle
du secteur 2, et ils coûtent plus cher. Avec **Archipelago Shop by Sector**, un colis n'est vendu que dans son
secteur, et la boutique dit dans quel secteur sont les suivants.

Par défaut, les colis que tu vois deviennent des indices pour leurs propriétaires : ils savent où leur objet
attend.

La boutique vend aussi des **pactes** : de la ferraille tout de suite, et un piège déclenché en échange, deux fois
sur trois sur un autre joueur (avec Trap Link), une fois sur trois sur toi. Sans Trap Link, c'est toujours toi.
Quand c'est toi, il frappe à ton prochain combat, pas à la balise calme de la boutique. Les **pactes de sang** de
la deuxième page paient plus, et ajoutent une chance (5, 10 ou 20 %) qu'un de tes membres d'équipage meure pour
de bon, baie de clonage ou pas. Ils ne prennent jamais ton dernier membre d'équipage.

![Les pactes de sang dans la boutique Archipelago](../images/blood-pacts.jpg)

### Les événements

- **Un relais** qui transporte des colis pour d'autres joueurs. Paie 15 ferrailles pour en faire suivre un.
- **Des pirates qui tiennent un colis**, souvent celui d'un ami. Paie-les 20 ferrailles, ou combats-les et
  envoie-le gratuitement si tu gagnes.
- **Un poste de contrôle zoltan** qui vend 3 carburants pour 15 ferrailles. Avec Energy Link, ça coûte 20 et
  ajoute 1 carburant à la réserve partagée, ou tu peux piocher du carburant dans la réserve à la place.
- **Un Slug** qui vend un vrai indice Archipelago pour 20 ferrailles. S'il n'y a plus rien à indiquer, tu
  récupères ta ferraille.
- **Une surtension venue d'un autre monde**, que tu peux absorber ou renvoyer comme piège (avec Trap Link).
- **Un technicien engi** (secteurs engi et civils) qui parie 30 ferrailles qu'il peut surcadencer ton réacteur.
  Ça rapporte 75 ferrailles si ça tient, et coûte des dégâts de coque et de moteurs sinon. Tu peux aussi le
  laisser tester les moteurs pour 3 carburants, ou juste partir.
- **Un marchand d'armes**, rare, dans les secteurs pirates : une arme au hasard pour 45 ferrailles, ou une
  augmentation au hasard pour 4 carburants.

| | |
|---|---|
| ![Le pari de surcadençage engi](../images/event-overclock.jpg) | ![Le marchand d'armes](../images/event-arms-dealer.jpg) |

Avec **Archipelago Event Checks**, les colis du relais et des pirates sont des checks à eux (« Archipelago Event
1 », 2...) avant de revenir aux colis de la boutique. Aucun de ces événements ne peut te cacher un check : ils
sont en plus, jamais obligatoires.

## Jouer avec les autres : les liens

Ils ne marchent que si ton YAML les a activés. La première page du tableau de bord montre lesquels sont actifs.

- **Death Link** : quand tu meurs, les autres meurent aussi, et inversement. Ta seed dit ce qui compte comme ta
  mort (une run perdue, un membre d'équipage perdu, ou les deux). Une mort reçue fait quelque chose de mauvais
  (par défaut une brèche et un incendie dans une salle de système) mais ne détruit jamais ton vaisseau et ne tue
  jamais ton dernier membre d'équipage. Clique sur Death Link sur la première page du tableau de bord pour le
  couper ou le remettre, si ta seed le permet.
- **Energy Link** : une réserve de carburant partagée avec tous les joueurs Energy Link. Ton carburant en trop y
  va aux balises calmes (25 % se perdent en route), et quand tu descends sous 3 carburants ton vaisseau en
  reprend, une fois par balise. Le tableau de bord montre ce qu'il y a dans la réserve.
- **Trap Link** : quand quelqu'un reçoit un piège, les autres en reçoivent un aussi. Un piège d'un autre jeu
  devient le piège FTL le plus proche (« Ice Trap » coupe un système, un piège de feu lance un incendie...).

## Le tableau de bord

Appuie sur **TAB** en run ou dans le hangar. En run, le jeu se met en pause tant qu'il est ouvert. **Gauche** /
**Droite** ou **1** à **5** changent de page, la molette fait défiler, **Échap** ou **TAB** le ferme.

| | |
|---|---|
| ![Vue d'ensemble](../images/dashboard-links.jpg) | ![Vaisseaux](../images/dashboard-ships.png) |
| **1 Vue d'ensemble** : ton but et où tu en es, les checks faits par catégorie, tes liens (Death Link, Energy Link, Trap Link), cette run (combats restants qui envoient un check, ferraille pour la prochaine run, améliorations gratuites), les derniers objets reçus et tes indices. | **2 Vaisseaux** : chaque layout de la seed, possédé ou pas, et combien de checks il lui reste. **U** montre seulement ceux que tu possèdes. |
| ![Systèmes](../images/dashboard-systems.png) | ![Checks](../images/dashboard-checks.png) |
| **3 Systèmes** : quels plans tu as, combien de niveaux d'amélioration tu as reçus pour chaque système, et les Head Starts donnés au début de chaque run. | **4 Checks** : tous les checks de la seed, par catégorie et vaisseau par vaisseau. Faits en vert, et une **ligne bleue** sous ceux que tu peux déjà faire avec ce que tu as. Pointe une case pour voir ce que c'est, et ce qu'elle a donné une fois faite. |

![Journal](../images/dashboard-journal.png)

**5 Journal** : chaque objet reçu, qui l'a envoyé, et ce qu'il y avait dans chaque lot, coloré selon sa classe
Archipelago (progression vert, utile bleu, piège rouge, remplissage gris). À droite, tes indices : ce que les
autres ont trouvé pour toi, et où tes objets attendent dans leurs mondes. Un indice reste là jusqu'à ce que
l'objet soit trouvé.

La page Checks a aussi les succès avec leurs icônes du jeu, les victoires avec l'image de chaque vaisseau, et les
races d'équipage que tu as recrutées.

![Les succès sur la page des checks](../images/dashboard-achievements.jpg)

**Où aller ensuite ?** Ouvre la page Checks et cherche les lignes bleues sur le vaisseau que tu pilotes. Sur la
page Vaisseaux, ceux qui ont le plus de checks restants passent en premier.

## Le but

Battre le vaisseau amiral avec un certain nombre de vaisseaux (ou de layouts) **différents**. Le menu principal et le
tableau de bord le disent en entier, par exemple « battre le vaisseau amiral 2 fois, un layout différent pour chaque
victoire », et listent les vaisseaux avec lesquels tu as déjà gagné. Une deuxième victoire avec le même vaisseau
envoie quand même son check de victoire, elle ne compte juste pas une deuxième fois pour le but.

Certaines seeds demandent aussi des **Archives** : des objets répartis dans le multiworld, chez toi aussi. Il te
faut à la fois les victoires et assez d'Archives. Le but part tout seul dès que les deux sont là, même si la
dernière Archive arrive pendant que tu es dans le menu.

Certaines seeds demandent des victoires en Normal ou Difficile. Une victoire plus facile envoie quand même son
check, mais ne compte pas pour le but.

## Le mode solo

Pas de serveur ? Clique sur **Solo mode** dans le panneau de connexion. Il utilise une vraie seed générée et te
donne un de ses objets par check. C'est toujours la même seed de démo fournie avec le mod, pas ton YAML, donc tes
options ne s'appliquent pas. Ta progression est gardée dans sa propre sauvegarde, tu peux donc arrêter et revenir
plus tard. **Stop solo** la met de côté, et recliquer sur **Solo mode** demande s'il faut continuer ou tout
recommencer.

## Bon à savoir

- **Perdre une run ne coûte que la run.** Les objets restent, et les Head Starts rendent la run suivante plus
  forte.
- **Une run commencée avant de te connecter ne compte pas.** Connecte-toi d'abord, puis lance une nouvelle
  partie. Pareil pour une run sauvegardée sous une autre seed : « Continuer » la ramène, mais elle ne compte pour
  rien, et la ferraille, le carburant et les pièges reçus entre-temps attendent ta prochaine vraie run.
- **Revenir sur une seed déjà jouée** ne redonne pas sa ferraille, son carburant et ses pièges une deuxième fois.
  Les vaisseaux, les plans et les niveaux d'amélioration reviennent comme ils étaient.
- **Les checks de succès partent au saut suivant**, et les succès gagnés avant Archipelago ne comptent pas :
  regagne-les.
- **« Atteindre le secteur 1 » demande un saut.** Un check part quand tu arrives quelque part.
- **Les pièges reçus ne détruisent jamais ton vaisseau.** Ils laissent au moins 3 de coque et 2 de carburant, et
  attendent une balise calme.
- **Les morts reçues** (Death Link) ne prennent jamais ton dernier point de coque ni ton dernier membre
  d'équipage.
- **Tu envoies une mort** (Death Link) quand tu perds la run ou un membre d'équipage, selon les options de la
  seed. Un membre d'équipage que la baie de clonage ramène n'est pas une mort, sauf si la seed les compte.
  Renvoyer un membre depuis l'écran d'équipage, ou perdre un drone, ne compte pas.
- **Les noms des objets et des lieux restent en anglais** quelle que soit la langue, parce que tous les joueurs
  et les trackers les partagent. Seules les phrases autour sont traduites.

## Si quelque chose ne marche pas

Regarde d'abord la [FAQ](FAQ.md) (en anglais). Si ça n'aide pas, demande sur le
[Discord](https://discord.gg/BVQnQu843Q) ou ouvre une
[issue](https://github.com/TheLiloji/FTLArchipelago/issues) avec ton `FTL_HS.log` (dans le dossier de FTL sous
Windows, dans son dossier `data` sous Linux).
