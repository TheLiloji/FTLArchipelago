local TAG = "[AP-sys] "

local function sysLog(message)
    log(TAG .. message)
end

local originalMaxLevel = {}

local startingSystems = {}

local purchaseGuardArmed = false

local function systemName(system)
    local name = Hyperspace.ShipSystem.SystemIdToName(system.iSystemType)
    if name == nil or name == "" then
        return nil
    end
    return name
end

local NO_CAP = 99

-- Upgrades received for one ship only count aboard that ship, whatever its layout.
local function shipBonus(inventory, name)
    local ok, blueprint = pcall(function() return Hyperspace.ships.player.myBlueprint.blueprintName end)
    if not ok or blueprint == nil then
        return 0
    end
    local ship = tostring(blueprint):gsub("_[23]$", "")
    return ((inventory.shipCaps or {})[ship] or {})[name] or 0
end

local function allowedCap(name)
    if _G.apSystemCapsActive and not _G.apSystemCapsActive() then
        return NO_CAP
    end
    local inventory = _G.apInventory
    if inventory == nil or inventory.systemCaps == nil then
        return 1
    end
    return (inventory.systemCaps[name] or 1) + shipBonus(inventory, name)
end

local function startingLevel(name)
    local inventory = _G.apInventory
    if inventory == nil or inventory.startingUpgrades == nil then
        return 0
    end
    return inventory.startingUpgrades[name] or 0
end

-- The Head Starts this run began with, kept in its save: one received during the run only comes with the next
-- run, so it must not raise the cap now (an event would sell the level). A run from before this record keeps
-- counting the inventory's.
local function runStartingLevel(name)
    local ok, value = pcall(function()
        local variables = Hyperspace.playerVariables
        if math.floor(tonumber(variables.ap_bonus_set) or 0) ~= 1 then
            return nil
        end
        return math.floor(tonumber(variables["ap_bonus_" .. name]) or 0)
    end)
    if ok and value ~= nil then
        return value
    end
    return startingLevel(name)
end

local function recordRunStartingLevels(names)
    pcall(function()
        local variables = Hyperspace.playerVariables
        for _, name in ipairs(names) do
            variables["ap_bonus_" .. name] = startingLevel(name)
        end
        variables.ap_bonus_set = 1
    end)
end

local function forgetRunStartingLevels()
    pcall(function() Hyperspace.playerVariables.ap_bonus_set = 0 end)
end

_G.apSystemCap = allowedCap

function apShipCapBonus(name)
    return shipBonus(_G.apInventory or {}, name)
end

local capWarned = {}

local startingPower = {}
local fromSave = false

-- The level a system had when the run began is kept in the run's save: after Continue, the current level
-- already includes what was bought, and counting it as the start would raise the cap at every reload.
local function recordedStart(name)
    local ok, value = pcall(function() return Hyperspace.playerVariables["ap_start_" .. name] end)
    if ok and type(value) == "number" and value > 0 then
        return value
    end
    return nil
end

local function recordStart(name, level)
    pcall(function() Hyperspace.playerVariables["ap_start_" .. name] = level end)
end

local function inRun()
    local ok, running = pcall(function()
        local app = Hyperspace.App
        return app.world.bStartedGame == true and app.menu.shipBuilder.bOpen ~= true
    end)
    return ok and running
end

-- With Free Upgrades, a level Archipelago gave is installed at once, no store needed.
local function freeUpgrades()
    return _G.apSeedOption ~= nil and (apSeedOption("free_upgrades") or 0) ~= 0
        and not (_G.apSystemCapsActive and not _G.apSystemCapsActive())
end

local function installFreeLevels(system, name, cap)
    local before = system.powerState.second
    while system.powerState.second < cap do
        if not system:UpgradeSystem(1) then
            break
        end
    end
    local gained = system.powerState.second - before
    if gained > 0 then
        sysLog(string.format("%s: %d free level(s) installed, now %d", name, gained, system.powerState.second))
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("system.free_levels", { name = apSystemLabel(name), level = system.powerState.second }))
        end
    end
end

-- System Install: a system whose blueprint came in is put aboard for free, when the hull has a place for it.
local SUBSYSTEMS = { pilot = true, sensors = true, doors = true, battery = true }
local INSTALL_ORDER = { "shields", "engines", "oxygen", "weapons", "medbay", "pilot", "sensors", "doors",
                        "drones", "teleporter", "cloaking", "hacking", "mind", "battery", "clonebay", "artillery" }
local systemIds = nil

local function systemId(name)
    if systemIds == nil then
        systemIds = {}
        for id = 0, 20 do
            local ok, found = pcall(Hyperspace.ShipSystem.SystemIdToName, id)
            if ok and found ~= nil and found ~= "" then
                systemIds[found] = id
            end
        end
    end
    return systemIds[name]
end

-- Older inventories (test profiles, a seed loaded before this was kept) have no blueprint list: any item
-- for the system then counts, as before.
local function hasBlueprint(name)
    local inventory = _G.apInventory
    if inventory == nil or inventory.systemCaps == nil then
        return false
    end
    if inventory.blueprints == nil then
        return inventory.systemCaps[name] ~= nil
    end
    return inventory.blueprints[name] == true
end

-- What the dashboard and the home screen call unlocked: what a store may sell.
function apSystemUnlocked(name)
    if _G.apSystemBlueprintsActive and not _G.apSystemBlueprintsActive() then
        return true
    end
    return hasBlueprint(name)
end

local function installMode()
    local mode = _G.apSeedOption ~= nil and apSeedOption("system_install") or 0
    if _G.apSystemBlueprintsActive and not _G.apSystemBlueprintsActive() then
        return 0
    end
    return tonumber(mode) or 0
end

local function hullHasPlace(player, id)
    local ok, found = pcall(function()
        local info = player.myBlueprint.systemInfo[id]
        return info ~= nil and info.location:size() > 0
    end)
    return ok and found == true
end

-- What could come aboard for free: received blueprints the hull has a room for, not a Medbay/Clone Bay swap.
local function installCandidates(player, caps)
    local candidates = {}
    for _, name in ipairs(INSTALL_ORDER) do
        local id = systemId(name)
        if id ~= nil and caps[name] ~= nil and hasBlueprint(name) and not player:HasSystem(id)
            and hullHasPlace(player, id) then
            local replaces = (name == "medbay" and player:HasSystem(systemId("clonebay")))
                or (name == "clonebay" and player:HasSystem(systemId("medbay")))
            if not replaces then
                candidates[#candidates + 1] = name
            end
        end
    end
    return candidates
end

-- Free main system slots: the ship's limit (Hyperspace, 8 unless a ship says otherwise) minus what it powers.
local function freeMainSlots(player)
    local ok, free = pcall(function()
        local limit = Hyperspace.CustomShipSelect.GetInstance():GetDefinition(player.myBlueprint.blueprintName)
            .systemLimit
        local used = 0
        local systems = player.vSystemList
        for i = 0, systems:size() - 1 do
            if systems[i].bNeedsPower then
                used = used + 1
            end
        end
        return math.max(0, math.floor(limit) - used)
    end)
    return ok and free or nil
end

local function installOne(player, name, reason)
    local id = systemId(name)
    local fits = SUBSYSTEMS[name] and player:CanFitSubsystem(id) or player:CanFitSystem(id)
    if not fits then
        return false
    end
    player:AddSystem(id)
    if player:HasSystem(id) then
        sysLog(name .. ": installed for free (" .. reason .. ")")
        return true
    end
    return false
end

-- Main systems left for the player to choose in the start-of-run menu, when they do not all fit. Kept in the
-- run's save, so a Continue before choosing still offers them.
local function setChoice(name, on)
    pcall(function() Hyperspace.playerVariables["ap_choose_" .. name] = on and 1 or 0 end)
end

local function isChoice(name)
    local ok, value = pcall(function() return Hyperspace.playerVariables["ap_choose_" .. name] end)
    return ok and math.floor(tonumber(value) or 0) == 1
end

local function installReceivedSystems(reason)
    local player = Hyperspace.ships.player
    local caps = (_G.apInventory or {}).systemCaps
    if player == nil or caps == nil then
        return 0
    end
    local candidates = installCandidates(player, caps)
    local mains = 0
    for _, name in ipairs(candidates) do
        if not SUBSYSTEMS[name] then
            mains = mains + 1
        end
    end
    -- At the start of a run, more systems than free slots: the fixed order would decide, so the player does.
    local free = freeMainSlots(player)
    local starting = reason == "start of the run"
    local choose = starting and free ~= nil and mains > free and free > 0
    if starting then
        for _, name in ipairs(INSTALL_ORDER) do
            setChoice(name, false)
        end
    end
    local installed = {}
    for _, name in ipairs(candidates) do
        if choose and not SUBSYSTEMS[name] then
            setChoice(name, true)
        elseif installOne(player, name, reason) then
            installed[#installed + 1] = apSystemLabel(name)
        end
    end
    if choose then
        sysLog(mains .. " system(s) for " .. free .. " free slot(s): the player chooses in the menu")
    end
    if #installed > 0 and _G.apNotifyStatus then
        _G.apNotifyStatus(apT("system.installed_free", { list = table.concat(installed, ", ") }))
    end
    return #installed
end

-- Every base ship starts with Oxygen, but some Multiverse ships do not, though their hull has a room for it (Lanius,
-- Caretaker, the automated ones). Their crew may still need air: the start-of-run menu offers it for free, and the
-- player is free to leave it.
local function offerMissingOxygen()
    local player = Hyperspace.ships.player
    local id = systemId("oxygen")
    if player == nil or id == nil or player:HasSystem(id) or not hullHasPlace(player, id) then
        return false
    end
    setChoice("oxygen", true)
    sysLog("oxygen: the ship starts without it, offered in the start-of-run menu")
    return true
end

-- The start-of-run menu: the systems still to choose from, while a slot is free.
function apSystemInstallChoices()
    local player = Hyperspace.ships.player
    if player == nil then
        return {}
    end
    local free = freeMainSlots(player)
    if free ~= nil and free <= 0 then
        return {}
    end
    local left = {}
    for _, name in ipairs(INSTALL_ORDER) do
        local id = systemId(name)
        if isChoice(name) and id ~= nil and not player:HasSystem(id) then
            left[#left + 1] = name
        end
    end
    return left
end

function apSystemFreeSlots()
    local player = Hyperspace.ships.player
    return player ~= nil and (freeMainSlots(player) or 0) or 0
end

function apInstallChosenSystem(name)
    local player = Hyperspace.ships.player
    if player == nil then
        return false
    end
    for _, choice in ipairs(apSystemInstallChoices()) do
        if choice == name then
            local ok, installed = pcall(installOne, player, name, "chosen in the start-of-run menu")
            if ok and installed then
                -- Put aboard at level 1 like any start system, before its cap is applied.
                apApplySystemRules()
                return true
            end
            return false
        end
    end
    return false
end

function apInstallReceivedSystems(reason)
    if installMode() == 0 or not inRun() then
        return 0
    end
    local ok, count = pcall(installReceivedSystems, reason or "check")
    if not ok then
        sysLog("system install failed: " .. tostring(count))
        return 0
    end
    return count
end

local function applyCap(system)
    local name = systemName(system)
    if name == nil then
        return
    end

    local current = system.powerState.second
    if originalMaxLevel[name] == nil or originalMaxLevel[name] < 2 then
        local seen = system.maxLevel
        if seen < 2 then
            if not capWarned[name] then
                capWarned[name] = true
                sysLog(string.format(
                    "%s: game maximum unreadable (%d), AP cap %d not applied for now",
                    name, seen, allowedCap(name)))
            end
            return
        end
        originalMaxLevel[name] = seen
    end

    if startingPower[name] == nil then
        if fromSave then
            startingPower[name] = recordedStart(name) or 1
        else
            startingPower[name] = current
            recordStart(name, current)
        end
    end
    local base = startingPower[name] or 1

    local cap = allowedCap(name)
    if base > 1 then
        cap = cap + (base - 1)
    end

    cap = cap + runStartingLevel(name)

    if cap > originalMaxLevel[name] then
        cap = originalMaxLevel[name]
    end
    if current and cap < current then
        cap = current
    end

    if system.maxLevel ~= cap then
        sysLog(string.format("%s: game cap %d -> %d (original max %d, AP cap %d)",
            name, system.maxLevel, cap, originalMaxLevel[name], allowedCap(name)))
    end
    system.maxLevel = cap
    if freeUpgrades() and inRun() and current < cap then
        installFreeLevels(system, name, cap)
    end
end

function apApplySystemRules()
    local ok, err = pcall(function()
        local player = Hyperspace.ships.player
        if player == nil then
            return
        end
        local systems = player.vSystemList
        for i = 0, systems:size() - 1 do
            applyCap(systems[i])
        end
    end)
    if not ok then
        sysLog("failed to apply caps: " .. tostring(err))
    end
end

local function announceBonuses()
    local inventory = _G.apInventory
    if inventory == nil or inventory.startingUpgrades == nil then
        return
    end
    local pieces = {}
    for name, levels in pairs(inventory.startingUpgrades) do
        if (levels or 0) > 0 then
            local label = name
            if name == "reactor" then
                label = apT("system.reactor")
            elseif _G.apSystemLabel then
                label = _G.apSystemLabel(name)
            end
            pieces[#pieces + 1] = label .. " +" .. levels
        end
    end
    if #pieces == 0 then
        return
    end
    table.sort(pieces)
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT("start.summary", { list = table.concat(pieces, ", ") }))
    end
end

local function applyStartingUpgrades()
    local ok, err = pcall(function()
        local player = Hyperspace.ships.player
        if player == nil then
            return
        end

        local granted = 0
        local systems = player.vSystemList
        local names = {}
        for i = 0, systems:size() - 1 do
            names[#names + 1] = systemName(systems[i])
        end
        recordRunStartingLevels(names)
        apApplySystemRules()
        for i = 0, systems:size() - 1 do
            local system = systems[i]
            local name = systemName(system)
            if name then
                local bonus = startingLevel(name)
                local current = system.powerState.second
                local target = current + bonus
                while current < target and system.maxLevel > current do
                    if not system:UpgradeSystem(1) then
                        break
                    end
                    granted = granted + 1
                    current = system.powerState.second
                end
            end
        end

        local reactorBonus = startingLevel("reactor")
        if reactorBonus > 0 then
            local power = Hyperspace.PowerManager.GetPowerManager(0)
            if power ~= nil then
                power.currentPower.second = power.currentPower.second + reactorBonus
                sysLog("reactor: +" .. reactorBonus)
            end
        end

        if granted > 0 then
            sysLog("levels granted at start: " .. granted)
        end

        announceBonuses()
    end)
    if not ok then
        sysLog("failed to apply starting bonuses: " .. tostring(err))
    end
end

function apSystemsForgetStartingPower()
    startingPower = {}
end

function apSystemStatus()
    pcall(function()
        local player = Hyperspace.ships.player
        if player == nil then
            sysLog("no player ship")
            return
        end
        local systems = player.vSystemList
        sysLog("ship systems (level / cap):")
        for i = 0, systems:size() - 1 do
            local system = systems[i]
            local name = systemName(system) or "?"
            sysLog(string.format("  %-12s %d/%d  (AP cap %d, game max %s)",
                name, system.powerState.second, system.maxLevel,
                allowedCap(name), tostring(originalMaxLevel[name])))
        end
    end)
end

local function purchaseAllowed(name)
    if _G.apSystemBlueprintsActive and not _G.apSystemBlueprintsActive() then
        return true
    end
    return hasBlueprint(name)
end

local pendingRefusal = {}

-- An Archipelago beacon loads its store from a sub-event: the beacon's own event has no store, only its name.
function apAtAStore()
    local ok, hasStore = pcall(function()
        local loc = Hyperspace.App.world.starMap.currentLoc
        if loc == nil or loc.event == nil then
            return false
        end
        return loc.event.store == true or tostring(loc.event.eventName or ""):sub(1, 14) == "AP_STORE_EVENT"
    end)
    return ok and hasStore
end

local atAStore = apAtAStore

local lastScrap = nil
-- A store opened at this beacon by an event the location does not show (a choice, a Multiverse store button).
local storeSeenHere = false

-- Stores never sell these, every ship has them: removing one would break the ship.
local NEVER_SOLD = { pilot = true, oxygen = true, shields = true, engines = true, weapons = true }

local function disarm(reason)
    if purchaseGuardArmed then
        sysLog("anti-purchase guard off: " .. reason)
    end
    purchaseGuardArmed = false
    pendingRefusal = {}
end

local function recordScrap()
    local ok, value = pcall(function() return Hyperspace.ships.player.currentScrap end)
    lastScrap = ok and tonumber(value) or nil
end

-- What the cargo holds, by name: Drone Control comes with a free drone, which a refusal must take back.
local function cargoCounts()
    local counts = {}
    pcall(function()
        local hold = Hyperspace.App.gui.equipScreen:GetCargoHold()
        for i = 0, hold:size() - 1 do
            local name = tostring(hold[i])
            counts[name] = (counts[name] or 0) + 1
        end
    end)
    return counts
end

local lastCargo = {}

local function takeBackFreeDrone(player, refusal)
    local now = cargoCounts()
    for name, count in pairs(now) do
        for _ = 1, count - (refusal.cargoBefore[name] or 0) do
            player:RemoveItem(name, true)
            sysLog(name .. " that came with the refused " .. refusal.name .. " taken back")
        end
    end
end

-- The medbay and the clone bay exclude each other: buying one makes the game remove the other.
local EXCLUSIVE = { medbay = "clonebay", clonebay = "medbay" }
local exclusiveLevels = {}

local function recordExclusive()
    local player = Hyperspace.ships.player
    if player == nil then
        return
    end
    for name in pairs(EXCLUSIVE) do
        local level = nil
        pcall(function()
            local id = systemId(name)
            if id ~= nil and player:HasSystem(id) then
                local system = player:GetSystem(id)
                level = (system and system.powerState.second) or 1
            end
        end)
        exclusiveLevels[name] = level
    end
end

-- A refused purchase must not cost the system it replaced: put it back, at the level it had.
local function restoreReplaced(player, refusal)
    local partner = EXCLUSIVE[refusal.name]
    local level = partner and refusal.partnerLevel
    if level == nil then
        return
    end
    local id = systemId(partner)
    if id == nil or player:HasSystem(id) then
        return
    end
    -- It was aboard before the purchase: the guard must not refuse it as one more.
    startingSystems[partner] = true
    player:AddSystem(id)
    local system = player:GetSystem(id)
    while system ~= nil and system.powerState.second < level do
        if not system:UpgradeSystem(1) then
            break
        end
    end
    sysLog(string.format("%s put back at level %d after the refused %s", partner, level, refusal.name))
end

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SHIP_SYSTEM, function(system)
    apTry(TAG, function()
        local name = systemName(system)
        if name == nil then
            return
        end

        if purchaseGuardArmed and not inRun() then
            disarm("left the run")
        end

        if not purchaseGuardArmed then
            startingSystems[name] = true
            sysLog("starting system: " .. name .. " (AP cap " .. allowedCap(name) .. ")")
            return
        end

        local ownOk, isPlayer = pcall(function()
            return system._shipObj.iShipId == 0
        end)
        if not ownOk or not isPlayer then
            return
        end

        if startingSystems[name] or purchaseAllowed(name) or NEVER_SOLD[name] then
            sysLog("system added: " .. name .. " (cap applied next tick)")
            return
        end

        -- Away from a known store, the next tick decides: paid for, it was bought (Multiverse opens its store from
        -- a button or a nested event, the beacon does not always say it has one); free, an event gave it.
        local maybeGift = not (atAStore() or storeSeenHere)

        pendingRefusal[#pendingRefusal + 1] = {
            name = name,
            systemType = system.iSystemType,
            system = system,
            scrapBefore = lastScrap,
            maybeGift = maybeGift,
            cargoBefore = lastCargo,
            partnerLevel = EXCLUSIVE[name] and exclusiveLevels[EXCLUSIVE[name]],
        }
    end)
end)

local function processRefusals()
    if #pendingRefusal == 0 then
        return
    end
    local player = Hyperspace.ships.player
    local okNow, scrapNow = pcall(function() return tonumber(player.currentScrap) end)
    local kept = {}
    for _, refusal in ipairs(pendingRefusal) do
        local paid = okNow and scrapNow ~= nil and refusal.scrapBefore ~= nil and scrapNow < refusal.scrapBefore
        if refusal.maybeGift and not paid then
            startingSystems[refusal.name] = true
            sysLog("system GIVEN by an event, accepted: " .. refusal.name)
            if _G.apNotifyStatus then
                _G.apNotifyStatus(apT("system.from_event", { name = apSystemLabel(refusal.name) }))
            end
        else
            kept[#kept + 1] = refusal
        end
    end
    pendingRefusal = kept
    if #pendingRefusal == 0 then
        return
    end
    -- A purchase adds one system; several in the same tick means a whole ship is being built.
    if #pendingRefusal > 1 or not inRun() then
        for _, refusal in ipairs(pendingRefusal) do
            startingSystems[refusal.name] = true
        end
        disarm(#pendingRefusal .. " system(s) built at once, a new ship rather than a purchase")
        return
    end

    if player == nil then
        pendingRefusal = {}
        return
    end

    for _, refusal in ipairs(pendingRefusal) do
        local ok, refund = pcall(function()
            return math.floor(refusal.system.bpCost or 0)
        end)
        refund = (ok and refund) or 0
        if refusal.scrapBefore ~= nil then
            local okNow, now = pcall(function() return player.currentScrap end)
            local lost = okNow and math.floor(refusal.scrapBefore - (tonumber(now) or 0)) or 0
            if lost > 0 then
                refund = lost
            end
        end

        pcall(function()
            player:RemoveSystem(refusal.systemType)
        end)
        if refusal.name == "drones" then
            pcall(takeBackFreeDrone, player, refusal)
        end
        pcall(restoreReplaced, player, refusal)
        if refund > 0 then
            pcall(function()
                player:ModifyScrapCount(refund, false)
            end)
        end

        sysLog(string.format("PURCHASE REFUSED: %s removed, %d scrap refunded",
            refusal.name, refund))
        if _G.apNotifyStatus then
            if refund > 0 then
                _G.apNotifyStatus(apT("system.locked.refunded",
                    { name = apSystemLabel(refusal.name), refund = refund }))
            else
                _G.apNotifyStatus(apT("system.locked", { name = apSystemLabel(refusal.name) }))
            end
        end
    end
    pendingRefusal = {}
end

script.on_init(function(newGame)
    lastScrap = nil
    storeSeenHere = false
    capWarned = {}
    startingPower = {}
    startingSystems = {}
    purchaseGuardArmed = false
    -- A continued run's variables are loaded after on_init: its caps wait for the next tick.
    fromSave = newGame == false
    if not fromSave then
        forgetRunStartingLevels()
        apApplySystemRules()
        if installMode() > 0 then
            pcall(installReceivedSystems, "start of the run")
            -- A system put aboard starts at level 1: recorded now, before the Head Starts raise it, or they
            -- would count twice in its cap.
            apApplySystemRules()
        end
        pcall(offerMissingOxygen)
        applyStartingUpgrades()
        apApplySystemRules()
    end
end)

local capDivider = 0
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    processRefusals()
    recordScrap()
    if purchaseGuardArmed and atAStore() then
        lastCargo = cargoCounts()
    end
    recordExclusive()

    -- A continued run may reload at a store: its systems are all built by now, so the guard goes on at once
    -- instead of waiting for a jump that would let a purchase through.
    if fromSave and not purchaseGuardArmed and inRun() then
        purchaseGuardArmed = true
        sysLog("anti-purchase guard armed (continued run)")
        apApplySystemRules()
    end

    capDivider = (capDivider + 1) % 60
    if capDivider == 0 then
        if installMode() == 2 and purchaseGuardArmed then
            apInstallReceivedSystems("received")
        end
        apApplySystemRules()
    end
end)

-- An event selling a level ("Trade scrap for upgrades") would take the scrap and give nothing for a system
-- already at its Archipelago cap: the trade is cancelled before the game applies it, like a refused purchase.
local function cancelLockedUpgrade(event)
    local stuff = event and event.stuff
    if stuff == nil or (stuff.upgradeAmount or 0) <= 0 then
        return
    end
    local id = stuff.upgradeId
    -- 16 is "every system" and 17 the reactor: the cap is per system, those are left to the game.
    if id == nil or id < 0 or id >= 16 then
        return
    end
    local player = Hyperspace.ships.player
    if player == nil or not player:HasSystem(id) then
        return
    end
    local system = player:GetSystem(id)
    local name = Hyperspace.ShipSystem.SystemIdToName(id)
    if system == nil or name == nil or system.powerState.second < system.maxLevel then
        return
    end
    local cost = -math.min(0, math.floor(stuff.scrap or 0))
    stuff.upgradeAmount = 0
    if cost > 0 then
        stuff.scrap = 0
    end
    sysLog(string.format("event upgrade cancelled: %s already at level %d, %d scrap kept",
        name, system.powerState.second, cost))
    if _G.apNotifyStatus then
        if cost > 0 then
            _G.apNotifyStatus(apT("system.upgrade_locked.refunded",
                { name = apSystemLabel(name), level = system.powerState.second, refund = cost }))
        else
            _G.apNotifyStatus(apT("system.upgrade_locked",
                { name = apSystemLabel(name), level = system.powerState.second }))
        end
    end
end

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
    apTry(TAG, function() cancelLockedUpgrade(event) end)
    if event ~= nil and event.store == true then
        storeSeenHere = true
    end
end)

script.on_internal_event(Defines.InternalEvents.MAIN_MENU, function()
    disarm("main menu")
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager.iShipId == 0 then
        storeSeenHere = false
        recordScrap()
        if not purchaseGuardArmed then
            purchaseGuardArmed = true
            sysLog("anti-purchase guard armed")
        end
        apApplySystemRules()
    end
end)

sysLog("systems module loaded (console: LUA apSystemStatus())")
