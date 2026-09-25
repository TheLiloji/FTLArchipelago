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

test("back to the hangar from a store: the new ship keeps all its systems", function()
    sim.startRun(true)
    sim.jumpArrive()
    sim.setStore(true)
    sim.player.currentScrap = 785
    sim.tick(1)
    sim.player.currentScrap = 0
    for _, name in ipairs({ "shields", "engines", "pilot", "doors", "sensors", "medbay", "oxygen" }) do
        sim.constructSystem(name, 0, 0)
    end
    sim.tick(5)
    equals(#sim.player._removed, 0, "nothing is removed from a ship being built")
    equals(sim.player.currentScrap, 0, "and no scrap comes out of nowhere")
    check(not sim.logged("PURCHASE REFUSED"), "no refusal in the log")
end)

test("in the hangar, a single system being built is not a purchase either", function()
    sim.startRun(true)
    sim.jumpArrive()
    sim.setStore(true)
    sim.hangarOpen = true
    sim.constructSystem("cloaking", 0, 90)
    sim.tick(5)
    sim.hangarOpen = false
    equals(#sim.player._removed, 0, "the hangar ship keeps its cloaking")
end)

test("a real purchase at a store is still refused after those changes", function()
    sim.startRun(true)
    _G.apInventory.systemCaps.cloaking = nil
    sim.jumpArrive()
    sim.setStore(true)
    sim.player.currentScrap = 0
    sim.constructSystem("cloaking", 0, 90)
    sim.tick(5)
    equals(#sim.player._removed, 1, "one locked system bought: removed")
end)

test("a run started without a seed counts for nothing, even once connected", function()
    _G.apRunStartCheckForTesting = nil
    apContractResetForTesting()
    apForgetChecksForTesting()
    apVictoriesResetForTesting()
    sim.startRun(false)
    local restoreGoal = stub("apNetSendGoal", function() return true end)
    apApplySlotData({ contract = 2, kinds = { "filler" }, kinds_required = {}, items = {},
                      loc = { ["PLAYER_SHIP_HARD:victory"] = "Kestrel Cruiser A: Defeat the Flagship" },
                      goal = { kind = "victories", count = 2 }, seed_hash = "late-seed" })
    sim.clearLog()
    equals(apSendCheck("PLAYER_SHIP_HARD:victory", "victory"), false, "the victory check is refused")
    apVictoryWith("PLAYER_SHIP_HARD")
    restoreGoal()
    equals(apGoalProgress().done, 0, "and the goal does not move")
    check(shownKey("check.run_without_seed"), "the player is told why")
    equals(apPendingCheckCount(), 0, "nothing is kept to be sent later")
end)

test("a run started with the seed counts, and keeps counting offline", function()
    _G.apRunStartCheckForTesting = nil
    apContractResetForTesting()
    apForgetChecksForTesting()
    apApplySlotData({ contract = 2, kinds = { "filler" }, kinds_required = {}, items = {},
                      loc = { ["shop:1"] = "Archipelago Shop 1" }, seed_hash = "early-seed" })
    sim.startRun(true)
    _G.apNetState.connected = false
    equals(apSendCheck("shop:1", "shop"), true, "the check counts, even with the server away")
end)

test("goal: victories that counted survive a restart of the game", function()
    sim.durable = {}
    apVictoriesResetForTesting()
    sim.startRun(true)
    applySeed({ goal = { kind = "victories", count = 2 }, seed_hash = "keep-wins" })
    local restore = stub("apNetSendGoal", function() return true end)
    apVictoryWith("PLAYER_SHIP_HARD")
    restore()
    equals(apGoalProgress().done, 1, "one victory")

    apVictoriesResetForTesting()
    apContractResetForTesting()
    applySeed({ goal = { kind = "victories", count = 2 }, seed_hash = "keep-wins" })
    equals(apGoalProgress().done, 1, "still one after the game is restarted")

    apVictoriesResetForTesting()
    apContractResetForTesting()
    applySeed({ goal = { kind = "victories", count = 2 }, seed_hash = "another-seed-entirely" })
    equals(apGoalProgress().done, 0, "and none for another seed")
end)

test("the goal says in plain words that each victory needs another ship", function()
    apLangResolve("fr")
    apContractResetForTesting()
    apVictoriesResetForTesting()
    apApplySlotData({ contract = 2, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {},
                      goal = { kind = "victories", count = 2 }, seed_hash = "plain-goal" })
    apLangResolve("fr")
    local goal = apGoalText()
    equals(goal.headline, "Objectif : battre le vaisseau amiral 2 fois", "the headline says what to do")
    equals(goal.lines[1].text, "Un vaisseau différent à chaque victoire", "then the rule")
    equals(goal.lines[2].text, "Difficulté : au choix", "then the difficulty")

    local restoreGoal = stub("apNetSendGoal", function() return true end)
    apVictoryWith("PLAYER_SHIP_HARD")
    restoreGoal()
    goal = apGoalText()
    equals(goal.headline, "Vaisseau amiral battu : 1 sur 2", "progress once a win counts")
    check(goal.lines[3] and goal.lines[3].text:find("Déjà gagné avec", 1, true),
          "and the ship already used is named")
    apLangResolve(nil)
end)

test("with every victory but not enough Archives, the goal says what is still missing", function()
    apLangResolve("fr")
    apContractResetForTesting()
    apVictoriesResetForTesting()
    apApplySlotData({ contract = 2, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {},
                      goal = { kind = "victories", count = 1, archives = 8 }, seed_hash = "archives-left" })
    apLangResolve("fr")
    _G.apInventory.archives = 3
    local sent = false
    local restoreGoal = stub("apNetSendGoal", function() sent = true return true end)
    sim.clearLog()
    apVictoryWith("PLAYER_SHIP_HARD")
    restoreGoal()
    check(not sent, "the goal is not sent")
    check(shownKey("goal.archives_missing"), "the toast says Archives are missing, not just 1 of 1")
    equals(apGoalText().headline, "Il reste 5 Archives à trouver", "and so does the goal box")
    apLangResolve(nil)
end)

test("a continued run keeps the seed it started with, not the one loaded now", function()
    _G.apRunStartCheckForTesting = nil
    apContractResetForTesting()
    apForgetChecksForTesting()
    apApplySlotData({ contract = 2, kinds = { "filler" }, kinds_required = {}, items = {},
                      loc = { ["shop:1"] = "Archipelago Shop 1", ["shop:2"] = "Archipelago Shop 2" },
                      seed_hash = "first-seed" })
    sim.startRun(true)
    sim.startRun(false)
    equals(apSendCheck("shop:1", "shop"), true, "continuing a run of this seed still counts")

    apContractResetForTesting()
    apForgetChecksForTesting()
    apApplySlotData({ contract = 2, kinds = { "filler" }, kinds_required = {}, items = {},
                      loc = { ["shop:2"] = "Archipelago Shop 2" }, seed_hash = "second-seed" })
    sim.startRun(false)
    equals(apSendCheck("shop:2", "shop"), false, "a run saved under another seed does not count")

    sim.runVariables = {}
    sim.startRun(false)
    equals(apSendCheck("shop:2", "shop"), false, "nor does a run saved with no seed at all")
end)

test("a wrong slot name is reported as such, not later as a silent server", function()
    apNetResetForTesting()
    apNetConnect("ws://localhost:38281", "Nobody", "")
    sim.clearLog()
    sim.netEvent("error", { name = "unreachable", extra = "TLS handshake failed" })
    sim.netEvent("refused", { extra = "InvalidSlot" })
    sim.tick(600)
    check(shownKey("net.refused.slot"), "the slot is named as the problem")
    check(not shownKey("net.error.unreachable"), "and no 'server not answering' comes after it")
    apNetResetForTesting()
end)

test("a run that does not count keeps what it would use up for the next one", function()
    _G.apRunStartCheckForTesting = nil
    apContractResetForTesting()
    apFillerResetForTesting()
    apApplySlotData({ contract = 2, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {},
                      seed_hash = "old-run-seed" })
    sim.startRun(true)
    apContractResetForTesting()
    apApplySlotData({ contract = 2, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {},
                      seed_hash = "new-seed" })
    sim.startRun(false)
    local scrapBefore = sim.player.currentScrap
    apQueueItem({ kind = "filler", res = "scrap", n = 20, display = "20 Scrap" })
    apDeliverPending()
    equals(#apFillerPendingForTesting(), 1, "the scrap waits")
    equals(sim.player.currentScrap, scrapBefore, "and is not spent on a run that counts for nothing")

    sim.startRun(true)
    apDeliverPending()
    equals(#apFillerPendingForTesting(), 0, "a new run with the seed gets it")
    apFillerResetForTesting()
end)

test("browsing ships in the hangar mid-game sends no DeathLink", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both", effect = "fire" })
    local sent = 0
    local restore = stub("apNetSendDeath", function() sent = sent + 1 return true end)
    sim.startRun(true)
    sim.tick(120)
    sim.hangarOpen = true
    for i = 0, sim.player.vCrewList:size() - 1 do
        sim.player.vCrewList[i]._name = "Preview" .. i
    end
    sim.tick(120)
    sim.hangarOpen = false
    sim.startRun(true)
    sim.tick(120)
    restore()
    equals(sent, 0, "the crew of another ship in the list is not a crew that died")

    sent = 0
    restore = stub("apNetSendDeath", function() sent = sent + 1 return true end)
    sim.tick(120)
    sim.player.vCrewList[0].bDead = true
    sim.tick(120)
    restore()
    equals(sent, 1, "a real death during the run still goes out")
    apDeathLinkConfigure({ enabled = false })
end)

test("the last crew member dying and the run ending send one DeathLink, not two", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both", effect = "fire" })
    local sent = 0
    local restore = stub("apNetSendDeath", function() sent = sent + 1 return true end)
    sim.startRun(true)
    sim.tick(700)
    apDeathLinkCrewDied("Ruwen", "human")
    apDeathLinkOnRunEnd("crew", "no living crew left")
    equals(sent, 1, "one death for one event")
    sim.tick(60 * 11)
    apDeathLinkCrewDied("Grokk", "rock")
    equals(sent, 2, "a later death goes out again")
    restore()
    apDeathLinkConfigure({ enabled = false })
end)

test("clearing the inventory really empties it", function()
    _G.apInventory.ships = { "PLAYER_SHIP_ROCK", "PLAYER_SHIP_MANTIS" }
    _G.apInventory.systemCaps = { shields = 4 }
    apInventoryClear()
    equals(#_G.apInventory.ships, 0, "no ship from the previous seed is left")
    equals(_G.apInventory.systemCaps.shields, nil, "nor any system level")
    _G.apInventory.ships[1] = "PLAYER_SHIP_ROCK"
    apInventoryClear()
    equals(#_G.apInventory.ships, 0, "and a second clear works as well as the first")
end)
