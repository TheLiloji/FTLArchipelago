local TAG = "[AP-shop] "

_G.apShopModes = {
    rarity_boost = true,
    locked = true,
}

local function shopLog(message)
    log(TAG .. message)
end

local originalRarity = {}

local lockedBySeed = {}

local MOST_COMMON = 1

local RAREST = 5

local function describe(name)
    local blueprints = Hyperspace.Blueprints
    for _, getter in ipairs({ "GetWeaponBlueprint", "GetAugmentBlueprint", "GetDroneBlueprint" }) do
        local ok, blueprint = pcall(function()
            return blueprints[getter](blueprints, name)
        end)
        if ok and blueprint ~= nil and tostring(blueprint.name) == name then
            return blueprint.desc
        end
    end
    return nil
end

-- FTL puts every rarity back on baseRarity each time it generates a map, then applies the sector's own list: a
-- value must be in both, and apApplyShopRules runs again once the map is there.
local function setRarity(desc, rarity)
    desc.rarity = rarity
    desc.baseRarity = rarity
end

local function rememberRarity(name, desc)
    if originalRarity[name] == nil then
        originalRarity[name] = math.floor(desc.baseRarity or desc.rarity)
    end
end

local function shopLock(name, locked)
    if _G.apNetShopLock then
        apNetShopLock(name, locked)
    end
end

local function applyAvailability(name, steps)
    local desc = describe(name)
    if desc == nil then
        shopLog("unknown blueprint, ignored: " .. tostring(name))
        return false
    end

    rememberRarity(name, desc)

    local base = originalRarity[name]
    if base <= 0 then
        base = RAREST
    end

    if lockedBySeed[name] then
        -- Never a rarity of 0 here: an entire family at 0 crashes FTL. The module keeps it out of the stores.
        shopLock(name, steps <= 0)
        if steps <= 0 then
            setRarity(desc, originalRarity[name])
            return true
        end
        setRarity(desc, math.max(MOST_COMMON, base - (steps - 1)))
        return true
    end

    if steps <= 0 then
        setRarity(desc, originalRarity[name])
        return true
    end
    setRarity(desc, math.max(MOST_COMMON, base - steps))
    return true
end

-- A store would offer a system without its blueprint, only for the mod to refuse the purchase. The module leaves it
-- out of the random picks, and greys out the ones a store always offers (drones, medbay). Shields are always sold.
local SYSTEMS = { "medbay", "drones", "sensors", "doors", "teleporter", "cloaking", "artillery", "battery",
                  "clonebay", "mind", "hacking" }

local function applySystems()
    if not _G.apSystemUnlocked or not (_G.apSeedLoaded and apSeedLoaded()) then
        return
    end
    for _, name in ipairs(SYSTEMS) do
        shopLock(name, not apSystemUnlocked(name))
    end
end

function apApplyShopRules()
    local inventory = _G.apInventory
    if inventory == nil then
        return
    end

    local changed = 0
    for name, steps in pairs(inventory.shopAvailability or {}) do
        if applyAvailability(name, steps) then
            changed = changed + 1
        end
    end
    for name in pairs(lockedBySeed) do
        if (inventory.shopAvailability or {})[name] == nil then
            applyAvailability(name, 0)
        end
    end
    if _G.apNetShopLockTip then
        apNetShopLockTip()
    end
    applySystems()
    if changed > 0 then
        shopLog(changed .. " item(s) adjusted in shops")
    end
end

_G.apShopConfig = {
    mode = "rarity_boost",
    deliver = true,
    baseline = {},
}

local deliveredOnce = {}

-- A first copy that could not come aboard yet is owed. The list is kept in the profile: a game closed in
-- between replays the item at the menu, where it would only fill the catalogue, and the copy would be lost.
local function owedKey(fingerprint)
    return apNetSlotKey("ap_owed_" .. tostring(fingerprint or 0))
end

local function seedFingerprint()
    return _G.apSeedFingerprint and apSeedFingerprint() or 0
end

local function readOwed()
    local owed = {}
    if _G.apNetRecallText then
        for name in tostring(apNetRecallText(owedKey(seedFingerprint()))):gmatch("[^,]+") do
            owed[name] = true
        end
    end
    return owed
end

local function writeOwed(owed)
    if not _G.apNetRememberText then
        return
    end
    local list = {}
    for name in pairs(owed) do
        list[#list + 1] = name
    end
    table.sort(list)
    apNetRememberText(owedKey(seedFingerprint()), table.concat(list, ","))
end

-- FTL saves the run at each jump and on the way back to the menu: a copy put aboard since then stays owed, so a
-- crash in between gives it again.
local unsaved = {}
local continuedRun = false

function apShopCopyAboard(name)
    local owed = readOwed()
    if not owed[name] then
        owed[name] = true
        writeOwed(owed)
    end
    unsaved[name] = true
end

local function runSaved()
    if next(unsaved) == nil then
        return
    end
    local owed = readOwed()
    for name in pairs(unsaved) do
        owed[name] = nil
    end
    writeOwed(owed)
    unsaved = {}
end

-- A continued run that already holds the owed copy was saved after it came aboard.
function apShopOwedAlreadyAboard(name)
    if not (continuedRun and _G.apShipHolds and apShipHolds(name)) then
        return false
    end
    local owed = readOwed()
    owed[name] = nil
    writeOwed(owed)
    shopLog("owed copy already in the saved run: " .. name)
    return true
end

-- A copy received during a run but held back (a fight): if the game closes first, it is still owed.
function apShopKeepOwed(name)
    if not _G.apShopConfig.deliver or deliveredOnce[name] then
        return
    end
    local owed = readOwed()
    if not owed[name] then
        owed[name] = true
        writeOwed(owed)
    end
end

function apShopForgetOwed(fingerprint)
    if _G.apNetRememberText then
        apNetRememberText(owedKey(fingerprint), "")
    end
end

function apShopForgetSeed()
    -- Every rarity the old seed touched goes back, the ones it made more common as well as the ones it locked.
    local restored = 0
    for name, rarity in pairs(originalRarity) do
        local desc = describe(name)
        if desc ~= nil and (desc.rarity ~= rarity or desc.baseRarity ~= rarity) then
            setRarity(desc, rarity)
            restored = restored + 1
        end
    end
    if _G.apNetClearShopLocks then
        apNetClearShopLocks()
    end
    lockedBySeed = {}
    deliveredOnce = {}
    _G.apShopConfig.offers = {}
    shopLog("new seed: " .. restored .. " item(s) restocked, deliveries forgotten")
    return restored
end

function apShopConfigure(settings)
    if type(settings) ~= "table" then
        return false
    end
    local config = _G.apShopConfig
    if settings.mode ~= nil then config.mode = settings.mode end
    if settings.deliver ~= nil then config.deliver = settings.deliver end
    if settings.baseline ~= nil then config.baseline = settings.baseline end
    config.offers = type(settings.offers) == "table" and settings.offers or {}
    config.sectors = tonumber(settings.sectors)
    config.owners = type(settings.owners) == "table" and #settings.owners > 0 and settings.owners or nil
    config.per = settings.per

    apApplyShopBaseline()
    shopLog("configured: mode=" .. config.mode .. " deliver=" .. tostring(config.deliver)
        .. " locked=" .. tostring(#(config.baseline or {})))
    return true
end

function apApplyShopBaseline()
    local config = _G.apShopConfig
    if config.mode ~= "locked" then
        return 0
    end
    local locked = 0
    for _, name in ipairs(config.baseline or {}) do
        local desc = describe(name)
        if desc ~= nil then
            rememberRarity(name, desc)
            lockedBySeed[name] = true
            locked = locked + 1
        else
            shopLog("baseline: unknown blueprint, ignored: " .. tostring(name))
        end
    end
    if locked > 0 then
        shopLog(locked .. " item(s) removed from shops until their item is received")
    end

    apApplyShopRules()
    return locked
end

function apApplyShopItem(descriptor)
    local name = descriptor.bp
    if name == nil or name == "" then
        shopLog("shop descriptor without a blueprint, ignored")
        return false
    end
    if describe(name) == nil then
        shopLog("unknown blueprint, shop item NOT applied: " .. tostring(name))
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("shop.item.unknown",
                { name = descriptor.display or tostring(name) }))
        end
        return false
    end

    local inventory = _G.apInventory
    if inventory == nil then
        return false
    end
    inventory.shopAvailability = inventory.shopAvailability or {}
    local received = (inventory.shopAvailability[name] or 0) + (descriptor.n or 1)
    inventory.shopAvailability[name] = received

    applyAvailability(name, received)

    local now = describe(name)
    -- The game's own name speaks the player's language; the seed's display name is English.
    local okTitle, title = pcall(function() return now.title:GetText() end)
    local label = (okTitle and type(title) == "string" and title ~= "" and title ~= name) and title
        or descriptor.display or name
    shopLog(string.format("%s: %d copy(ies) received, rarity %d -> %d%s",
        name, received, originalRarity[name] or -1,
        now and math.floor(now.rarity) or -1,
        lockedBySeed[name] and " (was locked)" or ""))
    local aboard = false
    if _G.apShopConfig.deliver and not deliveredOnce[name] and not descriptor.isReplay
        and not descriptor.noDelivery and _G.apDeliverEquipment then
        local attempt = { kind = "weapon", bp = name, display = label, silent = true }
        aboard = _G.apDeliverEquipment(attempt) == true
        if aboard then
            deliveredOnce[name] = true
        elseif _G.apQueueItem then
            -- Not now (a fight, full slots, the menu): the one copy waits in the queue rather than being lost.
            -- The copy takes the item's number with it: the item only counts as received once the copy is
            -- aboard, so a game closed in between gives it again next time.
            _G.apQueueItem({ kind = attempt.kind, bp = name, display = label, waiting = attempt.waiting,
                             index = descriptor.index })
            descriptor.index = nil
            deliveredOnce[name] = true
            local owed = readOwed()
            owed[name] = true
            writeOwed(owed)
            shopLog("immediate delivery deferred, queued: " .. name)
        end
    elseif _G.apShopConfig.deliver and not deliveredOnce[name] and _G.apQueueItem and readOwed()[name] then
        _G.apQueueItem({ kind = "weapon", bp = name, display = label, owed = true,
                         index = not descriptor.isReplay and descriptor.index or nil })
        descriptor.index = nil
        deliveredOnce[name] = true
        shopLog("copy owed from an earlier session, queued: " .. name)
    end

    if _G.apNotifyStatus and not descriptor.isReplay then
        _G.apNotifyStatus(apT(aboard and "shop.unlocked.aboard" or "shop.unlocked",
                              { item = label }))
    end
    return true
end

function apShopStatus()
    local inventory = _G.apInventory or {}
    shopLog("item availability driven by Archipelago:")
    for name, steps in pairs(inventory.shopAvailability or {}) do
        local desc = describe(name)
        shopLog(string.format("  %-22s items received=%d  vanilla rarity %s -> %s%s",
            name, steps, tostring(originalRarity[name]),
            desc and tostring(math.floor(desc.rarity)) or "?",
            lockedBySeed[name] and "  [locked by the seed]" or ""))
    end
end

script.on_internal_event(Defines.InternalEvents.MAIN_MENU, function()
    runSaved()
    apApplyShopRules()
end)
script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager ~= nil and shipManager.iShipId == 0 then
        runSaved()
    end
end)
-- The map of a new sector comes with the rarities reset: the rules go back on at the first tick after it.
local mapSeen = nil
local systemTicks = 0
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    -- A blueprint received at a store opens its box at once.
    systemTicks = systemTicks + 1
    if systemTicks >= 60 then
        systemTicks = 0
        applySystems()
    end
    local ok, level = pcall(function()
        local world = Hyperspace.App.world
        return world.bStartedGame and world.starMap.worldLevel or nil
    end)
    if ok and level ~= nil and level ~= mapSeen then
        mapSeen = level
        apApplyShopRules()
    end
end)

script.on_init(function(newGame)
    -- A restart from the pause menu leaves the old run behind with its copies.
    continuedRun = newGame == false
    if continuedRun then
        unsaved = {}
    else
        runSaved()
    end
    mapSeen = nil
    apApplyShopRules()
end)

shopLog("shop module loaded (console: LUA apShopStatus())")
