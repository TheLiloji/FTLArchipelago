local TAG = "[AP-notify] "

-- FTL keeps the text of every message (and the tests read it there), but the mod draws them itself.
local HIDDEN_X = -4000

local TOAST = {
    life = 6 * 60,
    fade = 45,
    max = 4,
    keptLife = 15 * 60,
    width = { run = 300, menu = 460 },
    gap = 6,
}

local AREA = {
    run = { x = 12, bottom = 588 },
    menu = { x = 62, top = 262 },
}

local toasts = {}
local area = "run"
local hidden = false

local function configureDisplay()
    local ok, err = pcall(function()
        local helper = Hyperspace.PrintHelper.GetInstance()
        helper.x = HIDDEN_X
        helper.messageLimit = 6
        helper.duration = 7
    end)
    if not ok then
        log(TAG .. "display setup failed: " .. tostring(err))
    end
end

-- A kept message (the goal) is not pushed out by the burst of items that often follows it.
local function push(text, tone, kept)
    toasts[#toasts + 1] = { text = tostring(text), tone = tone or "text", age = 0,
                            life = kept and TOAST.keptLife or TOAST.life, kept = kept }
    while #toasts > TOAST.max do
        local oldest = 1
        for index, toast in ipairs(toasts) do
            if not toast.kept then oldest = index break end
        end
        table.remove(toasts, oldest)
    end
end

-- Takes back a message that is no longer true, such as a refusal the player just answered.
function apNotifyWithdraw(text)
    for index = #toasts, 1, -1 do
        if toasts[index].text == tostring(text) then
            table.remove(toasts, index)
        end
    end
end

function apNotifyHide(value)
    hidden = value == true
end

function apNotifyPlaceMenu()
    area = "menu"
end

function apNotifyPlaceRun()
    area = "run"
end

local function toastHeight(text, w)
    local lines
    local ok, size = pcall(function()
        return Graphics.freetype.easy_measurePrintLines(10, 0, 0, w, text)
    end)
    if ok and size ~= nil and tonumber(size.y) then
        lines = math.max(1, math.floor((size.y + 4) / 14))
    else
        lines = math.max(1, math.ceil(apUi.width(10, text) / w))
    end
    return 12 + lines * 14
end

function apDrawToasts()
    if hidden or #toasts == 0 then
        return
    end
    local ui = apUi
    local w = TOAST.width[area]
    local y = AREA.run.bottom
    if area == "menu" then
        y = math.max(AREA.menu.top, (_G.apGoalBoxBottom or 0) + 12)
    end
    for index = #toasts, 1, -1 do
        local toast = toasts[index]
        local h = toastHeight(toast.text, w - 24)
        local left = toast.life - toast.age
        local alpha = left < TOAST.fade and math.max(0, left / TOAST.fade) or 1
        local top = area == "menu" and y or (y - h)
        local x = AREA[area].x
        ui.rect(x, top, w, h, "window", 0.92 * alpha)
        ui.rect(x, top, 3, h, toast.tone, alpha)
        ui.wrapped(10, x + 14, top + 6, w - 24, "text", toast.text, alpha)
        if area == "menu" then
            y = y + h + TOAST.gap
        else
            y = top - TOAST.gap
        end
    end
    for index = #toasts, 1, -1 do
        toasts[index].age = toasts[index].age + 1
        if toasts[index].age >= toasts[index].life then
            table.remove(toasts, index)
        end
    end
end

function apToastsForTesting()
    return toasts
end

local GROUP_ABOVE = 3
local pendingChecks = {}
local pendingItems = {}

local function itemLine(item)
    if item.fromServer then
        return apT("item.received.server", { item = item.name })
    elseif item.sender and item.sender ~= "" then
        return apT("item.received.from", { item = item.name, sender = item.sender })
    end
    return apT("item.received", { item = item.name })
end

function apNotifyItem(itemName, sender, fromServer)
    pendingItems[#pendingItems + 1] = { name = tostring(itemName), sender = sender,
                                        fromServer = fromServer }
end

function apNotifyCheck(locationName)
    pendingChecks[#pendingChecks + 1] = tostring(locationName)
end

local pendingWaiting = {}
local pendingCargo = {}

function apNotifyWaiting(itemName, reason)
    if reason == "cargo" then
        pendingCargo[#pendingCargo + 1] = tostring(itemName)
    else
        pendingWaiting[#pendingWaiting + 1] = tostring(itemName)
    end
end

-- A quiet tick shows one line per entry; a burst (several checks/items landing at once,
-- e.g. after reconnecting) collapses to a single "N received" line instead of flooding it.
local function flushQueue(queue, lineFor, manyKey, tone)
    local count = #queue
    if count == 0 then
        return queue
    end
    if count <= GROUP_ABOVE then
        for _, entry in ipairs(queue) do
            local line = lineFor(entry)
            print(line)
            push(line, tone)
        end
    else
        local line = apT(manyKey, { n = count })
        print(line)
        push(line, tone)
    end
    return {}
end

local function flushAll()
    pendingItems = flushQueue(pendingItems, itemLine, "item.received.many", "good")
    pendingChecks = flushQueue(pendingChecks,
        function(name) return apT("check.sent", { location = name }) end, "check.sent.many", "border")
    pendingWaiting = flushQueue(pendingWaiting,
        function(name) return apT("item.waiting_augment", { name = name }) end, "item.waiting_augment.many", "title")
    pendingCargo = flushQueue(pendingCargo,
        function(name) return apT("item.waiting_cargo", { name = name }) end, "item.waiting_cargo.many", "title")
end

script.on_internal_event(Defines.InternalEvents.ON_TICK, flushAll)

function apNotifyFlushForTesting()
    flushAll()
end

function apNotifyResetForTesting()
    pendingChecks = {}
    pendingItems = {}
    pendingWaiting = {}
    pendingCargo = {}
    toasts = {}
end

function apNotifyTrap(description)
    local line = apT("trap.sprung", { what = description })
    print(line)
    push(line, "bad")
end

function apNotifyStatus(message)
    print(apT("status.prefix", { message = message }))
    push(message, "title")
end

function apNotifyKept(message)
    print(apT("status.prefix", { message = message }))
    push(message, "good", true)
end

script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, function() end, function()
    if (_G.apDashboardOpen and apDashboardOpen()) or (_G.apLoadoutOpen and apLoadoutOpen()) then return end
    pcall(apDrawToasts)
end)

configureDisplay()
script.on_init(function()
    configureDisplay()
    apNotifyPlaceRun()
end)
script.on_internal_event(Defines.InternalEvents.MAIN_MENU, configureDisplay)

log(TAG .. "display module loaded")
