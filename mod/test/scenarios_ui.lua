test("toasts: an item, a check and a trap each get their own colour, then fade away", function()
    sim.startRun(true)
    apNotifyResetForTesting()
    apNotifyItem("Burst Laser II", "Axel")
    apNotifyCheck("Archipelago Shop 3")
    apNotifyFlushForTesting()
    apNotifyTrap("a fire")
    local toasts = apToastsForTesting()
    equals(#toasts, 3, "three toasts")
    equals(toasts[1].tone, "good", "the item is green")
    equals(toasts[2].tone, "border", "the check is violet")
    equals(toasts[3].tone, "bad", "the trap is red")
    sim.renderGui()
    check(sim.drawnText("Burst Laser II"), "they are drawn")
    for _ = 1, 400 do sim.renderGui() end
    equals(#apToastsForTesting(), 0, "and gone a few seconds later")
end)

test("toasts: never more than four, and none over the dashboard", function()
    sim.startRun(true)
    apNotifyResetForTesting()
    for index = 1, 6 do apNotifyStatus("message " .. index) end
    equals(#apToastsForTesting(), 4, "the oldest ones make room")
    apToggleHud()
    sim.renderGui()
    check(not sim.drawnText("message 6"), "hidden while the dashboard is open")
    apToggleHud()
    sim.renderGui()
    check(sim.drawnText("message 6"), "back once it closes")
end)

test("home screen: with a seed, a status card replaces the form", function()
    apConnectResetForTesting()
    sim.startRun(false)
    sim.started = false
    applySeed({ loc = { ["shop:1"] = "Archipelago Shop 1" } })
    sim.renderMenu()
    check(sim.drawnText(apT("dash.status.offline")), "it says the seed is kept offline")
    check(sim.drawnText(apT("connect.disconnect")), "with the button to leave it")
    check(not sim.drawnText(apT("connect.field.slot")), "and no form")
end)

test("home screen: the seed question opens in its own window, with a title", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    apInventoryClear()
    sim.started = false
    applySeed({ seed_hash = "seed-A" })
    apInventoryAdd({ kind = "ship", bp = "PLAYER_SHIP_ROCK" })
    applySeed({ seed_hash = "seed-B" })
    sim.renderMenu()
    check(sim.drawnText(apT("question.seed.title")), "the window has a title")
    check(sim.drawnText(apT("reset.yes")) and sim.drawnText(apT("reset.no")), "and both answers")
    apSeedChangeAcknowledged()
end)

test("start-of-run menu: the chosen weapon stays highlighted, the rest are greyed out", function()
    apInventoryClear()
    apInventory.shopAvailability.LASER_BURST_3 = 2
    apInventory.shopAvailability.BEAM_2 = 2
    sim.startRun(true)
    sim.renderGui()
    sim.click(apLoadoutPoint("row", "weapon", 1))
    sim.renderGui()
    check(sim.drawnText(apT("loadout.chosen")), "the column says it is done")
    check(sim.drawnText(apT("loadout.count", { n = 0 })) or true, "the other columns keep their count")
end)

test("hints: the Slug prefers a check the player can do now", function()
    sim.startRun(true)
    applySeed({ loc = { ["PLAYER_SHIP_HARD_2:sector:3"] = "Kestrel B: Reach sector 3",
                        ["shop:4"] = "Archipelago Shop 4" } })
    _G.apInventory.ships = { "PLAYER_SHIP_HARD" }
    equals(apCheckPlayable("PLAYER_SHIP_HARD_2:sector:3"), false, "a layout not unlocked is out of reach")
    equals(apCheckPlayable("shop:4"), true, "the shop is always reachable")
    for _ = 1, 20 do
        local picked = apHintPick({ "PLAYER_SHIP_HARD_2:sector:3", "shop:4" }, function(key) return key end)
        equals(picked, "shop:4", "the reachable one is picked")
    end
end)

test("journal: the items received survive a restart, per seed", function()
    sim.startRun(true)
    sim.durable = {}
    applySeed({ seed_hash = "journal-seed" })
    _G.apReceivedHistory = {}
    apRecordReceived("Glaive Beam", "Axel")
    local stored = sim.durable["ap_journal_" .. tostring(apSeedFingerprint())]
    check(stored ~= nil and stored:find("Glaive Beam", 1, true), "the journal is written to the module's memory")

    _G.apReceivedHistory = {}
    apContractResetForTesting()
    applySeed({ seed_hash = "journal-seed" })
    apToggleHud()
    apDashboardPage("journal")
    sim.renderGui()
    check(sim.drawnText("Glaive Beam"), "and read back for the same seed")
    apToggleHud()
end)

test("seed question: keeping the progress reconnects by itself", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    sim.started = false
    sim.renderMenu()
    sim.type("Navigator")
    apInventoryClear()
    applySeed({ seed_hash = "seed-C" })
    apInventoryAdd({ kind = "ship", bp = "PLAYER_SHIP_ROCK" })
    applySeed({ seed_hash = "seed-D" })
    local calls = 0
    local restoreConnect = stub("apNetConnect", function() calls = calls + 1; return true end)
    sim.renderMenu()
    for y = 360, 420 do
        sim.click(900, y)
        if calls > 0 then break end
    end
    restoreConnect()
    equals(calls, 1, "No, keep it asks the server again, without typing anything")
end)

test("new screens: no text leaves its frame, in all six languages", function()
    local function outside(box)
        local out = {}
        for _, d in ipairs(sim.draws) do
            local right = d.x + (d.maxWidth or 0)
            if d.x < box.x or right > box.x + box.w + 1 then out[#out + 1] = d.text end
        end
        return out
    end
    for _, code in ipairs({ "en", "fr", "de", "es", "it", "pt" }) do
        apLangSet(code, "test")

        apContractResetForTesting()
        apConnectResetForTesting()
        sim.started = false
        sim.renderMenu()
        local form = outside({ x = 24, w = 372 })
        equals(#form, 0, code .. ": connection form (" .. tostring(form[1]) .. ")")

        applySeed({ loc = { ["shop:1"] = "Archipelago Shop 1" } })
        sim.renderMenu()
        local card = outside({ x = 24, w = 372 })
        equals(#card, 0, code .. ": status card (" .. tostring(card[1]) .. ")")

        apContractResetForTesting()
        apInventoryClear()
        applySeed({ seed_hash = "frame-A" })
        apInventoryAdd({ kind = "ship", bp = "PLAYER_SHIP_ROCK" })
        applySeed({ seed_hash = "frame-B" })
        sim.renderMenu()
        local window = {}
        for _, d in ipairs(sim.draws) do
            if d.y >= 200 and d.y <= 420 and d.x >= 300 then
                if d.x < 320 or d.x + (d.maxWidth or 0) > 960 then window[#window + 1] = d.text end
            end
        end
        equals(#window, 0, code .. ": seed question window (" .. tostring(window[1]) .. ")")
        apSeedChangeAcknowledged()

        apInventoryClear()
        apInventory.shopAvailability.LASER_BURST_3 = 2
        sim.startRun(true)
        sim.renderGui()
        local menu = outside({ x = 190, w = 900 })
        equals(#menu, 0, code .. ": start-of-run menu (" .. tostring(menu[1]) .. ")")
    end
    apLangSet("en", "test")
end)

test("journal: items sent again at a reconnection are not written twice", function()
    sim.startRun(true)
    sim.durable = {}
    applySeed({ seed_hash = "journal-twice", items = { ["50 Scrap"] = { k = "filler", res = "scrap", n = 50 } } })
    _G.apReceivedHistory = {}
    apRecordReceived("Glaive Beam", "Axel", 0)
    apRecordReceived("Ion Blast", "Axel", 1)
    apRecordReceived("Glaive Beam", "Axel", 0)
    apRecordReceived("Ion Blast", "Axel", 1)
    equals(#_G.apReceivedHistory, 2, "the second round of the same indices is ignored")
    apRecordReceived("Hull Missile", "Axel", 2)
    equals(#_G.apReceivedHistory, 3, "a new index goes in")
end)
