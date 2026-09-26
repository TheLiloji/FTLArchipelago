# Options

[English](Options.md) · **Français** · [Deutsch](Options.de.md) · [Español](Options.es.md) ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

## Le plus simple : garder les réglages par défaut

Les options par défaut sont celles qu'on recommande. Tu n'as qu'à changer ton nom :

1. Ouvre **ArchipelagoOptionsCreator** (dans le dossier d'Archipelago), ou la page d'options du site qui
   héberge la partie.
2. Choisis **FTL: Faster Than Light**, écris ton nom, et exporte le YAML.

Avec les réglages par défaut, tu gagnes en battant le vaisseau amiral **5 fois avec 5 vaisseaux différents, en
Normal ou en Difficile**, et en réunissant **10 des 12 Archives** cachées dans les mondes des autres joueurs.
C'est une partie de plusieurs soirées, une dizaine d'heures jusqu'à l'objectif.

Si ton groupe joue avec le **Death Link**, active-le. Par défaut, la perte d'un membre d'équipage compte comme
une mort, pas seulement une run perdue.

## Les presets

Tu veux plus court ou plus long ? Choisis un preset en répondant à deux questions : combien de temps as-tu, et
connais-tu bien FTL ?

| | Tu débutes sur FTL | Tu connais bien FTL |
|---|---|---|
| **FTL parmi d'autres jeux**, sessions courtes | `A1_multi_game_beginner` | `A2_multi_game_veteran` |
| **Deux soirées** | `C1_two_evenings_beginner` | `C2_two_evenings_veteran` |
| **FTL tout seul**, une longue partie | `B1_solo_beginner` | `B2_solo_veteran` |

Ils sont dans `presets.zip` sur la [page des releases](https://github.com/TheLiloji/FTLArchipelago/releases/latest),
et dans le menu **Preset** de la page d'options du site. Le haut de chaque fichier donne son nombre de checks et
sa durée approximative. Change la ligne `name:` et c'est prêt.

## À quoi servent les options

Le créateur d'options les range par groupes :

- **Goal** : combien de victoires, dans quelle difficulté, et combien d'Archives.
- **Game Size** : quelles versions des vaisseaux sont dans la partie, et ce qui envoie des checks (secteurs,
  systèmes, succès, équipage, boutique Archipelago). Moins de checks, c'est une partie plus courte.
- **Playing with Others** : Death Link, Energy Link (une réserve de carburant partagée), Trap Link, et la part
  de pièges.
- **Advanced** (fermé au départ) : ton premier vaisseau, les objets Head Start, la langue du mod (il suit celle
  de FTL tout seul), les secteurs qui comptent, comment les Types B et C se débloquent, ce qui est verrouillé
  dans les magasins, et la difficulté de la logique. Tu n'as pas besoin d'y toucher.

Chaque option a une courte description : passe la souris dessus dans le créateur d'options. Les descriptions
sont en anglais, comme partout dans Archipelago.

## Options expertes

Quelques options n'existent que dans le fichier YAML, parce que presque personne n'en a besoin : choisir
exactement quels vaisseaux doivent gagner (`goal: victory_selection` avec `victory_layouts`), le minimum
d'objets de remplissage, et les cinq options `*_blueprint_logic` qui règlent finement la logique pour les
boucliers, les capteurs, l'infirmerie, les moteurs et les armes. La liste complète, avec tous les détails, est
sur la page du jeu (en anglais) : `apworld/ftl/docs/en_FTL Faster Than Light.md`.
