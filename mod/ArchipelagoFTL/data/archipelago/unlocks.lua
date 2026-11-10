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

-- kestrel_key: FTL always counts the Kestrel A as unlocked and the hangar cannot grey it out, so the mod says
-- it is locked and refuses START while it is the ship shown.
function apKestrelBlocked(layout)
    return layout == "PLAYER_SHIP_HARD" and _G.apSeedKestrelLocked ~= nil and apSeedKestrelLocked()
        and _G.apLayoutInSeed ~= nil and apLayoutInSeed(layout)
        and _G.apShipReceived ~= nil and _G.apInventorySynced ~= nil and apInventorySynced()
        and apShipReceived(layout) ~= "ok"
end

local START_BUTTON = { x = 1080, y = 10, w = 158, h = 58 }
-- Seconds the refusal stays up, counted on FTL's clock (SpeedFactor is in sixteenths of a second).
local refusedLeft = 0

local function frameSeconds()
    local ok, factor = pcall(function() return Hyperspace.FPS.SpeedFactor end)
    factor = ok and tonumber(factor) or nil
    if factor == nil or factor <= 0 then
        return 1 / 60
    end
    return math.min(factor * 0.0625, 0.25)
end

-- The ships the hangar may show for this seed, the starting ship first.
local playableLayouts

local openOnPlayableShip
-- A seed that locks the Kestrel opens the hangar on its starting ship instead of the locked Kestrel.
local hangarWasOpen = false
local openingFrames = 0

openOnPlayableShip = function()
    local ok, open = pcall(function() return Hyperspace.App.menu.shipBuilder.bOpen == true end)
    open = ok and open
    if open and not hangarWasOpen then
        -- Back from a run, the hangar shows the previous ship for a moment before FTL puts the Kestrel back:
        -- watch the first seconds, not only the first frame.
        openingFrames = 180
    end
    hangarWasOpen = open
    if not open or openingFrames <= 0 or not _G.apNetHangarShip then
        return
    end
    openingFrames = openingFrames - 1
    local shown = apNetHangarShip()
    if shown == nil or shown == "" or not apKestrelBlocked(shown) then
        return
    end
    openingFrames = 0
    local target = playableLayouts()[1]
    if target and _G.apNetSwitchHangarShip and apNetSwitchHangarShip(target) then
        unlockLog("hangar opened on " .. target .. " instead of the Kestrel A without its key")
    end
end

local function hangarBlocked()
    local ok, open = pcall(function()
        return Hyperspace.App.menu.shipBuilder.bOpen == true
            and not Hyperspace.CustomShipSelect.GetInstance():IsOpen()
    end)
    if not (ok and open) or not _G.apNetHangarShip then
        return false
    end
    return apKestrelBlocked(apNetHangarShip())
end

local function drawKestrelLock()
    if not hangarBlocked() then
        refusedLeft = 0
        return
    end
    -- START shaded out, with the same mark as the ship list on it.
    local b = START_BUTTON
    apUi.rect(b.x, b.y, b.w, b.h, "window", 0.75)
    local label = apT("hangar.needs_key")
    local font = apUi.fittingFont({ MARK_FONT, 10, 8 }, b.w - 20, label)
    local width = math.min(b.w - 4, apUi.width(font, label) + 16)
    local center = b.x + b.w / 2
    apUi.rect(center - width / 2, b.y + b.h / 2 - 10, width, 20, "window", 0.95)
    apUi.textCenter(font, center, b.y + b.h / 2 - 8, width, "warn", label)
    if refusedLeft > 0 then
        refusedLeft = refusedLeft - frameSeconds()
        local text = apT("hangar.kestrel_locked")
        local w = math.min(620, apUi.width(14, text) + 48)
        local lines = apUi.lines(14, text, w - 40, 3)
        local h = 28 + #lines * 22
        local x, y = (1280 - w) / 2, (720 - h) / 2
        apUi.window(x, y, w, h, "warn")
        for index, line in ipairs(lines) do
            apUi.textCenter(14, x + w / 2, y + 14 + (index - 1) * 22, w - 32, "warn", line)
        end
    end
end

-- Where FTL's help sits over the list the first time it opens: marks under it would be drawn over its text.
local HELP_BOX = { x = 335, y = 148, w = 602, h = 376 }

local function underHelp(x, y)
    return x + 190 > HELP_BOX.x and x < HELP_BOX.x + HELP_BOX.w and y + 120 > HELP_BOX.y
        and y < HELP_BOX.y + HELP_BOX.h
end

local function drawOutOfSeed(help)
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
            if apKestrelBlocked(layout) then
                key = "hangar.needs_key"
            elseif not apLayoutInSeed(layout) then
                key = "hangar.out_of_seed"
            elseif judged and apShipReceived(layout) == "not_received"
                and unlockedInFtl(ship, variant) then
                key = "hangar.not_received"
            end
        end
        local x, y = cellOf(index - 1)
        if key and not (help and underHelp(x, y)) then
            -- A Kestrel without its key looks as locked as the ships FTL locks itself.
            if key == "hangar.needs_key" then
                apUi.rect(x + 4, y + 4, 182, 112, "shade", 0.8)
            end
            local label = apT(key)
            local font = apUi.fittingFont({ MARK_FONT, 10, 8 }, 176, label)
            local width = apUi.width(font, label) + 12
            local center = x + 95
            apUi.rect(center - width / 2, y + 104, width, 18, "window", 0.9)
            apUi.textCenter(font, center, y + 106, width, "warn", label)
        end
    end
end

-- The first time a profile opens the list, FTL shows its help over it, which Lua cannot see. The game sets
-- openedList to 2 as it does: opened while it was lower, the list shows the help until it closes again.
local listOpen, helpShown, openedBefore = false, false, 2

local function helpOverList()
    local open = Hyperspace.CustomShipSelect.GetInstance():IsOpen()
    local opened = tonumber(Hyperspace.Settings.openedList) or 2
    if open and not listOpen then
        helpShown = openedBefore < 2
    elseif not open then
        helpShown = false
        openedBefore = opened
    end
    listOpen = open
    return helpShown
end

script.on_render_event(Defines.RenderEvents.MAIN_MENU, function() end, function()
    local ok, help = pcall(helpOverList)
    pcall(drawOutOfSeed, not ok or help)
    pcall(openOnPlayableShip)
    local drawn, err = pcall(drawKestrelLock)
    if not drawn then
        unlockLog("hangar lock not drawn: " .. tostring(err))
    end
end)

-- The menu is not drawn during a run: the hangar seen before it would otherwise still count as open on the
-- way back, and the hangar would stay on the Kestrel.
script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, function() end, function()
    hangarWasOpen = false
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    if not hangarBlocked() then
        return Defines.Chain.CONTINUE
    end
    x, y = apMousePosition(x, y)
    if apUi.inside(START_BUTTON, x, y) then
        refusedLeft = 5
        unlockLog("START refused: the Kestrel A has not received its key")
        return Defines.Chain.PREEMPT
    end
    return Defines.Chain.CONTINUE
end)

-- A Type B or C FTL earned by itself (its achievements, with layout unlocks set to vanilla) before its ship's
-- key came in: kept for the seed, and unlocked once the key is there.
local earned, earnedFor = {}, nil

local function earnedKey()
    return apNetSlotKey("ap_earned_layouts_" .. tostring(_G.apSeedFingerprint and apSeedFingerprint() or 0))
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

playableLayouts = function()
    if not (_G.apShipReceived and _G.apInventorySynced and apInventorySynced()) then
        return {}
    end
    local list, start = {}, _G.apSeedStartShip and apSeedStartShip() or nil
    for _, layout in ipairs(layoutsToCheck()) do
        if apShipReceived(layout) == "ok" and not apKestrelBlocked(layout) then
            if layout == start then
                table.insert(list, 1, layout)
            else
                list[#list + 1] = layout
            end
        end
    end
    return list
end

-- RANDOM SHIP: FTL draws among the ships its own profile unlocked, which is only the Kestrel when Archipelago
-- gives the ships. The mod draws among the ships received instead.
local RANDOM_BUTTON = { x = 18, y = 180, w = 158, h = 30 }

local function randomShipClick(x, y)
    local ok, open = pcall(function()
        return Hyperspace.App.menu.shipBuilder.bOpen == true
            and not Hyperspace.CustomShipSelect.GetInstance():IsOpen()
    end)
    if not (ok and open) or not _G.apNetSwitchHangarShip or not apUi.inside(RANDOM_BUTTON, x, y) then
        return false
    end
    local choices, current = {}, _G.apNetHangarShip and apNetHangarShip() or nil
    for _, layout in ipairs(playableLayouts()) do
        if layout ~= current then
            choices[#choices + 1] = layout
        end
    end
    if #choices == 0 then
        return false
    end
    local pick = choices[math.random(#choices)]
    unlockLog("RANDOM SHIP: " .. pick)
    return apNetSwitchHangarShip(pick) == true
end

-- The < and > arrows: FTL steps through the base ships its own profile unlocked (only the Kestrel when
-- Archipelago gives the ships). The mod steps through the base ships of the seed that can be shown instead: those
-- received, and the Kestrel A without its key, which the hangar then marks NO KEY. Same layout letter as shown.
local LEFT_ARROW = { x = 30, y = 142, w = 40, h = 32 }
local RIGHT_ARROW = { x = 124, y = 142, w = 40, h = 32 }

local function arrowClick(x, y)
    local step = apUi.inside(LEFT_ARROW, x, y) and -1 or (apUi.inside(RIGHT_ARROW, x, y) and 1 or nil)
    if step == nil or not _G.apNetSwitchHangarShip or not _G.apNetHangarShip then
        return false
    end
    local ok, open = pcall(function()
        return Hyperspace.App.menu.shipBuilder.bOpen == true
            and not Hyperspace.CustomShipSelect.GetInstance():IsOpen()
    end)
    if not (ok and open) or not (_G.apShipReceived and _G.apInventorySynced and apInventorySynced()) then
        return false
    end
    local current = apNetHangarShip() or ""
    local variant = current:match("_2$") and 1 or (current:match("_3$") and 2 or 0)
    local cycle, at = {}, nil
    for _, ship in ipairs(LIST_ORDER) do
        local layout = fullName(ship, variant)
        if layout == current then
            at = #cycle + 1
            cycle[at] = layout
        elseif variant < layoutCount(ship) and (apShipReceived(layout) == "ok" or apKestrelBlocked(layout)) then
            cycle[#cycle + 1] = layout
        end
    end
    -- Not a base ship (a Multiverse one): Hyperspace's own arrows already go through its list.
    if at == nil or #cycle < 2 then
        return false
    end
    local pick = cycle[(at - 1 + step) % #cycle + 1]
    unlockLog((step < 0 and "<" or ">") .. " " .. pick)
    return apNetSwitchHangarShip(pick) == true
end

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    x, y = apMousePosition(x, y)
    local arrowed, moved = pcall(arrowClick, x, y)
    if arrowed and moved then
        return Defines.Chain.PREEMPT
    end
    local ok, done = pcall(randomShipClick, x, y)
    if ok and done then
        return Defines.Chain.PREEMPT
    end
    return Defines.Chain.CONTINUE
end)

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
    local locked = math.floor(apNetLockShips(extra) or 0)
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
