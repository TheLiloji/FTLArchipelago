# Instalación en Windows

[English](Setup-Windows.md) · [Français](Setup-Windows.fr.md) · [Deutsch](Setup-Windows.de.md) · **Español** ·
[Italiano](Setup-Windows.it.md) · [Português](Setup-Windows.pt.md)

*Esta página se tradujo con IA y puede tener errores. En caso de duda, vale la página en inglés.*

Lleva unos diez minutos. Necesitas FTL de Steam (o GOG), con el contenido de la Advanced Edition, que traen todas
las copias que se venden hoy.

## Qué descargar

Pon todo en la misma carpeta, por ejemplo `Descargas`.

- De la [release de FTL Archipelago](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
  `ArchipelagoFTL.ftl` y `Hyperspace.dll`.
- De la [release de ftlman](https://github.com/afishhh/ftlman/releases/latest):
  `ftlman-x86_64-pc-windows-gnu.zip`.
- De la [release de Hyperspace 1.23.1](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1):
  `FTL.Hyperspace.1.23.1-Windows.zip`.

Descomprime los dos zip. Obtienes una carpeta `ftlman`, con `ftlman.exe` y una carpeta `mods` vacía dentro, y
`Hyperspace.ftl`, que viene del zip de Hyperspace.

## 1. Proteger tus partidas guardadas

- En Steam, clic derecho en FTL, **Propiedades**, **General**, y desactiva **Steam Cloud**. Si no, Steam puede
  volver a poner una partida antigua mientras juegas.
- Copia la carpeta `Documents\My Games\FasterThanLight` en un lugar seguro.

El mod usa un perfil propio, así que tu progreso normal de FTL no se toca. La copia es por si acaso.

## 2. Instalar Hyperspace con ftlman

Abre `ftlman.exe`. Normalmente encuentra el juego solo; si no, indícale la carpeta de FTL (la que tiene
`FTLGame.exe`, por ejemplo `C:\Program Files (x86)\Steam\steamapps\common\FTL Faster Than Light`).

Instala **Hyperspace 1.23.1** desde ftlman. En una copia de Steam, ftlman primero cambia FTL a la versión 1.6.9 y
guarda la original como `FTLGame_orig.exe`. Es normal: la 1.6.9 es la única versión de Windows en la que funciona
Hyperspace.

## 3. Añadir el mod

Copia `Hyperspace.ftl` y `ArchipelagoFTL.ftl` en la carpeta `mods`, la que está dentro de la carpeta `ftlman`.
En ftlman, marca los dos, con Hyperspace **encima** de ArchipelagoFTL, y haz clic en **Apply**. Cierra ftlman al
terminar.

## 4. Poner la biblioteca de Archipelago

En la carpeta de FTL ahora hay un `Hyperspace.dll`. Cámbiale el nombre a `Hyperspace.dll.official` (para
guardarlo) y copia en su lugar el `Hyperspace.dll` de la release de FTL Archipelago.

FTL tiene que estar cerrado: Windows bloquea el archivo mientras el juego está abierto.

Si algún día vuelves a hacer clic en Apply en ftlman, copia de nuevo después el `Hyperspace.dll` de Archipelago.

## 5. Iniciar el juego

Inicia FTL desde Steam. Deberías ver:

![Menú principal después de instalar](../images/connect-panel.jpg)

- `HS-1.23.1` arriba a la derecha,
- el logo de Archipelago arriba a la izquierda,
- un panel **Connect to a multiworld** abajo a la izquierda.

Si falta el panel, o la conexión nunca funciona, mira las [preguntas frecuentes](FAQ.md) (en inglés).

## Actualizar a una versión nueva

Pon el nuevo `ArchipelagoFTL.ftl` en la carpeta `mods` de ftlman, haz clic otra vez en **Apply** y copia el nuevo
`Hyperspace.dll` encima del que hay en la carpeta de FTL.

Siguiente: [Jugar](Playing.md) (en inglés).
