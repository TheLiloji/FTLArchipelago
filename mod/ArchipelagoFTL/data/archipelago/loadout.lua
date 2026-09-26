local TAG = "[AP-menu] "

local function menuLog(message)
    log(TAG .. message)
end

local ui = apUi

local PANEL = { x = 190, y = 86, w = 900, h = 548 }
local COLUMN_GAP = 16
local COLUMN_TOP = 90
local COLUMN_BOTTOM = 70
local ROW_H = 34
local ROW_GAP = 6
local LIST_OFFSET = 44
local PAGER_H = 24
local DONE_BUTTON = { w = 220, h = 34 }
local CATEGORIES = { "weapon", "drone", "crew" }
local COLUMN_KEYS = {
    weapon = "loadout.column.weapon", drone = "loadout.column.drone", crew = "loadout.column.crew",
}
local EMPTY_KEYS = {
    weapon = "loadout.empty.weapon", drone = "loadout.empty.drone", crew = "loadout.empty.crew",
}
local SKILL_KEYS = {
    pilot = "crew.skill.pilot", engines = "crew.skill.engines", shields = "crew.skill.shields",
    weapons = "crew.skill.weapons", repair = "crew.skill.repair", combat = "crew.skill.combat",
}

local LOGO = "ap_logo.png"
local LOGO_SIZE = 30

local pending = false
local logoTexture = nil
local open = false
local resumed = false
local taken = {}
local pages = {}

-- Kept in the run's save, so quitting to the main menu before choosing does not lose the menu.
local function remember(key, value)
    pcall(function() Hyperspace.playerVariables["ap_loadout_" .. key] = value end)
end

local function recalled(key)
    local ok, value = pcall(function() return Hyperspace.playerVariables["ap_loadout_" .. key] end)
    return ok and value == 1
end

local function blueprintTitle(name, family)
    local ok, text = pcall(function()
        local blueprints = Hyperspace.Blueprints
        local bp = family == "weapon" and blueprints:GetWeaponBlueprint(name)
            or blueprints:GetDroneBlueprint(name)
        return bp.desc.title:GetText()
    end)
    if ok and type(text) == "string" and text ~= "" then
        return text
    end
    return _G.apHumaniseId and _G.apHumaniseId(name) or tostring(name)
end

local function crewLabel(entry)
    local race = _G.apRaceLabel and _G.apRaceLabel(entry.race) or entry.race
    if entry.skill ~= nil and SKILL_KEYS[entry.skill] ~= nil then
        return race .. ", " .. apT(SKILL_KEYS[entry.skill])
    end
    return race
end

local function receivedCatalog()
    local catalog = { weapon = {}, drone = {}, crew = {} }
    local inventory = _G.apInventory or {}
    for name, count in pairs(inventory.shopAvailability or {}) do
        if (tonumber(count) or 0) >= 2 then
            local family = _G.apBlueprintFamily and _G.apBlueprintFamily(name)
            if family == "weapon" or family == "drone" then
                local list = catalog[family]
                list[#list + 1] = { bp = name, label = blueprintTitle(name, family) }
            end
        end
    end
    local seen = {}
    for race, state in pairs(inventory.crewProgress or {}) do
        if (tonumber(state.n) or 0) >= 2 then
            local entry = { race = race, skill = state.n >= 3 and state.skill or nil }
            seen[tostring(race) .. "/" .. tostring(entry.skill)] = true
            catalog.crew[#catalog.crew + 1] = {
                race = entry.race, skill = entry.skill, label = crewLabel(entry),
            }
        end
    end
    for _, entry in ipairs(inventory.crew or {}) do
        local key = tostring(entry.race) .. "/" .. tostring(entry.skill)
        if not seen[key] then
            seen[key] = true
            catalog.crew[#catalog.crew + 1] = {
                race = entry.race, skill = entry.skill, label = crewLabel(entry),
            }
        end
    end
    for _, category in ipairs(CATEGORIES) do
        table.sort(catalog[category], function(a, b) return a.label < b.label end)
    end
    return catalog
end

local function catalogEmpty(catalog)
    return #catalog.weapon == 0 and #catalog.drone == 0 and #catalog.crew == 0
end

local function uiFree()
    local ok, free = pcall(function()
        if Hyperspace.App.world.bStartedGame ~= true then return false end
        local gui = Hyperspace.App.gui
        return not (gui.choiceBoxOpen or gui.event_pause or gui.menu_pause)
    end)
    return ok and free == true
end

local function close(reason)
    if open then
        menuLog("menu closed: " .. reason)
    end
    open = false
    pending = false
    remember("open", 0)
end

local function geometry()
    local g = { columns = {} }
    local columnW = math.floor((PANEL.w - 40 - COLUMN_GAP * (#CATEGORIES - 1)) / #CATEGORIES)
    local columnH = PANEL.h - COLUMN_TOP - COLUMN_BOTTOM
    local perPage = math.floor((columnH - LIST_OFFSET - PAGER_H - 16) / (ROW_H + ROW_GAP))
    for index, category in ipairs(CATEGORIES) do
        local x = PANEL.x + 20 + (index - 1) * (columnW + COLUMN_GAP)
        local y = PANEL.y + COLUMN_TOP
        local pagerY = y + columnH - PAGER_H - 10
        g.columns[category] = {
            x = x, y = y, w = columnW, h = columnH,
            listY = y + LIST_OFFSET,
            previous = { x = x + 12, y = pagerY, w = 32, h = PAGER_H },
            next = { x = x + columnW - 44, y = pagerY, w = 32, h = PAGER_H },
        }
    end
    g.perPage = perPage
    g.done = {
        x = PANEL.x + math.floor((PANEL.w - DONE_BUTTON.w) / 2),
        y = PANEL.y + PANEL.h - DONE_BUTTON.h - 18,
        w = DONE_BUTTON.w, h = DONE_BUTTON.h,
    }
    return g
end

local function rowArea(column, row)
    return { x = column.x + 12, y = column.listY + (row - 1) * (ROW_H + ROW_GAP), w = column.w - 24, h = ROW_H }
end

function apLoadoutPoint(target, category, row)
    local g = geometry()
    if target == "done" then
        return g.done.x + g.done.w / 2, g.done.y + g.done.h / 2
    end
    local column = g.columns[category]
    local area = target == "row" and rowArea(column, row or 1) or column[target]
    return area.x + area.w / 2, area.y + area.h / 2
end

local function take(category, entry)
    local succeeded, reason
    if category == "crew" then
        succeeded, reason = _G.apRecruitCrew and _G.apRecruitCrew(entry.race, entry.skill)
    else
        succeeded = _G.apDeliverEquipment and _G.apDeliverEquipment(
            { kind = category, bp = entry.bp, display = entry.label, silent = true }) == true
    end
    if not succeeded then
        menuLog("cannot take " .. entry.label .. ": " .. tostring(reason))
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("loadout.refused", { name = entry.label }))
        end
        return
    end
    taken[category] = entry.label
    remember(category, 1)
    menuLog("taken for this run: " .. entry.label)
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT("loadout.taken", { name = entry.label }))
    end
    if taken.weapon and taken.drone and taken.crew then
        close("all three categories are taken")
    end
end

local function draw()
    local catalog = receivedCatalog()
    local g = geometry()
    ui.shade()
    ui.window(PANEL.x, PANEL.y, PANEL.w, PANEL.h)
    if logoTexture == nil then
        local ok, texture = pcall(function() return Hyperspace.Resources:GetImageId(LOGO) end)
        logoTexture = (ok and texture) or false
    end
    local titleX = PANEL.x + 20
    if logoTexture then
        Graphics.CSurface.GL_BlitPixelImage(logoTexture, titleX, PANEL.y + 14, LOGO_SIZE, LOGO_SIZE,
            0, Graphics.GL_Color(1, 1, 1, 1), false)
        titleX = titleX + LOGO_SIZE + 10
    end
    ui.text(24, titleX, PANEL.y + 14, PANEL.x + PANEL.w - 20 - titleX, "title", apT("loadout.title"))
    ui.text(10, PANEL.x + 20, PANEL.y + 56, PANEL.w - 40, "dim", apT("loadout.hint"))

    for _, category in ipairs(CATEGORIES) do
        local column = g.columns[category]
        local list = catalog[category]
        local chosen = taken[category]
        ui.rect(column.x, column.y, column.w, column.h, "card")
        ui.rect(column.x, column.y, column.w, 2, chosen and "good" or "border")
        local badge = chosen and apT("loadout.chosen") or apT("loadout.count", { n = #list })
        local badgeW = ui.width(9, badge)
        ui.text(13, column.x + 12, column.y + 14, column.w - 36 - badgeW, "title", apT(COLUMN_KEYS[category]))
        ui.textRight(9, column.x + column.w - 12, column.y + 18, badgeW, chosen and "good" or "dim", badge)

        if #list == 0 then
            ui.wrapped(10, column.x + 12, column.listY, column.w - 24, "dim", apT(EMPTY_KEYS[category]))
        else
            local total = math.ceil(#list / g.perPage)
            local page = math.min(pages[category] or 1, total)
            for row = 1, g.perPage do
                local entry = list[(page - 1) * g.perPage + row]
                if entry == nil then break end
                local area = rowArea(column, row)
                local isChosen = chosen ~= nil and entry.label == chosen
                local available = chosen == nil
                local over = available and ui.hovered(area)
                ui.rect(area.x, area.y, area.w, area.h, isChosen and "hover" or (over and "hover" or "window"))
                ui.rect(area.x, area.y, 3, area.h, isChosen and "good" or (over and "border" or "faint"))
                ui.text(10, area.x + 14, area.y + 10, area.w - 24,
                    isChosen and "good" or (available and "text" or "dim"), entry.label)
            end
            if total > 1 then
                ui.button(column.previous, apT("loadout.previous"), "secondary", page <= 1)
                ui.button(column.next, apT("loadout.next"), "secondary", page >= total)
                ui.textCenter(9, column.x + column.w / 2, column.previous.y + 6, column.w - 100, "dim",
                    apT("loadout.page", { n = page, total = total }))
            end
        end
    end

    ui.button(g.done, apT("loadout.done"), "primary")
end

function apLoadoutOpen()
    return open
end

local function handleClick(x, y)
    local catalog = receivedCatalog()
    local g = geometry()
    if ui.inside(g.done, x, y) then
        close("finished by the player")
        return true
    end
    for _, category in ipairs(CATEGORIES) do
        local column = g.columns[category]
        local list = catalog[category]
        local total = math.max(1, math.ceil(#list / g.perPage))
        if ui.inside(column.previous, x, y) then
            pages[category] = math.max(1, (pages[category] or 1) - 1)
            return true
        end
        if ui.inside(column.next, x, y) then
            pages[category] = math.min(total, (pages[category] or 1) + 1)
            return true
        end
        if not taken[category] then
            local page = math.min(pages[category] or 1, total)
            for row = 1, g.perPage do
                local entry = list[(page - 1) * g.perPage + row]
                if entry ~= nil and ui.inside(rowArea(column, row), x, y) then
                    take(category, entry)
                    return true
                end
            end
        end
    end
    return ui.inside(PANEL, x, y)
end

script.on_init(function(newGame)
    taken = {}
    pages = {}
    open = false
    pending = newGame == true
    resumed = newGame == false
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager ~= nil and shipManager.iShipId ~= 0 then
        return Defines.Chain.CONTINUE
    end
    close("first jump of the run")
    return Defines.Chain.CONTINUE
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    -- Hidden behind the pause menu or an event, the menu must not catch their clicks.
    if not open or not uiFree() then
        return Defines.Chain.CONTINUE
    end
    local ok, consumed = pcall(handleClick, apMousePosition(x, y))
    if ok and consumed then
        return Defines.Chain.PREEMPT
    end
    return Defines.Chain.CONTINUE
end)

script.on_render_event(
    Defines.RenderEvents.GUI_CONTAINER,
    function() end,
    function()
        if resumed and uiFree() then
            resumed = false
            pending = recalled("open")
            for _, category in ipairs(CATEGORIES) do
                taken[category] = recalled(category) or nil
            end
        end
        if pending and not open and uiFree() then
            if catalogEmpty(receivedCatalog()) then
                pending = false
            else
                open = true
                remember("open", 1)
                menuLog("start-of-run menu opened")
            end
        end
        if open and uiFree() then
            local ok, err = pcall(draw)
            if not ok then
                close("render error: " .. tostring(err))
            end
        end
    end
)

menuLog("start-of-run menu loaded")
