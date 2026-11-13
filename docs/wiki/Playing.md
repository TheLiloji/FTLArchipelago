# Playing

**English** · [Français](Playing.fr.md) · [Deutsch](Playing.de.md) · [Español](Playing.es.md) ·
[Italiano](Playing.it.md) · [Português](Playing.pt.md)

This page follows a game from start to finish: connecting, the hangar, a run, the Archipelago beacons, the
dashboard and the goal. If the mod is not installed yet, start with the setup guide
([Windows](Setup-Windows.md), [Linux](Setup-Linux.md)).

## Your first game in five steps

1. Start FTL, fill in the panel at the bottom left of the main menu and press **Connect**.
2. Answer **Use its own save** if the mod asks, so this seed gets its own FTL save.
3. Click **New Game**: the hangar opens on your starting ship. Pick the difficulty your seed asks for and press
   **START**.
4. Play as usual. Reaching sectors, winning fights, recruiting crew and achievements send checks. What the others
   find for you arrives on its own.
5. Press **TAB** at any time to see your goal, what is left to do and what you received.

Losing a run only costs the run: you keep everything you received, and the next run starts stronger.

## Connecting

![Connection panel](../images/connect-panel.jpg)

On the main menu, fill in the panel at the bottom left:

| Field | What to type |
|---|---|
| Address | the server, for example `archipelago.gg`, or the IP of the person who hosts |
| Port | the number after the colon in the room address, for example `38281` |
| Slot name | the `name:` of your YAML, exactly as written |
| Password | only if the room has one |

Press **Connect** or **ENTER**. **TAB** moves between fields. **Ctrl+V** pastes the address copied from your room
page (like `archipelago.gg:38281`) and fills the address and the port at once.

- The fields are remembered for next time. The password never is.
- Tick **Connect automatically on launch** and the mod reconnects every time FTL starts.
- If the connection drops, the mod tries again on its own. Checks done meanwhile wait and leave as soon as the
  link is back.

Once connected, the panel shows your checks and a **Disconnect** button, and the goal appears at the top:

![Main menu once connected](../images/main-menu.jpg)

### "The seed has changed"

![The seed change question](../images/seed-change.jpg)

FTL can unlock a ship but never lock it again. So each seed gets its own FTL save. When you join a new seed, the
mod asks first. **Use its own save** restarts FTL on a fresh save for that seed, and the old one stays exactly as
it was. **No, keep it** stays on the current save, offline.

The **Saves** button on the panel lists them: one per seed, plus solo, with the checks and the last time played.
**Load** restarts FTL on that save, run in progress included. **Archive** puts a save aside in the
`ap_profiles/archived` folder, nothing is deleted. Your FTL save without Archipelago is never touched.

![The Archipelago saves window](../images/saves.png)

## The hangar

![Locked ships](../images/hangar.jpg)

Only the ships you own can be picked. The others stay locked until their key arrives, and new ships show up the
next time you are back in the hangar, never in the middle of a run. Type B and C layouts are items of their own
(unless your seed says otherwise). In the ship list, a layout the seed left out is marked **NOT IN SEED**: it
never unlocks.

The hangar opens on your starting ship. **RANDOM SHIP** and the **< >** arrows go through the ships you own. FTL
always shows the Kestrel A, even when it cannot count: without its key (option `kestrel_key`) it is marked
**NO KEY**, and out of the seed **NOT IN SEED**. On such a ship **START** is greyed out and refused with a short
reason, so a run that would count for nothing never begins.

Press **TAB** in the hangar to open the dashboard on its Ships page: the ships with the most checks left come
first, and those with nothing left go to the bottom. **U** or the button shows or hides the ships you do not own.
It is a good way to choose your next ship.

FTL cannot unlock ships by itself: the mod refuses it, and locks again at the main menu a ship FTL unlocked
before. If one is playable all the same, it is marked **NOT RECEIVED**, and a run with it counts for nothing, no
checks and no victory.

**Which difficulty?** By default only Normal and Hard victories count for the goal. The main menu and the
dashboard say what your seed asks for. An easier win still sends its victory check.

## The start-of-run menu

![The start-of-run menu](../images/start-menu.jpg)

Weapons and drones exist twice in the item pool (by default in bundles of 3 weapons or 2 drones), and crew
members come in up to three steps. Once you have received a second copy of something, a menu opens at the very
start of each new run: pick **one weapon, one drone and one crew member** from everything you have collected,
and they come along for that run.

- With **System Install** set to `run_start`, the same menu also offers the systems whose blueprint you
  received: pick the ones you want, as many as your ship has free rooms.
- With **Sector Skip**, each sector you skip gives one more pick here.

Click **Done** to close it, or just jump: the menu only stays until the first jump. If you quit the game before
choosing, it is still there when you continue. It comes back at the start of every run, so a good second copy
is worth something every time.

## During a run

![Items arriving during a run](../images/in-game.jpg)

### What sends a check

Depending on your options:

- **reaching a sector** with a layout (most checks come from here);
- **beating the Flagship** with a layout;
- **the first crew member of each race** who joins you;
- **achievements**, of the ship or general ones. They are sent at the next jump after you earn them;
- **installing a system**, or each level of it (Systemsanity);
- **winning fights**: the first ones of a run, or of each sector;
- **reactor power** 10, 15, 20 and 25;
- **buying a package** in the Archipelago shop, and the packages of the relay and pirate events.

The dashboard (TAB) lists every check of your seed, and marks in blue the ones you can already do.

### What you receive

What you receive arrives by itself, at the next quiet beacon if you are in a fight:

- a **ship key** or **layout**: in the hangar next time;
- a **system blueprint**: stores can now sell that system (or it comes aboard for free, with System Install);
- a **Progressive** system item: one more upgrade level allowed (or installed for free, with Free Upgrades);
- a **weapon or drone**, first copy: one is put on board (in the cargo hold if your slots are full; if the cargo
  hold is full too, it waits until you make room) and it shows up more often in stores. Second copy: it joins the
  start-of-run menu;
- an **augment**: one is put on board and it shows up more often in stores (if your three slots are full, it
  waits until one is free);
- a **crew member**: the first joins your run (or waits for a free seat), the second goes into the start-of-run
  menu, the third makes that menu entry an expert with one skill mastered;
- a **Head Start**: a free system level or reactor bar at the start of every future run;
- a **Sector Pass** (with Sector Locks): the exit of sector 4, then 7, opens for that layout;
- an **Archive**: one step closer to the goal;
- **filler** (scrap, fuel, missiles, drone parts, hull repair) and, if the seed has them, **traps**.

When a lot arrives at once (another player's release, the end of the game), weapons and drones come four per
beacon; the rest follow at the next jumps.

Notes at the bottom left tell you what arrived and what was sent. They fade after a few seconds, and everything
is kept in the dashboard.

### Traps

A trap never destroys your ship: it leaves at least 3 hull and 2 fuel, never knocks a system out completely,
and waits for a quiet beacon. The note says which trap it is and who sent it.

| Trap | What happens |
|---|---|
| Fire | a fire starts in a room |
| Hull Breach | a breach opens in a room |
| Fuel Leak | you lose some fuel |
| System Damage | a system takes damage |
| Rebel Fleet | the rebel fleet comes one jump closer |
| Hull Damage | your hull takes a few points |
| Boarding Party | an enemy comes aboard |
| O2 Drain | every room loses its air at once (never if your oxygen system is down) |
| Anti-Ship Battery | waits for your next fight: a planetary battery shoots at you during it |
| Power Surge | waits for your next fight: the enemy fires a Flagship power surge (lighter in sectors 1 and 2) |
| Hazard | waits for your next fight: the beacon gets a nebula, an ion storm, asteroids, a sun or a pulsar |

The last three go away when the fight is over, and only one springs per fight.

### Sector Skip and Sector Locks

Two options change the map, if your seed has them:

- **Sector Skip**: in sectors 1 to 4, if this layout already reached the next sector in an earlier run, the
  first beacon is an exit. Jump at once to get 60 scrap and one more pick in the start-of-run menu, or explore
  as usual. The checks of the skipped sector wait for another run.

  ![Sector Skip: the first beacon is an exit](../images/sector-skip.jpg)

- **Sector Locks**: the exit of sector 4 stays shut until this layout has its first Sector Pass, and the exit of
  sector 7 until the second. The exit beacon says what is missing, and opens as soon as the pass comes in.

### The Flagship

With **Flagship Sabotage**, a message tells you when the Flagship arrives weakened, and how much (hull, shields,
weapons). The win is sent as soon as the Flagship is destroyed.

## Archipelago beacons

![Archipelago beacons on the map](../images/map.jpg)

Each sector has one beacon marked **AP STORE**, with the Archipelago shop, and other beacons hold the mod's own
events. By default only the two that carry a package (the relay and the pirates) are marked **ARCHIPELAGO** on
the map; the **Event Beacons** option can mark them all or none.

### The Archipelago shop

![The Archipelago shop](../images/shop.jpg)

Each package is an item from the multiworld. The name under it says who it is for; **FOR YOU** means one of your
own items. Buying a package sends it right away:

![A package sent](../images/shop-sent.jpg)

Filler costs 10 to 25 scrap, useful items 30 to 65, and important ones 70 to 150. A package that was sent never
comes back. Each sector sells its own packages: the shop of sector 5 has other packages than the one of sector 2,
and they cost more. With **Archipelago Shop by Sector**, a package is only sold in its own sector, and the shop
says in which sector the next ones are.

By default, the packages you see become hints for their owners: they know where their item waits.

The shop also sells **pacts**: scrap right away, and a trap sprung in exchange, two times out of three on another
player (with Trap Link on), one time out of three on you. Without Trap Link it is always you. When it is you, it
strikes in your next fight, not at the quiet shop beacon. The **blood pacts** on the second page pay more, and
add a chance (5, 10 or 20 %) that one of your crew dies for good, Clone Bay or not. They never take your last
crew member.

![Blood pacts in the Archipelago shop](../images/blood-pacts.jpg)

### The events

- **A relay** carrying packages for other players. Pay 15 scrap to forward one.
- **Pirates holding a package**, often a friend's. Pay them 20 scrap, or fight them and send it for free if you win.
- **A Zoltan checkpoint** that sells 3 fuel for 15 scrap. With Energy Link it costs 20 and adds 1 fuel to the
  shared reserve, or you can draw fuel from the reserve instead.
- **A Slug** who sells a real Archipelago hint for 20 scrap. If there is nothing left to hint, you get the scrap
  back.
- **A surge from another world**, which you can absorb or send away as a trap (with Trap Link on).
- **An Engi technician** (Engi and civilian sectors) who bets 30 scrap that they can overclock your reactor. It
  pays 75 scrap when it holds, and costs hull and engine damage when it does not. You can also let them test the
  engines for 3 fuel, or just leave.
- **An arms dealer**, rare, in pirate sectors: a random weapon for 45 scrap, or a random augment for 4 fuel.

| | |
|---|---|
| ![The Engi overclock bet](../images/event-overclock.jpg) | ![The arms dealer](../images/event-arms-dealer.jpg) |

With **Archipelago Event Checks**, the packages of the relay and the pirates are checks of their own
("Archipelago Event 1", 2...) before they go back to selling the shop's packages. None of these events can hide
a check from you: they are extra, never required.

## Playing with others: the links

They only work if your YAML turned them on. The first page of the dashboard shows which ones are active.

- **Death Link**: when you die, the others die too, and the other way round. Your seed says what counts as your
  death (a lost run, a lost crew member, or both). A death you receive does something bad (by default a breach
  and a fire in a system room) but never destroys your ship nor kills your last crew member. Click Death Link on
  the first page of the dashboard to turn it off or on, if your seed allows it.
- **Energy Link**: a fuel reserve shared with every Energy Link player. Your extra fuel goes in at quiet beacons
  (25 % is lost on the way), and when you drop below 3 fuel your ship takes some back, once per beacon. The
  dashboard shows how much is in the reserve.
- **Trap Link**: when someone gets a trap, the others get one too. A trap from another game is turned into the
  closest FTL trap ("Ice Trap" knocks out a system, a fire trap starts a fire...).

## The dashboard

Press **TAB** in a run or in the hangar. In a run the game pauses while it is open. **Left**/**Right** or **1** to
**5** change page, the mouse wheel scrolls, **Esc** or **TAB** closes it.

| | |
|---|---|
| ![Overview](../images/dashboard-links.jpg) | ![Ships](../images/dashboard-ships.png) |
| **1 Overview**: your goal and where you stand, checks done per category, your links (Death Link, Energy Link, Trap Link), this run (fights left to check, scrap for the next run, free upgrades), the last items received and your hints. | **2 Ships**: every layout of the seed, owned or not, and how many checks each one has left. **U** shows only the ones you own. |
| ![Systems](../images/dashboard-systems.png) | ![Checks](../images/dashboard-checks.png) |
| **3 Systems**: which blueprints you have, how many upgrade levels you received for each system, and the Head Starts given at the start of each run. | **4 Checks**: every check of the seed, by category and ship by ship. Done in green, and a **blue line** under the ones you can already do with what you have. Point at a box to see what it is, and what it gave once done. |

![Journal](../images/dashboard-journal.png)

**5 Journal**: every item received, who sent it, and what was inside each bundle, coloured by its Archipelago
class (progression green, useful blue, trap red, filler grey). On the right, your hints: what the others found
for you, and where your items wait in their worlds. A hint stays there until the item is found.

The Checks page also has the achievements with their game icons, the victories with each ship's picture, and
the crew races you recruited.

![Achievements on the checks page](../images/dashboard-achievements.jpg)

**Where to go next?** Open the Checks page and look for the blue lines on the ship you fly. On the Ships page,
the ships with the most checks left come first.

## The goal

Beat the Flagship with a number of **different** ships (or layouts). The main menu and the dashboard say it in
full, for example "defeat the Flagship 2 times, a different ship layout for each victory", and list the ships you
have already won with. A second win with the same ship still sends that ship's victory check, it just does not
count again for the goal.

Some seeds also ask for **Archives**: items spread in the multiworld, in your own world too. You need both the
victories and enough Archives. The goal is sent on its own as soon as both are there, even if the last Archive
arrives while you sit in the menu.

Some seeds ask for Normal or Hard wins. An easier win still sends its check, but does not count for the goal.

## Solo mode

No server? Click **Solo mode** in the connection panel. It uses a real generated seed and gives you one of its
items per check. It is always the same demo seed shipped with the mod, not your YAML, so your options do not
apply. Your progress is saved in its own save, so you can stop and come back later. **Stop solo** puts it aside,
and clicking **Solo mode** again asks whether to continue or start over.

## Things worth knowing

- **Losing a run costs only the run.** Items stay, and Head Starts make the next run stronger.
- **A run started before you connected does not count.** Connect first, then start a new game. The same goes for
  a run saved under another seed: "Continue" brings it back, but it counts for nothing, and the scrap, fuel
  and traps you receive meanwhile wait for your next real run.
- **Coming back to a seed you played before** does not hand out its scrap, fuel and traps a second time. Ships,
  blueprints and upgrade levels come back as they were.
- **Achievement checks are sent at the next jump** after you earn them, and achievements you earned before
  Archipelago do not count: earn them again.
- **"Reach sector 1" needs one jump.** A check is sent when you arrive somewhere.
- **Received traps never destroy your ship.** They leave at least 3 hull and 2 fuel, and wait for a quiet beacon.
- **Received deaths** (Death Link) never take your last hull point or your last crew member.
- **You send a death** (Death Link) when you lose the run or a crew member, depending on the seed's options. A
  crew member the Clone Bay brings back is not a death, unless the seed counts them. Dismissing a crew member
  from the crew screen, or losing a drone, does not count.
- **Item and location names stay in English** whatever the language, because every player and tracker shares
  them. Only the sentences around them are translated.

## If something goes wrong

Look at the [FAQ](FAQ.md) first. If it does not help, ask on the
[Discord](https://discord.gg/BVQnQu843Q) or open an
[issue](https://github.com/TheLiloji/FTLArchipelago/issues) with your `FTL_HS.log` (in the FTL folder on Windows, in its `data` folder on Linux).
