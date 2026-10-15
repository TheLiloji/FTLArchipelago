# Options

[English](Options.md) · **Français** · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

Tes options tiennent dans un petit fichier texte, le **YAML**. Tu le fais une fois, avant la partie, et tu
l'envoies à la personne qui génère le multiworld.

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
| layout | une version d'un vaisseau (« disposition » dans le jeu) : Kestrel A, Kestrel B et Kestrel C sont trois layouts |
| progressive | un objet qui monte un système d'un niveau à chaque fois que tu le reçois |
| Archives | des objets qu'il te faut en plus de tes victoires pour finir |
| logique | ce que le générateur suppose que tu as avant de te demander un check |

## Le plus simple : prendre un preset

Les presets sont des fichiers YAML tout prêts. Prends celui qui correspond à ton temps :

| Preset | Temps jusqu'au but | Ce que c'est |
|---|---|---|
| `first_game` | environ 3 h | **Ta première partie Archipelago.** 1 victoire, le Facile compte, 3 vaisseaux de type A, 2 Archives sur 3, pas de pièges. Les améliorations et les systèmes reçus viennent à bord tout seuls |
| `short_game` | environ 5 h | 2 victoires en Normal ou Difficile, 4 layouts, 4 Archives sur 5, toutes les améliorations d'un système d'un coup |
| `medium_game` | environ 10 h | les options par défaut : 5 victoires en Normal ou Difficile, 7 layouts, 10 Archives sur 12 |
| `long_game` | 20 h ou plus | 10 victoires, 14 layouts, 16 Archives sur 20, installer un système est un check |

Ils sont dans `presets.zip` sur la [page de release](https://github.com/TheLiloji/FTLArchipelago/releases/latest).
Le haut de chaque fichier dit combien il a de checks et le temps qu'il faut à peu près.

1. Ouvre le fichier dans un éditeur de texte.
2. Remplace la ligne `name:` par ton nom. Utilise seulement des lettres sans accent, des chiffres, des espaces,
   `-` et `_`, et 16 caractères au plus : le panneau de connexion du jeu ne sait rien taper d'autre.
3. Envoie le fichier à la personne qui génère le multiworld.

Les temps valent pour un joueur qui gagne en quelques runs. Si tu découvres FTL, compte plus.

## Faire ton propre YAML

Ouvre **ArchipelagoOptionsCreator** (dans le dossier d'Archipelago), choisis **FTL: Faster Than Light**, tape
ton nom et exporte le YAML. Chaque option a une courte description (en anglais) : passe la souris dessus. Les
réglages par défaut sont ceux du preset `medium_game`.

Trois pièges fréquents :

- **Les victoires en Facile.** Par défaut, seules les victoires en Normal et Difficile comptent pour ton but.
  Si tu joues en Facile, mets **Victory Difficulty** à `any` (tu peux aussi écrire `easy` dans le YAML).
- **Moins de checks ne veut pas dire une partie plus courte.** Couper des secteurs ou des succès ne retire pas
  leurs objets : ils passent dans la boutique Archipelago, où tu les achètes en ferraille. Pour raccourcir une
  partie, baisse plutôt **Victories Required** et **Layouts in the Seed**.
- **Death Link.** Si ton groupe y joue, active-le. Avec **Death Link Trigger** à `both` (par défaut), chaque
  membre d'équipage perdu tue aussi les autres. Dans un gros multiworld ou pour une première partie, choisis
  `ship_destroyed` : seule une run perdue compte.

## Ce que font les options

Le créateur d'options les range en groupes :

- **Goal** : combien de victoires, dans quelle difficulté, et combien d'Archives. Les Archives peuvent être
  n'importe où dans le multiworld, chez toi aussi.
- **Game Size** : quels layouts sont dans la partie et combien, et ce qui envoie des checks : secteurs,
  systèmes, succès, équipage, combats gagnés, boutique Archipelago.
  **Excluded Ships and Layouts** retire les vaisseaux ou les layouts que tu ne veux jamais piloter.
- **Playing with Others** : Death Link, Energy Link (une réserve de carburant partagée), Trap Link, et combien
  de pièges.
- **Advanced** (fermé au départ) : tu n'as pas besoin d'y toucher. Ton premier vaisseau, les Head Starts, la
  langue du mod (elle suit FTL toute seule), les secteurs qui comptent, le déblocage des types B et C, ce qui est
  verrouillé en magasin, les options ci-dessous, et la sévérité de la logique.

Deux sortes de boutiques apparaissent dans les noms. **Shop Weapons**, **Shop Drones**, **Shop Augments** et
**Shop Unlock Mode** parlent des magasins de FTL. Les options **Archipelago Shop** parlent de la boutique
Archipelago : les colis vendus aux balises BOUTIQUE AP, qui contiennent les objets des autres joueurs.

## Nouveau en 0.5

| Option | Ce qu'elle fait |
|---|---|
| **Free Upgrades** | Les niveaux de système reçus sont installés gratuitement, tout de suite et au début de chaque run. Seulement avec Progressive System Upgrades (activé par défaut) |
| **System Install** | Les systèmes dont tu as reçu le plan viennent à bord gratuitement : `run_start` au début de chaque run, `immediately` aussi dès que le plan arrive. Le vaisseau doit avoir une salle pour lui |
| **Run Start Scrap** | Chaque nouvelle run commence avec ce pourcentage de toute la ferraille reçue en objets. 10 à 25 est un bon choix |
| **Combat Checks per Ship** | Avec chaque vaisseau, les premiers combats gagnés d'une run envoient des checks. Ces combats rapportent moins de ferraille (**Combat Check Scrap**) |
| **Victory Collects the Layout** | Ce qu'une victoire envoie en plus : `sectors` (par défaut) les checks de secteur du layout encore à faire, `everything` aussi les succès, les checks de systèmes et de combats de son vaisseau |
| **Sector Logic** | Nouvelle valeur `power` : avant les secteurs lointains et le vaisseau amiral, la logique attend des couches de bouclier, des armes et des moteurs sur le vaisseau qui fait le check |

## Options expertes

Quelques options n'existent que dans le fichier YAML, parce que presque personne n'en a besoin : choisir
exactement quels vaisseaux doivent gagner (`goal: victory_selection` avec `victory_layouts`), le minimum
d'objets de remplissage, et les cinq options `*_blueprint_logic` qui affinent la logique pour les boucliers,
les capteurs, l'infirmerie, les moteurs et les armes. La liste complète, avec chaque détail, est sur la
[page du jeu](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
(en anglais).
