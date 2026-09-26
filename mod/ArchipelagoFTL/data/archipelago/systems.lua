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

local function allowedCap(name)
    if _G.apSystemCapsActive and not _G.apSystemCapsActive() then
        return NO_CAP
    end
    local inventory = _G.apInventory
    if inventory == nil or inventory.systemCaps == nil then
        return 1
    end
    return inventory.systemCaps[name] or 1
end

local function startingLevel(name)
    local inventory = _G.apInventory
    if inventory == nil or inventory.startingUpgrades == nil then
        return 0
    end
    return inventory.startingUpgrades[name] or 0
end

_G.apSystemCap = allowedCap

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

    cap = cap + startingLevel(name)

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
    local inventory = _G.apInventory
    if inventory == nil or inventory.systemCaps == nil then
        return false
    end
    return inventory.systemCaps[name] ~= nil
end

local pendingRefusal = {}

local function atAStore()
    local ok, hasStore = pcall(function()
        local loc = Hyperspace.App.world.starMap.currentLoc
        return loc ~= nil and loc.event ~= nil and loc.event.store == true
    end)
    return ok and hasStore
end

local lastScrap = nil

-- Stores never sell these, every ship has them: removing one would break the ship.
local NEVER_SOLD = { pilot = true, oxygen = true, shields = true, engines = true, weapons = true }

local function inRun()
    local ok, running = pcall(function()
        local app = Hyperspace.App
        return app.world.bStartedGame == true and app.menu.shipBuilder.bOpen ~= true
    end)
    return ok and running
end

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

        if not atAStore() then
            startingSystems[name] = true
            sysLog("system GIVEN by an event, accepted: " .. name)
            if _G.apNotifyStatus then
                _G.apNotifyStatus(apT("system.from_event", { name = apSystemLabel(name) }))
            end
            return
        end

        pendingRefusal[#pendingRefusal + 1] = {
            name = name,
            systemType = system.iSystemType,
            system = system,
            scrapBefore = lastScrap,
        }
    end)
end)

local function processRefusals()
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

    local player = Hyperspace.ships.player
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
    capWarned = {}
    startingPower = {}
    startingSystems = {}
    purchaseGuardArmed = false
    -- A continued run's variables are loaded after on_init: its caps wait for the next tick.
    fromSave = newGame == false
    if not fromSave then
        apApplySystemRules()
        applyStartingUpgrades()
        apApplySystemRules()
    end
end)

local capDivider = 0
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    processRefusals()
    recordScrap()

    -- A continued run may reload at a store: its systems are all built by now, so the guard goes on at once
    -- instead of waiting for a jump that would let a purchase through.
    if fromSave and not purchaseGuardArmed and inRun() then
        purchaseGuardArmed = true
        sysLog("anti-purchase guard armed (continued run)")
        apApplySystemRules()
    end

    capDivider = (capDivider + 1) % 60
    if capDivider == 0 then
        apApplySystemRules()
    end
end)

script.on_internal_event(Defines.InternalEvents.MAIN_MENU, function()
    disarm("main menu")
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager.iShipId == 0 then
        if not purchaseGuardArmed then
            purchaseGuardArmed = true
            sysLog("anti-purchase guard armed")
        end
        apApplySystemRules()
    end
end)

sysLog("systems module loaded (console: LUA apSystemStatus())")
