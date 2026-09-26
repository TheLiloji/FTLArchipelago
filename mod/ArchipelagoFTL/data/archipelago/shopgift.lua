local TAG = "[AP-gift] "

local function giftLog(message)
    log(TAG .. message)
end

local GIFT_BLUEPRINTS = {}
for numero = 1, 12 do
    GIFT_BLUEPRINTS[numero] = "AP_GIFT_" .. numero
end

function apShopPages()
    local slots = tonumber(_G.apShopSlotCount) or 0
    if slots > 100 then return 4 end
    if slots > 60 then return 3 end
    if slots > 30 then return 2 end
    return 1
end

local function visibleGifts()
    return 3 * apShopPages()
end

local function announceSize()
    pcall(function()
        Hyperspace.playerVariables.ap_shop_pages = apShopPages()
    end)
end

local DEAL_BLUEPRINTS = { "AP_DEAL_1", "AP_DEAL_2", "AP_DEAL_3" }

local DEAL_REWARD = { 35, 55, 80 }

local DEAL_SELF_CHANCE = 34

_G.apShopGifts = {}

local sold = {}

local function alreadyGone(key)
    if key == nil then
        return true
    end
    if sold[key] then
        return true
    end
    return _G.apCheckAlreadySent ~= nil and _G.apCheckAlreadySent(key) == true
end

local assignment = {}

local dealsSigned = {}

local function giftDesc(name)
    local ok, blueprint = pcall(function()
        return Hyperspace.Blueprints:GetWeaponBlueprint(name)
    end)
    if ok and blueprint ~= nil and tostring(blueprint.name) == name then
        return blueprint.desc
    end
    return nil
end

local function dealDesc(name)
    local ok, blueprint = pcall(function()
        return Hyperspace.Blueprints:GetAugmentBlueprint(name)
    end)
    if ok and blueprint ~= nil and tostring(blueprint.name) == name then
        return blueprint.desc
    end
    return nil
end

local KIND_KEY = {
    progression = "shop.kind.progression",
    useful = "shop.kind.useful",
    filler = "shop.kind.filler",
    trap = "shop.kind.trap",
}

local KIND_ART = {
    progression = "ap_gift_progression",
    useful = "ap_gift_useful",
    filler = "ap_gift_filler",
    trap = "ap_gift_trap",
}

local function setGiftArt(blueprintName, kind)
    pcall(function()
        local blueprint = Hyperspace.Blueprints:GetWeaponBlueprint(blueprintName)
        if blueprint ~= nil and tostring(blueprint.name) == blueprintName then
            blueprint.weaponArt = KIND_ART[kind] or "ap_gift"
        end
    end)
end

local BASE_PRICE = { progression = 70, useful = 30, filler = 10, trap = 10 }

local function offerFor(gift)
    local offers = (_G.apShopConfig or {}).offers
    local offer = type(offers) == "table" and gift ~= nil and gift.location ~= nil
        and offers[gift.location] or nil
    return type(offer) == "table" and offer or {}
end

local function giftPrice(gift)
    if gift == nil then
        return 0
    end
    local fixed = tonumber(gift.cost) or tonumber(offerFor(gift).price)
    if fixed ~= nil then
        return math.max(1, math.floor(fixed))
    end
    return BASE_PRICE[gift.kind] or BASE_PRICE.useful
end


local function writeGift(blueprintName, gift)
    local desc = giftDesc(blueprintName)
    if desc == nil then
        giftLog("gift blueprint missing: " .. tostring(blueprintName)
            .. " (is blueprints.xml.append not loaded?)")
        return false
    end

    if gift == nil then
        setGiftArt(blueprintName, nil)
        local noGifts = #(_G.apShopGifts or {}) == 0
        local linked = _G.apContractState ~= nil and _G.apContractState.connected == true
        if noGifts and not linked then
            desc.title.data = apT("shop.slot.noseed.title")
            desc.shortTitle.data = apT("shop.slot.noseed.short")
            desc.description.data = apT("shop.slot.noseed.body")
        else
            desc.title.data = apT("shop.slot.empty.title")
            desc.shortTitle.data = apT("shop.slot.empty.short")
            desc.description.data = apT("shop.slot.empty.body")
        end
        desc.title.isLiteral = true
        desc.shortTitle.isLiteral = true
        desc.description.isLiteral = true
        desc.tooltip.data = desc.description.data
        desc.tooltip.isLiteral = true
        desc.cost = 0
        return true
    end

    setGiftArt(blueprintName, gift.kind)

    local who = tostring(gift.slot or "?")
    local me = _G.apOwnSlotName and _G.apOwnSlotName() or nil
    local forMe = gift.mine == true or (me ~= nil and who == tostring(me))

    desc.title.data = forMe and apT("shop.slot.title.self")
        or apT("shop.slot.title", { slot = who })
    desc.title.isLiteral = true

    if forMe then
        desc.shortTitle.data = apT("shop.slot.self.short")
    else
        desc.shortTitle.data = _G.apTruncate and _G.apTruncate(who, 12) or who
    end
    desc.shortTitle.isLiteral = true

    local details = { tostring(gift.item or apT("shop.slot.unknown_item")) }
    if gift.game ~= nil and tostring(gift.game) ~= "" then
        details[#details + 1] = tostring(gift.game)
    end
    local sphere = tonumber(gift.sphere) or tonumber(offerFor(gift).sphere)
    if sphere ~= nil then
        details[#details + 1] = apT("shop.slot.sphere", { n = math.floor(sphere) })
    end
    if gift.kind ~= nil then
        details[#details + 1] = KIND_KEY[gift.kind] and apT(KIND_KEY[gift.kind])
            or tostring(gift.kind)
    end
    local text = details[1] .. "\n" .. table.concat(details, ", ", 2)

    desc.description.data = text
    desc.description.isLiteral = true
    desc.tooltip.data = text
    desc.tooltip.isLiteral = true

    desc.cost = giftPrice(gift)
    return true
end

function apApplyShopGifts()
    local applied = 0
    local function giftKey(gift)
        return gift and (gift.location or gift.item) or nil
    end

    local placed = {}
    for _, blueprintName in ipairs(GIFT_BLUEPRINTS) do
        local current = assignment[blueprintName]
        local key = giftKey(current)
        if not alreadyGone(key) then
            placed[key] = true
        else
            assignment[blueprintName] = nil
        end
    end

    announceSize()
    local nextGift = 1
    for rank, blueprintName in ipairs(GIFT_BLUEPRINTS) do
        if rank > visibleGifts() then
            assignment[blueprintName] = nil
        elseif assignment[blueprintName] == nil then
            while nextGift <= #_G.apShopGifts do
                local candidate = _G.apShopGifts[nextGift]
                local key = giftKey(candidate)
                if alreadyGone(key) or placed[key] then
                    nextGift = nextGift + 1
                else
                    break
                end
            end
            local gift = _G.apShopGifts[nextGift]
            if gift ~= nil then
                assignment[blueprintName] = gift
                placed[giftKey(gift)] = true
                nextGift = nextGift + 1
            end
        end

        local gift = assignment[blueprintName]
        if writeGift(blueprintName, gift) and gift ~= nil then
            applied = applied + 1
        end
    end

    for index, blueprintName in ipairs(DEAL_BLUEPRINTS) do
        local desc = dealDesc(blueprintName)
        if desc ~= nil and not dealsSigned[blueprintName] then
            local reward = tostring(DEAL_REWARD[index] or 30)
            desc.title.data = apT("deal.title", { scrap = reward })
            desc.title.isLiteral = true
            desc.shortTitle.data = apT("deal.short", { scrap = reward })
            desc.shortTitle.isLiteral = true
            desc.description.data = apT("deal.body", { scrap = reward })
            desc.description.isLiteral = true
            desc.tooltip.data = desc.description.data
            desc.tooltip.isLiteral = true
        end
    end
    if applied > 0 then
        giftLog(applied .. " gift(s) displayed in the Archipelago shop")
    end
    return applied
end

_G.apShopSlotCount = 0

function apShopSlotKeys()
    local keys = {}
    for slot = 1, (_G.apShopSlotCount or 0) do
        keys[#keys + 1] = "shop:" .. slot
    end
    return keys
end

function apShopGiftsScouted(scouted)
    if type(scouted) ~= "table" then
        return false
    end
    giftLog(#scouted .. " location(s) scouted from the server")
    return apShopGiftsConfigure(scouted)
end

function apShopGiftsForgetSeed()
    sold = {}
    dealsSigned = {}
    giftLog("new seed: gifts and deals become available again")
end

function apShopGiftsConfigure(gifts, source)
    if type(gifts) ~= "table" then
        return false
    end
    if source == "demo" and ((_G.apNetConnected and _G.apNetConnected()) or _G.apSoloEnabled) then
        giftLog("a seed is loaded: the shop keeps its items, not the demo")
        return false
    end
    _G.apShopGifts = gifts
    assignment = {}
    apApplyShopGifts()
    return true
end

local function playerHas(blueprintName)
    local found = false
    pcall(function()
        local equipment = Hyperspace.App.gui.equipScreen
        if equipment ~= nil then
            local cargo = equipment:GetCargoHold()
            for i = 0, cargo:size() - 1 do
                if tostring(cargo[i]) == blueprintName then
                    found = true
                    return
                end
            end
        end
        local weapons = Hyperspace.ships.player:GetWeaponList()
        for i = 0, weapons:size() - 1 do
            local weapon = weapons[i]
            if weapon ~= nil and tostring(weapon.blueprint.name) == blueprintName then
                found = true
                return
            end
        end
    end)
    return found
end

local function playerHasAugment(name)
    local ok, found = pcall(function()
        local list = Hyperspace.ships.player:GetAugmentationList()
        for i = 0, list:size() - 1 do
            if tostring(list[i]) == name then
                return true
            end
        end
        return false
    end)
    if ok then
        return found
    end

    local okHas, has = pcall(function()
        return Hyperspace.ships.player:HasAugmentation(name)
    end)
    return okHas and has == true
end

local function displayedPrice(blueprintName, gift)
    if gift ~= nil then
        return giftPrice(gift)
    end
    local desc = giftDesc(blueprintName)
    return desc ~= nil and math.floor(tonumber(desc.cost) or 0) or 0
end

local function collect(index, blueprintName)
    local gift = assignment[blueprintName]
    local paid = displayedPrice(blueprintName, gift)
    if gift == nil then
        giftLog("empty slot bought (" .. blueprintName .. "): nothing to send, item removed")
        pcall(function()
            Hyperspace.ships.player:RemoveItem(blueprintName, true)
        end)
        return
    end
    sold[gift.location or gift.item or blueprintName] = true

    pcall(function()
        Hyperspace.ships.player:RemoveItem(blueprintName, true)
    end)

    local who = gift and gift.slot or apT("gift.someone")
    local what = gift and gift.item or apT("gift.something")

    local reallySent = true
    if gift and gift.location and _G.apSendCheck then
        reallySent = _G.apSendCheck(gift.location, gift.item) ~= false
    end

    if not reallySent then
        giftLog("gift already sent before (" .. blueprintName .. "): refunded")
        local price = paid
        if price > 0 then
            pcall(function()
                Hyperspace.ships.player:ModifyScrapCount(math.floor(price), false)
            end)
        end
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("shop.gift.already_sent", { price = tostring(price) }))
        end
        writeGift(blueprintName, nil)
        return
    end

    giftLog(string.format("gift bought: %s for %s (%s)", what, who, blueprintName))
    local me = _G.apOwnSlotName and _G.apOwnSlotName() or nil
    local forMe = gift.mine == true or (me ~= nil and tostring(gift.slot) == tostring(me))
    if _G.apNotifyStatus then
        _G.apNotifyStatus(forMe and apT("shop.gift.sent.self", { item = what })
            or apT("shop.gift.sent", { item = what, slot = who }))
    end

    apApplyShopGifts()
end

local function signDeal(index, blueprintName)
    dealsSigned[blueprintName] = true

    pcall(function()
        Hyperspace.ships.player:RemoveItem(blueprintName, true)
    end)

    local reward = DEAL_REWARD[index] or 30
    pcall(function()
        Hyperspace.ships.player:ModifyScrapCount(reward, false)
    end)

    local againstSelf = math.random(1, 100) <= DEAL_SELF_CHANCE
    local effects = { "fire", "breach", "fuel_leak", "system_damage", "hull_damage" }
    local effect = effects[math.random(1, #effects)]

    if againstSelf then
        giftLog(string.format("deal %d: +%d scrap, and the trap is ON US (%s)",
            index, reward, effect))
        if _G.apQueueItem then
            _G.apQueueItem({ kind = "trap", eff = effect,
                             display = apT("deal.own_pact"), fromLink = true })
        end
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("deal.self", { scrap = reward }))
        end
    else
        local sent = false
        if _G.apNetSendTrap then
            local ok, result = pcall(_G.apNetSendTrap, "Archipelago Deal")
            sent = ok and result ~= false
        end

        if sent then
            giftLog(string.format("deal %d: +%d scrap, the trap goes to someone else (%s)",
                index, reward, effect))
            if _G.apNotifyStatus then
                _G.apNotifyStatus(apT("deal.other", { scrap = reward }))
            end
        else
            giftLog(string.format(
                "deal %d: +%d scrap, no one out there to take it, the trap comes back (%s)",
                index, reward, effect))
            if _G.apQueueItem then
                _G.apQueueItem({ kind = "trap", eff = effect,
                                 display = apT("deal.own_pact"), fromLink = true })
            end
            if _G.apNotifyStatus then
                _G.apNotifyStatus(apT("deal.backfired", { scrap = reward }))
            end
        end
    end

    local desc = dealDesc(blueprintName)
    if desc ~= nil then
        desc.title.data = apT("deal.closed.title")
        desc.title.isLiteral = true
        desc.shortTitle.data = apT("deal.closed.short")
        desc.shortTitle.isLiteral = true
        desc.description.data = apT("deal.closed.body")
        desc.description.isLiteral = true
    end
end

local pollDivider = 0

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    pollDivider = (pollDivider + 1) % 6
    if pollDivider ~= 0 then
        return
    end
    for index, blueprintName in ipairs(GIFT_BLUEPRINTS) do
        if playerHas(blueprintName) then
            collect(index, blueprintName)
        end
    end

    for index, blueprintName in ipairs(DEAL_BLUEPRINTS) do
        if playerHasAugment(blueprintName) then
            if dealsSigned[blueprintName] then
                pcall(function()
                    Hyperspace.ships.player:RemoveItem(blueprintName, true)
                end)
                if _G.apNotifyStatus then
                    _G.apNotifyStatus(apT("deal.closed"))
                end
            else
                signDeal(index, blueprintName)
            end
        end
    end
end)

script.on_init(function()
    sold = {}
    dealsSigned = {}
    apApplyShopGifts()
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager.iShipId ~= 0 then
        return
    end
    dealsSigned = {}
    apApplyShopGifts()
end)

function apShopGiftsResetForTesting()
    sold = {}
    dealsSigned = {}
    assignment = {}
    if _G.apForgetChecksForTesting then
        _G.apForgetChecksForTesting()
    end
    apApplyShopGifts()
    giftLog("shop reset to fresh (tests)")
end

local function offerCopy(gift)
    local me = _G.apOwnSlotName and _G.apOwnSlotName() or nil
    return { item = gift.item, slot = gift.slot, sphere = gift.sphere, kind = gift.kind,
             cost = gift.cost, location = gift.location, game = gift.game,
             mine = gift.mine == true or (me ~= nil and tostring(gift.slot) == tostring(me)) }
end

function apShopGiftPeekNext()
    for _, gift in ipairs(_G.apShopGifts or {}) do
        local key = gift and (gift.location or gift.item)
        if not alreadyGone(key) then
            return offerCopy(gift)
        end
    end
    return nil
end

function apShopGiftGiveNext()
    local gift = apShopGiftPeekNext()
    if gift == nil then
        giftLog("no gift to give: everything is already gone")
        return nil
    end

    if gift.location and _G.apSendCheck then
        if _G.apSendCheck(gift.location, gift.item) == false then
            giftLog("gift already sent, nothing to give: " .. tostring(gift.location))
            return nil
        end
    end

    sold[gift.location or gift.item] = true
    giftLog(string.format("gift GIVEN by an event: %s for %s",
        tostring(gift.item), tostring(gift.slot)))
    apApplyShopGifts()
    return gift
end

function apShopGiftPeekMany(n)
    local found = {}
    for _, gift in ipairs(_G.apShopGifts or {}) do
        local key = gift and (gift.location or gift.item)
        if not alreadyGone(key) then
            found[#found + 1] = offerCopy(gift)
            if #found >= (n or 2) then
                break
            end
        end
    end
    return found
end

function apShopGiftGiveAt(location)
    if location == nil then
        return nil
    end
    for _, gift in ipairs(_G.apShopGifts or {}) do
        local key = gift and (gift.location or gift.item)
        if key == location and not alreadyGone(key) then
            if gift.location and _G.apSendCheck then
                if _G.apSendCheck(gift.location, gift.item) == false then
                    giftLog("gift already sent: " .. tostring(gift.location))
                    return nil
                end
            end
            sold[key] = true
            giftLog(string.format("gift CHOSEN by the player: %s for %s",
                tostring(gift.item), tostring(gift.slot)))
            apApplyShopGifts()
            return offerCopy(gift)
        end
    end
    giftLog("gift not found or already gone: " .. tostring(location))
    return nil
end

function apShopGiftsStatus()
    giftLog("Archipelago shop: " .. #_G.apShopGifts .. " gift(s) configured")
    for index, blueprintName in ipairs(GIFT_BLUEPRINTS) do
        local gift = assignment[blueprintName]
        local desc = giftDesc(blueprintName)
        giftLog(string.format("  %s: %s | displays \"%s\"",
            blueprintName,
            gift and (tostring(gift.item) .. " -> " .. tostring(gift.slot)) or "(empty)",
            desc and tostring(desc.title.data) or "?"))
    end
end

giftLog("Archipelago shop module loaded (console: LUA apShopGiftsStatus())")
