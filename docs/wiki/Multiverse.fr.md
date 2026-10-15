# Jouer avec Multiverse

[English](Multiverse.md) · **Français** · [Deutsch](Multiverse.de.md) · [Español](Multiverse.es.md) ·
[Italiano](Multiverse.it.md) · [Português](Multiverse.pt.md)

Le mod fonctionne aussi avec **FTL: Multiverse 5.5.1**. Ses vaisseaux remplacent ceux du jeu de base, et ses
secteurs ont eux aussi des balises ARCHIPELAGO. C'est le même `ftl.apworld` : un joueur Multiverse et un joueur
du jeu de base peuvent être dans le même multiworld.

## Installation

Suis le guide d'installation ([Windows](Setup-Windows.fr.md), [Linux](Setup-Linux.fr.md)), avec un seul
changement : dans ftlman, coche les mods dans cet ordre, puis clique sur **Apply**.

1. Multiverse **Assets** (5.5)
2. Multiverse **Data** (5.5.1)
3. **ArchipelagoFTL**

Prends la version Multiverse du mod : la release dont le nom finit par `-mv`, comme `v0.5.0-mv.1`. Hyperspace
reste en 1.23.1, comme dans le guide.

Multiverse et le jeu de base partagent le profil de FTL. Si tu joues aux deux, ou à plusieurs seeds, sauvegarde
le dossier `FasterThanLight` avant de changer (voir « Protéger tes sauvegardes » dans le guide).

## Ton YAML

Active **Multiverse**. Dans le créateur d'options, c'est le premier groupe.

- Tu commences toujours avec le **MV Kestrel Cruiser** : Starting Ship est ignoré.
- **Layouts in the Seed** tire parmi les 55 vaisseaux de Multiverse et leurs dispositions. Tous les autres
  vaisseaux viennent d'objets Archipelago, comme dans le jeu de base.
- **Victory Layouts** prend les noms de Multiverse, comme « Union Cruiser B ». Un vaisseau qui porte le même nom
  qu'un vaisseau du jeu de base s'écrit avec « (MV) », comme « Kestrel Cruiser (MV) ».
- **Shop Weapons** et **Shop Drones** vont jusqu'à 37 et 14 : autant des 120 armes et 25 drones de Multiverse
  sont tirés au hasard et distribués par Archipelago, les autres restent en vente normale dans les magasins.
  **Shop Augments** peut prendre les 22 augmentations de Multiverse.
- **Multiverse Achievement Checks** ajoute 26 succès de Multiverse (Accomplishments et Special Events) comme
  checks. Ils ne contiennent que du remplissage ou des pièges, car certains sont longs ou rares.

Les runs Multiverse sont plus longues que celles du jeu de base : compte plus de temps que ce que disent les
presets.

## Ce qui change en jeu

- Les fins de Multiverse comptent comme des victoires, pas seulement le vaisseau amiral.
- Les variantes d'une race dans Multiverse (Zoltan Monk, Separatist Engi, Lanius Welder...) comptent pour le
  check de cette race, tout comme les équipiers uniques de cette race, comme Turzil l'Engi. Les races propres
  à Multiverse ne comptent pas.
- Le but, le tableau de bord (TAB) et la boutique Archipelago marchent de la même façon. La page Vaisseaux du tableau de bord montre sous chaque vaisseau la race de la plupart de son équipage.
- Chaque personnage de Multiverse qui rejoint ton équipage (Turzil, Tully...) donne un indice gratuit, une fois par seed.
