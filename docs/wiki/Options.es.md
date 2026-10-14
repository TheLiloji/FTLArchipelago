# Opciones

[English](Options.md) · [Français](Options.fr.md) · [Deutsch](Options.de.md) · **Español** ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

Tus opciones caben en un pequeño archivo de texto, el **YAML**. Lo haces una vez, antes de la partida, y se lo
envías a la persona que genera el multiworld.

## Antes de empezar

Necesitas **Archipelago 0.6.7**, con el `ftl.apworld` de la
[página de la release](https://github.com/TheLiloji/FTLArchipelago/releases/latest) en su carpeta
`custom_worlds`. Sin él, FTL no aparece en la lista. Las guías de instalación ([Windows](Setup-Windows.es.md),
[Linux](Setup-Linux.es.md)) explican cada paso.

## Algunas palabras que verás

| Palabra | Significado |
|---|---|
| check | algo que haces en el juego y que envía un objeto: llegar a un sector, ganar, un logro... |
| objeto (item) | lo que un check te da a ti o a otro jugador: una nave, un sistema, un arma, chatarra... |
| seed | la partida generada, la misma para todo el multiworld |
| slot | tu sitio en el multiworld, con el nombre de la línea `name:` de tu YAML |
| layout | una versión de una nave: Kestrel A, Kestrel B y Kestrel C son tres layouts |
| progressive | un objeto que sube un sistema un nivel cada vez que lo recibes |
| Archivos | objetos que necesitas además de tus victorias para terminar |
| lógica | lo que el generador supone que tienes antes de pedirte un check |

## Lo más fácil: elegir un preset

Los presets son archivos YAML ya hechos. Elige el que encaje con tu tiempo:

| Preset | Tiempo hasta el objetivo | Qué es |
|---|---|---|
| `first_game` | unas 3 h | **Tu primera partida de Archipelago.** 1 victoria, Fácil cuenta, 3 naves de tipo A, 2 Archivos de 3, sin trampas. Las mejoras y los sistemas que recibes suben a bordo solos |
| `short_game` | unas 5 h | 2 victorias en Normal o Difícil, 4 layouts, 4 Archivos de 5, todas las mejoras de un sistema de golpe |
| `medium_game` | unas 10 h | las opciones por defecto: 5 victorias en Normal o Difícil, 7 layouts, 10 Archivos de 12 |
| `long_game` | 20 h o más | 10 victorias, 14 layouts, 16 Archivos de 20, instalar un sistema es un check |

Están en `presets.zip` en la [página de la release](https://github.com/TheLiloji/FTLArchipelago/releases/latest).
El principio de cada archivo dice cuántos checks tiene y cuánto dura más o menos.

1. Abre el archivo en un editor de texto.
2. Cambia la línea `name:` por tu nombre. Usa solo letras sin tilde ni ñ, cifras, espacios, `-` y `_`, y 16
   caracteres como mucho: el panel de conexión del juego no sabe escribir nada más.
3. Envía el archivo a la persona que genera el multiworld.

Los tiempos son para alguien que gana en pocas partidas. Si FTL es nuevo para ti, cuenta con más.

## Hacer tu propio YAML

Abre **ArchipelagoOptionsCreator** (en la carpeta de Archipelago), elige **FTL: Faster Than Light**, escribe
tu nombre y exporta el YAML. Cada opción tiene una breve descripción (en inglés): pasa el ratón por encima. Los
valores por defecto son los del preset `medium_game`.

Tres errores frecuentes:

- **Victorias en Fácil.** Por defecto solo cuentan para tu objetivo las victorias en Normal y Difícil. Si juegas
  en Fácil, pon **Victory Difficulty** en `any` (en el YAML también vale `easy`).
- **Menos checks no es una partida más corta.** Desactivar sectores o logros no quita sus objetos: pasan a la
  tienda de Archipelago, donde los compras con chatarra. Para acortar una partida, baja mejor **Victories
  Required** y **Layouts in the Seed**.
- **Death Link.** Si tu grupo juega con él, actívalo. Con **Death Link Trigger** en `both` (por defecto), cada
  tripulante que pierdes mata también a los demás. En un multiworld grande o en una primera partida, elige
  `ship_destroyed`: solo cuenta una partida perdida.

## Qué hacen las opciones

El Options Creator las muestra por grupos:

- **Goal**: cuántas victorias, en qué dificultad, y cuántos Archivos. Los Archivos pueden estar en cualquier
  parte del multiworld, también en tu propio mundo.
- **Game Size**: qué layouts hay en la partida y cuántos, y qué envía checks: sectores, sistemas, logros,
  tripulación, combates ganados, la tienda de Archipelago.
  **Excluded Ships and Layouts** quita las naves o los layouts que nunca quieres pilotar.
- **Playing with Others**: Death Link, Energy Link (una reserva de combustible compartida), Trap Link, y cuántas
  trampas.
- **Advanced** (cerrado al principio): no hace falta tocarlo. Tu primera nave, los Head Starts, el idioma del mod
  (sigue a FTL solo), qué sectores cuentan, cómo se desbloquean los tipos B y C, qué está bloqueado en las
  tiendas, las opciones de abajo, y lo exigente que es la lógica.

En los nombres aparecen dos tipos de tienda. **Shop Weapons**, **Shop Drones**, **Shop Augments** y **Shop
Unlock Mode** hablan de las tiendas de FTL. Las opciones **Archipelago Shop** hablan de la tienda de
Archipelago: los paquetes que se venden en las balizas ARCHIPELAGO, con objetos de otros jugadores.

## Novedades de la 0.5

| Opción | Qué hace |
|---|---|
| **Free Upgrades** | Los niveles de sistema que recibes se instalan gratis, al momento y al inicio de cada partida. Solo con Progressive System Upgrades (activado por defecto) |
| **System Install** | Los sistemas cuyo plano recibiste suben a bordo gratis: `run_start` al inicio de cada partida, `immediately` también en cuanto llega el plano. La nave necesita una sala para él |
| **Run Start Scrap** | Cada partida nueva empieza con este porcentaje de toda la chatarra recibida en objetos. Entre 10 y 25 va bien |
| **Combat Checks per Ship** | Con cada nave, los primeros combates ganados en una partida envían checks. Esos combates dan menos chatarra (**Combat Check Scrap**) |
| **Victory Collects the Layout** | Lo que una victoria envía además: `sectors` (por defecto) los checks de sector del layout aún pendientes, `everything` también los logros y los checks de sistemas y de combates de su nave |
| **Sector Logic** | Nuevo valor `power`: antes de los sectores lejanos y de la nave insignia, la lógica espera capas de escudo, armas y motores en la nave que hace el check |

## Opciones para expertos

Algunas opciones solo existen en el archivo YAML, porque casi nadie las necesita: elegir exactamente qué naves
deben ganar (`goal: victory_selection` con `victory_layouts`), el mínimo de objetos de relleno, y las cinco
opciones `*_blueprint_logic` que ajustan la lógica para escudos, sensores, enfermería, motores y armas. La lista
completa, con todos los detalles, está en la
[página del juego](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
(en inglés).
