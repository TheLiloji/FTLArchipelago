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
