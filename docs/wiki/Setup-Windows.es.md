# Instalación en Windows

[English](Setup-Windows.md) · [Français](Setup-Windows.fr.md) · [Deutsch](Setup-Windows.de.md) · **Español** ·
[Italiano](Setup-Windows.it.md) · [Português](Setup-Windows.pt.md)

*Esta página se tradujo con IA y puede tener errores. Si hay dudas, manda la página en inglés.*

> [!WARNING]
> **Cierra FTL antes de empezar** y déjalo cerrado hasta el último paso. Windows bloquea los archivos del
> juego mientras FTL está abierto, y la instalación falla sin avisar.

> [!IMPORTANT]
> Elige **Hyperspace 1.23.1** en ftlman, no una versión más nueva. La biblioteca de Archipelago solo sirve para
> la 1.23.1.

## Qué descargar

1. De la [release de FTL Archipelago](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
   `ArchipelagoFTL.ftl` y `Hyperspace.dll`.
2. [ftlman](https://github.com/afishhh/ftlman/releases/latest): el zip de Windows. Descomprímelo en una carpeta
   propia, por ejemplo `Documents\ftlman`.

Eso es todo: ftlman descarga Hyperspace por sí solo.

## 1. Proteger tus partidas

En Steam, clic derecho en FTL, **Propiedades**, **General**, y desactiva **Steam Cloud**. Luego copia la
carpeta `Documents\My Games\FasterThanLight` a un lugar seguro. El mod usa un perfil propio, la copia es solo
por si acaso.

## 2. Comprobar la carpeta de FTL en ftlman

Abre `ftlman.exe` y pulsa **Settings**:

![Settings](../images/ftlman-1-settings-button.png)

**FTL data directory** debe apuntar a la carpeta de FTL, la que tiene `FTLGame.exe`. Normalmente ftlman la
encuentra solo. Si está vacía o mal, busca la carpeta desde Steam (clic derecho en FTL, **Administrar**,
**Ver archivos locales**) y pega su ruta aquí. Cierra la ventana de ajustes.

![FTL data directory](../images/ftlman-2-ftl-folder.png)

## 3. Añadir el mod

Pon `ArchipelagoFTL.ftl` en la carpeta `mods` junto a `ftlman.exe` (créala si no existe). Pulsa **Scan** (1):
el mod aparece en la lista (2).

![Scan](../images/ftlman-3-scan.png)

## 4. Elegir Hyperspace 1.23.1

Abre el menú **Hyperspace** (1) y elige **1.23.1** (2). Ni 1.23.2 ni «None».

![Hyperspace 1.23.1](../images/ftlman-4-hyperspace.png)

## 5. Aplicar

Haz clic en el mod para que se ponga azul (1) y luego en **Apply** (2). Si ftlman ofrece pasar FTL a la
versión 1.6.9, acepta: es la única versión de Windows en la que funciona Hyperspace, y tu juego original se
guarda como `FTLGame_orig.exe`. Espera a que ftlman termine y ciérralo.

![Apply](../images/ftlman-5-apply.png)

## 6. Poner la biblioteca de Archipelago

> [!WARNING]
> **Hazlo después de Apply, cada vez que pulses Apply.** Apply vuelve a poner el `Hyperspace.dll` oficial, y con
> él el mod no puede conectarse a un servidor.

Abre la carpeta de FTL (en Steam: clic derecho en FTL, **Administrar**, **Ver archivos locales**). Copia dentro el
`Hyperspace.dll` descargado de la release de FTL Archipelago y elige **Reemplazar el archivo**.

## 7. Iniciar el juego

Inicia FTL desde Steam. En el menú principal deberías ver el logo de Archipelago arriba a la izquierda y un panel
**Conectarse a un multiworld** abajo a la izquierda:

![Main menu](../images/connect-panel.jpg)

Si falta el panel o la conexión nunca funciona, mira las [FAQ](FAQ.md) (en inglés).

## Actualizar a una versión nueva

Cierra FTL. Pon el nuevo `ArchipelagoFTL.ftl` en la carpeta `mods` de ftlman, pulsa **Apply** y vuelve a copiar
el nuevo `Hyperspace.dll` en la carpeta de FTL.

Siguiente: [Playing](Playing.md) (en inglés).
