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
