local TAG = "[AP-unlock] "

local function unlockLog(message)
    log(TAG .. message)
end

local SHIPS = _G.apGameData and _G.apGameData.ships or {}

local VARIANT_SUFFIX = { [0] = "", [1] = "_2", [2] = "_3" }

local function fullName(ship, variant)
    return ship .. (VARIANT_SUFFIX[variant] or "")
end

-- Through the module's lock when it has one: FTL's own unlocks are refused, the mod's go through.
function apUnlockLayout(name, silent)
    if _G.apNetUnlockShip then
        local done = apNetUnlockShip(name, silent)
        if done ~= nil then
            return true
        end
    end
    return pcall(function()
        Hyperspace.CustomShipUnlocks.instance:UnlockShip(name, silent == true, true, false)
    end)
end

function apUnlock(ship, variant)
    variant = variant or 0
    local name = fullName(ship, variant)
    local ok, err = apUnlockLayout(name, false)
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

local function unlockedInFtl(ship, variant)
    local ok, value = pcall(function()
        return Hyperspace.CustomShipUnlocks.instance:GetCustomShipUnlocked(ship, variant)
    end)
    return ok and value == true
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
    -- FTL unlocks ships by itself (an event, an achievement) and cannot lock them again: say which
    -- playable ones did not come from Archipelago, before a run with them is started for nothing.
    local judged = _G.apShipReceived and _G.apInventorySynced and apInventorySynced()
    for index, ship in ipairs(LIST_ORDER) do
        local layout = fullName(ship, variant)
        local key = nil
        if variant < layoutCount(ship) then
            if not apLayoutInSeed(layout) then
                key = "hangar.out_of_seed"
            elseif judged and apShipReceived(layout) == "not_received"
                and unlockedInFtl(ship, variant) then
                key = "hangar.not_received"
            end
        end
        if key then
            local label = apT(key)
            local width = Graphics.freetype.easy_measureWidth(MARK_FONT, label) + 12
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

-- A Type B or C FTL earned by itself (its achievements, with layout unlocks set to vanilla) before its ship's
-- key came in: kept for the seed, and unlocked once the key is there.
local earned, earnedFor = {}, nil

local function earnedKey()
    return "ap_earned_layouts_" .. tostring(_G.apSeedFingerprint and apSeedFingerprint() or 0)
end

local function loadEarned()
    local key = earnedKey()
    if earnedFor == key then
        return
    end
    earned, earnedFor = {}, key
    local text = _G.apNetRecallText and apNetRecallText(key) or ""
    for name in tostring(text):gmatch("[^,]+") do
        earned[name] = true
    end
end

local function saveEarned()
    local list = {}
    for name in pairs(earned) do
        list[#list + 1] = name
    end
    table.sort(list)
    if _G.apNetRememberText then
        apNetRememberText(earnedKey(), table.concat(list, ","))
    end
end

function apShipUnlockDenied(blueprint)
    local status = _G.apShipReceived and apShipReceived(blueprint) or "not_received"
    if status == "ok" then
        unlockLog("FTL unlocked " .. blueprint .. ", which Archipelago allows: let through")
        apUnlockLayout(blueprint, false)
        return
    end
    unlockLog("FTL tried to unlock " .. blueprint .. " (" .. status .. "): refused")
    if blueprint:match("_[23]$") then
        loadEarned()
        if not earned[blueprint] then
            earned[blueprint] = true
            saveEarned()
        end
    end
end

-- The earned layouts whose ship is now received.
function apEarnedLayoutsReady()
    loadEarned()
    local ready = {}
    for name in pairs(earned) do
        if _G.apShipReceived and apShipReceived(name) == "ok" then
            ready[#ready + 1] = name
        end
    end
    table.sort(ready)
    return ready
end

local function layoutsToCheck()
    local layouts, seen = {}, {}
    local function add(name)
        if not seen[name] then
            seen[name] = true
            layouts[#layouts + 1] = name
        end
    end
    for _, entry in ipairs(SHIPS) do
        for variant = 0, entry.layouts - 1 do
            add(fullName(entry.name, variant))
        end
    end
    for _, name in ipairs(((_G.apContractState or {}).layoutList) or {}) do
        add(tostring(name))
    end
    return layouts
end

-- With the inventory complete, the profile holds exactly what Archipelago gave: anything FTL unlocked on its
-- own (an event, an achievement, an older version of the mod) is locked again. Only at the main menu.
function apRelockShips()
    if not (_G.apInventorySynced and apInventorySynced() and _G.apShipReceived and _G.apNetLockShips) then
        return 0
    end
    local extra = {}
    for _, layout in ipairs(layoutsToCheck()) do
        local ship = layout:gsub("_[23]$", "")
        local variant = layout:match("_2$") and 1 or (layout:match("_3$") and 2 or 0)
        if unlockedInFtl(ship, variant) and apShipReceived(layout) ~= "ok" then
            extra[#extra + 1] = layout
        end
    end
    if #extra == 0 then
        return 0
    end
    local locked = apNetLockShips(extra) or 0
    if locked > 0 then
        unlockLog(locked .. " ship(s) locked again, not given by Archipelago: " .. table.concat(extra, ", "))
        if _G.apNotifyStatus then
            apNotifyStatus(apT("unlock.relocked", { n = locked }))
        end
    end
    return locked
end

local function atMainMenu()
    local ok, open = pcall(function()
        local menu = Hyperspace.App.menu
        return menu.bOpen == true and menu.shipBuilder.bOpen ~= true
    end)
    return ok and open == true
end

local relockTicks = 0
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    relockTicks = relockTicks + 1
    if relockTicks % 120 == 0 and atMainMenu() then
        apTry(TAG, apRelockShips)
    end
end)

unlockLog("unlock module loaded (console: LUA apUnlockStatus())")
