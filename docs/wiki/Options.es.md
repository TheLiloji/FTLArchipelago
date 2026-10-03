# Opciones

[English](Options.md) · [Français](Options.fr.md) · [Deutsch](Options.de.md) · **Español** ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

*Esta página se tradujo con IA y puede tener errores. En caso de duda, vale la página en inglés.*

## Lo más fácil: dejar los valores por defecto

Las opciones por defecto son las recomendadas. Solo tienes que cambiar tu nombre:

1. Abre **ArchipelagoOptionsCreator** (en la carpeta de Archipelago), o la página de opciones de la web que
   aloja la partida.
2. Elige **FTL: Faster Than Light**, escribe tu nombre y exporta el YAML.

Con los valores por defecto, ganas al vencer a la nave insignia **5 veces con 5 naves distintas, en Normal o
Difícil**, y al reunir **10 de los 12 Archivos** escondidos en los mundos de los demás jugadores. Es una partida
de varias tardes, unas 10 horas hasta el objetivo.

Si tu grupo juega con **Death Link**, actívalo. Por defecto, perder a un tripulante cuenta como una muerte, no
solo perder la partida. Un tripulante que la bahía de clonación trae de vuelta no cuenta.

## Presets

¿Quieres algo más corto o más largo? Elige el preset según el tiempo que tengas:

| Preset | Tiempo hasta el objetivo | Qué cambia |
|---|---|---|
| `short_game` | unas 5 h | 2 victorias, 4 versiones de naves, 4 Archivos de 5, todas las mejoras de un sistema a la vez |
| `medium_game` | unas 10 h | nada: son las opciones por defecto |
| `long_game` | 20 h o más | 10 victorias, 14 versiones de naves, 16 Archivos de 20, instalar un sistema es un check |

Están en `presets.zip` en la [página de releases](https://github.com/TheLiloji/FTLArchipelago/releases/latest),
y en el menú **Preset** de la página de opciones de la web. Arriba de cada archivo pone cuántos checks tiene y
cuánto dura más o menos. Cambia la línea `name:` y listo.

## Qué hacen las opciones

El Options Creator las muestra en grupos:

- **Goal**: cuántas victorias, en qué dificultad, y cuántos Archivos.
- **Game Size**: qué versiones de las naves entran en la partida y cuántas (7 al azar por defecto), y qué
  envía checks (sectores, sistemas, logros, tripulación, la tienda Archipelago). Menos checks es una partida más corta.
- **Playing with Others**: Death Link, Energy Link (una reserva de combustible compartida), Trap Link, y
  cuántas trampas.
- **Advanced** (cerrado al principio): tu primera nave, los objetos Head Start, el idioma del mod (sigue el de
  FTL solo), qué sectores cuentan, cómo se desbloquean los Tipos B y C, qué está bloqueado en las tiendas y lo
  dura que es la lógica. No hace falta tocarlo.

Cada opción tiene una descripción corta: pasa el ratón por encima en el Options Creator. Las descripciones están
en inglés, como en todo Archipelago.

## Opciones de experto

Algunas opciones solo existen en el archivo YAML, porque casi nadie las necesita: elegir exactamente qué naves
deben ganar (`goal: victory_selection` con `victory_layouts`), el mínimo de objetos de relleno, y las cinco
opciones `*_blueprint_logic` que ajustan la lógica de escudos, sensores, enfermería, motores y armas. La lista
completa, con todos los detalles, está en la página del juego (en inglés):
`apworld/ftl/docs/en_FTL Faster Than Light.md`.
