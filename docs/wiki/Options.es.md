# Opciones

[English](Options.md) · [Français](Options.fr.md) · [Deutsch](Options.de.md) · **Español** ·
[Italiano](Options.it.md) · [Português](Options.pt.md)

Tus opciones caben en un pequeño archivo de texto, el **YAML**. Lo haces una vez, antes de la partida, y se lo
envías a la persona que genera el multiworld. Esta página explica cada opción, una por una. No hace falta leerla
entera: elige un preset y vuelve aquí cuando quieras cambiar algo.

## Antes de empezar

Necesitas **Archipelago 0.6.7**, con el `ftl.apworld` de la
[página de la release](https://github.com/TheLiloji/FTLArchipelago/releases/latest) en su carpeta
`custom_worlds`. Sin él, FTL no aparece en la lista. Las guías de instalación ([Windows](Setup-Windows.es.md),
[Linux](Setup-Linux.es.md)) explican cada paso.

## Algunas palabras que vas a ver

| Palabra | Significado |
|---|---|
| check | algo que haces en el juego y que envía un objeto: llegar a un sector, ganar, un logro... |
| objeto (item) | lo que un check te da a ti o a otro jugador: una nave, un sistema, un arma, chatarra... |
| seed | la partida generada, la misma para todo el multiworld |
| slot | tu lugar en el multiworld, con el nombre de la línea `name:` de tu YAML |
| layout | una versión de una nave: Kestrel A, Kestrel B y Kestrel C son tres layouts. Hay 28, en 10 naves |
| progressive | un objeto que sube un sistema un nivel cada vez que lo recibes |
| plano (blueprint) | el objeto que te deja tener un sistema (Camuflaje, Control de drones...) |
| run | un intento, de la primera baliza a la victoria o a la destrucción de la nave |
| Archivos | objetos que necesitas además de tus victorias para terminar |
| relleno (filler) | objetos pequeños: chatarra, combustible, misiles, piezas de dron |
| trampa (trap) | un objeto malo: un incendio, una brecha, la flota rebelde que avanza... |
| lógica | lo que el generador supone que tienes antes de pedirte un check |
| AP STORE | la tienda Archipelago, una baliza por sector, que vende los objetos del multiworld |

## Lo más fácil: elegir un preset

Los presets son archivos YAML ya hechos. Elige el que va con tu tiempo:

| Preset | Tiempo hasta el objetivo | Qué es |
|---|---|---|
| `first_game` | unas 3 h | **Tu primera partida de Archipelago.** 1 victoria, Fácil cuenta, 3 naves de tipo A, 2 Archivos de 3, sin trampas. Las mejoras y los sistemas que recibes suben a bordo solos |
| `short_game` | unas 5 h | 2 victorias en Normal o Difícil, 4 layouts, 4 Archivos de 5, todas las mejoras de un sistema de golpe |
| `medium_game` | unas 10 h | las opciones por defecto: 5 victorias en Normal o Difícil, 7 layouts, 10 Archivos de 12 |
| `long_game` | 20 h o más | 10 victorias, 14 layouts, 16 Archivos de 20, instalar un sistema es un check |
| `solo_game` | unas 7 h | **Solo en el multiworld.** 3 victorias, 5 layouts, combates por sector, salto de sector y Sector Passes, más checks de eventos |

Están en `presets.zip` en la [página de la release](https://github.com/TheLiloji/FTLArchipelago/releases/latest).
El principio de cada archivo dice cuántos checks tiene y cuánto dura más o menos.

1. Abre el archivo en un editor de texto.
2. Cambia la línea `name:` por tu nombre. Usa solo letras sin tilde ni ñ, cifras, espacios, `-` y `_`, y 16
   caracteres como mucho: el panel de conexión del juego no sabe escribir nada más.
3. Envía el archivo a la persona que genera el multiworld (su guía, en inglés: [Hosting a seed](Hosting-a-seed.md)).

Los tiempos son para alguien que gana en pocas runs. Si FTL es nuevo para ti, cuenta con más.

## Hacer tu propio YAML

Abre **ArchipelagoOptionsCreator** (en la carpeta de Archipelago), elige **FTL: Faster Than Light**, escribe
tu nombre y exporta el YAML. Cada opción tiene una breve descripción (en inglés): pasa el ratón por encima. Los
valores por defecto son los del preset `medium_game`.

También puedes cambiar un preset a mano. Cada opción es una línea: el nombre YAML, dos puntos, el valor. Por
ejemplo:

```yaml
name: MiNombre
game: "FTL: Faster Than Light"
requires:
  version: 0.6.7
"FTL: Faster Than Light":
  victories_required: 3
  start_ship: rock_cruiser
  trap_chance: 10
```

Deja los dos espacios delante de cada opción. Una opción que no escribes toma su valor por defecto.

## Tres errores frecuentes

- **Victorias en Fácil.** Por defecto solo cuentan para tu objetivo las victorias en Normal y Difícil. Si juegas
  en Fácil, pon **Victory Difficulty** en `any` (en el YAML también vale `easy`).
- **Menos checks no es una partida más corta.** Desactivar sectores o logros no quita sus objetos: pasan a la
  tienda Archipelago, donde los compras con chatarra. Para acortar una partida, baja mejor **Victories
  Required** y **Layouts in the Seed**.
- **Death Link.** Si tu grupo juega con él, actívalo. Con **Death Link Trigger** en `both` (por defecto), cada
  tripulante que pierdes mata también a los demás. En un multiworld grande o para una primera partida, elige
  `ship_destroyed`: solo cuenta una run perdida.

## Ideas para tu YAML

Una partida más corta, sin tocar el resto:

```yaml
  victories_required: 2
  layout_count: 4
  sectorsanity_last_sector: 6
```

Una segunda nave pronto, y objetos recibidos que sirven enseguida:

```yaml
  early_ship_keys: 3
  free_upgrades: true
  system_install: run_start
  run_start_scrap: 15
```

Más cosas que hacer en cada run:

```yaml
  combat_checks: 1
  combat_checks_mode: per_sector
  reactor_checks: true
  systemsanity: first_install
```

Caos entre amigos:

```yaml
  trap_chance: 30
  trap_link: true
  death_link: true
```

Una seed más dura, para quien conoce bien FTL:

```yaml
  victory_difficulty: hard
  sector_logic: none
  shop_unlock_mode: locked
  sector_locks: true
```

## Todas las opciones, grupo por grupo

Los grupos son los del creador de opciones. Cada opción muestra su nombre en el creador de opciones (en inglés),
su nombre en el YAML, los valores posibles y su valor por defecto. Los grupos marcados *cerrado* están plegados
al principio en el creador de opciones: no los necesitas para una primera partida.

### Goal (el objetivo)

Lo que tienes que hacer para terminar.

#### Victories Required

`victories_required` · 1 a 28 · por defecto `5`\
Cuántas veces tienes que vencer a la nave insignia, cada vez con un layout **distinto** (Kestrel A y Kestrel B
cuentan como dos). Es la opción que decide cuánto dura tu partida: 1 o 2 para una primera partida, 5 con amigos,
10 para una partida larga.

#### Victory Difficulty

`victory_difficulty` · `any`, `normal`, `hard` · por defecto `normal`\
La dificultad mínima de una victoria para que cuente para tu objetivo. `any` (o `easy`) cuenta todas las
victorias, `normal` cuenta Normal y Difícil, `hard` solo Difícil. Una victoria más fácil envía igual su check,
solo que no cuenta para el objetivo.

#### Flagship Sabotage

`flagship_sabotage` · 0 a 5 · por defecto `0`\
El multiworld debilita la nave insignia. Cada nivel añade algo, y vale para cada fase del combate: 1 es casco
-10 %, 2 añade escudos -1, 3 pasa a casco -20 %, 4 añade armas -1, 5 pasa a casco -30 %. Un mensaje te da el nivel
cuando llega la nave insignia. Bien para un grupo que quiere terminar antes.

#### Archives

`archives` · 0 a 50 · por defecto `12`\
Cuántos Archivos hay escondidos en el multiworld, en tu mundo o en el de los demás. Los Archivos son objetos que
necesitas además de tus victorias. 0 juega sin ellos.

#### Archives Required

`archives_required` · 0 a 50 · por defecto `10`\
Cuántos Archivos necesitas para terminar. Déjalo un poco más bajo que **Archives**, para que un Archivo mal
colocado no pueda bloquearte. Si es más alto que Archives, hacen falta todos.

#### Victory Collects the Layout

`victory_collects_layout` · `off`, `sectors`, `everything` · por defecto `sectors`\
Lo que una victoria envía además, entre los checks de ese layout que aún no has hecho. `off`: solo la victoria.
`sectors`: también todos los checks de sector de ese layout. `everything`: también los logros de su nave, sus
checks de sistema y sus checks de combate. Útil cuando ganas con una nave y no quieres volver a ella por el
sector 3.

### Ships (las naves)

Qué naves hay en la partida y cómo las consigues.

#### Starting Ship

`start_ship` · una de las 10 naves · por defecto `kestrel_cruiser`\
La nave con la que empiezas, en tipo A. Sus tipos B y C se encuentran como los de las demás. Los valores son
`kestrel_cruiser`, `engi_cruiser`, `federation_cruiser`, `zoltan_cruiser`, `mantis_cruiser`, `slug_cruiser`,
`rock_cruiser`, `stealth_cruiser`, `lanius_cruiser` y `crystal_cruiser` (o solo `rock`, `mantis`...).

#### Ship Layouts

`ship_layouts` · `type_a_only`, `up_to_type_b`, `all_layouts` · por defecto `all_layouts`\
Qué layouts pueden estar en la partida: solo el tipo A, los tipos A y B, o todos.

#### Layouts in the Seed

`layout_count` · 1 a 28 · por defecto `7`\
Cuántos layouts puedes pilotar en esta seed, en total. Tu nave inicial y el Kestrel A cuentan, así que 7 son esos
dos más otros 5, sacados al azar entre los que **Ship Layouts** permite. Un tipo B o C solo viene con el tipo A de
su nave. Los layouts que quedan fuera no tienen llave ni check, y el hangar los marca **NOT IN SEED**. Sube a
Victories Required si es más bajo.

#### Excluded Ships and Layouts

`excluded_layouts` · una lista · por defecto vacía\
Las naves o los layouts que nunca quieres en la seed. Nombra una nave entera (`"Engi Cruiser"`) o un layout
(`"Engi Cruiser B"`, o `"Engi B"`). Quitar un tipo A quita toda su nave. Tu nave inicial y el Kestrel A no se
pueden quitar. Ejemplo: `excluded_layouts: ["Stealth Cruiser", "Lanius Cruiser C"]`.

#### Layout Unlocks

`layout_unlocks` · `items`, `vanilla`, `independent`, `progressive` · por defecto `items`\
Cómo se vuelven disponibles los tipos B y C.
- `items`: cada layout es su propio objeto, y también necesitas la llave de la nave para pilotarlo.
- `vanilla`: como en FTL, ganando los logros de esa nave. Sin objetos de layout.
- `independent`: cada layout es su propio objeto y no necesita nada más, ni siquiera la llave de la nave.
- `progressive`: sin objetos de layout. La llave de la nave viene una vez por layout: la primera copia da el tipo
  A, las siguientes el tipo B, luego el C.

#### Early Ship Keys

`early_ship_keys` · 0 a 9 · por defecto `1`\
Cuántas llaves de nave, además de tu nave inicial y del Kestrel, se ponen en tus propios primeros checks. Una
segunda nave llega pronto en vez de horas después. El número de llaves no cambia, solo dónde caen. 0 las deja caer
en cualquier sitio.

#### Kestrel Needs Its Key

`kestrel_key` · `true` / `false` · por defecto `false`\
Cuando no empiezas con el Kestrel, el Kestrel A necesita su llave como cualquier nave. FTL lo sigue mostrando en
el hangar, pero está marcado **NO KEY** y START lo rechaza hasta que llegue la llave. Desactivado, el Kestrel A
siempre es tuyo.

### Checks

Lo que envía checks. La mayoría de tus checks vienen de los sectores.

#### Sectorsanity

`sectorsanity` · `disabled`, `milestones`, `full` · por defecto `full`\
Llegar a un sector con un layout envía un check. Cada layout tiene los suyos: el Rock A en el sector 4 no es el
mismo check que el Rock B en el sector 4. `full`: cada sector. `milestones`: solo los sectores 5 y 8.
`disabled`: nunca.

#### Sectorsanity First Sector

`sectorsanity_first_sector` · 1 a 8 · por defecto `2`\
El primer sector que envía un check. Los sectores anteriores no envían nada. Con todos los layouts en juego, los
sectores 1 y 2 son por sí solos 56 checks que consigues solo con despegar: subirlo es la forma más fácil de
aligerar una seed grande.

#### Sectorsanity Last Sector

`sectorsanity_last_sector` · 1 a 8 · por defecto `8`\
El último sector que envía un check. Un check en el sector 8 cuesta una run entera, uno en el sector 4 llega solo.
5 o 6 mantiene las mismas naves pero corta el final largo de la seed, la parte en la que los demás te esperan.

#### Systemsanity

`systemsanity` · `disabled`, `first_install`, `every_level` · por defecto `disabled`\
Instalar un sistema envía un check. `first_install`: una vez por sistema, 12 checks (Motores, Oxígeno, Pilotaje y
Control de armas no tienen, todas las naves empiezan con ellos). `every_level`: también cada nivel de mejora, 64
checks, una partida mucho más larga.

#### Systemsanity per Ship

`systemsanity_per_ship` · `true` / `false` · por defecto `false`\
Con Systemsanity activado, cada nave tiene sus propios checks de instalación, como "Kestrel Cruiser: Install
Cloaking". Nunca para un sistema con el que esa nave empieza.

#### Ship Achievement Checks

`ship_achievements` · `true` / `false` · por defecto `true`\
Los tres logros de cada nave envían un check, 30 en total. FTL se los da a la nave, no al layout: ganarlos con el
tipo A, B o C envía el mismo check.

#### General Achievement Checks

`general_achievements` · `disabled`, `basic`, `most`, `all` · por defecto `most`\
Cuáles de los 21 logros generales envían un check. `basic`: los fáciles, como llegar al sector 8. `most`:
también los más difíciles, que se ganan a lo largo de una run. `all`: todos, también los muy difíciles.

#### Cross-Run Achievement Checks

`cross_run_achievements` · `true` / `false` · por defecto `false`\
Los tres logros que no se pueden ganar en una sola run: "Rule Ten: Greed is Eternal" (10.000 de chatarra en todas
tus partidas), "Warlord" (1000 naves destruidas) y "Your Own Fleet" (todas las naves desbloqueadas). Déjalo
desactivado para una seed corta: los dos primeros pueden no llegar nunca.

#### Crew Checks

`crew_checks` · `true` / `false` · por defecto `true`\
El primer tripulante de cada raza que se une a ti envía un check: Humano, Engi, Zoltan, Mantis, Rock, Slug y
Lanius. 7 checks. La tripulación con la que empiezas una run no cuenta.

#### Archipelago Event Checks

`event_checks` · 0 a 20 · por defecto `5`\
Los paquetes de los eventos del relé y de los piratas pasan a ser checks propios, "Archipelago Event 1", 2...
hasta este número. Cuando están todos hechos, los eventos vuelven a vender paquetes de la tienda Archipelago. 0:
los eventos solo venden los paquetes de la tienda.

#### Reactor Checks

`reactor_checks` · `true` / `false` · por defecto `false`\
Mejorar el reactor envía checks con potencia 10, 15, 20 y 25, en cualquier run. La lógica los espera hacia los
sectores 2, 4, 6 y 7.

#### Combat Checks per Ship

`combat_checks` · 0 a 10 · por defecto `0`\
Ganar combates envía checks. Con cada nave, los primeros combates que ganas en una run (enemigo destruido o su
tripulación muerta) envían "Fight 1 won", "Fight 2 won"... hasta este número. 0 los desactiva.

#### Combat Checks Mode

`combat_checks_mode` · `per_run`, `per_sector` · por defecto `per_run`\
Cómo se cuentan los combates. `per_run`: los primeros combates de una run, como arriba. `per_sector`: los
primeros combates de **cada** sector envían su propio check ("Sector 3 fight 1 won"), hasta **Fights per
Sector**, así que una run hasta el sector 8 puede enviar checks en todas partes. En este modo Combat Checks per
Ship solo tiene que estar por encima de 0.

#### Fights per Sector

`fights_per_sector` · 1 a 5 · por defecto `2`\
Con `per_sector`: cuántos combates de cada sector envían un check, para cada nave.

#### Combat Check Scrap (%)

`combat_check_scrap` · 0 a 100 · por defecto `50`\
Un combate que envía un check solo da esta parte de su chatarra. Los misiles, el combustible y las piezas de dron
se quedan. Los combates que no envían nada guardan toda su recompensa.

### Systems and Upgrades (sistemas y mejoras) *(cerrado)*

Cómo se bloquean los sistemas y sus niveles, y cómo se devuelven.

#### System Blueprints

`system_blueprints` · `true` / `false` · por defecto `true`\
Los planos de sistemas son objetos. Sin el plano de un sistema, las tiendas no lo venden. Un sistema con el que
empieza tu nave nunca se quita: se queda en nivel 1 hasta que llega el plano. Desactivado, todos los sistemas
están a la venta.

#### Progressive System Upgrades

`progressive_systems` · `true` / `false` · por defecto `true`\
Cada objeto "Progressive" sube hasta dónde puedes mejorar un sistema, hasta el máximo de FTL. Sigues pagando la
chatarra, salvo con Free Upgrades. Por defecto un objeto cuenta para todas las naves: "Progressive Shields" sube
los escudos de todas. Desactivado, los sistemas se mejoran como en FTL.

#### Progressive Upgrades per Ship

`progressive_systems_per_ship` · `true` / `false` · por defecto `false`\
Las mejoras pertenecen cada una a una nave, como "Kestrel Cruiser: Progressive Shields", y solo cuentan a bordo
de esa nave, sea cual sea el layout. Muchos más objetos, así que una tienda Archipelago más grande.

#### Progressive Unlocks the System

`progressive_unlocks_system` · `true` / `false` · por defecto `false`\
El primer objeto Progressive de un sistema también lo desbloquea, así que ese sistema no tiene objeto de plano
aparte. Menos objetos que esperar: los sistemas llegan antes.

#### Full System Upgrades

`full_system_upgrades` · `true` / `false` · por defecto `false`\
Cada objeto Progressive da todos los niveles de su sistema de golpe. Menos objetos, una progresión más gruesa.

#### Free Upgrades

`free_upgrades` · `true` / `false` · por defecto `false`\
Los niveles de sistema que recibes se instalan gratis: enseguida si estás en una run, y otra vez al principio de
cada run. Desactivado, un nivel recibido solo te deja comprarlo. Necesita Progressive System Upgrades.

#### System Install

`system_install` · `store`, `run_start`, `immediately` · por defecto `store`\
Cuándo un sistema cuyo plano has recibido sube a bordo gratis, si la nave tiene una sala para él. `store`: nunca,
lo compras como en FTL. `run_start`: al principio de cada run, desde el menú de inicio de run. `immediately`:
también en cuanto llega el plano durante una run.

### Weapons, Drones, Augments, Crew (armas, drones, aumentos, tripulación) *(cerrado)*

Lo que se bloquea en las tiendas propias de FTL, y la tripulación como objetos.

#### Shop Weapons

`shop_weapons` · 0 a 37 · por defecto `37`\
Cuántas de las 37 armas de FTL se vuelven objetos. Las demás siguen siendo artículos normales de las tiendas. 0
deja las armas en paz.

#### Shop Drones

`shop_drones` · 0 a 14 · por defecto `14`\
Lo mismo para los 14 drones. Los drones necesitan el Control de drones para servir de algo.

#### Shop Augments

`shop_augments` · 0 a 23 · por defecto `23`\
Lo mismo para los 23 aumentos.

#### Weapon Bundle Size

`weapon_bundle_size` · 1 a 5 · por defecto `3`\
Cuántas armas tiene cada lote de armas. Un lote las desbloquea todas de golpe. 1 quiere decir sin lotes: cada arma
es su propio objeto. Lotes más grandes son menos objetos, así que una tienda Archipelago más pequeña.

#### Drone Bundle Size

`drone_bundle_size` · 1 a 5 · por defecto `2`\
Lo mismo para los drones.

#### Augment Bundle Size

`augment_bundle_size` · 1 a 5 · por defecto `3`\
Lo mismo para los aumentos.

#### Shop Unlock Mode

`shop_unlock_mode` · `rarity_boost`, `locked` · por defecto `rarity_boost`\
Lo que cambia en las tiendas de FTL al recibir un arma, un dron o un aumento. `rarity_boost`: ya estaba a la
venta, y ahora aparece mucho más a menudo. `locked`: no está a la venta en ningún sitio hasta que lo recibes. En
los dos casos dura para todas las runs siguientes.

#### Shop Item Delivery

`shop_item_delivery` · `true` / `false` · por defecto `true`\
También recibes una copia enseguida, una vez: a bordo si hay un hueco libre, si no en la bodega. Desactivado, el
objeto solo cambia lo que venden las tiendas.

#### Crew Members

`crew_members` · `true` / `false` · por defecto `true`\
Los tripulantes como objetos, uno por raza, hasta tres copias. Primera copia: uno se une a tu run. Segunda: la
raza entra en el menú de inicio de run. Tercera: ese menú ofrece un experto con una habilidad dominada. Lanius y
Crystal se quedan en dos.

### Archipelago Shop (la tienda Archipelago) *(cerrado)*

Las balizas AP STORE, una por sector, que venden los objetos del multiworld a cambio de chatarra.

#### Archipelago Shop Checks (minimum)

`shop_checks` · 0 a 100 · por defecto `20`\
El número más pequeño de paquetes en la tienda, para toda la seed. Si tus opciones crean más objetos que checks,
se añaden paquetes solos (hasta 400) para que cada objeto tenga un sitio. Cuanto más grande es la tienda, más
paquetes muestra cada baliza: 3, 6, 9 o 12.

#### Archipelago Shop by Sector

`shop_by_sector` · `true` / `false` · por defecto `false`\
Cada paquete pertenece a un sector, del 1 al 7, y solo se vende en el AP STORE de ese sector. Los paquetes más
profundos cuestan más, y la lógica espera que llegues antes a ese sector.

#### Archipelago Shop per Ship

`shop_per_ship` · `off`, `per_class`, `per_layout` · por defecto `off`\
Cada paquete pertenece a una nave (`per_class`) o a un layout (`per_layout`), y solo se vende mientras la
pilotas. No añade paquetes, los reparte. Un paquete que no compraste vuelve más tarde.

#### Archipelago Shop Hints

`shop_hints` · `off`, `seen` · por defecto `seen`\
`seen`: los paquetes que ves en la tienda se vuelven pistas, así sus dueños saben dónde espera su objeto. `off`:
la tienda sigue siendo tu secreto.

#### Archipelago Shop Deal Scrap (%)

`shop_deal_scrap` · 0 a 200 · por defecto `100`\
Cuánta chatarra pagan los pactos y los pactos de sangre de la tienda, en porcentaje. 0 los desactiva.

### Runs *(cerrado)*

Lo que cambia dentro de una run.

#### Head Starts

`head_starts` · `true` / `false` · por defecto `true`\
Los objetos Head Start dan un nivel de sistema gratis, o una barra de reactor, al principio de cada run siguiente.
Solo ocupan los checks que sobran cuando todos los demás objetos tienen su sitio, así que con las opciones por
defecto llegan pocos o ninguno.

#### Run Start Scrap (%)

`run_start_scrap` · 0 a 100 · por defecto `0`\
Cada run nueva empieza con esta parte de toda la chatarra que has recibido en objetos. Los objetos de chatarra
siguen dando su chatarra una vez al llegar. De 10 a 25 es un buen rango.

#### Sector Skip

`sector_skip` · `true` / `false` · por defecto `false`\
Un layout que ya llegó al sector siguiente puede saltarse los sectores 1 a 4: la primera baliza de un sector así
es una salida. Salta enseguida por 60 de chatarra y una elección más en el menú de inicio de run, o explora como
siempre. Los checks del sector saltado esperan otra run.

#### Sector Locks

`sector_locks` · `true` / `false` · por defecto `false`\
Cada layout necesita Sector Passes para ir más lejos: el primero para salir del sector 4, el segundo para salir
del sector 7. Sin ellos la salida sigue cerrada, y el juego dice por qué. Dos objetos por layout.

#### Event Beacons

`event_beacons` · `marked`, `important`, `hidden` · por defecto `important`\
Qué balizas de evento Archipelago muestran ARCHIPELAGO en el mapa. El AP STORE siempre lo muestra. `marked`:
todos los eventos. `important`: solo el relé y los piratas, que llevan un paquete. `hidden`: ninguno.

#### Sector Logic

`sector_logic` · `none`, `standard`, `strict`, `power` · por defecto `standard`\
Lo que el generador espera de tu nave antes de mandarte lejos. Nunca cambia lo que el juego te deja hacer.
- `none`: nada. Puede que se te pida llegar a la nave insignia con muy poco. Para jugadores con experiencia
  (`relaxed`, su nombre antiguo, sigue funcionando).
- `standard`: 2 planos para el sector 4, 4 para el sector 6, 5 para la nave insignia.
- `strict`: 3 planos para el sector 3, 6 para el sector 5, 9 para el sector 7, 11 para la nave insignia.
- `power`: mira la nave que hace el check. El sector 5 pide 2 capas de escudo, el sector 8 también Control de
  armas 5, la nave insignia 3 capas, Control de armas 6 y Motores 4.

#### Mod Language

`mod_language` · `game`, `english`, `french`, `spanish`, `german`, `italian`, `portuguese` · por defecto `game`\
El idioma de los menús y mensajes del mod. `game` sigue a FTL solo. Los nombres de objetos y lugares siempre se
quedan en inglés, porque todos los jugadores y trackers los comparten.

### Playing with Others (jugar con otros)

Los enlaces con los demás jugadores. Todos desactivados por defecto.

#### Death Link

`death_link` · `true` / `false` · por defecto `false`\
Cuando mueres, los demás que juegan con Death Link mueren también, y al revés. Una muerte recibida nunca destruye
tu nave y nunca mata a tu último tripulante.

#### Death Link Trigger

`death_link_trigger` · `ship_destroyed`, `crew_death`, `both` · por defecto `both`\
Lo que envía tu muerte. `ship_destroyed`: solo una run perdida, lo mejor en un multiworld grande. `crew_death`:
cualquier tripulante perdido. `both`: cualquiera de los dos. La tripulación muere a menudo, así que `both` envía
mucho.

#### Death Link Cloned Crew

`death_link_cloned_crew` · `true` / `false` · por defecto `false`\
Si un tripulante que la bahía de clonación trae de vuelta cuenta como muerte. Desactivado, solo cuenta uno que no
vuelve.

#### Death Link Toggle

`death_link_toggle` · `true` / `false` · por defecto `true`\
Puedes apagar y volver a encender Death Link durante el juego, haciendo clic en él en la primera página del panel
TAB. Desactiva esto para un grupo que quiere seguir unido hasta el final.

#### Death Link Effect

`death_link_effect` · `major_incident`, `crew_member`, `hull_damage`, `fire`, `boarding`, `varied` · por defecto `major_incident`\
Lo que te hace la muerte de otro jugador. `major_incident`: una brecha y un incendio en una sala de sistema, lo
más duro. `crew_member`: muere un tripulante. `hull_damage`: daño al casco. `fire`: un incendio. `boarding`: un
Mantis enemigo sube a bordo. `varied`: uno de los cuatro más suaves, al azar.

#### Energy Link

`energy_link` · `true` / `false` · por defecto `false`\
Una reserva de combustible compartida con todos los jugadores de Energy Link, juegue lo que juegue cada uno. Tu
combustible de sobra entra en las balizas tranquilas (con un 25 % de pérdida), y recibes algo cuando bajas de 3.

#### Trap Link

`trap_link` · `true` / `false` · por defecto `false`\
Las trampas se comparten con los demás jugadores de Trap Link: cuando uno recibe una trampa, los demás reciben
otra, aunque tu seed no tenga. Una trampa de otro juego se convierte en la trampa de FTL más parecida.

#### Trap Chance

`trap_chance` · 0 a 100 · por defecto `0`\
La parte de los objetos de relleno que se vuelven trampas. Hay 11 tipos: incendio, brecha, fuga de combustible,
daño de sistema, flota rebelde, daño al casco, abordaje, vaciado de O2, y tres que esperan a tu próximo combate
(una batería antinave, una sobrecarga de la nave insignia, un peligro). Las trampas esperan una baliza tranquila y
nunca destruyen tu nave.

#### Crew Names

`crew_names` · `vanilla`, `multiworld`, `multiworld_and_team` · por defecto `multiworld`\
Los nombres de la tripulación que se une a ti durante una run. `multiworld`: los nombres de slot de los demás
jugadores, luego los de FTL. `multiworld_and_team`: lo mismo, luego la gente que hizo y probó el mod. `vanilla`:
los nombres de FTL. Tu tripulación inicial conserva sus nombres.

### Expert (solo YAML)

Estas opciones no están en el creador de opciones, solo en el YAML. Casi nadie las necesita.

#### Goal

`goal` · `victory_count`, `victory_selection` · por defecto `victory_count`\
`victory_count`: ganar con Victories Required layouts distintos. `victory_selection`: ganar con cada layout de
**Victory Layouts**, y solo con esos.

#### Victory Layouts

`victory_layouts` · una lista · por defecto vacía\
Con `victory_selection`, los layouts que tienen que ganar cada uno. Ejemplo:
`victory_layouts: ["Kestrel Cruiser A", "Mantis Cruiser B"]`. Tienen que estar en la seed.

#### Minimum Filler

`minimum_filler` · 0 a 100 · por defecto `20`\
El número más pequeño de objetos de relleno en tu seed.

#### Shields, Sensors, Medbay blueprint logic

`shields_blueprint_logic`, `sensors_blueprint_logic`, `medbay_blueprint_logic` · `required`, `upgrade_only`, `start_with` · por defecto `upgrade_only`\
`required`: una nave que empieza con ese sistema solo entra en la lógica cuando tienes su plano. `upgrade_only`:
el plano solo hace falta para mejorar o comprar el sistema. `start_with`: empiezas con el plano.

#### Engines, Weapon Control blueprint logic

`engines_blueprint_logic`, `weapons_blueprint_logic` · `anywhere`, `early`, `start_with` · por defecto `early`\
Todas las naves empiezan con estos dos sistemas, así que solo deciden cuándo llega el plano: en cualquier sitio,
pronto en tus propios primeros checks, o desde el principio.

La [página del juego](https://github.com/TheLiloji/FTLArchipelago/blob/main/apworld/ftl/docs/en_FTL%20Faster%20Than%20Light.md)
(en inglés) explica con más detalle la lógica, las trampas y los enlaces.
