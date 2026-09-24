
local TAG = "[AP-hud] "

local COLOR = {
    panel = { 0.08, 0.09, 0.12, 0.92 },
    border = { 0.59, 0.55, 0.86, 1.0 },
    title = { 0.72, 0.68, 0.92, 1.0 },
    text = { 0.88, 0.92, 0.86, 1.0 },
    dim = { 0.52, 0.55, 0.52, 1.0 },
    good = { 0.55, 0.80, 0.55, 1.0 },
    warn = { 0.85, 0.72, 0.42, 1.0 },
}

local function color(name)
    local c = COLOR[name]
    return Graphics.GL_Color(c[1], c[2], c[3], c[4])
end

local open = false

local function hasSeed()
    local contract = _G.apContractState
    return contract ~= nil and contract.connected == true
end

local function snapshot()
    local inventory = _G.apInventory or {}
    local info = {
        ships = 0,
        systems = {},
        starts = {},
        reactor = 0,
        checks = _G.apCheckCount and _G.apCheckCount() or nil,
        connected = _G.apNetState and _G.apNetState.connected or false,
    }

    info.ships = #(inventory.ships or {})

    local caps = inventory.systemCaps or {}
    for _, system in ipairs((_G.apGameData and _G.apGameData.systems) or {}) do
        local count = caps[system.id] or 0
        info.systems[#info.systems + 1] = {
            name = (_G.apSystemLabel and _G.apSystemLabel(system.id)) or system.id,
            cap = count,
            received = math.max(0, count - 1),
            total = _G.apSystemCapTotal and _G.apSystemCapTotal(system.id) or nil,
            maxLevel = system.maxLevel,
            locked = count <= 0,
        }
        if count > 0 then
            info.unlockedCount = (info.unlockedCount or 0) + 1
        end
    end
    info.unlockedCount = info.unlockedCount or 0
    info.systemTotal = #info.systems

    for name, count in pairs(inventory.startingUpgrades or {}) do
        if count and count > 0 then
            if name == "reactor" then
                info.reactor = count
            else
                info.starts[#info.starts + 1] = {
                    name = (_G.apSystemLabel and _G.apSystemLabel(name)) or name,
                    levels = count,
                }
            end
        end
    end
    table.sort(info.starts, function(a, b) return a.name < b.name end)

    return info
end

local function summary()
    local info = snapshot()
    local parts = {}

    if info.checks then
        parts[#parts + 1] = apT("hud.summary.checks",
            { done = info.checks.sent, total = info.checks.total })
    end
    parts[#parts + 1] = apT("hud.summary.ships", { count = info.ships })
    parts[#parts + 1] = apT("hud.summary.systems",
        { unlocked = info.unlockedCount or 0, total = info.systemTotal or #info.systems })

    local levels = 0
    for _, entry in ipairs(info.starts) do
        levels = levels + entry.levels
    end
    parts[#parts + 1] = apT("hud.summary.start_levels", { levels = levels })

    return table.concat(parts, "   ")
end

local function goalLine()
    local seed = _G.apSeedSummary and _G.apSeedSummary() or nil
    if seed == nil or seed.goal == nil or seed.goal.kind ~= "victories" then
        return nil
    end
    local progress = _G.apGoalProgress and _G.apGoalProgress() or nil
    if progress == nil then
        return apT("hud.goal", { n = seed.goal.layouts and #seed.goal.layouts or seed.goal.count })
    end
    local line = apT(progress.reached and "hud.goal.done" or "hud.goal.progress",
                      { done = progress.done, total = progress.total, n = progress.total })
    local difficulty = _G.apGoalDifficulty and _G.apGoalDifficulty() or nil
    local subLine
    if difficulty ~= nil then
        subLine = apT("hud.goal.difficulty", { difficulty = difficulty })
    else
        subLine = apT("hud.goal.difficulty.any")
    end
    local archives = _G.apGoalArchives and _G.apGoalArchives() or nil
    if archives ~= nil then
        subLine = subLine .. "   " .. apT("hud.goal.archives",
            { done = _G.apReceivedArchives and _G.apReceivedArchives() or 0, total = archives })
    end
    return line, progress.reached, subLine
end

local PANEL = { x = 20, y = 60, w = 340, h = 420 }

local COLUMN_GAP = 12
local LINE_H = 13

-- keep the panel clear of the 720px screen edge even when it grows tall
local PANEL_MAX_BOTTOM = 710

local function layoutPanel(x, y, w, emitting, limit)
    local info = snapshot()
    local line = y + 16
    local hidden = 0

    local function visible(height)
        if limit == nil or line + height <= limit then
            return true
        end
        hidden = hidden + 1
        return false
    end

    local function write(text, tint, indent, size)
        local height = (size == 12) and 20 or 14
        if emitting and visible(height) then
            Graphics.CSurface.GL_SetColor(color(tint or "text"))
            Graphics.freetype.easy_printAutoShrink(size or 10, x + 12 + (indent or 0), line,
                w - 24 - (indent or 0), false, text)
        end
        line = line + height
    end

    write(apT("hud.title"), "title", 0, 12)

    if not hasSeed() then
        write(apT("hud.no_seed"), "warn", 0, 9)
        write(apT("hud.no_seed.how"), "dim", 0, 9)
        write(apT("hud.no_seed.solo"), "dim", 0, 9)
    end

    local seed = _G.apSeedSummary and _G.apSeedSummary() or nil
    if seed then
        local goal = seed.goal
        if goal and goal.kind == "victories" then
            local progress = _G.apGoalProgress and _G.apGoalProgress() or nil
            if progress then
                write(apT(progress.reached and "hud.goal.done" or "hud.goal.progress",
                          { done = progress.done, total = progress.total, n = progress.total }),
                      progress.reached and "good" or "dim", 0, 9)
            else
                write(apT("hud.goal", { n = goal.layouts and #goal.layouts or goal.count }),
                      "dim", 0, 9)
            end
        end
        local links = {}
        if seed.links.death then links[#links + 1] = "DeathLink" end
        if seed.links.energy then links[#links + 1] = "EnergyLink" end
        if seed.links.trap then links[#links + 1] = "TrapLink" end
        if #links > 0 then
            write(table.concat(links, "  "), "dim", 0, 9)
        end
    end

    if info.checks and info.checks.total > 0 then
        local done = info.checks.sent
        local total = info.checks.total
        write(apT("hud.checks_sent", { done = done, total = total }),
              done >= total and "good" or "text")

        local barWidth = w - 24
        local filled = total > 0 and math.floor(barWidth * done / total) or 0
        if emitting and visible(18) then
            Graphics.CSurface.GL_DrawRect(x + 12, line, barWidth, 6, color("dim"))
            if filled > 0 then
                Graphics.CSurface.GL_DrawRect(x + 12, line, filled, 6, color("border"))
            end
        end
        line = line + 18

        local waiting = _G.apPendingCheckCount and _G.apPendingCheckCount() or 0
        if waiting > 0 then
            write(apT("hud.checks_waiting", { n = waiting }), "warn", 12)
        end
        if not info.connected and not _G.apSoloEnabled then
            write(apT("hud.link_lost"), "warn", 12)
        end
    else
        write(apT("hud.not_connected"), "dim")
    end

    line = line + 6
    write(apT("hud.ships"), "title")
    write(apT("hud.ships.unlocked", { count = info.ships }),
          info.ships > 0 and "text" or "dim", 12)

    line = line + 6
    if info.systemTotal and info.systemTotal > 0 then
        write(apT("hud.systems.counted",
                  { unlocked = info.unlockedCount, total = info.systemTotal }), "title")
    else
        write(apT("hud.systems"), "title")
    end

    if #info.systems == 0 then
        write(apT("hud.systems.none"), "dim", 12)
    else
        local half = math.ceil(#info.systems / 2)
        local startLine = line
        local column = math.floor((w - 24 - COLUMN_GAP) / 2)
        for index, entry in ipairs(info.systems) do
            if index == half + 1 then
                line = startLine
            end
            local textX = x + 12 + (index <= half and 0 or (column + COLUMN_GAP))
            if entry.locked then
                if emitting and visible(LINE_H) then
                    Graphics.CSurface.GL_SetColor(color("dim"))
                    Graphics.freetype.easy_printAutoShrink(10, textX, line, column, false,
                        entry.name)
                end
                line = line + LINE_H
            else
                local known = entry.total ~= nil and entry.total > 0
                local full = known and entry.received >= entry.total
                if emitting and visible(LINE_H * 2) then
                    Graphics.CSurface.GL_SetColor(color(full and "good" or "text"))
                    Graphics.freetype.easy_printAutoShrink(10, textX, line, column, false,
                        entry.name)
                    local countText
                    if full then
                        countText = apT("hud.system.max")
                    elseif known then
                        countText = apT("hud.system.progress",
                            { received = entry.received, total = entry.total })
                    else
                        countText = apT("hud.system.received", { n = entry.received })
                    end
                    Graphics.CSurface.GL_SetColor(color(full and "good" or "dim"))
                    Graphics.freetype.easy_printAutoShrink(9, textX + 10, line + LINE_H,
                        column - 10, false, countText)
                end
                line = line + LINE_H * 2
            end
        end
    end

    line = line + 6
    write(apT("hud.starts"), "title")
    if #info.starts == 0 and info.reactor == 0 then
        write(apT("hud.starts.none"), "dim", 12)
    else
        for _, entry in ipairs(info.starts) do
            write("+" .. entry.levels .. "  " .. entry.name, "good", 12)
        end
        if info.reactor > 0 then
            write("+" .. info.reactor .. "  " .. apT("hud.starts.reactor"), "good", 12)
        end
    end

    local hints = _G.apHintsForDisplay and _G.apHintsForDisplay(3) or {}
    if #hints > 0 then
        line = line + 6
        write(apT("hud.hints"), "title", 0, 10)
        for _, hint in ipairs(hints) do
            write(_G.apHintLine(hint), "text", 12, 9)
        end
    end

    return line, hidden
end

local function drawPanel()
    local x, y, w = PANEL.x, PANEL.y, PANEL.w

    local bottom = layoutPanel(x, y, w, false) + 18
    local h = math.max(PANEL.h, bottom - y)
    if y + h > PANEL_MAX_BOTTOM then
        h = PANEL_MAX_BOTTOM - y
    end

    Graphics.CSurface.GL_DrawRect(x, y, w, h, color("panel"))
    Graphics.CSurface.GL_DrawRectOutline(x, y, w, h, color("border"), 2)

    local _, hidden = layoutPanel(x, y, w, true, y + h - 32)
    if hidden > 0 then
        Graphics.CSurface.GL_SetColor(color("dim"))
        Graphics.freetype.easy_printAutoShrink(9, x + 12, y + h - 32, w - 24, false,
            apT("hud.more", { n = hidden }))
    end

    Graphics.CSurface.GL_SetColor(color("dim"))
    Graphics.freetype.easy_printAutoShrink(9, x + 12, y + h - 18, w - 24, false, apT("hud.close"))
end

local TUTORIAL_W = 660
local TUTORIAL_H = 72
local TUTORIAL_Y = math.floor((720 - TUTORIAL_H) / 2)
local TUTORIAL_FONT = 24

local function drawTutorialBanner()
    local title = apT("tutorial.blocked")
    local width = math.max(TUTORIAL_W,
        Graphics.freetype.easy_measureWidth(TUTORIAL_FONT, title) + 48)
    local left = math.floor((1280 - width) / 2)
    Graphics.CSurface.GL_DrawRect(left, TUTORIAL_Y, width, TUTORIAL_H, color("panel"))
    Graphics.CSurface.GL_DrawRectOutline(left, TUTORIAL_Y, width, TUTORIAL_H, color("warn"), 2)
    Graphics.CSurface.GL_SetColor(color("warn"))
    Graphics.freetype.easy_printCenter(TUTORIAL_FONT, 640, TUTORIAL_Y + 18, title)
end

script.on_render_event(
    Defines.RenderEvents.GUI_CONTAINER,
    function() end,
    function()
        if open then
            local ok, err = pcall(drawPanel)
            if not ok then
                open = false
                log(TAG .. "render interrupted, panel closed: " .. tostring(err))
            end
        end
        if _G.apTutorialRunning and _G.apTutorialRunning()
            and not (_G.apPauseMenuOpen and _G.apPauseMenuOpen()) then
            pcall(drawTutorialBanner)
        end
    end
)

local SCREEN_H = 720
local SCREEN_W = 1280
local GOAL_FONT = 24
local GOAL_Y = 182
local GOAL_H = 52
local GOAL_BASELINE = 0
local GOAL_PADDING = 28
local GOAL_SUB_FONT = 10
local GOAL_SUB_H = 22

local TITLE_FONT = 63
local TITLE_Y = 92
local LOGO = "stars/planet_ap_archipelago.png"
local LOGO_SIZE = 210
local LOGO_X = 4
local LOGO_Y = -6
local LOGO_ALPHA = 0.7
local TITLE_X = 196

local function atMainMenuHome()
    local ok, shown = pcall(function()
        return Hyperspace.App.menu.bOpen == true
    end)
    if not (ok and shown) then
        return false
    end
    return not (_G.apMenuSubScreen and _G.apMenuSubScreen())
end

local loadedLogo = nil

local function logo()
    if loadedLogo == nil then
        local ok, texture = pcall(function()
            return Hyperspace.Resources:GetImageId(LOGO)
        end)
        loadedLogo = (ok and texture) or false
    end
    return loadedLogo or nil
end

local function drawTitle()
    local texture = logo()
    if texture then
        Graphics.CSurface.GL_BlitPixelImage(texture, LOGO_X, LOGO_Y, LOGO_SIZE, LOGO_SIZE,
            0, Graphics.GL_Color(1, 1, 1, LOGO_ALPHA), false)
    end
    Graphics.CSurface.GL_SetColor(color("title"))
    Graphics.freetype.easy_print(TITLE_FONT, TITLE_X, TITLE_Y, apT("hud.title"))
end
local WELCOME_MARGIN = 10
local BANNER_STEP = 14

script.on_render_event(
    Defines.RenderEvents.MAIN_MENU,
    function() end,
    function()
        pcall(function()
            if not atMainMenuHome() then
                if _G.apNotifyPlaceRun then _G.apNotifyPlaceRun() end
                return
            end
            local bottom = SCREEN_H - WELCOME_MARGIN - BANNER_STEP

            pcall(drawTitle)
            if _G.apNotifyPlaceMenu then _G.apNotifyPlaceMenu() end

            if hasSeed() then
                Graphics.CSurface.GL_SetColor(color("title"))
                Graphics.freetype.easy_print(10, 10, bottom - BANNER_STEP,
                    apT("hud.menu_line", { summary = summary() }))

                local goal, reached, subLine = goalLine()
                if goal ~= nil then
                    local subLines = {}
                    if subLine ~= nil then
                        subLines[#subLines + 1] = { text = subLine, tone = "dim" }
                    end
                    if _G.apAdvancedEditionOff and _G.apAdvancedEditionOff() then
                        subLines[#subLines + 1] = { text = apT("hud.advanced_off"), tone = "warn" }
                    end
                    local width = Graphics.freetype.easy_measureWidth(GOAL_FONT, goal)
                    for _, item in ipairs(subLines) do
                        width = math.max(width,
                            Graphics.freetype.easy_measureWidth(GOAL_SUB_FONT, item.text))
                    end
                    local frame = math.min(width + GOAL_PADDING * 2, SCREEN_W - 40)
                    local left = math.floor((SCREEN_W - frame) / 2)
                    local height = GOAL_H + #subLines * GOAL_SUB_H
                    Graphics.CSurface.GL_DrawRect(left, GOAL_Y, frame, height, color("panel"))
                    Graphics.CSurface.GL_DrawRect(left, GOAL_Y, frame, 2, color("border"))
                    Graphics.CSurface.GL_DrawRect(left, GOAL_Y + height - 2, frame, 2,
                        color("border"))
                    Graphics.CSurface.GL_SetColor(color(reached and "good" or "title"))
                    Graphics.freetype.easy_printCenter(GOAL_FONT, SCREEN_W / 2,
                        GOAL_Y + GOAL_BASELINE, goal)
                    for index, item in ipairs(subLines) do
                        Graphics.CSurface.GL_SetColor(color(item.tone))
                        Graphics.freetype.easy_printCenter(GOAL_SUB_FONT, SCREEN_W / 2,
                            GOAL_Y + GOAL_H - 4 + (index - 1) * GOAL_SUB_H, item.text)
                    end
                end
            end

            if _G.apModBanner then
                Graphics.CSurface.GL_SetColor(color("dim"))
                Graphics.freetype.easy_print(10, 10, bottom, _G.apModBanner())
            end
        end)
    end
)

script.on_internal_event(Defines.InternalEvents.ON_KEY_DOWN, function(key)
    if key ~= Defines.SDL.KEY_TAB then
        return Defines.Chain.CONTINUE
    end
    local okRunning, running = pcall(function() return Hyperspace.App.world.bStartedGame == true end)
    if not (okRunning and running) then
        return Defines.Chain.CONTINUE
    end
    open = not open
    return Defines.Chain.CONTINUE
end)

function apToggleHud()
    open = not open
    return open
end

log(TAG .. "dashboard loaded (TAB in-game)")
