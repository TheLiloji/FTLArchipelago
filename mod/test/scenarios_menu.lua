
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
    -- Seven weapons at five a page: two pages.
    for index = 1, 4 do
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

test("start-of-run menu: works in solo mode too", function()
    _G.apRunStartCheckForTesting = nil
    check(apSoloStart(true), "solo mode starts")
    catalog({ LASER_BURST_3 = 2 })
    sim.startRun(true)
    check(menuShown(), "a new run in solo gets the menu")
    sim.startRun(false)
    check(menuShown(), "and keeps it on Continue")
    apSoloStop()
    _G.apRunStartCheckForTesting = false
end)

test("start-of-run menu: each row shows the weapon, the drone or the race it gives", function()
    local first = next(sim.droneBlueprints)
    catalog({ LASER_BURST_3 = 2, [first] = 2 }, { { race = "energy" } })
    sim.images = {}
    sim.startRun(true)
    check(menuShown(), "open")
    local seen = {}
    for _, image in ipairs(sim.images) do seen[tostring(image.texture.name)] = image end
    check(seen[apGameData.weaponArt.LASER_BURST_3[1]] ~= nil, "the weapon's own art")
    local dronePath = apGameData.droneArt[first] or ("ship/drones/" .. first:lower() .. "_base.png")
    check(seen[dronePath] ~= nil, "the drone's picture")
    check(seen["people/energy_base.png"] ~= nil, "the race's sprite")
end)

test("start-of-run menu: a crew drone shows its sprite, a drone without a picture its drone bar icon", function()
    local saved = apGameData.droneArt
    apGameData.droneArt = { TEST_CREW_DRONE = "people/battle_base.png", TEST_ICON_DRONE = "systemUI/weapbox_icon_D_shield.png" }
    sim.droneBlueprints.TEST_CREW_DRONE, sim.droneBlueprints.TEST_ICON_DRONE = 2, 2
    catalog({ TEST_CREW_DRONE = 2, TEST_ICON_DRONE = 2 })
    sim.images = {}
    sim.startRun(true)
    check(menuShown(), "open")
    local crew, icon
    for _, image in ipairs(sim.images) do
        if image.texture.name == "people/battle_base.png" then crew = image end
        if image.texture.name == "systemUI/weapbox_icon_D_shield.png" then icon = image end
    end
    check(crew ~= nil and crew.part ~= nil and crew.part[2] < 1, "the crew drone: one frame of its sprite sheet")
    check(icon ~= nil, "the other: its drone bar icon")
    apGameData.droneArt = saved
    sim.droneBlueprints.TEST_CREW_DRONE, sim.droneBlueprints.TEST_ICON_DRONE = nil, nil
end)

test("start-of-run menu: a drone picture the game lacks falls back to the drone it draws, never to the warning sign", function()
    local saved = apGameData.droneArt
    apGameData.droneArt = { TEST_MOVED_DRONE = "ship/drones/moved_away_base.png" }
    sim.droneBlueprints.TEST_MOVED_DRONE = 2
    sim.missingImages = { ["ship/drones/moved_away_base.png"] = true }
    catalog({ TEST_MOVED_DRONE = 2 })
    sim.images = {}
    sim.startRun(true)
    check(menuShown(), "open")
    local fallback, warning
    for _, image in ipairs(sim.images) do
        if image.texture.name == "ship/drones/test_moved_drone_base.png" then fallback = image end
        if image.texture.name == "missing" then warning = image end
    end
    check(fallback ~= nil, "the drone the game itself would draw")
    check(warning == nil, "not the game's missing-file triangle")
    apGameData.droneArt = saved
    sim.droneBlueprints.TEST_MOVED_DRONE = nil
    sim.missingImages = nil
end)

local function systemsThatDoNotAllFit(limit)
    sim.hullPlaces = { [9] = true, [10] = true, [15] = true }
    _G.apInventory = { ships = {}, systemCaps = {}, blueprints = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ kinds = { "cap" }, options = { system_install = 1 } })
    for _, name in ipairs({ "teleporter", "cloaking", "hacking" }) do
        apQueueItem({ kind = "cap", sys = name, n = 0, display = name .. " blueprint" })
    end
    drain()
    sim.systemLimit, sim.mainSystemsUsed = limit, 0
    sim.startRun(true)
end

test("system install: more received systems than free slots, the player picks them in the start menu", function()
    systemsThatDoNotAllFit(2)
    equals(sim.player:HasSystem(9) or sim.player:HasSystem(10) or sim.player:HasSystem(15), false,
        "no fixed order decides: nothing comes aboard by itself")
    check(menuShown(), "the start-of-run menu opens with them")
    check(sim.drawnText(apT("loadout.column.system")), "in a column of their own")
    local labels = {}
    for _, name in ipairs(apSystemInstallChoices()) do labels[#labels + 1] = apSystemLabel(name) end
    table.sort(labels)
    sim.click(apLoadoutPoint("row", "system", 2))
    equals(#apSystemInstallChoices(), 2, "one picked, a slot is still free")
    sim.click(apLoadoutPoint("row", "system", 1))
    equals(#apSystemInstallChoices(), 0, "the second slot taken, nothing more to pick")
    equals(sim.mainSystemsUsed, 2, "two systems came aboard, the third waits for a store")
    sim.systemLimit, sim.mainSystemsUsed, sim.hullPlaces = nil, nil, nil
end)

test("system install: when they all fit, they all come aboard without asking", function()
    systemsThatDoNotAllFit(8)
    check(sim.player:HasSystem(9) and sim.player:HasSystem(10) and sim.player:HasSystem(15), "all three aboard")
    equals(#apSystemInstallChoices(), 0, "nothing to choose")
    sim.systemLimit, sim.mainSystemsUsed, sim.hullPlaces = nil, nil, nil
end)

test("system install: the choice is still there after a Continue", function()
    systemsThatDoNotAllFit(1)
    sim.startRun(false)
    sim.tick(1)
    equals(#apSystemInstallChoices(), 3, "the run's save keeps the systems to choose from")
    sim.systemLimit, sim.mainSystemsUsed, sim.hullPlaces = nil, nil, nil
end)

test("start-of-run menu: each weapon says its power and numbers, the store's text on hover", function()
    catalog({ LASER_BURST_3 = 2, MISSILES_2 = 2 })
    sim.blueprintStats = {
        LASER_BURST_3 = { power = 2, shots = 3, cooldown = 12, missiles = 0, damage = { iDamage = 1 } },
        MISSILES_2 = { power = 1, shots = 1, cooldown = 14, missiles = 1, damage = { iDamage = 2 } },
    }
    sim.rarityFor("LASER_BURST_3", 5).description = sim.textString("Fires three shots.")
    sim.startRun(true)
    check(menuShown(), "the menu is open")
    check(sim.drawnText(apT("loadout.power", { n = 2 })), "the burst laser's power on its row")
    check(sim.drawnText(apT("loadout.power", { n = 1 })), "and the missile launcher's")
    local x, y = apLoadoutPoint("row", "weapon", 1)
    local mouse = Hyperspace.Mouse
    Hyperspace.Mouse = { position = { x = x, y = y } }
    sim.renderGui()
    Hyperspace.Mouse = mouse
    check(sim.drawnText("Fires three shots."), "hovering shows the store's description")
    check(sim.drawnText(apT("loadout.power", { n = 2 }) .. ", "
        .. apT("loadout.weapon.stats", { damage = 1, shots = 3, cooldown = 12 })), "and all its numbers")
    x, y = apLoadoutPoint("row", "weapon", 2)
    Hyperspace.Mouse = { position = { x = x, y = y } }
    sim.renderGui()
    Hyperspace.Mouse = mouse
    check(sim.drawnText(apT("loadout.power", { n = 1 }) .. ", "
        .. apT("loadout.weapon.missile", { damage = 2, shots = 1, cooldown = 14 })), "a missile launcher says it uses missiles")
    sim.blueprintStats = nil
end)

test("Multiverse ship without Oxygen: the start menu offers it for free, even without System Install", function()
    _G.apInventory = { ships = {}, systemCaps = {}, blueprints = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ kinds = { "cap" } })
    sim.hullPlaces = { [2] = true }
    sim.systemLimit, sim.mainSystemsUsed = 8, 0
    sim.startRun(true)
    equals(sim.player:HasSystem(2), false, "not put aboard by itself: the player may leave it")
    equals(table.concat(apSystemInstallChoices(), ","), "oxygen", "offered in the start-of-run menu")
    check(menuShown(), "the menu opens for it")
    sim.click(apLoadoutPoint("row", "system", 1))
    check(sim.player:HasSystem(2), "picked: Oxygen comes aboard")
    sim.systemLimit, sim.mainSystemsUsed, sim.hullPlaces = nil, nil, nil
end)

test("a ship that starts with Oxygen is offered nothing", function()
    _G.apInventory = { ships = {}, systemCaps = {}, blueprints = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ kinds = { "cap" } })
    sim.hullPlaces = { [2] = true }
    sim.player._systemsHeld = { [2] = true }
    sim.startRun(true)
    equals(#apSystemInstallChoices(), 0, "Oxygen is already aboard")
    sim.hullPlaces = nil
end)
