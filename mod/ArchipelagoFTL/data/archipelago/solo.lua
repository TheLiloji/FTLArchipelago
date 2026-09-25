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
local KEY_ITEM = "ap_solo_item_"

local GIFT_KIND = {
    ship = "progression", cap = "progression", start = "progression", archive = "progression",
    filler = "filler", trap = "trap",
}

_G.apSoloEnabled = false

local state = {
    delivered = 0,
    given = {},
    done = false,
    byKey = nil,
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

local stockShop

local function checkKey(entry)
    return _G.apCheckKeyFor and apCheckKeyFor(entry.location) or entry.location
end

local function isShop(key)
    return tostring(key or ""):sub(1, 5) == "shop:"
end

local function indexByKey()
    if state.byKey == nil then
        state.byKey = {}
        for index, entry in ipairs(_G.apSoloOrder or {}) do
            state.byKey[checkKey(entry)] = index
        end
    end
    return state.byKey
end

-- Same as a server: the item placed at that location. A check with no item of its own takes the next
-- one that is not on sale in the shop.
local function pick(reason)
    local index = indexByKey()[reason]
    if index ~= nil and not state.given[index] then
        return index
    end
    local order = _G.apSoloOrder or {}
    for pass = 1, 2 do
        for i = 1, #order do
            if not state.given[i] and (pass == 2 or not isShop(checkKey(order[i]))) then
                return i
            end
        end
    end
    return nil
end

local function give(index, replay)
    state.given[index] = true
    state.delivered = state.delivered + 1
    if not replay then
        remember(KEY_ITEM .. index, 1)
        remember(KEY_GIVEN, state.delivered)
    end
end

local function deliverNext(reason)
    if not _G.apSoloEnabled then
        return false
    end
    local order = _G.apSoloOrder or {}
    local index = pick(reason)
    if index == nil then
        return false
    end

    give(index)
    local entry = order[index]
    if isShop(checkKey(entry)) and checkKey(entry) ~= reason then
        stockShop()
    end
    soloLog(string.format("check %s -> item %d/%d: %s",
        tostring(reason), state.delivered, #order, tostring(entry.item)))

    local received = _G.apReceiveItem and _G.apReceiveItem(entry.item, nil) or false
    if state.delivered >= #order and not state.done then
        state.done = true
        soloLog("all items have been received (" .. #order .. ")")
        notify(apT("solo.complete"))
    end
    return received
end

local function soloGifts()
    local gifts = {}
    local descriptors = (_G.apContractState or {}).itemDescriptors or {}
    for index, entry in ipairs(_G.apSoloOrder or {}) do
        local key = checkKey(entry)
        if isShop(key) and not state.given[index] then
            local descriptor = descriptors[entry.item] or {}
            gifts[#gifts + 1] = { mine = true, item = entry.item, location = key,
                                  kind = GIFT_KIND[descriptor.k] or "useful" }
        end
    end
    return gifts
end

stockShop = function()
    local gifts = soloGifts()
    if _G.apShopGiftsConfigure then
        _G.apShopGiftsConfigure(gifts, "solo")
        soloLog(#gifts .. " item(s) of the seed on sale in the Archipelago shop")
    end
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
        if _G.apApplySlotData(_G.apSoloSlotData, nil, true) == false then
            if _G.apSeedChangeLeftovers and apSeedChangeLeftovers() then
                _G.apSoloPending = true
                soloLog("the profile holds ships from another seed: asking before going solo")
            else
                soloLog("the solo slot_data was rejected by the contract")
            end
            return false
        end
        soloLog("solo slot_data applied")
    end

    local fingerprint = _G.apSeedFingerprint and apSeedFingerprint() or 0
    if _G.apNetSeedTag and _G.apNetRememberSeed and apNetSeedTag() ~= fingerprint then
        apNetRememberSeed(fingerprint)
    end

    if _G.apInventoryClear then
        _G.apInventoryClear()
        if _G.apApplySystemRules then pcall(_G.apApplySystemRules) end
    end

    state.byKey = nil

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
    for index = 1, #_G.apSoloOrder do
        if recall(KEY_ITEM .. index) ~= 0 then
            remember(KEY_ITEM .. index, 0)
        end
    end
    state.delivered, state.given, state.done = 0, {}, false
    remember(KEY_GIVEN, 0)
    stockShop()
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
    local indices, listed = {}, {}
    for index = 1, #order do
        if recall(KEY_ITEM .. index) ~= 0 then
            indices[#indices + 1] = index
            listed[index] = true
        end
    end
    -- Older saves only kept a count.
    local legacy = math.min(recall(KEY_GIVEN), #order) - #indices
    for index = 1, #order do
        if legacy <= 0 then break end
        if not listed[index] then
            indices[#indices + 1] = index
            remember(KEY_ITEM .. index, 1)
            legacy = legacy - 1
        end
    end

    _G.apSoloEnabled = true
    state.delivered, state.given = 0, {}
    for _, index in ipairs(indices) do
        give(index, true)
        if _G.apReceiveItem then
            _G.apReceiveItem(order[index].item, nil, true)
        end
    end
    state.done = state.delivered >= #order
    stockShop()
    remember(KEY_ACTIVE, 1)

    soloLog(string.format("solo run resumed: %d/%d items, %d check(s)", state.delivered, #order, #checked))
    notify(apT("solo.resumed", { done = state.delivered, total = #order }))
    return true
end

function apSoloHint(alreadyHinted)
    local candidates = {}
    for index, entry in ipairs(_G.apSoloOrder or {}) do
        local key = checkKey(entry)
        local checked = _G.apCheckAlreadySent and apCheckAlreadySent(key)
        if not state.given[index] and not checked and not (alreadyHinted and alreadyHinted(entry.location)) then
            candidates[#candidates + 1] = entry
        end
    end
    if #candidates == 0 then
        return nil
    end
    return candidates[math.random(1, #candidates)]
end

function apSoloSaved()
    local total = #(_G.apSoloOrder or {})
    local done = math.min(recall(KEY_GIVEN), total)
    if recall(KEY_SEED) == 0 or done == 0 then
        return nil
    end
    return { done = done, total = total }
end

-- startAfter: solo starts again by itself at the next launch.
function apSoloForgetProgress(startAfter)
    remember(KEY_GIVEN, 0)
    remember(KEY_SEED, 0)
    remember(KEY_ACTIVE, startAfter and 1 or 0)
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
    state.delivered, state.given, state.done, state.byKey = 0, {}, false, nil
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
