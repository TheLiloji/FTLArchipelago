-- FTL unlocks ships by itself (an event, an achievement, an old profile) and nothing can lock them again.
-- A run only counts with a ship Archipelago gave: these scenarios go through the real network path, with the
-- check turned on, the way a player meets it.

local SHIP_ITEMS = {
    ["Kestrel Cruiser Key"] = { k = "ship", bp = "PLAYER_SHIP_HARD" },
    ["Rock Cruiser Key"] = { k = "ship", bp = "PLAYER_SHIP_ROCK" },
    ["Engi Cruiser Key"] = { k = "ship", bp = "PLAYER_SHIP_CIRCLE" },
    ["Mantis Cruiser Key"] = { k = "ship", bp = "PLAYER_SHIP_MANTIS" },
    ["Layout B - Engi Cruiser"] = { k = "ship", bp = "PLAYER_SHIP_CIRCLE_2" },
    ["Layout C - Mantis Cruiser"] = { k = "ship", bp = "PLAYER_SHIP_MANTIS_3" },
    ["20 Scrap"] = { k = "filler", res = "scrap", n = 20 },
}

local SHIP_LAYOUTS = {
    "PLAYER_SHIP_HARD", "PLAYER_SHIP_ROCK", "PLAYER_SHIP_CIRCLE", "PLAYER_SHIP_CIRCLE_2",
    "PLAYER_SHIP_MANTIS", "PLAYER_SHIP_MANTIS_3",
}

local function shipSeed(overrides)
    local loc = {}
    for _, layout in ipairs(SHIP_LAYOUTS) do
        for sector = 2, 3 do
            loc[layout .. ":sector:" .. sector] = layout .. ": Reach sector " .. sector
        end
        loc[layout .. ":victory"] = layout .. ": Defeat the Flagship"
    end
    loc["shop:1"] = "Archipelago Shop 1"
    local seed = {
        contract = 2, kinds = { "ship", "filler" }, kinds_required = { "ship" },
        items = SHIP_ITEMS, loc = loc, layouts = SHIP_LAYOUTS,
        start_ship = "PLAYER_SHIP_ROCK", seed_hash = "SHIPS",
        goal = { kind = "victories", count = 3 },
    }
    for key, value in pairs(overrides or {}) do
        seed[key] = value
    end
    return seed
end

-- Connected, every item in (names known), the queue emptied into the inventory: a normal session.
local function shipConnect(received, overrides)
    apNetResetForTesting()
    apContractResetForTesting()
    apForgetChecksForTesting()
    apVictoriesResetForTesting()
    apInventoryClear()
    _G.apShipCheckForTesting = nil
    _G.apRunStartCheckForTesting = nil
    sim.menuOpen = false
    sim.net.calls = {}
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = shipSeed(overrides) })
    for index, name in ipairs(received) do
        sim.netEvent("item", { name = name, sender = "Nina", index = index - 1 })
    end
    sim.net.connected = true
    sim.tick(1)
    sim.tick(120)
end

local function startRunWith(layout)
    sim.player.myBlueprint.blueprintName = layout
    sim.startRun(true)
end

local function reachSector(sector)
    sim.starMap.worldLevel = sector - 1
    sim.jumpArrive()
end

local function sentChecks()
    local names = {}
    for _, call in ipairs(sim.net.calls) do
        if call[1] == "SendCheck" then names[#names + 1] = call.name end
    end
    return table.concat(names, ",")
end

local function shipDone()
    sim.player.myBlueprint.blueprintName = "PLAYER_SHIP_HARD"
    sim.starMap.worldLevel = 0
    sim.menuOpen = nil
    _G.apShipCheckForTesting = false
    _G.apRunStartCheckForTesting = false
    apNetResetForTesting()
    apContractResetForTesting()
end

test("ships: the Engi FTL unlocked on its own sends nothing (Astron's run)", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key", "Layout C - Mantis Cruiser" })
    sim.unlocked["PLAYER_SHIP_CIRCLE"] = true
    sim.clearLog()
    startRunWith("PLAYER_SHIP_CIRCLE")
    sim.tick(1)
    check(shownKey("check.run_ship_not_received", { ship = apShipLabel("PLAYER_SHIP_CIRCLE") }),
        "the player is told as the run starts, before any check")
    local warned = false
    for _, toast in ipairs(apToastsForTesting()) do
        warned = warned or (toast.kept and toast.tone == "warn")
    end
    check(warned, "as a warning that stays on screen")
    for sector = 2, 3 do reachSector(sector) end
    equals(sentChecks(), "", "no sector check leaves")
    local restoreGoal = stub("apNetSendGoal", function() return true end)
    apOnRunEnd("victory")
    restoreGoal()
    equals(sentChecks(), "", "nor the victory")
    equals(apGoalProgress().done, 0, "and the goal does not move")
    equals(apHeldCheckCount(), 0, "nothing waits to be sent later either")
    equals(sim.runVariables.ap_run_ship_refused, 1, "the refusal is written in the run's save")
    shipDone()
end)

test("ships: a received ship counts", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key", "Engi Cruiser Key" })
    startRunWith("PLAYER_SHIP_CIRCLE")
    reachSector(2)
    equals(sentChecks(), "PLAYER_SHIP_CIRCLE: Reach sector 2", "the Engi's sector check leaves")
    check(not shownKey("check.run_ship_not_received", { ship = apShipLabel("PLAYER_SHIP_CIRCLE") }),
        "and no warning")
    shipDone()
end)

test("ships: a ship already judged fine stays fine while a key received waits in the queue", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    startRunWith("PLAYER_SHIP_ROCK")
    reachSector(2)
    equals(sentChecks(), "PLAYER_SHIP_ROCK: Reach sector 2", "judged fine")
    local restore = stub("apFillerShipsWaiting", function() return true end)
    reachSector(3)
    restore()
    equals(sentChecks(), "PLAYER_SHIP_ROCK: Reach sector 2,PLAYER_SHIP_ROCK: Reach sector 3",
        "a layout bought a moment ago does not hold the next check (Tom's lost Shield Upgrade)")
    shipDone()
end)

test("ships: the start ship and the Kestrel A count even without their item (solo)", function()
    shipConnect({ "20 Scrap" })
    startRunWith("PLAYER_SHIP_ROCK")
    reachSector(2)
    equals(sentChecks(), "PLAYER_SHIP_ROCK: Reach sector 2", "the start ship")
    startRunWith("PLAYER_SHIP_HARD")
    reachSector(3)
    equals(sentChecks(), "PLAYER_SHIP_ROCK: Reach sector 2,PLAYER_SHIP_HARD: Reach sector 3", "the Kestrel A")
    shipDone()
end)

test("ships: a Type B needs its own item when the seed has layout items", function()
    shipConnect({ "Kestrel Cruiser Key", "Engi Cruiser Key" })
    startRunWith("PLAYER_SHIP_CIRCLE_2")
    reachSector(2)
    equals(sentChecks(), "", "the key alone does not make the Engi B playable")
    shipConnect({ "Kestrel Cruiser Key", "Engi Cruiser Key", "Layout B - Engi Cruiser" })
    startRunWith("PLAYER_SHIP_CIRCLE_2")
    reachSector(2)
    equals(sentChecks(), "PLAYER_SHIP_CIRCLE_2: Reach sector 2", "with its item it counts")
    shipDone()
end)

test("ships: independent layouts, a Type B counts without its ship's key, and the key alone gives only the A", function()
    local independent = {}
    for name, descriptor in pairs(SHIP_ITEMS) do independent[name] = descriptor end
    independent["Layout B - Engi Cruiser"] = { k = "layout", bp = "PLAYER_SHIP_CIRCLE_2" }
    local seed = { items = independent, kinds = { "ship", "filler", "layout" }, kinds_required = { "ship", "layout" } }
    shipConnect({ "Kestrel Cruiser Key", "Layout B - Engi Cruiser" }, seed)
    check(sim.unlocked["PLAYER_SHIP_CIRCLE_2"], "the Engi B is unlocked in the hangar without the Engi key")
    check(not sim.unlocked["PLAYER_SHIP_CIRCLE"], "and the Engi A is not")
    startRunWith("PLAYER_SHIP_CIRCLE_2")
    reachSector(2)
    equals(sentChecks(), "PLAYER_SHIP_CIRCLE_2: Reach sector 2", "a run with the Engi B counts")
    startRunWith("PLAYER_SHIP_CIRCLE")
    reachSector(3)
    equals(sentChecks(), "PLAYER_SHIP_CIRCLE_2: Reach sector 2", "a run with the Engi A does not")
    shipDone()
end)

test("ships: a progressive ship key gives the A with its first copy, the B with its second", function()
    local progressive = {}
    for name, descriptor in pairs(SHIP_ITEMS) do progressive[name] = descriptor end
    progressive["Engi Cruiser Key"] = { k = "progressive_ship", bp = "PLAYER_SHIP_CIRCLE",
                                        bps = { "PLAYER_SHIP_CIRCLE", "PLAYER_SHIP_CIRCLE_2" } }
    progressive["Layout B - Engi Cruiser"] = nil
    local seed = { items = progressive, kinds = { "ship", "filler", "progressive_ship" },
                   kinds_required = { "ship", "progressive_ship" } }
    shipConnect({ "Kestrel Cruiser Key", "Engi Cruiser Key" }, seed)
    check(sim.unlocked["PLAYER_SHIP_CIRCLE"], "one copy unlocks the Engi A")
    check(not sim.unlocked["PLAYER_SHIP_CIRCLE_2"], "but not the B")
    startRunWith("PLAYER_SHIP_CIRCLE_2")
    reachSector(2)
    equals(sentChecks(), "", "a run with the B does not count yet")
    shipConnect({ "Kestrel Cruiser Key", "Engi Cruiser Key", "Engi Cruiser Key" }, seed)
    check(sim.unlocked["PLAYER_SHIP_CIRCLE_2"], "the second copy unlocks the B")
    startRunWith("PLAYER_SHIP_CIRCLE_2")
    reachSector(2)
    equals(sentChecks(), "PLAYER_SHIP_CIRCLE_2: Reach sector 2", "and a run with it counts")
    shipDone()
end)

test("ships: a Type C without its ship's key is refused, and waits in the hangar for the key", function()
    shipConnect({ "Kestrel Cruiser Key", "Layout C - Mantis Cruiser" })
    check(not sim.unlocked["PLAYER_SHIP_MANTIS_3"], "the Mantis C is not unlocked without the Mantis key")
    startRunWith("PLAYER_SHIP_MANTIS_3")
    reachSector(2)
    equals(sentChecks(), "", "a run with it counts for nothing")
    sim.netEvent("item", { name = "Mantis Cruiser Key", sender = "Nina", index = 2 })
    sim.tick(1)
    sim.tick(120)
    check(sim.unlocked["PLAYER_SHIP_MANTIS_3"], "the key unlocks it along with the Mantis A")
    shipDone()
end)

test("ships: with vanilla layout unlocks, the ship's key is enough for its Type B", function()
    local vanilla = {}
    for name, descriptor in pairs(SHIP_ITEMS) do
        if not tostring(descriptor.bp):match("_[23]$") then vanilla[name] = descriptor end
    end
    shipConnect({ "Kestrel Cruiser Key", "Engi Cruiser Key" }, { items = vanilla })
    startRunWith("PLAYER_SHIP_CIRCLE_2")
    reachSector(2)
    equals(sentChecks(), "PLAYER_SHIP_CIRCLE_2: Reach sector 2", "FTL's own unlock of the Engi B counts")
    shipConnect({ "Kestrel Cruiser Key" }, { items = vanilla })
    startRunWith("PLAYER_SHIP_CIRCLE_2")
    reachSector(2)
    equals(sentChecks(), "", "but not without the Engi key")
    shipDone()
end)

test("ships: a layout the seed leaves out is refused and the player reads why", function()
    shipConnect({ "Kestrel Cruiser Key", "Engi Cruiser Key" },
        { layouts = { "PLAYER_SHIP_HARD", "PLAYER_SHIP_ROCK", "PLAYER_SHIP_CIRCLE" } })
    sim.clearLog()
    startRunWith("PLAYER_SHIP_CIRCLE_2")
    reachSector(2)
    equals(sentChecks(), "", "nothing leaves")
    check(shownKey("check.run_ship_not_in_seed", { ship = apShipLabel("PLAYER_SHIP_CIRCLE_2") }),
        "the player reads that the ship is not in the seed")
    equals(sim.runVariables.ap_run_ship_refused, 2, "kept in the run's save")
    shipDone()
end)

test("ships: a refused run stays refused once the key comes in, and after a restart", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    startRunWith("PLAYER_SHIP_CIRCLE")
    reachSector(2)
    sim.netEvent("item", { name = "Engi Cruiser Key", sender = "Nina", index = 2 })
    sim.tick(1)
    sim.tick(120)
    check(sim.unlocked["PLAYER_SHIP_CIRCLE"], "the key is applied")
    reachSector(3)
    equals(sentChecks(), "", "the run that started without it still counts for nothing")
    sim.startRun(false)
    sim.tick(1)
    reachSector(3)
    equals(sentChecks(), "", "nor once continued after a restart")
    startRunWith("PLAYER_SHIP_CIRCLE")
    reachSector(2)
    equals(sentChecks(), "PLAYER_SHIP_CIRCLE: Reach sector 2", "a new run with the Engi counts")
    shipDone()
end)

test("ships: a run continued from an older version is judged too", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    sim.player.myBlueprint.blueprintName = "PLAYER_SHIP_CIRCLE"
    sim.runVariables = { ap_run_seed = apSeedFingerprint() }
    sim.startRun(false)
    sim.tick(1)
    reachSector(4)
    equals(sentChecks(), "", "no ship verdict in the save: it is decided now, and refused")
    equals(sim.runVariables.ap_run_ship_refused, 1, "and written down")
    shipDone()
end)

test("ships: a key still in the queue is not a missing ship", function()
    apNetResetForTesting()
    apContractResetForTesting()
    apForgetChecksForTesting()
    apInventoryClear()
    _G.apShipCheckForTesting = nil
    _G.apRunStartCheckForTesting = nil
    sim.menuOpen = false
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = shipSeed() })
    sim.netEvent("item", { name = "Kestrel Cruiser Key", sender = "Nina", index = 0 })
    sim.netEvent("item", { name = "Engi Cruiser Key", sender = "Nina", index = 1 })
    sim.net.connected = true
    sim.tick(1)
    check(apFillerShipsWaiting(), "the Engi key is received but still queued")
    startRunWith("PLAYER_SHIP_CIRCLE")
    sim.clearLog()
    -- A jump empties the queue first: a check made between two jumps, like a victory, meets it full.
    apSendCheck("PLAYER_SHIP_CIRCLE:sector:2", "Sector 2")
    equals(sentChecks(), "", "the check waits instead of going out or being refused")
    equals(apHeldCheckCount(), 1, "it is held")
    check(not shownKey("check.run_ship_not_received", { ship = apShipLabel("PLAYER_SHIP_CIRCLE") }),
        "no false warning")
    sim.tick(120)
    equals(sentChecks(), "PLAYER_SHIP_CIRCLE: Reach sector 2", "once the key is in, the held check leaves")
    equals(apHeldCheckCount(), 0, "nothing left held")
    equals(sim.runVariables.ap_run_ship_refused, 0, "the run was never refused")
    shipDone()
end)

test("ships: items named before the data package are not an empty inventory", function()
    apNetResetForTesting()
    apContractResetForTesting()
    apForgetChecksForTesting()
    apInventoryClear()
    _G.apShipCheckForTesting = nil
    _G.apRunStartCheckForTesting = nil
    sim.menuOpen = false
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = shipSeed() })
    sim.netEvent("item", { name = "Unknown", sender = "Nina", index = 0 })
    sim.netEvent("item", { name = "Unknown", sender = "Nina", index = 1 })
    sim.net.connected = true
    sim.tick(1)
    sim.tick(240)
    check(not apInventorySynced(), "names missing: the inventory is not complete")
    startRunWith("PLAYER_SHIP_CIRCLE")
    sim.clearLog()
    reachSector(2)
    local restoreGoal = stub("apNetSendGoal", function() return true end)
    apVictoryWith("PLAYER_SHIP_CIRCLE")
    sim.tick(240)
    equals(sentChecks(), "", "nothing decided yet")
    equals(apHeldCheckCount(), 2, "the sector check and the victory are held")
    check(not shownKey("check.run_ship_not_received", { ship = apShipLabel("PLAYER_SHIP_CIRCLE") }),
        "no false warning")
    sim.netEvent("item", { name = "Kestrel Cruiser Key", sender = "Nina", index = 0 })
    sim.netEvent("item", { name = "Engi Cruiser Key", sender = "Nina", index = 1 })
    sim.tick(1)
    sim.tick(120)
    restoreGoal()
    equals(sentChecks(), "PLAYER_SHIP_CIRCLE: Reach sector 2", "the server sent them again with names: it leaves")
    equals(apGoalProgress().done, 1, "and the held victory counts")
    shipDone()
end)

test("ships: a held check is refused, not sent, once the inventory shows the ship missing", function()
    apNetResetForTesting()
    apContractResetForTesting()
    apForgetChecksForTesting()
    apInventoryClear()
    _G.apShipCheckForTesting = nil
    _G.apRunStartCheckForTesting = nil
    sim.menuOpen = false
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = shipSeed() })
    sim.netEvent("item", { name = "Unknown", sender = "Nina", index = 0 })
    sim.net.connected = true
    sim.tick(1)
    startRunWith("PLAYER_SHIP_CIRCLE")
    reachSector(2)
    equals(apHeldCheckCount(), 1, "held while unsure")
    sim.clearLog()
    sim.netEvent("item", { name = "Kestrel Cruiser Key", sender = "Nina", index = 0 })
    sim.tick(1)
    sim.tick(120)
    equals(sentChecks(), "", "the Engi was never received: the held check is dropped")
    equals(apHeldCheckCount(), 0, "not kept")
    check(shownKey("check.run_ship_not_received", { ship = apShipLabel("PLAYER_SHIP_CIRCLE") }),
        "and the player is told")
    shipDone()
end)

test("ships: browsing the hangar judges nothing", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    sim.runVariables = {}
    sim.started = true
    sim.hangarOpen = true
    sim.player.myBlueprint.blueprintName = "PLAYER_SHIP_CIRCLE"
    sim.clearLog()
    sim.tick(200)
    check(not shownKey("check.run_ship_not_received", { ship = apShipLabel("PLAYER_SHIP_CIRCLE") }),
        "no warning for a ship only looked at")
    check(apRunMatchesSeed(), "items are not held back by a ship only looked at")
    equals((sim.runVariables or {}).ap_run_ship_refused or 0, 0, "nothing written")
    sim.hangarOpen = false
    startRunWith("PLAYER_SHIP_ROCK")
    reachSector(2)
    equals(sentChecks(), "PLAYER_SHIP_ROCK: Reach sector 2", "the ship actually picked counts")
    shipDone()
end)

test("ships: back at the main menu, the last refused run holds nothing back", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    startRunWith("PLAYER_SHIP_CIRCLE")
    sim.tick(1)
    check(not apRunMatchesSeed(), "in the run, items wait")
    sim.menuOpen = true
    check(apRunMatchesSeed(), "at the menu, the old run's ship no longer matters")
    shipDone()
end)

test("ships: a package bought in a refused run is refunded and stays on sale", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    startRunWith("PLAYER_SHIP_CIRCLE")
    sim.tick(1)
    equals(apRunRefusal(), "not_received", "the run is refused")
    apShopGiftsConfigure({ { slot = "Nina", item = "Seashell", location = "shop:1", kind = "filler", cost = 40 } })
    sim.player.currentScrap = 0
    sim.clearLog()
    sim.buy("AP_GIFT_1")
    sim.tick(60)
    equals(sentChecks(), "", "nothing leaves")
    equals(apHeldCheckCount(), 0, "a package is never held: it would be sold twice")
    check(shownKey("shop.gift.not_counted", { price = "40" }), "the player reads why")
    equals(sim.rarityFor("AP_GIFT_1", 0).shortTitle.data, "Nina", "the package is still on the shelf")
    shipDone()
end)

test("ships: the hangar list marks the playable ships Archipelago did not give", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    sim.started = false
    sim.unlocked["PLAYER_SHIP_CIRCLE"] = true
    sim.unlocked["PLAYER_SHIP_ROCK"] = true
    local label = apT("hangar.not_received")
    local function marked(left, top)
        for _, draw in ipairs(sim.draws) do
            if draw.text == label and draw.x >= left and draw.x < left + 205 and draw.y >= top and draw.y < top + 177 then
                return true
            end
        end
        return false
    end
    sim.shipList = { open = true, page = 0, variant = 0 }
    sim.renderMenu()
    check(marked(341, 161), "the Engi, unlocked by FTL, is marked")
    check(not marked(341, 338), "not the Rock, which was received")
    check(not marked(546, 161), "nor the Federation, still locked")
    check(not marked(136, 161), "nor the Kestrel")
    sim.shipList = { open = false, page = 0, variant = 0 }
    shipDone()
end)

test("ships: a package bought before the inventory is complete is refunded and stays on sale", function()
    apNetResetForTesting()
    apContractResetForTesting()
    apForgetChecksForTesting()
    apInventoryClear()
    _G.apShipCheckForTesting = nil
    _G.apRunStartCheckForTesting = nil
    sim.menuOpen = false
    sim.net.calls = {}
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = shipSeed() })
    sim.netEvent("item", { name = "Unknown", sender = "Nina", index = 0 })
    sim.net.connected = true
    sim.tick(1)
    startRunWith("PLAYER_SHIP_ROCK")
    equals(apRunRefusal(), "unknown", "not decided yet")
    apShopGiftsConfigure({ { slot = "Nina", item = "Seashell", location = "shop:1", kind = "filler", cost = 40 } })
    sim.player.currentScrap = 0
    sim.clearLog()
    sim.buy("AP_GIFT_1")
    sim.tick(60)
    equals(sentChecks(), "", "nothing leaves yet")
    check(not shownKey("shop.gift.already_sent", { price = "40" }), "the package is not taken for already sent")
    equals(sim.rarityFor("AP_GIFT_1", 0).shortTitle.data, "Nina", "it is still on the shelf, to buy again")
    shipDone()
end)

test("ships: solo counts its start ship and refuses one FTL unlocked on its own", function()
    _G.apShipCheckForTesting = nil
    _G.apRunStartCheckForTesting = nil
    sim.menuOpen = false
    check(apSoloStart(true), "solo mode starts")
    startRunWith("PLAYER_SHIP_HARD")
    equals(apRunRefusal(), nil, "the solo start ship counts, though solo hands out no starting item")
    check(apSendCheck("PLAYER_SHIP_HARD:sector:5", "a sector"), "its check goes through")
    startRunWith("PLAYER_SHIP_CIRCLE")
    sim.tick(1)
    equals(apRunRefusal(), "not_received", "an Engi with no key in solo does not")
    apSoloStop()
    shipDone()
end)


local function atMenu()
    sim.started = false
    sim.menuOpen = true
    sim.hangarOpen = false
end

local function shownRelocked(n)
    return shownKey("unlock.relocked", { n = n })
end

test("lock: an event unlocking a ship Archipelago did not give is refused", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    sim.clearLog()
    Hyperspace.CustomShipUnlocks.instance:UnlockShip("PLAYER_SHIP_CIRCLE", false, true, true)
    sim.tick(1)
    check(not sim.unlocked["PLAYER_SHIP_CIRCLE"], "the Engi stays locked")
    check(sim.logged("FTL tried to unlock PLAYER_SHIP_CIRCLE (not_received): refused"), "and the log says why")
    shipDone()
end)

test("lock: received ships still unlock, silently when the inventory is applied again", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key", "Engi Cruiser Key" })
    check(sim.unlocked["PLAYER_SHIP_CIRCLE"], "the Engi key unlocks the Engi through the lock")
    local silent = nil
    for _, call in ipairs(sim.net.calls) do
        if call[1] == "UnlockShip" and call.name == "PLAYER_SHIP_CIRCLE" then silent = call.silent end
    end
    equals(silent, true, "without a popup")
    shipDone()
end)

test("lock: with vanilla layout unlocks, a Type B FTL earns for a received ship goes through", function()
    local vanilla = {}
    for name, descriptor in pairs(SHIP_ITEMS) do
        if not tostring(descriptor.bp):match("_[23]$") then vanilla[name] = descriptor end
    end
    shipConnect({ "Kestrel Cruiser Key", "Engi Cruiser Key" }, { items = vanilla })
    Hyperspace.CustomShipUnlocks.instance:UnlockShip("PLAYER_SHIP_CIRCLE_2", false, true, false)
    sim.tick(1)
    check(sim.unlocked["PLAYER_SHIP_CIRCLE_2"], "the Engi B earned by its achievements is unlocked")
    shipDone()
end)

test("lock: a Type B FTL earns before its ship's key waits for the key", function()
    local vanilla = {}
    for name, descriptor in pairs(SHIP_ITEMS) do
        if not tostring(descriptor.bp):match("_[23]$") then vanilla[name] = descriptor end
    end
    shipConnect({ "Kestrel Cruiser Key" }, { items = vanilla })
    Hyperspace.CustomShipUnlocks.instance:UnlockShip("PLAYER_SHIP_CIRCLE_2", false, true, false)
    sim.tick(1)
    check(not sim.unlocked["PLAYER_SHIP_CIRCLE_2"], "no Engi key: the Engi B stays locked")
    sim.netEvent("item", { name = "Engi Cruiser Key", sender = "Nina", index = 1 })
    sim.tick(1)
    sim.tick(120)
    check(sim.unlocked["PLAYER_SHIP_CIRCLE"], "the key unlocks the Engi")
    check(sim.unlocked["PLAYER_SHIP_CIRCLE_2"], "and the Engi B earned earlier along with it")
    shipDone()
end)

test("lock: at the main menu, ships FTL unlocked on its own are locked again", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    -- An older profile: FTL unlocked these before the lock existed.
    sim.unlocked["PLAYER_SHIP_CIRCLE"] = true
    sim.unlocked["PLAYER_SHIP_MANTIS_3"] = true
    sim.unlocked["PLAYER_SHIP_HARD"] = true
    atMenu()
    sim.clearLog()
    sim.tick(240)
    check(not sim.unlocked["PLAYER_SHIP_CIRCLE"], "the Engi is locked again")
    check(not sim.unlocked["PLAYER_SHIP_MANTIS_3"], "so is the Mantis C, which has no Mantis key")
    check(sim.unlocked["PLAYER_SHIP_ROCK"], "the received Rock stays")
    check(sim.unlocked["PLAYER_SHIP_HARD"], "and the Kestrel A")
    check(shownRelocked(2), "the player reads that two ships were locked again")
    sim.clearLog()
    sim.tick(240)
    check(not shownRelocked(2), "said once, not every few seconds")
    shipDone()
end)

test("lock: nothing is locked again during a run, in the hangar, or before the inventory is complete", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    sim.unlocked["PLAYER_SHIP_CIRCLE"] = true
    startRunWith("PLAYER_SHIP_CIRCLE")
    sim.menuOpen = false
    sim.tick(240)
    check(sim.unlocked["PLAYER_SHIP_CIRCLE"], "not in the middle of a run")
    sim.started = true
    sim.menuOpen = true
    sim.hangarOpen = true
    sim.tick(240)
    check(sim.unlocked["PLAYER_SHIP_CIRCLE"], "not while the hangar is open")
    apInventoryClear()
    atMenu()
    sim.tick(240)
    check(sim.unlocked["PLAYER_SHIP_CIRCLE"], "not with an inventory that is not complete")
    shipDone()
end)

test("lock: an older module without the lock still unlocks ships and locks nothing", function()
    sim.net.client.SetShipLock = nil
    sim.net.client.UnlockShip = nil
    sim.net.client.LockShips = nil
    sim.net.shipLock = false
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    check(sim.unlocked["PLAYER_SHIP_ROCK"], "the Rock key still unlocks the Rock")
    sim.unlocked["PLAYER_SHIP_CIRCLE"] = true
    atMenu()
    sim.tick(240)
    check(sim.unlocked["PLAYER_SHIP_CIRCLE"], "nothing to lock with: left as it is, the run check still guards")
    shipDone()
end)

test("achievements: FTL's own are read from FTL's tracker, not Hyperspace's", function()
    sim.startRun(true)
    applySeed({ loc = { ["ach:ACH_TOUGH_SHIP"] = "Achievement: Tough Little Ship" } })
    sim.clearLog()
    sim.earnAchievement("ACH_TOUGH_SHIP", 1)
    equals(Hyperspace.CustomAchievementTracker.instance:GetAchievementStatus("ACH_TOUGH_SHIP"), -1,
        "Hyperspace's tracker does not hold it, like in the game")
    sim.jumpArrive()
    check(sim.logged("CHECK ach:ACH_TOUGH_SHIP"), "the check goes out all the same")
end)

test("achievements: the ones a mod adds are still read from Hyperspace's tracker", function()
    sim.startRun(true)
    applySeed({ loc = { ["ach:ACH_TOUGH_SHIP"] = "Achievement: Tough Little Ship" } })
    sim.clearLog()
    sim.earnCustomAchievement("ACH_TOUGH_SHIP", 0)
    sim.jumpArrive()
    check(sim.logged("CHECK ach:ACH_TOUGH_SHIP"), "a custom achievement counts")
end)

test("achievements: an older module that cannot read FTL's says so once and keeps the custom ones", function()
    sim.net.client.AchievementStatus = nil
    sim.startRun(true)
    applySeed({ loc = { ["ach:ACH_TOUGH_SHIP"] = "Achievement: Tough Little Ship" } })
    sim.earnAchievement("ACH_TOUGH_SHIP", 1)
    sim.jumpArrive()
    check(not sim.logged("CHECK ach:ACH_TOUGH_SHIP"), "FTL's achievement cannot be seen")
    sim.earnCustomAchievement("ACH_TOUGH_SHIP", 1)
    sim.jumpArrive()
    check(sim.logged("CHECK ach:ACH_TOUGH_SHIP"), "a custom one still can")
end)

test("checks: a sector check says what it sends, and to whom", function()
    shipConnect({ "Kestrel Cruiser Key", "Rock Cruiser Key" })
    sim.netEvent("scout", { name = "PLAYER_SHIP_ROCK: Reach sector 2", sender = "Nina",
                            extra = "Hookshot", value = 1 })
    sim.netEvent("scout", { name = "PLAYER_SHIP_ROCK: Reach sector 3", sender = "Navigator",
                            extra = "Burst Laser II", value = 1 })
    sim.tick(1)
    startRunWith("PLAYER_SHIP_ROCK")
    apNotifyResetForTesting()
    sim.clearLog()
    reachSector(2)
    apNotifyFlushForTesting()
    check(shownKey("check.sent.item", { location = "PLAYER_SHIP_ROCK: Reach sector 2", item = "Hookshot",
                                        slot = "Nina" }), "the item and its player")
    sim.clearLog()
    reachSector(3)
    apNotifyFlushForTesting()
    check(shownKey("check.sent.item.self", { location = "PLAYER_SHIP_ROCK: Reach sector 3",
                                             item = "Burst Laser II" }), "an item of our own says so")
    shipDone()
end)

test("checks: every check of the seed is scouted, without a hint", function()
    shipConnect({ "Kestrel Cruiser Key" })
    local scouted = 0
    for _, call in ipairs(sim.net.calls) do
        if call[1] == "ScoutLocations" then scouted = math.max(scouted, call.count) end
    end
    local total = 0
    for _ in pairs(_G.apContractState.locNames) do total = total + 1 end
    equals(scouted, total, "the shop slots and every other check")
    equals(sim.netCalls("HintLocation"), 0, "a scout is not a hint")
    shipDone()
end)

test("ships: Multiverse's Kestrel counts without its item and is never locked again", function()
    local layouts = { "PLAYER_SHIP_MVKESTREL", "PLAYER_SHIP_ROCK" }
    local loc = { ["PLAYER_SHIP_MVKESTREL:sector:2"] = "MV Kestrel: Reach sector 2" }
    shipConnect({ "Rock Cruiser Key" }, { layouts = layouts, loc = loc, multiverse = true })
    sim.unlocked["PLAYER_SHIP_MVKESTREL"] = true
    startRunWith("PLAYER_SHIP_MVKESTREL")
    reachSector(2)
    equals(sentChecks(), "MV Kestrel: Reach sector 2", "the Multiverse Kestrel counts, like the Kestrel A")
    sim.started = false
    sim.menuOpen = true
    sim.tick(240)
    check(sim.unlocked["PLAYER_SHIP_MVKESTREL"], "and stays unlocked at the menu")
    shipDone()
end)

test("dashboard: a Multiverse achievement shows the icon Hyperspace gives it", function()
    equals(apGameData.achievementImages.ACH_ACC_DATABASE, "achievements/ach_acc_database.png", "named like its icon")
    equals(apGameData.achievementImages.ACH_ACC_DETERGENT, "achievements/ach_detergent.png",
        "even when the icon's name differs from the achievement's")
    equals(apGameData.achievementImages.ACH_SECTOR_5, "achievements/0.png", "the base game's stay as they were")
end)

test("start-of-run menu: a Multiverse weapon has its art too", function()
    local art = apGameData.weaponArt.BEAM_4
    check(art ~= nil and tostring(art[1]):match("%.png$") ~= nil, "BEAM_4: its sheet comes from Multiverse's animations")
    check(art ~= nil and art[4] > 0 and art[5] > 0, "with a frame size")
    check(apGameData.weaponArt.LASER_BURST_3 ~= nil, "the base game's weapons keep theirs")
end)

test("ships: a ship is named by its class, a B or C layout adds its letter", function()
    sim.shipClasses = { PLAYER_SHIP_FED = "Federation Cruiser" }
    local before = sim.shipNames.PLAYER_SHIP_FED
    sim.shipNames.PLAYER_SHIP_FED = "The Osprey"
    equals(apShipLabel("PLAYER_SHIP_FED"), "Federation Cruiser", "not the Type A's own name")
    equals(apShipLabel("PLAYER_SHIP_FED_2"), "Federation Cruiser B", "the B layout")
    equals(apShipLabel("PLAYER_SHIP_FED_3"), "Federation Cruiser C", "the C layout")
    sim.shipClasses = nil
    sim.shipNames.PLAYER_SHIP_FED = before
end)

test("magic hat: an item opens its destinations in the reroute menu, for this run and the next", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    sim.startRun(true)
    apQueueItem({ kind = "hat", hat = { "rebel_generic", "rebel_unique" }, display = "Magic Hat: Hostile Sectors" })
    sim.tick(31)
    equals(sim.runVariables.ap_hat_on, 1, "the hat shows in the reroute menu")
    equals(sim.runVariables.ap_hat_rebel_generic, 1, "with its destinations")
    equals(sim.runVariables.ap_hat_generic, 1, "in the generic menu")
    equals(sim.runVariables.ap_hat_unique, 1, "and the unique one")
    equals(sim.runVariables.ap_hat_secret, 0, "not the secret one")
    sim.startRun(true)
    sim.tick(31)
    equals(sim.runVariables.ap_hat_rebel_generic, 1, "still there in the next run")
    _G.apInventory.hat = nil
end)

test("multiverse endings: an ending reached sends its own check", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    applySeed({ loc = { ["mvend:true"] = "Multiverse Ending: True Ending", ["mvend:nexus"] = "Multiverse Ending: Nexus" } })
    sim.startRun(true)
    check(apEndingCheck("TRUE_VICTORY_SAVE"), "the true ending")
    check(apCheckAlreadySent("mvend:true"), "is sent")
    check(apEndingCheck("NEXUS_ENDING_GOOD_KILL"), "a Nexus ending")
    check(not apEndingCheck("HER_FINALE_REAL"), "an ending not in the seed sends nothing")
end)

test("multiverse quests: the game unlocking a ship's Type A sends that ship's quest check", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    applySeed({ loc = { ["mvquest:PLAYER_SHIP_LANIUS"] = "Multiverse Quest: Lanius Cruiser" } })
    sim.startRun(true)
    apShipUnlockDenied("PLAYER_SHIP_LANIUS_2")
    check(not apCheckAlreadySent("mvquest:PLAYER_SHIP_LANIUS"), "a B layout unlocked by an achievement is no quest")
    apShipUnlockDenied("PLAYER_SHIP_LANIUS")
    check(apCheckAlreadySent("mvquest:PLAYER_SHIP_LANIUS"), "the Type A unlocked: quest done")
end)

test("kestrel key: a seed that locks the Kestrel refuses its runs until the key comes in", function()
    shipConnect({ "Rock Cruiser Key" }, { kestrel_locked = true })
    equals(apShipReceived("PLAYER_SHIP_HARD"), "not_received", "no key, no Kestrel run")
    shipConnect({ "Rock Cruiser Key", "Kestrel Cruiser Key" }, { kestrel_locked = true })
    equals(apShipReceived("PLAYER_SHIP_HARD"), "ok", "with its key it counts")
    shipConnect({ "Rock Cruiser Key" })
    equals(apShipReceived("PLAYER_SHIP_HARD"), "ok", "other seeds keep the Kestrel A")
    shipDone()
end)

test("in logic: after a reconnection, the items received before still count", function()
    local logic = { layouts = { PLAYER_SHIP_ROCK = { "Rock Cruiser Key" } },
                    checks = { ["PLAYER_SHIP_ROCK:sector:3"] = { ways = { { l = "PLAYER_SHIP_ROCK", i = {} } }, bp = 0, pass = 0 } },
                    blueprint_items = {} }
    shipConnect({ "Rock Cruiser Key" }, { logic = logic })
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:3"), true, "the Rock received: in logic")
    sim.netEvent("disconnected", {})
    sim.net.connected = false
    sim.tick(60 * 6)
    sim.netEvent("connected", { name = "Navigator", extra = shipSeed({ logic = logic }) })
    sim.netEvent("item", { name = "Rock Cruiser Key", sender = "Nina", index = 0 })
    sim.net.connected = true
    sim.tick(1)
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:3"), true, "the server's replay of the Rock still counts once reconnected")
    shipDone()
end)
