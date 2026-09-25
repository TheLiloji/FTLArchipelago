# Installazione su Windows

[English](Setup-Windows.md) · [Français](Setup-Windows.fr.md) · [Deutsch](Setup-Windows.de.md) ·
[Español](Setup-Windows.es.md) · **Italiano** · [Português](Setup-Windows.pt.md)

*Questa pagina è stata tradotta con l'IA e può contenere errori. In caso di dubbio, vale la pagina in inglese.*

Ci vogliono circa dieci minuti. Ti serve FTL da Steam (o GOG), con i contenuti della Advanced Edition, presenti in
tutte le copie vendute oggi.

## Cosa scaricare

Metti tutto nella stessa cartella, per esempio `Download`.

- Dalla [release di FTL Archipelago](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
  `ArchipelagoFTL.ftl` e `Hyperspace.dll`.
- Dalla [release di ftlman](https://github.com/afishhh/ftlman/releases/latest):
  `ftlman-x86_64-pc-windows-gnu.zip`.
- Dalla [release di Hyperspace 1.23.1](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1):
  `FTL.Hyperspace.1.23.1-Windows.zip`.

Estrai i due zip. Ottieni una cartella `ftlman`, con dentro `ftlman.exe` e una cartella `mods` vuota, e
`Hyperspace.ftl`, che viene dallo zip di Hyperspace.

## 1. Proteggere i salvataggi

- In Steam, clic destro su FTL, **Proprietà**, **Generali**, e disattiva **Steam Cloud**. Altrimenti Steam può
  rimettere un vecchio salvataggio mentre giochi.
- Copia la cartella `Documents\My Games\FasterThanLight` in un posto sicuro.

La mod usa un profilo suo, quindi i tuoi progressi normali di FTL non vengono toccati. La copia è solo per
sicurezza.

## 2. Installare Hyperspace con ftlman

Avvia `ftlman.exe`. Di solito trova il gioco da solo; altrimenti indicagli la cartella di FTL (quella con
`FTLGame.exe`, per esempio `C:\Program Files (x86)\Steam\steamapps\common\FTL Faster Than Light`).

Installa **Hyperspace 1.23.1** da ftlman. Su una copia Steam, ftlman prima porta FTL alla versione 1.6.9 e tiene
l'originale come `FTLGame_orig.exe`. È normale: la 1.6.9 è l'unica versione Windows su cui gira Hyperspace.

## 3. Aggiungere la mod

Copia `Hyperspace.ftl` e `ArchipelagoFTL.ftl` nella cartella `mods`, quella dentro la cartella `ftlman`. In
ftlman, spunta entrambe, con Hyperspace **sopra** ArchipelagoFTL, e clicca su **Apply**. Chiudi ftlman quando ha
finito.

## 4. Mettere la libreria di Archipelago

Nella cartella di FTL ora c'è un `Hyperspace.dll`. Rinominalo in `Hyperspace.dll.official` (per tenerlo), poi
copia al suo posto il `Hyperspace.dll` della release di FTL Archipelago.

FTL deve essere chiuso: Windows blocca il file mentre il gioco è aperto.

Se un giorno clicchi di nuovo su Apply in ftlman, dopo ricopia l'`Hyperspace.dll` di Archipelago.

## 5. Avviare il gioco

Avvia FTL da Steam. Dovresti vedere:

![Menu principale dopo l'installazione](../images/connect-panel.jpg)

- `HS-1.23.1` in alto a destra,
- il logo di Archipelago in alto a sinistra,
- un pannello **Connect to a multiworld** in basso a sinistra.

Se il pannello manca, o la connessione non funziona mai, guarda le [FAQ](FAQ.md) (in inglese).

## Aggiornare a una nuova versione

Metti il nuovo `ArchipelagoFTL.ftl` nella cartella `mods` di ftlman, clicca di nuovo su **Apply**, poi copia il
nuovo `Hyperspace.dll` sopra quello nella cartella di FTL.

Avanti: [Giocare](Playing.md) (in inglese).
