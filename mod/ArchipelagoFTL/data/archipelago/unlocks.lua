local TAG = "[AP-unlock] "

local function unlockLog(message)
    log(TAG .. message)
end

local SHIPS = _G.apGameData and _G.apGameData.ships or {}

local VARIANT_SUFFIX = { [0] = "", [1] = "_2", [2] = "_3" }

local function fullName(ship, variant)
    return ship .. (VARIANT_SUFFIX[variant] or "")
end

function apUnlock(ship, variant)
    variant = variant or 0
    local name = fullName(ship, variant)
    local ok, err = pcall(function()
        Hyperspace.CustomShipUnlocks.instance:UnlockShip(name, false, true, false)
    end)
    if ok then
        unlockLog("UnlockShip(" .. name .. ") called")
    else
        unlockLog("UnlockShip(" .. name .. ") failed: " .. tostring(err))
    end
end

-- The default Kestrel layout is unlocked on a fresh profile; skip probing it so a brand
-- new profile with nothing else unlocked does not read as "already has ships".
local ALWAYS_THERE = { PLAYER_SHIP_HARD = 0 }

function apProfileHasShips()
    local unlocks = Hyperspace.CustomShipUnlocks and Hyperspace.CustomShipUnlocks.instance
    if unlocks == nil then
        return false
    end
    for _, entry in ipairs(SHIPS) do
        for variant = 0, entry.layouts - 1 do
            if ALWAYS_THERE[entry.name] ~= variant then
                local ok, value = pcall(function()
                    return unlocks:GetCustomShipUnlocked(entry.name, variant)
                end)
                if ok and value == true then
                    return true
                end
            end
        end
    end
    return false
end

function apUnlockStatus()
    local unlocks = Hyperspace.CustomShipUnlocks.instance
    unlockLog("ship status (true = playable):")
    for _, entry in ipairs(SHIPS) do
        local ship = entry.name
        local parts = {}
        for variant = 0, entry.layouts - 1 do
            local ok, value = pcall(function()
                return unlocks:GetCustomShipUnlocked(ship, variant)
            end)
            parts[#parts + 1] = string.format("%s=%s", ("ABC"):sub(variant + 1, variant + 1),
                ok and tostring(value) or ("error:" .. tostring(value)))
        end
        unlockLog("  " .. ship .. " " .. table.concat(parts, " "))
    end
end

function apUnlockAll()
    for _, entry in ipairs(SHIPS) do
        for variant = 0, entry.layouts - 1 do
            apUnlock(entry.name, variant)
        end
    end
    unlockLog("everything unlocked")
end

-- The ten base ships in the order of the ship list. Hyperspace lays them out as a snake: four along the top,
-- four back along the bottom, then two on the right.
local LIST_ORDER = {
    "PLAYER_SHIP_HARD", "PLAYER_SHIP_CIRCLE", "PLAYER_SHIP_FED", "PLAYER_SHIP_ENERGY", "PLAYER_SHIP_MANTIS",
    "PLAYER_SHIP_JELLY", "PLAYER_SHIP_ROCK", "PLAYER_SHIP_STEALTH", "PLAYER_SHIP_ANAEROBIC", "PLAYER_SHIP_CRYSTAL",
}
local CELL_W, CELL_H = 205, 177
local LIST_X, LIST_Y = 136, 161
local MARK_FONT = 12

local function cellOf(slot)
    if slot < 4 then
        return LIST_X + CELL_W * slot, LIST_Y
    elseif slot < 8 then
        return LIST_X + CELL_W * (7 - slot), LIST_Y + CELL_H
    end
    return LIST_X + CELL_W * 3 + 225, LIST_Y + CELL_H * (slot - 8)
end

local function layoutCount(ship)
    for _, entry in ipairs(SHIPS) do
        if entry.name == ship then
            return entry.layouts
        end
    end
    return 3
end

local function drawOutOfSeed()
    if not _G.apLayoutInSeed then
        return
    end
    local list = Hyperspace.CustomShipSelect.GetInstance()
    if not (list:IsOpen() and list:FirstPage()) then
        return
    end
    local variant = list.shipSelect.currentType
    local label = apT("hangar.out_of_seed")
    local width = Graphics.freetype.easy_measureWidth(MARK_FONT, label) + 12
    for index, ship in ipairs(LIST_ORDER) do
        if variant < layoutCount(ship) and not apLayoutInSeed(fullName(ship, variant)) then
            local x, y = cellOf(index - 1)
            local center = x + 95
            apUi.rect(center - width / 2, y + 104, width, 18, "window", 0.9)
            apUi.textCenter(MARK_FONT, center, y + 106, width, "warn", label)
        end
    end
end

script.on_render_event(Defines.RenderEvents.MAIN_MENU, function() end, function()
    pcall(drawOutOfSeed)
end)

unlockLog("unlock module loaded (console: LUA apUnlockStatus())")
