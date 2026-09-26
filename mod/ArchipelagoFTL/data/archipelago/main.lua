local MOD_NAME = "ArchipelagoFTL"
local MOD_VERSION = "0.3.1"
local TAG = "[AP] "

local function apLog(message)
    log(TAG .. message)
end

-- Game hooks must never throw into Hyperspace, but a failure there is a bug worth seeing in the log.
function apTry(tag, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        log(tag .. "error: " .. tostring(err))
    end
end

apLog(MOD_NAME .. " " .. MOD_VERSION .. " loaded (Hyperspace " .. tostring(Hyperspace.version) .. ")")

script.on_load(function()
    apLog("on_load: ready, waiting for a run to start")
end)

script.on_init(function(newGame)
    if newGame then
        apLog("on_init: new run started")
    else
        apLog("on_init: saved run loaded")
    end
end)

function apMenuSubScreen()
    local menu = Hyperspace.App.menu
    local screens = {
        function() return menu.shipBuilder.bOpen end,
        function() return menu.bScoreScreen end,
        function() return menu.bCreditScreen end,
        function() return menu.bSelectSave end,
        function() return menu.optionScreen.bOpen end,
    }
    for _, read in ipairs(screens) do
        local ok, open = pcall(read)
        if ok and open == true then
            return true
        end
    end
    return false
end

-- Mouse events carry window pixels, which only match the 1280x720 layout when the window is not scaled.
function apMousePosition(x, y)
    local ok, px, py = pcall(function()
        local position = Hyperspace.Mouse.position
        return position.x, position.y
    end)
    if ok and px ~= nil then
        return px, py
    end
    return x, y
end

function apPauseMenuOpen()
    local ok, open = pcall(function()
        return Hyperspace.App.gui.menu_pause
    end)
    return ok and open == true
end

function apTutorialRunning()
    local ok, active = pcall(function()
        return Hyperspace.Tutorial.bRunning
    end)
    return ok and active == true
end

function apModBanner()
    local connected = _G.apNetConnected and _G.apNetConnected()
    return apT(connected and "menu.banner.online" or "menu.banner.offline",
               { mod = MOD_NAME, version = MOD_VERSION })
end

local function describeSector()
    local starMap = Hyperspace.App.world.starMap
    if starMap == nil then
        return "sector=? (no star map)"
    end

    local sectorNumber = starMap.worldLevel + 1
    local sectorType = "?"
    local sectorName = "?"

    local sector = starMap.currentSector
    if sector ~= nil then
        local description = sector.description
        if description ~= nil then
            sectorType = tostring(description.type)
            sectorName = tostring(description.name:GetText())
        end
    end

    return string.format("sector=%d type=%s name=%s", sectorNumber, sectorType, sectorName)
end

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager.iShipId ~= 0 then
        return
    end
    apLog("JUMP_ARRIVE " .. describeSector())
end)
