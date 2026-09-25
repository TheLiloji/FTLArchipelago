# Installation sous Linux

[English](Setup-Linux.md) · **Français** · [Deutsch](Setup-Linux.de.md) · [Español](Setup-Linux.es.md) ·
[Italiano](Setup-Linux.it.md) · [Português](Setup-Linux.pt.md)

Pour la version Linux native de FTL sur Steam (1.6.13). Ne lance pas FTL avec Proton pour ça : la bibliothèque
Linux ci-dessous ne s'y charge pas. Compte une dizaine de minutes.

## Quoi télécharger

Mets tout dans le même dossier, par exemple `Téléchargements`.

- Sur la [release FTL Archipelago](https://github.com/TheLiloji/FTLArchipelago/releases/latest) :
  `ArchipelagoFTL.ftl` et `Hyperspace.1.6.13.amd64.so`.
- Sur la [release de ftlman](https://github.com/afishhh/ftlman/releases/latest) :
  `ftlman-x86_64-unknown-linux-gnu.tar.gz`.
- Sur la [release Hyperspace 1.23.1](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1) :
  `FTL.Hyperspace.1.23.1-Linux.zip`.

## 1. Protéger tes sauvegardes

Désactive **Steam Cloud** pour FTL (clic droit, Propriétés, Général), puis copie ton dossier de sauvegardes :

```sh
cp -r ~/.local/share/FasterThanLight ~/.local/share/FasterThanLight.backup
```

## 2. Décompresser

Ouvre un terminal dans le dossier des téléchargements :

```sh
tar xzf ftlman-x86_64-unknown-linux-gnu.tar.gz
unzip FTL.Hyperspace.1.23.1-Linux.zip Hyperspace.ftl
cp Hyperspace.ftl ArchipelagoFTL.ftl ftlman/mods/
```

Tu as maintenant ftlman dans `ftlman/ftlman`, et les deux mods dans son dossier `mods`.

## 3. Installer Hyperspace et le mod

Toujours dans le même terminal :

```sh
D=~/.steam/steam/steamapps/common/"FTL Faster Than Light"/data
ftlman/ftlman hyperspace-install 1.23.1 -d "$D"
ftlman/ftlman patch -d "$D" Hyperspace.ftl ArchipelagoFTL.ftl
```

`D` est le dossier du jeu qui contient `FTL.amd64`. Si FTL est dans une autre bibliothèque Steam, change cette
première ligne.

Donne toujours les deux mods, Hyperspace en premier. ftlman refait les données du jeu à partir de zéro à chaque
fois, donc n'appliquer qu'`ArchipelagoFTL.ftl` enlèverait Hyperspace.

## 4. Mettre la bibliothèque Archipelago

Garde la bibliothèque officielle et mets celle d'Archipelago à sa place :

```sh
cp "$D/Hyperspace.1.6.13.amd64.so" "$D/Hyperspace.1.6.13.amd64.so.official"
cp Hyperspace.1.6.13.amd64.so "$D/"
```

## 5. Lancer le jeu

Lance FTL **depuis Steam**, ou avec le script `FTL` du dossier `data`. Lancer `FTL.amd64` directement saute
Hyperspace. Tu dois voir :

![Menu principal après l'installation](../images/connect-panel.jpg)

- `HS-1.23.1 x64` en haut à droite,
- le logo Archipelago en haut à gauche,
- un panneau **Connect to a multiworld** en bas à gauche.

Si le panneau n'est pas là, ou si la connexion ne marche jamais, regarde la [FAQ](FAQ.md) (en anglais).

## Passer à une nouvelle version

Mets le nouveau `ArchipelagoFTL.ftl` dans `ftlman/mods/`, relance la ligne `patch` de l'étape 3, puis refais
l'étape 4 avec le nouveau `Hyperspace.1.6.13.amd64.so`.

Ensuite : [Jouer](Playing.md) (en anglais).
