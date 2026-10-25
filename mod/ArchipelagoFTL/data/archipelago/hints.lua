local TAG = "[AP-hints] "

local function hintLog(message)
    log(TAG .. message)
end

local known = {}
local order = {}
local requested = {}

local function key(hint)
    return tostring(hint.finder) .. "|" .. tostring(hint.location) .. "|" .. tostring(hint.item)
end

local function forMe(hint)
    local own = _G.apOwnSlotName and _G.apOwnSlotName() or nil
    return own ~= nil and tostring(hint.receiver) == tostring(own)
end

-- A hint on one of our shop slots says where it is sold: its name alone cannot.
local function placeOf(hint)
    local own = _G.apOwnSlotName and _G.apOwnSlotName() or nil
    local ours = hint.solo or (own ~= nil and tostring(hint.finder) == tostring(own))
    if not ours or not (_G.apCheckKeyFor and _G.apShopPlace) then
        return hint.location
    end
    local place = apShopPlace(apCheckKeyFor(hint.location))
    return place and (tostring(hint.location) .. " (" .. place .. ")") or hint.location
end

function apHintText(hint)
    if hint.solo then
        return apT("hint.received.solo", { item = hint.item, location = placeOf(hint) })
    end
    if forMe(hint) then
        return apT("hint.received.mine", { item = hint.item, finder = hint.finder,
                                           location = placeOf(hint) })
    end
    return apT("hint.received.theirs", { item = hint.item, receiver = hint.receiver,
                                         location = placeOf(hint) })
end

function apHintLine(hint)
    if hint.solo then
        return apT("hud.hint.solo", { item = hint.item, location = placeOf(hint) })
    end
    if forMe(hint) then
        return apT("hud.hint.mine", { item = hint.item, finder = hint.finder,
                                      location = placeOf(hint) })
    end
    return apT("hud.hint.theirs", { item = hint.item, receiver = hint.receiver,
                                    location = placeOf(hint) })
end

function apHintReceived(hint)
    if type(hint) ~= "table" or hint.item == nil or hint.location == nil then
        return false
    end
    local k = key(hint)
    local existing = known[k]
    known[k] = hint
    if existing == nil then
        order[#order + 1] = k
    end
    hintLog(string.format("%s for %s, at %s by %s%s", tostring(hint.item),
        tostring(hint.receiver), tostring(hint.location), tostring(hint.finder),
        hint.found and " (already found)" or ""))
    if existing == nil and not hint.known and not hint.found and _G.apNotifyStatus then
        _G.apNotifyStatus(apHintText(hint))
    end
    return existing == nil
end

-- The server marks a hint found only when it is read again on connecting: a check done here since, at one of
-- our own locations, finds it already.
local function foundHere(hint)
    local own = _G.apOwnSlotName and _G.apOwnSlotName() or nil
    if own == nil or tostring(hint.finder) ~= tostring(own) or not _G.apCheckKeyFor then
        return false
    end
    local checkKey = apCheckKeyFor(hint.location)
    return checkKey ~= nil and _G.apCheckAlreadySent ~= nil and apCheckAlreadySent(checkKey) == true
end

function apHintsForDisplay(limit)
    local openHints = {}
    for i = #order, 1, -1 do
        local hint = known[order[i]]
        if hint ~= nil and not hint.found and not foundHere(hint) then
            openHints[#openHints + 1] = hint
            if #openHints >= (limit or 4) then
                break
            end
        end
    end
    return openHints
end

local function alreadyHinted(name)
    if requested[name] then
        return true
    end
    for _, hint in pairs(known) do
        if hint.location == name then
            return true
        end
    end
    return false
end

-- A check tied to a ship layout the player has not unlocked cannot be done yet.
function apCheckPlayable(key)
    local layout = tostring(key):match("^(PLAYER_SHIP_[%u%d_]+):")
    if layout == nil then
        return true
    end
    for _, name in ipairs(((_G.apInventory or {}).ships) or {}) do
        if name == layout then return true end
    end
    return false
end

-- Hints point at checks the player can go and do now, when there are any.
function apHintPick(candidates, keyOf)
    local playable = {}
    for _, candidate in ipairs(candidates) do
        if apCheckPlayable(keyOf(candidate)) then playable[#playable + 1] = candidate end
    end
    local pool = #playable > 0 and playable or candidates
    if #pool == 0 then
        return nil
    end
    return pool[math.random(1, #pool)]
end

function apHintPurchase()
    if _G.apSoloEnabled and _G.apSoloHint then
        local entry = _G.apSoloHint(alreadyHinted)
        if entry == nil then
            return false
        end
        requested[entry.location] = true
        return apHintReceived({ item = entry.item, location = entry.location, solo = true })
    end
    if not (_G.apNetConnected and _G.apNetConnected()) or _G.apNetHintLocation == nil then
        return false
    end
    local contract = _G.apContractState
    local names = contract and contract.locNames or nil
    if names == nil then
        return false
    end
    local candidates = {}
    local keys = {}
    for id, name in pairs(names) do
        local done = _G.apCheckAlreadySent and _G.apCheckAlreadySent(id)
        if not done and not alreadyHinted(name) then
            candidates[#candidates + 1] = name
            keys[name] = id
        end
    end
    if #candidates == 0 then
        return false
    end
    table.sort(candidates)
    local chosen = apHintPick(candidates, function(name) return keys[name] end)
    if _G.apNetHintLocation(chosen) ~= true then
        return false
    end
    requested[chosen] = true
    hintLog("hint requested from server for " .. chosen)
    return true
end

function apHintsForgetSeed()
    known = {}
    order = {}
    requested = {}
end

hintLog("hints module loaded")
