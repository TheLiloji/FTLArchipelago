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
-- of them. Going back to the main menu with a dozen there crashes the game: past a few, the next ones wait
-- for the jump that empties the box.
local OVERFLOW_LIMIT = 3
local overflowCount = 0

local function itemsAboard(equipment)
    local ok, count = pcall(function()
        local player = Hyperspace.ships.player
        local total = equipment:GetCargoHold():size()
        if player.weaponSystem ~= nil then total = total + player.weaponSystem.weapons:size() end
        if player.droneSystem ~= nil then total = total + player.droneSystem.drones:size() end
        return total
    end)
    return ok and count or nil
end

local function deliverEquipped(name, family)
    local equipment = Hyperspace.App.gui.equipScreen
    if equipment == nil then
        return nil, "equipment screen unavailable"
    end
    if overflowCount >= OVERFLOW_LIMIT then
        return nil, "over capacity box full"
    end
    local before = itemsAboard(equipment)
    local blueprints = Hyperspace.Blueprints
    if family == "weapon" then
        equipment:AddWeapon(blueprints:GetWeaponBlueprint(name), true, false)
    else
        equipment:AddDrone(blueprints:GetDroneBlueprint(name), true, false)
    end
    -- Hyperspace counts the box's hidden pages as cargo, so only the first item into the box leaves the
    -- count unchanged. Cargo stays full after that: everything that follows goes to the box as well.
    local after = itemsAboard(equipment)
    if overflowCount > 0 or (before ~= nil and after ~= nil and after <= before) then
        overflowCount = overflowCount + 1
    end
    return name
end

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager ~= nil and shipManager.iShipId == 0 then
        overflowCount = 0
    end
end)

script.on_init(function()
    overflowCount = 0
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

function apDeliverEquipment(descriptor)
    local queued = descriptor
    local name = descriptor.bp
    if name == nil or name == "" then
        equipLog("descriptor without a blueprint, ignored")
        return false
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
        delivered, err = deliverEquipped(name, descriptor.kind)
    elseif descriptor.kind == "augment" then
        delivered, err = deliverAugment(name)
    else
        return false
    end

    if delivered == nil then
        -- Retried every few seconds until it fits: say it once, not at each try.
        if not queued.waiting then
            queued.waiting = true
            equipLog("delivery deferred for " .. tostring(name) .. ": " .. tostring(err))
            if descriptor.kind == "augment" and _G.apNotifyWaiting then
                _G.apNotifyWaiting(descriptor.display or (_G.apHumaniseId and _G.apHumaniseId(name)) or name)
            end
        end
        return false, "retry"
    end

    local label = descriptor.display or (_G.apHumaniseId and _G.apHumaniseId(name)) or tostring(name)
    equipLog("delivered: " .. name .. " (" .. descriptor.kind .. ")")
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
