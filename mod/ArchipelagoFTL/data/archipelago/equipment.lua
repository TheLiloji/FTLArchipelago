local TAG = "[AP-equip] "

local function equipLog(message)
    log(TAG .. message)
end

function apBlueprintFamily(name)
    local blueprints = Hyperspace.Blueprints
    local getters = {
        weapon = "GetWeaponBlueprint",
        drone = "GetDroneBlueprint",
        augment = "GetAugmentBlueprint",
    }
    for family, getter in pairs(getters) do
        local ok, blueprint = pcall(function()
            return blueprints[getter](blueprints, name)
        end)
        if ok and blueprint ~= nil and tostring(blueprint.name) == name then
            return family
        end
    end
    return nil
end

-- With weapon slots and cargo full, FTL puts an item in the "over capacity" box, and Hyperspace keeps a list
-- of them. Going back to the main menu with a dozen there crashes the game. The box can't be read from Lua
-- (Hyperspace counts it as cargo), so at most a few weapons and drones arrive per beacon; the box empties at
-- each jump and the rest follow then.
local PER_BEACON = 4
local deliveredHere = 0

-- The box also empties at each jump, and what is in it is lost: with the slots and the cargo hold full, an
-- item waits for room instead.
local CARGO_SLOTS = 4
local CARGO_FULL = "weapon slots and cargo full"
local CARGO_KEPT = "last cargo slot kept free at a store"
-- Right at a jump the game still points at the beacon left behind, so whether the new one has a store is only
-- known from the next tick on.
local justArrived = false

-- A store sells an Archipelago package as a weapon, so buying one takes a cargo slot: there, the last free cargo
-- slot is kept for buying, and what would take it waits until the player leaves the store.
local function atAStore()
    return _G.apAtAStore ~= nil and apAtAStore()
end

-- nil when the item fits, else why it waits.
local function noRoom(family)
    local ok, why = pcall(function()
        local player = Hyperspace.ships.player
        local system = family == "weapon" and player.weaponSystem or player.droneSystem
        if system ~= nil then
            local held = family == "weapon" and system.weapons or system.drones
            if held:size() < system.slot_count then
                return nil
            end
        end
        local held = Hyperspace.App.gui.equipScreen:GetCargoHold():size()
        if held >= CARGO_SLOTS then
            return CARGO_FULL
        end
        if held == CARGO_SLOTS - 1 and (atAStore() or justArrived) then
            return CARGO_KEPT
        end
        return nil
    end)
    return ok and why or nil
end

local function deliverEquipped(name, family, chosen)
    local equipment = Hyperspace.App.gui.equipScreen
    if equipment == nil then
        return nil, "equipment screen unavailable"
    end
    if deliveredHere >= PER_BEACON and not chosen then
        return nil, "enough equipment for this beacon"
    end
    local why = noRoom(family)
    if why ~= nil then
        return nil, why
    end
    local blueprints = Hyperspace.Blueprints
    if family == "weapon" then
        equipment:AddWeapon(blueprints:GetWeaponBlueprint(name), true, false)
    else
        equipment:AddDrone(blueprints:GetDroneBlueprint(name), true, false)
    end
    deliveredHere = deliveredHere + 1
    return name
end

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager ~= nil and shipManager.iShipId == 0 then
        deliveredHere = 0
        justArrived = true
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    justArrived = false
end)

script.on_init(function()
    deliveredHere = 0
end)

local AUGMENT_SLOTS = 3

-- FTL holds three augments: with all three taken, the new one waits for a free slot instead of vanishing.
local function augmentsAboard(player)
    local ok, count = pcall(function()
        local list = player:GetAugmentationList()
        local n = 0
        for i = 0, list:size() - 1 do
            if tostring(list[i]):sub(1, 3) ~= "AP_" then n = n + 1 end
        end
        return n
    end)
    return ok and count or 0
end

local function deliverAugment(name)
    local player = Hyperspace.ships.player
    if player == nil then
        return nil, "no ship"
    end
    if augmentsAboard(player) >= AUGMENT_SLOTS then
        return nil, "no free augment slot"
    end
    player:AddAugmentation(name)
    return name
end

function apShipHolds(name)
    local ok, found = pcall(function()
        local player = Hyperspace.ships.player
        local lists = {
            player:GetWeaponList(),
            Hyperspace.App.gui.equipScreen:GetCargoHold(),
            player:GetAugmentationList(),
        }
        for _, list in ipairs(lists) do
            for i = 0, list:size() - 1 do
                local held = list[i]
                if tostring(type(held) == "string" and held or held.blueprint.name) == name then
                    return true
                end
            end
        end
        if player.droneSystem ~= nil then
            local drones = player.droneSystem.drones
            for i = 0, drones:size() - 1 do
                if tostring(drones[i].blueprint.name) == name then
                    return true
                end
            end
        end
        return false
    end)
    return ok and found
end

function apDeliverEquipment(descriptor)
    local queued = descriptor
    local name = descriptor.bp
    if name == nil or name == "" then
        equipLog("descriptor without a blueprint, ignored")
        return false
    end
    if descriptor.owed and _G.apShopOwedAlreadyAboard and apShopOwedAlreadyAboard(name) then
        return true
    end

    local family = apBlueprintFamily(name)
    if family == nil then
        equipLog("unknown blueprint, item NOT delivered: " .. tostring(name)
            .. " (kind " .. tostring(descriptor.kind) .. ")")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("item.unknown",
                { name = descriptor.display or tostring(name) }))
        end
        return false
    end
    if family ~= descriptor.kind then
        equipLog(string.format("kind corrected for %s: %s -> %s", name, descriptor.kind, family))
        queued.kind = family
        descriptor = { kind = family, bp = name, display = descriptor.display,
            sender = descriptor.sender, silent = descriptor.silent }
    end

    local delivered, err
    if descriptor.kind == "weapon" or descriptor.kind == "drone" then
        delivered, err = deliverEquipped(name, descriptor.kind, descriptor.chosen)
    elseif descriptor.kind == "augment" then
        delivered, err = deliverAugment(name)
    else
        return false
    end

    if delivered == nil then
        -- Retried every few seconds until it fits: say it once per reason, not at each try.
        if queued.waiting ~= err then
            queued.waiting = err
            equipLog("delivery deferred for " .. tostring(name) .. ": " .. tostring(err))
            local label = descriptor.display or (_G.apHumaniseId and _G.apHumaniseId(name)) or name
            if descriptor.kind == "augment" and _G.apNotifyWaiting then
                _G.apNotifyWaiting(label)
            elseif err == CARGO_FULL and _G.apNotifyWaiting then
                _G.apNotifyWaiting(label, "cargo")
            end
        end
        return false, "retry"
    end

    local label = descriptor.display or (_G.apHumaniseId and _G.apHumaniseId(name)) or tostring(name)
    equipLog("delivered: " .. name .. " (" .. descriptor.kind .. ")")
    if not descriptor.chosen and _G.apShopCopyAboard then
        apShopCopyAboard(name)
    end
    if _G.apNotifyItem and not descriptor.silent then
        _G.apNotifyItem(label, descriptor.sender)
    end
    return true
end

local SKILLS = { pilot = 0, engines = 1, shields = 2, weapons = 3, repair = 4, combat = 5 }

function apRecruitCrew(race, skill)
    local player = Hyperspace.ships.player
    if player == nil then
        return false, "no ship"
    end
    local isFullOk, isFull = pcall(function() return player:IsCrewFull() end)
    if isFullOk and isFull then
        return false, "crew full"
    end
    local ok, member = pcall(function()
        return player:AddCrewMemberFromString("", race, false, 0, false, math.random(0, 1) == 0)
    end)
    if not ok or member == nil then
        return false, "recruit failed"
    end
    local number = SKILLS[skill or ""]
    if number ~= nil then
        pcall(function() member:MasterSkill(number) end)
    end
    equipLog("recruit: " .. tostring(race) .. (skill and (" expert in " .. skill) or ""))
    return true
end

function apCargoStatus()
    pcall(function()
        local equipment = Hyperspace.App.gui.equipScreen
        if equipment == nil then
            equipLog("equipment screen unavailable (out of run?)")
            return
        end
        local cargo = equipment:GetCargoHold()
        equipLog("cargo: " .. cargo:size() .. " item(s)")
        for i = 0, cargo:size() - 1 do
            equipLog("  " .. tostring(cargo[i]))
        end
    end)
end

equipLog("equipment module loaded (console: LUA apCargoStatus())")
