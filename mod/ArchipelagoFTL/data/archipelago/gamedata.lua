local gamedata = {}

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

gamedata.variantSuffix = { [0] = "", [1] = "_2", [2] = "_3" }

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

_G.apGameData = gamedata
