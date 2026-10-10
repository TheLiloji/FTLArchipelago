local function sendsFor(key)
    local n = 0
    for _, line in ipairs(sim.log) do
        if line:find("CHECK " .. key, 1, true) then n = n + 1 end
    end
    return n
end

local function seedWithSpecies()
    apContractResetForTesting()
    apForgetChecksForTesting()
    applySeed({ loc = {
        ["crew:human"] = "First Human aboard",
        ["crew:energy"] = "First Zoltan aboard",
        ["crew:slug"] = "First Slug aboard",
        ["crew:mantis"] = "First Mantis aboard",
    } })
end

test("crew: starting species are not free checks", function()
    seedWithSpecies()
    sim.startRun(true)
    sim.tick(1)
    sim.jumpArrive()
    check(not apCheckAlreadySent("crew:human"), "humans were already there at the start")
    check(not apCheckAlreadySent("crew:energy"), "so was the Zoltan")
end)

test("crew: the first recruit of a new species sends its check", function()
    seedWithSpecies()
    sim.startRun(true)
    sim.tick(1)
    sim.player:AddCrewMemberFromString("Sluggo", "slug", false, 0)
    sim.jumpArrive()
    check(apCheckAlreadySent("crew:slug"), "the recruited Slug counts on the next jump")
    equals(sendsFor("crew:slug"), 1, "only one send")
    sim.jumpArrive()
    equals(sendsFor("crew:slug"), 1, "the next jump does not resend it")
end)

test("crew: an intruder or a dead crew member does not count", function()
    seedWithSpecies()
    sim.startRun(true)
    sim.tick(1)
    sim.player:AddCrewMemberFromString("Pirate", "mantis", true, 0)
    local dead = sim.player:AddCrewMemberFromString("Sluggo", "slug", false, 0)
    dead.bDead = true
    sim.jumpArrive()
    check(not apCheckAlreadySent("crew:mantis"), "a boarding Mantis is not a recruit")
    check(not apCheckAlreadySent("crew:slug"), "an already dead recruit does not count")
end)

test("received crew member: comes aboard and enters the catalog", function()
    apInventoryClear()
    sim.startRun(true)
    local before = sim.player.vCrewList:size()
    apQueueItem({ kind = "crew", race = "energy", skill = "shields", display = "Zoltan Shield Expert" })
    drain()
    equals(sim.player.vCrewList:size(), before + 1, "one more crew member aboard")
    local recruit = sim.player.vCrewList[sim.player.vCrewList:size() - 1]
    equals(recruit.species, "energy", "it's a Zoltan")
    equals(recruit.maitrises[1], 2, "shields expert")
    equals(#apInventory.crew, 1, "and it waits in the start-of-run menu")
end)

test("received crew member, full crew: waits in the menu, nothing lost", function()
    apInventoryClear()
    sim.startRun(true)
    sim.player._crewCap = 0
    apQueueItem({ kind = "crew", race = "mantis", display = "Mantis Crew" })
    drain()
    equals(#apInventory.crew, 1, "the catalog keeps it")
    check(shownKey("crew.received.menu"), "and the player knows where to find it")
    sim.player._crewCap = nil
end)

local function cloneBayRun(cloned, trigger)
    apDeathLinkConfigure({ enabled = true, trigger = trigger or "both", cloned = cloned, graceSeconds = 0 })
    local sent = { n = 0 }
    sent.restore = stub("apNetSendDeath", function() sent.n = sent.n + 1 return true end)
    sim.startRun(true)
    sim.player._systemsHeld = { [13] = true }
    sim.tick(60)
    local member = sim.player.vCrewList[0]
    member.health.first = 0
    sim.tick(30)
    member.bDead = true
    sim.tick(30)
    table.remove(sim.player.vCrewList._store, 1)
    sim.cloneQueue = { member }
    sim.tick(60)
    return sent, member
end

test("DeathLink: a crew member the Clone Bay brings back is not a death", function()
    local sent, member = cloneBayRun(false)
    equals(sent.n, 0, "waiting in the Clone Bay: nothing yet")
    member.bDead = false
    member.health.first = 100
    sim.cloneQueue = {}
    sim.player.vCrewList:push_back(member)
    sim.tick(60)
    sent.restore()
    equals(sent.n, 0, "back on board: no death")
end)

test("DeathLink: a crew member the Clone Bay loses is a death", function()
    local sent = cloneBayRun(false)
    sim.cloneQueue = {}
    sim.tick(60)
    sent.restore()
    equals(sent.n, 1, "gone from the Clone Bay without coming back: the death goes out")
end)

test("DeathLink: with cloned crew counted, a death in the Clone Bay goes out at once", function()
    local sent = cloneBayRun(true)
    sent.restore()
    equals(sent.n, 1, "the option counts every crew death")
end)

test("DeathLink: a run lost while a crew member waits in the Clone Bay sends that death", function()
    local sent = cloneBayRun(false, "crew_death")
    apOnRunEnd("crew", "no living crew left")
    sent.restore()
    equals(sent.n, 1, "the crew member will never come back")
end)

test("DeathLink: a seed without the clone option does not keep the last seed's", function()
    apDeathLinkConfigure({ cloned = true })
    apContractResetForTesting()
    applySeed({ links = { death = { enabled = true, trigger = "both", effect = "fire" } } })
    equals(_G.apDeathLink.cloned, false, "back to the default")
end)

test("DeathLink: without a Clone Bay, a crew member lying dead aboard is a death at once", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both", cloned = false, graceSeconds = 0 })
    local sent = 0
    local restore = stub("apNetSendDeath", function() sent = sent + 1 return true end)
    sim.startRun(true)
    sim.tick(60)
    sim.player.vCrewList[0].health.first = 0
    sim.tick(30)
    sim.player.vCrewList[0].bDead = true
    sim.tick(30)
    restore()
    equals(sent, 1, "no Clone Bay to wait for")
end)

test("DeathLink: a run loaded with a crew member in the Clone Bay still counts their loss", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both", cloned = false, graceSeconds = 0 })
    local sent = 0
    local restore = stub("apNetSendDeath", function() sent = sent + 1 return true end)
    sim.player._systemsHeld = { [13] = true }
    local member = sim.player.vCrewList[0]
    member.bDead = true
    table.remove(sim.player.vCrewList._store, 1)
    sim.cloneQueue = { member }
    sim.startRun(false)
    sim.tick(60)
    equals(sent, 0, "waiting in the Clone Bay")
    sim.cloneQueue = {}
    sim.tick(60)
    restore()
    equals(sent, 1, "lost for good: the death goes out")
end)

test("contract: an unloaded seed forgets its layouts", function()
    apContractResetForTesting()
    applySeed({ layouts = { "PLAYER_SHIP_HARD" } })
    check(not apLayoutInSeed("PLAYER_SHIP_ROCK"), "the Rock is not in this seed")
    apContractUnload()
    check(apLayoutInSeed("PLAYER_SHIP_ROCK"), "no seed, no filter")
end)

test("crew: a recruit of a species already aboard at the start counts too", function()
    seedWithSpecies()
    sim.startRun(true)
    sim.tick(1)
    check(not apCheckAlreadySent("crew:human"), "the Kestrel's own humans are not recruits")
    sim.player:AddCrewMemberFromString("Hired Hand", "human", false, 0)
    sim.jumpArrive()
    check(apCheckAlreadySent("crew:human"), "a human bought for the Kestrel's human crew sends First Human aboard")
end)
