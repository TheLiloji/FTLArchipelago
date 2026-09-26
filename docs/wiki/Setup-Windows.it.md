# Installazione su Windows

[English](Setup-Windows.md) · [Français](Setup-Windows.fr.md) · [Deutsch](Setup-Windows.de.md) · [Español](Setup-Windows.es.md) ·
**Italiano** · [Português](Setup-Windows.pt.md)

*Questa pagina è stata tradotta con l'IA e può contenere errori. In caso di dubbio vale la pagina inglese.*

> [!WARNING]
> **Chiudi FTL prima di iniziare** e lascialo chiuso fino all'ultimo passo. Windows blocca i file del gioco
> mentre FTL è aperto, e l'installazione fallisce senza avvisare.

> [!IMPORTANT]
> In ftlman scegli **Hyperspace 1.23.1**, non una versione più recente. La libreria Archipelago è fatta solo per
> la 1.23.1.

## Cosa scaricare

1. Dalla [release di FTL Archipelago](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
   `ArchipelagoFTL.ftl` e `Hyperspace.dll`.
2. [ftlman](https://github.com/afishhh/ftlman/releases/latest): lo zip per Windows. Estrailo in una cartella
   tutta sua, per esempio `Documents\ftlman`.

Tutto qui: ftlman scarica Hyperspace da solo.

## 1. Proteggere i salvataggi

In Steam, clic destro su FTL, **Proprietà**, **Generale**, e disattiva **Steam Cloud**. Poi copia la cartella
`Documents\My Games\FasterThanLight` in un posto sicuro. Il mod usa un profilo suo, la copia è solo per
sicurezza.

## 2. Controllare la cartella di FTL in ftlman

Avvia `ftlman.exe` e clicca **Settings**:

![Settings](../images/ftlman-1-settings-button.png)

**FTL data directory** deve puntare alla cartella di FTL, quella con `FTLGame.exe`. Di solito ftlman la trova
da solo. Se è vuota o sbagliata, apri la cartella da Steam (clic destro su FTL, **Gestisci**, **Sfoglia file
locali**) e incolla qui il suo percorso. Chiudi la finestra delle impostazioni.

![FTL data directory](../images/ftlman-2-ftl-folder.png)

## 3. Aggiungere il mod

Metti `ArchipelagoFTL.ftl` nella cartella `mods` accanto a `ftlman.exe` (creala se manca). Clicca **Scan** (1):
il mod compare nella lista (2).

![Scan](../images/ftlman-3-scan.png)

## 4. Scegliere Hyperspace 1.23.1

Apri il menu **Hyperspace** (1) e scegli **1.23.1** (2). Non 1.23.2, non «None».

![Hyperspace 1.23.1](../images/ftlman-4-hyperspace.png)

## 5. Applicare

Clicca sul mod finché diventa blu (1), poi su **Apply** (2). Se ftlman propone di portare FTL alla versione
1.6.9, accetta: è l'unica versione Windows su cui gira Hyperspace, e il gioco originale resta come
`FTLGame_orig.exe`. Aspetta che ftlman finisca, poi chiudilo.

![Apply](../images/ftlman-5-apply.png)

## 6. Mettere la libreria Archipelago

> [!WARNING]
> **Da fare dopo Apply, ogni volta che clicchi Apply.** Apply rimette la `Hyperspace.dll` ufficiale, e con quella
> il mod non può collegarsi a un server.

Apri la cartella di FTL (da Steam: clic destro su FTL, **Gestisci**, **Sfoglia file locali**). Copiaci dentro la
`Hyperspace.dll` scaricata dalla release di FTL Archipelago e scegli **Sostituisci il file**.

## 7. Avviare il gioco

Avvia FTL da Steam. Nel menu principale dovresti vedere il logo Archipelago in alto a sinistra e un pannello
**Connettersi a un multiworld** in basso a sinistra:

![Main menu](../images/connect-panel.jpg)

Se il pannello manca o la connessione non funziona mai, guarda le [FAQ](FAQ.md) (in inglese).

## Aggiornare a una nuova versione

Chiudi FTL. Metti il nuovo `ArchipelagoFTL.ftl` nella cartella `mods` di ftlman, clicca **Apply**, poi ricopia
la nuova `Hyperspace.dll` nella cartella di FTL.

Poi: [Playing](Playing.md) (in inglese).
