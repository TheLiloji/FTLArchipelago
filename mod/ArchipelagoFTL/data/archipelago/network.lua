local TAG = "[AP-net] "

local function netLog(message)
    log(TAG .. message)
end

local RETRY_DELAYS = { 5, 10, 20, 40, 60 }

local state = {
    available = false,
    connecting = false,
    connected = false,
    lastConnection = nil,
    retries = 0,
    retryAt = nil,
    ticks = 0,
    lastItemIndex = -1,
    consumedUntil = -1,
    delivered = {},
    scoutsPending = false,
    scouted = {},
}

_G.apNetState = state

function apNetResetForTesting()
    state.connecting = false
    state.connected = false
    state.lastConnection = nil
    state.retries = 0
    state.retryAt = nil
    state.ticks = 0
    state.lastItemIndex = -1
    state.consumedUntil = -1
    state.delivered = {}
    state.scoutsPending = false
    state.scouted = {}
    state.seedRefused = false
    state.refusal = nil
    if _G.apNetForgetDurableStore then _G.apNetForgetDurableStore() end
end

local function client()
    local ok, instance = pcall(function()
        return Hyperspace.Archipelago and Hyperspace.Archipelago.Instance()
    end)
    if ok and instance ~= nil then
        return instance
    end
    return nil
end

local function whenConnected(action)
    local ap = client()
    if ap == nil or not state.connected then
        return false
    end
    return action(ap)
end

function apNetConnect(uri, slot, password)
    local ap = client()
    if ap == nil then
        netLog("network module missing: the mod stays in local mode")
        return false
    end
    state.connecting = true
    state.refusal = nil
    state.unreachableShown = false
    state.unreachableSince = nil
    state.seedRefused = false
    state.lastItemIndex = -1
    state.lastConnection = { uri = uri, slot = slot, password = password or "" }
    state.retries = 0
    state.retryAt = nil
    netLog("connecting to " .. tostring(uri) .. " (slot " .. tostring(slot) .. ")")
    return ap:Connect(uri, slot, password or "")
end

function apNetLastConnection()
    local ap = client()
    if ap == nil then
        return nil
    end
    local ok, uri, slot = pcall(function()
        return tostring(ap:LastUri()), tostring(ap:LastSlot())
    end)
    if not ok or uri == nil or uri == "" then
        return nil
    end
    return { uri = uri, slot = slot ~= "" and slot or nil }
end

function apNetRequestProfileReset()
    local ap = client()
    if ap == nil then
        return false
    end
    local ok, requested = pcall(function() return ap:RequestProfileReset() end)
    return ok and requested ~= false
end

function apNetRelaunchWhenClosed()
    local ap = client()
    if ap == nil then
        return false
    end
    local ok, planned = pcall(function() return ap:RelaunchWhenClosed() end)
    return ok and planned == true
end

function apNetProfileResetRequested()
    local ap = client()
    if ap == nil then
        return false
    end
    local ok, requested = pcall(function() return ap:ProfileResetRequested() end)
    return ok and requested == true
end

function apNetDisconnect()
    local ap = client()
    if ap ~= nil then
        ap:Disconnect()
    end
    state.connected = false
    state.lastConnection = nil
    state.retryAt = nil
    state.retries = 0
end

local function scheduleRetry()
    if state.lastConnection == nil then
        return
    end
    state.retries = state.retries + 1
    local delay = RETRY_DELAYS[math.min(state.retries, #RETRY_DELAYS)]
    state.retryAt = state.ticks + delay * 60
    netLog(string.format("reconnecting in %d s (attempt %d)", delay, state.retries))
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT("net.retrying", { n = delay }))
    end
end

local UNREACHABLE_DELAY = 6 * 60

local function announceIfStillUnreachable()
    if state.unreachableSince == nil then
        return
    end
    if state.connected then
        state.unreachableSince = nil
        return
    end
    if state.ticks - state.unreachableSince < UNREACHABLE_DELAY then
        return
    end
    state.unreachableSince = nil
    state.unreachableShown = true
    netLog("server still unreachable, the player has been warned")
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT("net.error.unreachable"))
    end
end

local function retryIfDue()
    if state.retryAt == nil or state.connected or state.ticks < state.retryAt then
        return
    end
    state.retryAt = nil
    local target = state.lastConnection
    if target == nil then
        return
    end
    local ap = client()
    if ap == nil then
        return
    end
    netLog("new connection attempt")
    state.connecting = true
    local ok = pcall(function()
        return ap:Connect(target.uri, target.slot, target.password)
    end)
    if not ok then
        scheduleRetry()
    end
end

function apNetAnnounceTags()
    return whenConnected(function(ap)
        local tags = Hyperspace.vector_string()
        if _G.apDeathLink and _G.apDeathLink.enabled then tags:push_back("DeathLink") end
        if _G.apTrapLink and _G.apTrapLink.enabled then tags:push_back("TrapLink") end
        local ok, sent = pcall(function() return ap:SetTags(tags) end)
        return ok and sent == true
    end)
end

function apNetHintLocation(name)
    return whenConnected(function(ap)
        local ok, sent = pcall(function() return ap:HintLocation(name) end)
        return ok and sent == true
    end)
end

function apNetSendCheck(checkId)
    return whenConnected(function(ap) return ap:SendCheck(checkId) end)
end

function apNetSendDeath(cause)
    return whenConnected(function(ap) return ap:SendDeath(tostring(cause or "died")) end)
end

function apNetSendTrap(trapName)
    return whenConnected(function(ap) return ap:SendTrap(tostring(trapName or "Trap")) end)
end

function apNetEnergyLinkDeposit(joules)
    return whenConnected(function(ap) return ap:EnergyDeposit(math.floor(joules)) end)
end

function apNetEnergyLinkRequest(joules)
    return whenConnected(function(ap) return ap:EnergyRequest(math.floor(joules)) end)
end

function apNetSendGoal()
    return whenConnected(function(ap)
        netLog("goal reached: StatusUpdate(GOAL)")
        return ap:SendGoal()
    end)
end

local UNKNOWN = "Unknown"

local CONSUMED_KEY = "ap_items_done"
local SEED_KEY = "ap_seed_tag"

local durableStore = nil

local function store()
    if durableStore ~= nil then
        return durableStore or nil
    end
    local ap = client()
    if ap == nil then return nil end
    local ok = pcall(function() return ap:RecallState(SEED_KEY) end)
    durableStore = ok and ap or false
    if not ok then
        netLog("network module has no durable memory: falling back to the FTL profile")
    end
    return durableStore or nil
end

function apNetForgetDurableStore()
    durableStore = nil
end

local function meta(key)
    local ap = store()
    if ap ~= nil then
        local ok, value = pcall(function() return ap:RecallState(key) end)
        if ok and value ~= nil and value ~= "" then return tonumber(value) or 0 end
    end
    local ok, value = pcall(function() return Hyperspace.metaVariables[key] end)
    return ok and tonumber(value) or 0
end

local function writeMeta(key, value)
    local ap = store()
    if ap ~= nil then
        pcall(function() ap:RememberState(key, tostring(value)) end)
    end
    pcall(function() Hyperspace.metaVariables[key] = value end)
end

function apNetSeedTag()
    return meta(SEED_KEY)
end

function apNetRecall(key)
    return meta(key)
end

function apNetRemember(key, value)
    writeMeta(key, value)
end

function apNetRememberText(key, value)
    local ap = store()
    if ap ~= nil then
        pcall(function() ap:RememberState(key, tostring(value)) end)
    end
end

function apNetRecallText(key)
    local ap = store()
    if ap == nil then return "" end
    local ok, value = pcall(function() return ap:RecallState(key) end)
    return ok and value ~= nil and tostring(value) or ""
end

-- Each seed keeps its own count of consumed items, so coming back to a seed played before does not hand out
-- its scrap and traps a second time.
local function consumedKey(fingerprint)
    return CONSUMED_KEY .. "_" .. tostring(fingerprint or 0)
end

-- Older versions kept one count for whichever seed was current: it moves to that seed's own count.
local function migrateOldCount()
    local old = meta(CONSUMED_KEY)
    if old <= 0 then
        return
    end
    local tag = meta(SEED_KEY)
    if meta(consumedKey(tag)) == 0 then
        writeMeta(consumedKey(tag), old)
    end
    writeMeta(CONSUMED_KEY, 0)
end

local function consumedFor(fingerprint)
    migrateOldCount()
    return meta(consumedKey(fingerprint))
end

function apNetRememberSeed(fingerprint)
    state.consumedUntil = consumedFor(fingerprint) - 1
    writeMeta(SEED_KEY, fingerprint or 0)
    state.delivered = {}
    netLog("seed fingerprint recorded: " .. tostring(fingerprint))
end

function apNetForgetProgress(incoming)
    writeMeta(consumedKey(meta(SEED_KEY)), 0)
    if incoming ~= nil then writeMeta(consumedKey(incoming), 0) end
    writeMeta(SEED_KEY, 0)
    writeMeta(CONSUMED_KEY, 0)
    state.consumedUntil = -1
    state.delivered = {}
    netLog("Archipelago progress forgotten: the next seed starts from zero")
end

local function reloadConsumed()
    local fingerprint = _G.apSeedFingerprint and _G.apSeedFingerprint() or 0
    state.consumedUntil = consumedFor(fingerprint) - 1
    state.delivered = {}
    if meta(SEED_KEY) ~= fingerprint then
        writeMeta(SEED_KEY, fingerprint)
        if state.consumedUntil < 0 then
            netLog("new seed: resources already received start over from zero")
            return
        end
    end
    if state.consumedUntil >= 0 then
        netLog(string.format("%d resource(s) already consumed in previous sessions",
            state.consumedUntil + 1))
    end
end

local function onConnected(event)
    local wasRetrying = state.retries > 0
    state.connected = true
    state.connecting = false
    state.retries = 0
    state.retryAt = nil
    netLog("connected as \"" .. tostring(event.name) .. "\"")
    state.seedRefused = false

    local slotData = event.extra
    if type(slotData) == "string" and _G.apJsonDecode then
        local decoded, err = _G.apJsonDecode(slotData)
        if decoded ~= nil then
            netLog("slot_data decoded: " .. #slotData .. " bytes of JSON")
            slotData = decoded
        else
            netLog("slot_data UNREADABLE (" .. #slotData .. " bytes): " .. tostring(err))
        end
    end

    if type(slotData) == "table" then
        netLog("slot_data received as a table")
        if _G.apApplySlotData then
            local accepted = _G.apApplySlotData(slotData, event.name)
            netLog(accepted ~= false and "seed accepted" or "SEED REFUSED (see [AP-contract])")
            state.seedRefused = accepted == false
        end
    else
        netLog("slot_data received as TEXT (" .. #tostring(event.extra) .. " bytes): "
            .. "the C++ module must turn it into a Lua table, nothing was applied")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("net.slot_data_unreadable"))
        end
    end

    -- Said after the seed check: "nothing was lost" followed by a refusal would contradict itself.
    if _G.apNotifyStatus and not state.seedRefused then
        _G.apNotifyStatus(apT(wasRetrying and "net.reconnected" or "net.connected",
                              { slot = tostring(event.name) }))
    end

    if _G.apOnSlotData then
        pcall(_G.apOnSlotData, event.extra)
    end

    if not state.seedRefused then
        reloadConsumed()
    end

    if not state.seedRefused then
        apNetAnnounceTags()
    end

    if _G.apAdoptCheckedLocations then
        local ap = client()
        if ap ~= nil and ap.CheckedLocations ~= nil then
            local ok, names = pcall(function() return ap:CheckedLocations() end)
            if ok and names ~= nil then
                local list = {}
                for i = 0, names:size() - 1 do
                    local name = tostring(names[i])
                    if name ~= UNKNOWN then
                        list[#list + 1] = name
                    end
                end
                pcall(_G.apAdoptCheckedLocations, list)
            else
                netLog("CheckedLocations unavailable: the check counter starts over from zero")
            end
        end
    end

    if _G.apResendPendingChecks then
        pcall(_G.apResendPendingChecks)
    end

    if _G.apDeclareGoal then
        pcall(_G.apDeclareGoal)
    end

    if _G.apShopSlotKeys and _G.apLocationNameFor then
        local names = {}
        for _, key in ipairs(_G.apShopSlotKeys()) do
            local name = _G.apLocationNameFor(key)
            if name then
                names[#names + 1] = name
            end
        end
        if #names > 0 then
            local ap = client()
            if ap ~= nil then
                state.scoutsPending = true
                state.scouted = {}
                local vector = Hyperspace.vector_string()
                for _, name in ipairs(names) do
                    vector:push_back(name)
                end
                ap:ScoutLocations(vector)
                netLog(#names .. " shop slot(s) to scout")
            end
        end
    end
end

local function classify(flags)
    flags = math.floor(flags or 0)
    if flags % 8 >= 4 then return "trap" end
    if flags % 2 == 1 then return "progression" end
    if flags % 4 >= 2 then return "useful" end
    return "filler"
end

local function onScout(event)
    local key = _G.apCheckKeyFor and _G.apCheckKeyFor(event.name) or event.name
    if tostring(key):sub(1, 5) ~= "shop:" then
        return
    end
    state.scouted[#state.scouted + 1] = {
        location = key,
        slot = event.sender,
        item = event.extra,
        kind = classify(event.value),
        sphere = nil,
    }
end

local function onItem(event)
    if event.index >= 0 and event.index <= state.lastItemIndex then
        return
    end
    if tostring(event.name) == UNKNOWN then
        netLog("item received before the data packet, asked again once it is in")
        return
    end
    if event.index >= 0 then
        state.lastItemIndex = event.index
    end

    local isReplay = event.index >= 0 and event.index <= state.consumedUntil

    if _G.apReceiveItem then
        local sender = tostring(event.sender)
        if sender == "" then
            sender = nil
        end
        _G.apReceiveItem(event.name, sender, isReplay, event.index)
    end
end

function apNetItemDelivered(index)
    index = tonumber(index)
    if index == nil or index < 0 or index <= state.consumedUntil then
        return false
    end
    state.delivered[index] = true
    local advanced = false
    while state.delivered[state.consumedUntil + 1] do
        state.consumedUntil = state.consumedUntil + 1
        state.delivered[state.consumedUntil] = nil
        advanced = true
    end
    if advanced then
        local fingerprint = _G.apSeedFingerprint and _G.apSeedFingerprint() or 0
        writeMeta(consumedKey(fingerprint), state.consumedUntil + 1)
    end
    return advanced
end

local REFUSAL_KEYS = {
    InvalidSlot = "net.refused.slot",
    InvalidGame = "net.refused.game",
    InvalidPassword = "net.refused.password",
    IncompatibleVersion = "net.refused.version",
    InvalidItemsHandling = "net.refused.items",
}

local function onRefused(event)
    state.connecting = false
    state.connected = false
    state.unreachableSince = nil
    state.retryAt = nil
    state.retries = 0
    state.lastConnection = nil

    local reasons = tostring(event.extra or "")
    netLog("connection refused by the server: " .. (reasons ~= "" and reasons or "no reason given"))

    local said = {}
    for reason in reasons:gmatch("[^,]+") do
        reason = reason:match("^%s*(.-)%s*$")
        local key = REFUSAL_KEYS[reason]
        if key ~= nil then
            said[#said + 1] = apT(key)
        elseif reason ~= "" then
            said[#said + 1] = apT("net.refused.other", { reason = reason })
        end
    end
    if #said == 0 then
        said[1] = apT("net.refused.unknown")
    end
    state.refusal = said[1]
    if _G.apNotifyStatus then
        for _, line in ipairs(said) do
            _G.apNotifyStatus(line)
        end
    end
end

local ERROR_KEYS = {
    socket = "net.error.socket",
    location = "net.error.location",
    unreachable = "net.error.unreachable",
}

local HANDLERS = {
    connected = onConnected,
    refused = onRefused,
    item = onItem,
    scout = onScout,
    hint = function(event)
        if _G.apHintReceived then
            _G.apHintReceived({
                item = tostring(event.name),
                receiver = tostring(event.sender),
                finder = tostring(event.other),
                location = tostring(event.extra),
                found = tonumber(event.value) == 1,
                known = tonumber(event.index) == 1,
            })
        end
    end,

    disconnected = function()
        local wasConnected = state.connected
        state.connected = false
        state.connecting = false
        netLog("disconnected")
        if wasConnected and _G.apNotifyStatus then
            _G.apNotifyStatus(apT("net.disconnected"))
        end
        scheduleRetry()
    end,

    death = function(event)
        if _G.apDeathLinkReceive then
            _G.apDeathLinkReceive(event.sender, event.name)
        end
    end,

    trap = function(event)
        if _G.apTrapLinkReceive then
            _G.apTrapLinkReceive(event.sender, event.name)
        end
    end,

    -- A reply to our own request carries what was taken (0 when the pool was empty); updates from others carry -1.
    energy = function(event)
        if event.index and event.index >= 0 and _G.apEnergyLinkGranted then
            _G.apEnergyLinkGranted(event.index)
        elseif _G.apEnergyLinkSync then
            _G.apEnergyLinkSync(event.value)
        end
    end,

    error = function(event)
        local token = tostring(event.name)
        if token == "unreachable" then
            netLog("unreachable for now: " .. tostring(event.extra))
            if not state.unreachableShown and state.unreachableSince == nil then
                state.unreachableSince = state.ticks
            end
            return
        end
        netLog("ERROR: " .. token
            .. (event.extra ~= "" and (" - " .. tostring(event.extra)) or ""))
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT(ERROR_KEYS[token] or "net.error.unknown"))
        end
    end,
}

local function drain()
    local ap = client()
    if ap == nil then
        return
    end

    local events = ap:TakeEvents()
    local count = events:size()
    if count == 0 then
        return
    end

    for i = 0, count - 1 do
        local event = events[i]
        local handler = HANDLERS[tostring(event.kind)]
        if handler then
            local ok, err = pcall(handler, event)
            if not ok then
                netLog("error handling \"" .. tostring(event.kind) .. "\": " .. tostring(err))
            end
        end
    end

    if state.scoutsPending and #state.scouted > 0 then
        state.scoutsPending = false
        if _G.apShopGiftsScouted then
            local ok, err = pcall(_G.apShopGiftsScouted, state.scouted)
            if not ok then
                netLog("shop not configured after scouting: " .. tostring(err))
            end
        end
    end
end

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    state.ticks = state.ticks + 1
    drain()
    retryIfDue()
    announceIfStillUnreachable()
end)

function apNetConnected()
    return state.connected == true
end

function apNetStatus()
    if client() == nil then
        netLog("network module MISSING (Hyperspace without the Archipelago patch)")
        return
    end
    netLog(string.format("network: %s | last item #%d | %d location(s) scouted",
        state.connected and "connected" or "offline",
        state.lastItemIndex, #state.scouted))
    if state.retryAt ~= nil then
        netLog(string.format("  reconnection scheduled in %.0f s (attempt %d)",
            math.max(0, state.retryAt - state.ticks) / 60, state.retries))
    end
end

state.available = client() ~= nil
netLog(state.available
    and "network module present (console: LUA apNetStatus())"
    or "network module missing: the mod runs locally, everything else works")
