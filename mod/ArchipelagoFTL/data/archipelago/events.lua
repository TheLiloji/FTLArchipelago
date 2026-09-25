local TAG = "[AP-events] "

local function eventLog(message)
    log(TAG .. message)
end

_G.apEventLog = {}

local function record(name, detail)
    _G.apEventLog[#_G.apEventLog + 1] = { event = name, detail = detail }
    eventLog(name .. " : " .. detail)
end

local function feedTheLink(eventName, fuel)
    if _G.apEnergyLinkDeposit == nil then
        record(eventName, "energy link missing, nothing deposited")
        return
    end
    local joules = fuel * (_G.apEnergyLinkJoulesPerFuel or 1000000)
    local ok, deposited = pcall(_G.apEnergyLinkDeposit, joules, true)
    local sent = ok and tonumber(deposited) ~= nil and tonumber(deposited) > 0
    record(eventName, sent and ("deposited to the link: " .. joules .. " J") or "nothing deposited to the link")
    if sent and _G.apNotifyStatus then
        _G.apNotifyStatus(apT("event.link.fed"))
    end
end

local function drainTheLink(eventName)
    if _G.apEnergyLinkRequestFuel == nil then
        record(eventName, "energy link missing, nothing drawn")
        return
    end
    -- The answer comes later, through apEnergyLinkGranted.
    local ok, asked = pcall(_G.apEnergyLinkRequestFuel, 5)
    if not ok or asked ~= true then
        record(eventName, "no request possible, the shared pool is out of reach")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("event.link.empty"))
        end
        return
    end
    record(eventName, "5 fuel units asked from the link")
end

local function sendTrapOutward(eventName)
    if _G.apNetSendTrap == nil then
        record(eventName, "offline: would have broadcast a trap")
        return
    end
    local ok, result = pcall(_G.apNetSendTrap, "Archipelago Signal Surge")
    local sent = ok and result ~= false
    record(eventName, sent and "trap broadcast to others" or "no one out there to receive it")
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT(sent and "event.trap.sent" or "event.trap.nobody"))
    end
end


local offeredPackages = { a = nil, b = nil }
local PRICE = { ["AP_EVT_PACKAGE"] = 15, ["AP_EVT_SLUG_WHISPER"] = 20 }
local scrapBefore = {}

local function scrap()
    local ok, value = pcall(function() return Hyperspace.ships.player.currentScrap end)
    return ok and tonumber(value) or nil
end

local function refund(eventName)
    local before = scrapBefore[eventName]
    scrapBefore[eventName] = nil
    if before == nil then
        return 0
    end
    local refunded = math.min(PRICE[eventName] or 0, math.max(0, math.floor(before)))
    if refunded > 0 then
        pcall(function() Hyperspace.ships.player:ModifyScrapCount(refunded, false) end)
    end
    return refunded
end

local function buyHint(eventName)
    if _G.apHintPurchase and _G.apHintPurchase() then
        scrapBefore["AP_EVT_SLUG_WHISPER"] = nil
        record(eventName, _G.apSoloEnabled and "hint given from the solo seed" or "hint requested from server")
        if _G.apNotifyStatus and not _G.apSoloEnabled then
            _G.apNotifyStatus(apT("event.hint.asked"))
        end
        return
    end
    local refunded = refund("AP_EVT_SLUG_WHISPER")
    record(eventName, "no hint possible, " .. refunded .. " scrap refunded")
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT("event.hint.nothing", { scrap = refunded }))
    end
end

function routePackage(eventName, package)
    local sent = nil
    if package ~= nil and _G.apShopGiftGiveAt ~= nil then
        sent = _G.apShopGiftGiveAt(package.location)
    end
    if sent == nil and _G.apShopGiftGiveNext ~= nil then
        sent = _G.apShopGiftGiveNext()
    end
    if sent == nil then
        local refunded = refund("AP_EVT_PACKAGE")
        record(eventName, "nothing to send, " .. refunded .. " scrap refunded")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("event.gift.nothing", { scrap = refunded }))
        end
        return
    end
    scrapBefore["AP_EVT_PACKAGE"] = nil
    record(eventName, "package routed: " .. tostring(sent.item) .. " -> "
        .. (sent.mine and "the player" or tostring(sent.slot)))
    if _G.apNotifyStatus and not sent.mine then
        _G.apNotifyStatus(apT("event.gift.sent",
            { item = tostring(sent.item), slot = tostring(sent.slot) }))
    end
end

local function writePackageChoices(event)
    offeredPackages.a, offeredPackages.b = nil, nil
    local packages = (_G.apShopGiftPeekMany and _G.apShopGiftPeekMany(2)) or {}
    if packages[1] == nil then
        return
    end
    local choices = event:GetChoices()
    if choices == nil or choices:size() < 2 then
        return
    end

    local function setChoice(index, chosenPackage)
        if chosenPackage.mine then
            choices[index].text.data = apT("event.package.self", { item = tostring(chosenPackage.item) })
        else
            choices[index].text.data = apT("event.package.route",
                { slot = tostring(chosenPackage.slot), item = tostring(chosenPackage.item) })
        end
        choices[index].text.isLiteral = true
    end

    offeredPackages.a = packages[1]
    setChoice(0, packages[1])
    if packages[2] ~= nil then
        offeredPackages.b = packages[2]
        setChoice(1, packages[2])
    end
end

local BRANCH_EFFECTS = {
    AP_EVT_ZOLTAN_TITHE_A = function(name) feedTheLink(name, 1) end,
    AP_EVT_ZOLTAN_TITHE_B = function(name) drainTheLink(name) end,
    AP_EVT_PACKAGE_A = function(name) routePackage(name, offeredPackages.a) end,
    AP_EVT_PACKAGE_B = function(name) routePackage(name, offeredPackages.b) end,
    AP_EVT_SLUG_WHISPER_A = function(name) buyHint(name) end,
    AP_EVT_ANOTHER_WORLD_B = function(name) sendTrapOutward(name) end,
}

_G.apEventBranchEffects = BRANCH_EFFECTS

for branch, effect in pairs(BRANCH_EFFECTS) do
    script.on_game_event(branch, false, function()
        local ok, err = pcall(effect, branch)
        if not ok then
            eventLog("ERROR in " .. branch .. " : " .. tostring(err))
        end
    end)
end

function apEventStatus()
    eventLog(#_G.apEventLog .. " event effect(s) since startup")
    for index, entry in ipairs(_G.apEventLog) do
        eventLog(string.format("  %d. %s - %s", index, entry.event, entry.detail))
    end
end

function apEventsResetForTesting()
    _G.apEventLog = {}
end

local DECOR_X, DECOR_Y = 830, 10

local OUR_DECOR = {}
for name in pairs(BRANCH_EFFECTS) do
    OUR_DECOR[name:gsub("_[AB]$", "")] = true
end
for name in pairs(BRANCH_EFFECTS) do OUR_DECOR[name] = true end
OUR_DECOR["AP_STORE_EVENT"] = true
for _, name in ipairs({ "AP_EVT_ZOLTAN_TITHE_LINK", "AP_EVT_ZOLTAN_TOLL", "AP_EVT_ZOLTAN_TOLL_A",
                        "AP_EVT_ZOLTAN_TOLL_B", "AP_EVT_ANOTHER_WORLD_LINK", "AP_EVT_ANOTHER_WORLD_PLAIN",
                        "AP_EVT_ANOTHER_WORLD_PLAIN_A", "AP_EVT_ANOTHER_WORLD_VOID" }) do
    OUR_DECOR[name] = true
end

-- The loadEventList of the tithe and the surge picks the link version only when it can work.
local flagTicks = 0
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    flagTicks = flagTicks + 1
    if flagTicks < 30 then return end
    flagTicks = 0
    pcall(function()
        local online = _G.apNetConnected and _G.apNetConnected()
        Hyperspace.playerVariables.ap_energylink = (online and _G.apEnergyLink and _G.apEnergyLink.enabled) and 1 or 0
        Hyperspace.playerVariables.ap_traplink = (online and _G.apTrapLink and _G.apTrapLink.enabled) and 1 or 0
    end)
end)
local SHOPS = { "AP_STORE_EVENT_3", "AP_STORE_EVENT_6", "AP_STORE_EVENT_9", "AP_STORE_EVENT_12" }
for _, name in ipairs(SHOPS) do OUR_DECOR[name] = true end

local function setDecor()
    local world = Hyperspace.App.world
    local loc = world.starMap.currentLoc
    if loc == nil then return end

    local space = world.space
    loc.space = space:SwitchBackground("AP_BACKGROUND")
    loc.spaceImage = "AP_BACKGROUND"

    -- SwitchPlanet on the planet already shown froze FTL. After a reload the image is 0x0 though.
    local shown = tostring(loc.planetImage) == "AP_PLANET" and loc.planet ~= nil and (loc.planet.w or 0) > 0
    if not shown then
        loc.planet = space:SwitchPlanet("AP_PLANET")
        loc.planetImage = "AP_PLANET"
    end

    eventLog(string.format("AP planet: FTL suggested (%d, %d), we force (%d, %d)",
        space.currentPlanet.x, space.currentPlanet.y, DECOR_X, DECOR_Y))
    space.currentPlanet.x, space.currentPlanet.y = DECOR_X, DECOR_Y
    loc.planet.x, loc.planet.y = DECOR_X, DECOR_Y
    space:UpdatePlanetImage()
end

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
    local ok, err = pcall(function()
        if event == nil or not OUR_DECOR[tostring(event.eventName)] then
            return
        end
        if PRICE[tostring(event.eventName)] ~= nil then
            scrapBefore[tostring(event.eventName)] = scrap()
        end
        if tostring(event.eventName) == "AP_EVT_PACKAGE" then
            local okPackages, errPackages = pcall(writePackageChoices, event)
            if not okPackages then
                eventLog("packages not named: " .. tostring(errPackages))
            end
        end
        setDecor()
    end)
    if not ok then
        eventLog("decor not applied: " .. tostring(err))
    end
end)

local reloaded = false
script.on_init(function(newGame)
    reloaded = not newGame
end)

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if not reloaded then return end
    reloaded = false
    pcall(function()
        local loc = Hyperspace.App.world.starMap.currentLoc
        if loc ~= nil and tostring(loc.planetImage) == "AP_PLANET" then
            setDecor()
        end
    end)
end)

local SHOP_EVENTS = { "AP_STORE_EVENT" }
for _, name in ipairs(SHOPS) do SHOP_EVENTS[#SHOP_EVENTS + 1] = name end
for _, name in ipairs(SHOP_EVENTS) do
    script.on_game_event(name, false, function()
        local ok, err = pcall(setDecor)
        if not ok then
            eventLog("shop decor not applied: " .. tostring(err))
        end
    end)
end

eventLog("events module loaded: " .. (function()
    local count = 0
    for _ in pairs(BRANCH_EFFECTS) do count = count + 1 end
    return count
end)() .. " branches wired (console: LUA apEventStatus())")
