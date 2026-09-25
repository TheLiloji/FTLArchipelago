local TAG = "[AP-contract] "

local function contractLog(message)
    log(TAG .. message)
end

local AP_CONTRACT_MIN = 1
local AP_CONTRACT_MAX = 3

_G.apContractRange = { min = AP_CONTRACT_MIN, max = AP_CONTRACT_MAX }

local state = {
    connected = false,
    contract = nil,
    refusal = nil,
    unknownItems = 0,
    unknownKinds = {},
    itemDescriptors = {},
}

_G.apContractState = state

local function missingKinds(kinds)
    local missing = {}
    for _, kind in ipairs(kinds or {}) do
        if not (_G.apSupportedKinds or {})[kind] then
            missing[#missing + 1] = kind
        end
    end
    return missing
end

local function refuse(reason)
    state.refusal = reason
    state.connected = false
    contractLog("SEED REFUSED: " .. reason)
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT("contract.refused", { reason = reason }))
    end
    return false
end

local function seedsDifferent(before, after)
    if before == nil then
        return false
    end
    if before.hash ~= nil and after.hash ~= nil and before.hash ~= after.hash then
        return true
    end
    if before.slot ~= nil and after.slot ~= nil and before.slot ~= after.slot then
        return true
    end
    return false
end

local function seedIdentity(slotData, slotName)
    local hash = slotData.seed_hash or slotData.seed_name
    local slot = slotName
    if slot == "" then slot = nil end
    return { hash = hash and tostring(hash) or nil, slot = slot and tostring(slot) or nil }
end

function apApplySlotData(slotData, slotName, solo)
    if type(slotData) ~= "table" then
        return refuse(apT("contract.reason.nodata"))
    end

    local identity = seedIdentity(slotData, slotName)

    local onServer = _G.apNetConnected and _G.apNetConnected()
    if onServer or solo then
        local stored = _G.apNetSeedTag and _G.apNetSeedTag() or 0
        local incoming = apSeedFingerprint(identity)
        contractLog(string.format("seed fingerprint: stored %d, incoming %d, hash %s",
            stored, incoming, tostring(identity.hash)))
        if incoming ~= stored
            and _G.apProfileHasShips and _G.apProfileHasShips() then
            state.seedChangedWithUnlocks = true
            state.seedChangeReason = stored == 0 and "foreign" or "seedchange"
            state.refusedFingerprint = incoming
            if onServer and _G.apNetDisconnect then pcall(_G.apNetDisconnect) end
            if state.seedChangeReason == "foreign" then
                return refuse(apT("contract.reason.foreign"))
            end
            return refuse(apT("contract.reason.seedchange"))
        end
    end

    if seedsDifferent(state.identity, identity) then
        contractLog(string.format("seed change: %s/%s -> %s/%s",
            tostring(state.identity.hash), tostring(state.identity.slot),
            tostring(identity.hash), tostring(identity.slot)))
        state.seedChangedWithUnlocks = #((_G.apInventory or {}).ships or {}) > 0
            or (_G.apCheckCount and (_G.apCheckCount().sent or 0) > 0) or false

        if _G.apChecksForgetSeed then pcall(_G.apChecksForgetSeed) end
        if _G.apInventoryClear then pcall(_G.apInventoryClear) end
        if _G.apFillerForgetSeed then pcall(_G.apFillerForgetSeed) end
        if _G.apShopGiftsForgetSeed then pcall(_G.apShopGiftsForgetSeed) end
        if _G.apShopForgetSeed then pcall(_G.apShopForgetSeed) end
        if _G.apHintsForgetSeed then pcall(_G.apHintsForgetSeed) end

    end
    state.identity = {
        hash = identity.hash or (state.identity and state.identity.hash) or nil,
        slot = identity.slot or (state.identity and state.identity.slot) or nil,
    }

    state.refusal = nil
    state.unknownItems = 0
    state.unknownKinds = {}

    if _G.apLangResolve then
        apLangResolve(slotData.language)
    end

    local contract = slotData.contract
    if type(contract) ~= "number" then
        return refuse(apT("contract.reason.nonumber"))
    end
    state.contract = contract
    if contract > AP_CONTRACT_MAX then
        return refuse(apT("contract.reason.toonew",
            { seed = contract, mod = AP_CONTRACT_MAX }))
    end
    if contract < AP_CONTRACT_MIN then
        return refuse(apT("contract.reason.tooold",
            { seed = contract, mod = AP_CONTRACT_MIN }))
    end

    for _, field in ipairs({ "kinds", "kinds_required", "items", "loc", "caps", "goal", "shop",
                             "links", "options" }) do
        local value = slotData[field]
        if value ~= nil and type(value) ~= "table" then
            return refuse(apT("contract.reason.malformed", { field = field }))
        end
    end

    local required = missingKinds(slotData.kinds_required)
    if #required > 0 then
        return refuse(apT("contract.reason.kinds", { list = table.concat(required, ", ") }))
    end
    local optional = missingKinds(slotData.kinds)
    if #optional > 0 then
        contractLog("WARNING: kind(s) not implemented, their items will have no effect: "
            .. table.concat(optional, ", "))
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("contract.partial", { list = table.concat(optional, ", ") }))
        end
    end

    state.goal = slotData.goal
    state.startShip = slotData.start_ship
    state.seedName = slotData.seed_name
    state.options = slotData.options or {}

    state.itemDescriptors = slotData.items or {}
    state.capTotals = slotData.caps or {}
    state.systemCapsActive = slotData.system_caps ~= false
    state.blueprintsActive = slotData.system_blueprints ~= false
    state.locNames = slotData.loc or {}
    state.locKeys = {}
    for key, name in pairs(state.locNames) do
        state.locKeys[name] = key
    end

    if _G.apInventory then
        _G.apInventory.shopAvailability = {}
    end

    local failed = {}
    local function configure(name, fn, arg)
        local ok, err = pcall(fn, arg)
        if not ok then
            failed[#failed + 1] = name
            contractLog("CONFIGURATION FAILED (" .. name .. "): " .. tostring(err))
        end
        return ok
    end

    if slotData.shop and _G.apShopConfigure then
        configure("shop", _G.apShopConfigure, slotData.shop)
        if type(slotData.shop.slots) == "number" then
            _G.apShopSlotCount = math.floor(slotData.shop.slots)
        end
    end
    local links = slotData.links or {}
    if links.death and _G.apDeathLinkConfigure then
        configure("DeathLink", _G.apDeathLinkConfigure, links.death)
    end
    if links.energy and _G.apEnergyLinkConfigure then
        configure("EnergyLink", _G.apEnergyLinkConfigure, links.energy)
    end
    if links.trap then
        _G.apTrapLink = _G.apTrapLink or {}
        _G.apTrapLink.enabled = links.trap.enabled == true
    end

    local descriptorCount = 0
    for _ in pairs(state.itemDescriptors) do
        descriptorCount = descriptorCount + 1
    end

    state.connected = true
    contractLog(string.format("seed accepted: contract %d, %d item descriptor(s)",
        contract, descriptorCount))
    if not solo and _G.apSoloLeave then
        _G.apSoloLeave()
    end

    if #failed > 0 then
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("contract.partial", { list = table.concat(failed, ", ") }))
        end
    end
    return true
end

local function announceLostItem(itemName)
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT("item.unknown", { name = tostring(itemName) }))
    end
end

function apReceiveItem(itemName, sender, isReplay, index)
    local descriptor = state.itemDescriptors[itemName]
    if descriptor == nil then
        state.unknownItems = state.unknownItems + 1
        contractLog("item received without descriptor: " .. tostring(itemName))
        announceLostItem(itemName)
        return false
    end

    local kind = descriptor.k
    if not (_G.apSupportedKinds or {})[kind] then
        state.unknownKinds[kind] = (state.unknownKinds[kind] or 0) + 1
        contractLog("kind not implemented: " .. tostring(kind) .. " (item " .. tostring(itemName) .. ")")
        announceLostItem(itemName)
        return false
    end

    if _G.apQueueItem == nil then
        contractLog("delivery queue unavailable, item ignored: " .. tostring(itemName))
        return false
    end

    if not isReplay and _G.apRecordReceived then
        apRecordReceived(itemName, sender, index)
    end

    return apQueueItem({
        kind = kind,
        bp = descriptor.bp,
        sys = descriptor.sys,
        res = descriptor.res,
        eff = descriptor.eff,
        race = descriptor.race,
        skill = descriptor.skill,
        tiers = descriptor.tiers,
        n = descriptor.n or 1,
        display = itemName,
        sender = sender,
        isReplay = isReplay == true,
        index = index,
    })
end

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, inner in pairs(value) do
        result[key] = copy(inner)
    end
    return result
end

local SEED_GLOBALS = { "apInventory", "apDeathLink", "apEnergyLink", "apTrapLink" }

function apRunIsolated(fn)
    local before = {}
    for _, name in ipairs(SEED_GLOBALS) do
        before[name] = copy(_G[name])
    end
    local ok, err = pcall(fn)
    for _, name in ipairs(SEED_GLOBALS) do
        local current = _G[name]
        if type(current) == "table" and type(before[name]) == "table" then
            for key in pairs(current) do
                current[key] = nil
            end
            for key, value in pairs(before[name]) do
                current[key] = copy(value)
            end
        else
            _G[name] = copy(before[name])
        end
    end
    apContractResetForTesting()
    return ok, err
end

function apSeedFingerprint(identity)
    local hash = tostring((identity or state.identity or {}).hash or "")
    local fingerprint = 0
    for index = 1, #hash do
        fingerprint = (fingerprint * 31 + hash:byte(index)) % 2147483647
    end
    return fingerprint
end

function apGoal()
    return state.goal
end

function apSeedChangeLeftovers()
    return state.seedChangedWithUnlocks == true
end

function apSeedChangeAcknowledged()
    state.seedChangedWithUnlocks = false
end

function apSeedChangeReason()
    return state.seedChangeReason or "seedchange"
end

function apSeedChangeFingerprint()
    return state.refusedFingerprint
end

function apOwnSlotName()
    return (state.identity or {}).slot
end

function apSeedSummary()
    if not state.connected then
        return nil
    end
    return {
        ship = state.startShip,
        name = state.seedName,
        goal = state.goal,
        options = state.options or {},
        links = {
            death = _G.apDeathLink and _G.apDeathLink.enabled or false,
            energy = _G.apEnergyLink and _G.apEnergyLink.enabled or false,
            trap = _G.apTrapLink and _G.apTrapLink.enabled or false,
        },
    }
end

function apLocationNameFor(checkKey)
    return (state.locNames or {})[checkKey]
end

function apSystemCapsActive()
    return state.systemCapsActive ~= false
end

function apSystemBlueprintsActive()
    return state.blueprintsActive ~= false
end

function apSystemCapTotal(system)
    return (state.capTotals or {})[system]
end

function apSeedKnowsLocations()
    return next(state.locNames or {}) ~= nil
end

function apCheckKeyFor(locationName)
    return (state.locKeys or {})[locationName] or locationName
end

function apContractResetForTesting()
    state.connected = false
    state.contract = nil
    state.refusal = nil
    state.unknownItems = 0
    state.unknownKinds = {}
    state.itemDescriptors = {}
    state.capTotals = {}
    state.locNames = {}
    state.locKeys = {}
    state.goal = nil
    state.startShip = nil
    state.seedName = nil
    state.options = {}
    state.identity = nil
    state.systemCapsActive = true
    state.blueprintsActive = true
end

function apContractUnload()
    apContractResetForTesting()
    contractLog("seed unloaded")
end

function apContractStatus()
    if state.refusal then
        contractLog("seed REFUSED: " .. state.refusal)
        return
    end
    if not state.connected then
        contractLog("no seed applied (offline)")
        return
    end
    contractLog("contract " .. tostring(state.contract) .. ", seed accepted")
    if state.unknownItems > 0 then
        contractLog("  " .. state.unknownItems .. " item(s) received without descriptor")
    end
    for kind, count in pairs(state.unknownKinds) do
        contractLog("  kind not implemented \"" .. kind .. "\": " .. count .. " item(s) with no effect")
    end
end

script.on_internal_event(Defines.InternalEvents.MAIN_MENU, function()
    if state.unknownItems > 0 or next(state.unknownKinds) ~= nil then
        apContractStatus()
    end
end)

contractLog("contract module loaded (console: LUA apContractStatus())")
