
local TAG = "[AP-solo] "

local function soloLog(message)
    log(TAG .. message)
end

_G.apSoloEnabled = false

local state = {
    delivered = 0,
}

_G.apSoloState = state

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
            soloLog("all items have been received (" .. #order .. ")")
            if _G.apNotifyStatus then
                _G.apNotifyStatus(apT("solo.complete"))
            end
        end
        return false
    end

    state.delivered = state.delivered + 1
    local entry = order[state.delivered]

    soloLog(string.format("check %s -> item %d/%d: %s",
        tostring(reason), state.delivered, #order, tostring(entry.item)))

    if _G.apReceiveItem then
        return _G.apReceiveItem(entry.item, nil)
    end
    return false
end

function apSoloStart(force)
    if _G.apSoloEnabled and not force then
        local total = #(_G.apSoloOrder or {})
        soloLog("solo mode already running: " .. state.delivered .. "/" .. total)
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("solo.already",
                { done = math.min(state.delivered, total), total = total }))
        end
        return false
    end

    local order = _G.apSoloOrder
    if order == nil or #order == 0 then
        soloLog("no receive order: run apworld/multiworld/make.sh")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("solo.no_order"))
        end
        return false
    end

    local alreadyConnected = _G.apContractState and _G.apContractState.connected
    if not alreadyConnected then
        if _G.apSoloSlotData == nil or _G.apApplySlotData == nil then
            soloLog("no solo slot_data: items could not be recognized")
            if _G.apNotifyStatus then
                _G.apNotifyStatus(apT("solo.no_slot_data"))
            end
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

    state.delivered = 0
    _G.apSoloEnabled = true

    soloLog("solo mode active: " .. #order .. " items to receive, one per check")
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT("solo.started", { count = #order }))
    end
    return true
end

function apSoloStop()
    _G.apSoloEnabled = false
    soloLog("solo mode stopped")
end

function apSoloResetForTesting()
    _G.apSoloEnabled = false
    state.delivered = 0
end

local previousSendCheck = _G.apSendCheck
_G.apSendCheck = function(id, label)
    local sent = previousSendCheck and previousSendCheck(id, label)
    if sent then
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
