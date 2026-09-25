local TAG = "[AP-test] "

local function testLog(message)
    log(TAG .. message)
end

local function snapshot(prefix)
    if _G.apEndSnapshot then
        _G.apEndSnapshot(prefix)
    end
end

local function eventPossible()
    local ok, reason = pcall(function()
        if Hyperspace.App.world.bStartedGame ~= true then return "not in a run" end
        local gui = Hyperspace.App.gui
        if gui.choiceBoxOpen or gui.event_pause or gui.menu_pause then
            return "an event or the menu is open"
        end
        local loc = Hyperspace.App.world.starMap.currentLoc
        if loc ~= nil and loc.event ~= nil and loc.event.store == true then
            return "this beacon already has a shop"
        end
        return nil
    end)
    if not ok then return "game state unreadable" end
    return reason
end

local function playEvent(eventName)
    local refusal = eventPossible()
    if refusal ~= nil then
        testLog("event " .. eventName .. " refused: " .. refusal)
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("test.event.refused"))
        end
        return
    end
    local ok, err = pcall(function()
        local world = Hyperspace.App.world
        Hyperspace.CustomEventsParser.GetInstance():LoadEvent(world, eventName, false, -1)
    end)
    if ok then
        testLog("event " .. eventName .. " played")
    else
        testLog("failed to load " .. eventName .. ": " .. tostring(err))
    end
end

local function damagePlayer(amount)
    local ok, err = pcall(function()
        Hyperspace.ships.player:DamageHull(amount, true)
    end)
    testLog(ok and ("damage dealt: " .. amount) or ("damage failed: " .. tostring(err)))
end

local function surveyAugments()
    local okList, contents = pcall(function()
        local list = Hyperspace.ships.player:GetAugmentationList()
        local names = {}
        for i = 0, list:size() - 1 do
            names[#names + 1] = tostring(list[i])
        end
        return names
    end)
    if okList then
        testLog("augments (" .. #contents .. "): "
            .. (#contents > 0 and table.concat(contents, ", ") or "none"))
    else
        testLog("GetAugmentationList UNAVAILABLE: " .. tostring(contents))
    end

    local okHas, has = pcall(function()
        return Hyperspace.ships.player:HasAugmentation("AP_DEAL_1")
    end)
    testLog("HasAugmentation: " .. (okHas and ("responds (" .. tostring(has) .. ")")
        or ("UNAVAILABLE: " .. tostring(has))))
end

local function surveyBeacons()
    local ok, err = pcall(function()
        local starMap = Hyperspace.App.world.starMap
        local locations = starMap.locations
        local total = locations:size()
        local archipelago, stores = 0, 0
        local names = {}

        for i = 0, total - 1 do
            local loc = locations[i]
            if loc ~= nil and loc.event ~= nil then
                local name = tostring(loc.event.eventName)
                names[name] = (names[name] or 0) + 1
                if name:find("AP_STORE", 1, true) then
                    archipelago = archipelago + 1
                elseif name:find("STORE", 1, true) then
                    stores = stores + 1
                end
            end
        end

        testLog(string.format("map: %d beacons, %d Archipelago, %d ordinary shops",
            total, archipelago, stores))
        if archipelago == 0 then
            testLog("  NO Archipelago shop in this sector - events present:")
            local sorted = {}
            for name in pairs(names) do sorted[#sorted + 1] = name end
            table.sort(sorted)
            for _, name in ipairs(sorted) do
                testLog("    " .. name .. " x" .. names[name])
            end
        end
    end)
    if not ok then
        testLog("beacon survey failed: " .. tostring(err))
    end
end

local function killCrew()
    local ok = pcall(function()
        local crewList = Hyperspace.ships.player.vCrewList
        for i = crewList:size() - 1, 0, -1 do
            local crew = crewList[i]
            if crew ~= nil and crew.iShipId == 0 then
                crew:Kill(true)
            end
        end
    end)
    testLog(ok and "crew killed" or "failed")
end

local LOCKED_SAMPLE = { "LASER_BURST_3", "BEAM_2", "DEFENSE_1", "SCRAP_COLLECTOR" }

local function fakeSlotData()
    return {
        contract = 1,
        kinds = { "ship", "cap", "start", "filler", "trap", "shop" },
        kinds_required = { "ship", "cap", "start", "shop" },
        seed_name = "TEST",
        seed_hash = 1234,
        start_ship = "PLAYER_SHIP_HARD",
        items = {
            ["Burst Laser Mark II"] = { k = "shop", bp = "LASER_BURST_3" },
            ["Halberd Beam"] = { k = "shop", bp = "BEAM_2" },
            ["Defense Drone Mark I"] = { k = "shop", bp = "DEFENSE_1" },
            ["Scrap Recovery Arm"] = { k = "shop", bp = "SCRAP_COLLECTOR" },
            ["20 Scrap"] = { k = "filler", res = "scrap", n = 20 },
            ["Fire Trap"] = { k = "trap", eff = "fire" },
        },
        shop = { mode = "locked", deliver = true, baseline = LOCKED_SAMPLE },
        links = {
            death = { enabled = true, trigger = "run_lost", effect = "varied", graceSeconds = 15 },
            energy = { enabled = true },
            trap = { enabled = false },
        },
    }
end

local function selfCheck()
    local results = {}
    local function verify(label, ok, detail)
        results[#results + 1] = (ok and "  OK   " or "  FAIL ") .. " " .. label
            .. (detail and (" - " .. tostring(detail)) or "")
        return ok
    end

    local blueprints = Hyperspace.Blueprints

    local GETTERS = { "GetWeaponBlueprint", "GetDroneBlueprint", "GetAugmentBlueprint" }
    -- FTL keeps weapons, drones and augments in separate blueprint tables; try each in turn.
    local function findBlueprint(name)
        for _, getter in ipairs(GETTERS) do
            local ok, bp = pcall(function() return blueprints[getter](blueprints, name) end)
            if ok and bp ~= nil and tostring(bp.name) == name then
                return bp
            end
        end
        return nil
    end

    local ok, ghost = pcall(function()
        return blueprints:GetWeaponBlueprint("THIS_NAME_DOES_NOT_EXIST")
    end)
    if ok and ghost ~= nil then
        verify("an unknown blueprint returns a non-nil object (hence the name check)",
            true, "name='" .. tostring(ghost.name) .. "'")
        verify("and this ghost object does have a name different from the one requested",
            tostring(ghost.name) ~= "THIS_NAME_DOES_NOT_EXIST")
    else
        verify("an unknown blueprint returns nil: the name check would be unnecessary", false,
            "needs checking, the mod assumes the opposite")
    end

    local realNames = { "LASER_BURST_3", "BEAM_2", "DEFENSE_1", "SCRAP_COLLECTOR" }
    for _, name in ipairs(realNames) do
        verify("blueprint " .. name .. " exists in ftl.dat", findBlueprint(name) ~= nil)
    end

    for _, name in ipairs({ "BURST_LASER_2", "DRONE_DEFENSE_1" }) do
        verify("'" .. name .. "' does not exist (that was indeed a typo)", findBlueprint(name) == nil)
    end

    local before = {}
    local function rarityOf(name)
        local bp = findBlueprint(name)
        return bp ~= nil and bp.desc.rarity or nil
    end
    for _, name in ipairs(LOCKED_SAMPLE) do
        before[name] = rarityOf(name)
    end

    if _G.apApplySlotData then
        local accepted = _G.apApplySlotData(fakeSlotData())
        verify("the test slot_data is accepted", accepted)
        verify("items are removed from shops", rarityOf("LASER_BURST_3") == 0,
            "rarity = " .. tostring(rarityOf("LASER_BURST_3")))

        if _G.apApplyShopItem then
            pcall(_G.apApplyShopItem,
                { kind = "shop", bp = "LASER_BURST_3", isReplay = true })
        end
        verify("receiving the item makes it reappear", (rarityOf("LASER_BURST_3") or 0) > 0,
            "rarity = " .. tostring(rarityOf("LASER_BURST_3")))

        local future = fakeSlotData()
        future.contract = 99
        verify("a seed from a too-recent contract is refused", _G.apApplySlotData(future) == false)
    end

    local giftOk = true
    for _, name in ipairs({ "AP_GIFT_1", "AP_GIFT_2", "AP_GIFT_3" }) do
        local found = false
        local gotOk, bp = pcall(function()
            return blueprints:GetWeaponBlueprint(name)
        end)
        if gotOk and bp ~= nil and tostring(bp.name) == name then
            found = true
        end
        if not verify("item " .. name .. " is declared (weapon)", found) then
            giftOk = false
        end
    end

    for _, name in ipairs({ "AP_DEAL_1", "AP_DEAL_2", "AP_DEAL_3" }) do
        local found = false
        local gotOk, bp = pcall(function()
            return blueprints:GetAugmentBlueprint(name)
        end)
        if gotOk and bp ~= nil and tostring(bp.name) == name then
            found = true
        end
        verify("deal " .. name .. " is declared (augment)", found)
    end

    local gotArt, art = pcall(function()
        return tostring(blueprints:GetWeaponBlueprint("AP_GIFT_1").weaponArt)
    end)
    verify("the gift image is indeed 'ap_gift'", gotArt and art == "ap_gift",
        "weaponArt = '" .. tostring(art) .. "'")

    local gotRef, ref = pcall(function()
        return tostring(blueprints:GetWeaponBlueprint("LASER_BURST_3").weaponArt)
    end)
    testLog("  (reference: LASER_BURST_3.weaponArt = '"
        .. (gotRef and ref or "?") .. "')")

    if giftOk and _G.apShopGiftsConfigure then
        _G.apShopGiftsConfigure({
            { slot = "Navigator", item = "Burst Laser Mark II", sphere = 2, kind = "progression" },
        })
        local gotOk, title = pcall(function()
            return tostring(blueprints:GetWeaponBlueprint("AP_GIFT_1").desc.title.data)
        end)
        local expected = apT("shop.slot.title", { slot = "Navigator" })
        verify("the gift title is rewritten from the server",
            gotOk and title == expected, "displayed: '" .. tostring(title) .. "'")
        _G.apShopGiftsConfigure({})
    end

    local drawOk = pcall(function()
        local white = Graphics.GL_Color(1, 1, 1, 1)
        Graphics.CSurface.GL_DrawRect(-100, -100, 1, 1, white)
        Graphics.CSurface.GL_DrawRectOutline(-100, -100, 1, 1, white, 1)
        Graphics.CSurface.GL_SetColor(white)
        Graphics.freetype.easy_print(10, -100, -100, "probe")
    end)
    verify("the dashboard drawing primitives respond", drawOk)

    for name, rarity in pairs(before) do
        if rarity ~= nil then
            local bp = findBlueprint(name)
            if bp ~= nil then
                bp.desc.rarity = rarity
            end
        end
    end
    if _G.apInventory then
        _G.apInventory.shopAvailability = {}
    end
    if _G.apShopConfigure then
        pcall(_G.apShopConfigure, { mode = "rarity_boost", deliver = true, baseline = {} })
    end

    local failures = 0
    for _, line in ipairs(results) do
        if line:find("FAIL", 1, true) then failures = failures + 1 end
    end
    testLog("=== self-check in the real engine: "
        .. (#results - failures) .. " OK, " .. failures .. " failure(s) ===")
    for _, line in ipairs(results) do
        testLog(line)
    end
    testLog("=== end of self-check (state reset) ===")
end

local selfCheckDone = false
script.on_internal_event(Defines.InternalEvents.MAIN_MENU, function()
    if selfCheckDone then
        return
    end
    selfCheckDone = true
    local ok, err = apRunIsolated(selfCheck)
    if not ok then
        testLog("self-check interrupted: " .. tostring(err))
    end
end)

local DEMO_GIFTS = {
    { slot = "Navigator", item = "Burst Laser Mark II", sphere = 2, kind = "progression",
      location = "PLAYER_SHIP_HARD:sector:3", cost = 45 },
    { slot = "Berserker", item = "20 Scrap", sphere = 1, kind = "filler",
      location = "PLAYER_SHIP_HARD:sector:4", cost = 20 },
    { slot = "Axel", item = "Zoltan Shield", sphere = 4, kind = "useful",
      location = "PLAYER_SHIP_HARD:sector:5", cost = 70 },
    { slot = "Nina", item = "Halberd Beam", sphere = 3, kind = "progression",
      location = "PLAYER_SHIP_HARD:sector:6", cost = 60 },
    { slot = "Berserker", item = "Drone Parts", sphere = 2, kind = "filler",
      location = "PLAYER_SHIP_HARD:sector:7", cost = 25 },
    { slot = "Navigator", item = "Engi Crew", sphere = 5, kind = "useful",
      location = "PLAYER_SHIP_HARD:sector:8", cost = 80 },
}

local function demoGifts()
    if _G.apGiftsDemo and #_G.apGiftsDemo > 0 then
        return _G.apGiftsDemo
    end
    return DEMO_GIFTS
end

local function setUpDemo()
    if _G.apShopGiftsConfigure then
        _G.apShopGiftsConfigure(demoGifts(), "demo")
    end
end

local nextUnlock = 1

local CUSTOM_EVENTS = {
    "AP_EVT_PACKAGE", "AP_EVT_ZOLTAN_TITHE",
    "AP_EVT_SLUG_WHISPER", "AP_EVT_ANOTHER_WORLD",
}
local nextCustomEvent = 1

local armed = false

local function inGame()
    local ok, playing = pcall(function()
        return Hyperspace.App.world.bStartedGame == true
    end)
    return ok and playing
end

local function keyAllowed(key)
    if armed then
        return true
    end
    return key == Defines.SDL.KEY_s and not inGame()
end

script.on_internal_event(Defines.InternalEvents.ON_KEY_DOWN, function(key)
    if key == Defines.SDL.KEY_F10 then
        armed = not armed
        testLog(armed and "F10 - test keys armed" or "F10 - test keys disarmed")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT(armed and "test.keys.on" or "test.keys.off"))
        end
        return
    end
    if not keyAllowed(key) then
        return
    end
    if key == Defines.SDL.KEY_F1 then
        testLog("F1 - opening a shop")
        playEvent("STORE")
    elseif key == Defines.SDL.KEY_x then
        testLog("X - end combat and load FTL drive")
        local destroyed = pcall(function()
            local enemy = Hyperspace.ships.enemy
            if enemy ~= nil and not enemy.bDestroyed then
                enemy:DamageHull(enemy.ship.hullIntegrity.first + 10, true)
            end
        end)
        local loaded, err = pcall(function()
            local player = Hyperspace.ships.player
            player.jump_timer.first = player.jump_timer.second
        end)
        testLog("X - enemy: " .. (destroyed and "destroyed or absent" or "failed")
            .. ", FTL drive: " .. (loaded and "loaded" or ("failed: " .. tostring(err))))
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT(loaded and "test.skip_combat" or "test.skip_combat.partial"))
        end
    elseif key == Defines.SDL.KEY_F2 then
        testLog("F2 - +200 scrap")
        pcall(function() Hyperspace.ships.player:ModifyScrapCount(200, false) end)
    elseif key == Defines.SDL.KEY_F3 then
        testLog("F3 - next sector")
        pcall(function()
            local starMap = Hyperspace.App.world.starMap
            starMap.bSecretSector = false
            Hyperspace.App.world.starMap:ForceWaitMessage("")
        end)
        testLog("(if nothing happens: use the exit beacon, AdvanceWorldLevel is not exposed)")
    elseif key == Defines.SDL.KEY_F4 then
        testLog("F4 - shop status")
        if _G.apShopStatus then _G.apShopStatus() end
    elseif key == Defines.SDL.KEY_F5 then
        testLog("F5 - queuing test items")
        if _G.apQueueItem then
            _G.apQueueItem({ kind = "filler", res = "scrap", n = 25 })
            _G.apQueueItem({ kind = "filler", res = "fuel", n = 5 })
            _G.apQueueItem({ kind = "filler", res = "missiles", n = 3 })
            _G.apQueueItem({ kind = "filler", res = "hull", n = 4 })
            _G.apQueueItem({ kind = "filler", res = "crew", n = 1 })
            _G.apQueueItem({ kind = "trap", eff = "fire" })
        end
        if _G.apFillerStatus then _G.apFillerStatus() end
    elseif key == Defines.SDL.KEY_F6 then
        testLog("F6 - simulated Archipelago connection")
        nextUnlock = 1
        if _G.apApplySlotData then
            local accepted = _G.apApplySlotData(fakeSlotData())
            testLog(accepted and "seed accepted" or "SEED REFUSED (see [AP-contract])")
        end
        if _G.apShopGiftsScouted then
            _G.apShopGiftsScouted(demoGifts())
        end
        if _G.apShopStatus then _G.apShopStatus() end
    elseif key == Defines.SDL.KEY_e then
        testLog("E - queuing equipment")
        if _G.apQueueItem then
            _G.apQueueItem({ kind = "weapon", bp = "LASER_BURST_3", display = "Burst Laser Mark II" })
            _G.apQueueItem({ kind = "drone", bp = "DEFENSE_1", display = "Defense Drone Mark I" })
            _G.apQueueItem({ kind = "augment", bp = "SHIELD_RECHARGE", display = "Shield Charge Booster" })
        end
        if _G.apFillerStatus then _G.apFillerStatus() end
    elseif key == Defines.SDL.KEY_p then
        testLog("P - progression items (ship, cap, starting bonus)")
        if _G.apQueueItem then
            _G.apQueueItem({ kind = "ship", bp = "PLAYER_SHIP_ROCK",
                             display = "Rock Cruiser Key" })
            _G.apQueueItem({ kind = "cap", sys = "shields", n = 1,
                             display = "Progressive Shields" })
            _G.apQueueItem({ kind = "start", sys = "engines", n = 1,
                             display = "Engines Head Start" })
        end
        if _G.apFillerStatus then _G.apFillerStatus() end
    elseif key == Defines.SDL.KEY_v then
        local name = CUSTOM_EVENTS[nextCustomEvent]
        testLog(string.format("V - event %d/%d: %s",
            nextCustomEvent, #CUSTOM_EVENTS, name))
        playEvent(name)
        nextCustomEvent = nextCustomEvent % #CUSTOM_EVENTS + 1
    elseif key == Defines.SDL.KEY_b then
        testLog("B - event summary")
        if _G.apEventStatus then _G.apEventStatus() end
    elseif key == Defines.SDL.KEY_F7 then
        testLog("F7 - unlock status")
        if _G.apUnlockStatus then _G.apUnlockStatus() end
    elseif key == Defines.SDL.KEY_F8 then
        testLog("F8 - unlocking the Rock")
        if _G.apUnlock then _G.apUnlock("PLAYER_SHIP_ROCK", 0) end
        if _G.apUnlockStatus then _G.apUnlockStatus() end
    elseif key == Defines.SDL.KEY_F9 then
        testLog("F9 - state survey")
        snapshot("F9 -")
        surveyBeacons()
        surveyAugments()
        if _G.apContractStatus then _G.apContractStatus() end
        if _G.apGoalStatus then _G.apGoalStatus() end
        if _G.apDeathLinkStatus then _G.apDeathLinkStatus() end
        if _G.apEnergyLinkStatus then _G.apEnergyLinkStatus() end
    elseif key == Defines.SDL.KEY_F10 then
        testLog("F10 - victory simulation")
        playEvent("BOSS_DESTROYED")
    elseif key == Defines.SDL.KEY_F11 then
        testLog("F11 - defeat simulation by destruction")
        damagePlayer(999)
    elseif key == Defines.SDL.KEY_F12 then
        testLog("F12 - defeat simulation by crew loss")
        killCrew()
    elseif key == Defines.SDL.KEY_k then
        testLog("K - DeathLink received")
        if _G.apDeathLinkReceive then
            local applied = _G.apDeathLinkReceive("Berserker", "fell into a pit")
            testLog(applied and "effect applied" or "no effect (DeathLink off? outside a run?)")
        end
    elseif key == Defines.SDL.KEY_g then
        testLog("G - fuel received from the EnergyLink pool")
        if _G.apEnergyLinkGranted then
            _G.apEnergyLinkGranted(2000000)
        end
        if _G.apEnergyLinkStatus then _G.apEnergyLinkStatus() end
    elseif key == Defines.SDL.KEY_h then
        local name = LOCKED_SAMPLE[nextUnlock]
        if name == nil then
            testLog("H - all sample items are already unlocked")
        else
            testLog("H - unlocking " .. name)
            nextUnlock = nextUnlock + 1
            if _G.apQueueItem then
                _G.apQueueItem({ kind = "shop", bp = name, display = name })
            end
        end
    elseif key == Defines.SDL.KEY_c then
        testLog("C - Archipelago shop")
        setUpDemo()

        if _G.apShopGiftsStatus then _G.apShopGiftsStatus() end
        playEvent("AP_STORE_EVENT")
    elseif key == Defines.SDL.KEY_s then
        if _G.apSoloEnabled then
            testLog("S - stopping solo mode")
            if _G.apSoloStop then _G.apSoloStop() end
        else
            testLog("S - starting solo mode")
            if _G.apSoloStart then _G.apSoloStart() end
        end
        if _G.apSoloStatus then _G.apSoloStatus() end
    elseif key == Defines.SDL.KEY_r then
        testLog("R - resetting the shop")
        setUpDemo()
        if _G.apShopGiftsResetForTesting then
            _G.apShopGiftsResetForTesting()
        end
        if _G.apShopGiftsStatus then _G.apShopGiftsStatus() end
    elseif key == Defines.SDL.KEY_j then
        testLog("J - trap received via TrapLink")
        if _G.apTrapLinkReceive then
            _G.apTrapLink.enabled = true
            _G.apTrapLinkReceive("Berserker", "Ice Trap")
        end
        if _G.apTrapLinkStatus then _G.apTrapLinkStatus() end
    else
        testLog("key " .. tostring(key))
    end
    return Defines.Chain.CONTINUE
end)

testLog("shortcuts: F6 AP connection, F1 shop, F2 scrap, F4 shop status, "
    .. "F5 items, E equipment, H unlock, K DeathLink, G EnergyLink, J TrapLink, "
    .. "C Archipelago shop, B event summary, V events, P progression, "
    .. "R reset, S solo mode, X end combat and load FTL drive, TAB dashboard, "
    .. "F9 full status")
