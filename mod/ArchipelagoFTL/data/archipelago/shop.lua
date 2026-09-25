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

local function applyAvailability(name, steps)
    local desc = describe(name)
    if desc == nil then
        shopLog("unknown blueprint, ignored: " .. tostring(name))
        return false
    end

    if originalRarity[name] == nil then
        originalRarity[name] = math.floor(desc.rarity)
    end

    local base = originalRarity[name]
    if base <= 0 then
        base = RAREST
    end

    if lockedBySeed[name] then
        if steps <= 0 then
            desc.rarity = 0
            return true
        end
        desc.rarity = math.max(MOST_COMMON, base - (steps - 1))
        return true
    end

    if steps <= 0 then
        desc.rarity = originalRarity[name]
        return true
    end
    desc.rarity = math.max(MOST_COMMON, base - steps)
    return true
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

function apShopForgetSeed()
    local restored = 0
    for name in pairs(lockedBySeed) do
        local desc = describe(name)
        if desc ~= nil and originalRarity[name] ~= nil then
            desc.rarity = originalRarity[name]
            restored = restored + 1
        end
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
            if originalRarity[name] == nil then
                originalRarity[name] = math.floor(desc.rarity)
            end
            lockedBySeed[name] = true
            desc.rarity = 0
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

    local label = descriptor.display or name
    local now = describe(name)
    shopLog(string.format("%s: %d copy(ies) received, rarity %d -> %d%s",
        name, received, originalRarity[name] or -1,
        now and math.floor(now.rarity) or -1,
        lockedBySeed[name] and " (was locked)" or ""))
    local aboard = false
    if _G.apShopConfig.deliver and not deliveredOnce[name] and not descriptor.isReplay
        and not descriptor.noDelivery and _G.apDeliverEquipment then
        aboard = _G.apDeliverEquipment(
            { kind = "weapon", bp = name, display = label, silent = true }) == true
        if aboard then
            deliveredOnce[name] = true
        else
            shopLog("immediate delivery deferred: " .. name)
        end
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

script.on_internal_event(Defines.InternalEvents.MAIN_MENU, apApplyShopRules)
script.on_init(apApplyShopRules)

shopLog("shop module loaded (console: LUA apShopStatus())")
