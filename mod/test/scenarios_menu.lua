
local function catalog(weapons, crewList)
    apInventoryClear()
    for name, count in pairs(weapons or {}) do
        apInventory.shopAvailability[name] = count
    end
    for _, member in ipairs(crewList or {}) do
        apInventory.crew[#apInventory.crew + 1] = member
    end
end

local function menuShown()
    sim.renderGui()
    return sim.drawnText(apT("loadout.title"))
end

test("start-of-run menu: opens on a new run when something has been received", function()
    catalog({ LASER_BURST_3 = 2 })
    sim.startRun(true)
    check(menuShown(), "the Archipelago menu is on screen")
end)

test("start-of-run menu: not when resuming a saved game", function()
    catalog({ LASER_BURST_3 = 2 })
    sim.runVariables = {}
    sim.startRun(false)
    check(not menuShown(), "a resumed game keeps what it had already taken")
end)

test("start-of-run menu: back after quitting to the main menu before choosing", function()
    catalog({ LASER_BURST_3 = 2, BEAM_2 = 2 }, { { race = "energy" } })
    sim.startRun(true)
    menuShown()
    local before = sim.delivered()
    sim.click(apLoadoutPoint("row", "weapon", 1))
    sim.startRun(false)
    check(menuShown(), "the menu comes back on Continue")
    sim.click(apLoadoutPoint("row", "weapon", 2))
    equals(sim.delivered(), before + 1, "the weapon already taken still counts")
    local crew = sim.player.vCrewList:size()
    sim.click(apLoadoutPoint("row", "crew", 1))
    equals(sim.player.vCrewList:size(), crew + 1, "the crew member can still be taken")
end)

test("start-of-run menu: back even if the game was quit before it could show", function()
    catalog({ LASER_BURST_3 = 2 })
    sim.pauseOpen = true
    sim.startRun(true)
    check(not menuShown(), "hidden while the game is paused")
    sim.pauseOpen = false
    sim.startRun(false)
    check(menuShown(), "the menu shows on Continue")
end)

test("start-of-run menu: not reopened on a run from another seed", function()
    _G.apRunStartCheckForTesting = nil
    apContractResetForTesting()
    apApplySlotData({ contract = 2, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {},
                      seed_hash = "loadout-first" })
    sim.startRun(true)
    apContractResetForTesting()
    apApplySlotData({ contract = 2, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {},
                      seed_hash = "loadout-second" })
    catalog({ LASER_BURST_3 = 2 })
    sim.startRun(false)
    check(not menuShown(), "the run belongs to the first seed: no menu from the second")
    _G.apRunStartCheckForTesting = false
    check(menuShown(), "it is only waiting for a run that counts")
end)

test("start-of-run menu: closed for good once the run has jumped", function()
    catalog({ LASER_BURST_3 = 2 })
    sim.startRun(true)
    menuShown()
    sim.jumpArrive()
    sim.startRun(false)
    check(not menuShown(), "no menu after Continue")
end)

test("start-of-run menu: nothing to offer, nothing on screen", function()
    catalog({ LASER_BURST_3 = 1 })
    sim.startRun(true)
    check(not menuShown(), "a weapon received only once is not yet in the menu")
end)

test("start-of-run menu: a click gives the weapon, only one per run", function()
    catalog({ LASER_BURST_3 = 2, BEAM_2 = 2 })
    sim.startRun(true)
    menuShown()
    local before = sim.delivered()
    sim.click(apLoadoutPoint("row", "weapon", 1))
    equals(sim.delivered(), before + 1, "the weapon is delivered")
    sim.click(apLoadoutPoint("row", "weapon", 2))
    equals(sim.delivered(), before + 1, "the second weapon is refused: one per category")
    sim.renderGui()
    check(sim.drawnText(apT("loadout.chosen")), "the column says something was taken")
end)

test("start-of-run menu: the expert crew member arrives with their specialty", function()
    catalog({}, { { race = "energy", skill = "shields" } })
    sim.startRun(true)
    menuShown()
    local before = sim.player.vCrewList:size()
    sim.click(apLoadoutPoint("row", "crew", 1))
    equals(sim.player.vCrewList:size(), before + 1, "one more crew member")
    local recruit = sim.player.vCrewList[sim.player.vCrewList:size() - 1]
    equals(recruit.species, "energy", "a Zoltan")
    equals(recruit.maitrises[1], 2, "who has mastered shields")
end)

test("start-of-run menu: the first jump closes it", function()
    catalog({ LASER_BURST_3 = 2 })
    sim.startRun(true)
    check(menuShown(), "open at the start")
    sim.jumpArrive()
    check(not menuShown(), "closed after the first jump")
end)

test("start-of-run menu: Done closes it without taking anything", function()
    catalog({ LASER_BURST_3 = 2 })
    sim.startRun(true)
    menuShown()
    local before = sim.delivered()
    sim.click(apLoadoutPoint("done"))
    check(not menuShown(), "the button closes the menu")
    equals(sim.delivered(), before, "and nothing was given")
end)

test("items received outside a run: the catalog fills up, nothing arrives all at once at the start", function()
    apInventoryClear()
    apShopConfigure({ mode = "rarity_boost", deliver = true, baseline = {} })
    sim.started = false
    apQueueItem({ kind = "shop", bp = "LASER_BURST_3", display = "Burst Laser Mark II" })
    apQueueItem({ kind = "shop", bp = "LASER_BURST_3", display = "Burst Laser Mark II" })
    apQueueItem({ kind = "crew", race = "energy", skill = "shields", display = "Zoltan Shield Expert" })
    apDeliverPending()
    equals(apInventory.shopAvailability.LASER_BURST_3, 2, "both copies are counted")
    equals(#apInventory.crew, 1, "the crew member is in the catalog")

    local deliveredBefore = sim.delivered()
    local crewBefore = sim.player.vCrewList:size()
    sim.startRun(true)
    sim.tick(240)
    equals(sim.delivered(), deliveredBefore, "no weapon is given automatically at the start of the run")
    equals(sim.player.vCrewList:size(), crewBefore, "no crew member is added automatically")
    check(menuShown(), "everything waits in the start-of-run menu")
end)

test("start-of-run menu: the arrows change page", function()
    local weapons = {}
    for _, name in ipairs({ "LASER_BURST_3", "BEAM_2", "MISSILES_2" }) do weapons[name] = 2 end
    catalog(weapons)
    for index = 1, 9 do
        sim.weaponBlueprints["TEST_WEAPON_" .. index] = 3
        apInventory.shopAvailability["TEST_WEAPON_" .. index] = 2
    end
    sim.startRun(true)
    check(menuShown(), "open")
    check(sim.drawnText(apT("loadout.page", { n = 1, total = 2 })), "page 1 of 2 at the start")
    local nextX, nextY = apLoadoutPoint("next", "weapon")
    local rightArrow = nil
    for _, drawing in ipairs(sim.draws) do
        if drawing.text == ">" and math.abs(drawing.x - nextX) < 20 and math.abs(drawing.y - nextY) < 20 then
            rightArrow = drawing
        end
    end
    check(rightArrow ~= nil, "the > is drawn where you click")
    sim.click(nextX, nextY)
    sim.renderGui()
    check(sim.drawnText(apT("loadout.page", { n = 2, total = 2 })), "the right arrow moves to page 2")
    sim.click(apLoadoutPoint("previous", "weapon"))
    sim.renderGui()
    check(sim.drawnText(apT("loadout.page", { n = 1, total = 2 })), "the left arrow goes back to page 1")
end)

local function progressiveZoltan()
    apQueueItem({ kind = "crew", race = "energy", skill = "shields", tiers = 3,
                  display = "Progressive Zoltan Crew" })
    drain()
end

local function crewRows()
    local rows = {}
    for _, drawing in ipairs(sim.draws) do
        if drawing.x >= 784 and drawing.x < 784 + 250 and drawing.y >= 200 and drawing.y < 200 + 8 * 26 then
            rows[#rows + 1] = drawing.text
        end
    end
    return rows
end

test("progressive crew member: tier 1 aboard, not yet in the menu", function()
    catalog({})
    sim.startRun(true)
    local before = sim.player.vCrewList:size()
    progressiveZoltan()
    equals(sim.player.vCrewList:size(), before + 1, "a Zoltan joins the run")
    check(shownKey("crew.progress.aboard"), "and the player knows the next one will go to the menu")
    sim.startRun(true)
    check(not menuShown(), "only one copy: nothing in the menu")
end)

test("progressive crew member: tier 2 in the menu, tier 3 the expert replaces the normal one", function()
    catalog({})
    sim.startRun(true)
    progressiveZoltan()
    progressiveZoltan()
    sim.startRun(true)
    check(menuShown(), "two copies: the Zoltan is in the menu")
    local normal = crewRows()
    equals(#normal, 1, "one row for the species")

    progressiveZoltan()
    sim.startRun(true)
    menuShown()
    local expert = crewRows()
    equals(#expert, 1, "still only one row: the expert replaces the normal one")
    check(expert[1]:find(apT("crew.skill.shields"), 1, true), "and it's the shields expert")

    local before = sim.player.vCrewList:size()
    sim.click(apLoadoutPoint("row", "crew", 1))
    local recruit = sim.player.vCrewList[sim.player.vCrewList:size() - 1]
    equals(sim.player.vCrewList:size(), before + 1, "the click brings them aboard")
    equals(recruit.maitrises[1], 2, "with shields mastered")
end)

test("menu: the goal box steps aside while a question is open", function()
    applySeed({ goal = { kind = "victories", count = 3 } })
    local restore = stub("apConnectQuestionOpen", function() return true end)
    sim.renderMenu()
    restore()
    check(not sim.drawnText(apT("hud.goal", { n = 3 })), "no goal drawn over the question")
    sim.renderMenu()
    check(sim.drawnText(apT("hud.goal", { n = 3 })), "and it is back once the question is answered")
end)

test("start-of-run menu: behind the pause menu it does not catch clicks", function()
    catalog({ LASER_BURST_3 = 2, BEAM_2 = 2 })
    sim.startRun(true)
    menuShown()
    local before = sim.delivered()
    sim.pauseOpen = true
    sim.click(apLoadoutPoint("row", "weapon", 1))
    sim.pauseOpen = false
    equals(sim.delivered(), before, "a click meant for the pause menu gives nothing")
    sim.click(apLoadoutPoint("row", "weapon", 1))
    equals(sim.delivered(), before + 1, "once the pause menu is closed, the click works again")
end)
