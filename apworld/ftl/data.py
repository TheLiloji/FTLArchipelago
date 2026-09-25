from __future__ import annotations

from dataclasses import dataclass

CONTRACT_VERSION = 3

GAME_NAME = "FTL: Faster Than Light"

SECTOR_CHECK_FORMAT = "{layout}:sector:{sector}"
SHOP_CHECK_FORMAT = "shop:{slot}"
VICTORY_CHECK_FORMAT = "{layout}:victory"
ACHIEVEMENT_CHECK_FORMAT = "ach:{achievement}"
SYSTEM_CHECK_FORMAT = "sys:{system}"
CREW_CHECK_FORMAT = "crew:{race}"
SYSTEM_LEVEL_CHECK_FORMAT = "sys:{system}:{level}"

KIND_SHIP = "ship"
KIND_CAP = "cap"
KIND_START = "start"
KIND_FILLER = "filler"
KIND_TRAP = "trap"
KIND_SHOP = "shop"
KIND_WEAPON = "weapon"
KIND_DRONE = "drone"
KIND_AUGMENT = "augment"
KIND_ARCHIVE = "archive"
KIND_CREW = "crew"

KINDS_IMPLEMENTED = (
    KIND_SHIP, KIND_CAP, KIND_START, KIND_FILLER, KIND_TRAP,
    KIND_SHOP, KIND_WEAPON, KIND_DRONE, KIND_AUGMENT, KIND_ARCHIVE, KIND_CREW,
)

REACTOR_TARGET = "reactor"

LAYOUT_SUFFIXES = ("", "_2", "_3")
LAYOUT_LETTERS = ("A", "B", "C")

SECTOR_COUNT = 8

ALWAYS_UNLOCKED_LAYOUTS = ("PLAYER_SHIP_HARD",)

CROSS_RUN_ACHIEVEMENTS = ("ACH_SCRAP", "ACH_SHIPS", "ACH_UNLOCK_ALL")

BASE_ID = 0x46544C00
ITEM_ID_BASE = BASE_ID
LOCATION_ID_BASE = BASE_ID + 100_000

ITEM_OFFSET_SHIP_KEY = 0
ITEM_OFFSET_LAYOUT_B = 1_000
ITEM_OFFSET_LAYOUT_C = 2_000
ITEM_OFFSET_BLUEPRINT = 3_000
ITEM_OFFSET_SYSTEM_LEVEL = 4_000
ITEM_OFFSET_HEAD_START = 5_000
ITEM_OFFSET_BONUS = 6_000
ITEM_OFFSET_FILLER = 7_000
ITEM_OFFSET_TRAP = 8_000
ITEM_OFFSET_SHOP_WEAPON = 9_000
ITEM_OFFSET_SHOP_DRONE = 10_000
ITEM_OFFSET_SHOP_AUGMENT = 11_000
ITEM_OFFSET_ARCHIVE = 12_000
ITEM_OFFSET_CREW = 13_000

LOCATION_OFFSET_SECTOR = 0
LOCATION_OFFSET_VICTORY = 10_000
LOCATION_OFFSET_SHIP_ACH = 20_000
LOCATION_OFFSET_GENERAL_ACH = 30_000
LOCATION_OFFSET_SHOP = 40_000
LOCATION_OFFSET_SYSTEM = 50_000
LOCATION_OFFSET_CREW = 60_000

MAX_ACHIEVEMENTS_PER_SHIP = 10

MAX_SHOP_SLOTS = 400

ARCHIVE_ITEM_NAME = "Archipelago Archive"
MAX_ARCHIVES = 50

NEVER_SOLD_SYSTEMS: frozenset[str] = frozenset({"artillery"})

CREW_ITEMS_RAW: tuple[tuple[int, str, str, str | None], ...] = (
    (0, "Human Crew", "human", None),
    (1, "Engi Crew", "engi", None),
    (2, "Zoltan Crew", "energy", None),
    (3, "Mantis Crew", "mantis", None),
    (4, "Rock Crew", "rock", None),
    (5, "Slug Crew", "slug", None),
    (6, "Lanius Crew", "anaerobic", None),
    (7, "Crystal Crew", "crystal", None),
    (8, "Human Pilot Expert", "human", "pilot"),
    (9, "Engi Engine Expert", "engi", "engines"),
    (10, "Zoltan Shield Expert", "energy", "shields"),
    (11, "Slug Weapons Expert", "slug", "weapons"),
    (12, "Rock Repair Expert", "rock", "repair"),
    (13, "Mantis Combat Expert", "mantis", "combat"),
)

PROGRESSIVE_CREW_RAW: tuple[tuple[int, str, str, str | None], ...] = (
    (14, "Progressive Human Crew", "human", "pilot"),
    (15, "Progressive Engi Crew", "engi", "engines"),
    (16, "Progressive Zoltan Crew", "energy", "shields"),
    (17, "Progressive Mantis Crew", "mantis", "combat"),
    (18, "Progressive Rock Crew", "rock", "repair"),
    (19, "Progressive Slug Crew", "slug", "weapons"),
    (20, "Progressive Lanius Crew", "anaerobic", None),
    (21, "Progressive Crystal Crew", "crystal", None),
)

CREW_RACES: tuple[tuple[int, str, str], ...] = (
    (0, "human", "Human"),
    (1, "engi", "Engi"),
    (2, "energy", "Zoltan"),
    (3, "mantis", "Mantis"),
    (4, "rock", "Rock"),
    (5, "slug", "Slug"),
    (6, "anaerobic", "Lanius"),
)

# --- BEGIN GENERATED BLOCK, extracted from ftl.dat, do not edit by hand ---

SHIPS_RAW: tuple[tuple[int, str, str, int], ...] = (
    (0, "PLAYER_SHIP_ANAEROBIC", "Lanius Cruiser", 2),
    (1, "PLAYER_SHIP_CIRCLE", "Engi Cruiser", 3),
    (2, "PLAYER_SHIP_CRYSTAL", "Crystal Cruiser", 2),
    (3, "PLAYER_SHIP_ENERGY", "Zoltan Cruiser", 3),
    (4, "PLAYER_SHIP_FED", "Federation Cruiser", 3),
    (5, "PLAYER_SHIP_HARD", "Kestrel Cruiser", 3),
    (6, "PLAYER_SHIP_JELLY", "Slug Cruiser", 3),
    (7, "PLAYER_SHIP_MANTIS", "Mantis Cruiser", 3),
    (8, "PLAYER_SHIP_ROCK", "Rock Cruiser", 3),
    (9, "PLAYER_SHIP_STEALTH", "Stealth Cruiser", 3),
)

LAYOUT_SYSTEMS_RAW: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("PLAYER_SHIP_ANAEROBIC",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "clonebay",
      "hacking")),
    ("PLAYER_SHIP_ANAEROBIC_2",
     ("pilot", "doors", "oxygen", "engines", "shields", "weapons", "clonebay", "teleporter",
      "mind")),
    ("PLAYER_SHIP_CIRCLE",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "drones", "medbay")),
    ("PLAYER_SHIP_CIRCLE_2",
     ("pilot", "doors", "oxygen", "engines", "shields", "weapons", "drones", "medbay")),
    ("PLAYER_SHIP_CIRCLE_3",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "drones",
      "clonebay", "hacking")),
    ("PLAYER_SHIP_CRYSTAL",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "medbay")),
    ("PLAYER_SHIP_CRYSTAL_2",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "medbay",
      "teleporter", "cloaking")),
    ("PLAYER_SHIP_ENERGY",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "medbay")),
    ("PLAYER_SHIP_ENERGY_2",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "medbay")),
    ("PLAYER_SHIP_ENERGY_3",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "drones",
      "clonebay", "battery")),
    ("PLAYER_SHIP_FED",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "medbay",
      "artillery")),
    ("PLAYER_SHIP_FED_2",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "medbay",
      "artillery")),
    ("PLAYER_SHIP_FED_3",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "clonebay",
      "teleporter", "artillery")),
    ("PLAYER_SHIP_HARD",
     ("pilot", "doors", "sensors", "medbay", "oxygen", "shields", "engines", "weapons")),
    ("PLAYER_SHIP_HARD_2",
     ("pilot", "doors", "sensors", "medbay", "oxygen", "shields", "engines", "weapons")),
    ("PLAYER_SHIP_HARD_3",
     ("pilot", "doors", "sensors", "clonebay", "oxygen", "shields", "engines", "weapons")),
    ("PLAYER_SHIP_JELLY",
     ("pilot", "doors", "oxygen", "engines", "shields", "weapons", "medbay")),
    ("PLAYER_SHIP_JELLY_2",
     ("pilot", "doors", "oxygen", "engines", "shields", "weapons", "teleporter")),
    ("PLAYER_SHIP_JELLY_3",
     ("pilot", "doors", "oxygen", "engines", "shields", "weapons", "clonebay", "mind", "hacking")),
    ("PLAYER_SHIP_MANTIS",
     ("pilot", "doors", "oxygen", "shields", "engines", "weapons", "medbay", "teleporter")),
    ("PLAYER_SHIP_MANTIS_2",
     ("pilot", "doors", "sensors", "oxygen", "shields", "engines", "weapons", "drones", "medbay",
      "teleporter")),
    ("PLAYER_SHIP_MANTIS_3",
     ("pilot", "doors", "sensors", "oxygen", "shields", "engines", "weapons", "clonebay",
      "teleporter")),
    ("PLAYER_SHIP_ROCK",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "medbay")),
    ("PLAYER_SHIP_ROCK_2",
     ("pilot", "sensors", "oxygen", "engines", "shields", "weapons", "medbay")),
    ("PLAYER_SHIP_ROCK_3",
     ("pilot", "doors", "sensors", "oxygen", "engines", "shields", "weapons", "clonebay")),
    ("PLAYER_SHIP_STEALTH",
     ("pilot", "doors", "sensors", "oxygen", "engines", "weapons", "medbay", "cloaking")),
    ("PLAYER_SHIP_STEALTH_2",
     ("pilot", "doors", "sensors", "oxygen", "engines", "weapons", "medbay", "cloaking")),
    ("PLAYER_SHIP_STEALTH_3",
     ("pilot", "doors", "oxygen", "engines", "weapons", "drones", "clonebay")),
)

LAYOUT_EMPTY_SLOTS_RAW: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("PLAYER_SHIP_ANAEROBIC", ("drones", "medbay", "teleporter", "cloaking", "battery", "mind")),
    ("PLAYER_SHIP_ANAEROBIC_2",
     ("sensors", "drones", "medbay", "cloaking", "battery", "hacking")),
    ("PLAYER_SHIP_CIRCLE", ("clonebay", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_CIRCLE_2",
     ("sensors", "clonebay", "teleporter", "cloaking", "mind", "battery", "hacking")),
    ("PLAYER_SHIP_CIRCLE_3", ("medbay", "teleporter", "cloaking", "battery", "mind")),
    ("PLAYER_SHIP_CRYSTAL",
     ("drones", "clonebay", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_CRYSTAL_2", ("drones", "clonebay", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_ENERGY",
     ("drones", "clonebay", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_ENERGY_2",
     ("drones", "clonebay", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_ENERGY_3", ("medbay", "teleporter", "cloaking", "mind", "hacking")),
    ("PLAYER_SHIP_FED",
     ("drones", "clonebay", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_FED_2",
     ("drones", "clonebay", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_FED_3", ("drones", "medbay", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_HARD",
     ("clonebay", "drones", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_HARD_2",
     ("clonebay", "drones", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_HARD_3",
     ("medbay", "drones", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_JELLY",
     ("clonebay", "sensors", "drones", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_JELLY_2",
     ("sensors", "medbay", "clonebay", "drones", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_JELLY_3", ("medbay", "sensors", "drones", "teleporter", "cloaking", "battery")),
    ("PLAYER_SHIP_MANTIS",
     ("sensors", "drones", "clonebay", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_MANTIS_2", ("clonebay", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_MANTIS_3", ("drones", "medbay", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_ROCK",
     ("drones", "clonebay", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_ROCK_2",
     ("doors", "drones", "clonebay", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_ROCK_3",
     ("drones", "medbay", "teleporter", "cloaking", "battery", "mind", "hacking")),
    ("PLAYER_SHIP_STEALTH",
     ("shields", "drones", "clonebay", "teleporter", "hacking", "battery", "mind")),
    ("PLAYER_SHIP_STEALTH_2",
     ("shields", "drones", "clonebay", "teleporter", "hacking", "battery", "mind")),
    ("PLAYER_SHIP_STEALTH_3",
     ("sensors", "shields", "medbay", "teleporter", "cloaking", "hacking", "battery", "mind")),
)

SYSTEMS_RAW: tuple[tuple[int, str, str, int], ...] = (
    (0, "artillery", "Artillery Beam", 4),
    (1, "battery", "Backup Battery", 2),
    (2, "cloaking", "Cloaking", 3),
    (3, "clonebay", "Clone Bay", 3),
    (4, "doors", "Door System", 3),
    (5, "drones", "Drone Control", 8),
    (6, "engines", "Engines", 8),
    (7, "hacking", "Hacking", 3),
    (8, "medbay", "Medbay", 3),
    (9, "mind", "Mind Control", 3),
    (10, "oxygen", "Oxygen", 3),
    (11, "pilot", "Piloting", 3),
    (12, "sensors", "Sensors", 3),
    (13, "shields", "Shields", 8),
    (14, "teleporter", "Crew Teleporter", 3),
    (15, "weapons", "Weapon Control", 8),
)

GENERAL_ACHIEVEMENTS_RAW: tuple[tuple[int, str, str, str], ...] = (
    (0, "ACH_BAD_DODGING", "Astronomically Low Odds", "feats"),
    (1, "ACH_BOARDING_DRONE", "BOARDING OBJECTIVE SUCCESSFUL", "feats"),
    (2, "ACH_BURNING", "Some people just like to watch ships burn", "feats"),
    (3, "ACH_INVADE_SHIP", "Trustworthy Auto-Pilot", "feats"),
    (4, "ACH_NO_BUYING", "Living off the Land", "distance"),
    (5, "ACH_NO_DEATH", "No Redshirts Here", "distance"),
    (6, "ACH_NO_DRONES", "Technophobia", "distance"),
    (7, "ACH_NO_MISSILES", "Ballistophobia", "distance"),
    (8, "ACH_NO_REPAIR", "On a Wing and a Prayer", "distance"),
    (9, "ACH_NO_UPGRADES", "I don't need no stinkin' upgrades!", "distance"),
    (10, "ACH_ONE_VOLLEY", "They never saw it coming", "feats"),
    (11, "ACH_PACIFIST", "Coming in for my Pacifism run!", "distance"),
    (12, "ACH_SCRAP", "Rule Ten: Greed is Eternal", "general"),
    (13, "ACH_SECTOR_5", "Just Getting Started", "general"),
    (14, "ACH_SECTOR_8", "Federation Base in Range", "general"),
    (15, "ACH_SHIPS", "Warlord", "general"),
    (16, "ACH_SLICE_DICE", "Slice and Dice", "feats"),
    (17, "ACH_SUFFOCATE", "Victory through Asphyxiation", "feats"),
    (18, "ACH_UNLOCK_ALL", "Your Own Fleet", "general"),
    (19, "ACH_WIN_EASY", "Federation Victory (Easy)", "general"),
    (20, "ACH_WIN_NORMAL", "Federation Victory (Normal)", "general"),
)

SHIP_ACHIEVEMENTS_RAW: tuple[tuple[int, str, str, str], ...] = (
    (0, "PLAYER_SHIP_ANAEROBIC", "ACH_LANIUS_ADVANCED", "Advanced Mastery"),
    (1, "PLAYER_SHIP_ANAEROBIC", "ACH_LANIUS_OXYGEN", "Loss of Cabin Pressure"),
    (2, "PLAYER_SHIP_ANAEROBIC", "ACH_LANIUS_SCRAP", "Scrap Hoarder"),
    (0, "PLAYER_SHIP_CIRCLE", "ACH_IONED", "The guns... They've stopped"),
    (1, "PLAYER_SHIP_CIRCLE", "ACH_ONLY_DRONES", "I hardly lifted a finger"),
    (2, "PLAYER_SHIP_CIRCLE", "ACH_ROBOTIC", "Robotic Warfare"),
    (0, "PLAYER_SHIP_CRYSTAL", "ACH_CRYSTAL_CLASH", "Clash of the Titans"),
    (1, "PLAYER_SHIP_CRYSTAL", "ACH_CRYSTAL_LOCKDOWN", "No Escape"),
    (2, "PLAYER_SHIP_CRYSTAL", "ACH_CRYSTAL_SHARD", "Sweet Revenge"),
    (0, "PLAYER_SHIP_ENERGY", "ACH_ENERGY_MANPOWER", "Manpower"),
    (1, "PLAYER_SHIP_ENERGY", "ACH_ENERGY_POWER", "Givin' her all she's got, Captain!"),
    (2, "PLAYER_SHIP_ENERGY", "ACH_ENERGY_SHIELDS", "Shields Holding"),
    (0, "PLAYER_SHIP_FED", "ACH_FED_DIPLOMACY", "Diplomatic Immunity"),
    (1, "PLAYER_SHIP_FED", "ACH_FED_PATIENCE", "Master of Patience"),
    (2, "PLAYER_SHIP_FED", "ACH_FED_UPGRADE", "Artillery Mastery"),
    (0, "PLAYER_SHIP_HARD", "ACH_FULL_ARSENAL", "Full Arsenal"),
    (1, "PLAYER_SHIP_HARD", "ACH_TOUGH_SHIP", "Tough Little Ship"),
    (2, "PLAYER_SHIP_HARD", "ACH_UNITED_FEDERATION", "The United Federation"),
    (0, "PLAYER_SHIP_JELLY", "ACH_SLUG_BIO", "Disintegration Ray"),
    (1, "PLAYER_SHIP_JELLY", "ACH_SLUG_NEBULA", "Home Sweet Home"),
    (2, "PLAYER_SHIP_JELLY", "ACH_SLUG_VISION", "We're in Position!"),
    (0, "PLAYER_SHIP_MANTIS", "ACH_MANTIS_CREW_DEAD", "Take no prisoners!"),
    (1, "PLAYER_SHIP_MANTIS", "ACH_MANTIS_SLAUGHTER", "Avast, ye scurvy dogs!"),
    (2, "PLAYER_SHIP_MANTIS", "ACH_MANTIS_SURVIVOR", "Battle Royale"),
    (0, "PLAYER_SHIP_ROCK", "ACH_ROCK_CRYSTAL", "Ancestry"),
    (1, "PLAYER_SHIP_ROCK", "ACH_ROCK_FIRE", "Is it warm in here?"),
    (2, "PLAYER_SHIP_ROCK", "ACH_ROCK_MISSILES", "Defense Drones Don't Do D'anything!"),
    (0, "PLAYER_SHIP_STEALTH", "ACH_STEALTH_AVOID", "Phase Shift"),
    (1, "PLAYER_SHIP_STEALTH", "ACH_STEALTH_DESTROY", "Bird of Prey"),
    (2, "PLAYER_SHIP_STEALTH", "ACH_STEALTH_TACTICAL", "Tactical Approach"),
)

ACHIEVEMENT_DESCRIPTIONS_RAW: tuple[tuple[str, str], ...] = (
    ("ACH_BAD_DODGING", "Fail to evade 5 shots in a row with a fully powered and upgraded engine."),
    ("ACH_BOARDING_DRONE", "Have a single boarding drone kill 4 crewmembers on one ship."),
    ("ACH_BURNING", "Have every square of an enemy ship on fire simultaneously."),
    ("ACH_CRYSTAL_CLASH", "Destroy 10 Rock Ships (pirates count) using the Crystal Cruiser."),
    ("ACH_CRYSTAL_LOCKDOWN", "While using the Crystal Cruiser, trap 4 enemy crew in a single room using the Crystal Being power or a Lockdown Bomb."),
    ("ACH_CRYSTAL_SHARD", "Destroy an enemy ship with a shard from the Crystal Vengeance augment (unique to the Crystal Cruiser)."),
    ("ACH_ENERGY_MANPOWER", "Get to sector 5 without upgrading your reactor in the Zoltan Cruiser."),
    ("ACH_ENERGY_POWER", "With the Zoltan Cruiser, have 29 power in systems at the same time."),
    ("ACH_ENERGY_SHIELDS", "Destroy a ship before it gets through the Zoltan Shield."),
    ("ACH_FED_DIPLOMACY", "While using the Federation Cruiser, use your crew in 4 special blue event choices by sector 5."),
    ("ACH_FED_PATIENCE", "Use only the Artillery Beam to destroy an enemy ship while taking no hull damage."),
    ("ACH_FED_UPGRADE", "Get to sector 5 in the Federation Cruiser without upgrading your Weapons system."),
    ("ACH_FULL_ARSENAL", "Have 11 systems installed on the Kestrel Cruiser at one time."),
    ("ACH_INVADE_SHIP", "Defeat an enemy ship with all of your crew aboard it."),
    ("ACH_IONED", "Have 4 enemy systems or subsystems ioned at the same time while using the Engi Cruiser."),
    ("ACH_LANIUS_ADVANCED", "Have Hacking, Mind Control and the Battery active at once."),
    ("ACH_LANIUS_OXYGEN", "Get to sector 8 without your ship's net oxygen levels exceeding 20 percent (starts after the first jump)."),
    ("ACH_LANIUS_SCRAP", "Have at least 600 scrap in your ship storage."),
    ("ACH_MANTIS_CREW_DEAD", "Kill the crew of 20 ships by sector 6 in the Mantis Cruiser."),
    ("ACH_MANTIS_SLAUGHTER", "Kill 5 enemy crew in a fight without taking hull damage or losing a crewmember while using the Mantis Cruiser."),
    ("ACH_MANTIS_SURVIVOR", "While using the Mantis Cruiser, kill the last enemy with your last crewmember on their ship."),
    ("ACH_NO_BUYING", "Get to sector 8 without buying at a store (Repairs are ok)."),
    ("ACH_NO_DEATH", "Get to sector 8 without losing a crewmember."),
    ("ACH_NO_DRONES", "Get to sector 8 without using drones."),
    ("ACH_NO_MISSILES", "Get to sector 8 without using missiles/bombs."),
    ("ACH_NO_REPAIR", "Get to sector 5 without repairing at a store."),
    ("ACH_NO_UPGRADES", "Get to sector 5 with no system/reactor upgrades."),
    ("ACH_ONE_VOLLEY", "Use the Weapon Pre-Igniter augmentation to destroy an enemy ship in one volley before the enemy can get a single shot off."),
    ("ACH_ONLY_DRONES", "With the Engi Cruiser, destroy an enemy ship using only drones (no weapons)."),
    ("ACH_PACIFIST", "Get to sector 5 without firing a shot, using an offensive drone, or teleporting."),
    ("ACH_ROBOTIC", "With the Engi Cruiser, have 3 drones functioning at the same time."),
    ("ACH_ROCK_CRYSTAL", "Find the secret sector with the Rock Cruiser."),
    ("ACH_ROCK_FIRE", "Have your crew kill a burning enemy on their ship while using the Rock Cruiser."),
    ("ACH_ROCK_MISSILES", "While using the Rock Cruiser, destroy an enemy ship which has a defense drone deployed using only missiles."),
    ("ACH_SCRAP", "Collect 10,000 scrap across all games."),
    ("ACH_SECTOR_5", "Get to sector 5."),
    ("ACH_SECTOR_8", "Get to sector 8."),
    ("ACH_SHIPS", "Defeat 1000 ships across all playthroughs."),
    ("ACH_SLICE_DICE", "Hit every room of a ship with at least one beam in under 5 seconds."),
    ("ACH_SLUG_BIO", "While using the Slug Cruiser, kill 3 enemy crewmembers with one shot from the Anti-Bio Beam."),
    ("ACH_SLUG_NEBULA", "Jump to 30 nebula locations before sector 8."),
    ("ACH_SLUG_VISION", "While using the Slug Cruiser, have vision of every room of the enemy ship without functioning sensors."),
    ("ACH_STEALTH_AVOID", "With the Stealth Cruiser, avoid 9 points of damage during a single cloak."),
    ("ACH_STEALTH_DESTROY", "Destroy a ship at full health during a single cloak in the Stealth Cruiser."),
    ("ACH_STEALTH_TACTICAL", "With the Stealth Cruiser, get to sector 8 without jumping to a beacon with an environmental danger."),
    ("ACH_SUFFOCATE", "Empty the oxygen (Net level less than 5 percent) of a non-automated, hostile enemy ship."),
    ("ACH_TOUGH_SHIP", "As the Kestrel Cruiser, repair back to full health when it only has 1 HP remaining."),
    ("ACH_UNITED_FEDERATION", "Have six unique aliens on the Kestrel Cruiser simultaneously."),
    ("ACH_UNLOCK_ALL", "Unlock the Type A layout for every playable ship."),
    ("ACH_WIN_EASY", "Beat the boss on Easy."),
    ("ACH_WIN_NORMAL", "Beat the boss on Normal."),
)

SHOP_ITEMS_RAW: tuple[tuple[int, str, str, str, int, int], ...] = (
    (0, "weapon", "BEAM_2", "Halberd Beam", 2, 65),
    (1, "weapon", "BEAM_3", "Glaive Beam", 5, 95),
    (2, "weapon", "BEAM_BIO", "Anti-Bio Beam", 5, 50),
    (3, "weapon", "BEAM_FIRE", "Fire Beam", 3, 50),
    (4, "weapon", "BEAM_HULL", "Hull Beam", 3, 70),
    (5, "weapon", "BEAM_LONG", "Pike Beam", 2, 55),
    (6, "weapon", "BOMB_1", "Small Bomb", 1, 45),
    (7, "weapon", "BOMB_BREACH_2", "Breach Bomb Mark II", 4, 60),
    (8, "weapon", "BOMB_FIRE", "Fire Bomb", 2, 50),
    (9, "weapon", "BOMB_HEAL", "Healing Burst", 3, 40),
    (10, "weapon", "BOMB_HEAL_SYSTEM", "Repair Burst", 3, 40),
    (11, "weapon", "BOMB_ION", "Ion Bomb", 3, 55),
    (12, "weapon", "BOMB_STUN", "Stun Bomb", 2, 45),
    (13, "weapon", "ION_1", "Ion Blast", 3, 30),
    (14, "weapon", "ION_2", "Heavy Ion", 3, 45),
    (15, "weapon", "ION_4", "Ion Blast Mark II", 4, 70),
    (16, "weapon", "ION_CHAINGUN", "Chain Ion", 4, 55),
    (17, "weapon", "ION_CHARGEGUN", "Ion Charger", 3, 50),
    (18, "weapon", "ION_STUN", "Ion Stunner", 4, 35),
    (19, "weapon", "LASER_BURST_2_A", "Burst Laser Mark I", 1, 50),
    (20, "weapon", "LASER_BURST_3", "Burst Laser Mark II", 4, 80),
    (21, "weapon", "LASER_BURST_5", "Burst Laser Mark III", 4, 95),
    (22, "weapon", "LASER_CHAINGUN", "Chain Burst Laser", 3, 65),
    (23, "weapon", "LASER_CHAINGUN_2", "Chain Vulcan", 5, 95),
    (24, "weapon", "LASER_CHARGEGUN", "Laser Charger", 3, 55),
    (25, "weapon", "LASER_CHARGEGUN_2", "Laser Charger Mark II", 3, 70),
    (26, "weapon", "LASER_HEAVY_1", "Heavy Laser Mark I", 2, 50),
    (27, "weapon", "LASER_HEAVY_2", "Heavy Laser Mark II", 4, 65),
    (28, "weapon", "LASER_HULL_1", "Hull Smasher Laser", 2, 55),
    (29, "weapon", "LASER_HULL_2", "Hull Smasher Laser Mark II", 3, 75),
    (30, "weapon", "MISSILES_3", "Hermes Missile", 2, 45),
    (31, "weapon", "MISSILES_BREACH", "Breach Missiles", 3, 65),
    (32, "weapon", "MISSILES_BURST", "Pegasus Missile", 3, 60),
    (33, "weapon", "MISSILES_HULL", "Hull Missile", 3, 65),
    (34, "weapon", "MISSILE_CHARGEGUN", "Swarm Missiles", 4, 65),
    (35, "weapon", "SHOTGUN", "Flak Gun Mark I", 1, 65),
    (36, "weapon", "SHOTGUN_2", "Flak Gun Mark II", 4, 80),
    (0, "drone", "ANTI_DRONE", "Anti-Combat Drone", 1, 35),
    (1, "drone", "BATTLE", "Anti-Personnel Drone", 2, 35),
    (2, "drone", "BOARDER", "Boarding Drone", 4, 70),
    (3, "drone", "BOARDER_ION", "Ion Intruder Drone", 4, 65),
    (4, "drone", "COMBAT_1", "Combat Drone Mark I", 2, 50),
    (5, "drone", "COMBAT_2", "Combat Drone Mark II", 5, 75),
    (6, "drone", "COMBAT_BEAM", "Anti-Ship Beam Drone I", 3, 50),
    (7, "drone", "COMBAT_BEAM_2", "Anti-Ship Beam Drone II", 5, 60),
    (8, "drone", "COMBAT_FIRE", "Anti-Ship Fire Drone", 4, 50),
    (9, "drone", "DEFENSE_1", "Defense Drone Mark I", 1, 50),
    (10, "drone", "DEFENSE_2", "Defense Drone Mark II", 3, 70),
    (11, "drone", "DRONE_SHIELD", "Shield Overcharger", 4, 60),
    (12, "drone", "REPAIR", "System Repair Drone", 1, 30),
    (13, "drone", "SHIP_REPAIR", "Hull Repair", 4, 85),
    (0, "augment", "ADV_SCANNERS", "Long-Ranged Scanners", 1, 30),
    (1, "augment", "AUTO_COOLDOWN", "Automated Re-loader", 2, 40),
    (2, "augment", "BACKUP_DNA", "Backup DNA Bank", 2, 40),
    (3, "augment", "BATTERY_BOOSTER", "Battery Charger", 2, 40),
    (4, "augment", "CLOAK_FIRE", "Stealth Weapons", 3, 50),
    (5, "augment", "DEFENSE_SCRAMBLER", "Defense Scrambler", 4, 80),
    (6, "augment", "DRONE_RECOVERY", "Drone Recovery Arm", 2, 50),
    (7, "augment", "EXPLOSIVE_REPLICATOR", "Explosive Replicator", 3, 60),
    (8, "augment", "FIRE_EXTINGUISHERS", "Fire Suppression", 3, 65),
    (9, "augment", "FLEET_DISTRACTION", "Distraction Buoys", 3, 55),
    (10, "augment", "FTL_BOOSTER", "FTL Recharge Booster", 2, 50),
    (11, "augment", "FTL_JAMMER", "FTL Jammer", 3, 30),
    (12, "augment", "FTL_JUMPER", "Adv. FTL Navigation", 3, 50),
    (13, "augment", "HACKING_STUN", "Hacking Stun", 3, 60),
    (14, "augment", "ION_ARMOR", "Reverse Ion Field", 2, 45),
    (15, "augment", "LIFE_SCANNER", "Lifeform Scanner", 3, 40),
    (16, "augment", "O2_MASKS", "Emergency Respirators", 2, 50),
    (17, "augment", "REPAIR_ARM", "Repair Arm", 3, 50),
    (18, "augment", "SCRAP_COLLECTOR", "Scrap Recovery Arm", 1, 50),
    (19, "augment", "SHIELD_RECHARGE", "Shield Charge Booster", 2, 45),
    (20, "augment", "TELEPORT_HEAL", "Reconstructive Teleport", 3, 70),
    (21, "augment", "WEAPON_PREIGNITE", "Weapon Pre-igniter", 4, 120),
    (22, "augment", "ZOLTAN_BYPASS", "Zoltan Shield Bypass", 3, 55),
)

# --- END GENERATED BLOCK ---

FILLER_RAW: tuple[tuple[int, str, str, int, int], ...] = (
    (0, "20 Scrap", "scrap", 20, 20),
    (1, "50 Scrap", "scrap", 50, 10),
    (2, "Fuel Cache", "fuel", 5, 12),
    (3, "Missile Crate", "missiles", 3, 12),
    (4, "Drone Parts", "drone_parts", 2, 10),
    (5, "Hull Repair", "hull", 5, 8),
    (6, "New Crew Member", "crew", 1, 6),
)

FILLER_ITEM_NAME = "20 Scrap"

TRAPS_RAW: tuple[tuple[int, str, str, int], ...] = (
    (0, "Fire Trap", "fire", 4),
    (1, "Hull Breach Trap", "breach", 4),
    (2, "Fuel Leak Trap", "fuel_leak", 3),
    (3, "System Damage Trap", "system_damage", 4),
    (4, "Rebel Fleet Trap", "fleet_advance", 2),
    (5, "Hull Damage Trap", "hull_damage", 3),
    (6, "Boarding Party Trap", "boarding", 2),
)

RESOURCES_IMPLEMENTED = ("scrap", "fuel", "missiles", "drone_parts", "hull", "crew")
TRAP_EFFECTS_IMPLEMENTED = ("fire", "breach", "fuel_leak", "system_damage", "fleet_advance",
                            "hull_damage", "boarding")

BONUS_RAW: tuple[tuple[int, str, str, int, str], ...] = (
    (0, "Reactor Power", REACTOR_TARGET, 8, "useful"),
)

VICTORY_ITEM_NAME = "Victory"

GROUP_SHIP_KEYS = "Ship keys"
GROUP_SHIP_LAYOUTS = "Ship layouts"
GROUP_BLUEPRINTS = "System blueprints"
GROUP_SYSTEM_LEVELS = "System upgrades"
GROUP_HEAD_STARTS = "Head starts"
GROUP_BONUSES = "Permanent bonuses"
GROUP_FILLER = "Filler"
GROUP_TRAPS = "Traps"
GROUP_SHOP_WEAPONS = "Weapons"
GROUP_SHOP_DRONES = "Drones"
GROUP_SHOP_AUGMENTS = "Augmentations"
GROUP_ARCHIVES = "Archives"

SHOP_FAMILIES: tuple[str, ...] = ("weapon", "drone", "augment")
SHOP_FAMILY_GROUPS: dict[str, str] = {
    "weapon": GROUP_SHOP_WEAPONS,
    "drone": GROUP_SHOP_DRONES,
    "augment": GROUP_SHOP_AUGMENTS,
}
SHOP_FAMILY_OFFSETS: dict[str, int] = {
    "weapon": ITEM_OFFSET_SHOP_WEAPON,
    "drone": ITEM_OFFSET_SHOP_DRONE,
    "augment": ITEM_OFFSET_SHOP_AUGMENT,
}

GROUP_SYSTEMS = "Systems"
GROUP_CREW = "Crew"
GROUP_CREW_MEMBERS = "Crew members"
GROUP_SECTORS = "Sectors"
GROUP_VICTORIES = "Ship victories"
GROUP_SHIP_ACHIEVEMENTS = "Ship achievements"
GROUP_GENERAL_ACHIEVEMENTS = "General achievements"
GROUP_SHOP_SLOTS = "Archipelago shop"

TIER_GENERAL = "general"
TIER_DISTANCE = "distance"
TIER_FEATS = "feats"

TIER_DIFFICULTY = "difficulty"


@dataclass(frozen=True)
class Ship:

    blueprint: str
    slot: int
    display: str
    layout_count: int


@dataclass(frozen=True)
class Layout:

    blueprint: str
    ship: str
    variant: int
    letter: str
    display: str
    index: int
    start_systems: tuple[str, ...] = ()
    empty_slots: tuple[str, ...] = ()


@dataclass(frozen=True)
class System:

    system_id: str
    slot: int
    display: str
    max_level: int


@dataclass(frozen=True)
class Item:

    name: str
    code: int
    group: str
    classification: str
    kind: str
    blueprint: str | None = None
    system: str | None = None
    resource: str | None = None
    trap_effect: str | None = None
    amount: int = 1
    count: int = 1
    weight: int = 0
    ship: str | None = None
    family: str | None = None
    rarity: int = 0
    race: str | None = None
    skill: str | None = None
    tiers: int = 0


@dataclass(frozen=True)
class ShopItem:

    blueprint: str
    family: str
    slot: int
    display: str
    rarity: int
    cost: int


@dataclass(frozen=True)
class Location:
    name: str
    code: int
    check_id: str
    group: str
    ship: str | None = None
    layout: str | None = None
    sector: int | None = None
    achievement: str | None = None
    tier: str | None = None
    shop_slot: int | None = None
    system: str | None = None
    level: int | None = None
    race: str | None = None
    description: str = ""


def item_descriptor(item: Item) -> dict[str, object]:
    descriptor: dict[str, object] = {"k": item.kind}
    if item.blueprint is not None:
        descriptor["bp"] = item.blueprint
    if item.system is not None:
        descriptor["sys"] = item.system
    if item.resource is not None:
        descriptor["res"] = item.resource
    if item.trap_effect is not None:
        descriptor["eff"] = item.trap_effect
    if item.amount != 1:
        descriptor["n"] = item.amount
    if item.race is not None:
        descriptor["race"] = item.race
    if item.skill is not None:
        descriptor["skill"] = item.skill
    if item.tiers:
        descriptor["tiers"] = item.tiers
    return descriptor


def _build_ships() -> tuple[Ship, ...]:
    return tuple(
        Ship(blueprint=blueprint, slot=slot, display=display, layout_count=layout_count)
        for slot, blueprint, display, layout_count in SHIPS_RAW
    )


SHIPS: tuple[Ship, ...] = _build_ships()
SHIPS_BY_BLUEPRINT: dict[str, Ship] = {ship.blueprint: ship for ship in SHIPS}


LAYOUT_SYSTEMS: dict[str, tuple[str, ...]] = dict(LAYOUT_SYSTEMS_RAW)
LAYOUT_EMPTY_SLOTS: dict[str, tuple[str, ...]] = dict(LAYOUT_EMPTY_SLOTS_RAW)
ACHIEVEMENT_DESCRIPTIONS: dict[str, str] = dict(ACHIEVEMENT_DESCRIPTIONS_RAW)


def _build_layouts() -> tuple[Layout, ...]:
    layouts = []
    for ship in SHIPS:
        for variant in range(ship.layout_count):
            blueprint = ship.blueprint + LAYOUT_SUFFIXES[variant]
            layouts.append(Layout(
                blueprint=blueprint,
                ship=ship.blueprint,
                variant=variant,
                letter=LAYOUT_LETTERS[variant],
                display=f"{ship.display} {LAYOUT_LETTERS[variant]}",
                index=ship.slot * len(LAYOUT_SUFFIXES) + variant,
                start_systems=LAYOUT_SYSTEMS[blueprint],
                empty_slots=LAYOUT_EMPTY_SLOTS[blueprint],
            ))
    return tuple(layouts)


def _build_systems() -> tuple[System, ...]:
    return tuple(
        System(system_id=system_id, slot=slot, display=display, max_level=max_level)
        for slot, system_id, display, max_level in SYSTEMS_RAW
    )


def _build_shop_items() -> tuple[ShopItem, ...]:
    return tuple(
        ShopItem(blueprint=blueprint, family=family, slot=slot, display=display,
                 rarity=rarity, cost=cost)
        for slot, family, blueprint, display, rarity, cost in SHOP_ITEMS_RAW
    )


SHOP_ITEMS: tuple[ShopItem, ...] = _build_shop_items()
SHOP_ITEMS_BY_BLUEPRINT: dict[str, ShopItem] = {item.blueprint: item for item in SHOP_ITEMS}
SHOP_ITEMS_BY_FAMILY: dict[str, tuple[ShopItem, ...]] = {
    family: tuple(item for item in SHOP_ITEMS if item.family == family)
    for family in SHOP_FAMILIES
}


LAYOUTS: tuple[Layout, ...] = _build_layouts()
LAYOUTS_BY_BLUEPRINT: dict[str, Layout] = {layout.blueprint: layout for layout in LAYOUTS}
SYSTEMS: tuple[System, ...] = _build_systems()
SYSTEMS_BY_ID: dict[str, System] = {system.system_id: system for system in SYSTEMS}


def _build_items() -> tuple[Item, ...]:
    items: list[Item] = []

    for ship in SHIPS:
        items.append(Item(
            name=f"{ship.display} Key",
            code=ITEM_ID_BASE + ITEM_OFFSET_SHIP_KEY + ship.slot,
            group=GROUP_SHIP_KEYS,
            classification="progression",
            kind=KIND_SHIP,
            blueprint=ship.blueprint,
            ship=ship.blueprint,
        ))

    layout_offsets = (None, ITEM_OFFSET_LAYOUT_B, ITEM_OFFSET_LAYOUT_C)
    for layout in LAYOUTS:
        if layout.variant == 0:
            continue
        ship = SHIPS_BY_BLUEPRINT[layout.ship]
        items.append(Item(
            name=f"Layout {layout.letter} - {ship.display}",
            code=ITEM_ID_BASE + layout_offsets[layout.variant] + ship.slot,
            group=GROUP_SHIP_LAYOUTS,
            classification="progression",
            kind=KIND_SHIP,
            blueprint=layout.blueprint,
            ship=ship.blueprint,
        ))

    for system in SYSTEMS:
        items.append(Item(
            name=f"{system.display} blueprint",
            code=ITEM_ID_BASE + ITEM_OFFSET_BLUEPRINT + system.slot,
            group=GROUP_BLUEPRINTS,
            classification="progression",
            kind=KIND_CAP,
            system=system.system_id,
            amount=0,
        ))

        if system.max_level > 1:
            items.append(Item(
                name=f"Progressive {system.display}",
                code=ITEM_ID_BASE + ITEM_OFFSET_SYSTEM_LEVEL + system.slot,
                group=GROUP_SYSTEM_LEVELS,
                classification="useful",
                kind=KIND_CAP,
                system=system.system_id,
                count=system.max_level - 1,
            ))

        items.append(Item(
            name=f"Head Start: {system.display}",
            code=ITEM_ID_BASE + ITEM_OFFSET_HEAD_START + system.slot,
            group=GROUP_HEAD_STARTS,
            classification="useful",
            kind=KIND_START,
            system=system.system_id,
        ))

    for slot, name, target, count, classification in BONUS_RAW:
        items.append(Item(
            name=name,
            code=ITEM_ID_BASE + ITEM_OFFSET_BONUS + slot,
            group=GROUP_BONUSES,
            classification=classification,
            kind=KIND_START,
            system=target,
            count=count,
        ))

    items.append(Item(
        name=ARCHIVE_ITEM_NAME,
        code=ITEM_ID_BASE + ITEM_OFFSET_ARCHIVE,
        group=GROUP_ARCHIVES,
        classification="progression_skip_balancing",
        kind=KIND_ARCHIVE,
        count=MAX_ARCHIVES,
    ))

    for slot, name, resource, amount, weight in FILLER_RAW:
        items.append(Item(
            name=name,
            code=ITEM_ID_BASE + ITEM_OFFSET_FILLER + slot,
            group=GROUP_FILLER,
            classification="filler",
            kind=KIND_FILLER,
            resource=resource,
            amount=amount,
            count=0,
            weight=weight,
        ))

    taken = {item.name for item in items}
    family_suffix = {"weapon": "Weapon", "drone": "Drone", "augment": "Augment"}

    for shop_item in SHOP_ITEMS:
        name = shop_item.display
        if name in taken:
            name = f"{shop_item.display} ({family_suffix[shop_item.family]})"
        taken.add(name)
        items.append(Item(
            name=name,
            code=ITEM_ID_BASE + SHOP_FAMILY_OFFSETS[shop_item.family] + shop_item.slot,
            group=SHOP_FAMILY_GROUPS[shop_item.family],
            classification="useful",
            kind=KIND_SHOP,
            blueprint=shop_item.blueprint,
            family=shop_item.family,
            rarity=shop_item.rarity,
            count=2 if shop_item.family in ("weapon", "drone") else 1,
        ))

    for slot, name, race, skill in CREW_ITEMS_RAW:
        items.append(Item(
            name=name,
            code=ITEM_ID_BASE + ITEM_OFFSET_CREW + slot,
            group=GROUP_CREW_MEMBERS,
            classification="useful",
            kind=KIND_CREW,
            race=race,
            skill=skill,
            count=0,
        ))

    for slot, name, race, skill in PROGRESSIVE_CREW_RAW:
        tiers = 3 if skill is not None else 2
        items.append(Item(
            name=name,
            code=ITEM_ID_BASE + ITEM_OFFSET_CREW + slot,
            group=GROUP_CREW_MEMBERS,
            classification="useful",
            kind=KIND_CREW,
            race=race,
            skill=skill,
            tiers=tiers,
            count=tiers,
        ))

    for slot, name, effect, weight in TRAPS_RAW:
        items.append(Item(
            name=name,
            code=ITEM_ID_BASE + ITEM_OFFSET_TRAP + slot,
            group=GROUP_TRAPS,
            classification="trap",
            kind=KIND_TRAP,
            trap_effect=effect,
            count=0,
            weight=weight,
        ))

    return tuple(items)


def _build_locations() -> tuple[Location, ...]:
    locations: list[Location] = []

    for layout in LAYOUTS:
        for sector in range(1, SECTOR_COUNT + 1):
            locations.append(Location(
                name=f"{layout.display}: Reach sector {sector}",
                code=(LOCATION_ID_BASE + LOCATION_OFFSET_SECTOR
                      + layout.index * 10 + sector - 1),
                check_id=SECTOR_CHECK_FORMAT.format(layout=layout.blueprint, sector=sector),
                group=GROUP_SECTORS,
                ship=layout.ship,
                layout=layout.blueprint,
                sector=sector,
            ))

    for layout in LAYOUTS:
        locations.append(Location(
            name=f"{layout.display}: Defeat the Flagship",
            code=LOCATION_ID_BASE + LOCATION_OFFSET_VICTORY + layout.index,
            check_id=VICTORY_CHECK_FORMAT.format(layout=layout.blueprint),
            group=GROUP_VICTORIES,
            ship=layout.ship,
            layout=layout.blueprint,
        ))

    for slot, ship_blueprint, achievement, label in SHIP_ACHIEVEMENTS_RAW:
        ship = SHIPS_BY_BLUEPRINT[ship_blueprint]
        locations.append(Location(
            name=f"{ship.display}: {label}",
            code=(LOCATION_ID_BASE + LOCATION_OFFSET_SHIP_ACH
                  + ship.slot * MAX_ACHIEVEMENTS_PER_SHIP + slot),
            check_id=ACHIEVEMENT_CHECK_FORMAT.format(achievement=achievement),
            group=GROUP_SHIP_ACHIEVEMENTS,
            ship=ship_blueprint,
            achievement=achievement,
            description=ACHIEVEMENT_DESCRIPTIONS[achievement],
        ))

    for slot in range(1, MAX_SHOP_SLOTS + 1):
        locations.append(Location(
            name=f"Archipelago Shop {slot}",
            code=LOCATION_ID_BASE + LOCATION_OFFSET_SHOP + slot,
            check_id=SHOP_CHECK_FORMAT.format(slot=slot),
            group=GROUP_SHOP_SLOTS,
            shop_slot=slot,
        ))

    for system in SYSTEMS:
        locations.append(Location(
            name=f"Install {system.display}",
            code=(LOCATION_ID_BASE + LOCATION_OFFSET_SYSTEM + system.slot * 10),
            check_id=SYSTEM_CHECK_FORMAT.format(system=system.system_id),
            group=GROUP_SYSTEMS,
            system=system.system_id,
            level=1,
        ))
        for level in range(2, system.max_level + 1):
            locations.append(Location(
                name=f"{system.display} level {level}",
                code=(LOCATION_ID_BASE + LOCATION_OFFSET_SYSTEM
                      + system.slot * 10 + level - 1),
                check_id=SYSTEM_LEVEL_CHECK_FORMAT.format(
                    system=system.system_id, level=level),
                group=GROUP_SYSTEMS,
                system=system.system_id,
                level=level,
            ))

    for slot, race, label in CREW_RACES:
        locations.append(Location(
            name=f"First {label} aboard",
            code=LOCATION_ID_BASE + LOCATION_OFFSET_CREW + slot,
            check_id=CREW_CHECK_FORMAT.format(race=race),
            group=GROUP_CREW,
            race=race,
        ))

    for slot, achievement, label, tier in GENERAL_ACHIEVEMENTS_RAW:
        locations.append(Location(
            name=f"Achievement: {label}",
            code=LOCATION_ID_BASE + LOCATION_OFFSET_GENERAL_ACH + slot,
            check_id=ACHIEVEMENT_CHECK_FORMAT.format(achievement=achievement),
            group=GROUP_GENERAL_ACHIEVEMENTS,
            achievement=achievement,
            tier=tier,
            description=ACHIEVEMENT_DESCRIPTIONS[achievement],
        ))

    return tuple(locations)


ITEMS: tuple[Item, ...] = _build_items()
ITEMS_BY_NAME: dict[str, Item] = {item.name: item for item in ITEMS}

LOCATIONS: tuple[Location, ...] = _build_locations()
LOCATIONS_BY_NAME: dict[str, Location] = {loc.name: loc for loc in LOCATIONS}


def _name_groups(entries) -> dict[str, set[str]]:
    groups: dict[str, set[str]] = {}
    for entry in entries:
        groups.setdefault(entry.group, set()).add(entry.name)
    return groups


ITEM_NAME_GROUPS: dict[str, set[str]] = _name_groups(ITEMS)
LOCATION_NAME_GROUPS: dict[str, set[str]] = _name_groups(LOCATIONS)

SHIP_KEY_NAMES: dict[str, str] = {
    item.blueprint: item.name for item in ITEMS if item.group == GROUP_SHIP_KEYS
}
LAYOUT_ITEM_NAMES: dict[str, str] = {
    item.blueprint: item.name for item in ITEMS if item.group == GROUP_SHIP_LAYOUTS
}
BLUEPRINT_ITEM_NAMES: dict[str, str] = {
    item.system: item.name for item in ITEMS if item.group == GROUP_BLUEPRINTS
}


def _check() -> None:
    def unique(values, label):
        seen = set()
        for value in values:
            if value in seen:
                raise ValueError(f"duplicate {label}: {value!r}")
            seen.add(value)

    unique([item.name for item in ITEMS], "item name")
    unique([item.code for item in ITEMS], "item id")
    unique([loc.name for loc in LOCATIONS], "location name")
    unique([loc.code for loc in LOCATIONS], "location id")
    unique([loc.check_id for loc in LOCATIONS], "check id")
    unique([ship.slot for ship in SHIPS], "ship slot")
    unique([system.slot for system in SYSTEMS], "system slot")

    required = {
        KIND_SHIP: "blueprint",
        KIND_CAP: "system",
        KIND_START: "system",
        KIND_FILLER: "resource",
        KIND_TRAP: "trap_effect",
        KIND_SHOP: "blueprint",
        KIND_WEAPON: "blueprint",
        KIND_DRONE: "blueprint",
        KIND_AUGMENT: "blueprint",
        KIND_CREW: "race",
    }
    for item in ITEMS:
        if item.kind not in KINDS_IMPLEMENTED:
            raise ValueError(f"{item.name!r} has a kind unknown to the contract: {item.kind!r}")
        if item.kind not in required:
            continue
        if getattr(item, required[item.kind]) is None:
            raise ValueError(
                f"{item.name!r} is of kind {item.kind!r} but has no "
                f"{required[item.kind]!r}"
            )

    for layout in LAYOUTS:
        unknown_systems = [s for s in layout.start_systems if s not in SYSTEMS_BY_ID]
        if unknown_systems:
            raise ValueError(
                f"{layout.blueprint} starts with unknown systems: {unknown_systems}"
            )
        unknown_slots = [s for s in layout.empty_slots if s not in SYSTEMS_BY_ID]
        if unknown_slots:
            raise ValueError(
                f"{layout.blueprint} has slots for unknown systems: {unknown_slots}"
            )
        both = set(layout.start_systems) & set(layout.empty_slots)
        if both:
            raise ValueError(f"{layout.blueprint} has {sorted(both)} both at start and as an empty slot")
        unsold = set(layout.empty_slots) & NEVER_SOLD_SYSTEMS
        if unsold:
            raise ValueError(
                f"{layout.blueprint} has an empty slot for {sorted(unsold)}, which no shop "
                "sells (rarity 0): the logic would assume an impossible purchase"
            )
    if set(LAYOUT_EMPTY_SLOTS) != {layout.blueprint for layout in LAYOUTS}:
        raise ValueError(
            "LAYOUT_EMPTY_SLOTS_RAW and the layout list do not match: "
            "regenerate the block from ftl.dat."
        )
    if set(LAYOUT_SYSTEMS) != {layout.blueprint for layout in LAYOUTS}:
        raise ValueError(
            "LAYOUT_SYSTEMS_RAW and the layout list do not match: "
            "regenerate the block from ftl.dat."
        )

    for slot, ship_blueprint, achievement, _ in SHIP_ACHIEVEMENTS_RAW:
        if slot >= MAX_ACHIEVEMENTS_PER_SHIP:
            raise ValueError(
                f"{achievement} occupies slot {slot} of {ship_blueprint}, beyond the "
                f"{MAX_ACHIEVEMENTS_PER_SHIP} reserved: widen LOCATION_OFFSET_SHIP_ACH."
            )

    for blueprint in ALWAYS_UNLOCKED_LAYOUTS:
        if blueprint not in LAYOUTS_BY_BLUEPRINT:
            raise ValueError(f"ALWAYS_UNLOCKED_LAYOUTS cites an unknown layout: {blueprint!r}")
    known_achievements = {loc.achievement for loc in LOCATIONS}
    for achievement in CROSS_RUN_ACHIEVEMENTS:
        if achievement not in known_achievements:
            raise ValueError(f"CROSS_RUN_ACHIEVEMENTS cites an unknown achievement: {achievement!r}")

    if ITEMS and LOCATIONS and max(item.code for item in ITEMS) >= LOCATION_ID_BASE:
        raise ValueError("the item id range overflows into the location id range")

    if LOCATIONS and max(loc.code for loc in LOCATIONS) >= 2 ** 31:
        raise ValueError("ids go past 2^31: 32-bit trackers will truncate them")

    if VICTORY_ITEM_NAME in ITEMS_BY_NAME:
        raise ValueError(f"{VICTORY_ITEM_NAME!r} must stay an event item, without a code")

    if FILLER_ITEM_NAME not in ITEMS_BY_NAME:
        raise ValueError(f"the default filler {FILLER_ITEM_NAME!r} does not exist")

    for item in ITEMS:
        if item.kind == KIND_FILLER and item.resource not in RESOURCES_IMPLEMENTED:
            raise ValueError(
                f"{item.name!r} uses resource {item.resource!r}, missing from "
                "RESOURCES_IMPLEMENTED: add it here AND in filler.lua."
            )
        if item.kind == KIND_TRAP and item.trap_effect not in TRAP_EFFECTS_IMPLEMENTED:
            raise ValueError(
                f"{item.name!r} uses effect {item.trap_effect!r}, missing from "
                "TRAP_EFFECTS_IMPLEMENTED: add it here AND in filler.lua."
            )

    for item in ITEMS:
        if item.kind != KIND_SHOP:
            continue
        shop_item = SHOP_ITEMS_BY_BLUEPRINT.get(item.blueprint or "")
        if shop_item is None:
            raise ValueError(f"{item.name!r} cites a blueprint missing from SHOP_ITEMS_RAW")
        if shop_item.rarity <= 0:
            raise ValueError(
                f"{item.name!r} has rarity zero: no shop will ever offer it, "
                "the item would have no visible effect."
            )


def _check_vanilla_totals() -> None:
    expected = {
        "ships": (len(SHIPS), 10),
        "layouts": (len(LAYOUTS), 28),
        "systems": (len(SYSTEMS), 16),
        "ship achievements": (len(SHIP_ACHIEVEMENTS_RAW), 30),
        "general achievements": (len(GENERAL_ACHIEVEMENTS_RAW), 21),
        "sellable items": (len(SHOP_ITEMS), 74),
        "locations": (len(LOCATIONS), 28 * SECTOR_COUNT + 28 + 30 + 21 + MAX_SHOP_SLOTS
                      + sum(system.max_level for system in SYSTEMS) + len(CREW_RACES)),
    }
    wrong = {label: pair for label, pair in expected.items() if pair[0] != pair[1]}
    if wrong:
        details = ", ".join(f"{label}: {got} instead of {want}"
                            for label, (got, want) in wrong.items())
        raise ValueError(
            f"the table no longer matches vanilla FTL ({details}). "
            "Regenerate the block from ftl.dat."
        )


_check()
_check_vanilla_totals()
