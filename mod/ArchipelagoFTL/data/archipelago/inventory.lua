local TAG = "[AP-inv] "

local function invLog(message)
    log(TAG .. message)
end

local AP_PROFILE = "empty"

local PROFILES = {
    empty = {
        ships = {},
        systemCaps = {},
        shipCaps = {},
        startingUpgrades = {},
        shopAvailability = {},
        crew = {},
        crewProgress = {},
    },

    start = {
        ships = { "PLAYER_SHIP_ROCK", "PLAYER_SHIP_MANTIS", "PLAYER_SHIP_CIRCLE" },
        systemCaps = {
            shields = 2, weapons = 2, engines = 2, sensors = 2, drones = 1,
            doors = 1, pilot = 1, medbay = 1, oxygen = 1, teleporter = 1,
        },
        startingUpgrades = { reactor = 1 },
        shopAvailability = {},
    },

    mid = {
        ships = {
            "PLAYER_SHIP_ROCK", "PLAYER_SHIP_ROCK_2",
            "PLAYER_SHIP_MANTIS", "PLAYER_SHIP_MANTIS_2",
            "PLAYER_SHIP_CIRCLE", "PLAYER_SHIP_CIRCLE_2",
            "PLAYER_SHIP_ENERGY", "PLAYER_SHIP_ENERGY_2",
            "PLAYER_SHIP_FED", "PLAYER_SHIP_JELLY",
            "PLAYER_SHIP_STEALTH", "PLAYER_SHIP_ANAEROBIC",
            "PLAYER_SHIP_CRYSTAL", "PLAYER_SHIP_HARD_2", "PLAYER_SHIP_HARD_3",
            "PLAYER_SHIP_ROCK_3",
        },
        systemCaps = {
            shields = 5, engines = 5, weapons = 4, drones = 4,
            artillery = 2, sensors = 2, teleporter = 2, medbay = 2, pilot = 2,
            clonebay = 2, hacking = 2, doors = 2, oxygen = 2, mind = 2,
            battery = 2, cloaking = 1,
        },
        startingUpgrades = {
            shields = 1, engines = 1, weapons = 1, drones = 1, medbay = 1, pilot = 1,
            doors = 1, oxygen = 1, sensors = 1, teleporter = 1, clonebay = 1,
            hacking = 1, mind = 1, battery = 1, cloaking = 1, artillery = 1,
            reactor = 4,
        },
        shopAvailability = {
            LASER_BURST_3 = 2,
            DEFENSE_1 = 1,
            ENERGY_SHIELD = 1,
        },
    },

    late = {
        ships = {
            "PLAYER_SHIP_ROCK", "PLAYER_SHIP_ROCK_2", "PLAYER_SHIP_ROCK_3",
            "PLAYER_SHIP_MANTIS", "PLAYER_SHIP_MANTIS_2", "PLAYER_SHIP_MANTIS_3",
            "PLAYER_SHIP_CIRCLE", "PLAYER_SHIP_CIRCLE_2", "PLAYER_SHIP_CIRCLE_3",
            "PLAYER_SHIP_ENERGY", "PLAYER_SHIP_ENERGY_2", "PLAYER_SHIP_ENERGY_3",
            "PLAYER_SHIP_FED", "PLAYER_SHIP_FED_2", "PLAYER_SHIP_FED_3",
            "PLAYER_SHIP_JELLY", "PLAYER_SHIP_JELLY_2", "PLAYER_SHIP_JELLY_3",
            "PLAYER_SHIP_STEALTH", "PLAYER_SHIP_STEALTH_2", "PLAYER_SHIP_STEALTH_3",
            "PLAYER_SHIP_ANAEROBIC", "PLAYER_SHIP_ANAEROBIC_2",
            "PLAYER_SHIP_CRYSTAL", "PLAYER_SHIP_CRYSTAL_2",
            "PLAYER_SHIP_HARD_2", "PLAYER_SHIP_HARD_3",
        },
        systemCaps = {
            shields = 8, engines = 8, weapons = 8, drones = 7,
            artillery = 4, doors = 3, pilot = 3, sensors = 3, teleporter = 3,
            oxygen = 3, medbay = 3, clonebay = 3, cloaking = 3, hacking = 3,
            mind = 3, battery = 2,
        },
        startingUpgrades = {
            shields = 1, engines = 1, weapons = 1, drones = 1, medbay = 1, pilot = 1,
            doors = 1, oxygen = 1, sensors = 1, teleporter = 1, clonebay = 1,
            hacking = 1, mind = 1, battery = 1, cloaking = 1, artillery = 1,
            reactor = 7,
        },
        shopAvailability = {
            LASER_BURST_3 = 4, LASER_BURST_5 = 3, BEAM_2 = 3,
            DEFENSE_1 = 3, COMBAT_1 = 2,
            ENERGY_SHIELD = 3, SHIELD_RECHARGE = 2,
        },
    },
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, inner in pairs(value) do
        copy[key] = deepCopy(inner)
    end
    return copy
end

-- The live inventory must not be the profile table itself, or clearing it would copy it onto itself.
local EMPTY = deepCopy(PROFILES.empty)
_G.apInventory = deepCopy(PROFILES[AP_PROFILE] or PROFILES.mid)

local pristine = deepCopy(_G.apInventory)

-- Complete once the server has sent every item again after a connection, with their names. Before that,
-- a ship missing from the inventory may only be on its way.
local synced = false

function apInventorySynced()
    return synced and not (_G.apFillerShipsWaiting and apFillerShipsWaiting())
end

function apInventoryMarkSynced()
    if not synced then
        synced = true
        invLog("inventory complete: every item received so far is in")
    end
end

function apInventoryClear()
    synced = false
    -- An empty inventory must get every item again: the server's next replay is not skipped.
    if _G.apNetForgetItems then pcall(_G.apNetForgetItems) end
    local reset = EMPTY
    for key in pairs(_G.apInventory) do
        _G.apInventory[key] = nil
    end
    for key, value in pairs(reset) do
        _G.apInventory[key] = deepCopy(value)
    end
    invLog("inventory reset to empty (starting a real run)")
end

function apInventoryResetForTesting()
    local fresh = deepCopy(pristine)
    for key in pairs(_G.apInventory) do
        if fresh[key] == nil then
            _G.apInventory[key] = nil
        end
    end
    for key, value in pairs(fresh) do
        local current = _G.apInventory[key]
        if type(current) == "table" and type(value) == "table" then
            for inner in pairs(current) do
                current[inner] = nil
            end
            for inner, innerValue in pairs(value) do
                current[inner] = innerValue
            end
        else
            _G.apInventory[key] = value
        end
    end
end

local function owned(blueprint)
    for _, known in ipairs(_G.apInventory.ships or {}) do
        if known == blueprint then
            return true
        end
    end
    return false
end

-- The Kestrel A, and the Multiverse Kestrel that replaces it there: FTL always has them unlocked.
local ALWAYS_THERE = { PLAYER_SHIP_HARD = true, PLAYER_SHIP_MVKESTREL = true }

local function hasKey(ship)
    return ALWAYS_THERE[ship] == true or ship == (_G.apSeedStartShip and apSeedStartShip()) or owned(ship)
end

-- Whether a run may count with this layout: "ok", "not_in_seed" or "not_received". FTL unlocks ships on its
-- own and cannot lock them again, so the hangar alone proves nothing. The start ship and the Kestrel A are
-- given by the seed even when the item is missing (solo does not hand out the starting items).
function apShipReceived(layout)
    if type(layout) ~= "string" or layout == "" then
        return "not_received"
    end
    if _G.apLayoutInSeed and not apLayoutInSeed(layout) then
        return "not_in_seed"
    end
    local ship = layout:gsub("_[23]$", "")
    if not hasKey(ship) then
        return "not_received"
    end
    if layout == ship or owned(layout) then
        return "ok"
    end
    if _G.apSeedHasLayoutItems and apSeedHasLayoutItems() then
        return "not_received"
    end
    return "ok"
end

function apApplyInventory()
    local applied, failed, waiting = 0, 0, 0

    local names = {}
    for _, shipName in ipairs(_G.apInventory.ships) do
        names[#names + 1] = shipName
    end
    for _, shipName in ipairs(_G.apEarnedLayoutsReady and apEarnedLayoutsReady() or {}) do
        names[#names + 1] = shipName
    end
    for _, shipName in ipairs(names) do
        local ship = shipName:gsub("_[23]$", "")
        -- A Type B or C waits for its ship's key: it is unlocked along with it.
        if ship ~= shipName and not hasKey(ship) then
            waiting = waiting + 1
        else
            local ok, err = apUnlockLayout(shipName, true)
            if ok then
                applied = applied + 1
            else
                failed = failed + 1
                invLog("failed to unlock " .. shipName .. ": " .. tostring(err))
            end
        end
    end

    invLog(string.format("profile \"%s\" applied: %d ship(s) unlocked%s%s",
        AP_PROFILE, applied, failed > 0 and (", " .. failed .. " failure(s)") or "",
        waiting > 0 and (", " .. waiting .. " layout(s) waiting for their ship's key") or ""))
end

local function repairInventory()
    local missing = {}
    for _, section in ipairs({ "ships", "systemCaps", "shipCaps", "startingUpgrades", "shopAvailability" }) do
        if type(_G.apInventory[section]) ~= "table" then
            _G.apInventory[section] = {}
            missing[#missing + 1] = section
        end
    end
    if #missing > 0 then
        invLog("MOD BUG: inventory missing " .. table.concat(missing, ", ")
            .. " - rebuilt so the received item is not lost")
    end
end

function apInventoryAdd(descriptor)
    if type(descriptor) ~= "table" then
        return false
    end
    if type(_G.apInventory) ~= "table" then
        invLog("MOD BUG: no inventory, item refused")
        return false
    end
    repairInventory()

    if descriptor.kind == "ship" then
        local blueprint = descriptor.bp
        if type(blueprint) ~= "string" or blueprint == "" then
            invLog("ship item without a blueprint, ignored")
            return false
        end
        for _, known in ipairs(_G.apInventory.ships) do
            if known == blueprint then
                invLog("ship already unlocked, nothing to do: " .. blueprint)
                return true
            end
        end
        _G.apInventory.ships[#_G.apInventory.ships + 1] = blueprint
        invLog("ship added to inventory: " .. blueprint)
        apTry(TAG, apApplyInventory)
        return true
    end

    if descriptor.kind == "cap" then
        local system = descriptor.sys
        if type(system) ~= "string" or system == "" then
            invLog("cap item without a system, ignored")
            return false
        end
        if type(descriptor.ship) == "string" then
            local caps = _G.apInventory.shipCaps
            caps[descriptor.ship] = caps[descriptor.ship] or {}
            caps[descriptor.ship][system] = (caps[descriptor.ship][system] or 0) + (descriptor.n or 1)
            invLog(string.format("%s cap raised by %d on %s", system, caps[descriptor.ship][system],
                descriptor.ship))
        else
            local caps = _G.apInventory.systemCaps
            caps[system] = (caps[system] or 1) + (descriptor.n or 1)
            invLog(string.format("%s cap raised to %d", system, caps[system]))
        end
        if _G.apApplySystemRules then
            apTry(TAG, _G.apApplySystemRules)
        end
        return true
    end

    if descriptor.kind == "start" then
        local system = descriptor.sys
        if type(system) ~= "string" or system == "" then
            invLog("starting bonus without a system, ignored")
            return false
        end
        local starts = _G.apInventory.startingUpgrades
        starts[system] = (starts[system] or 0) + (descriptor.n or 1)
        invLog(string.format("starting bonus: %s to %d (next run)", system, starts[system]))
        return true
    end

    return false
end

local appliedOnce = false

script.on_internal_event(Defines.InternalEvents.MAIN_MENU, function()
    apApplyInventory()
    if not appliedOnce then
        appliedOnce = true
        if _G.apUnlockStatus then
            _G.apUnlockStatus()
        end
    end
end)
