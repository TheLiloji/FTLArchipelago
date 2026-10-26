local TAG = "[AP-filler] "

local function fillerLog(message)
    log(TAG .. message)
end

local pending = {}

local RESOURCE_DELIVERY = {
    scrap = function(player, n)
        player:ModifyScrapCount(n, false)
        return "filler.scrap", { n = n }
    end,
    fuel = function(player, n)
        player.fuel_count = player.fuel_count + n
        return "filler.fuel", { n = n }
    end,
    missiles = function(player, n)
        player:ModifyMissileCount(n)
        return "filler.missiles", { n = n }
    end,
    drone_parts = function(player, n)
        player:ModifyDroneCount(n)
        return "filler.drone_parts", { n = n }
    end,
    hull = function(player, n)
        player:DamageHull(-n, true)
        return "filler.hull", { n = n }
    end,
    crew = function(player, n)
        local added = 0
        for _ = 1, n do
            if player:IsCrewFull() then
                fillerLog("crew full: " .. (n - added) .. " crew member(s) not delivered")
                break
            end
            local room = apRandomRoomId(player)
            if room == nil then
                break
            end
            player:AddCrewMemberFromString("", "human", false, room, false, math.random(0, 1) == 1)
            added = added + 1
        end
        if added == 0 then
            return nil
        end
        return "filler.crew", { n = added }
    end,
}

local TRAP_LIMITS = {
    hullFloor = 3,
    fuelFloor = 2,
    systemFloor = 1,
    pursuitCeiling = 6,
    boardingCrewFloor = 2,
    fightTrapCeiling = 2,
}

_G.apTrapLimits = TRAP_LIMITS

local TRAP_DELIVERY = {
    fire = function(player)
        local room = apRandomRoomId(player)
        if room == nil then
            return nil
        end
        player:StartFire(room)
        return "trap.fire", { room = room }
    end,
    breach = function(player)
        local damage = Hyperspace.Damage()
        damage.iDamage = 0
        damage.breachChance = 100
        damage.bFriendlyFire = true
        damage.ownerId = 0
        player:DamageArea(player:GetRandomRoomCenter(), damage, true)
        return "trap.breach"
    end,
    boarding = function(player)
        local alive = 0
        local crew = player.vCrewList
        for i = 0, crew:size() - 1 do
            local member = crew[i]
            if member ~= nil and member.iShipId == 0 and not member.bDead then
                alive = alive + 1
            end
        end
        if alive < TRAP_LIMITS.boardingCrewFloor then
            return nil
        end

        local room = apRandomRoomId(player)
        if room == nil then
            return nil
        end
        local ok = pcall(function()
            player:AddCrewMemberFromString("", "mantis", true, room, false, true)
        end)
        if not ok then
            return nil
        end
        return "trap.boarding", { room = room }
    end,
    fuel_leak = function(player)
        local available = player.fuel_count - TRAP_LIMITS.fuelFloor
        if available <= 0 then
            return nil
        end
        local lost = math.min(available, 5)
        player.fuel_count = player.fuel_count - lost
        return "trap.fuel_leak", { n = lost }
    end,
    system_damage = function(player)
        local candidates = {}
        local systems = player.vSystemList
        for i = 0, systems:size() - 1 do
            local system = systems[i]
            if system ~= nil and system.healthState.first > TRAP_LIMITS.systemFloor then
                candidates[#candidates + 1] = system
            end
        end
        if #candidates == 0 then
            return nil
        end
        local target = candidates[math.random(1, #candidates)]
        local amount = math.min(2, target.healthState.first - TRAP_LIMITS.systemFloor)
        target:AddDamage(amount)
        return "trap.system_damage",
            { system = _G.apSystemLabel and _G.apSystemLabel(target.name) or tostring(target.name),
              n = amount }
    end,
    hull_damage = function(player)
        local hull = player.ship.hullIntegrity
        local amount = math.min(2, hull.first - TRAP_LIMITS.hullFloor)
        if amount <= 0 then
            return nil
        end
        player:DamageHull(amount, true)
        return "trap.hull_damage", { n = amount }
    end,
    fleet_advance = function()
        local starMap = Hyperspace.App.world.starMap
        if _G.apTrapFleetPushes >= TRAP_LIMITS.pursuitCeiling then
            return nil
        end
        _G.apTrapFleetPushes = _G.apTrapFleetPushes + 1
        starMap:ModifyPursuit(1)
        return "trap.fleet_advance"
    end,
    -- Armed now, sprung at the next beacon with a hostile ship: an anti-ship battery joins that fight.
    asb = function()
        return apArmFightTrap("asb") and "trap.asb" or nil
    end,
    -- Same wait: the enemy of the next fight unleashes a Flagship power surge, its lasers or its drones.
    power_surge = function()
        return apArmFightTrap("power_surge") and "trap.power_surge" or nil
    end,
    -- Same wait: the next fight's beacon gets a hazard it did not have (nebula, ion storm, asteroids, sun, pulsar).
    hazard = function()
        return apArmFightTrap("hazard") and "trap.hazard" or nil
    end,
}

-- Fight traps wait in the run's save, at most fightTrapCeiling of each kind.
local FIGHT_TRAPS = {
    { name = "asb", events = { "AP_TRAP_ASB" } },
    { name = "power_surge", events = { "AP_TRAP_SURGE_LASER", "AP_TRAP_SURGE_DRONES" },
      early = { "AP_TRAP_SURGE_LASER_LIGHT", "AP_TRAP_SURGE_DRONES_LIGHT" } },
    -- Its events depend on the beacon: a hazard it does not have yet.
    { name = "hazard" },
}

-- Sectors 1 and 2: a ship there cannot take a Flagship surge, it gets a lighter one.
local EARLY_SECTORS = 2

function apFightTrapArmed(name)
    local ok, value = pcall(function() return Hyperspace.playerVariables["ap_trap_" .. name] end)
    return ok and math.floor(tonumber(value) or 0) or 0
end

local function setFightTrapArmed(name, n)
    pcall(function() Hyperspace.playerVariables["ap_trap_" .. name] = n end)
end

function apArmFightTrap(name)
    local armed = apFightTrapArmed(name)
    if armed >= TRAP_LIMITS.fightTrapCeiling then
        return false
    end
    setFightTrapArmed(name, armed + 1)
    return true
end

function apTrapAsbArmed()
    return apFightTrapArmed("asb")
end

_G.apTrapFleetPushes = 0

local TRAP_TITLES = {
    fire = "trap.title.fire", breach = "trap.title.breach", fuel_leak = "trap.title.fuel_leak",
    system_damage = "trap.title.system_damage", fleet_advance = "trap.title.fleet_advance",
    hull_damage = "trap.title.hull_damage", boarding = "trap.title.boarding", asb = "trap.title.asb",
    power_surge = "trap.title.power_surge", hazard = "trap.title.hazard",
}

local TRAP_FALLBACK_ORDER = { "fire", "breach", "system_damage", "fuel_leak" }

local function springTrap(player, wanted)
    local order = { wanted }
    for _, name in ipairs(TRAP_FALLBACK_ORDER) do
        if name ~= wanted then
            order[#order + 1] = name
        end
    end
    for _, name in ipairs(order) do
        local effect = TRAP_DELIVERY[name]
        if effect ~= nil then
            local ok, key, params = pcall(effect, player)
            if ok and key ~= nil then
                if name ~= wanted then
                    fillerLog(string.format(
                        "trap %s impossible (floor reached), falling back to %s", wanted, name))
                end
                return key, params
            end
        end
    end
    return nil
end

function apRandomRoomId(shipManager)
    local rooms = shipManager.ship.vRoomList
    local count = rooms:size()
    if count == 0 then
        return nil
    end
    return math.floor(rooms[math.random(0, count - 1)].iRoomId)
end

local CONSUMABLE_KINDS = { filler = true, trap = true }
local RUN_START_RESOURCES = { scrap = true }

function apQueueItem(descriptor)
    if type(descriptor) ~= "table" or descriptor.kind == nil then
        fillerLog("invalid descriptor ignored")
        return false
    end
    -- Every scrap item of the seed counts toward Run Start Scrap, replayed or not: it is given once, but
    -- a share of it comes back at the start of every run.
    if descriptor.kind == "filler" and RUN_START_RESOURCES[descriptor.res] and type(_G.apInventory) == "table" then
        _G.apInventory.scrapReceived = (_G.apInventory.scrapReceived or 0) + (descriptor.n or 0)
    end
    if descriptor.isReplay and CONSUMABLE_KINDS[descriptor.kind] then
        fillerLog("already consumed in a previous session: "
            .. tostring(descriptor.res or descriptor.eff or descriptor.kind))
        return false
    end
    -- The server sends everything again after a reconnect: an item still waiting here is not queued twice.
    if descriptor.index ~= nil then
        for _, waiting in ipairs(pending) do
            if waiting.index == descriptor.index then
                return false
            end
        end
    end
    pending[#pending + 1] = descriptor
    fillerLog(string.format("queued: %s (%d in queue)",
        descriptor.res or descriptor.eff or descriptor.kind, #pending))
    return true
end

-- A ship key still in the queue is received but not in the inventory yet.
function apFillerShipsWaiting()
    for _, descriptor in ipairs(pending) do
        if descriptor.kind == "ship" then
            return true
        end
    end
    return false
end

local SHIPLESS_KINDS = { ship = true, cap = true, start = true, archive = true, pass = true }
local CATALOG_KINDS = { shop = true, crew = true }

local function noRunStarted()
    local ok, started = pcall(function() return Hyperspace.App.world.bStartedGame == true end)
    return ok and not started
end

local function safeToDeliver()
    local ok, safe = pcall(function()
        local world = Hyperspace.App.world
        if not world.bStartedGame then
            return false
        end
        local player = Hyperspace.ships.player
        if player == nil or player.bDestroyed then
            return false
        end
        -- A ship that is not hostile (a guard, a trader, a quest giver) is not a fight.
        local enemy = Hyperspace.ships.enemy
        return enemy == nil or enemy._targetable.hostile == false
    end)
    return ok and safe
end

local function markProcessed(descriptor)
    if descriptor.index ~= nil and _G.apNetItemDelivered then
        _G.apNetItemDelivered(descriptor.index)
    end
end

local function deliverOne(descriptor)
    local player = Hyperspace.ships.player
    local amount = descriptor.n or 1

    if descriptor.kind == "filler" then
        local deliver = RESOURCE_DELIVERY[descriptor.res]
        if deliver == nil then
            fillerLog("unknown resource: " .. tostring(descriptor.res))
            return false
        end
        local key, params = deliver(player, amount)
        if key == nil then
            fillerLog("delivery deferred: " .. tostring(descriptor.res))
            return false, "retry"
        end
        fillerLog("delivered: " .. key)
        if _G.apNotifyItem then
            _G.apNotifyItem(descriptor.display or apT(key, params), descriptor.sender,
                descriptor.sender == nil and not _G.apSoloEnabled)
        end
        return true
    end

    -- sector_locks: one more pass for this layout, kept for this run and the next ones.
    if descriptor.kind == "pass" then
        local inventory = _G.apInventory
        if inventory == nil or descriptor.bp == nil then
            return false
        end
        inventory.passes = inventory.passes or {}
        -- The same item sent again (a reconnection) is the same pass, not a second one.
        inventory.passIndices = inventory.passIndices or {}
        if descriptor.index ~= nil and inventory.passIndices[descriptor.index] then
            return true
        end
        if descriptor.index ~= nil then
            inventory.passIndices[descriptor.index] = true
        end
        inventory.passes[descriptor.bp] = (inventory.passes[descriptor.bp] or 0) + 1
        fillerLog("sector pass: " .. descriptor.bp .. " x" .. inventory.passes[descriptor.bp])
        if _G.apNotifyItem and not descriptor.isReplay then
            _G.apNotifyItem(descriptor.display or apT("gift.something"), descriptor.sender,
                descriptor.sender == nil and not _G.apSoloEnabled)
        end
        return true
    end

    if descriptor.kind == "archive" then
        local inventory = _G.apInventory
        if inventory == nil then
            return false
        end
        inventory.archives = (inventory.archives or 0) + (descriptor.n or 1)
        fillerLog("archive: " .. inventory.archives)
        if _G.apNotifyStatus and not descriptor.isReplay then
            local total = _G.apGoalArchives and _G.apGoalArchives() or nil
            local key = "archive.received.alone"
            if total ~= nil then
                key = inventory.archives > total and "archive.received.extra" or "archive.received"
            end
            _G.apNotifyStatus(apT(key, { done = inventory.archives, total = total or 0 }))
        end
        if _G.apDeclareGoal then
            apTry(TAG, _G.apDeclareGoal)
        end
        return true
    end

    if descriptor.kind == "ship" or descriptor.kind == "cap" or descriptor.kind == "start" then
        if _G.apInventoryAdd == nil then
            fillerLog("inventory.lua missing: inventory item ignored")
            return false
        end
        if not _G.apInventoryAdd(descriptor) then
            return false
        end
        if _G.apNotifyItem and not descriptor.isReplay then
            local name = descriptor.display
            -- A Head Start's item name is English: the game's own name of the system reads in every language.
            if descriptor.kind == "start" and descriptor.sys ~= nil and descriptor.sys ~= "reactor"
                and _G.apSystemLabel then
                name = apSystemLabel(descriptor.sys)
            end
            if name == nil and descriptor.bp ~= nil then
                name = _G.apShipLabel and _G.apShipLabel(descriptor.bp) or descriptor.bp
            end
            if name == nil and descriptor.sys ~= nil then
                name = _G.apSystemLabel and _G.apSystemLabel(descriptor.sys) or descriptor.sys
            end
            if name ~= nil and _G.apHumaniseId and name:find("%u[%u%d]*_[%u%d_]+") then
                name = _G.apHumaniseId(name)
            end
            if descriptor.kind == "start" and _G.apNotifyStatus then
                _G.apNotifyStatus(apT("start.received", { item = tostring(name) }))
            else
                _G.apNotifyItem(name, descriptor.sender, descriptor.sender == nil and not _G.apSoloEnabled)
            end
        end
        return true
    end

    if descriptor.kind == "weapon" or descriptor.kind == "drone" or descriptor.kind == "augment" then
        if _G.apDeliverEquipment == nil then
            fillerLog("equipment.lua missing: equipment item ignored")
            return false
        end
        return _G.apDeliverEquipment(descriptor)
    end

    if descriptor.kind == "crew" and tonumber(descriptor.tiers) ~= nil then
        local inventory = _G.apInventory
        if inventory == nil or type(descriptor.race) ~= "string" then
            return false
        end
        inventory.crewProgress = inventory.crewProgress or {}
        local progress = inventory.crewProgress[descriptor.race] or { n = 0 }
        progress.n = progress.n + 1
        progress.skill = descriptor.skill
        inventory.crewProgress[descriptor.race] = progress
        local name = _G.apRaceLabel and _G.apRaceLabel(descriptor.race) or descriptor.race
        fillerLog("progressive crew member " .. descriptor.race .. ": tier " .. progress.n)
        if descriptor.isReplay then
            return true
        end
        local key = progress.n >= 3 and "crew.progress.expert"
            or progress.n == 2 and "crew.progress.menu" or "crew.progress.later"
        if progress.n == 1 and not descriptor.noDelivery and _G.apRecruitCrew then
            local aboard = _G.apRecruitCrew(descriptor.race, nil)
            if aboard then key = "crew.progress.aboard" end
        end
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT(key, { name = tostring(name) }))
        end
        return true
    end

    if descriptor.kind == "crew" then
        local inventory = _G.apInventory
        if inventory == nil or type(descriptor.race) ~= "string" then
            return false
        end
        inventory.crew = inventory.crew or {}
        inventory.crew[#inventory.crew + 1] = {
            race = descriptor.race, skill = descriptor.skill, display = descriptor.display,
        }
        if descriptor.isReplay or descriptor.noDelivery or not _G.apRecruitCrew then
            if descriptor.noDelivery and not descriptor.isReplay and _G.apNotifyStatus then
                _G.apNotifyStatus(apT("crew.received.menu",
                    { name = tostring(descriptor.display or descriptor.race) }))
            end
            return true
        end
        local aboard, reason = _G.apRecruitCrew(descriptor.race, descriptor.skill)
        fillerLog("crew member " .. tostring(descriptor.display or descriptor.race)
            .. (aboard and " aboard" or (" catalog only: " .. tostring(reason))))
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT(aboard and "crew.received.aboard" or "crew.received.menu",
                { name = tostring(descriptor.display or descriptor.race) }))
        end
        return true
    end

    if descriptor.kind == "shop" then
        if _G.apApplyShopItem == nil then
            fillerLog("shop.lua missing: shop item ignored")
            return false
        end
        return _G.apApplyShopItem(descriptor)
    end

    if descriptor.kind == "trap" then
        if TRAP_DELIVERY[descriptor.eff] == nil then
            fillerLog("unknown trap: " .. tostring(descriptor.eff))
            if _G.apNotifyStatus then
                _G.apNotifyStatus(apT("item.unknown",
                    { name = descriptor.display or tostring(descriptor.eff) }))
            end
            return false
        end
        local key, params = springTrap(player, descriptor.eff)
        if key == nil then
            fillerLog("trap fizzled: all floors already reached")
            if _G.apNotifyTrap then
                _G.apNotifyTrap(apT("trap.fizzled"))
            end
            return true
        end
        fillerLog("trap triggered: " .. key)
        if _G.apNotifyTrap then
            local effect = apT(key, params)
            -- Our own traps are named in the player's language; one from Trap Link keeps its game's name.
            local title = descriptor.display
            if not descriptor.fromLink and TRAP_TITLES[descriptor.eff] then
                title = apT(TRAP_TITLES[descriptor.eff])
            end
            if title ~= nil and title ~= "" then
                _G.apNotifyTrap(apT("trap.named", { name = title, effect = effect }))
            else
                _G.apNotifyTrap(effect)
            end
        end
        if _G.apTrapLinkOnTrap then
            apTry(TAG, _G.apTrapLinkOnTrap, descriptor)
        end
        return true
    end

    return false
end

-- Whether a delivery pass can hand things out now (in a run that counts, no fight).
function apFillerCanDeliver()
    return safeToDeliver() and apFillerRunCounts()
end

-- Weapons and drones still waiting, for the "wait for the next jump" line.
function apFillerEquipmentWaiting()
    local count = 0
    for _, descriptor in ipairs(pending) do
        local family = descriptor.kind
        if family == "shop" and descriptor.bp and _G.apBlueprintFamily then
            family = apBlueprintFamily(descriptor.bp)
        end
        if family == "weapon" or family == "drone" then
            count = count + 1
        end
    end
    return count
end

-- A run started without this seed does not count: what it would use up waits for a run that does.
local function runCounts()
    local contract = _G.apContractState
    if _G.apRunMatchesSeed == nil or noRunStarted() or contract == nil or contract.connected ~= true then
        return true
    end
    return apRunMatchesSeed()
end

function apFillerRunCounts()
    return runCounts()
end

function apDeliverPending()
    if #pending == 0 then
        return
    end
    local counts = runCounts()
    local inRun = safeToDeliver() and counts
    if not inRun and counts and not noRunStarted() and _G.apShopKeepOwed then
        for _, descriptor in ipairs(pending) do
            if descriptor.kind == "shop" and not descriptor.isReplay and not descriptor.keptOwed then
                descriptor.keptOwed = true
                apShopKeepOwed(descriptor.bp)
            end
        end
    end
    local deliverable = function(descriptor)
        if inRun or SHIPLESS_KINDS[descriptor.kind] == true then
            return true
        end
        if CATALOG_KINDS[descriptor.kind] and (noRunStarted() or not counts) then
            descriptor.noDelivery = true
            return true
        end
        return false
    end
    -- Runs every tick while something is queued: leave early when nothing can be delivered yet.
    if not inRun then
        local none = true
        for _, descriptor in ipairs(pending) do
            if deliverable(descriptor) then none = false break end
        end
        if none then
            return
        end
    end

    local delivered = 0
    local deferred = {}
    local index = 1
    while index <= #pending do
        local descriptor = pending[index]
        if not deliverable(descriptor) then
            index = index + 1
        else
            table.remove(pending, index)
            local ok, result, reason = pcall(deliverOne, descriptor)
            if ok and result then
                delivered = delivered + 1
                markProcessed(descriptor)
            elseif ok and reason == "retry" then
                deferred[#deferred + 1] = descriptor
            elseif ok then
                fillerLog("permanently dropped (" .. tostring(descriptor.kind) .. "): "
                    .. tostring(descriptor.display or descriptor.bp or descriptor.res or "?"))
                markProcessed(descriptor)
            else
                descriptor.attempts = (descriptor.attempts or 0) + 1
                fillerLog(string.format("delivery failed (%s%s, attempt %d): %s",
                    tostring(descriptor.kind),
                    descriptor.bp and (" " .. tostring(descriptor.bp)) or "",
                    descriptor.attempts, tostring(result)))
                if descriptor.attempts < 3 then
                    deferred[#deferred + 1] = descriptor
                else
                    markProcessed(descriptor)
                    if _G.apNotifyStatus then
                        _G.apNotifyStatus(apT("item.failed",
                            { name = descriptor.display or tostring(descriptor.kind) }))
                    end
                end
            end
        end
        inRun = safeToDeliver() and counts
    end
    for _, descriptor in ipairs(deferred) do
        pending[#pending + 1] = descriptor
    end

    if delivered > 0 then
        fillerLog(delivered .. " item(s) delivered, " .. #pending .. " pending")
    end
end

function apRunStartScrap()
    local percent = tonumber(_G.apSeedOption and apSeedOption("run_start_scrap") or 0) or 0
    local received = tonumber((_G.apInventory or {}).scrapReceived or 0) or 0
    return math.floor(received * percent / 100)
end

-- Given once the run is under way, not in on_init: the ship may not exist yet, the start events (Multiverse's)
-- come first, and the items of the seed may not all be in. The run's save says it is still owed.
local function giveRunStartScrap()
    if math.floor(tonumber(Hyperspace.playerVariables.ap_run_scrap_owed) or 0) ~= 1 then
        return
    end
    if not (_G.apInventorySynced and apInventorySynced()) then
        return
    end
    if Hyperspace.ships.player == nil or noRunStarted() then
        return
    end
    Hyperspace.playerVariables.ap_run_scrap_owed = 0
    local amount = apRunStartScrap()
    if amount <= 0 then
        return
    end
    Hyperspace.ships.player:ModifyScrapCount(amount, false)
    fillerLog("run start scrap: +" .. amount)
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT("filler.run_start_scrap", { n = amount }))
    end
end

script.on_init(function(newGame)
    if newGame then
        pcall(function() Hyperspace.playerVariables.ap_run_scrap_owed = 1 end)
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    apTry(TAG, giveRunStartScrap)
end)

function apFillerForgetSeed()
    local remaining = #pending
    pending = {}
    if remaining > 0 then
        fillerLog("new seed: " .. remaining .. " queued item(s) dropped")
    end
end

function apFillerResetForTesting()
    pending = {}
end

function apFillerPendingForTesting()
    return pending
end

function apFillerStatus()
    fillerLog(#pending .. " item(s) waiting to be delivered")
    for index, descriptor in ipairs(pending) do
        fillerLog(string.format("  %d. %s %s x%d", index, descriptor.kind,
            descriptor.res or descriptor.eff or "?", descriptor.n or 1))
    end
end

_G.apSupportedKinds = {
    ship = true, cap = true, start = true, filler = true, trap = true,
    weapon = true, drone = true, augment = true, shop = true, archive = true, crew = true, bundle = true,
    layout = true, progressive_ship = true, pass = true,
}

_G.apSupportedResources = {}
for name in pairs(RESOURCE_DELIVERY) do
    _G.apSupportedResources[name] = true
end

_G.apSupportedTrapEffects = {}
for name in pairs(TRAP_DELIVERY) do
    _G.apSupportedTrapEffects[name] = true
end

script.on_init(function()
    _G.apTrapFleetPushes = 0
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager.iShipId == 0 then
        apDeliverPending()
    end
end)

-- A fight trap comes as an event once the fight is on and no other event is open, one per fight. The Last Stand
-- keeps it for later, and so does a beacon that already has what the trap would bring.
local sprungHere = false
-- An anti-ship battery or a hazard brought by a trap goes away with the fight. Switching it off clears every
-- hazard, so the beacon's own ones (asteroids, sun, pulsar, ion storm) are put back right after.
local cleanupHere = nil

local RESTORE_EVENTS = {
    asteroid = "AP_TRAP_RESTORE_ASTEROID", sun = "AP_TRAP_RESTORE_SUN",
    pulsar = "AP_TRAP_RESTORE_PULSAR", storm = "AP_TRAP_RESTORE_STORM",
}
local HAZARD_EVENTS = {
    nebula = "AP_TRAP_HAZARD_NEBULA", storm = "AP_TRAP_HAZARD_STORM", asteroid = "AP_TRAP_HAZARD_ASTEROID",
    sun = "AP_TRAP_HAZARD_SUN", pulsar = "AP_TRAP_HAZARD_PULSAR",
}

-- What the beacon has on its own, before any trap.
local function beaconHazards()
    local hazards = {}
    pcall(function()
        local space = Hyperspace.App.world.space
        hazards.pds = space.bPDS == true or nil
        hazards.nebula = space.bNebula == true or nil
        hazards.storm = space.bStorm == true or nil
        hazards.asteroid = space.asteroidGenerator.bRunning == true or nil
        hazards.sun = space.sunLevel == true or nil
        hazards.pulsar = space.pulsarLevel == true or nil
    end)
    return hazards
end

local function trapEvents(trap, hazards)
    if trap.name == "asb" then
        return not hazards.pds and trap.events or {}
    end
    if trap.name == "hazard" then
        local events = {}
        for _, hazard in ipairs({ "nebula", "storm", "asteroid", "sun", "pulsar" }) do
            if not hazards[hazard] then
                events[#events + 1] = HAZARD_EVENTS[hazard]
            end
        end
        return events
    end
    local ok, level = pcall(function() return Hyperspace.App.world.starMap.worldLevel end)
    if trap.early and ok and tonumber(level) and level + 1 <= EARLY_SECTORS then
        return trap.early
    end
    return trap.events
end

local function springFightTrap()
    if sprungHere then
        return
    end
    local ready = false
    pcall(function()
        local app = Hyperspace.App
        local gui = app.gui
        local enemy = Hyperspace.ships.enemy
        ready = app.world.bStartedGame and not (gui.choiceBoxOpen or gui.event_pause or gui.menu_pause)
            and enemy ~= nil and not enemy.bDestroyed and enemy._targetable.hostile == true
            and not app.world.starMap.bossLevel
    end)
    if not ready then
        return
    end
    local hazards = beaconHazards()
    for _, trap in ipairs(FIGHT_TRAPS) do
        local armed = apFightTrapArmed(trap.name)
        local events = trapEvents(trap, hazards)
        if armed > 0 and #events > 0 then
            local event = events[math.random(1, #events)]
            local ok, err = pcall(function()
                Hyperspace.CustomEventsParser.GetInstance():LoadEvent(Hyperspace.App.world, event, false, -1)
            end)
            if not ok then
                fillerLog("fight trap " .. trap.name .. " not sprung: " .. tostring(err))
                return
            end
            setFightTrapArmed(trap.name, armed - 1)
            sprungHere = true
            if trap.name == "asb" or trap.name == "hazard" then
                cleanupHere = { trap = trap.name, hazards = hazards,
                                nebulaAdded = event == HAZARD_EVENTS.nebula
                                    or (event == HAZARD_EVENTS.storm and not hazards.nebula) }
            end
            fillerLog("fight trap sprung: " .. event)
            return
        end
    end
end

-- The enemy surrendered, fled or is beaten: what the trap brought goes, it was not part of the beacon.
local function fightOver()
    local enemy = Hyperspace.ships.enemy
    if enemy == nil or enemy.bDestroyed or enemy._targetable.hostile ~= true then
        return true
    end
    if enemy.ship.hullIntegrity.first <= 0 then
        return true
    end
    return not enemy.bAutomated and enemy:CountCrew(false) == 0
end

local function cleanUpTrap()
    if cleanupHere == nil then
        return
    end
    local ready = false
    pcall(function()
        local gui = Hyperspace.App.gui
        ready = not (gui.choiceBoxOpen or gui.event_pause or gui.menu_pause) and fightOver()
    end)
    if not ready then
        return
    end
    local cleanup = cleanupHere
    cleanupHere = nil
    local ending = "AP_TRAP_ASB_END"
    if cleanup.trap == "hazard" then
        ending = cleanup.nebulaAdded and "AP_TRAP_HAZARD_END_NEBULA" or "AP_TRAP_HAZARD_END"
    end
    local ok, err = pcall(function()
        local parser = Hyperspace.CustomEventsParser.GetInstance()
        parser:LoadEvent(Hyperspace.App.world, ending, false, -1)
        for _, hazard in ipairs({ "asteroid", "sun", "pulsar", "storm" }) do
            if cleanup.hazards[hazard] then
                parser:LoadEvent(Hyperspace.App.world, RESTORE_EVENTS[hazard], false, -1)
            end
        end
    end)
    fillerLog(ok and ("trap " .. cleanup.trap .. " cleared: the fight is over")
        or ("trap not cleared: " .. tostring(err)))
end

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager.iShipId == 0 then
        sprungHere = false
        cleanupHere = nil
    end
end)

script.on_init(function()
    sprungHere = false
    cleanupHere = nil
end)

local pollDivider = 0
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    pollDivider = (pollDivider + 1) % 120
    if pollDivider == 0 then
        apDeliverPending()
    end
    if pollDivider % 30 == 0 then
        apTry(TAG, springFightTrap)
        apTry(TAG, cleanUpTrap)
    end
end)

fillerLog("filler and traps module loaded (console: LUA apFillerStatus())")
