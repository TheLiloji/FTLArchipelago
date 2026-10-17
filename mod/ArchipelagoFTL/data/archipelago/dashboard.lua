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

local CATEGORIES = { "shop", "sector", "victory", "achievement", "system", "crew", "fight", "other" }
local CATEGORY_TITLE = {
    shop = "dash.cat.shop", sector = "dash.cat.sector", victory = "dash.cat.victory",
    achievement = "dash.cat.achievement", system = "dash.cat.system", crew = "dash.cat.crew",
    fight = "dash.cat.fight",
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


local function inRun()
    local ok, running = pcall(function() return Hyperspace.App.world.bStartedGame == true end)
    return ok and running
end

local function hasSeed()
    local contract = _G.apContractState
    return contract ~= nil and contract.connected == true
end

local function categoryOf(key)
    key = tostring(key)
    if key:sub(1, 5) == "shop:" then return "shop" end
    if key:sub(1, 4) == "sys:" or key:find(":sys:", 1, true) then return "system" end
    if key:sub(1, 5) == "crew:" then return "crew" end
    if key:find(":fight:", 1, true) then return "fight" end
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
        book.byCategory[name] = { total = 0, done = 0, remaining = {}, sent = {} }
    end
    local names = ((_G.apContractState or {}).locNames) or {}
    for key, name in pairs(names) do
        local entry = book.byCategory[categoryOf(key)]
        entry.total = entry.total + 1
        book.total = book.total + 1
        if sentCheck(key) then
            entry.done = entry.done + 1
            book.done = book.done + 1
            entry.sent[#entry.sent + 1] = { key = key, name = tostring(name), sent = true }
        else
            local place = categoryOf(key) == "shop" and _G.apShopPlace and apShopPlace(key) or nil
            entry.remaining[#entry.remaining + 1] = { key = key, raw = tostring(name),
                name = place and (tostring(name) .. " (" .. place .. ")") or tostring(name) }
        end
    end
    local function natural(name)
        return (name:gsub("%d+", function(digits) return string.format("%09d", tonumber(digits)) end))
    end
    for _, entry in pairs(book.byCategory) do
        table.sort(entry.remaining, function(a, b) return natural(a.name) < natural(b.name) end)
        table.sort(entry.sent, function(a, b) return natural(a.name) < natural(b.name) end)
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
    for _, ship in ipairs(apSeedShips()) do
        local row = { base = ship.name, layouts = {}, remaining = 0 }
        row.label = _G.apShipLabel and apShipLabel(ship.name) or ship.name
        row.species = _G.apShipSpecies and apShipSpecies(ship.name) or nil
        for index = 0, (ship.layouts or 1) - 1 do
            local name = layoutName(ship.name, index)
            if not _G.apLayoutInSeed or apLayoutInSeed(name) then
                row.layouts[#row.layouts + 1] = { name = name, letter = string.char(65 + index),
                                                  unlocked = unlocked[name] == true }
                total = total + 1
                if unlocked[name] then open = open + 1 end
            end
        end
        for key in pairs(book) do
            local prefix = tostring(key):match("^(PLAYER_SHIP_[A-Z0-9_]-):")
            if prefix and prefix:gsub("_[23]$", "") == ship.name and not sentCheck(key) then
                row.remaining = row.remaining + 1
            end
        end
        if #row.layouts > 0 then
            rows[#rows + 1] = row
        end
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
    local rows, unlockedCount = {}, 0
    for _, system in ipairs(((_G.apGameData or {}).systems) or {}) do
        local cap = caps[system.id] or 0
        local bonus = _G.apShipCapBonus and apShipCapBonus(system.id) or 0
        local total = _G.apSystemCapTotal and apSystemCapTotal(system.id) or nil
        local unlocked
        if _G.apSystemUnlocked then
            unlocked = apSystemUnlocked(system.id)
        else
            unlocked = cap > 0 or bonus > 0
        end
        rows[#rows + 1] = {
            id = system.id,
            name = _G.apSystemLabel and apSystemLabel(system.id) or system.id,
            locked = not unlocked,
            aboard = aboard[system.id] == true,
            received = math.max(0, cap - 1) + bonus,
            total = total,
            start = starts[system.id] or 0,
        }
        if unlocked then unlockedCount = unlockedCount + 1 end
    end
    return rows, unlockedCount, starts.reactor or 0
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
        local item, sender, class = entry:match("^([^\31]*)\31?([^\31]*)\31?(.*)$")
        if item and item ~= "" then
            history[#history + 1] = { item = item, sender = sender ~= "" and sender or nil,
                                      class = class ~= "" and class or nil }
        end
    end
    _G.apReceivedHistory = history
end

local function saveJournal()
    if not _G.apNetRememberText then return end
    local parts = {}
    for index = 1, math.min(JOURNAL_SAVED, #_G.apReceivedHistory) do
        local entry = _G.apReceivedHistory[index]
        parts[#parts + 1] = entry.item .. "\31" .. (entry.sender or "") .. "\31" .. (entry.class or "")
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

function apRecordReceived(itemName, sender, index, class)
    loadJournal()
    if alreadyInJournal(index) then
        return
    end
    local own = _G.apOwnSlotName and apOwnSlotName() or nil
    if sender ~= nil and own ~= nil and tostring(sender) == tostring(own) then
        sender = nil
    end
    local history = _G.apReceivedHistory
    table.insert(history, 1, { item = tostring(itemName), sender = sender, class = class })
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
        -- A click opens that category on the Checks page.
        local area = { x = rx - 4, y = ry - 3, w = colW + 8, h = math.min(rowH, 24) }
        state.areas["go:" .. index] = area
        if hovered(area) then rect(area.x, area.y, area.w, area.h, "hover") end
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

-- What the seed's run options mean for the run in progress; empty when the seed uses none of them.
local function runLines()
    local lines = {}
    local option = function(name) return tonumber(_G.apSeedOption and apSeedOption(name) or 0) or 0 end
    local status = hasSeed() and _G.apCombatStatus and apCombatStatus() or nil
    if status and status.total > 0 then
        local key = status.nextSends and "dash.run.fights.next" or "dash.run.fights"
        lines[#lines + 1] = { key = key, params = { n = status.won, left = status.left },
                              tone = status.nextSends and "good" or "text" }
    end
    if option("run_start_scrap") > 0 and _G.apRunStartScrap then
        lines[#lines + 1] = { key = "dash.run.scrap", params = { n = apRunStartScrap() }, tone = "text" }
    end
    -- Each option only does something with the seed setting it relies on: say nothing rather than promise.
    local capsActive = not _G.apSystemCapsActive or apSystemCapsActive()
    local blueprintsActive = not _G.apSystemBlueprintsActive or apSystemBlueprintsActive()
    if option("free_upgrades") > 0 and capsActive then
        lines[#lines + 1] = { key = "dash.run.free_upgrades", tone = "dim" }
    end
    local install = blueprintsActive and option("system_install") or 0
    if install == 1 then
        lines[#lines + 1] = { key = "dash.run.install.start", tone = "dim" }
    elseif install == 2 then
        lines[#lines + 1] = { key = "dash.run.install.now", tone = "dim" }
    end
    return lines
end

-- A line too wide for the card wraps onto a second one (translations run longer than English).
local function runLineHeight(line, w)
    return width(10, apT(line.key, line.params)) > w - 32 and 34 or 20
end

local function runCardHeight(lines, w)
    local h = 40
    for _, line in ipairs(lines) do
        h = h + runLineHeight(line, w)
    end
    return h
end

local function drawRunCard(x, y, w, h, lines)
    card(x, y, w, h)
    label(x + 16, y + 10, w - 32, "dash.run.title")
    local lineY = y + 32
    for _, line in ipairs(lines) do
        Graphics.CSurface.GL_SetColor(color(line.tone))
        Graphics.freetype.easy_printAutoNewlines(10, x + 16, lineY, w - 32, apT(line.key, line.params))
        lineY = lineY + runLineHeight(line, w)
    end
end

-- Archipelago's item classes: progression green, useful blue, trap red, filler grey.
local CLASS_TONE = { p = "good", u = "useful", t = "bad", f = "dim" }
local function classTone(entry)
    return CLASS_TONE[entry.class] or "text"
end

-- What the colours mean, right of the journal's title when it fits.
local function drawClassLegend(right, y, room)
    local words, total = {}, 0
    for _, pair in ipairs({ { "p", "dash.class.p" }, { "u", "dash.class.u" }, { "t", "dash.class.t" },
                            { "f", "dash.class.f" } }) do
        local word = apT(pair[2])
        words[#words + 1] = { code = pair[1], word = word, w = width(9, word) }
        total = total + words[#words].w + (#words > 1 and 10 or 0)
    end
    if total > room then
        return
    end
    for index = #words, 1, -1 do
        local entry = words[index]
        textRight(9, right, y, entry.w, CLASS_TONE[entry.code], entry.word)
        right = right - entry.w - 10
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
        text(10, x + 16, lineY, w - 40 - senderW, classTone(entry), entry.item)
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
    local lines = runLines()
    local runH = #lines > 0 and runCardHeight(lines, right) or 0
    if runH > 0 then
        drawRunCard(rx, y + 70 + GAP, right, runH, lines)
        runH = runH + GAP
    end
    drawRecentCard(rx, y + 70 + GAP + runH, right, h - 70 - GAP - runH - hintH - GAP)
    drawHintCard(rx, y + h - hintH, right, hintH)
end

-- Below this height the name and the checks left would be drawn over each other.
local SHIP_CARD_MIN_H = 74

local function drawShipCard(row, cx, cy, cardW, cardH)
    local any = false
    for _, layout in ipairs(row.layouts) do any = any or layout.unlocked end
    card(cx, cy, cardW, cardH)
    rect(cx, cy, 3, cardH, any and "good" or "faint")
    -- Each layout as the ship list shows it: in colour once unlocked, faded until then.
    local miniGap = 6
    local miniH = cardH - 30
    local miniW = math.min(math.floor(miniH * 191 / 121), math.floor((cardW * 0.6 - miniGap * 2) / 3))
    miniH = math.floor(miniW * 121 / 191)
    local minisW = #row.layouts * miniW + (#row.layouts - 1) * miniGap
    local textW = cardW - minisW - 40
    -- The race goes under the name, or after it when the cards are too short for one more line.
    local roomy = cardH >= 64
    local label = (row.species and not roomy) and apT("dash.ships.species", { ship = row.label, species = row.species })
        or row.label
    text(12, cx + 16, cy + 10, textW, any and "text" or "dim", label)
    if row.species and roomy then
        text(9, cx + 16, cy + 28, textW, "dim", row.species)
    end
    local remaining = row.remaining > 0 and apT("dash.ships.remaining", { n = row.remaining })
        or apT("dash.ships.clear")
    text(9, cx + 16, cy + cardH - 22, textW, "dim", remaining)
    local mx = cx + cardW - 12 - minisW
    local my = cy + math.floor((cardH - miniH - 18) / 2)
    for _, layout in ipairs(row.layouts) do
        if not ui.shipMini(layout.name, mx, my, miniW, miniH, layout.unlocked and 1 or 0.3) then
            rect(mx, my, miniW, miniH, layout.unlocked and "faint" or "card")
        end
        rect(mx, my + miniH + 2, miniW, 3, layout.unlocked and "good" or "faint")
        textCenter(9, mx + miniW / 2, my + miniH + 7, miniW, layout.unlocked and "text" or "dim",
            apT("dash.ships.type", { letter = layout.letter }))
        mx = mx + miniW + miniGap
    end
end

local function drawShips(x, y, w, h)
    local rows, open, total = shipRows()
    text(12, x, y, w, "title", apT("dash.ships.header", { done = open, total = total }))
    local top = y + 30
    local columns = 2
    local lines = {}
    for index, row in ipairs(rows) do
        local line = math.floor((index - 1) / columns) + 1
        lines[line] = lines[line] or {}
        lines[line][#lines[line] + 1] = row
    end
    -- A seed with few ships keeps cards of a normal height at the top instead of stretching them, and one
    -- with many ships (Multiverse) scrolls instead of squeezing them.
    local fitH = math.floor((h - 30 - GAP * (#lines - 1)) / math.max(1, #lines))
    local cardH = math.max(SHIP_CARD_MIN_H, math.min(110, fitH))
    scrollList("ships", { x = x, y = top, w = w, h = y + h - top }, lines, cardH + GAP, function(line, rx, ry, rw)
        local lineW = math.floor((rw - GAP) / columns)
        for column, row in ipairs(line) do
            drawShipCard(row, rx + (column - 1) * (lineW + GAP), ry, lineW, cardH)
        end
    end)
end

-- FTL's own system icons, green when the system can be used, grey when it is still locked.
local VANILLA_ICONS = {
    artillery = true, battery = true, cloaking = true, clonebay = true, doors = true, drones = true,
    engines = true, hacking = true, medbay = true, mind = true, oxygen = true, pilot = true,
    sensors = true, shields = true, teleporter = true, weapons = true,
}
-- The images are 64 pixels with a wide transparent margin: drawn at their own size, crisp.
local ICON_SIZE = 64
local iconTextures = {}

local function systemIcon(id, lit)
    if not VANILLA_ICONS[id] then
        return nil
    end
    local path = "icons/s_" .. id .. (lit and "_green1.png" or "_grey1.png")
    if iconTextures[path] == nil then
        local ok, texture = pcall(function() return Hyperspace.Resources:GetImageId(path) end)
        iconTextures[path] = (ok and texture) or false
    end
    return iconTextures[path] or nil
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
        local icon = systemIcon(row.id, not row.locked or row.aboard)
        local innerW = icon and cardW - 18 - ICON_SIZE or cardW - 26
        if icon then
            Graphics.CSurface.GL_BlitPixelImage(icon, cx + cardW - ICON_SIZE - 2,
                cy + math.floor((cardH - ICON_SIZE) / 2), ICON_SIZE, ICON_SIZE, 0, Graphics.GL_Color(1, 1, 1, 1), false)
        end
        text(10, cx + 14, cy + 10, innerW, row.locked and "dim" or "text", row.name)
        local status
        -- A system the ship starts with counts its upgrades like the others, its blueprint still missing.
        if row.locked and row.aboard and known then
            status = apT("dash.system.aboard", { received = row.received, total = row.total })
        elseif row.locked and row.aboard then
            status = apT("dash.system.aboard", { received = row.received, total = "?" })
        elseif row.locked then
            status = apT("dash.system.locked")
        elseif full then
            status = apT("hud.system.max")
        elseif known then
            status = apT("hud.system.progress", { received = row.received, total = row.total })
        else
            status = apT("hud.system.received", { n = row.received })
        end
        text(9, cx + 14, cy + 28, innerW, row.locked and "dim" or (full and "good" or "dim"), status)
        if known and (not row.locked or row.aboard) then
            local pipGap = 3
            local pipW = math.max(4, math.min(18, math.floor((innerW - 2 - pipGap * (row.total - 1)) / row.total)))
            for pip = 1, row.total do
                rect(cx + 14 + (pip - 1) * (pipW + pipGap), cy + 48, pipW, 8,
                    pip <= row.received and (full and "good" or "border") or "faint")
            end
        end
        if row.start > 0 then
            text(9, cx + 14, cy + cardH - 20, innerW, "good", apT("dash.system.start", { n = row.start }))
        end
    end
end

-- The Checks page draws a category as a grid: one row per ship (or system), one box per sector,
-- fight, level or achievement, green once done. Pointing at a box tells what it is and what it gave.
local function baseOf(ship)
    return (tostring(ship):gsub("_[23]$", ""))
end

local function flyingShip()
    if not inRun() then return nil end
    local ok, name = pcall(function() return Hyperspace.ships.player.myBlueprint.blueprintName end)
    return ok and name ~= nil and tostring(name) or nil
end

local function currentSector()
    local ok, level = pcall(function() return Hyperspace.App.world.starMap.worldLevel end)
    return ok and tonumber(level) and math.floor(level) + 1 or nil
end

local function shipLabel(ship, layout)
    local base = baseOf(ship)
    local label = _G.apShipLabel and apShipLabel(base) or base
    if not layout then return label end
    local variant = tostring(ship):match("_([23])$")
    return label .. " " .. (variant == "2" and "B" or variant == "3" and "C" or "A")
end

local achievementShip = nil
local function shipOfAchievement(id)
    if achievementShip == nil then
        achievementShip = {}
        for ship, list in pairs(((_G.apGameData or {}).shipAchievements) or {}) do
            for _, achievement in ipairs(list) do achievementShip[achievement] = ship end
        end
    end
    return achievementShip[id]
end

-- Where a check sits: its row (a ship, a system, or one row for the rest) and its box in that row.
local function placeOf(key, name, category)
    key = tostring(key)
    if category == "shop" then
        local owner, sector
        if _G.apShopSlotWhere then owner, sector = apShopSlotWhere(key) end
        local slot = tonumber(key:match("^shop:(%d+)$")) or 0
        local layout = owner ~= nil and (_G.apShopConfig or {}).per == "per_layout"
        return { row = owner or "any", ship = owner, layout = layout,
                 label = owner and shipLabel(owner, layout) or apT("dash.checks.any_ship"),
                 box = sector or slot, text = tostring(sector or slot), sector = sector }
    end
    local layout, sector = key:match("^([%u_%d]+):sector:(%d+)$")
    if layout then
        return { row = layout, ship = layout, layout = true, label = shipLabel(layout, true),
                 box = tonumber(sector), text = sector }
    end
    layout = key:match("^([%u_%d]+):victory$")
    if layout then
        local index = ({ ["2"] = 2, ["3"] = 3 })[layout:match("_([23])$") or ""] or 1
        local base = baseOf(layout)
        return { row = base, ship = base, label = shipLabel(base), box = index,
                 text = apT("dash.ships.type", { letter = string.char(64 + index) }), named = true }
    end
    local ship, fight = key:match("^([%u_%d]+):fight:(%d+)$")
    if ship then
        return { row = ship, ship = ship, label = shipLabel(ship), box = tonumber(fight), text = fight }
    end
    local system
    ship, system = key:match("^([%u_%d]+):sys:(%a+)$")
    if ship then
        return { row = ship, ship = ship, label = shipLabel(ship), box = system, named = true,
                 text = _G.apSystemLabel and apSystemLabel(system) or system }
    end
    local level
    system, level = key:match("^sys:(%a+):?(%d*)$")
    if system then
        level = tonumber(level) or 1
        return { row = "sys:" .. system, label = _G.apSystemLabel and apSystemLabel(system) or system,
                 box = level, text = tostring(level) }
    end
    local achievement = key:match("^ach:(.+)$")
    if achievement then
        local owner = shipOfAchievement(achievement)
        local label = _G.apAchievementLabel and apAchievementLabel(achievement) or achievement
        if owner then
            return { row = owner, ship = owner, label = shipLabel(owner), box = label, text = label, named = true,
                     translated = true }
        end
        return { row = "~general", label = apT("dash.checks.general"), box = label, text = label, named = true,
                 translated = true }
    end
    local race = key:match("^crew:(.+)$")
    if race then
        local label = _G.apRaceLabel and apRaceLabel(race) or race
        return { row = "~crew", label = apT(CATEGORY_TITLE.crew), box = label, text = label, named = true,
                 translated = true }
    end
    return { row = "~" .. category, label = apT(CATEGORY_TITLE[category]), box = tostring(name),
             text = tostring(name), named = true }
end

local function checkRows(entry, category)
    local flying = flyingShip()
    local sector = currentSector()
    local rows, byId = {}, {}
    local function add(check, done)
        local place = placeOf(check.key, check.name, category)
        local row = byId[place.row]
        if row == nil then
            local current = flying ~= nil and (place.row == "any"
                or place.ship ~= nil and (place.ship == flying or (not place.layout and place.ship == baseOf(flying))))
            row = { id = place.row, label = place.label, ship = place.ship, current = current,
                    boxes = {}, byBox = {}, done = 0, total = 0, here = 0 }
            byId[place.row] = row
            rows[#rows + 1] = row
        end
        local box = row.byBox[place.box]
        if box == nil then
            box = { id = place.box, text = place.text, named = place.named, checks = {}, done = 0, total = 0,
                    here = place.sector ~= nil and place.sector == sector }
            row.byBox[place.box] = box
            row.boxes[#row.boxes + 1] = box
        end
        -- The grid already shows the ship and the sector: the name alone says the rest. A named box (an
        -- achievement, a race) speaks the game's language, not the seed's English location name.
        local name = place.translated and place.text or check.raw or check.name
        box.checks[#box.checks + 1] = { key = check.key, name = name, done = done }
        box.total, row.total = box.total + 1, row.total + 1
        if done then
            box.done, row.done = box.done + 1, row.done + 1
        elseif box.here and row.current then
            row.here = row.here + 1
        end
    end
    for _, check in ipairs(entry.remaining) do add(check, false) end
    for _, check in ipairs(entry.sent) do add(check, true) end
    for _, row in ipairs(rows) do
        table.sort(row.boxes, function(a, b)
            if type(a.id) == type(b.id) then return a.id < b.id end
            return type(a.id) == "number"
        end)
    end
    -- The ship flown first, then what counts on any ship, then the other ships: the same order in every language.
    local function rank(row)
        return row.current and 0 or (row.ship == nil and 1 or 2)
    end
    table.sort(rows, function(a, b)
        if rank(a) ~= rank(b) then return rank(a) < rank(b) end
        local aLeft, bLeft = a.done < a.total, b.done < b.total
        if aLeft ~= bLeft then return aLeft end
        return a.label < b.label
    end)
    return rows, flying
end

-- What a check done gave, as the server answered the scout: "Glaive Beam for Axel".
local function contentOf(key)
    local found
    if tostring(key):sub(1, 5) == "shop:" then
        found = _G.apShopSlotContent and apShopSlotContent(key)
    else
        found = _G.apNetScoutedItem and apNetScoutedItem(key)
    end
    if found == nil or found.item == nil then return nil end
    local own = _G.apOwnSlotName and apOwnSlotName() or nil
    local receiver = found.slot ~= nil and tostring(found.slot) or nil
    if found.mine or receiver == nil or receiver == "" or (own ~= nil and receiver == tostring(own)) then
        return tostring(found.item)
    end
    return apT("dash.checks.gave", { item = tostring(found.item), slot = receiver })
end

local BOX_W, BOX_H, BOX_GAP = 26, 22, 4
local LINE_H = BOX_H + 8

local function boxWidth(box)
    if not box.named then return BOX_W end
    return math.min(240, width(9, box.text) + 16)
end

-- A row too long for the panel goes on as many lines as it needs, its name on the first one.
local function gridLines(rows, boxesW)
    local lines = {}
    for _, row in ipairs(rows) do
        local line = { row = row, first = true, boxes = {} }
        local used = 0
        for _, box in ipairs(row.boxes) do
            local bw = boxWidth(box)
            if #line.boxes > 0 and used + bw > boxesW then
                lines[#lines + 1] = line
                line = { row = row, first = false, boxes = {} }
                used = 0
            end
            line.boxes[#line.boxes + 1] = box
            used = used + bw + BOX_GAP
        end
        lines[#lines + 1] = line
    end
    return lines
end

local function drawBox(box, row, bx, by, bw)
    local complete = box.done >= box.total
    if complete then
        rect(bx, by, bw, BOX_H, "good")
    else
        rect(bx, by, bw, BOX_H, row.current and "faint" or "card")
        outline(bx, by, bw, BOX_H, row.current and "border" or "faint", 1)
    end
    -- Several checks in one box (shop packages of a sector): one dot each, green once done.
    if box.total > 1 and box.total <= 6 and not complete then
        local dotsW = box.total * 3 + (box.total - 1) * 2
        for dot = 1, box.total do
            rect(bx + math.floor((bw - dotsW) / 2) + (dot - 1) * 5, by + BOX_H - 5, 3, 3,
                dot <= box.done and "good" or (row.current and "border" or "dim"))
        end
    end
    if box.here and row.current then
        outline(bx - 2, by - 2, bw + 4, BOX_H + 4, "warn", 2)
    end
    local area = { x = bx, y = by, w = bw, h = BOX_H }
    if hovered(area) then
        outline(bx, by, bw, BOX_H, "title", 1)
        state.pointed = box
    end
    local tone = complete and "window" or (row.current and "text" or "dim")
    textCenter(9, bx + bw / 2, by + (box.total > 1 and not complete and 3 or 5), bw - 4, tone, box.text)
end

local function drawShipBanner(x, y, w, rows, flying, category)
    local left, here, any = 0, 0, false
    for _, row in ipairs(rows) do
        if row.current then
            any = true
            left = left + row.total - row.done
            here = here + row.here
        end
    end
    local tone = left == 0 and "good" or "border"
    rect(x, y, w, 50, "faint")
    rect(x, y, 3, 50, tone)
    local layout = category == "sector" or (category == "shop" and (_G.apShopConfig or {}).per == "per_layout")
    text(9, x + 14, y + 7, w - 200, "dim", apT("dash.checks.ship", { ship = shipLabel(flying, layout) }))
    if not any or left == 0 then
        text(12, x + 14, y + 24, w - 28, "good", apT("dash.checks.ship_clear"))
        return
    end
    local count = apT("dash.checks.remaining", { n = left })
    text(18, x + 14, y + 22, w - 28, "text", count)
    if category == "shop" and here > 0 then
        text(10, x + 24 + width(18, count), y + 28, w - 60 - width(18, count), "warn",
            apT("dash.checks.ship_sector", { n = here }))
    end
end

local function drawPointed(x, y, w, complete)
    local box = state.pointed
    if box == nil then
        if complete then text(10, x, y, w, "good", apT("dash.checks.all_done")) end
        text(9, x, y + (complete and 18 or 0), w, "dim", apT("dash.checks.hover"))
        return
    end
    for index, check in ipairs(box.checks) do
        if index > 3 then
            text(9, x, y + 3 * 15, w, "dim", apT("dash.plus", { n = #box.checks - 3 }))
            break
        end
        local line = check.name
        local gave = check.done and contentOf(check.key) or nil
        if gave then line = line .. "  >  " .. gave end
        text(9, x, y + (index - 1) * 15, w, check.done and "good" or "text", line)
    end
end

-- First crew members get a card each, with the race's own sprite: facing down, first frame.
local FRAME = 35
local crewTextures = {}

local function crewTexture(race)
    if crewTextures[race] == nil then
        local ok, texture = pcall(function()
            return Hyperspace.Resources:GetImageId("people/" .. race .. "_base.png")
        end)
        crewTextures[race] = (ok and texture and (texture.width or 0) >= FRAME) and texture or false
    end
    return crewTextures[race] or nil
end

local function drawCrewCards(x, y, w, bottom, rows)
    local cards = {}
    for _, row in ipairs(rows) do
        for _, box in ipairs(row.boxes) do cards[#cards + 1] = box end
    end
    -- Multiverse's eighteen races fit on one screen in six narrower columns.
    local columns = #cards > 8 and 6 or 4
    local cardW = math.floor((w - GAP * (columns - 1)) / columns)
    local narrow = columns == 6
    local cardH = narrow and 110 or 128
    local lines = {}
    for index, box in ipairs(cards) do
        local line = lines[math.floor((index - 1) / columns) + 1] or {}
        line[#line + 1] = box
        lines[math.floor((index - 1) / columns) + 1] = line
    end
    scrollList("checks:crew", { x = x, y = y, w = w, h = bottom - y }, lines, cardH + GAP,
        function(line, rx, ry)
            for column, box in ipairs(line) do
                local cx = rx + (column - 1) * (cardW + GAP)
                local done = box.done >= box.total
                local area = { x = cx, y = ry, w = cardW, h = cardH }
                rect(cx, ry, cardW, cardH, hovered(area) and "hover" or "faint")
                rect(cx, ry + cardH - 3, cardW, 3, done and "good" or "card")
                if hovered(area) then state.pointed = box end
                local race = tostring(box.checks[1].key):match("^crew:(.+)$")
                local texture = race and crewTexture(race)
                -- Three times its size (twice in narrow cards, where big races would cover the name); the
                -- frame's empty border lets it overflow the card's top a little.
                local size = FRAME * (narrow and 2 or 3)
                local sx = cx + math.floor((cardW - size) / 2)
                if texture then
                    Graphics.CSurface.GL_BlitImagePartial(texture, sx, narrow and ry - 6 or ry - 12, size, size,
                        0, FRAME / texture.width, 0, FRAME / texture.height,
                        done and 1 or 0.45, Graphics.GL_Color(1, 1, 1, 1), false)
                end
                ui.textCenterTwoLines(10, cx + cardW / 2, ry + cardH - 46, cardW - 12, 13,
                    done and "good" or "text", box.text)
                local status = done and (contentOf(box.checks[1].key) or apT("dash.crew.done"))
                    or apT("dash.crew.waiting")
                ui.textCenterTwoLines(9, cx + cardW / 2, ry + cardH - (narrow and 18 or 28), cardW - 12, 11,
                    done and "good" or "dim", status)
            end
        end)
end

-- Any image of the game, loaded once; false when missing, so a lookup is not retried every frame.
local images = {}
local function gameImage(path)
    if path == nil then return nil end
    if images[path] == nil then
        local ok, texture = pcall(function() return Hyperspace.Resources:GetImageId(path) end)
        images[path] = (ok and texture and (texture.width or 0) > 0) and texture or false
    end
    return images[path] or nil
end

local function blit(texture, x, y, w, h, alpha)
    Graphics.CSurface.GL_BlitImagePartial(texture, x, y, w, h, 0, 1, 0, 1, alpha, Graphics.GL_Color(1, 1, 1, 1), false)
end

local function pointable(box, area)
    if hovered(area) then
        state.pointed = box
        outline(area.x - 1, area.y - 1, area.w + 2, area.h + 2, "title", 1)
    end
end

-- Achievements as the game shows them: their icons, faded until done. One card per ship, the general ones
-- spread over as many full-width lines as they need.
local ICON = 48
local function achievementIcon(box)
    local id = tostring(box.checks[1].key):match("^ach:(.+)$")
    local path = id and (((_G.apGameData or {}).achievementImages or {})[id])
    return gameImage(path)
end

local function drawIcons(boxes, x, y)
    for index, box in ipairs(boxes) do
        local bx = x + (index - 1) * (ICON + 8)
        local done = box.done >= box.total
        local icon = achievementIcon(box)
        rect(bx, y, ICON, ICON, "card")
        if icon then
            blit(icon, bx, y, ICON, ICON, done and 1 or 0.3)
        else
            textCenter(12, bx + ICON / 2, y + 14, ICON - 4, done and "good" or "dim", "?")
        end
        rect(bx, y + ICON + 2, ICON, 3, done and "good" or "faint")
        pointable(box, { x = bx, y = y, w = ICON, h = ICON })
    end
end

local function drawAchievementCards(x, y, w, bottom, rows)
    local lineH = ICON + 44
    local perLine = math.max(1, math.floor((w - 24 + 8) / (ICON + 8)))
    local lines, pending = {}, {}
    local function flush()
        if #pending > 0 then lines[#lines + 1] = { cards = pending } end
        pending = {}
    end
    for _, row in ipairs(rows) do
        if row.ship == nil then
            flush()
            for start = 1, #row.boxes, perLine do
                local chunk = {}
                for index = start, math.min(#row.boxes, start + perLine - 1) do chunk[#chunk + 1] = row.boxes[index] end
                lines[#lines + 1] = { wide = { row = row, boxes = chunk, first = start == 1 } }
            end
        else
            pending[#pending + 1] = row
            if #pending == 3 then flush() end
        end
    end
    flush()
    local cardW = math.floor((w - GAP * 2) / 3)
    local function card(row, cx, ry, cw, boxes, first)
        -- A card spread over several lines stays one card: its next lines cover the gap above them.
        local top = first and ry or ry - GAP
        rect(cx, top, cw, ry + lineH - GAP - top, row.current and "hover" or "faint")
        if row.current then rect(cx, ry, 3, lineH - GAP, "border") end
        local complete = row.done >= row.total
        if first then
            text(10, cx + 12, ry + 6, cw - 70, row.current and "title" or (complete and "good" or "text"), row.label)
            textRight(9, cx + cw - 10, ry + 7, 56, complete and "good" or "dim",
                apT("dash.fraction", { done = row.done, total = row.total }))
        end
        drawIcons(boxes, cx + 12, ry + (first and 26 or 6))
    end
    scrollList("checks:achievement", { x = x, y = y, w = w, h = bottom - y }, lines, lineH, function(line, rx, ry, rw)
        if line.wide then
            card(line.wide.row, rx, ry, rw, line.wide.boxes, line.wide.first)
            return
        end
        for column, row in ipairs(line.cards) do
            card(row, rx + (column - 1) * (cardW + GAP), ry, cardW, row.boxes, true)
        end
    end)
end

-- Victories: one card per ship, each layout drawn as the ship list shows it, in colour once won.

local function drawVictoryCards(x, y, w, bottom, rows)
    local columns = 2
    local cardW = math.floor((w - GAP * (columns - 1)) / columns)
    local miniW = math.floor((cardW - 24 - 8 * 2) / 3)
    local miniH = math.floor(miniW * 121 / 191)
    local lineH = miniH + 66
    local lines = {}
    for index, row in ipairs(rows) do
        local line = lines[math.floor((index - 1) / columns) + 1] or {}
        line[#line + 1] = row
        lines[math.floor((index - 1) / columns) + 1] = line
    end
    local suffix = (_G.apGameData or {}).variantSuffix or { [0] = "", [1] = "_2", [2] = "_3" }
    scrollList("checks:victory", { x = x, y = y, w = w, h = bottom - y }, lines, lineH, function(line, rx, ry)
        for column, row in ipairs(line) do
            local cx = rx + (column - 1) * (cardW + GAP)
            local complete = row.done >= row.total
            rect(cx, ry, cardW, lineH - GAP, row.current and "hover" or "faint")
            if row.current then rect(cx, ry, 3, lineH - GAP, "border") end
            text(10, cx + 12, ry + 6, cardW - 24, row.current and "title" or (complete and "good" or "text"), row.label)
            for index, box in ipairs(row.boxes) do
                local mx = cx + 12 + (index - 1) * (miniW + 8)
                local my = ry + 26
                local done = box.done >= box.total
                if not ui.shipMini(tostring(row.ship) .. (suffix[(box.id or 1) - 1] or ""), mx, my, miniW, miniH,
                        done and 1 or 0.45) then
                    rect(mx, my, miniW, miniH, "card")
                end
                rect(mx, my + miniH + 2, miniW, 3, done and "good" or "faint")
                textCenter(9, mx + miniW / 2, my + miniH + 8, miniW, done and "good" or "dim", box.text)
                pointable(box, { x = mx, y = my, w = miniW, h = miniH })
            end
        end
    end)
end

local function drawChecks(x, y, w, h)
    local book = checkBook()
    state.pointed = nil
    if book.total == 0 then
        text(12, x, y, w, "dim", apT("dash.checks.none"))
        return
    end
    local listW = 236
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

    local category = shown[state.category]
    local px = x + listW + PAD
    local pw = w - listW - PAD
    local current = book.byCategory[category]
    card(px, y, pw, h)
    text(12, px + 16, y + 12, pw - 180, "title", apT(CATEGORY_TITLE[category]))
    textRight(10, px + pw - 16, y + 15, 170, current.done >= current.total and "good" or "dim",
        apT("dash.checks.remaining", { n = #current.remaining }))

    local rows, flying = checkRows(current, category)
    local top = y + 42
    local shipBound = false
    for _, row in ipairs(rows) do shipBound = shipBound or row.ship ~= nil end
    if flying and shipBound then
        drawShipBanner(px + 16, top, pw - 32, rows, flying, category)
        top = top + 62
    end
    local detailH = 52
    local CARDS = { crew = drawCrewCards, achievement = drawAchievementCards, victory = drawVictoryCards }
    if CARDS[category] then
        rect(px + 16, y + h - detailH - 6, pw - 32, 1, "faint")
        CARDS[category](px + 16, top, pw - 32, y + h - detailH - 12, rows)
        drawPointed(px + 16, y + h - detailH, pw - 32, current.done >= current.total)
        return
    end
    local labelW = 180
    local fractionW = 56
    local boxesW = pw - 32 - labelW - fractionW
    local lines = gridLines(rows, boxesW)
    rect(px + 16, y + h - detailH - 6, pw - 32, 1, "faint")
    scrollList("checks:" .. category, { x = px + 16, y = top, w = pw - 32, h = y + h - detailH - 12 - top },
        lines, LINE_H, function(line, rx, ry, rw)
            local row = line.row
            local complete = row.done >= row.total
            if line.first then
                if row.current then rect(rx, ry, 3, BOX_H, "border") end
                text(10, rx + 10, ry + 4, labelW - 16, row.current and "title" or (complete and "good" or "text"),
                    row.label)
                textRight(9, rx + rw, ry + 5, fractionW - 6, complete and "good" or "dim",
                    apT("dash.fraction", { done = row.done, total = row.total }))
            end
            local bx = rx + labelW
            for _, box in ipairs(line.boxes) do
                local bw = boxWidth(box)
                drawBox(box, row, bx, ry, bw)
                bx = bx + bw + BOX_GAP
            end
        end)
    drawPointed(px + 16, y + h - detailH, pw - 32, current.done >= current.total)
end

local function drawJournal(x, y, w, h)
    local colW = math.floor((w - PAD) / 2)
    card(x, y, colW, h)
    text(12, x + 16, y + 12, colW - 32, "title", apT("dash.journal.items"))
    drawClassLegend(x + colW - 16, y + 15, colW - 48 - width(12, apT("dash.journal.items")))
    local history = _G.apReceivedHistory or {}
    if #history == 0 then
        Graphics.CSurface.GL_SetColor(color("dim"))
        Graphics.freetype.easy_printAutoNewlines(10, x + 16, y + 44, colW - 32, apT("dash.recent.none"))
    else
        -- A bundle lists what it brought, one line each, under its own name.
        local rows = {}
        local descriptors = (_G.apContractState or {}).itemDescriptors or {}
        for _, entry in ipairs(history) do
            rows[#rows + 1] = entry
            local descriptor = descriptors[entry.item]
            if descriptor and descriptor.k == "bundle" then
                for _, name in ipairs(descriptor.names or descriptor.bps or {}) do
                    rows[#rows + 1] = { member = tostring(name) }
                end
            end
        end
        scrollList("journal:items", { x = x + 16, y = y + 44, w = colW - 32, h = h - 56 }, rows, 20,
            function(entry, rx, ry, rw)
                if entry.member then
                    rect(rx + 6, ry + 7, 4, 4, "faint")
                    text(9, rx + 18, ry + 2, rw - 18, "dim", entry.member)
                    return
                end
                local senderW = 0
                if entry.sender and entry.sender ~= "" then
                    local sender = apT("dash.recent.from", { sender = entry.sender })
                    senderW = math.min(width(9, sender), math.floor(rw * 0.4))
                    textRight(9, rx + rw, ry + 2, senderW, "dim", sender)
                end
                text(10, rx, ry, rw - senderW - 8, classTone(entry), entry.item)
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
    ui.hideGameTooltip()
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
            elseif kind == "go" then
                state.page, state.category = 4, tonumber(index)
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
