# Installation sous Windows

[English](Setup-Windows.md) · **Français** · [Deutsch](Setup-Windows.de.md) · [Español](Setup-Windows.es.md) ·
[Italiano](Setup-Windows.it.md) · [Português](Setup-Windows.pt.md)

Compte une dizaine de minutes. Il te faut FTL sur Steam (ou GOG), avec le contenu Advanced Edition, présent dans
toutes les copies vendues aujourd'hui.

## Quoi télécharger

Mets tout dans le même dossier, par exemple `Téléchargements`.

- Sur la [release FTL Archipelago](https://github.com/TheLiloji/FTLArchipelago/releases/latest) :
  `ArchipelagoFTL.ftl` et `Hyperspace.dll`.
- Sur la [release de ftlman](https://github.com/afishhh/ftlman/releases/latest) :
  `ftlman-x86_64-pc-windows-gnu.zip`.
- Sur la [release Hyperspace 1.23.1](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1) :
  `FTL.Hyperspace.1.23.1-Windows.zip`.

Décompresse les deux zip. Tu obtiens un dossier `ftlman`, avec `ftlman.exe` et un dossier `mods` vide dedans,
et `Hyperspace.ftl`, qui vient du zip de Hyperspace.

## 1. Protéger tes sauvegardes

- Dans Steam, clic droit sur FTL, **Propriétés**, **Général**, et désactive **Steam Cloud**. Sinon Steam peut
  remettre une vieille sauvegarde pendant que tu joues.
- Copie le dossier `Documents\My Games\FasterThanLight` dans un endroit sûr.

Le mod utilise son propre profil, ta progression FTL normale n'est pas touchée. La copie, c'est au cas où.

## 2. Installer Hyperspace avec ftlman

Lance `ftlman.exe`. En général il trouve le jeu tout seul ; sinon, indique-lui le dossier de FTL (celui qui
contient `FTLGame.exe`, par exemple `C:\Program Files (x86)\Steam\steamapps\common\FTL Faster Than Light`).

Installe **Hyperspace 1.23.1** depuis ftlman. Sur une copie Steam, ftlman passe d'abord FTL en version 1.6.9 et
garde l'original sous le nom `FTLGame_orig.exe`. C'est normal : la 1.6.9 est la seule version Windows sur
laquelle Hyperspace tourne.

## 3. Ajouter le mod

Copie `Hyperspace.ftl` et `ArchipelagoFTL.ftl` dans le dossier `mods`, celui qui est dans le dossier `ftlman`.
Dans ftlman, coche les deux, avec Hyperspace **au-dessus** d'ArchipelagoFTL, et clique sur **Apply**. Ferme
ftlman quand c'est fini.

## 4. Mettre la bibliothèque Archipelago

Dans le dossier de FTL, il y a maintenant un `Hyperspace.dll`. Renomme-le en `Hyperspace.dll.official` (pour le
garder), puis copie à sa place le `Hyperspace.dll` de la release FTL Archipelago.

FTL doit être fermé : Windows bloque le fichier tant que le jeu tourne.

Si un jour tu recliques sur Apply dans ftlman, recopie ensuite le `Hyperspace.dll` d'Archipelago.

## 5. Lancer le jeu

Lance FTL depuis Steam. Tu dois voir :

![Menu principal après l'installation](../images/connect-panel.jpg)

- `HS-1.23.1` en haut à droite,
- le logo Archipelago en haut à gauche,
- un panneau **Connect to a multiworld** en bas à gauche.

Si le panneau n'est pas là, ou si la connexion ne marche jamais, regarde la [FAQ](FAQ.md) (en anglais).

## Passer à une nouvelle version

Mets le nouveau `ArchipelagoFTL.ftl` dans le dossier `mods` de ftlman, clique de nouveau sur **Apply**, puis
recopie le nouveau `Hyperspace.dll` par-dessus celui du dossier de FTL.

Ensuite : [Jouer](Playing.md) (en anglais).
