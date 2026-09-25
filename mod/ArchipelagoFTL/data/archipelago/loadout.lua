local TAG = "[AP-menu] "

local function menuLog(message)
    log(TAG .. message)
end

local PANEL = { x = 240, y = 110, w = 800, h = 470 }
local COLUMN_W = 250
local COLUMN_GAP = 12
local LINE_H = 26
local PER_PAGE = 8
local LIST_TOP = 200
local DONE_BUTTON = { w = 160, h = 30 }
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
local taken = {}
local pages = {}

local function color(name)
    local shades = {
        panel = { 18, 22, 34, 235 }, border = { 150, 140, 220, 255 }, title = { 230, 225, 255, 255 },
        text = { 210, 210, 220, 255 }, dim = { 140, 140, 160, 255 }, good = { 120, 220, 140, 255 },
        focus = { 45, 50, 75, 255 },
    }
    local t = shades[name] or shades.text
    return Graphics.GL_Color(t[1] / 255, t[2] / 255, t[3] / 255, t[4] / 255)
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
end

local function geometry()
    local g = { columns = {} }
    for index, category in ipairs(CATEGORIES) do
        local x = PANEL.x + 20 + (index - 1) * (COLUMN_W + COLUMN_GAP)
        g.columns[category] = {
            x = x,
            previous = { x = x, y = LIST_TOP + PER_PAGE * LINE_H + 6, w = 30, h = 22 },
            next = { x = x + COLUMN_W - 30, y = LIST_TOP + PER_PAGE * LINE_H + 6, w = 30, h = 22 },
        }
    end
    g.done = {
        x = PANEL.x + (PANEL.w - DONE_BUTTON.w) / 2,
        y = PANEL.y + PANEL.h - DONE_BUTTON.h - 16,
        w = DONE_BUTTON.w, h = DONE_BUTTON.h,
    }
    return g
end

local function inside(box, x, y)
    return x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h
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
    Graphics.CSurface.GL_DrawRect(PANEL.x, PANEL.y, PANEL.w, PANEL.h, color("panel"))
    Graphics.CSurface.GL_DrawRectOutline(PANEL.x, PANEL.y, PANEL.w, PANEL.h, color("border"), 2)
    if logoTexture == nil then
        local ok, texture = pcall(function() return Hyperspace.Resources:GetImageId(LOGO) end)
        logoTexture = (ok and texture) or false
    end
    local titleX = PANEL.x + 20
    if logoTexture then
        Graphics.CSurface.GL_BlitPixelImage(logoTexture, titleX, PANEL.y + 10, LOGO_SIZE, LOGO_SIZE,
            0, Graphics.GL_Color(1, 1, 1, 1), false)
        titleX = titleX + LOGO_SIZE + 8
    end
    Graphics.CSurface.GL_SetColor(color("title"))
    Graphics.freetype.easy_printAutoShrink(18, titleX, PANEL.y + 16, PANEL.x + PANEL.w - 20 - titleX, false,
        apT("loadout.title"))
    Graphics.CSurface.GL_SetColor(color("dim"))
    Graphics.freetype.easy_printAutoShrink(10, PANEL.x + 20, PANEL.y + 46, PANEL.w - 40, false,
        apT("loadout.hint"))

    for _, category in ipairs(CATEGORIES) do
        local column = g.columns[category]
        local list = catalog[category]
        Graphics.CSurface.GL_SetColor(color("title"))
        Graphics.freetype.easy_printAutoShrink(13, column.x, LIST_TOP - 26, COLUMN_W, false,
            apT(COLUMN_KEYS[category]))
        if taken[category] then
            Graphics.CSurface.GL_SetColor(color("good"))
            Graphics.freetype.easy_printAutoShrink(10, column.x, LIST_TOP, COLUMN_W, false,
                apT("loadout.taken.short", { name = taken[category] }))
        elseif #list == 0 then
            Graphics.CSurface.GL_SetColor(color("dim"))
            Graphics.freetype.easy_printAutoShrink(10, column.x, LIST_TOP, COLUMN_W, false,
                apT(EMPTY_KEYS[category]))
        else
            local total = math.ceil(#list / PER_PAGE)
            local page = math.min(pages[category] or 1, total)
            for row = 1, PER_PAGE do
                local entry = list[(page - 1) * PER_PAGE + row]
                if entry == nil then break end
                local y = LIST_TOP + (row - 1) * LINE_H
                Graphics.CSurface.GL_DrawRect(column.x, y - 2, COLUMN_W, LINE_H - 4, color("focus"))
                Graphics.CSurface.GL_SetColor(color("text"))
                Graphics.freetype.easy_printAutoShrink(10, column.x + 6, y + 2, COLUMN_W - 12, false,
                    entry.label)
            end
            if total > 1 then
                for _, button in ipairs({ { column.previous, "<", page > 1 },
                                          { column.next, ">", page < total } }) do
                    local zone = button[1]
                    Graphics.CSurface.GL_DrawRect(zone.x, zone.y, zone.w, zone.h, color("focus"))
                    Graphics.CSurface.GL_DrawRectOutline(zone.x, zone.y, zone.w, zone.h,
                        color(button[3] and "border" or "dim"), 1)
                    Graphics.CSurface.GL_SetColor(color(button[3] and "title" or "dim"))
                    Graphics.freetype.easy_printCenter(12, zone.x + zone.w / 2, zone.y + 4, button[2])
                end
                Graphics.CSurface.GL_SetColor(color("dim"))
                Graphics.freetype.easy_printCenter(10, column.x + COLUMN_W / 2, column.previous.y + 5,
                    apT("loadout.page", { n = page, total = total }))
            end
        end
    end

    local done = g.done
    Graphics.CSurface.GL_DrawRect(done.x, done.y, done.w, done.h, color("focus"))
    Graphics.CSurface.GL_DrawRectOutline(done.x, done.y, done.w, done.h, color("border"), 1)
    Graphics.CSurface.GL_SetColor(color("title"))
    Graphics.freetype.easy_printAutoShrink(12, done.x + 10, done.y + 8, done.w - 20, false, apT("loadout.done"))
end

local function handleClick(x, y)
    local catalog = receivedCatalog()
    local g = geometry()
    if inside(g.done, x, y) then
        close("finished by the player")
        return true
    end
    for _, category in ipairs(CATEGORIES) do
        local column = g.columns[category]
        local list = catalog[category]
        local total = math.max(1, math.ceil(#list / PER_PAGE))
        if inside(column.previous, x, y) then
            pages[category] = math.max(1, (pages[category] or 1) - 1)
            return true
        end
        if inside(column.next, x, y) then
            pages[category] = math.min(total, (pages[category] or 1) + 1)
            return true
        end
        if not taken[category] and x >= column.x and x <= column.x + COLUMN_W then
            local row = math.floor((y - LIST_TOP + 2) / LINE_H) + 1
            if row >= 1 and row <= PER_PAGE then
                local entry = list[((pages[category] or 1) - 1) * PER_PAGE + row]
                if entry ~= nil then
                    take(category, entry)
                    return true
                end
            end
        end
    end
    return inside(PANEL, x, y)
end

script.on_init(function(newGame)
    taken = {}
    pages = {}
    open = false
    pending = newGame == true
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager ~= nil and shipManager.iShipId ~= 0 then
        return Defines.Chain.CONTINUE
    end
    close("first jump of the run")
    return Defines.Chain.CONTINUE
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    if not open then
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
        if pending and not open and uiFree() then
            if catalogEmpty(receivedCatalog()) then
                pending = false
            else
                open = true
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
