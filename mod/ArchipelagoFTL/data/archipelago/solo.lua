local TAG = "[AP-solo] "

local function soloLog(message)
    log(TAG .. message)
end

local function notify(text)
    if _G.apNotifyStatus then
        _G.apNotifyStatus(text)
    end
end

local KEY_ACTIVE = "ap_solo_active"
local KEY_GIVEN = "ap_solo_given"
local KEY_SEED = "ap_solo_seed"
local KEY_CHECK = "ap_solo_check_"

_G.apSoloEnabled = false

local state = {
    delivered = 0,
}

_G.apSoloState = state

local function recall(key)
    return _G.apNetRecall and _G.apNetRecall(key) or 0
end

local function remember(key, value)
    if _G.apNetRemember then
        _G.apNetRemember(key, value)
    end
end

local function locationKeys()
    local keys = {}
    for key in pairs((_G.apContractState or {}).locNames or {}) do
        keys[#keys + 1] = key
    end
    return keys
end

local function remaining()
    local order = _G.apSoloOrder or {}
    return math.max(0, #order - state.delivered)
end

local function deliverNext(reason)
    if not _G.apSoloEnabled then
        return false
    end
    local order = _G.apSoloOrder or {}
    if state.delivered >= #order then
        if state.delivered == #order and #order > 0 then
            state.delivered = state.delivered + 1
            remember(KEY_GIVEN, state.delivered)
            soloLog("all items have been received (" .. #order .. ")")
            notify(apT("solo.complete"))
        end
        return false
    end

    state.delivered = state.delivered + 1
    remember(KEY_GIVEN, state.delivered)
    local entry = order[state.delivered]

    soloLog(string.format("check %s -> item %d/%d: %s",
        tostring(reason), state.delivered, #order, tostring(entry.item)))

    if _G.apReceiveItem then
        return _G.apReceiveItem(entry.item, nil)
    end
    return false
end

local function loadSeed()
    local order = _G.apSoloOrder
    if order == nil or #order == 0 then
        soloLog("no receive order: run apworld/multiworld/make.sh")
        notify(apT("solo.no_order"))
        return false
    end

    if not (_G.apContractState and _G.apContractState.connected) then
        if _G.apSoloSlotData == nil or _G.apApplySlotData == nil then
            soloLog("no solo slot_data: items could not be recognized")
            notify(apT("solo.no_slot_data"))
            return false
        end
        if _G.apApplySlotData(_G.apSoloSlotData) == false then
            soloLog("the solo slot_data was rejected by the contract")
            return false
        end
        soloLog("solo slot_data applied")
    end

    if _G.apInventoryClear then
        _G.apInventoryClear()
        if _G.apApplySystemRules then pcall(_G.apApplySystemRules) end
    end

    if _G.apShopGiftsConfigure and _G.apGiftsDemo and #_G.apGiftsDemo > 0
        and #(_G.apShopGifts or {}) == 0 then
        _G.apShopSlotCount = math.max(_G.apShopSlotCount or 0, #_G.apGiftsDemo)
        _G.apShopGiftsConfigure(_G.apGiftsDemo, "demo")
        soloLog(#_G.apGiftsDemo .. " gift(s) installed in the Archipelago shop")
    end

    if _G.apForgetChecks then apForgetChecks() end
    return true
end

function apSoloStart(force)
    if _G.apSoloEnabled and not force then
        local total = #(_G.apSoloOrder or {})
        soloLog("solo mode already running: " .. state.delivered .. "/" .. total)
        notify(apT("solo.already", { done = math.min(state.delivered, total), total = total }))
        return false
    end

    if not loadSeed() then
        return false
    end

    for _, key in ipairs(locationKeys()) do
        if recall(KEY_CHECK .. key) ~= 0 then
            remember(KEY_CHECK .. key, 0)
        end
    end
    state.delivered = 0
    remember(KEY_GIVEN, 0)
    remember(KEY_SEED, _G.apSeedFingerprint and apSeedFingerprint() or 0)
    remember(KEY_ACTIVE, 1)
    _G.apSoloEnabled = true

    local order = _G.apSoloOrder
    soloLog("solo mode active: " .. #order .. " items to receive, one per check")
    notify(apT("solo.started", { count = #order }))
    return true
end

function apSoloResume()
    if _G.apSoloEnabled then
        return false
    end
    if not loadSeed() then
        return false
    end

    local fingerprint = _G.apSeedFingerprint and apSeedFingerprint() or 0
    if recall(KEY_SEED) ~= fingerprint then
        soloLog("the saved solo run belongs to another seed: starting over")
        return apSoloStart(true)
    end

    local checked = {}
    for _, key in ipairs(locationKeys()) do
        if recall(KEY_CHECK .. key) ~= 0 then
            checked[#checked + 1] = key
        end
    end
    if _G.apRestoreSentChecks then apRestoreSentChecks(checked) end

    local order = _G.apSoloOrder
    local given = math.min(recall(KEY_GIVEN), #order)
    _G.apSoloEnabled = true
    if _G.apReceiveItem then
        for index = 1, given do
            _G.apReceiveItem(order[index].item, nil, true)
        end
    end
    state.delivered = recall(KEY_GIVEN)
    remember(KEY_ACTIVE, 1)

    soloLog(string.format("solo run resumed: %d/%d items, %d check(s)", given, #order, #checked))
    notify(apT("solo.resumed", { done = given, total = #order }))
    return true
end

function apSoloSaved()
    local total = #(_G.apSoloOrder or {})
    local done = math.min(recall(KEY_GIVEN), total)
    if recall(KEY_SEED) == 0 or done == 0 then
        return nil
    end
    return { done = done, total = total }
end

function apSoloWasActive()
    return recall(KEY_ACTIVE) == 1
end

function apSoloStop()
    _G.apSoloEnabled = false
    remember(KEY_ACTIVE, 0)
    soloLog("solo mode stopped, progress kept")
    if _G.apContractUnload then apContractUnload() end
end

function apSoloResetForTesting()
    _G.apSoloEnabled = false
    state.delivered = 0
end

local previousSendCheck = _G.apSendCheck
_G.apSendCheck = function(id, label)
    local sent = previousSendCheck and previousSendCheck(id, label)
    if sent and _G.apSoloEnabled then
        remember(KEY_CHECK .. id, 1)
        apTry(TAG, deliverNext, id)
    end
    return sent
end

function apSoloStatus()
    local order = _G.apSoloOrder or {}
    if not _G.apSoloEnabled then
        soloLog("solo mode inactive (" .. #order .. " items available)")
        return
    end
    soloLog(string.format("solo mode: %d/%d items received, %d remaining",
        math.min(state.delivered, #order), #order, remaining()))
end

soloLog("solo mode loaded, inactive (console: LUA apSoloStart())")
