
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

unlockLog("unlock module loaded (console: LUA apUnlockStatus())")
