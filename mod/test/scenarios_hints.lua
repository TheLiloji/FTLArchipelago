local function seedWithTwoLocations()
    apContractResetForTesting()
    apForgetChecksForTesting()
    apNetResetForTesting()
    apHintsForgetSeed()
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = slotData({
        seed_hash = "HINTS",
        loc = {
            ["PLAYER_SHIP_HARD:sector:3"] = "Kestrel Cruiser A: Reach sector 3",
            ["PLAYER_SHIP_HARD:sector:4"] = "Kestrel Cruiser A: Reach sector 4",
        },
    }) })
    sim.net.connected = true
    sim.tick(1)
end

local function hintRequests()
    local names = {}
    for _, call in ipairs(sim.net.calls) do
        if call[1] == "HintLocation" then names[#names + 1] = call.name end
    end
    return names
end

test("hints: the slug asks the server for a real hint, on a location not yet visited", function()
    seedWithTwoLocations()
    apCheckAlreadySent("x")
    apSendCheck("PLAYER_SHIP_HARD:sector:3", "Sector 3")
    sim.startRun(true)
    sim.player.currentScrap = 50
    sim.openChoiceBox("AP_EVT_SLUG_WHISPER")
    sim.player.currentScrap = 30
    sim.clearLog()

    playBranch("AP_EVT_SLUG_WHISPER_A")

    local names = hintRequests()
    equals(#names, 1, "only one request goes out")
    equals(names[1], "Kestrel Cruiser A: Reach sector 4", "for the only location left to visit")
    equals(sim.player.currentScrap, 30, "the service is rendered, the 20 stay paid")
    check(shownKey("event.hint.asked"), "the player knows the answer is coming")
end)

test("hints: with no server the slug returns the scrap instead of selling hot air", function()
    apContractResetForTesting()
    apNetResetForTesting()
    apHintsForgetSeed()
    sim.startRun(true)
    sim.player.currentScrap = 50
    sim.openChoiceBox("AP_EVT_SLUG_WHISPER")
    sim.player.currentScrap = 30
    sim.clearLog()

    playBranch("AP_EVT_SLUG_WHISPER_A")

    equals(#hintRequests(), 0, "nothing goes out")
    equals(sim.player.currentScrap, 50, "the 20 are returned")
    check(shownKey("event.hint.nothing", { scrap = 20 }), "and the player knows why")
end)

test("hints: a hint arriving from the server shows once and stays on the dashboard", function()
    seedWithTwoLocations()
    sim.clearLog()
    sim.netEvent("hint", { name = "Burst Laser II", sender = "Navigator", other = "Nina",
                           extra = "Nina's Temple", value = 0, index = 0 })
    sim.tick(1)
    local text = apT("hint.received.mine", { item = "Burst Laser II", finder = "Nina",
                                              location = "Nina's Temple" })
    check(sim.shown(text), "the player sees where their item is waiting")

    sim.clearLog()
    sim.netEvent("hint", { name = "Burst Laser II", sender = "Navigator", other = "Nina",
                           extra = "Nina's Temple", value = 0, index = 0 })
    sim.tick(1)
    check(not sim.shown(text), "the same hint does not repeat")

    sim.startRun(true)
    apToggleHud()
    sim.renderGui()
    apToggleHud()
    check(sim.drawnText(apT("hud.hints")), "the dashboard has its section")
    check(sim.drawnText("Burst Laser II"), "and the hint is in it")
end)

test("hints: ones already known at connection make no noise", function()
    seedWithTwoLocations()
    sim.clearLog()
    sim.netEvent("hint", { name = "Rock Cruiser Key", sender = "Navigator", other = "Axel",
                           extra = "Axel's Cave", value = 0, index = 1 })
    sim.tick(1)
    check(not sim.shown("Rock Cruiser Key"), "no notification for an already known hint")
    equals(#apHintsForDisplay(5), 1, "but it is kept")
end)

test("hints: an already found hint does not stay displayed", function()
    seedWithTwoLocations()
    sim.netEvent("hint", { name = "Scrap", sender = "Navigator", other = "Axel",
                           extra = "Axel's Cave", value = 1, index = 1 })
    sim.tick(1)
    equals(#apHintsForDisplay(5), 0, "the item already arrived: nothing to look for")
end)

test("hints: the answer to a hint scout does not fall into the shop", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    apNetResetForTesting()
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = slotData({
        seed_hash = "HINTS",
        loc = {
            ["shop:1"] = "Archipelago Shop 1",
            ["PLAYER_SHIP_HARD:sector:4"] = "Kestrel Cruiser A: Reach sector 4",
        },
        shop = { mode = "rarity_boost", deliver = false, baseline = {}, slots = 1 },
    }) })
    sim.net.connected = true
    sim.tick(1)

    sim.netEvent("scout", { name = "Archipelago Shop 1", sender = "Axel",
                            extra = "20 Scrap", value = 0 })
    sim.netEvent("scout", { name = "Kestrel Cruiser A: Reach sector 4", sender = "Nina",
                            extra = "Burst Laser II", value = 1 })
    sim.tick(1)

    local locations = {}
    for _, package in ipairs(_G.apShopGifts or {}) do locations[#locations + 1] = tostring(package.location) end
    equals(#locations, 1, "a single package: " .. table.concat(locations, ", "))
    equals(locations[1], "shop:1", "the shop's one, not the location we wanted a hint for")
end)
