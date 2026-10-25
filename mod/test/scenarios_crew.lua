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

test("DeathLink: a temporary crew member who fades away is not a death", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both", cloned = false, graceSeconds = 0 })
    local sent = 0
    local restore = stub("apNetSendDeath", function() sent = sent + 1 return true end)
    sim.startRun(true)
    local projection = sim.player:AddCrewMemberFromString("Projection", "human", false, 0, false, false)
    projection.extend.deathTimer = {}
    local hologram = sim.player:AddCrewMemberFromString("Hologram", "zoltan_osmian_hologram", false, 0, false, false)
    hologram.extend.noSlot = true
    sim.tick(60)
    projection.bDead = true
    hologram.bDead = true
    sim.tick(60)
    table.remove(sim.player.vCrewList._store)
    table.remove(sim.player.vCrewList._store)
    sim.tick(60)
    restore()
    equals(sent, 0, "a projection or a hologram running out is not a crew member lost")
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

test("crew: a Multiverse kind of a race counts as that race", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    applySeed({ loc = {
        ["crew:human"] = "First Human aboard",
        ["crew:engi"] = "First Engi aboard",
        ["crew:energy"] = "First Zoltan aboard",
        ["crew:anaerobic"] = "First Lanius aboard",
    } })
    sim.startRun(true)
    sim.tick(1)
    sim.player:AddCrewMemberFromString("Alex", "engi_separatist", false, 0)
    sim.player:AddCrewMemberFromString("Monk", "zoltan_monk", false, 0)
    sim.player:AddCrewMemberFromString("Welder", "lanius_welder", false, 0)
    sim.jumpArrive()
    check(apCheckAlreadySent("crew:engi"), "a Separatist Engi sends First Engi aboard")
    check(apCheckAlreadySent("crew:energy"), "a Zoltan Monk sends First Zoltan aboard")
    check(apCheckAlreadySent("crew:anaerobic"), "a Lanius Welder sends First Lanius aboard")
end)

test("crew: each Multiverse character who joins gives one free hint per seed, a new run does not repeat it", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    sim.durable = {}
    applySeed({ seed_hash = "characters", loc = { ["crew:engi"] = "First Engi aboard" } })
    local hints = 0
    local restore = stub("apHintPurchase", function() hints = hints + 1; return true end)
    sim.startRun(true)
    sim.tick(1)
    sim.player:AddCrewMemberFromString("Turzil", "unique_turzil", false, 0)
    sim.player:AddCrewMemberFromString("Bob", "engi", false, 0)
    sim.jumpArrive()
    equals(hints, 1, "Turzil gives a hint, an ordinary Engi does not")
    check(shownKey("crew.character.hint", { name = "Turzil" }), "and the player is told who knew")

    sim.startRun(true)
    sim.tick(1)
    sim.player:AddCrewMemberFromString("Turzil", "unique_turzil", false, 0)
    sim.player:AddCrewMemberFromString("Tully", "unique_tully", false, 0)
    sim.jumpArrive()
    equals(hints, 2, "met again in a new run, Turzil gives nothing more; Tully, met for the first time, does")
    restore()
end)

test("crew: a species of no race stays itself", function()
    equals(apRaceFamily("human_soldier"), "human", "a Multiverse soldier is a human")
    equals(apRaceFamily("crystal"), "crystal", "a base race is unchanged")
    equals(apRaceFamily("technolanius"), "technolanius", "a name that only contains a race is not that race")
    equals(apRaceFamily("eldritch_spawn"), "eldritch_spawn", "a species with no race of the seed stays as is")
    equals(apRaceFamily("orchid_vampweed"), "orchid", "a Multiverse race keeps its variants too")
    equals(apRaceFamily("phantom_goul_alpha"), "phantom", "however long the variant's name")
end)

test("crew: a race the text library lacks takes its name from its crew blueprint", function()
    sim.crewTitles = { orchid = "Orchid Floral" }
    equals(apRaceLabel("orchid"), "Orchid Floral", "Multiverse writes it in the blueprint")
    equals(apRaceLabel("nothing_known"), "nothing_known", "no title anywhere: the id itself")
    sim.crewTitles = nil
end)

test("crew: a Multiverse unique crew member counts as its race", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    applySeed({ loc = {
        ["crew:human"] = "First Human aboard",
        ["crew:engi"] = "First Engi aboard",
        ["crew:pony"] = "First Pony aboard",
    } })
    sim.startRun(true)
    sim.tick(1)
    sim.player:AddCrewMemberFromString("Turzil", "unique_turzil", false, 0)
    sim.player:AddCrewMemberFromString("Jerry", "unique_jerry_pony", false, 0)
    sim.player:AddCrewMemberFromString("Gnome", "unique_gnome", false, 0)
    sim.jumpArrive()
    check(apCheckAlreadySent("crew:engi"), "Turzil, an Engi, sends First Engi aboard")
    check(apCheckAlreadySent("crew:pony"), "Jerry, a Pony, sends First Pony aboard: a Multiverse race")
    check(not apCheckAlreadySent("crew:gnome"), "a unique crew member of no race of the seed sends nothing")
    sim.player:AddCrewMemberFromString("Tully", "unique_tully", false, 0)
    sim.jumpArrive()
    check(apCheckAlreadySent("crew:human"), "Tully, a Human, sends First Human aboard")
end)

local function joins(name)
    local member = sim.player:AddCrewMemberFromString(name, "human", false, 0, false, false)
    sim.tick(30)
    return member
end

test("crew names: new crew is named after the other players, then keeps FTL's names", function()
    apCrewNamesConfigure("multiworld", { "Nina", "Bérénice", "Berserker" })
    sim.startRun(true)
    sim.tick(30)
    local captain = sim.player.vCrewList[0]
    local starting = captain:GetName()
    equals(joins("Ruwen"):GetName(), "Nina", "the first recruit takes a player's name")
    equals(joins("Kazu"):GetName(), "Berserker", "the next one the next player's, skipping a name FTL cannot draw")
    equals(joins("Hara"):GetName(), "Hara", "once every player is aboard, FTL's names come back")
    equals(captain:GetName(), starting, "the starting crew keeps its names")
    sim.startRun(false)
    sim.tick(30)
    equals(joins("Lio"):GetName(), "Lio", "after a Continue, the names aboard are still taken")
end)

test("crew names: the team comes after the players, only when asked", function()
    apCrewNamesConfigure("multiworld_and_team", { "Nina" })
    sim.startRun(true)
    sim.tick(30)
    equals(joins("Ruwen"):GetName(), "Nina", "players first")
    equals(joins("Kazu"):GetName(), "Liloji", "then the team")
    apCrewNamesConfigure("vanilla", { "Nina" })
    sim.startRun(true)
    sim.tick(30)
    equals(joins("Hara"):GetName(), "Hara", "vanilla keeps FTL's names")
    apCrewNamesConfigure("multiworld", {})
end)

test("crew names: a hologram or a drone keeps its name", function()
    apCrewNamesConfigure("multiworld", { "Nina" })
    sim.startRun(true)
    sim.tick(30)
    local hologram = sim.player:AddCrewMemberFromString("Hologram", "human", false, 0, false, false)
    hologram.extend.deathTimer = {}
    local drone = sim.player:AddCrewMemberFromString("Drone", "repair", false, 0, false, false)
    drone.IsDrone = function() return true end
    sim.tick(30)
    equals(hologram:GetName(), "Hologram", "a projection is not a recruit")
    equals(drone:GetName(), "Drone", "nor a drone")
    equals(joins("Ruwen"):GetName(), "Nina", "the name waits for a real recruit")
    apCrewNamesConfigure("multiworld", {})
end)

local function deathLinkRun()
    apDeathLinkConfigure({ enabled = true, trigger = "both", cloned = false, graceSeconds = 0 })
    local sent = { n = 0 }
    sent.restore = stub("apNetSendDeath", function() sent.n = sent.n + 1 return true end)
    sim.startRun(true)
    sim.tick(60)
    return sent
end

test("DeathLink: an event that takes a crew member away (the Engi virus) is not a death", function()
    local sent = deathLinkRun()
    table.remove(sim.player.vCrewList._store, 1)
    sim.tick(60)
    sent.restore()
    equals(sent.n, 0, "gone from the list without dying first")
end)

test("DeathLink: a Multiverse crew member turned into another race is not a death", function()
    local sent = deathLinkRun()
    local old = table.remove(sim.player.vCrewList._store, 1)
    sim.player:AddCrewMemberFromString(old._name, "rock", false, 0, false, false)
    sim.tick(60)
    sent.restore()
    equals(sent.n, 0, "the same crew member under a new race")
end)

test("DeathLink: a crew member left on the enemy ship when it goes is a death", function()
    local sent = deathLinkRun()
    sim.player.vCrewList[0].currentShipId = 1
    sim.tick(60)
    table.remove(sim.player.vCrewList._store, 1)
    sim.tick(60)
    sent.restore()
    equals(sent.n, 1, "boarders lost with the enemy ship")
end)
