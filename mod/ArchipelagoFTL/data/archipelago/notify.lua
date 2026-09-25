local TAG = "[AP-notify] "

local DISPLAY = {
    x = 100,
    y = 100,
    font = 10,
    lineLength = 460,
    messageLimit = 6,
    duration = 7,
}

local Y_MENU = 250

local function place(y)
    pcall(function()
        Hyperspace.PrintHelper.GetInstance().y = y
    end)
end

function apNotifyPlaceMenu()
    place(Y_MENU)
end

function apNotifyPlaceRun()
    place(DISPLAY.y)
end

local function configureDisplay()
    local ok, err = pcall(function()
        local helper = Hyperspace.PrintHelper.GetInstance()
        helper.x = DISPLAY.x
        helper.y = DISPLAY.y
        helper.font = DISPLAY.font
        helper.lineLength = DISPLAY.lineLength
        helper.messageLimit = DISPLAY.messageLimit
        helper.duration = DISPLAY.duration
    end)
    if not ok then
        log(TAG .. "display setup failed: " .. tostring(err))
    end
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

-- A quiet tick prints one line per entry; a burst (several checks/items landing at once,
-- e.g. after reconnecting) collapses to a single "N received" line instead of flooding it.
local function flushQueue(queue, lineFor, manyKey)
    local count = #queue
    if count == 0 then
        return queue
    end
    if count <= GROUP_ABOVE then
        for _, entry in ipairs(queue) do
            print(lineFor(entry))
        end
    else
        print(apT(manyKey, { n = count }))
    end
    return {}
end

local function flushAll()
    pendingItems = flushQueue(pendingItems, itemLine, "item.received.many")
    pendingChecks = flushQueue(pendingChecks,
        function(name) return apT("check.sent", { location = name }) end, "check.sent.many")
end

script.on_internal_event(Defines.InternalEvents.ON_TICK, flushAll)

function apNotifyFlushForTesting()
    flushAll()
end

function apNotifyResetForTesting()
    pendingChecks = {}
    pendingItems = {}
end

function apNotifyTrap(description)
    print(apT("trap.sprung", { what = description }))
end

function apNotifyStatus(message)
    print(apT("status.prefix", { message = message }))
end

configureDisplay()
script.on_init(function()
    configureDisplay()
    apNotifyPlaceRun()
end)
script.on_internal_event(Defines.InternalEvents.MAIN_MENU, configureDisplay)

log(TAG .. "display module loaded")
