# Jugar con Multiverse

[English](Multiverse.md) · [Français](Multiverse.fr.md) · [Deutsch](Multiverse.de.md) · **Español** ·
[Italiano](Multiverse.it.md) · [Português](Multiverse.pt.md)

El mod también funciona con **FTL: Multiverse 5.5.1**. Sus naves sustituyen a las del juego base, y sus sectores
también tienen balizas ARCHIPELAGO. Es el mismo `ftl.apworld`: un jugador de Multiverse y uno del juego base
pueden estar en el mismo multiworld.

## Instalación

Sigue la guía de instalación ([Windows](Setup-Windows.es.md), [Linux](Setup-Linux.es.md)) con un cambio: en
ftlman, marca los mods en este orden y luego haz clic en **Apply**.

1. Multiverse **Assets** (5.5)
2. Multiverse **Data** (5.5.1)
3. **ArchipelagoFTL**

Usa la versión Multiverse del mod: la release cuyo nombre termina en `-mv`, como `v0.5.0-mv.1`. Hyperspace sigue
en 1.23.1, como en la guía.

Multiverse y el juego base comparten el perfil de FTL. Si juegas a los dos, o a varias seeds, guarda la carpeta
`FasterThanLight` antes de cambiar (mira «Proteger tus partidas» en la guía).

## Tu YAML

Activa **Multiverse**. En el Options Creator es el primer grupo.

- Siempre empiezas con el **MV Kestrel Cruiser**: Starting Ship se ignora.
- **Layouts in the Seed** elige entre las 55 naves de Multiverse y sus layouts. Todas las demás naves llegan como
  objetos de Archipelago, como en el juego base.
- **Victory Layouts** usa los nombres de Multiverse, como «Union Cruiser B». Una nave con el mismo nombre que una
  del juego base se escribe con «(MV)», como «Kestrel Cruiser (MV)».
- **Shop Weapons** y **Shop Drones** llegan hasta 37 y 14: esa cantidad de las 120 armas y 25 drones de
  Multiverse se elige al azar y la reparte Archipelago; el resto se sigue vendiendo en las tiendas. **Shop
  Augments** puede tomar los 22 aumentos de Multiverse.
- **Multiverse Achievement Checks** añade 26 logros de Multiverse (Accomplishments y Special Events) como checks.
  Solo contienen relleno o trampas, porque algunos son largos o raros.

Las partidas de Multiverse son más largas que las del juego base: cuenta con más tiempo del que indican los
presets.

## Qué cambia en el juego

- Los finales de Multiverse cuentan como victorias, no solo la nave insignia.
- Las variantes de una raza en Multiverse (Zoltan Monk, Separatist Engi, Lanius Welder...) cuentan para el check
  de esa raza, igual que los tripulantes únicos de esa raza, como Turzil el Engi. Las razas propias de
  Multiverse también tienen su check (Crystal, Orchid, Shell, Leech, Phantom, Spider, Lizard). Las raras (Cognitive,
  Siren, Pony, Obelisk) solo tienen relleno: ahí no te espera nada necesario.
- El objetivo, el panel (TAB) y la tienda de Archipelago funcionan igual. La página de naves del panel muestra bajo cada nave la raza de la mayoría de su tripulación.
- Cada personaje de Multiverse que se une a tu tripulación (Turzil, Tully...) da una pista gratis, una vez por seed.
