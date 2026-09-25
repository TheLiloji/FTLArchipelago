# Instalación en Linux

[English](Setup-Linux.md) · [Français](Setup-Linux.fr.md) · [Deutsch](Setup-Linux.de.md) · **Español** ·
[Italiano](Setup-Linux.it.md) · [Português](Setup-Linux.pt.md)

*Esta página se tradujo con IA y puede tener errores. En caso de duda, vale la página en inglés.*

Para la versión nativa de Linux de FTL en Steam (1.6.13). No inicies FTL con Proton para esto: la biblioteca de
Linux de abajo no se carga ahí. Lleva unos diez minutos.

## Qué descargar

Pon todo en la misma carpeta, por ejemplo `Descargas`.

- De la [release de FTL Archipelago](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
  `ArchipelagoFTL.ftl` y `Hyperspace.1.6.13.amd64.so`.
- De la [release de ftlman](https://github.com/afishhh/ftlman/releases/latest):
  `ftlman-x86_64-unknown-linux-gnu.tar.gz`.
- De la [release de Hyperspace 1.23.1](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1):
  `FTL.Hyperspace.1.23.1-Linux.zip`.

## 1. Proteger tus partidas guardadas

Desactiva **Steam Cloud** para FTL (clic derecho, Propiedades, General) y copia tu carpeta de partidas:

```sh
cp -r ~/.local/share/FasterThanLight ~/.local/share/FasterThanLight.backup
```

## 2. Descomprimir

Abre una terminal en la carpeta de las descargas:

```sh
tar xzf ftlman-x86_64-unknown-linux-gnu.tar.gz
unzip FTL.Hyperspace.1.23.1-Linux.zip Hyperspace.ftl
cp Hyperspace.ftl ArchipelagoFTL.ftl ftlman/mods/
```

Ahora tienes ftlman en `ftlman/ftlman`, y los dos mods en su carpeta `mods`.

## 3. Instalar Hyperspace y el mod

En la misma terminal:

```sh
D=~/.steam/steam/steamapps/common/"FTL Faster Than Light"/data
ftlman/ftlman hyperspace-install 1.23.1 -d "$D"
ftlman/ftlman patch -d "$D" Hyperspace.ftl ArchipelagoFTL.ftl
```

`D` es la carpeta del juego que contiene `FTL.amd64`. Si FTL está en otra biblioteca de Steam, cambia esa primera
línea.

Pon siempre los dos mods, Hyperspace primero. ftlman rehace los datos del juego desde cero cada vez, así que
aplicar solo `ArchipelagoFTL.ftl` quitaría Hyperspace.

## 4. Poner la biblioteca de Archipelago

Guarda la biblioteca oficial y pon la de Archipelago en su lugar:

```sh
cp "$D/Hyperspace.1.6.13.amd64.so" "$D/Hyperspace.1.6.13.amd64.so.official"
cp Hyperspace.1.6.13.amd64.so "$D/"
```

## 5. Iniciar el juego

Inicia FTL **desde Steam**, o con el script `FTL` de la carpeta `data`. Si abres `FTL.amd64` directamente, no se
carga Hyperspace. Deberías ver:

![Menú principal después de instalar](../images/connect-panel.jpg)

- `HS-1.23.1 x64` arriba a la derecha,
- el logo de Archipelago arriba a la izquierda,
- un panel **Connect to a multiworld** abajo a la izquierda.

Si falta el panel, o la conexión nunca funciona, mira las [preguntas frecuentes](FAQ.md) (en inglés).

## Actualizar a una versión nueva

Pon el nuevo `ArchipelagoFTL.ftl` en `ftlman/mods/`, vuelve a ejecutar la línea `patch` del paso 3 y luego el
paso 4 con el nuevo `Hyperspace.1.6.13.amd64.so`.

Siguiente: [Jugar](Playing.md) (en inglés).
