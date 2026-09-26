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

local function summary(withoutChecks)
    local info = snapshot()
    local parts = {}

    if info.checks and not withoutChecks then
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

function apSeedSummaryLine()
    return summary(true)
end

local function shipList(layouts)
    local names = {}
    for _, layout in ipairs(layouts) do
        names[#names + 1] = _G.apShipLabel and apShipLabel(layout) or layout
    end
    return table.concat(names, ", ")
end

-- Shared by the main menu and the dashboard: a headline, then the rules in plain words.
function apGoalText()
    local seed = _G.apSeedSummary and _G.apSeedSummary() or nil
    local goal = seed and seed.goal or nil
    if goal == nil or goal.kind ~= "victories" then
        return nil
    end
    local total = goal.layouts and #goal.layouts or (goal.count or 1)
    local progress = _G.apGoalProgress and _G.apGoalProgress() or nil
    local lines = {}

    local headline
    if progress == nil or (progress.done == 0 and not progress.reached) then
        headline = apT("hud.goal", { n = total })
    elseif progress.reached then
        headline = apT("hud.goal.done", { done = progress.total })
    elseif progress.done >= progress.total and _G.apGoalArchivesMissing and apGoalArchivesMissing() > 0 then
        headline = apT("hud.goal.archives_missing", { n = apGoalArchivesMissing() })
    else
        headline = apT("hud.goal.progress", { done = progress.done, total = progress.total })
    end

    if goal.layouts ~= nil then
        lines[#lines + 1] = { text = apT("hud.goal.rule.layouts", { ships = shipList(goal.layouts) }), tone = "dim" }
    elseif total > 1 then
        lines[#lines + 1] = { text = apT("hud.goal.rule"), tone = "dim" }
    end

    local difficulty = _G.apGoalDifficulty and _G.apGoalDifficulty() or nil
    local rules = difficulty and apT("hud.goal.difficulty", { difficulty = difficulty })
        or apT("hud.goal.difficulty.any")
    local archives = _G.apGoalArchives and _G.apGoalArchives() or nil
    if archives ~= nil then
        rules = rules .. "   " .. apT("hud.goal.archives",
            { done = math.min(archives, _G.apReceivedArchives and _G.apReceivedArchives() or 0), total = archives })
    end
    lines[#lines + 1] = { text = rules, tone = "dim" }

    local won = _G.apGoalWonWith and apGoalWonWith() or {}
    if #won > 0 and progress ~= nil and not progress.reached then
        lines[#lines + 1] = { text = apT("hud.goal.won", { ships = shipList(won) }), tone = "good" }
    end

    return {
        headline = headline,
        reached = progress ~= nil and progress.reached,
        lines = lines,
        done = progress and progress.done or 0,
        total = progress and progress.total or total,
    }
end

local TUTORIAL_W = 660
local TUTORIAL_H = 72
local TUTORIAL_Y = math.floor((720 - TUTORIAL_H) / 2)
local TUTORIAL_FONT = 24

function apDrawTutorialBanner()
    if not (_G.apTutorialRunning and apTutorialRunning()) or (_G.apPauseMenuOpen and apPauseMenuOpen()) then
        return
    end
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
        if not (_G.apDashboardOpen and apDashboardOpen()) then
            pcall(apDrawTutorialBanner)
        end
    end
)

local SCREEN_H = 720
local SCREEN_W = 1280
local GOAL_FONT = 24
local GOAL_X = 62
local GOAL_Y = 182
local GOAL_MAX_RIGHT = 850
local GOAL_H = 52
local GOAL_BASELINE = 0
local GOAL_PADDING = 28
local GOAL_SUB_FONT = 10
local GOAL_SUB_H = 22

local TITLE_FONT = 63
local TITLE_Y = 92
local LOGO = "ap_logo.png"
local LOGO_SIZE = 120
local LOGO_X = 62
local LOGO_Y = 40
local LOGO_ALPHA = 1
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

            _G.apGoalBoxBottom = nil
            local questionOpen = _G.apConnectQuestionOpen and apConnectQuestionOpen()
            if hasSeed() and not questionOpen then

                local goalText = apGoalText()
                if goalText ~= nil then
                    local goal, reached, subLines = goalText.headline, goalText.reached, goalText.lines
                    if _G.apAdvancedEditionOff and _G.apAdvancedEditionOff() then
                        subLines[#subLines + 1] = { text = apT("hud.advanced_off"), tone = "warn" }
                    end
                    local goalFont = apUi.fittingFont({ GOAL_FONT, 18, 12 },
                        GOAL_MAX_RIGHT - GOAL_X - GOAL_PADDING * 2, goal)
                    local width = Graphics.freetype.easy_measureWidth(goalFont, goal)
                    for _, item in ipairs(subLines) do
                        width = math.max(width,
                            Graphics.freetype.easy_measureWidth(GOAL_SUB_FONT, item.text))
                    end
                    local frame = math.min(width + GOAL_PADDING * 2, GOAL_MAX_RIGHT - GOAL_X)
                    local left = GOAL_X
                    local center = left + frame / 2
                    local height = GOAL_H + #subLines * GOAL_SUB_H
                    _G.apGoalBoxBottom = GOAL_Y + height
                    Graphics.CSurface.GL_DrawRect(left, GOAL_Y, frame, height, color("panel"))
                    Graphics.CSurface.GL_DrawRect(left, GOAL_Y, frame, 2, color("border"))
                    Graphics.CSurface.GL_DrawRect(left, GOAL_Y + height - 2, frame, 2,
                        color("border"))
                    Graphics.CSurface.GL_SetColor(color(reached and "good" or "title"))
                    Graphics.freetype.easy_printCenter(goalFont, center,
                        GOAL_Y + GOAL_BASELINE + (GOAL_FONT - goalFont) // 2, goal)
                    for index, item in ipairs(subLines) do
                        Graphics.CSurface.GL_SetColor(color(item.tone))
                        Graphics.freetype.easy_printCenter(GOAL_SUB_FONT, center,
                            GOAL_Y + GOAL_H - 4 + (index - 1) * GOAL_SUB_H, item.text)
                    end
                end
            end

            if _G.apModBanner then
                apUi.text(9, 24, bottom + 4, 372, "dim", _G.apModBanner())
            end
            if _G.apDrawToasts and not (_G.apConnectQuestionOpen and apConnectQuestionOpen()) then
                pcall(apDrawToasts)
            end
        end)
    end
)

log(TAG .. "main menu title and goal loaded")
