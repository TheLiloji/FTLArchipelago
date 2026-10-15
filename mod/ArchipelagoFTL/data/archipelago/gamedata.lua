--[[
    ArchipelagoFTL - game data.

    GENERATED FILE by mod/gen_gamedata.py from ftl.dat. Do not hand-edit: any fix
    must go through the generator, or it will be lost next time it runs. These
    identifiers are the boundary with the game, a typo would only show up in game,
    long after the fact.
]]

local gamedata = {}

-- Number of playable layouts per ship (1 = A, 2 = A and B, 3 = A, B and C).
gamedata.ships = {
    { name = "PLAYER_SHIP_ANAEROBIC", layouts = 2 },
    { name = "PLAYER_SHIP_CIRCLE", layouts = 3 },
    { name = "PLAYER_SHIP_CRYSTAL", layouts = 2 },
    { name = "PLAYER_SHIP_ENERGY", layouts = 3 },
    { name = "PLAYER_SHIP_FED", layouts = 3 },
    { name = "PLAYER_SHIP_HARD", layouts = 3 },
    { name = "PLAYER_SHIP_JELLY", layouts = 3 },
    { name = "PLAYER_SHIP_MANTIS", layouts = 3 },
    { name = "PLAYER_SHIP_ROCK", layouts = 3 },
    { name = "PLAYER_SHIP_STEALTH", layouts = 3 },
}

-- The sixteen systems, with their max level in FTL. Used by the dashboard:
-- it also shows what is STILL locked, which gives the player a goal.
gamedata.systems = {
    { id = "artillery", maxLevel = 4 },
    { id = "battery", maxLevel = 2 },
    { id = "cloaking", maxLevel = 3 },
    { id = "clonebay", maxLevel = 3 },
    { id = "doors", maxLevel = 3 },
    { id = "drones", maxLevel = 8 },
    { id = "engines", maxLevel = 8 },
    { id = "hacking", maxLevel = 3 },
    { id = "medbay", maxLevel = 3 },
    { id = "mind", maxLevel = 3 },
    { id = "oxygen", maxLevel = 3 },
    { id = "pilot", maxLevel = 3 },
    { id = "sensors", maxLevel = 3 },
    { id = "shields", maxLevel = 8 },
    { id = "teleporter", maxLevel = 3 },
    { id = "weapons", maxLevel = 8 },
}

-- Blueprint name suffix per layout: A has none.
gamedata.variantSuffix = { [0] = "", [1] = "_2", [2] = "_3" }

-- General achievements (21), independent of ship.
gamedata.generalAchievements = {
    "ACH_BAD_DODGING",
    "ACH_BOARDING_DRONE",
    "ACH_BURNING",
    "ACH_INVADE_SHIP",
    "ACH_NO_BUYING",
    "ACH_NO_DEATH",
    "ACH_NO_DRONES",
    "ACH_NO_MISSILES",
    "ACH_NO_REPAIR",
    "ACH_NO_UPGRADES",
    "ACH_ONE_VOLLEY",
    "ACH_PACIFIST",
    "ACH_SCRAP",
    "ACH_SECTOR_5",
    "ACH_SECTOR_8",
    "ACH_SHIPS",
    "ACH_SLICE_DICE",
    "ACH_SUFFOCATE",
    "ACH_UNLOCK_ALL",
    "ACH_WIN_EASY",
    "ACH_WIN_NORMAL",
}

-- Ship achievements (30 across 10 ships).
gamedata.shipAchievements = {
    ["PLAYER_SHIP_ANAEROBIC"] = {
        "ACH_LANIUS_ADVANCED",
        "ACH_LANIUS_OXYGEN",
        "ACH_LANIUS_SCRAP",
    },
    ["PLAYER_SHIP_CIRCLE"] = {
        "ACH_IONED",
        "ACH_ONLY_DRONES",
        "ACH_ROBOTIC",
    },
    ["PLAYER_SHIP_CRYSTAL"] = {
        "ACH_CRYSTAL_CLASH",
        "ACH_CRYSTAL_LOCKDOWN",
        "ACH_CRYSTAL_SHARD",
    },
    ["PLAYER_SHIP_ENERGY"] = {
        "ACH_ENERGY_MANPOWER",
        "ACH_ENERGY_POWER",
        "ACH_ENERGY_SHIELDS",
    },
    ["PLAYER_SHIP_FED"] = {
        "ACH_FED_DIPLOMACY",
        "ACH_FED_PATIENCE",
        "ACH_FED_UPGRADE",
    },
    ["PLAYER_SHIP_HARD"] = {
        "ACH_FULL_ARSENAL",
        "ACH_TOUGH_SHIP",
        "ACH_UNITED_FEDERATION",
    },
    ["PLAYER_SHIP_JELLY"] = {
        "ACH_SLUG_BIO",
        "ACH_SLUG_NEBULA",
        "ACH_SLUG_VISION",
    },
    ["PLAYER_SHIP_MANTIS"] = {
        "ACH_MANTIS_CREW_DEAD",
        "ACH_MANTIS_SLAUGHTER",
        "ACH_MANTIS_SURVIVOR",
    },
    ["PLAYER_SHIP_ROCK"] = {
        "ACH_ROCK_CRYSTAL",
        "ACH_ROCK_FIRE",
        "ACH_ROCK_MISSILES",
    },
    ["PLAYER_SHIP_STEALTH"] = {
        "ACH_STEALTH_AVOID",
        "ACH_STEALTH_DESTROY",
        "ACH_STEALTH_TACTICAL",
    },
}

-- Each achievement's icon, as the game's achievement screen draws it.
gamedata.achievementImages = {
    ACH_BAD_DODGING = "achievements/18.png",
    ACH_BOARDING_DRONE = "achievements/15.png",
    ACH_BURNING = "achievements/16.png",
    ACH_CRYSTAL_CLASH = "achievements/crystal_cruiser_3.png",
    ACH_CRYSTAL_LOCKDOWN = "achievements/crystal_cruiser_2.png",
    ACH_CRYSTAL_SHARD = "achievements/crystal_cruiser_1.png",
    ACH_ENERGY_MANPOWER = "achievements/energy_cruiser_3.png",
    ACH_ENERGY_POWER = "achievements/energy_cruiser_2.png",
    ACH_ENERGY_SHIELDS = "achievements/energy_cruiser_1.png",
    ACH_FED_DIPLOMACY = "achievements/fed_cruiser_2.png",
    ACH_FED_PATIENCE = "achievements/fed_cruiser_1.png",
    ACH_FED_UPGRADE = "achievements/fed_cruiser_3.png",
    ACH_FULL_ARSENAL = "achievements/kestral_2.png",
    ACH_INVADE_SHIP = "achievements/19.png",
    ACH_IONED = "achievements/circle_cruiser_3.png",
    ACH_LANIUS_ADVANCED = "achievements/anaerobic_cruiser_1.png",
    ACH_LANIUS_OXYGEN = "achievements/anaerobic_cruiser_3.png",
    ACH_LANIUS_SCRAP = "achievements/anaerobic_cruiser_2.png",
    ACH_MANTIS_CREW_DEAD = "achievements/mantis_cruiser_1.png",
    ACH_MANTIS_SLAUGHTER = "achievements/mantis_cruiser_2.png",
    ACH_MANTIS_SURVIVOR = "achievements/mantis_cruiser_3.png",
    ACH_NO_BUYING = "achievements/12.png",
    ACH_NO_DEATH = "achievements/13.png",
    ACH_NO_DRONES = "achievements/11.png",
    ACH_NO_MISSILES = "achievements/10.png",
    ACH_NO_REPAIR = "achievements/9.png",
    ACH_NO_UPGRADES = "achievements/7.png",
    ACH_ONE_VOLLEY = "achievements/14.png",
    ACH_ONLY_DRONES = "achievements/circle_cruiser_2.png",
    ACH_PACIFIST = "achievements/8.png",
    ACH_ROBOTIC = "achievements/circle_cruiser_1.png",
    ACH_ROCK_CRYSTAL = "achievements/rock_cruiser_3.png",
    ACH_ROCK_FIRE = "achievements/rock_cruiser_1.png",
    ACH_ROCK_MISSILES = "achievements/rock_cruiser_2.png",
    ACH_SCRAP = "achievements/5.png",
    ACH_SECTOR_5 = "achievements/0.png",
    ACH_SECTOR_8 = "achievements/1.png",
    ACH_SHIPS = "achievements/6.png",
    ACH_SLICE_DICE = "achievements/20.png",
    ACH_SLUG_BIO = "achievements/jelly_cruiser_3.png",
    ACH_SLUG_NEBULA = "achievements/jelly_cruiser_2.png",
    ACH_SLUG_VISION = "achievements/jelly_cruiser_1.png",
    ACH_STEALTH_AVOID = "achievements/stealth_2.png",
    ACH_STEALTH_DESTROY = "achievements/stealth_1.png",
    ACH_STEALTH_TACTICAL = "achievements/stealth_3.png",
    ACH_SUFFOCATE = "achievements/17.png",
    ACH_TOUGH_SHIP = "achievements/kestral_3.png",
    ACH_UNITED_FEDERATION = "achievements/kestral_1.png",
    ACH_UNLOCK_ALL = "achievements/4.png",
    ACH_WIN_EASY = "achievements/2.png",
    ACH_WIN_NORMAL = "achievements/3.png",
}

-- Hyperspace Lua has neither require nor package: a mod's scripts only share
-- globals, and load order follows hyperspace.xml.
_G.apGameData = gamedata
