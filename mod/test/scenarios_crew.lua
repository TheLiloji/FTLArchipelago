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

test("received crew member, full crew: waits for a free seat and in the menu, nothing lost", function()
    apInventoryClear()
    sim.startRun(true)
    sim.player._crewCap = 0
    apQueueItem({ kind = "crew", race = "mantis", display = "Mantis Crew" })
    drain()
    equals(#apInventory.crew, 1, "the catalog keeps it")
    check(shownKey("crew.waiting"), "and the player knows it waits for a seat")
    equals(apOwedCrewCount(), 1, "and it is counted for the dashboard")
    local before = sim.player.vCrewList:size()
    sim.player._crewCap = nil
    sim.tick(61)
    equals(sim.player.vCrewList:size(), before + 1, "a seat frees up: the Mantis comes aboard")
    equals(sim.player.vCrewList[sim.player.vCrewList:size() - 1].species, "mantis", "the right race")
    check(shownKey("crew.seated"), "and the player is told")
    sim.tick(61)
    equals(sim.player.vCrewList:size(), before + 1, "only once")
end)

test("progressive crew member, full crew: the first copy comes aboard once someone leaves", function()
    apInventoryClear()
    sim.startRun(true)
    local size = sim.player.vCrewList:size()
    sim.player._crewCap = size
    apQueueItem({ kind = "filler", res = "crew", n = 1 })
    apQueueItem({ kind = "crew", race = "crystal", tiers = 3, display = "Progressive Crystal Crew" })
    drain()
    check(shownKey("crew.waiting"), "the Crystal waits for a seat")
    sim.player.vCrewList[0].bDead = true
    drain()
    sim.tick(61)
    local crystals = 0
    for i = 0, sim.player.vCrewList:size() - 1 do
        if sim.player.vCrewList[i].species == "crystal" then crystals = crystals + 1 end
    end
    equals(crystals, 0, "one seat: the crew member queued first takes it")
    sim.player.vCrewList[1].bDead = true
    sim.tick(61)
    for i = 0, sim.player.vCrewList:size() - 1 do
        if sim.player.vCrewList[i].species == "crystal" and not sim.player.vCrewList[i].bDead then
            crystals = crystals + 1
        end
    end
    equals(crystals, 1, "a second seat: the Crystal comes aboard")
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
    sim.tick(300)
    sent.restore()
    equals(sent.n, 1, "boarders lost with the enemy ship")
end)

test("DeathLink: a crew member teleporting back from the enemy ship is not a death", function()
    local sent = deathLinkRun()
    local member = sim.player.vCrewList[0]
    member.currentShipId = 1
    sim.tick(60)
    table.remove(sim.player.vCrewList._store, 1)
    sim.tick(120)
    equals(sent.n, 0, "on neither ship during the teleport: nothing yet")
    member.currentShipId = 0
    table.insert(sim.player.vCrewList._store, member)
    sim.tick(300)
    sent.restore()
    equals(sent.n, 0, "back aboard: nobody died")
end)

test("DeathLink: a crew member seen dead on the enemy ship does not wait for the teleport delay", function()
    local sent = deathLinkRun()
    local member = sim.player.vCrewList[0]
    member.currentShipId = 1
    sim.tick(60)
    member.health.first = 0
    sim.tick(30)
    table.remove(sim.player.vCrewList._store, 1)
    sim.tick(30)
    sent.restore()
    equals(sent.n, 1, "seen dying: it goes out at once")
end)

test("DeathLink: turned off from the dashboard, nothing goes out or comes in, and the choice is kept", function()
    local sent = deathLinkRun()
    check(apDeathLinkToggle(), "the seed lets the player choose")
    equals(_G.apDeathLink.enabled, false, "off")
    sim.tick(60)
    local member = sim.player.vCrewList[0]
    member.health.first = 0
    sim.tick(30)
    member.bDead = true
    sim.tick(30)
    table.remove(sim.player.vCrewList._store, 1)
    sim.tick(60)
    equals(sent.n, 0, "no death sent")
    equals(apDeathLinkReceive("Other", "fell"), false, "no death received")
    apDeathLinkConfigure({ enabled = true })
    equals(_G.apDeathLink.enabled, false, "still off after a reconnection")
    equals(_G.apDeathLink.offered, true, "the dashboard still shows it")
    check(apDeathLinkToggle(), "and back on")
    equals(_G.apDeathLink.enabled, true, "on again")
    sent.restore()
end)

test("DeathLink: a seed that forbids the toggle stays as it is", function()
    apDeathLinkConfigure({ enabled = true, toggle = false })
    equals(apDeathLinkToggle(), false, "refused")
    equals(_G.apDeathLink.enabled, true, "still on")
    apDeathLinkConfigure({ toggle = true })
end)

local trapLog = {}

local function trapStubs()
    trapLog = {}
    local aimed = stub("apNetSendTrapTo", function(slot, name)
        trapLog[#trapLog + 1] = { "SendTrapTo", slot = slot, name = name }
        return true
    end)
    local whole = stub("apNetSendTrap", function(name)
        trapLog[#trapLog + 1] = { "SendTrap", name = name }
        return true
    end)
    return function() aimed() whole() end
end

test("a pact lands on one FTL player, never on the whole link", function()
    _G.apTrapLink.enabled = true
    apTrapLinkForgetPartner()
    apTrapLinkPartner("Nina", true, 2)
    apTrapLinkPartner("Bers", true, 3)
    local restore = trapStubs()
    check(apTrapLinkSendToOne("Archipelago Deal"), "sent")
    restore()
    local calls = trapLog
    equals(#calls, 1, "one trap")
    equals(calls[1][1], "SendTrapTo", "aimed")
    check(calls[1].slot == 2 or calls[1].slot == 3, "at a partner")
    _G.apTrapLink.enabled = false
    apTrapLinkForgetPartner()
end)

test("a pact goes through the link when only other games were seen on it", function()
    _G.apTrapLink.enabled = true
    apTrapLinkForgetPartner()
    apTrapLinkReceive("Other game", "Ice Trap")
    local restore = trapStubs()
    check(apTrapLinkSendToOne("Archipelago Deal"), "sent")
    restore()
    local calls = trapLog
    equals(#calls, 1, "one trap")
    equals(calls[1][1], "SendTrap", "through the link")
    _G.apTrapLink.enabled = false
    apTrapLinkForgetPartner()
end)

test("a partner not heard for ten minutes is not aimed at any more", function()
    _G.apTrapLink.enabled = true
    apTrapLinkForgetPartner()
    apTrapLinkPartner("Nina", true, 2)
    apTrapLinkAgePartner(601)
    local restore = trapStubs()
    equals(apTrapLinkSendToOne("Archipelago Deal"), false, "no one left: the pact comes back")
    restore()
    equals(#trapLog, 0, "nothing sent")
    _G.apTrapLink.enabled = false
    apTrapLinkForgetPartner()
end)

test("a race a mod calls differently is recruited under the game's own name", function()
    sim.startRun(true)
    _G.apRaceNames = { anaerobic = "lanius" }
    local before = sim.player.vCrewList:size()
    check(apRecruitCrew("anaerobic"), "recruited")
    equals(sim.player.vCrewList[before].species, "lanius", "the game's own race")
    _G.apRaceNames = nil
end)

test("locked shops: a new sector's reset does not bring back what the seed locked", function()
    sim.weaponBlueprints.LOCK_TEST = 3
    sim.resetBlueprints()
    sim.net.shopLocks = {}
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apShopForgetSeed()
    apShopConfigure({ mode = "locked", deliver = false, baseline = { "LOCK_TEST" } })
    sim.startRun(true)
    local desc = sim.rarityFor("LOCK_TEST", 3)
    equals(sim.net.shopLocks.LOCK_TEST, true, "the stores leave it out")
    equals(desc.rarity, 3, "never a rarity of 0: a whole family at 0 crashes the game")
    equals(desc.baseRarity, 3, "in both fields")
    sim.newSectorRarities()
    equals(sim.net.shopLocks.LOCK_TEST, true, "a new map changes nothing to the lock")
    apApplyShopItem({ bp = "LOCK_TEST", n = 1, noDelivery = true })
    equals(sim.net.shopLocks.LOCK_TEST, nil, "received: on sale")
    check(desc.rarity > 0, "and in the random picks")
    sim.newSectorRarities()
    equals(desc.rarity, 3, "a received item survives the reset")
    sim.newSectorRarities({ LOCK_TEST = 0 })
    sim.tick(1)
    equals(desc.rarity, 3, "and the sector's own list, from the next tick")
    apShopForgetSeed()
    equals(desc.rarity, 3, "a new seed gets the game's rarity back")
    equals(desc.baseRarity, 3, "in both fields")
    _G.apShopConfig.mode = "rarity_boost"
    _G.apShopConfig.baseline = {}
end)

test("a system without its blueprint stays off the store shelves until it comes in", function()
    sim.resetBlueprints()
    sim.net.shopLocks = {}
    local unlocked, loaded = _G.apSystemUnlocked, _G.apSeedLoaded
    local owned = {}
    _G.apSystemUnlocked = function(name) return owned[name] == true end
    _G.apSeedLoaded = function() return true end
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplyShopRules()
    equals(sim.net.shopLocks.cloaking, true, "locked")
    owned.cloaking = true
    sim.tick(60)
    equals(sim.net.shopLocks.cloaking, nil, "the blueprint opens it within a second")
    _G.apSystemUnlocked, _G.apSeedLoaded = unlocked, loaded
    apShopForgetSeed()
end)

test("New Crew Member with the crew full: the player is told once and the dashboard counts it", function()
    sim.startRun(true)
    apNotifyResetForTesting()
    local full = sim.player.IsCrewFull
    sim.player.IsCrewFull = function() return true end
    apQueueItem({ kind = "filler", res = "crew", n = 1 })
    sim.jumpArrive()
    sim.tick(2)
    local function told()
        local count = 0
        for _, toast in ipairs(apToastsForTesting()) do
            if toast.text == apT("crew.waiting.new") then count = count + 1 end
        end
        return count
    end
    equals(told(), 1, "the player is told")
    apNotifyResetForTesting()
    sim.jumpArrive()
    sim.tick(2)
    equals(apOwedCrewCount(), 1, "it waits in the count")
    equals(told(), 0, "and it is not said again once the message has gone")
    sim.player.IsCrewFull = full
    sim.jumpArrive()
    sim.tick(2)
    equals(apOwedCrewCount(), 0, "and it boards once there is room")
end)
