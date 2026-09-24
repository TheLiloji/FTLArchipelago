test("network: a check made before any seed waits for the connection instead of being lost", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    apNetResetForTesting()
    _G.apNetState.connected = false
    sim.clearLog()

    apSendCheck("PLAYER_SHIP_HARD:sector:3", "Sector 3")
    equals(apPendingCheckCount(), 1, "with no seed, the check stays queued")

    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = slotData({
        seed_hash = "AUDIT",
        loc = { ["PLAYER_SHIP_HARD:sector:3"] = "Kestrel Cruiser A: Reach sector 3" },
    }) })
    sim.net.connected = true
    sim.tick(1)

    local wasSent = false
    for _, call in ipairs(sim.net.calls) do
        if call[1] == "SendCheck" and call.name == "Kestrel Cruiser A: Reach sector 3" then
            wasSent = true
        end
    end
    check(wasSent, "once the seed is received, the check goes to the server")
    equals(apPendingCheckCount(), 0, "and the queue is emptied")

    apNetResetForTesting()
    apForgetChecksForTesting()
end)

test("network: a queued check that does not belong to the seed is dropped silently", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    apNetResetForTesting()
    _G.apNetState.connected = false

    apSendCheck("PLAYER_SHIP_HARD:sector:1", "Sector 1")
    equals(apPendingCheckCount(), 1, "queued while we don't know yet")

    applySeed({ loc = { ["PLAYER_SHIP_HARD:sector:3"] = "Kestrel Cruiser A: Reach sector 3" } })
    equals(apResendPendingChecks(), 0, "nothing is counted as recovered")
    equals(apPendingCheckCount(), 0, "and the queue doesn't keep it forever")

    apForgetChecksForTesting()
end)

test("shop: a refused package refunds the displayed price, even with no price from the network", function()
    sim.startRun(true)
    apShopGiftsConfigure({
        { slot = "Berserker", item = "Seashell", location = "already:1" },
    })
    local shownPrice = sim.rarityFor("AP_GIFT_1", 0).cost
    check(shownPrice > 0, "the box shows a price")
    local before = sim.player.currentScrap
    local restore = stub("apSendCheck", function() return false end)

    sim.buy("AP_GIFT_1")
    sim.tick(60)
    restore()

    equals(sim.player.currentScrap, before + shownPrice,
        "the player gets back exactly what FTL took")
end)

test("seed: changing seed gives shops back what the old one had removed", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.rarityFor("BEAM_2", 4)
    applySeed({ seed_hash = "OLD",
                shop = { mode = "locked", deliver = false, baseline = { "BEAM_2" } } })
    equals(sim.rarityFor("BEAM_2", 4).rarity, 0, "locked by the first seed")

    applySeed({ seed_hash = "NEW",
                shop = { mode = "locked", deliver = false, baseline = {} } })
    check(sim.rarityFor("BEAM_2", 4).rarity > 0,
        "the new seed doesn't lock it: it's back on the shelf")
end)

test("event: the relay with no package returns the scrap it took", function()
    sim.startRun(true)
    apShopGiftsConfigure({})
    sim.player.currentScrap = 40
    sim.openChoiceBox("AP_EVT_PACKAGE")
    sim.player.currentScrap = 25
    sim.clearLog()

    playBranch("AP_EVT_PACKAGE_A")

    equals(sim.player.currentScrap, 40, "the 15 taken by the game are returned")
    check(shownKey("event.gift.nothing", { scrap = 15 }), "and the player knows how much")
end)

test("event: the relay never returns more than the player had", function()
    sim.startRun(true)
    apShopGiftsConfigure({})
    sim.player.currentScrap = 6
    sim.openChoiceBox("AP_EVT_PACKAGE")
    sim.player.currentScrap = 0

    playBranch("AP_EVT_PACKAGE_A")

    equals(sim.player.currentScrap, 6, "it had 6, it gets back 6, not 15")
end)

test("event: the relay that actually ships a package keeps its 15", function()
    sim.startRun(true)
    _G.apShopSlotCount = 2
    twoGifts()
    sim.player.currentScrap = 40
    sim.openChoiceBox("AP_EVT_PACKAGE")
    sim.player.currentScrap = 25
    local restore = stub("apSendCheck", function() return true end)

    playBranch("AP_EVT_PACKAGE_A")
    restore()

    equals(sim.player.currentScrap, 25, "the service was rendered, the price stays paid")
end)

test("reset: a failed erase does not forget the seed", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    apInventoryClear()
    sim.durable = { ap_seed_tag = "4242", ap_items_done = "7" }
    sim.net.last = { uri = "", slot = "" }
    applySeed({ seed_hash = "seed-A" })
    apInventoryAdd({ kind = "ship", bp = "PLAYER_SHIP_ROCK" })
    applySeed({ seed_hash = "seed-B" })

    sim.quitCalled = false
    sim.renderMenu()
    local restore = stub("apNetRequestProfileReset", function() return false end)
    for y = 150, 400 do
        sim.click(640 - 200, y)
        if not apSeedChangeLeftovers() then break end
    end
    restore()

    equals(sim.durable["ap_seed_tag"], "4242", "nothing was erased: the fingerprint stays")
    equals(sim.durable["ap_items_done"], "7", "and so does the received items counter")
    check(not sim.quitCalled, "and the game doesn't close for nothing")
    sim.durable = {}
end)

test("filler: an item that cannot be delivered does not block the counter for the following ones", function()
    apNetResetForTesting()
    sim.durable = {}
    sim.startRun(true)

    apQueueItem({ kind = "filler", res = "nonexistent_resource", n = 1, index = 0 })
    apQueueItem({ kind = "filler", res = "scrap", n = 5, index = 1 })
    apQueueItem({ kind = "filler", res = "scrap", n = 5, index = 2 })
    drain()

    equals(sim.durable["ap_items_done"], "3",
        "all three are processed: otherwise scrap and fuel would come back on every launch")
    sim.durable = {}
end)

test("event: the zoltan tithe deposits nothing when the seed has EnergyLink disabled", function()
    apEnergyLinkConfigure({ enabled = false })
    sim.startRun(true)
    sim.clearLog()
    local deposits = 0
    local restore = stub("apNetEnergyLinkDeposit", function() deposits = deposits + 1; return true end)

    playBranch("AP_EVT_ZOLTAN_TITHE_A")
    restore()

    equals(deposits, 0, "no deposit goes to the server")
    check(not shownKey("event.link.fed"), "and we don't pretend to have paid into the link")
end)

test("event: the zoltan tithe does deposit when EnergyLink is active", function()
    apEnergyLinkConfigure({ enabled = true })
    sim.startRun(true)
    sim.clearLog()
    local deposits = 0
    local restore = stub("apNetEnergyLinkDeposit", function() deposits = deposits + 1; return true end)

    playBranch("AP_EVT_ZOLTAN_TITHE_A")
    restore()

    equals(deposits, 1, "the deposit goes through")
    check(shownKey("event.link.fed"), "and the player knows it")
end)

test("language: a received trap says its name AND what it does, in the player's language", function()
    sim.gameLanguage = "fr"
    sim.startRun(true)
    sim.clearLog()

    apQueueItem({ kind = "trap", eff = "breach", display = "Breach Trap" })
    drain()

    check(sim.shown("Breach Trap"), "the item's name stays the one from Archipelago")
    check(sim.shown(apT("trap.breach")), "and the translated sentence says what just happened")
    sim.gameLanguage = ""
end)

test("shop: a refused system refunds what the player actually paid", function()
    sim.startRun(true)
    _G.apInventory.systemCaps.cloaking = nil
    sim.jumpArrive()
    sim.setStore(true)
    sim.player.currentScrap = 200
    sim.tick(1)

    sim.player.currentScrap = 80
    sim.constructSystem("cloaking", 0, 150)
    sim.tick(5)

    equals(sim.player.currentScrap, 200,
        "the shop took 120, not the blueprint's 150: 120 is returned")
end)

test("home screen: TAB in the connection form does not open the dashboard", function()
    sim.started = false
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.keyDown(Defines.SDL.KEY_TAB)

    sim.startRun(true)
    sim.renderGui()
    check(not sim.drawnText(apT("hud.close")),
        "three TABs to move between fields don't leave the panel open in a run")

    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.renderGui()
    check(sim.drawnText(apT("hud.close")), "in a run, TAB does open the panel")
    sim.keyDown(Defines.SDL.KEY_TAB)
end)

test("language: the goal progress text agrees correctly in all six languages", function()
    local forbidden = {
        fr = { "1 victoires", "0 victoires sur 1" },
        it = { "1 vittorie" },
        en = { "1 victories" },
    }
    for _, code in ipairs({ "fr", "en", "de", "es", "it", "pt" }) do
        apLangResolve(code)
        for _, case in ipairs({ { 1, 5 }, { 0, 5 }, { 3, 5 }, { 1, 1 }, { 0, 1 } }) do
            local done, total = case[1], case[2]
            for _, key in ipairs({ "hud.goal.progress", "hud.goal.done" }) do
                local text = apT(key, { done = done, total = total, n = total })
                for _, mistake in ipairs(forbidden[code] or {}) do
                    check(not text:find(mistake, 1, true),
                        code .. ": \"" .. text .. "\" contains \"" .. mistake .. "\"")
                end
            end
        end
    end
    apLangResolve(nil)
end)

test("seed: on a real server, changing seed resets the checks to zero", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    sim.durable = {}
    sim.unlocked = {}
    _G.apInventory = { ships = {}, shopAvailability = {} }
    _G.apNetState.connected = true

    applySeed({ seed_hash = "FIRST", loc = { ["PLAYER_SHIP_HARD:sector:3"] = "K3" } })
    apSendCheck("PLAYER_SHIP_HARD:sector:3", "Sector 3")
    equals(apCheckCount().sent, 1, "a check made on the first seed")

    applySeed({ seed_hash = "SECOND", loc = { ["PLAYER_SHIP_HARD:sector:3"] = "K3" } })
    equals(apCheckCount().sent, 0,
        "the second seed starts fresh, otherwise its checks would be assumed already done")
    _G.apNetState.connected = false
end)

local function oxygen()
    local list = sim.player.vSystemList
    for i = 0, list:size() - 1 do
        if list[i].name == "oxygen" then return list[i] end
    end
    return nil
end

test("cap: with no progressive upgrades, systems level up like in the base game", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ system_caps = false })
    sim.startRun(true)
    apApplySystemRules()
    equals(oxygen().maxLevel, 3,
        "oxygen keeps its base game maximum: with no progressive item, nobody would unlock it")
end)

test("cap: with progressive upgrades, the cap stays at what Archipelago delivered", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({})
    sim.startRun(true)
    apApplySystemRules()
    equals(oxygen().maxLevel, 1, "nothing received: oxygen stays at the ship's level")
end)

test("cap: a blueprint allows the purchase without consuming an upgrade", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ kinds = { "cap" } })
    sim.startRun(true)
    apQueueItem({ kind = "cap", sys = "teleporter", n = 0, display = "Teleporter blueprint" })
    drain()
    equals(_G.apInventory.systemCaps.teleporter, 1, "the blueprint opens level 1, not level 2")
    for _ = 1, 2 do
        apQueueItem({ kind = "cap", sys = "teleporter", n = 1, display = "Progressive Teleporter" })
    end
    drain()
    equals(_G.apInventory.systemCaps.teleporter, 3,
        "blueprint then two upgrades: exactly the teleporter's maximum, nothing wasted")
end)

test("shop: with no blueprints in the seed, every system can be bought", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ system_blueprints = false })
    sim.startRun(true)
    sim.jumpArrive()
    sim.setStore(true)
    sim.player.currentScrap = 100
    sim.tick(1)
    sim.clearLog()

    sim.constructSystem("cloaking", 0, 80)
    sim.tick(5)

    equals(#sim.player._removed, 0, "the purchased system stays aboard")
    check(not shownKey("system.locked", { name = apSystemLabel("cloaking") }), "and no refusal is announced")
end)

test("contract: malformed slot_data is refused cleanly instead of half-crashing", function()
    for _, field in ipairs({ "kinds", "kinds_required", "items", "loc", "caps", "goal", "shop" }) do
        apContractResetForTesting()
        sim.clearLog()
        local seed = slotData({})
        seed[field] = "not a table"
        local ok, accepted = pcall(apApplySlotData, seed)
        check(ok, field .. ": no Lua error bubbles up")
        equals(accepted, false, field .. ": the seed is refused")
        check(shownKey("contract.refused", { reason = apT("contract.reason.malformed", { field = field }) }),
            field .. ": and the player knows which field is at fault")
    end
end)

local function lastTags()
    local tags = nil
    for _, call in ipairs(sim.net.calls) do
        if call[1] == "SetTags" then tags = call.tags end
    end
    return tags
end

test("network: the server only learns the links the seed activates", function()
    apContractResetForTesting()
    apNetResetForTesting()
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.net.connected = true
    sim.netEvent("connected", { name = "Navigator", extra = slotData({
        seed_hash = "LINKS",
        links = {
            death = { enabled = true, trigger = "run_lost", effect = "crew_member" },
            energy = { enabled = false },
            trap = { enabled = false },
        },
    }) })
    sim.tick(1)

    local tags = lastTags()
    check(tags ~= nil, "tags are announced after the seed is read")
    equals(table.concat(tags or {}, ","), "DeathLink",
        "DeathLink active, TrapLink off: we don't receive other players' traps")
end)

test("solo: the Solo Mode button really starts solo mode, even with an active field", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    apSoloResetForTesting()
    sim.renderMenu()
    local started = 0
    local restore = stub("apSoloStart", function() started = started + 1 end)
    for y = 560, 715, 2 do
        for x = 220, 305, 4 do
            if started == 0 then sim.click(x, y) end
        end
    end
    restore()
    equals(started, 1, "a click on the button starts solo mode")

    sim.type("s")
    check(not _G.apSoloEnabled, "while the S key itself goes into the input field")
end)

test("network: the first encrypted attempt failing does not make a responding server look unreachable", function()
    sim.startRun(true)
    apNetResetForTesting()
    apNetConnect("localhost:38281", "Navigator", "")
    sim.clearLog()

    sim.netEvent("error", { name = "unreachable", extra = "TLS handshake failed" })
    sim.tick(30)
    sim.netEvent("connected", { name = "Navigator", extra = slotData({ seed_hash = "LOCAL" }) })
    sim.net.connected = true
    sim.tick(400)

    check(not shownKey("net.error.unreachable"),
        "apclientpp tries wss then ws: this first failure is not an outage")
end)

test("contract: seeds from contracts 1 to 3 are accepted, contract 4 is refused", function()
    for _, case in ipairs({ { 1, true }, { 2, true }, { 3, true }, { 4, false } }) do
        apContractResetForTesting()
        local ok = apApplySlotData(slotData({ contract = case[1] }))
        equals(ok ~= false, case[2], "contract " .. case[1])
    end
end)

local function tryConnect()
    apContractResetForTesting()
    apNetResetForTesting()
    apConnectResetForTesting()
    sim.net.last = { uri = "localhost:38281", slot = "Navigator" }
    sim.renderMenu()
    equals(apConnectState().slot, "Navigator", "the slot is pre-filled")
    check(apConnectNow(), "the attempt goes out")
    equals(apConnectState().message, apT("connect.trying", { uri = "localhost:38281" }),
        "the panel announces the attempt")
end

test("network: the panel says when the connection succeeded", function()
    tryConnect()
    sim.netEvent("connected", { name = "Navigator", extra = slotData({ seed_hash = "OK" }) })
    sim.net.connected = true
    sim.tick(1)
    sim.renderMenu()
    equals(apConnectState().message, apT("net.connected", { slot = "Navigator" }),
        "the message goes from 'connecting to...' to the link being established")
end)

test("network: the panel says why the seed was refused", function()
    tryConnect()
    sim.netEvent("connected", { name = "Navigator", extra = slotData({ contract = 99 }) })
    sim.net.connected = true
    sim.tick(1)
    sim.renderMenu()
    local reason = apT("contract.reason.toonew", { seed = 99, mod = 3 })
    equals(apConnectState().message, apT("contract.refused", { reason = reason }),
        "instead of staying on 'connecting to...' forever")
end)

test("notify: a burst of items gets summarized instead of overflowing the screen", function()
    apNotifyResetForTesting()
    sim.clearLog()
    for i = 1, 12 do apNotifyItem("Item " .. i, "Nina", false) end
    apNotifyFlushForTesting()
    check(shownKey("item.received.many", { n = 12 }), "the player reads that they received twelve")
    check(#sim.screen <= 2, "in one line, not twelve where six would be pushed off screen")

    sim.clearLog()
    for i = 1, 2 do apNotifyItem("Item " .. i, "Nina", false) end
    apNotifyFlushForTesting()
    check(sim.shown("Item 1") and sim.shown("Item 2"), "two items are still named one by one")
end)

test("network: the dashboard says when the link is lost mid-run", function()
    applySeed({ goal = { kind = "victories", count = 3 },
                loc = { ["PLAYER_SHIP_HARD:sector:3"] = "K3" } })
    sim.startRun(true)
    _G.apNetState.connected = true
    apToggleHud()
    sim.renderGui()
    check(not sim.drawnText(apT("hud.link_lost")), "connected: nothing to report")

    _G.apNetState.connected = false
    sim.renderGui()
    check(sim.drawnText(apT("hud.link_lost")), "disconnected: the player knows their checks are waiting")
    apToggleHud()
end)

test("reset: answering yes asks the real module to erase, then closes the game", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    apInventoryClear()
    sim.durable = { ap_autoconnect = "1", ap_seed_tag = "4242" }
    sim.net.resetRequested = false
    applySeed({ seed_hash = "seed-A" })
    apInventoryAdd({ kind = "ship", bp = "PLAYER_SHIP_ROCK" })
    applySeed({ seed_hash = "seed-B" })

    sim.quitCalled = false
    sim.renderMenu()
    for y = 150, 400 do
        sim.click(640 - 200, y)
        if sim.quitCalled then break end
    end

    equals(sim.netCalls("RequestProfileReset"), 1, "the module receives the request")
    check(apNetProfileResetRequested(), "and the mod knows it was made")
    equals(sim.netCalls("RelaunchWhenClosed"), 1, "the relaunch is requested before closing")
    check(sim.quitCalled, "then the game closes")
    sim.durable = {}
end)

local function answerYes()
    apContractResetForTesting()
    apConnectResetForTesting()
    apInventoryClear()
    sim.durable = { ap_autoconnect = "1", ap_seed_tag = "4242" }
    sim.net.resetRequested = false
    applySeed({ seed_hash = "seed-A" })
    apInventoryAdd({ kind = "ship", bp = "PLAYER_SHIP_ROCK" })
    applySeed({ seed_hash = "seed-B" })
    sim.quitCalled = false
    sim.renderMenu()
    for y = 150, 400 do
        sim.click(640 - 200, y)
        if sim.quitCalled then break end
    end
    sim.renderMenu()
end

test("reset: when the relaunch is planned, the screen says FTL restarts on its own", function()
    sim.net.relaunchPossible = true
    answerYes()
    equals(apConnectState().message, apT("reset.relaunch"), "the player has nothing to do")
    sim.durable = {}
end)

test("reset: if the relaunch is impossible, the screen asks to relaunch by hand", function()
    sim.net.relaunchPossible = false
    answerYes()
    equals(apConnectState().message, apT("reset.asked"), "the player knows they have to relaunch")
    check(sim.quitCalled, "and the game closes anyway")
    sim.net.relaunchPossible = nil
    sim.durable = {}
end)

test("hooks: an error inside a game hook is logged, not swallowed", function()
    sim.clearLog()
    apTry("[AP-test] ", function() error("boom") end)
    check(sim.logged("[AP-test] error:"), "the failure shows in the log")
    check(sim.logged("boom"), "with its message")
end)

test("systems: building a system runs its hook without error, before maxLevel exists", function()
    sim.startRun(true)
    sim.clearLog()
    sim.jumpArrive()
    sim.setStore(true)
    sim.constructSystem("cloaking", 0, 90)
    sim.tick(5)
    check(not sim.logged("[AP-sys] error:"), "the hook does not read fields Hyperspace has not set yet")
end)
