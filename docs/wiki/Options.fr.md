# Options

[English](Options.md) · **Français** · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

Tes options tiennent dans un petit fichier texte, le **YAML**. Tu le fais une fois, avant la partie, et tu
l'envoies à la personne qui génère le multiworld. Cette page explique chaque option, une par une. Pas besoin de
tout lire : prends un preset, et reviens ici quand tu veux changer quelque chose.

**Tu joues avec Multiverse ?** Voir [Multiverse](Multiverse.fr.md) : l'installation et ce qui change dans ton YAML.

## Avant de commencer

Il te faut **Archipelago 0.6.7**, avec le `ftl.apworld` de la
[page de release](https://github.com/TheLiloji/FTLArchipelago/releases/latest) dans son dossier
`custom_worlds`. Sans lui, FTL n'apparaît pas dans la liste. Les guides d'installation
([Windows](Setup-Windows.fr.md), [Linux](Setup-Linux.fr.md)) expliquent chaque étape.

## Quelques mots que tu vas croiser

| Mot | Sens |
|---|---|
| check | une action en jeu qui envoie un objet : atteindre un secteur, gagner, un succès... |
| objet (item) | ce qu'un check donne, à toi ou à un autre joueur : un vaisseau, un système, une arme, de la ferraille... |
| seed | la partie générée, la même pour tout le multiworld |
| slot | ta place dans le multiworld, nommée par la ligne `name:` de ton YAML |
| layout | une version d'un vaisseau (« disposition » dans le jeu) : Kestrel A, Kestrel B et Kestrel C sont trois layouts. Il y en a 28, sur 10 vaisseaux |
| progressive | un objet qui monte un système d'un niveau à chaque fois que tu le reçois |
| plan (blueprint) | l'objet qui te donne le droit d'avoir un système (Camouflage, Contrôle des drones...) |
| Archives | des objets qu'il te faut en plus de tes victoires pour finir |
| remplissage (filler) | les petits objets : ferraille, carburant, missiles, pièces de drone |
| piège (trap) | un mauvais objet : un incendie, une brèche, la flotte rebelle qui avance... |
| logique | ce que le générateur suppose que tu as avant de te demander un check |
| AP STORE | la boutique Archipelago, une balise par secteur, qui vend les objets du multiworld |

## Le plus simple : prendre un preset

Les presets sont des fichiers YAML tout prêts. Prends celui qui correspond à ton temps :

| Preset | Temps jusqu'au but | Ce que c'est |
|---|---|---|
| `first_game` | environ 3 h | **Ta première partie Archipelago.** 1 victoire, le Facile compte, 3 vaisseaux de type A, 2 Archives sur 3, pas de pièges. Les améliorations et les systèmes reçus viennent à bord tout seuls |
| `short_game` | environ 5 h | 2 victoires en Normal ou Difficile, 4 layouts, 4 Archives sur 5, toutes les améliorations d'un système d'un coup |
| `medium_game` | environ 10 h | les options par défaut : 5 victoires en Normal ou Difficile, 7 layouts, 10 Archives sur 12 |
| `long_game` | 20 h ou plus | 10 victoires, 14 layouts, 16 Archives sur 20, installer un système est un check |
| `solo_game` | environ 7 h | **Seul dans le multiworld.** 3 victoires, 5 layouts, combats comptés par secteur, saut de secteur et Sector Passes, plus de checks d'événements |

Ils sont dans `presets.zip` sur la [page de release](https://github.com/TheLiloji/FTLArchipelago/releases/latest).
Le haut de chaque fichier dit combien il a de checks et le temps qu'il faut à peu près.

1. Ouvre le fichier dans un éditeur de texte.
2. Remplace la ligne `name:` par ton nom. Utilise seulement des lettres sans accent, des chiffres, des espaces,
   `-` et `_`, et 16 caractères au plus : le panneau de connexion du jeu ne sait rien taper d'autre.
3. Envoie le fichier à la personne qui génère le multiworld (son guide, en anglais : [Hosting a seed](Hosting-a-seed.md)).

Les temps valent pour un joueur qui gagne en quelques runs. Si tu découvres FTL, compte plus.

## Faire ton propre YAML

Ouvre **ArchipelagoOptionsCreator** (dans le dossier d'Archipelago), choisis **FTL: Faster Than Light**, tape
ton nom et exporte le YAML. Chaque option a une courte description (en anglais) : passe la souris dessus. Les
réglages par défaut sont ceux du preset `medium_game`.

Tu peux aussi modifier un preset à la main. Chaque option tient sur une ligne : le nom YAML, deux-points, la
valeur. Par exemple :

```yaml
name: MonNom
game: "FTL: Faster Than Light"
requires:
  version: 0.6.7
"FTL: Faster Than Light":
  victories_required: 3
  start_ship: rock_cruiser
  trap_chance: 10
```

Garde les deux espaces devant chaque option. Une option que tu n'écris pas prend sa valeur par défaut.

## Trois pièges fréquents

- **Les victoires en Facile.** Par défaut, seules les victoires en Normal et Difficile comptent pour ton but.
  Si tu joues en Facile, mets **Victory Difficulty** à `any` (tu peux aussi écrire `easy` dans le YAML).
- **Moins de checks ne veut pas dire une partie plus courte.** Couper des secteurs ou des succès ne retire pas
  leurs objets : ils passent dans la boutique Archipelago, où tu les achètes en ferraille. Pour raccourcir une
  partie, baisse plutôt **Victories Required** et **Layouts in the Seed**.
- **Death Link.** Si ton groupe y joue, active-le. Avec **Death Link Trigger** à `both` (par défaut), chaque
  membre d'équipage perdu tue aussi les autres. Dans un gros multiworld ou pour une première partie, choisis
  `ship_destroyed` : seule une run perdue compte.

## Des idées pour ton YAML

Une partie plus courte, sans toucher au reste :

```yaml
  victories_required: 2
  layout_count: 4
  sectorsanity_last_sector: 6
```

Un deuxième vaisseau vite, et des objets reçus qui servent tout de suite :

```yaml
  early_ship_keys: 3
  free_upgrades: true
  system_install: run_start
  run_start_scrap: 15
```

Plus de choses à faire dans chaque run :

```yaml
  combat_checks: 1
  combat_checks_mode: per_sector
  reactor_checks: true
  systemsanity: first_install
```

Le chaos entre amis :

```yaml
  trap_chance: 30
  trap_link: true
  death_link: true
```

Une seed plus dure, pour ceux qui connaissent bien FTL :

```yaml
  victory_difficulty: hard
  sector_logic: none
  shop_unlock_mode: locked
  sector_locks: true
```

## Toutes les options, groupe par groupe

Les groupes sont ceux du créateur d'options. Chaque option donne son nom dans le créateur d'options (en
anglais), son nom dans le YAML, les valeurs possibles et sa valeur par défaut. Les groupes marqués *fermé* sont
repliés au départ dans le créateur d'options : tu n'en as pas besoin pour une première partie.

### Goal (le but)

Ce que tu dois faire pour finir.

#### Victories Required

`victories_required` · 1 à 28 · défaut `5`\
Combien de fois tu dois battre le vaisseau amiral, à chaque fois avec un layout **différent** (Kestrel A et Kestrel B
comptent pour deux). C'est l'option qui décide de la durée de ta partie : 1 ou 2 pour une première partie, 5
entre amis, 10 pour une longue partie.

#### Victory Difficulty

`victory_difficulty` · `any`, `normal`, `hard` · défaut `normal`\
La difficulté minimum d'une victoire pour qu'elle compte pour ton but. `any` (ou `easy`) compte toutes les
victoires, `normal` compte Normal et Difficile, `hard` seulement Difficile. Une victoire plus facile envoie quand
même son check, elle ne compte juste pas pour le but.

#### Flagship Sabotage

`flagship_sabotage` · 0 à 5 · défaut `0`\
Le multiworld affaiblit le vaisseau amiral. Chaque niveau ajoute quelque chose, et ça vaut pour chaque phase du combat :
1 c'est coque -10 %, 2 ajoute boucliers -1, 3 passe à coque -20 %, 4 ajoute armes -1, 5 passe à coque -30 %. Un
message te donne le niveau quand le vaisseau amiral arrive. Bien pour un groupe qui veut finir plus vite.

#### Archives

`archives` · 0 à 50 · défaut `12`\
Combien d'Archives sont cachées dans le multiworld, chez toi ou chez les autres. Les Archives sont des objets
qu'il te faut en plus de tes victoires. 0 joue sans.

#### Archives Required

`archives_required` · 0 à 50 · défaut `10`\
Combien d'Archives il te faut pour finir. Garde-le un peu plus bas que **Archives**, pour qu'une Archive mal
placée ne puisse pas te bloquer. S'il est plus haut que Archives, il faut toutes les Archives.

#### Victory Collects the Layout

`victory_collects_layout` · `off`, `sectors`, `everything` · défaut `sectors`\
Ce qu'une victoire envoie en plus, parmi les checks de ce layout que tu n'as pas encore faits. `off` : seulement
la victoire. `sectors` : aussi tous les checks de secteur de ce layout. `everything` : aussi les succès de son
vaisseau, ses checks de système et ses checks de combat. Pratique quand tu gagnes avec un vaisseau et que tu ne
veux pas y revenir pour le secteur 3.

### Ships (les vaisseaux)

Quels vaisseaux sont dans la partie et comment tu les obtiens.

#### Starting Ship

`start_ship` · un des 10 vaisseaux · défaut `kestrel_cruiser`\
Le vaisseau avec lequel tu commences, en type A. Ses types B et C se trouvent comme ceux des autres. Les valeurs
sont `kestrel_cruiser`, `engi_cruiser`, `federation_cruiser`, `zoltan_cruiser`, `mantis_cruiser`,
`slug_cruiser`, `rock_cruiser`, `stealth_cruiser`, `lanius_cruiser` et `crystal_cruiser` (ou juste `rock`,
`mantis`...).

#### Ship Layouts

`ship_layouts` · `type_a_only`, `up_to_type_b`, `all_layouts` · défaut `all_layouts`\
Quels layouts peuvent être dans la partie : seulement le type A, les types A et B, ou tous.

#### Layouts in the Seed

`layout_count` · 1 à 28 · défaut `7`\
Combien de layouts tu peux piloter dans cette seed, en tout. Ton vaisseau de départ et le Kestrel A comptent
dedans, donc 7 veut dire ces deux-là plus 5 autres, tirés au hasard parmi ceux que **Ship Layouts** permet. Un
type B ou C ne vient qu'avec le type A de son vaisseau. Les layouts laissés de côté n'ont ni clé ni check, et le
hangar les marque **NOT IN SEED**. La valeur monte à Victories Required si elle est plus basse.

#### Excluded Ships and Layouts

`excluded_layouts` · une liste · défaut vide\
Les vaisseaux ou les layouts que tu ne veux jamais dans la seed. Donne un vaisseau entier (`"Engi Cruiser"`) ou
un layout (`"Engi Cruiser B"`, ou `"Engi B"`). Retirer un type A retire tout son vaisseau. Ton vaisseau de départ
et le Kestrel A ne peuvent pas être retirés. Exemple : `excluded_layouts: ["Stealth Cruiser", "Lanius Cruiser C"]`.

#### Layout Unlocks

`layout_unlocks` · `items`, `vanilla`, `independent`, `progressive` · défaut `items`\
Comment les types B et C deviennent disponibles.
- `items` : chaque layout est son propre objet, et il te faut aussi la clé du vaisseau pour le piloter.
- `vanilla` : comme dans FTL, en gagnant les succès de ce vaisseau. Pas d'objets de layout.
- `independent` : chaque layout est son propre objet et n'a besoin de rien d'autre, pas même de la clé du
  vaisseau.
- `progressive` : pas d'objets de layout. La clé du vaisseau vient une fois par layout : la première copie donne
  le type A, les suivantes le type B, puis C.

#### Early Ship Keys

`early_ship_keys` · 0 à 9 · défaut `1`\
Combien de clés de vaisseau, en plus de ton vaisseau de départ et du Kestrel, sont placées dans tes propres
premiers checks. Un deuxième vaisseau arrive tôt au lieu d'arriver des heures plus tard. Le nombre de clés ne
change pas, seulement où elles tombent. 0 les laisse tomber n'importe où.

#### Kestrel Needs Its Key

`kestrel_key` · `true` / `false` · défaut `false`\
Quand tu ne commences pas avec le Kestrel, le Kestrel A a besoin de sa clé comme n'importe quel vaisseau. FTL le
montre quand même dans le hangar, mais il est marqué **NO KEY** et START le refuse tant que la clé n'est pas
arrivée. Désactivé, le Kestrel A est toujours à toi.

### Checks

Ce qui envoie des checks. La plupart de tes checks viennent des secteurs.

#### Sectorsanity

`sectorsanity` · `disabled`, `milestones`, `full` · défaut `full`\
Atteindre un secteur avec un layout envoie un check. Chaque layout a les siens : le Rock A au secteur 4, ce n'est
pas le même check que le Rock B au secteur 4. `full` : chaque secteur. `milestones` : seulement les secteurs 5 et
8. `disabled` : jamais.

#### Sectorsanity First Sector

`sectorsanity_first_sector` · 1 à 8 · défaut `2`\
Le premier secteur qui envoie un check. Les secteurs avant n'envoient rien. Avec tous les layouts en jeu, les
secteurs 1 et 2 font à eux seuls 56 checks que tu obtiens juste en décollant : le monter est la façon la plus
simple d'alléger une grosse seed.

#### Sectorsanity Last Sector

`sectorsanity_last_sector` · 1 à 8 · défaut `8`\
Le dernier secteur qui envoie un check. Un check au secteur 8 coûte une run entière, un check au secteur 4 vient
tout seul. 5 ou 6 garde les mêmes vaisseaux mais coupe la longue fin de la seed, celle où les autres t'attendent.

#### Systemsanity

`systemsanity` · `disabled`, `first_install`, `every_level` · défaut `disabled`\
Installer un système envoie un check. `first_install` : une fois par système, 12 checks (Moteurs, Oxygène,
Pilotage et Contrôle des armes n'en ont pas, tous les vaisseaux commencent avec). `every_level` : chaque niveau
d'amélioration aussi, 64 checks, une partie bien plus longue.

#### Systemsanity per Ship

`systemsanity_per_ship` · `true` / `false` · défaut `false`\
Avec Systemsanity activé, chaque vaisseau a ses propres checks d'installation, comme « Kestrel Cruiser: Install
Cloaking ». Jamais pour un système avec lequel ce vaisseau commence.

#### Ship Achievement Checks

`ship_achievements` · `true` / `false` · défaut `true`\
Les trois succès de chaque vaisseau envoient un check, 30 en tout. FTL les donne au vaisseau, pas au layout :
les gagner avec le type A, B ou C envoie le même check.

#### General Achievement Checks

`general_achievements` · `disabled`, `basic`, `most`, `all` · défaut `most`\
Lesquels des 21 succès généraux envoient un check. `basic` : les faciles, comme atteindre le secteur 8. `most` :
aussi les plus durs, gagnés au fil d'une run. `all` : tous, même les très durs.

#### Cross-Run Achievement Checks

`cross_run_achievements` · `true` / `false` · défaut `false`\
Les trois succès qu'on ne peut pas gagner en une seule run : « Rule Ten: Greed is Eternal » (10 000 ferrailles sur
toutes tes parties), « Warlord » (1000 vaisseaux détruits) et « Your Own Fleet » (tous les vaisseaux débloqués).
Laisse-le désactivé pour une seed courte : les deux premiers peuvent ne jamais arriver.

#### Crew Checks

`crew_checks` · `true` / `false` · défaut `true`\
Le premier membre d'équipage de chaque race qui te rejoint envoie un check : Humain, Engi, Zoltan, Mantis, Rock,
Slug et Lanius. 7 checks. L'équipage avec lequel tu commences une run ne compte pas.

#### Archipelago Event Checks

`event_checks` · 0 à 20 · défaut `5`\
Les colis des événements du relais et des pirates deviennent des checks à eux, « Archipelago Event 1 », 2...
jusqu'à ce nombre. Une fois qu'ils sont tous faits, les événements reviennent aux colis de la boutique
Archipelago. 0 : les événements ne vendent que les colis de la boutique.

#### Reactor Checks

`reactor_checks` · `true` / `false` · défaut `false`\
Améliorer le réacteur envoie des checks à 10, 15, 20 et 25 de puissance, dans n'importe quelle run. La logique
les attend vers les secteurs 2, 4, 6 et 7.

#### Combat Checks per Ship

`combat_checks` · 0 à 10 · défaut `0`\
Gagner des combats envoie des checks. Avec chaque vaisseau, les premiers combats gagnés d'une run (ennemi
détruit ou son équipage tué) envoient « Fight 1 won », « Fight 2 won »... jusqu'à ce nombre. 0 les désactive.

#### Combat Checks Mode

`combat_checks_mode` · `per_run`, `per_sector` · défaut `per_run`\
Comment les combats sont comptés. `per_run` : les premiers combats d'une run, comme au-dessus. `per_sector` : les
premiers combats de **chaque** secteur envoient leur propre check (« Sector 3 fight 1 won »), jusqu'à **Fights
per Sector**, donc une run jusqu'au secteur 8 peut envoyer des checks partout. Dans ce mode, Combat Checks per
Ship doit juste être au-dessus de 0.

#### Fights per Sector

`fights_per_sector` · 1 à 5 · défaut `2`\
Avec `per_sector` : combien de combats dans chaque secteur envoient un check, pour chaque vaisseau.

#### Combat Check Scrap (%)

`combat_check_scrap` · 0 à 100 · défaut `50`\
Un combat qui envoie un check ne donne que cette part de sa ferraille. Les missiles, le carburant et les pièces
de drone restent. Les combats qui n'envoient rien gardent toute leur récompense.

### Systems and Upgrades (systèmes et améliorations) *(fermé)*

Comment les systèmes et leurs niveaux sont verrouillés puis rendus.

#### System Blueprints

`system_blueprints` · `true` / `false` · défaut `true`\
Les plans de systèmes sont des objets. Sans le plan d'un système, les magasins ne le vendent pas. Un système avec
lequel ton vaisseau commence ne t'est jamais retiré : il reste au niveau 1 jusqu'à l'arrivée du plan. Désactivé,
tous les systèmes sont en vente.

#### Progressive System Upgrades

`progressive_systems` · `true` / `false` · défaut `true`\
Chaque objet « Progressive » monte jusqu'où tu peux améliorer un système, jusqu'au maximum de FTL. Tu paies
toujours la ferraille, sauf avec Free Upgrades. Par défaut un objet compte pour tous les vaisseaux :
« Progressive Shields » monte les boucliers de tous. Désactivé, les systèmes s'améliorent comme dans FTL.

#### Progressive Upgrades per Ship

`progressive_systems_per_ship` · `true` / `false` · défaut `false`\
Les améliorations appartiennent chacune à un vaisseau, comme « Kestrel Cruiser: Progressive Shields », et ne
comptent qu'à bord de ce vaisseau, quel que soit le layout. Beaucoup plus d'objets, donc une plus grosse boutique
Archipelago.

#### Progressive Unlocks the System

`progressive_unlocks_system` · `true` / `false` · défaut `false`\
Le premier objet Progressive d'un système le débloque aussi, donc ce système n'a pas d'objet de plan à part. Moins
d'objets à attendre : les systèmes arrivent plus tôt.

#### Full System Upgrades

`full_system_upgrades` · `true` / `false` · défaut `false`\
Chaque objet Progressive donne tous les niveaux de son système d'un coup. Moins d'objets, une progression moins
fine.

#### Free Upgrades

`free_upgrades` · `true` / `false` · défaut `false`\
Les niveaux de système que tu reçois sont installés gratuitement : tout de suite si tu es en run, et à nouveau au
début de chaque run. Désactivé, un niveau reçu te permet seulement de l'acheter. A besoin de Progressive System
Upgrades.

#### System Install

`system_install` · `store`, `run_start`, `immediately` · défaut `store`\
Quand un système dont tu as reçu le plan vient à bord gratuitement, si le vaisseau a une salle pour lui.
`store` : jamais, tu l'achètes comme dans FTL. `run_start` : au début de chaque run, depuis le menu de début de
run. `immediately` : aussi dès que le plan arrive pendant une run.

### Weapons, Drones, Augments, Crew (armes, drones, augmentations, équipage) *(fermé)*

Ce qui est verrouillé dans les magasins de FTL, et l'équipage comme objets.

#### Shop Weapons

`shop_weapons` · 0 à 37 · défaut `37`\
Combien des 37 armes de FTL deviennent des objets. Les autres restent des articles normaux des magasins. 0 laisse
les armes tranquilles.

#### Shop Drones

`shop_drones` · 0 à 14 · défaut `14`\
Pareil pour les 14 drones. Les drones ont besoin du Contrôle des drones pour servir.

#### Shop Augments

`shop_augments` · 0 à 23 · défaut `23`\
Pareil pour les 23 augmentations.

#### Weapon Bundle Size

`weapon_bundle_size` · 1 à 5 · défaut `3`\
Combien d'armes contient chaque lot d'armes. Un lot les débloque toutes d'un coup. 1 veut dire pas de lots :
chaque arme est son propre objet. Des lots plus gros font moins d'objets, donc une plus petite boutique
Archipelago.

#### Drone Bundle Size

`drone_bundle_size` · 1 à 5 · défaut `2`\
Pareil pour les drones.

#### Augment Bundle Size

`augment_bundle_size` · 1 à 5 · défaut `3`\
Pareil pour les augmentations.

#### Shop Unlock Mode

`shop_unlock_mode` · `rarity_boost`, `locked` · défaut `rarity_boost`\
Ce que recevoir une arme, un drone ou une augmentation change dans les magasins de FTL. `rarity_boost` : il était
déjà en vente, et apparaît maintenant bien plus souvent. `locked` : il n'est en vente nulle part tant que tu ne
l'as pas reçu. Dans les deux cas, ça dure pour toutes les runs suivantes.

#### Shop Item Delivery

`shop_item_delivery` · `true` / `false` · défaut `true`\
Tu reçois aussi un exemplaire tout de suite, une fois : à bord si un emplacement est libre, sinon dans la soute.
Désactivé, l'objet change seulement ce que vendent les magasins.

#### Crew Members

`crew_members` · `true` / `false` · défaut `true`\
Les membres d'équipage comme objets, un par race, jusqu'à trois copies. Première copie : un membre rejoint ta
run. Deuxième : la race entre dans le menu de début de run. Troisième : ce menu propose un expert avec une
compétence au maximum. Lanius et Crystal s'arrêtent à deux.

### Archipelago Shop (la boutique Archipelago) *(fermé)*

Les balises AP STORE, une par secteur, qui vendent les objets du multiworld contre de la ferraille.

#### Archipelago Shop Checks (minimum)

`shop_checks` · 0 à 100 · défaut `20`\
Le plus petit nombre de colis dans la boutique, pour toute la seed. Si tes options créent plus d'objets que de
checks, des colis s'ajoutent tout seuls (jusqu'à 400) pour que chaque objet ait une place. Plus la boutique est
grosse, plus chaque balise montre de colis : 3, 6, 9 ou 12.

#### Archipelago Shop by Sector

`shop_by_sector` · `true` / `false` · défaut `false`\
Chaque colis appartient à un secteur, de 1 à 7, et n'est vendu qu'à l'AP STORE de ce secteur. Les colis plus
profonds coûtent plus cher, et la logique attend que tu atteignes ce secteur d'abord.

#### Archipelago Shop per Ship

`shop_per_ship` · `off`, `per_class`, `per_layout` · défaut `off`\
Chaque colis appartient à un vaisseau (`per_class`) ou à un layout (`per_layout`), et n'est vendu que quand tu le
pilotes. Ça n'ajoute pas de colis, ça les répartit. Un colis que tu n'as pas acheté revient plus tard.

#### Archipelago Shop Hints

`shop_hints` · `off`, `seen` · défaut `seen`\
`seen` : les colis que tu vois dans la boutique deviennent des indices, donc leurs propriétaires savent où leur
objet attend. `off` : la boutique reste ton secret.

#### Archipelago Shop Deal Scrap (%)

`shop_deal_scrap` · 0 à 200 · défaut `100`\
Combien de ferraille paient les pactes et les pactes de sang de la boutique, en pourcentage. 0 les désactive.

### Runs *(fermé)*

Ce qui change pendant une run.

#### Head Starts

`head_starts` · `true` / `false` · défaut `true`\
Les objets Head Start donnent un niveau de système gratuit, ou une barre de réacteur, au début de chaque run
suivante. Ils ne prennent que les checks qui restent une fois que tous les autres objets ont leur place, donc avec
les options par défaut il en vient peu ou pas.

#### Run Start Scrap (%)

`run_start_scrap` · 0 à 100 · défaut `0`\
Chaque nouvelle run commence avec cette part de toute la ferraille reçue en objets. Les objets de ferraille
donnent quand même leur ferraille une fois à leur arrivée. 10 à 25, c'est une bonne plage.

#### Sector Skip

`sector_skip` · `true` / `false` · défaut `false`\
Un layout qui a déjà atteint le secteur suivant peut sauter les secteurs 1 à 4 : la première balise d'un tel
secteur est une sortie. Saute tout de suite pour 60 ferrailles et un choix de plus dans le menu de début de run,
ou explore comme d'habitude. Les checks du secteur sauté attendent une autre run.

#### Sector Locks

`sector_locks` · `true` / `false` · défaut `false`\
Chaque layout a besoin de Sector Passes pour aller plus loin : le premier pour quitter le secteur 4, le second
pour quitter le secteur 7. Sans eux la sortie reste fermée, et le jeu dit pourquoi. Deux objets par layout.

#### Event Beacons

`event_beacons` · `marked`, `important`, `hidden` · défaut `important`\
Quelles balises d'événement Archipelago affichent ARCHIPELAGO sur la carte. L'AP STORE l'affiche toujours.
`marked` : tous les événements. `important` : seulement le relais et les pirates, qui portent un colis.
`hidden` : aucun.

#### Sector Logic

`sector_logic` · `none`, `standard`, `strict`, `power` · défaut `standard`\
Ce que le générateur attend de ton vaisseau avant de t'envoyer loin. Ça ne change jamais ce que le jeu te laisse
faire.
- `none` : rien. On peut te demander d'atteindre le vaisseau amiral avec très peu. Pour les joueurs expérimentés
  (`relaxed`, son ancien nom, marche toujours).
- `standard` : 2 plans pour le secteur 4, 4 pour le secteur 6, 5 pour le vaisseau amiral.
- `strict` : 3 plans pour le secteur 3, 6 pour le secteur 5, 9 pour le secteur 7, 11 pour le vaisseau amiral.
- `power` : regarde le vaisseau qui fait le check. Le secteur 5 demande 2 couches de bouclier, le secteur 8 aussi
  Contrôle des armes 5, le vaisseau amiral 3 couches, Contrôle des armes 6 et Moteurs 4.

#### Mod Language

`mod_language` · `game`, `english`, `french`, `spanish`, `german`, `italian`, `portuguese` · défaut `game`\
La langue des menus et des messages du mod. `game` suit FTL tout seul. Les noms des objets et des lieux restent
toujours en anglais, parce que tous les joueurs et les trackers les partagent.

### Playing with Others (jouer avec les autres)

Les liens avec les autres joueurs. Tous désactivés par défaut.

#### Death Link

`death_link` · `true` / `false` · défaut `false`\
Quand tu meurs, les autres qui jouent avec Death Link meurent aussi, et inversement. Une mort reçue ne détruit
jamais ton vaisseau et ne tue jamais ton dernier membre d'équipage.

#### Death Link Trigger

`death_link_trigger` · `ship_destroyed`, `crew_death`, `both` · défaut `both`\
Ce qui envoie ta mort. `ship_destroyed` : seulement une run perdue, le mieux dans un gros multiworld.
`crew_death` : n'importe quel membre d'équipage perdu. `both` : l'un ou l'autre. L'équipage meurt souvent, donc
`both` en envoie beaucoup.

#### Death Link Cloned Crew

`death_link_cloned_crew` · `true` / `false` · défaut `false`\
Si un membre d'équipage que la baie de clonage ramène compte comme une mort. Désactivé, seul un membre qui ne
revient pas compte.

#### Death Link Toggle

`death_link_toggle` · `true` / `false` · défaut `true`\
Tu peux couper et remettre Death Link pendant la partie, en cliquant dessus sur la première page du tableau de
bord TAB. Désactive cette option pour un groupe qui veut rester lié jusqu'au bout.

#### Death Link Effect

`death_link_effect` · `major_incident`, `crew_member`, `hull_damage`, `fire`, `boarding`, `varied` · défaut `major_incident`\
Ce que te fait la mort d'un autre joueur. `major_incident` : une brèche et un incendie dans une salle de système,
le plus dur. `crew_member` : un membre d'équipage meurt. `hull_damage` : des dégâts à la coque. `fire` : un
incendie. `boarding` : un Mantis ennemi monte à bord. `varied` : un des quatre plus doux, au hasard.

#### Energy Link

`energy_link` · `true` / `false` · défaut `false`\
Une réserve de carburant partagée avec tous les joueurs Energy Link, quel que soit leur jeu. Ton carburant en trop
y va aux balises calmes (avec 25 % de perte), et tu en récupères quand tu descends sous 3.

#### Trap Link

`trap_link` · `true` / `false` · défaut `false`\
Les pièges sont partagés avec les autres joueurs Trap Link : quand l'un de vous reçoit un piège, les autres en
reçoivent un aussi, même si ta seed n'en a pas. Un piège d'un autre jeu devient le piège FTL le plus proche.

#### Trap Chance

`trap_chance` · 0 à 100 · défaut `0`\
La part des objets de remplissage qui deviennent des pièges. Il y en a 11 sortes : incendie, brèche, fuite de
carburant, dégâts de système, flotte rebelle, dégâts de coque, abordage, vidange d'O2, et trois qui attendent ton
prochain combat (une batterie anti-vaisseau, une surcharge du vaisseau amiral, un danger). Les pièges attendent une
balise calme et ne détruisent jamais ton vaisseau.

#### Crew Names

`crew_names` · `vanilla`, `multiworld`, `multiworld_and_team` · défaut `multiworld`\
Les noms de l'équipage qui te rejoint pendant une run. `multiworld` : les noms de slot des autres joueurs, puis
ceux de FTL. `multiworld_and_team` : pareil, puis les gens qui ont fait et testé le mod. `vanilla` : les noms de
FTL. Ton équipage de départ garde ses noms.

### Expert (YAML seulement)

Ces options ne sont pas dans le créateur d'options, seulement dans le YAML. Presque personne n'en a besoin.

#### Goal

`goal` · `victory_count`, `victory_selection` · défaut `victory_count`\
`victory_count` : gagner avec Victories Required layouts différents. `victory_selection` : gagner avec chaque
layout listé dans **Victory Layouts**, et seulement ceux-là.

#### Victory Layouts

`victory_layouts` · une liste · défaut vide\
Avec `victory_selection`, les layouts qui doivent chacun gagner. Exemple :
`victory_layouts: ["Kestrel Cruiser A", "Mantis Cruiser B"]`. Ils doivent être dans la seed.

#### Minimum Filler

`minimum_filler` · 0 à 100 · défaut `20`\
Le plus petit nombre d'objets de remplissage dans ta seed.

#### Shields, Sensors, Medbay blueprint logic

`shields_blueprint_logic`, `sensors_blueprint_logic`, `medbay_blueprint_logic` · `required`, `upgrade_only`, `start_with` · défaut `upgrade_only`\
`required` : un vaisseau qui commence avec ce système n'est dans la logique qu'une fois que tu as son plan.
`upgrade_only` : le plan sert seulement à améliorer ou acheter le système. `start_with` : tu commences avec le
plan.

#### Engines, Weapon Control blueprint logic

`engines_blueprint_logic`, `weapons_blueprint_logic` · `anywhere`, `early`, `start_with` · défaut `early`\
Tous les vaisseaux commencent avec ces deux systèmes, donc ces options décident seulement quand le plan arrive :
n'importe où, tôt dans tes propres premiers checks, ou dès le départ.

La [page du jeu](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
(en anglais) explique plus en détail la logique, les pièges et les liens.
