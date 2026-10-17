test("network: a check made with no seed loaded is not kept for later", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    apNetResetForTesting()
    _G.apNetState.connected = false
    sim.clearLog()

    equals(apSendCheck("PLAYER_SHIP_HARD:sector:3", "Sector 3"), false, "with no seed, nothing is recorded")
    equals(apPendingCheckCount(), 0, "and nothing waits for a connection")

    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = slotData({
        seed_hash = "AUDIT",
        loc = { ["PLAYER_SHIP_HARD:sector:3"] = "Kestrel Cruiser A: Reach sector 3" },
    }) })
    sim.net.connected = true
    sim.tick(1)

    local wasSent = false
    for _, call in ipairs(sim.net.calls) do
        if call[1] == "SendCheck" then wasSent = true end
    end
    check(not wasSent, "connecting later sends nothing from that seedless moment")

    apNetResetForTesting()
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

test("shop: a package bought with no room aboard still sends its check", function()
    sim.startRun(true)
    apNetResetForTesting()
    apShopGiftsConfigure({
        { slot = "Berserker", item = "Seashell", location = "full:1" },
    })
    local sent = nil
    local restore = stub("apSendCheck", function(location) sent = location; return true end)
    sim.netEvent("package_bought", { name = "AP_GIFT_1" })
    sim.tick(60)
    restore()
    equals(sent, "full:1", "the module kept it off the ship, the shop sends it all the same")
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

    equals(sim.durable["ap_items_done_0"], "3",
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

test("shop: a refused Drone Control takes back its free drone and leaves the player's own", function()
    sim.startRun(true)
    _G.apInventory.systemCaps.drones = nil
    sim.droneBlueprints.DEFENSE_1 = true
    sim.droneBlueprints.COMBAT_1 = true
    sim.cargo = { "DEFENSE_1", "COMBAT_1" }
    sim.jumpArrive()
    sim.setStore(true)
    sim.player.currentScrap = 200
    sim.tick(1)

    -- The game sells Drone Control with a free drone, here one more Defense I.
    sim.player.currentScrap = 125
    sim.cargo[#sim.cargo + 1] = "DEFENSE_1"
    sim.constructSystem("drones", 0, 50)
    sim.tick(5)

    equals(#sim.player._removed, 1, "Drone Control is refused")
    equals(table.concat(sim.cargo, ","), "COMBAT_1,DEFENSE_1", "the free drone is gone, the two held before stay")
    equals(sim.player.currentScrap, 200, "the whole price comes back")
    check(sim.logged("DEFENSE_1 that came with the refused drones taken back"), "and the log says so")
end)

test("shop: a refused clone bay gives back the medbay the purchase replaced", function()
    sim.startRun(true)
    _G.apInventory.systemCaps.clonebay = nil
    sim.player._systemsHeld = { [5] = true }
    sim.jumpArrive()
    sim.setStore(true)
    sim.tick(1)

    -- Like the game, putting a system aboard builds it, which the guard sees.
    local addSystem = sim.player.AddSystem
    sim.player.AddSystem = function(self, id)
        addSystem(self, id)
        if id == 5 then sim.constructSystem("medbay", 0, 0) end
    end
    -- The game swaps them: the medbay goes as the clone bay comes in.
    sim.player._systemsHeld[5] = nil
    sim.constructSystem("clonebay", 0, 70)
    sim.tick(5)
    sim.player.AddSystem = addSystem

    equals(#sim.player._removed, 1, "only the clone bay is refused, not the medbay put back")
    check(sim.player:HasSystem(5), "the medbay is back aboard")
    check(sim.logged("medbay put back"), "and the log says so")
    sim.player._systemsHeld = nil
end)

test("event: a level sold for scrap on a system at its Archipelago cap is cancelled, the scrap kept", function()
    sim.startRun(true)
    sim.jumpArrive()
    local shields = { powerState = { first = 2, second = 2 }, maxLevel = 2 }
    sim.player._systemsHeld = { [0] = true }
    local getSystem = sim.player.GetSystem
    sim.player.GetSystem = function(_, id) return id == 0 and shields or nil end
    sim.clearLog()

    local stuff = { upgradeId = 0, upgradeAmount = 1, scrap = -40 }
    sim.openChoiceBox("UPGRADE_TRADE", 1, stuff)
    equals(stuff.upgradeAmount, 0, "no level is given past the cap")
    equals(stuff.scrap, 0, "and the 40 scrap are not taken")
    check(shownKey("system.upgrade_locked.refunded",
        { name = apSystemLabel("shields"), level = 2, refund = 40 }), "the player is told why")

    shields.maxLevel = 4
    stuff = { upgradeId = 0, upgradeAmount = 1, scrap = -40 }
    sim.openChoiceBox("UPGRADE_TRADE", 1, stuff)
    equals(stuff.upgradeAmount, 1, "below the cap, the trade goes through")
    equals(stuff.scrap, -40, "and costs its price")
    sim.player._systemsHeld = nil
    sim.player.GetSystem = getSystem
end)

test("home screen: TAB in the connection form does not open the dashboard", function()
    sim.started = false
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.keyDown(Defines.SDL.KEY_TAB)

    sim.startRun(true)
    sim.renderGui()
    check(not sim.drawnText(apT("dash.footer")),
        "three TABs to move between fields don't leave the panel open in a run")

    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.renderGui()
    check(sim.drawnText(apT("dash.footer")), "in a run, TAB does open the panel")
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

test("free upgrades: a received level is installed at once, no store needed", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ kinds = { "cap" }, options = { free_upgrades = 1 } })
    sim.startRun(true)
    apApplySystemRules()
    local start = oxygen().powerState.second
    apQueueItem({ kind = "cap", sys = "oxygen", n = 1, display = "Progressive Oxygen" })
    drain()
    apApplySystemRules()
    equals(oxygen().powerState.second, start + 1, "the oxygen level Archipelago gave is already installed")
    oxygen().powerState.second, oxygen().maxLevel = start, 3 -- a new run comes with a fresh ship
    sim.startRun(true)
    apApplySystemRules()
    equals(oxygen().powerState.second, start + 1, "and again at the start of the next run")
end)

test("free upgrades: off, a received level only allows the purchase", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ kinds = { "cap" } })
    sim.startRun(true)
    apApplySystemRules()
    local start = oxygen().powerState.second
    apQueueItem({ kind = "cap", sys = "oxygen", n = 1, display = "Progressive Oxygen" })
    drain()
    apApplySystemRules()
    equals(oxygen().powerState.second, start, "nothing installed by itself")
    equals(oxygen().maxLevel, start + 1, "but the level can be bought")
end)

test("free upgrades: with no progressive upgrades in the seed, nothing is given for free", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ system_caps = false, options = { free_upgrades = 1 } })
    sim.startRun(true)
    apApplySystemRules()
    equals(oxygen().powerState.second, 1, "without caps every level would be free: the option does nothing")
end)

local function withTeleporterPlace()
    sim.hullPlaces = { [9] = true, [10] = true }
    _G.apInventory = { ships = {}, systemCaps = {}, blueprints = {}, startingUpgrades = {}, shopAvailability = {} }
end

test("system install: at the start of a run, a system whose blueprint came in is put aboard", function()
    withTeleporterPlace()
    applySeed({ kinds = { "cap" }, options = { system_install = 1 } })
    apQueueItem({ kind = "cap", sys = "teleporter", n = 0, display = "Teleporter blueprint" })
    drain()
    sim.startRun(true)
    check(sim.player:HasSystem(9), "the teleporter is aboard from the first beacon")
    check(not sim.player:HasSystem(10), "cloaking, with no blueprint, is not")
    check(sim.shown("Teleporter"), "the player is told")
    sim.hullPlaces = nil
end)

test("system install: a level received without the blueprint puts nothing aboard and allows no purchase", function()
    withTeleporterPlace()
    applySeed({ kinds = { "cap" }, options = { system_install = 1 } })
    apQueueItem({ kind = "cap", sys = "teleporter", n = 1, display = "Progressive Teleporter" })
    drain()
    sim.startRun(true)
    check(not sim.player:HasSystem(9), "no teleporter aboard without its blueprint")
    sim.jumpArrive()
    sim.setStore(true)
    sim.tick(1)
    sim.constructSystem("teleporter", 0, 90)
    sim.tick(5)
    equals(#sim.player._removed, 1, "and a store purchase is still refused")
    sim.setStore(false)
    sim.hullPlaces = nil
end)

test("system install: a head start raises a system put aboard at the run start once, not twice", function()
    withTeleporterPlace()
    applySeed({ kinds = { "cap" }, options = { system_install = 1 } })
    local added
    local addSystem = sim.player.AddSystem
    local makeTeleporter = function()
        local system = { name = "teleporter", _shipObj = { iShipId = 0 }, bpCost = 0,
            powerState = { first = 1, second = 1 }, maxLevel = 3, healthState = { first = 2, second = 2 },
            iSystemType = 9, roomId = 0, AddDamage = function() end }
        system.UpgradeSystem = function(self, amount)
            local before = self.powerState.second
            self.powerState.second = math.min(self.maxLevel, before + amount)
            return self.powerState.second > before
        end
        return system
    end
    apQueueItem({ kind = "cap", sys = "teleporter", n = 0, display = "Teleporter blueprint" })
    apQueueItem({ kind = "start", sys = "teleporter", n = 1, display = "Head Start: Teleporter" })
    drain()
    sim.player.AddSystem = function(self, id)
        addSystem(self, id)
        if id == 9 then
            added = makeTeleporter()
            self.vSystemList:push_back(added)
        end
        return 1
    end
    sim.startRun(true)
    sim.player.AddSystem = addSystem
    check(added ~= nil, "the teleporter is put aboard")
    equals(added.powerState.second, 2, "the head start gives it level 2")
    equals(added.maxLevel, 2, "and the store can sell no level above: blueprint + head start, counted once")
    sim.hullPlaces = nil
end)

test("system install: no place in the hull, nothing is forced aboard", function()
    withTeleporterPlace()
    sim.hullPlaces = {}
    applySeed({ kinds = { "cap" }, options = { system_install = 1 } })
    apQueueItem({ kind = "cap", sys = "teleporter", n = 0, display = "Teleporter blueprint" })
    drain()
    sim.startRun(true)
    check(not sim.player:HasSystem(9), "a ship without a teleporter room gets no teleporter")
    sim.hullPlaces = nil
end)

test("system install: immediately, a blueprint received mid-run is put aboard", function()
    withTeleporterPlace()
    applySeed({ kinds = { "cap" }, options = { system_install = 2 } })
    sim.startRun(true)
    sim.jumpArrive()
    apQueueItem({ kind = "cap", sys = "teleporter", n = 0, display = "Teleporter blueprint" })
    drain()
    sim.tick(61)
    check(sim.player:HasSystem(9), "the teleporter comes aboard during the run")
    sim.hullPlaces = nil
end)

test("system install: the default keeps the store as the only way", function()
    withTeleporterPlace()
    applySeed({ kinds = { "cap" } })
    sim.startRun(true)
    sim.jumpArrive()
    apQueueItem({ kind = "cap", sys = "teleporter", n = 0, display = "Teleporter blueprint" })
    drain()
    sim.tick(61)
    sim.startRun(true)
    check(not sim.player:HasSystem(9), "nothing put aboard without the option")
    sim.hullPlaces = nil
end)

test("run start scrap: a share of every scrap item received comes back at each new run", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ kinds = { "filler" }, options = { run_start_scrap = 25 } })
    sim.startRun(true)
    apQueueItem({ kind = "filler", res = "scrap", n = 20, display = "20 Scrap" })
    apQueueItem({ kind = "filler", res = "scrap", n = 20, display = "20 Scrap", isReplay = true })
    drain()
    equals(apRunStartScrap(), 10, "25% of the 40 scrap of the seed, a replayed item counting too")
    local before = sim.player.currentScrap
    sim.startRun(true)
    equals(sim.player.currentScrap - before, 10, "given at the start of the next run")
    check(sim.shown("+10"), "the player is told")
    before = sim.player.currentScrap
    sim.startRun(false)
    equals(sim.player.currentScrap, before, "not again when a saved run is continued")
end)

test("run start scrap: off by default", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ kinds = { "filler" } })
    apQueueItem({ kind = "filler", res = "scrap", n = 50, display = "50 Scrap", isReplay = true })
    equals(apRunStartScrap(), 0, "nothing without the option")
end)

local function fightSeed(percent)
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    apContractResetForTesting()
    apForgetChecksForTesting()
    applySeed({ loc = { ["PLAYER_SHIP_HARD:fight:1"] = "Kestrel Cruiser: Fight 1 won",
                        ["PLAYER_SHIP_HARD:fight:2"] = "Kestrel Cruiser: Fight 2 won" },
                options = { combat_check_scrap = percent } })
    sim.startRun(true)
    sim.jumpArrive()
end

local function winFight(scrap)
    sim.enemy = sim.makeShip(1)
    sim.enemy:DamageHull(100)
    local event = { stuff = { scrap = scrap, fuel = 2, missiles = 1 } }
    fire("PRE_CREATE_CHOICEBOX", event)
    return event
end

test("combat checks: the first fights won in a run send their checks, with less scrap", function()
    fightSeed(50)
    local event = winFight(30)
    check(apCheckAlreadySent("PLAYER_SHIP_HARD:fight:1"), "fight 1 won sends its check")
    equals(event.stuff.scrap, 15, "half the scrap is kept")
    equals(event.stuff.fuel, 2, "fuel and missiles stay")
    winFight(30)
    check(not apCheckAlreadySent("PLAYER_SHIP_HARD:fight:2"), "a second box at the same beacon is the same fight")
    sim.jumpArrive()
    winFight(30)
    check(apCheckAlreadySent("PLAYER_SHIP_HARD:fight:2"), "the next beacon's fight is fight 2")
    sim.jumpArrive()
    local third = winFight(30)
    equals(third.stuff.scrap, 30, "a fight beyond the seed's checks keeps its full scrap")
    sim.enemy = nil
end)

test("combat checks: a new run counts from fight 1 again, and an already sent check costs nothing", function()
    fightSeed(50)
    winFight(30)
    sim.startRun(true)
    sim.jumpArrive()
    local event = winFight(30)
    equals(event.stuff.scrap, 30, "fight 1 was already sent: full scrap")
    sim.enemy = nil
end)

test("combat checks: the game's float run variable still gives a whole fight number", function()
    fightSeed(50)
    sim.runVariables.ap_fights_won = 1.0
    winFight(30)
    check(apCheckAlreadySent("PLAYER_SHIP_HARD:fight:2"), "fight 2, not fight 2.0")
    sim.enemy = nil
end)

test("combat checks: the dashboard knows when the next fight sends a check", function()
    fightSeed(50)
    local status = apCombatStatus()
    equals(status.total, 2, "two fight checks in the seed for the Kestrel")
    check(status.nextSends, "fight 1 is still due")
    winFight(30)
    sim.jumpArrive()
    winFight(30)
    status = apCombatStatus()
    equals(status.left, 0, "both sent")
    check(not status.nextSends, "a third fight sends nothing")
    sim.enemy = nil
end)

test("combat checks: a living enemy, like a surrender, is not a won fight", function()
    fightSeed(50)
    sim.enemy = sim.makeShip(1)
    sim.enemy.vCrewList = sim.vector({ sim.makeCrew("Rebel", "human", 1) })
    fire("PRE_CREATE_CHOICEBOX", { stuff = { scrap = 10 } })
    check(not apCheckAlreadySent("PLAYER_SHIP_HARD:fight:1"), "nothing sent while the enemy lives")
    sim.enemy = nil
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

test("network: a local server is reached without the secure attempt, and the panel still shows its address", function()
    tryConnect()
    local connect = sim.net.calls[#sim.net.calls]
    equals(connect.uri, "ws://localhost:38281", "localhost goes straight to a plain connection")
    sim.net.last = { uri = connect.uri, slot = "Navigator" }
    apConnectResetForTesting()
    sim.renderMenu()
    equals(apConnectState().uri, "localhost", "the remembered address comes back without the scheme")

    apConnectResetForTesting()
    sim.net.last = { uri = "archipelago.gg:38281", slot = "Navigator" }
    sim.renderMenu()
    apConnectNow()
    equals(sim.net.calls[#sim.net.calls].uri, "archipelago.gg:38281", "a remote server keeps the secure attempt")
    apNetResetForTesting()
end)

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

test("network: the panel says the server refused the slot, and a new attempt clears it", function()
    tryConnect()
    sim.netEvent("error", { name = "unreachable", extra = "TLS handshake failed" })
    sim.netEvent("refused", { extra = "InvalidSlot" })
    sim.tick(600)
    sim.renderMenu()
    equals(apConnectState().message, apT("net.refused.slot"),
        "the reason stays in the panel after the notice fades")
    check(apConnectNow(), "a second attempt goes out")
    sim.tick(1)
    sim.renderMenu()
    equals(apConnectState().message, apT("connect.trying", { uri = "localhost:38281" }),
        "the old refusal does not end the new attempt")
    apNetResetForTesting()
end)

test("network: a refused seed says why and nothing else, no unknown items, no silent server", function()
    tryConnect()
    sim.clearLog()
    sim.netEvent("error", { name = "unreachable", extra = "TLS handshake failed" })
    -- Like a seed change: the refusal cuts the link inside the same event.
    local apply = _G.apApplySlotData
    _G.apApplySlotData = function(...)
        local accepted = apply(...)
        apNetDisconnect()
        sim.net.connected = false
        return accepted
    end
    sim.net.connected = true
    sim.netEvent("connected", { name = "Navigator", extra = slotData({ contract = 99 }) })
    sim.netEvent("item", { name = "Kestrel Cruiser Key", sender = "Nina", index = 0 })
    sim.tick(600)
    _G.apApplySlotData = apply
    check(not shownKey("item.unknown", { name = "Kestrel Cruiser Key" }), "the refused seed's items are not called unknown")
    check(not shownKey("net.error.unreachable"), "the server answered, it is not said to be silent")
    apNetResetForTesting()
    apContractResetForTesting()
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

test("reset: the password typed before the relaunch is there again after it, once", function()
    sim.net.relaunchPossible = true
    apContractResetForTesting()
    apConnectResetForTesting()
    apInventoryClear()
    sim.durable = { ap_autoconnect = "1", ap_seed_tag = "4242" }
    sim.net.resetRequested = false
    sim.renderMenu()
    sim.keyDown(Defines.SDL.KEY_DOWN)
    for _, key in ipairs({ Defines.SDL.KEY_s, Defines.SDL.KEY_e, Defines.SDL.KEY_c }) do sim.keyDown(key) end
    equals(apConnectState().password, "sec", "the password field took the keys")
    applySeed({ seed_hash = "seed-A" })
    apInventoryAdd({ kind = "ship", bp = "PLAYER_SHIP_ROCK" })
    applySeed({ seed_hash = "seed-B" })
    sim.quitCalled = false
    sim.renderMenu()
    for y = 150, 400 do
        sim.click(640 - 200, y)
        if sim.quitCalled then break end
    end
    check(sim.quitCalled, "the game closes for its relaunch")

    apConnectResetForTesting()
    sim.renderMenu()
    equals(apConnectState().password, "sec", "the relaunched game fills the password in again")
    equals(sim.durable.relaunch_password, "", "and forgets it at once")
    sim.net.relaunchPossible = nil
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

test("network: a reconnection to a room whose seed changed does not claim nothing was lost", function()
    apNetResetForTesting()
    apContractResetForTesting()
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = slotData({ seed_hash = "FIRST" }) })
    sim.net.connected = true
    sim.tick(1)
    sim.netEvent("disconnected", {})
    sim.net.connected = false
    sim.tick(60 * 6)
    local restoreRefuse = stub("apApplySlotData", function() return false end)
    sim.clearLog()
    sim.netEvent("connected", { name = "Navigator", extra = slotData({ seed_hash = "SECOND" }) })
    sim.tick(1)
    restoreRefuse()
    check(not shownKey("net.reconnected"), "no 'signal back, nothing lost' before a refusal")
    apNetResetForTesting()
end)

test("event beacons: the seed's option hides the labels it should, and leaving the seed shows them all again", function()
    sim.hiddenBeacons = {}
    apContractResetForTesting()
    applySeed({ seed_hash = "beacons", event_beacons = "important" })
    check(sim.hiddenBeacons.AP_EVT_SLUG_WHISPER, "important: the Slug's hints look like any beacon")
    check(not sim.hiddenBeacons.AP_EVT_PACKAGE, "but the package relay keeps its label")
    applySeed({ seed_hash = "beacons2", event_beacons = "hidden" })
    check(sim.hiddenBeacons.AP_EVT_PACKAGE and sim.hiddenBeacons.AP_EVT_HIJACK, "hidden: no event is labelled")
    apContractUnload()
    check(next(sim.hiddenBeacons) == nil, "every label is back once the seed is left")
    applySeed({ seed_hash = "beacons3" })
    check(next(sim.hiddenBeacons) == nil, "a seed from before the option keeps every label")
    sim.hiddenBeacons = nil
end)
