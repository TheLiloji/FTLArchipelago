# Installation sous Windows

[English](Setup-Windows.md) · **Français** · [Deutsch](Setup-Windows.de.md) · [Español](Setup-Windows.es.md) ·
[Italiano](Setup-Windows.it.md) · [Português](Setup-Windows.pt.md)

> [!WARNING]
> **Ferme FTL avant de commencer**, et laisse-le fermé jusqu'à la dernière étape. Windows verrouille les fichiers
> du jeu tant que FTL tourne, et l'installation échoue sans rien dire.

> [!IMPORTANT]
> Choisis **Hyperspace 1.23.1** dans ftlman, pas une version plus récente. La bibliothèque Archipelago est faite
> pour la 1.23.1 uniquement.

## Quoi télécharger

1. Sur la [release FTL Archipelago](https://github.com/TheLiloji/FTLArchipelago/releases/latest) :
   `ArchipelagoFTL.ftl` et `Hyperspace.dll`.
2. [ftlman](https://github.com/afishhh/ftlman/releases/latest) : le zip Windows. Décompresse-le dans un dossier
   à lui, par exemple `Documents\ftlman`.

C'est tout : ftlman télécharge Hyperspace tout seul.

## 1. Protéger tes sauvegardes

Dans Steam, clic droit sur FTL, **Propriétés**, **Général**, et désactive **Steam Cloud**. Copie ensuite le
dossier `Documents\My Games\FasterThanLight` dans un endroit sûr. Le mod utilise son propre profil, la copie
c'est juste au cas où.

## 2. Vérifier le dossier de FTL dans ftlman

Lance `ftlman.exe` et clique sur **Settings** :

![Bouton Settings](../images/ftlman-1-settings-button.png)

**FTL data directory** doit pointer vers le dossier de FTL, celui qui contient `FTLGame.exe`. En général ftlman
le trouve tout seul. S'il est vide ou faux, trouve le dossier depuis Steam (clic droit sur FTL, **Gérer**,
**Parcourir les fichiers locaux**) et colle son chemin ici. Ferme la fenêtre des réglages.

![FTL data directory](../images/ftlman-2-ftl-folder.png)

## 3. Ajouter le mod

Mets `ArchipelagoFTL.ftl` dans le dossier `mods` à côté de `ftlman.exe` (crée le dossier s'il n'existe pas).
Clique sur **Scan** (1) : le mod apparaît dans la liste (2).

![Scan](../images/ftlman-3-scan.png)

## 4. Choisir Hyperspace 1.23.1

Ouvre le menu **Hyperspace** (1) et choisis **1.23.1** (2). Pas 1.23.2, pas « None ».

![Hyperspace 1.23.1](../images/ftlman-4-hyperspace.png)

## 5. Appliquer

Clique sur le mod pour qu'il devienne bleu (1), puis sur **Apply** (2). Si ftlman propose de passer FTL en
version 1.6.9, accepte : c'est la seule version Windows sur laquelle Hyperspace fonctionne, et ton jeu
d'origine est gardé sous le nom `FTLGame_orig.exe`. Attends que ftlman ait fini, puis ferme-le.

![Apply](../images/ftlman-5-apply.png)

## 6. Mettre la bibliothèque Archipelago

> [!WARNING]
> **À faire après Apply, à chaque fois que tu cliques sur Apply.** Apply remet le `Hyperspace.dll` officiel, et
> avec lui le mod ne peut pas se connecter à un serveur.

Ouvre le dossier de FTL (depuis Steam : clic droit sur FTL, **Gérer**, **Parcourir les fichiers locaux**).
Copie dedans le `Hyperspace.dll` téléchargé sur la release FTL Archipelago, et choisis **Remplacer le fichier**.

## 7. Lancer le jeu

Lance FTL depuis Steam. Sur le menu principal, tu dois voir le logo Archipelago en haut à gauche et un panneau
**Se connecter à un multiworld** en bas à gauche :

![Menu principal après l'installation](../images/connect-panel.jpg)

Si le panneau n'est pas là, ou si la connexion ne marche jamais, regarde la [FAQ](FAQ.md) (en anglais).
Ensuite : [Playing](Playing.md) (en anglais).

## Passer à une nouvelle version

Ferme FTL. Mets le nouveau `ArchipelagoFTL.ftl` dans le dossier `mods` de ftlman, clique sur **Apply**, puis
recopie le nouveau `Hyperspace.dll` dans le dossier de FTL.
