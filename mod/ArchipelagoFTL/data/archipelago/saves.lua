local TAG = "[AP-saves] "

local function savesLog(message)
    log(TAG .. message)
end

local ui = apUi

-- Save profiles: each seed, and solo, keeps its own FTL profile and run, so switching seeds loses nothing. The
-- module keeps them next to FTL's own files and swaps them at the next launch; the player's own FTL save (the
-- one without Archipelago) is never touched. A module older than 0.6 has none of this: everything stays as before.

local PANEL = { x = 250, y = 160, w = 780, h = 480 }
local ROW_H = 58
local VISIBLE_ROWS = 5
local BUTTON_H = 30

local open = false
local scroll = 0
local confirmArchive = nil
local status, statusTone = nil, "dim"

local function call(method, ...)
    if _G.apNetProfileCall == nil then
        return nil
    end
    return apNetProfileCall(method, ...)
end

function apSavesSupported()
    return call("ProfileId") ~= nil
end

function apSavesCurrent()
    return tostring(call("ProfileId") or "main")
end

local function list()
    local ids = call("ProfileIds")
    local found = {}
    if ids == nil then
        return found
    end
    -- The save in use first, then the others in the order they were made.
    local current = apSavesCurrent()
    found[1] = current
    for i = 0, ids:size() - 1 do
        local id = tostring(ids[i])
        if id ~= current then
            found[#found + 1] = id
        end
    end
    return found
end

local function detail(id, key)
    local value = call("ProfileDetail", id, key)
    return value ~= nil and tostring(value) or ""
end

-- The profile a seed or solo plays in. The first profile ("main") is the one players had before 0.6.
function apSavesIdFor(fingerprint, solo)
    if solo then
        return "solo"
    end
    return "seed-" .. tostring(fingerprint or 0)
end

-- Switches at the next launch: the caller closes FTL, which saves the current profile on its way out.
function apSavesSwitch(id)
    if call("SwitchProfile", id) ~= true then
        savesLog("switch to " .. tostring(id) .. " refused")
        return false
    end
    -- Solo resumes by itself at launch: only in the solo save.
    if id == "solo" then
        if _G.apSoloRememberActive then apSoloRememberActive() end
    elseif _G.apSoloForgetActive then
        apSoloForgetActive()
    end
    savesLog("switch to " .. tostring(id) .. " at the next launch")
    return true
end

-- What the menu shows for the current profile: written on connecting and as checks come in.
function apSavesDescribe()
    if not apSavesSupported() then
        return
    end
    local solo = _G.apSoloEnabled == true
    local label
    if solo then
        label = apT("saves.solo")
    else
        local slot = _G.apOwnSlotName and apOwnSlotName() or nil
        local state = _G.apConnectState and apConnectState() or {}
        if slot == nil or slot == "" then
            return
        end
        label = apT("saves.label", { slot = tostring(slot), host = tostring(state.uri or "?") })
    end
    local counts = _G.apCheckCount and apCheckCount() or { sent = 0, total = 0 }
    call("DescribeProfile", "label", label)
    call("DescribeProfile", "checks", tostring(counts.sent) .. "/" .. tostring(counts.total))
    call("DescribeProfile", "solo", solo and "1" or "0")
end

local describeTicks = 0
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    describeTicks = describeTicks + 1
    if describeTicks >= 60 * 30 then
        describeTicks = 0
        apTry(TAG, apSavesDescribe)
    end
end)

local function geometry()
    local g = { panel = PANEL, rows = {} }
    local top = PANEL.y + 96
    for slot = 1, VISIBLE_ROWS do
        local y = top + (slot - 1) * ROW_H
        g.rows[slot] = {
            box = { x = PANEL.x + 20, y = y, w = PANEL.w - 40, h = ROW_H - 8 },
            load = { x = PANEL.x + PANEL.w - 20 - 230, y = y + 10, w = 110, h = BUTTON_H },
            archive = { x = PANEL.x + PANEL.w - 20 - 112, y = y + 10, w = 102, h = BUTTON_H },
        }
    end
    g.close = { x = PANEL.x + PANEL.w - 20 - 140, y = PANEL.y + PANEL.h - 20 - 34, w = 140, h = 34 }
    g.up = { x = PANEL.x + 20, y = PANEL.y + PANEL.h - 20 - 34, w = 40, h = 34 }
    g.down = { x = PANEL.x + 66, y = PANEL.y + PANEL.h - 20 - 34, w = 40, h = 34 }
    return g
end

local function inside(box, x, y)
    return x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h
end

local function rowTitle(id)
    local label = detail(id, "label")
    if label ~= "" then
        return label
    end
    if id == "main" then
        return apT("saves.main")
    end
    if id == "solo" then
        return apT("saves.solo")
    end
    return apT("saves.unnamed")
end

local function rowFacts(id)
    local facts = {}
    local checks = detail(id, "checks")
    if checks ~= "" and checks ~= "0/0" then
        facts[#facts + 1] = apT("saves.checks", { checks = checks })
    end
    local last = detail(id, "last")
    if last ~= "" then
        facts[#facts + 1] = apT("saves.last", { date = last })
    end
    if #facts == 0 then
        facts[1] = apT("saves.empty")
    end
    return table.concat(facts, "   ")
end

local function draw()
    local g = geometry()
    local p = g.panel
    local current = apSavesCurrent()
    local pending = tostring(call("PendingProfile") or "")
    local ids = list()
    ui.shade()
    ui.window(p.x, p.y, p.w, p.h, "border")
    ui.text(13, p.x + 20, p.y + 18, p.w - 40, "title", apT("saves.title"))
    ui.wrapped(9, p.x + 20, p.y + 44, p.w - 40, "dim", apT("saves.intro"))
    for slot = 1, VISIBLE_ROWS do
        local id = ids[slot + scroll]
        local row = g.rows[slot]
        if id ~= nil then
            local isCurrent = id == current
            local isPending = id == pending
            ui.rect(row.box.x, row.box.y, row.box.w, row.box.h, isCurrent and "hover" or "card")
            ui.outline(row.box.x, row.box.y, row.box.w, row.box.h, isCurrent and "good" or "faint", 1)
            ui.text(11, row.box.x + 12, row.box.y + 8, row.box.w - 270, "title", rowTitle(id))
            ui.text(9, row.box.x + 12, row.box.y + 28, row.box.w - 270, "dim", rowFacts(id))
            if isCurrent then
                ui.textRight(10, row.archive.x + row.archive.w, row.box.y + 17, 220, "good", apT("saves.current"))
            elseif isPending then
                ui.textRight(10, row.archive.x + row.archive.w, row.box.y + 17, 220, "warn", apT("saves.pending"))
            else
                ui.button(row.load, apT("saves.load"), "primary")
                ui.button(row.archive, apT(confirmArchive == id and "saves.archive.sure" or "saves.archive"),
                    confirmArchive == id and "danger" or "secondary")
            end
        end
    end
    if #ids > VISIBLE_ROWS then
        ui.button(g.up, "<", "secondary", scroll == 0)
        ui.button(g.down, ">", "secondary", scroll + VISIBLE_ROWS >= #ids)
    end
    if status ~= nil then
        ui.wrapped(9, p.x + 120, g.close.y + 4, p.w - 300, statusTone, status)
    end
    ui.button(g.close, apT("saves.close"), "secondary")
end

local function loadProfile(id)
    if not apSavesSwitch(id) then
        status, statusTone = apT("saves.failed"), "warn"
        return
    end
    local relaunch = _G.apNetRelaunchWhenClosed and apNetRelaunchWhenClosed() or false
    status, statusTone = apT(relaunch and "saves.relaunch" or "saves.restart"), "good"
    savesLog("closing FTL to load " .. id .. (relaunch and ", relaunch planned" or ", relaunch by hand"))
    pcall(function() Hyperspace.App:OnExit() end)
end

local function click(x, y)
    local g = geometry()
    if inside(g.close, x, y) or not inside(g.panel, x, y) then
        open = false
        confirmArchive = nil
        return
    end
    local ids = list()
    if inside(g.up, x, y) and scroll > 0 then
        scroll = scroll - 1
        return
    end
    if inside(g.down, x, y) and scroll + VISIBLE_ROWS < #ids then
        scroll = scroll + 1
        return
    end
    local current = apSavesCurrent()
    for slot = 1, VISIBLE_ROWS do
        local id = ids[slot + scroll]
        local row = g.rows[slot]
        if id ~= nil and id ~= current then
            if inside(row.load, x, y) then
                confirmArchive = nil
                loadProfile(id)
                return
            end
            if inside(row.archive, x, y) then
                if confirmArchive ~= id then
                    confirmArchive = id
                    return
                end
                confirmArchive = nil
                local done = call("ArchiveProfile", id) == true
                status, statusTone = apT(done and "saves.archived" or "saves.failed"), done and "dim" or "warn"
                savesLog("archive " .. id .. (done and ": moved to ap_profiles/archived" or ": refused"))
                scroll = 0
                return
            end
        end
    end
    confirmArchive = nil
end

function apSavesOpen()
    if not apSavesSupported() then
        return false
    end
    pcall(apSavesDescribe)
    open = true
    scroll = 0
    confirmArchive = nil
    status = nil
    return true
end

function apSavesIsOpen()
    return open
end

function apSavesClick(x, y)
    if not open then
        return false
    end
    apTry(TAG, click, x, y)
    return true
end

function apSavesDraw()
    if open then
        apTry(TAG, draw)
    end
end

function apSavesCloseForTesting()
    open = false
end

savesLog("save profiles loaded")
