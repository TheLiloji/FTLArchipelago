local TAG = "[AP-dash] "


local WINDOW = { x = 140, y = 56, w = 1000, h = 608 }
local HEADER_H = 46
local TAB_Y, TAB_H = 52, 30
local CONTENT_Y = 96
local FOOTER_H = 30
local PAD = 20
local GAP = 12

local PAGES = { "overview", "ships", "systems", "checks", "journal" }
local PAGE_TITLE = {
    overview = "dash.tab.overview", ships = "dash.tab.ships", systems = "dash.tab.systems",
    checks = "dash.tab.checks", journal = "dash.tab.journal",
}

local CATEGORIES = { "shop", "sector", "victory", "achievement", "system", "crew", "other" }
local CATEGORY_TITLE = {
    shop = "dash.cat.shop", sector = "dash.cat.sector", victory = "dash.cat.victory",
    achievement = "dash.cat.achievement", system = "dash.cat.system", crew = "dash.cat.crew",
    other = "dash.cat.other",
}

local HISTORY_MAX = 200

local state = {
    open = false,
    page = 1,
    category = 1,
    scroll = {},
    wasPaused = nil,
    areas = {},
}

_G.apReceivedHistory = _G.apReceivedHistory or {}

local function dashLog(message)
    log(TAG .. message)
end

local ui = apUi
local color, rect, outline, width = ui.color, ui.rect, ui.outline, ui.width
local text, textRight, textCenter, bar = ui.text, ui.textRight, ui.textCenter, ui.bar
local inside, mouse, hovered = ui.inside, ui.mouse, ui.hovered

local function card(x, y, w, h, tone)
    rect(x, y, w, h, tone or "card")
end

local function label(x, y, w, key, params)
    text(9, x, y, w, "dim", apT(key, params))
end

local function inside(area, x, y)
    return area ~= nil and x >= area.x and x <= area.x + area.w and y >= area.y and y <= area.y + area.h
end

local function mouse()
    if _G.apMousePosition then
        return apMousePosition(-1, -1)
    end
    return -1, -1
end

local function hovered(area)
    local mx, my = mouse()
    return inside(area, mx, my)
end


local function hasSeed()
    local contract = _G.apContractState
    return contract ~= nil and contract.connected == true
end

local function categoryOf(key)
    key = tostring(key)
    if key:sub(1, 5) == "shop:" then return "shop" end
    if key:sub(1, 4) == "sys:" then return "system" end
    if key:sub(1, 5) == "crew:" then return "crew" end
    if key:sub(1, 4) == "ach:" then return "achievement" end
    if key:find(":sector:", 1, true) then return "sector" end
    if key:sub(-8) == ":victory" then return "victory" end
    if key:find(":ach:", 1, true) or key:find("ACH_", 1, true) then return "achievement" end
    return "other"
end

local function sentCheck(key)
    return _G.apCheckAlreadySent ~= nil and apCheckAlreadySent(key) == true
end

local function checkBook()
    local book = { total = 0, done = 0, byCategory = {} }
    for _, name in ipairs(CATEGORIES) do
        book.byCategory[name] = { total = 0, done = 0, remaining = {} }
    end
    local names = ((_G.apContractState or {}).locNames) or {}
    for key, name in pairs(names) do
        local entry = book.byCategory[categoryOf(key)]
        entry.total = entry.total + 1
        book.total = book.total + 1
        if sentCheck(key) then
            entry.done = entry.done + 1
            book.done = book.done + 1
        else
            entry.remaining[#entry.remaining + 1] = { key = key, name = tostring(name) }
        end
    end
    local function natural(name)
        return (name:gsub("%d+", function(digits) return string.format("%09d", tonumber(digits)) end))
    end
    for _, entry in pairs(book.byCategory) do
        table.sort(entry.remaining, function(a, b) return natural(a.name) < natural(b.name) end)
    end
    return book
end

local function layoutName(base, index)
    local suffix = ((_G.apGameData or {}).variantSuffix or {})[index] or ""
    return base .. suffix
end

local function unlockedLayouts()
    local set = {}
    for _, name in ipairs(((_G.apInventory or {}).ships) or {}) do
        set[name] = true
    end
    return set
end

local function shipRows()
    local unlocked = unlockedLayouts()
    local book = ((_G.apContractState or {}).locNames) or {}
    local rows, open, total = {}, 0, 0
    for _, ship in ipairs(((_G.apGameData or {}).ships) or {}) do
        local row = { base = ship.name, layouts = {}, remaining = 0 }
        row.label = _G.apShipLabel and apShipLabel(ship.name) or ship.name
        for index = 0, (ship.layouts or 1) - 1 do
            local name = layoutName(ship.name, index)
            row.layouts[#row.layouts + 1] = { name = name, letter = string.char(65 + index),
                                              unlocked = unlocked[name] == true }
            total = total + 1
            if unlocked[name] then open = open + 1 end
        end
        for key in pairs(book) do
            local prefix = tostring(key):match("^(PLAYER_SHIP_[A-Z]+)")
            if prefix == ship.name and not sentCheck(key) then
                row.remaining = row.remaining + 1
            end
        end
        rows[#rows + 1] = row
    end
    return rows, open, total
end

local function systemsAboard()
    local aboard = {}
    pcall(function()
        local list = Hyperspace.ships.player.vSystemList
        for i = 0, list:size() - 1 do
            aboard[Hyperspace.ShipSystem.SystemIdToName(list[i].iSystemType)] = true
        end
    end)
    return aboard
end

local function systemRows()
    local aboard = systemsAboard()
    local inventory = _G.apInventory or {}
    local caps = inventory.systemCaps or {}
    local starts = inventory.startingUpgrades or {}
    local rows, unlocked = {}, 0
    for _, system in ipairs(((_G.apGameData or {}).systems) or {}) do
        local cap = caps[system.id] or 0
        local total = _G.apSystemCapTotal and apSystemCapTotal(system.id) or nil
        rows[#rows + 1] = {
            name = _G.apSystemLabel and apSystemLabel(system.id) or system.id,
            locked = cap <= 0,
            aboard = aboard[system.id] == true,
            received = math.max(0, cap - 1),
            total = total,
            start = starts[system.id] or 0,
        }
        if cap > 0 then unlocked = unlocked + 1 end
    end
    return rows, unlocked, starts.reactor or 0
end

local function startLevels()
    local levels = 0
    for name, count in pairs(((_G.apInventory or {}).startingUpgrades) or {}) do
        if name ~= "reactor" and count and count > 0 then
            levels = levels + count
        end
    end
    return levels
end

local function statusLine()
    if _G.apSoloEnabled then
        return apT("dash.status.solo"), "good"
    end
    if _G.apNetConnected and apNetConnected() and hasSeed() then
        local slot = _G.apOwnSlotName and apOwnSlotName() or "?"
        return apT("dash.status.online", { slot = tostring(slot) }), "good"
    end
    if hasSeed() then
        return apT("dash.status.offline"), "warn"
    end
    return apT("dash.status.noseed"), "dim"
end

local JOURNAL_SAVED = 40
local journalFor = nil

local function journalKey()
    return "ap_journal_" .. tostring(_G.apSeedFingerprint and apSeedFingerprint() or 0)
end

-- The journal is kept per seed in the network module's memory, so it survives a restart.
local function loadJournal()
    local key = journalKey()
    if not hasSeed() or (journalFor == key and #_G.apReceivedHistory > 0) then
        return
    end
    journalFor = key
    local stored = _G.apNetRecallText and apNetRecallText(key) or ""
    local history = {}
    for entry in stored:gmatch("[^\30]+") do
        local item, sender = entry:match("^([^\31]*)\31?(.*)$")
        if item and item ~= "" then
            history[#history + 1] = { item = item, sender = sender ~= "" and sender or nil }
        end
    end
    _G.apReceivedHistory = history
end

local function saveJournal()
    if not _G.apNetRememberText then return end
    local parts = {}
    for index = 1, math.min(JOURNAL_SAVED, #_G.apReceivedHistory) do
        local entry = _G.apReceivedHistory[index]
        parts[#parts + 1] = entry.item .. "\31" .. (entry.sender or "")
    end
    apNetRememberText(journalKey(), table.concat(parts, "\30"))
end

-- The server sends every item again at each connection; its index tells the new ones apart.
local function alreadyInJournal(index)
    if index == nil or index < 0 or not _G.apNetRecall then
        return false
    end
    local key = journalKey() .. "_last"
    if index < apNetRecall(key) then
        return true
    end
    apNetRemember(key, index + 1)
    return false
end

function apRecordReceived(itemName, sender, index)
    loadJournal()
    if alreadyInJournal(index) then
        return
    end
    local own = _G.apOwnSlotName and apOwnSlotName() or nil
    if sender ~= nil and own ~= nil and tostring(sender) == tostring(own) then
        sender = nil
    end
    local history = _G.apReceivedHistory
    table.insert(history, 1, { item = tostring(itemName), sender = sender })
    while #history > HISTORY_MAX do
        table.remove(history)
    end
    saveJournal()
end


local function scrollList(id, area, rows, lineH, draw)
    local visible = math.max(1, math.floor(area.h / lineH))
    local maxOffset = math.max(0, #rows - visible)
    local offset = math.min(state.scroll[id] or 0, maxOffset)
    state.scroll[id] = offset
    state.areas["scroll:" .. id] = { x = area.x, y = area.y, w = area.w, h = area.h, max = maxOffset }
    for i = 1, visible do
        local row = rows[offset + i]
        if row == nil then break end
        draw(row, area.x, area.y + (i - 1) * lineH, area.w - (maxOffset > 0 and 10 or 0))
    end
    if maxOffset > 0 then
        local trackH = area.h
        local thumbH = math.max(20, math.floor(trackH * visible / #rows))
        local thumbY = area.y + math.floor((trackH - thumbH) * offset / maxOffset)
        rect(area.x + area.w - 4, area.y, 4, trackH, "faint")
        rect(area.x + area.w - 4, thumbY, 4, thumbH, "border")
    end
end


local function drawNoSeed(x, y, w)
    text(12, x + 16, y + 14, w - 32, "warn", apT("hud.no_seed"))
    Graphics.CSurface.GL_SetColor(color("dim"))
    Graphics.freetype.easy_printAutoNewlines(10, x + 16, y + 44, w - 32,
        apT("hud.no_seed.how") .. "\n" .. apT("hud.no_seed.solo"))
end

local function drawGoalCard(x, y, w, h)
    card(x, y, w, h)
    label(x + 16, y + 10, w - 32, "dash.goal.title")
    local goal = apGoalText()
    if goal == nil then
        text(12, x + 16, y + 36, w - 32, "dim", apT("dash.goal.unknown"))
        return
    end
    local font = ui.fittingFont({ 18, 12 }, w - 32, goal.headline)
    text(font, x + 16, y + (font == 18 and 32 or 36), w - 32, goal.reached and "good" or "title", goal.headline)
    local lineY = y + 60
    for _, line in ipairs(goal.lines) do
        text(9, x + 16, lineY, w - 32, line.tone, line.text)
        lineY = lineY + 14
    end
    if _G.apAdvancedEditionOff and apAdvancedEditionOff() then
        text(9, x + 16, lineY, w - 32, "warn", apT("hud.advanced_off"))
    end
    bar(x + 16, y + h - 18, w - 32, 6, goal.total > 0 and goal.done / goal.total or 0,
        goal.reached and "good" or "border")
end

local function drawChecksCard(x, y, w, h, book)
    card(x, y, w, h)
    label(x + 16, y + 10, w - 32, "dash.checks.title")
    if book.total == 0 then
        text(12, x + 16, y + 34, w - 32, "dim", apT("hud.not_connected"))
        return
    end
    local done = book.done >= book.total
    text(24, x + 16, y + 26, w - 140, done and "good" or "text",
        apT("dash.checks.count", { done = book.done, total = book.total }))
    textRight(12, x + w - 16, y + 32, 120, "dim",
        apT("dash.percent", { n = math.floor(100 * book.done / book.total) }))
    bar(x + 16, y + 64, w - 32, 6, book.done / book.total, done and "good" or "border")
    local notes = {}
    local waiting = _G.apPendingCheckCount and apPendingCheckCount() or 0
    if waiting > 0 then notes[#notes + 1] = apT("hud.checks_waiting", { n = waiting }) end
    local online = _G.apNetState and _G.apNetState.connected
    if not online and not _G.apSoloEnabled then notes[#notes + 1] = apT("hud.link_lost") end
    if #notes > 0 then
        text(9, x + 16, y + 76, w - 32, "warn", table.concat(notes, "   "))
    end
end

local function drawTile(x, y, w, h, key, value, sub, tone)
    card(x, y, w, h)
    label(x + 12, y + 10, w - 24, key)
    local font = ui.fittingFont({ 24, 18, 13 }, w - 24, value)
    text(font, x + 12, y + 30 + math.floor((24 - font) / 2), w - 24, tone or "text", value)
    if sub then
        text(9, x + 12, y + h - 22, w - 24, "dim", sub)
    end
end

local function drawCategoriesCard(x, y, w, h, book)
    card(x, y, w, h)
    label(x + 16, y + 10, w - 32, "dash.bycat.title")
    local shown = {}
    for _, name in ipairs(CATEGORIES) do
        if book.byCategory[name].total > 0 then shown[#shown + 1] = name end
    end
    if #shown == 0 then
        text(10, x + 16, y + 32, w - 32, "dim", apT("dash.checks.none"))
        return
    end
    local perColumn = math.ceil(#shown / 2)
    local colW = math.floor((w - 32 - 24) / 2)
    local rowH = math.floor((h - 34) / math.max(1, perColumn))
    for index, name in ipairs(shown) do
        local entry = book.byCategory[name]
        local col = (index - 1) // perColumn
        local rx = x + 16 + col * (colW + 24)
        local ry = y + 30 + ((index - 1) % perColumn) * rowH
        local complete = entry.done >= entry.total
        local count = apT("dash.fraction", { done = entry.done, total = entry.total })
        local countW = width(9, count)
        text(9, rx, ry, colW - countW - 8, complete and "good" or "text", apT(CATEGORY_TITLE[name]))
        textRight(9, rx + colW, ry, countW, complete and "good" or "dim", count)
        bar(rx, ry + 14, colW, 3, entry.done / entry.total, complete and "good" or "border")
    end
end

local function drawLinksCard(x, y, w, h)
    card(x, y, w, h)
    label(x + 16, y + 10, w - 32, "dash.links.title")
    local seed = _G.apSeedSummary and apSeedSummary() or nil
    local links = {}
    if seed then
        if seed.links.death then links[#links + 1] = "DeathLink" end
        if seed.links.energy then links[#links + 1] = "EnergyLink" end
        if seed.links.trap then links[#links + 1] = "TrapLink" end
    end
    if #links == 0 then
        text(10, x + 16, y + 34, w - 32, "dim", apT("dash.links.none"))
        return
    end
    local chipX = x + 16
    for _, name in ipairs(links) do
        local chipW = width(10, name) + 20
        if chipX + chipW > x + w - 16 then break end
        rect(chipX, y + 32, chipW, 22, "faint")
        rect(chipX, y + 32, 3, 22, "good")
        text(10, chipX + 11, y + 36, chipW - 14, "text", name)
        chipX = chipX + chipW + 8
    end
end

local function drawRecentCard(x, y, w, h)
    card(x, y, w, h)
    label(x + 16, y + 10, w - 32, "dash.recent.title")
    local history = _G.apReceivedHistory or {}
    if #history == 0 then
        Graphics.CSurface.GL_SetColor(color("dim"))
        Graphics.freetype.easy_printAutoNewlines(10, x + 16, y + 34, w - 32, apT("dash.recent.none"))
        return
    end
    local lineY = y + 32
    for i = 1, #history do
        if lineY + 16 > y + h - 8 then break end
        local entry = history[i]
        local senderW = 0
        if entry.sender and entry.sender ~= "" then
            local sender = apT("dash.recent.from", { sender = entry.sender })
            senderW = math.min(width(9, sender), math.floor((w - 32) * 0.4))
            textRight(9, x + w - 16, lineY + 2, senderW, "dim", sender)
        end
        text(10, x + 16, lineY, w - 40 - senderW, i == 1 and "good" or "text", entry.item)
        lineY = lineY + 20
    end
end

local function drawHintCard(x, y, w, h)
    card(x, y, w, h)
    label(x + 16, y + 10, w - 32, "hud.hints")
    local hints = _G.apHintsForDisplay and apHintsForDisplay(1) or {}
    Graphics.CSurface.GL_SetColor(color(#hints > 0 and "text" or "dim"))
    Graphics.freetype.easy_printAutoNewlines(10, x + 16, y + 32, w - 32,
        #hints > 0 and apHintLine(hints[1]) or apT("dash.hints.none"))
end

local function drawOverview(x, y, w, h)
    local left = math.floor(w * 0.58)
    local right = w - left - PAD
    local rx = x + left + PAD
    local book = checkBook()

    local goalH, checksH, tileH = 118, 96, 96
    if hasSeed() then
        drawGoalCard(x, y, left, goalH)
    else
        card(x, y, left, goalH)
        drawNoSeed(x, y, left)
    end
    drawChecksCard(x, y + goalH + GAP, left, checksH, book)
    local catY = y + goalH + GAP + checksH + GAP
    local tileY = y + h - tileH
    drawCategoriesCard(x, catY, left, tileY - GAP - catY, book)
    local tileW = math.floor((left - GAP * 3) / 4)
    local _, openLayouts, totalLayouts = shipRows()
    local _, unlockedSystems, reactor = systemRows()
    local systemsTotal = #(((_G.apGameData or {}).systems) or {})
    drawTile(x, tileY, tileW, tileH, "dash.tile.ships",
        apT("dash.fraction", { done = openLayouts, total = totalLayouts }), nil)
    drawTile(x + (tileW + GAP), tileY, tileW, tileH, "dash.tile.systems",
        apT("dash.fraction", { done = unlockedSystems, total = systemsTotal }), nil)
    drawTile(x + (tileW + GAP) * 2, tileY, tileW, tileH, "dash.tile.starts",
        apT("dash.plus", { n = startLevels() + reactor }),
        reactor > 0 and apT("dash.tile.reactor", { n = reactor }) or nil, "good")
    local archives = _G.apGoalArchives and apGoalArchives() or nil
    if archives ~= nil then
        drawTile(x + (tileW + GAP) * 3, tileY, tileW, tileH, "dash.tile.archives",
            apT("dash.fraction", { done = math.min(archives, _G.apReceivedArchives and apReceivedArchives() or 0),
                                   total = archives }), nil)
    else
        local hintCount = #(_G.apHintsForDisplay and apHintsForDisplay(999) or {})
        drawTile(x + (tileW + GAP) * 3, tileY, tileW, tileH, "dash.tile.hints", tostring(hintCount), nil)
    end

    drawLinksCard(rx, y, right, 70)
    local hintH = 110
    drawRecentCard(rx, y + 70 + GAP, right, h - 70 - GAP - hintH - GAP)
    drawHintCard(rx, y + h - hintH, right, hintH)
end

local function drawShips(x, y, w, h)
    local rows, open, total = shipRows()
    text(12, x, y, w, "title", apT("dash.ships.header", { done = open, total = total }))
    local top = y + 30
    local columns = 2
    local perColumn = math.ceil(#rows / columns)
    local cardW = math.floor((w - GAP) / columns)
    local cardH = math.floor((h - 30 - GAP * (perColumn - 1)) / math.max(1, perColumn))
    for index, row in ipairs(rows) do
        local col = (index - 1) // perColumn
        local line = (index - 1) % perColumn
        local cx = x + col * (cardW + GAP)
        local cy = top + line * (cardH + GAP)
        local any = false
        for _, layout in ipairs(row.layouts) do any = any or layout.unlocked end
        card(cx, cy, cardW, cardH)
        rect(cx, cy, 3, cardH, any and "good" or "faint")
        local chipW, chipH = 64, 22
        local chipsW = #row.layouts * chipW + (#row.layouts - 1) * 6
        text(12, cx + 16, cy + 10, cardW - chipsW - 44, any and "text" or "dim", row.label)
        local remaining = row.remaining > 0 and apT("dash.ships.remaining", { n = row.remaining })
            or apT("dash.ships.clear")
        text(9, cx + 16, cy + cardH - 22, cardW - chipsW - 44, "dim", remaining)
        local chipX = cx + cardW - 16 - chipsW
        local chipY = cy + math.floor((cardH - chipH) / 2)
        for _, layout in ipairs(row.layouts) do
            if layout.unlocked then
                rect(chipX, chipY, chipW, chipH, "faint")
                rect(chipX, chipY + chipH - 3, chipW, 3, "good")
            else
                outline(chipX, chipY, chipW, chipH, "faint", 1)
            end
            textCenter(10, chipX + chipW / 2, chipY + 4, chipW - 8,
                layout.unlocked and "text" or "dim", apT("dash.ships.type", { letter = layout.letter }))
            chipX = chipX + chipW + 6
        end
    end
end

local function drawSystems(x, y, w, h)
    local rows, unlocked, reactor = systemRows()
    text(12, x, y, w - 260, "title", apT("dash.systems.header", { done = unlocked, total = #rows }))
    if reactor > 0 then
        textRight(10, x + w, y + 3, 250, "good", apT("dash.systems.reactor", { n = reactor }))
    end
    local top = y + 30
    local columns = 4
    local rowsCount = math.ceil(#rows / columns)
    local cardW = math.floor((w - GAP * (columns - 1)) / columns)
    local cardH = math.floor((h - 30 - GAP * (rowsCount - 1)) / math.max(1, rowsCount))
    for index, row in ipairs(rows) do
        local col = (index - 1) % columns
        local line = (index - 1) // columns
        local cx = x + col * (cardW + GAP)
        local cy = top + line * (cardH + GAP)
        card(cx, cy, cardW, cardH)
        local known = row.total ~= nil and row.total > 0
        local full = known and row.received >= row.total
        rect(cx, cy, 3, cardH, row.locked and "faint" or (full and "good" or "border"))
        text(10, cx + 14, cy + 10, cardW - 26, row.locked and "dim" or "text", row.name)
        local status
        if row.locked and row.aboard then
            status = apT("dash.system.aboard")
        elseif row.locked then
            status = apT("dash.system.locked")
        elseif full then
            status = apT("hud.system.max")
        elseif known then
            status = apT("hud.system.progress", { received = row.received, total = row.total })
        else
            status = apT("hud.system.received", { n = row.received })
        end
        text(9, cx + 14, cy + 28, cardW - 26, row.locked and "dim" or (full and "good" or "dim"), status)
        if known and not row.locked then
            local pipGap = 3
            local pipW = math.max(4, math.min(18, math.floor((cardW - 28 - pipGap * (row.total - 1)) / row.total)))
            for pip = 1, row.total do
                rect(cx + 14 + (pip - 1) * (pipW + pipGap), cy + 48, pipW, 8,
                    pip <= row.received and (full and "good" or "border") or "faint")
            end
        end
        if row.start > 0 then
            text(9, cx + 14, cy + cardH - 20, cardW - 26, "good", apT("dash.system.start", { n = row.start }))
        end
    end
end

local function drawChecks(x, y, w, h)
    local book = checkBook()
    if book.total == 0 then
        text(12, x, y, w, "dim", apT("dash.checks.none"))
        return
    end
    local listW = 300
    local rowH = 46
    local shown = {}
    for _, name in ipairs(CATEGORIES) do
        if book.byCategory[name].total > 0 then shown[#shown + 1] = name end
    end
    if state.category > #shown then state.category = 1 end
    for index, name in ipairs(shown) do
        local entry = book.byCategory[name]
        local area = { x = x, y = y + (index - 1) * (rowH + 6), w = listW, h = rowH }
        state.areas["cat:" .. index] = area
        local selected = index == state.category
        card(area.x, area.y, area.w, area.h, (selected or hovered(area)) and "hover" or "card")
        if selected then rect(area.x, area.y, 3, area.h, "border") end
        local complete = entry.done >= entry.total
        local count = apT("dash.fraction", { done = entry.done, total = entry.total })
        local countW = width(10, count)
        text(10, area.x + 14, area.y + 8, listW - 34 - countW, complete and "good" or "text",
            apT(CATEGORY_TITLE[name]))
        textRight(10, area.x + listW - 12, area.y + 8, countW, complete and "good" or "dim", count)
        bar(area.x + 14, area.y + rowH - 14, listW - 28, 5, entry.done / entry.total,
            complete and "good" or "border")
    end

    local px = x + listW + PAD
    local pw = w - listW - PAD
    local current = book.byCategory[shown[state.category]]
    card(px, y, pw, h)
    text(12, px + 16, y + 12, pw - 180, "title", apT(CATEGORY_TITLE[shown[state.category]]))
    textRight(10, px + pw - 16, y + 15, 170, "dim", apT("dash.checks.remaining", { n = #current.remaining }))
    if #current.remaining == 0 then
        text(10, px + 16, y + 48, pw - 32, "good", apT("dash.checks.all_done"))
        return
    end
    scrollList("checks:" .. shown[state.category], { x = px + 16, y = y + 44, w = pw - 32, h = h - 56 },
        current.remaining, 20, function(row, rx, ry, rw)
            rect(rx, ry + 6, 5, 5, "faint")
            text(10, rx + 14, ry, rw - 14, "text", row.name)
        end)
end

local function drawJournal(x, y, w, h)
    local colW = math.floor((w - PAD) / 2)
    card(x, y, colW, h)
    text(12, x + 16, y + 12, colW - 32, "title", apT("dash.journal.items"))
    local history = _G.apReceivedHistory or {}
    if #history == 0 then
        Graphics.CSurface.GL_SetColor(color("dim"))
        Graphics.freetype.easy_printAutoNewlines(10, x + 16, y + 44, colW - 32, apT("dash.recent.none"))
    else
        scrollList("journal:items", { x = x + 16, y = y + 44, w = colW - 32, h = h - 56 }, history, 20,
            function(entry, rx, ry, rw)
                local senderW = 0
                if entry.sender and entry.sender ~= "" then
                    local sender = apT("dash.recent.from", { sender = entry.sender })
                    senderW = math.min(width(9, sender), math.floor(rw * 0.4))
                    textRight(9, rx + rw, ry + 2, senderW, "dim", sender)
                end
                text(10, rx, ry, rw - senderW - 8, "text", entry.item)
            end)
    end

    local hx = x + colW + PAD
    card(hx, y, colW, h)
    text(12, hx + 16, y + 12, colW - 32, "title", apT("hud.hints"))
    local hints = _G.apHintsForDisplay and apHintsForDisplay(200) or {}
    if #hints == 0 then
        Graphics.CSurface.GL_SetColor(color("dim"))
        Graphics.freetype.easy_printAutoNewlines(10, hx + 16, y + 44, colW - 32, apT("dash.hints.none"))
    else
        -- Location and item names are long: each hint gets two lines rather than an ellipsis.
        scrollList("journal:hints", { x = hx + 16, y = y + 44, w = colW - 32, h = h - 56 }, hints, 34,
            function(hint, rx, ry, rw)
                ui.wrapped(10, rx, ry, rw, "text", apHintLine(hint))
            end)
    end
end

local DRAW_PAGE = {
    overview = drawOverview,
    ships = drawShips,
    systems = drawSystems,
    checks = drawChecks,
    journal = drawJournal,
}


local logoTexture = nil

local function logo()
    if logoTexture == nil then
        local ok, texture = pcall(function() return Hyperspace.Resources:GetImageId("ap_logo.png") end)
        logoTexture = (ok and texture) or false
    end
    return logoTexture or nil
end

local function drawWindow()
    state.areas = {}
    loadJournal()
    local x, y, w, h = WINDOW.x, WINDOW.y, WINDOW.w, WINDOW.h
    rect(0, 0, 1280, 720, "shade")
    rect(x, y, w, h, "window")
    outline(x, y, w, h, "border", 2)

    local texture = logo()
    if texture then
        Graphics.CSurface.GL_BlitPixelImage(texture, x + 16, y + 8, 32, 32, 0, Graphics.GL_Color(1, 1, 1, 1), false)
    end
    text(24, x + 56, y + 8, 360, "title", apT("hud.title"))
    local status, tone = statusLine()
    local statusW = math.min(width(10, status) + 24, 420)
    rect(x + w - 16 - statusW, y + 12, statusW, 22, "faint")
    rect(x + w - 16 - statusW, y + 12, 3, 22, tone)
    text(10, x + w - 16 - statusW + 12, y + 16, statusW - 18, "text", status)

    local tabGap = 6
    local tabW = math.floor((w - 32 - tabGap * (#PAGES - 1)) / #PAGES)
    for index, page in ipairs(PAGES) do
        local area = { x = x + 16 + (index - 1) * (tabW + tabGap), y = y + TAB_Y, w = tabW, h = TAB_H }
        state.areas["tab:" .. index] = area
        local selected = index == state.page
        rect(area.x, area.y, area.w, area.h, selected and "hover" or (hovered(area) and "card" or "window"))
        rect(area.x, area.y + area.h - 2, area.w, 2, selected and "border" or "faint")
        textCenter(10, area.x + area.w / 2, area.y + 8, area.w - 16, selected and "title" or "dim",
            apT(PAGE_TITLE[page], { n = index }))
    end

    local cx, cy = x + PAD, y + CONTENT_Y
    local cw, ch = w - PAD * 2, h - CONTENT_Y - FOOTER_H - 6
    DRAW_PAGE[PAGES[state.page]](cx, cy, cw, ch)

    rect(x + 16, y + h - FOOTER_H, w - 32, 1, "faint")
    text(9, x + 16, y + h - FOOTER_H + 9, w - 32, "dim", apT("dash.footer"))
end


local function inRun()
    local ok, running = pcall(function() return Hyperspace.App.world.bStartedGame == true end)
    return ok and running
end

local function setOpen(value)
    if state.open == value then return end
    state.open = value
    if _G.apNotifyHide then apNotifyHide(value) end
    pcall(function()
        local gui = Hyperspace.App.gui
        if value then
            state.wasPaused = gui.bPaused == true
            gui.bPaused = true
        elseif state.wasPaused ~= nil then
            gui.bPaused = state.wasPaused
            state.wasPaused = nil
        end
    end)
end

function apToggleHud()
    setOpen(not state.open)
    return state.open
end

function apDashboardPage(page)
    for index, name in ipairs(PAGES) do
        if name == page or index == page then
            state.page = index
            return true
        end
    end
    return false
end

function apDashboardOpen()
    return state.open
end

local function turnPage(step)
    state.page = (state.page - 1 + step) % #PAGES + 1
end

script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, function() end, function()
    if not state.open then return end
    if not inRun() then
        setOpen(false)
        return
    end
    local ok, err = pcall(drawWindow)
    if not ok then
        setOpen(false)
        dashLog("render interrupted, dashboard closed: " .. tostring(err))
    end
    if _G.apDrawTutorialBanner then pcall(apDrawTutorialBanner) end
end)

local PAGE_KEYS = {
    [Defines.SDL.KEY_1] = 1, [Defines.SDL.KEY_2] = 2, [Defines.SDL.KEY_3] = 3,
    [Defines.SDL.KEY_4] = 4, [Defines.SDL.KEY_5] = 5,
}

script.on_internal_event(Defines.InternalEvents.ON_KEY_DOWN, function(key)
    if key == Defines.SDL.KEY_TAB then
        if inRun() then setOpen(not state.open) end
        return Defines.Chain.CONTINUE
    end
    if not state.open then
        return Defines.Chain.CONTINUE
    end
    if key == Defines.SDL.KEY_ESCAPE then
        setOpen(false)
        return Defines.Chain.PREEMPT
    end
    if key == Defines.SDL.KEY_LEFT then
        turnPage(-1)
        return Defines.Chain.PREEMPT
    end
    if key == Defines.SDL.KEY_RIGHT then
        turnPage(1)
        return Defines.Chain.PREEMPT
    end
    if PAGE_KEYS[key] then
        state.page = PAGE_KEYS[key]
        return Defines.Chain.PREEMPT
    end
    return Defines.Chain.CONTINUE
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    if not state.open then
        return Defines.Chain.CONTINUE
    end
    x, y = apMousePosition(x, y)
    if not inside(WINDOW, x, y) then
        setOpen(false)
        return Defines.Chain.PREEMPT
    end
    for name, area in pairs(state.areas) do
        if inside(area, x, y) then
            local kind, index = name:match("^(%a+):(%d+)$")
            if kind == "tab" then
                state.page = tonumber(index)
            elseif kind == "cat" then
                state.category = tonumber(index)
            end
        end
    end
    return Defines.Chain.PREEMPT
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_SCROLL, function(direction)
    if not state.open then
        return Defines.Chain.CONTINUE
    end
    local mx, my = mouse()
    for name, area in pairs(state.areas) do
        local id = name:match("^scroll:(.+)$")
        if id and inside(area, mx, my) then
            local step = (tonumber(direction) or 0) > 0 and 3 or -3
            state.scroll[id] = math.max(0, math.min(area.max, (state.scroll[id] or 0) + step))
        end
    end
    return Defines.Chain.PREEMPT
end)

script.on_init(function()
    setOpen(false)
    state.page, state.category, state.scroll = 1, 1, {}
end)

dashLog("dashboard loaded (TAB in-game)")
