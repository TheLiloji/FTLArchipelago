# Installazione su Linux

[English](Setup-Linux.md) · [Français](Setup-Linux.fr.md) · [Deutsch](Setup-Linux.de.md) ·
[Español](Setup-Linux.es.md) · **Italiano** · [Português](Setup-Linux.pt.md)

*Questa pagina è stata tradotta con l'IA e può contenere errori. In caso di dubbio, vale la pagina in inglese.*

Per la versione Linux nativa di FTL su Steam (1.6.13). Non avviare FTL con Proton per questo: la libreria Linux
qui sotto lì non si carica. Ci vogliono circa dieci minuti.

## Cosa scaricare

Metti tutto nella stessa cartella, per esempio `Download`.

- Dalla [release di FTL Archipelago](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
  `ArchipelagoFTL.ftl` e `Hyperspace.1.6.13.amd64.so`.
- Dalla [release di ftlman](https://github.com/afishhh/ftlman/releases/latest):
  `ftlman-x86_64-unknown-linux-gnu.tar.gz`.
- Dalla [release di Hyperspace 1.23.1](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1):
  `FTL.Hyperspace.1.23.1-Linux.zip`.

## 1. Proteggere i salvataggi

Disattiva **Steam Cloud** per FTL (clic destro, Proprietà, Generali), poi copia la cartella dei salvataggi:

```sh
cp -r ~/.local/share/FasterThanLight ~/.local/share/FasterThanLight.backup
```

## 2. Estrarre

Apri un terminale nella cartella dei download:

```sh
tar xzf ftlman-x86_64-unknown-linux-gnu.tar.gz
unzip FTL.Hyperspace.1.23.1-Linux.zip Hyperspace.ftl
cp Hyperspace.ftl ArchipelagoFTL.ftl ftlman/mods/
```

Ora hai ftlman in `ftlman/ftlman`, e le due mod nella sua cartella `mods`.

## 3. Installare Hyperspace e la mod

Nello stesso terminale:

```sh
D=~/.steam/steam/steamapps/common/"FTL Faster Than Light"/data
ftlman/ftlman hyperspace-install 1.23.1 -d "$D"
ftlman/ftlman patch -d "$D" Hyperspace.ftl ArchipelagoFTL.ftl
```

`D` è la cartella del gioco che contiene `FTL.amd64`. Se FTL è in un'altra libreria di Steam, cambia questa prima
riga.

Indica sempre entrambe le mod, Hyperspace per prima. ftlman ricostruisce i dati del gioco da zero ogni volta,
quindi applicare solo `ArchipelagoFTL.ftl` toglierebbe Hyperspace.

## 4. Mettere la libreria di Archipelago

Tieni la libreria ufficiale e metti quella di Archipelago al suo posto:

```sh
cp "$D/Hyperspace.1.6.13.amd64.so" "$D/Hyperspace.1.6.13.amd64.so.official"
cp Hyperspace.1.6.13.amd64.so "$D/"
```

## 5. Avviare il gioco

Avvia FTL **da Steam**, o con lo script `FTL` nella cartella `data`. Se avvii `FTL.amd64` direttamente, Hyperspace
non viene caricato. Dovresti vedere:

![Menu principale dopo l'installazione](../images/connect-panel.jpg)

- `HS-1.23.1 x64` in alto a destra,
- il logo di Archipelago in alto a sinistra,
- un pannello **Connect to a multiworld** in basso a sinistra.

Se il pannello manca, o la connessione non funziona mai, guarda le [FAQ](FAQ.md) (in inglese).

## Aggiornare a una nuova versione

Metti il nuovo `ArchipelagoFTL.ftl` in `ftlman/mods/`, rilancia la riga `patch` del passo 3, poi il passo 4 con
il nuovo `Hyperspace.1.6.13.amd64.so`.

Avanti: [Giocare](Playing.md) (in inglese).
