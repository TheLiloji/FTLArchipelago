local DASH = { x = 140, y = 56, w = 1000, h = 608 }
local DASH_PAGES = { "overview", "ships", "systems", "checks", "journal" }

local function dashboardSeed()
    applySeed({
        goal = { kind = "victories", count = 3 },
        items = {},
        loc = {
            ["shop:1"] = "Archipelago Shop 1", ["shop:2"] = "Archipelago Shop 2",
            ["PLAYER_SHIP_HARD:sector:2"] = "Kestrel Cruiser A: Reach sector 2",
            ["PLAYER_SHIP_HARD:victory"] = "Kestrel Cruiser A: Defeat the Flagship",
            ["sys:shields"] = "Install Shields", ["crew:engi"] = "First Engi aboard",
        },
        links = { death = { enabled = true, trigger = "both", effect = "fire" },
                  energy = { enabled = false }, trap = { enabled = true } },
    })
end

local function openDashboard(page)
    if not apDashboardOpen() then apToggleHud() end
    apDashboardPage(page)
    sim.renderGui()
end

local function closeDashboard()
    if apDashboardOpen() then apToggleHud() end
end

local function overflowing()
    local out = {}
    for _, draw in ipairs(sim.draws) do
        local right = draw.x + (draw.maxWidth or 0)
        if draw.x < DASH.x or right > DASH.x + DASH.w or draw.y < DASH.y or draw.y > DASH.y + DASH.h then
            out[#out + 1] = draw.text
        end
    end
    return out
end

test("dashboard: every page stays inside the window, in every language", function()
    sim.startRun(true)
    dashboardSeed()
    _G.apInventory.ships = { "PLAYER_SHIP_HARD", "PLAYER_SHIP_HARD_2" }
    apRecordReceived("A very long item name that would not fit anywhere at all", "SomeoneWithALongName")
    for _, code in ipairs({ "en", "fr", "de", "es", "it", "pt" }) do
        apLangSet(code, "test")
        for _, page in ipairs(DASH_PAGES) do
            openDashboard(page)
            check(sim.errors == 0, code .. "/" .. page .. ": drawn without error")
            local out = overflowing()
            equals(#out, 0, code .. "/" .. page .. ": no text leaves the window (" .. tostring(out[1]) .. ")")
            check(#sim.draws > 5, code .. "/" .. page .. ": the page draws something")
        end
    end
    apLangSet("en", "test")
    closeDashboard()
end)

test("dashboard: TAB opens it in a run, pauses the game, and TAB closes it", function()
    sim.startRun(true)
    local gui = Hyperspace.App.gui
    gui.bPaused = false
    sim.keyDown(Defines.SDL.KEY_TAB)
    check(apDashboardOpen(), "TAB opens the dashboard")
    equals(gui.bPaused, true, "the game is paused behind it")
    sim.keyDown(Defines.SDL.KEY_TAB)
    check(not apDashboardOpen(), "TAB closes it")
    equals(gui.bPaused, false, "and the game resumes as it was")
end)

test("dashboard: a game already paused stays paused when it closes", function()
    sim.startRun(true)
    local gui = Hyperspace.App.gui
    gui.bPaused = true
    apToggleHud()
    apToggleHud()
    equals(gui.bPaused, true, "the player's own pause is kept")
end)

test("dashboard: arrows, digits and clicks on tabs change page; Esc and a click outside close", function()
    sim.startRun(true)
    dashboardSeed()
    openDashboard("overview")
    sim.keyDown(Defines.SDL.KEY_RIGHT)
    sim.renderGui()
    check(sim.drawnText(apT("dash.ships.header", { done = 0, total = 28 }):sub(1, 10)), "right arrow: ships page")
    sim.keyDown(Defines.SDL.KEY_LEFT)
    sim.keyDown(Defines.SDL.KEY_LEFT)
    sim.renderGui()
    check(sim.drawnText(apT("dash.journal.items")), "left arrow wraps around to the journal")
    sim.keyDown(Defines.SDL.KEY_4)
    sim.renderGui()
    check(sim.drawnText(apT("dash.cat.shop")), "4 opens the checks page")

    local tabW = math.floor((DASH.w - 32 - 6 * 4) / 5)
    sim.click(DASH.x + 16 + (tabW + 6) * 2 + 10, DASH.y + 60)
    sim.renderGui()
    check(sim.drawnText(apT("dash.system.locked")), "a click on the third tab opens the systems page")

    sim.keyDown(Defines.SDL.KEY_ESCAPE)
    check(not apDashboardOpen(), "Esc closes it")
    openDashboard("overview")
    sim.click(20, 20)
    check(not apDashboardOpen(), "a click outside closes it")
end)

test("dashboard: the overview gathers the goal, the checks, the links and the latest items", function()
    sim.startRun(true)
    apVictoriesResetForTesting()
    dashboardSeed()
    apSendCheck("shop:1", "test")
    apRecordReceived("Burst Laser II", "Axel")
    openDashboard("overview")
    check(sim.drawnText("defeat the Flagship 3 times"), "the goal and where it stands")
    check(sim.drawnText(apT("dash.checks.count", { done = 1, total = 6 })), "the checks sent out of the seed's")
    check(sim.drawnText("DeathLink") and sim.drawnText("TrapLink"), "the active links")
    check(not sim.drawnText("EnergyLink"), "and not the inactive one")
    check(sim.drawnText("Burst Laser II"), "the latest item")
    check(sim.drawnText(apT("dash.recent.from", { sender = "Axel" })), "with who sent it")
    closeDashboard()
end)

test("dashboard: without a seed the overview says so instead of zeros", function()
    apContractResetForTesting()
    sim.startRun(true)
    openDashboard("overview")
    check(sim.drawnText(apT("hud.no_seed")), "no seed loaded is stated")
    check(sim.drawnText(apT("dash.status.noseed")), "and the header agrees")
    closeDashboard()
end)

test("dashboard: the ships page shows the unlocked layouts and the checks left per class", function()
    sim.startRun(true)
    dashboardSeed()
    _G.apInventory.ships = { "PLAYER_SHIP_HARD" }
    openDashboard("ships")
    check(sim.drawnText(apT("dash.ships.header", { done = 1, total = 28 })), "one layout out of twenty-eight")
    check(sim.drawnText(apT("dash.ships.remaining", { n = 2 })), "the Kestrel still has its two checks")
    check(sim.drawnText(apT("dash.ships.type", { letter = "C" })), "layouts are named by type")
    closeDashboard()
end)

test("dashboard: the systems page tells locked, levels and head starts apart", function()
    sim.startRun(true)
    dashboardSeed()
    _G.apInventory.systemCaps = { shields = 3, cloaking = 2 }
    _G.apInventory.blueprints = { shields = true }
    _G.apInventory.startingUpgrades = { shields = 1, reactor = 2 }
    openDashboard("systems")
    check(sim.drawnText(apT("dash.systems.header", { done = 1, total = 16 })),
        "one system unlocked out of sixteen: cloaking has a level but no blueprint")
    check(sim.drawnText(apT("dash.system.locked")), "the others are locked")
    check(sim.drawnText(apT("dash.system.start", { n = 1 })), "the head start is shown on its system")
    check(sim.drawnText(apT("dash.systems.reactor", { n = 2 })), "and the reactor bonus in the header")
    closeDashboard()
end)

test("dashboard: each system card shows FTL's icon, green once usable, grey while locked", function()
    sim.startRun(true)
    dashboardSeed()
    _G.apInventory.systemCaps = { shields = 3, cloaking = 2 }
    _G.apInventory.blueprints = { shields = true }
    sim.images = {}
    openDashboard("systems")
    local drawn = {}
    for _, image in ipairs(sim.images) do
        if type(image.texture) == "table" then drawn[image.texture.name] = (drawn[image.texture.name] or 0) + 1 end
    end
    check(drawn["icons/s_shields_green1.png"], "shields, blueprint received: green")
    check(drawn["icons/s_cloaking_grey1.png"], "cloaking, a level but no blueprint: grey")
    local icons = 0
    for name in pairs(drawn) do
        if name:find("^icons/s_") then icons = icons + 1 end
    end
    equals(icons, 16, "one icon per system")
    closeDashboard()
end)

local function sameColorTone(drawn, tone)
    local c = (_G.apUi or {}).COLOR and apUi.COLOR[tone]
    return drawn ~= nil and c ~= nil and drawn.r == c[1] and drawn.g == c[2] and drawn.b == c[3]
end

local function boxDraw(value, color)
    for _, draw in ipairs(sim.draws) do
        if draw.text == value and draw.size == 9 and (color == nil or sameColorTone(draw.color, color)) then
            return draw
        end
    end
end

-- Points the mouse at a box of the checks grid and draws the page again.
local function pointAt(draw)
    Hyperspace.Mouse = { position = { x = draw.x + 2, y = draw.y + 3 } }
    sim.renderGui()
    Hyperspace.Mouse = nil
end

test("dashboard: the checks page draws a box per check, and pointing at one names it", function()
    sim.startRun(true)
    local loc = {}
    for i = 1, 60 do loc["shop:" .. i] = string.format("Archipelago Shop %02d", i) end
    loc["sys:shields"] = "Install Shields"
    loc["sys:shields:2"] = "Shields Level 2"
    applySeed({ items = {}, loc = loc })
    _G.apShopConfig.owners, _G.apShopConfig.sectors = nil, nil
    apSendCheck("shop:1", "test")
    openDashboard("checks")
    check(sim.drawnText(apT("dash.checks.remaining", { n = 59 })), "59 shop slots left")
    check(sim.drawnText(apT("dash.checks.any_ship")), "a shop sold anywhere has one row for any ship")
    check(boxDraw("2") ~= nil and boxDraw("60") ~= nil, "a box per slot, all of them on screen")
    check(not sim.drawnText("Archipelago Shop 02"), "names wait for the mouse")
    check(sim.drawnText(apT("dash.checks.hover")), "and the page says so")
    pointAt(boxDraw("2"))
    check(sim.drawnText("Archipelago Shop 02"), "pointing at a box names its check")

    local rowH = 46
    sim.click(DASH.x + 20 + 40, DASH.y + 96 + (rowH + 6) + 10)
    sim.renderGui()
    check(sim.drawnText(apSystemLabel("shields")), "the systems category has a row per system")
    check(boxDraw("1") ~= nil and boxDraw("2") ~= nil, "with a box per level, the install first")
    closeDashboard()
end)

test("dashboard: a check done turns its box green and tells what it gave", function()
    sim.startRun(true)
    applySeed({ items = {}, loc = { ["shop:1"] = "Archipelago Shop 1", ["shop:2"] = "Archipelago Shop 2",
                                    ["PLAYER_SHIP_HARD:sector:2"] = "Kestrel Cruiser A: Reach sector 2" } })
    _G.apShopConfig.owners, _G.apShopConfig.sectors = nil, nil
    apShopGiftsConfigure({ { location = "shop:1", slot = "Axel", item = "Glaive Beam", kind = "useful" },
                           { location = "shop:2", slot = "Axel", item = "Hull Repair", kind = "filler" } })
    apSendCheck("shop:1", "test")
    openDashboard("checks")
    local done = boxDraw("1")
    check(done ~= nil and sameColorTone(done.color, "window"), "the box done is drawn on green")
    check(sameColorTone(boxDraw("2") and boxDraw("2").color, "text"), "the one left is not")
    pointAt(done)
    check(sim.drawnText(apT("dash.checks.gave", { item = "Glaive Beam", slot = "Axel" })),
        "a shop slot bought still says what it held and for whom")
    pointAt(boxDraw("2"))
    check(not sim.drawnText("Hull Repair"), "one not bought yet keeps its secret")
    closeDashboard()

    apSendCheck("shop:2", "test")
    openDashboard("checks")
    check(sim.drawnText(apT("dash.checks.all_done")), "a category all done says so")
    closeDashboard()
end)

test("dashboard: first crew members get a card each, with the race's sprite", function()
    sim.startRun(true)
    applySeed({ items = {}, loc = { ["crew:engi"] = "First Engi aboard", ["crew:mantis"] = "First Mantis aboard" } })
    apSendCheck("crew:mantis", "test")
    sim.images = {}
    openDashboard("checks")
    check(sim.drawnText(apRaceLabel("engi")), "the card names the race as the game does")
    check(not sim.drawnText("First Engi aboard"), "not the English location name")
    local engi, mantis
    for _, image in ipairs(sim.images) do
        if image.texture.name == "people/engi_base.png" then engi = image end
        if image.texture.name == "people/mantis_base.png" then mantis = image end
    end
    check(engi ~= nil and mantis ~= nil, "each race shows its own sprite")
    check(engi ~= nil and engi.part[1] == 0 and engi.part[3] == 0 and engi.part[2] < 0.1,
        "only the first frame of the sheet")
    check(engi ~= nil and mantis ~= nil and engi.alpha < mantis.alpha, "a race not met yet is faded")
    check(sim.drawnText(apT("dash.crew.waiting")) and sim.drawnText(apT("dash.crew.done")),
        "each card says whether the race came aboard")
    closeDashboard()
end)

test("dashboard: Multiverse's eighteen races all fit on the crew page", function()
    sim.startRun(true)
    local loc = {}
    for _, race in ipairs({ "human", "engi", "energy", "mantis", "rock", "slug", "anaerobic", "crystal", "orchid",
                            "shell", "leech", "phantom", "spider", "lizard", "cognitive", "siren", "pony", "obelisk" }) do
        loc["crew:" .. race] = "First " .. race .. " aboard"
    end
    applySeed({ items = {}, loc = loc })
    sim.images = {}
    openDashboard("checks")
    local sprites = 0
    for _, image in ipairs(sim.images) do
        if tostring(image.texture.name):match("^people/") then sprites = sprites + 1 end
    end
    equals(sprites, 18, "every race on screen, no scrolling needed")
    check(#overflowing() == 0, "and nothing leaves the window")
    closeDashboard()
end)

local function imagesNamed(pattern)
    local found = {}
    for _, image in ipairs(sim.images) do
        if tostring(image.texture.name):match(pattern) then found[#found + 1] = image end
    end
    return found
end

test("dashboard: achievements show their game icon, faded until done", function()
    sim.startRun(true)
    applySeed({ items = {}, loc = { ["ach:ACH_FULL_ARSENAL"] = "The Kestrel: Full Arsenal",
                                    ["ach:ACH_TOUGH_SHIP"] = "The Kestrel: Tough Little Ship",
                                    ["ach:ACH_BURNING"] = "Achievement: Burning" } })
    apSendCheck("ach:ACH_TOUGH_SHIP", "test")
    sim.images = {}
    openDashboard("checks")
    local function icon(id)
        local path = apGameData.achievementImages[id]
        for _, image in ipairs(sim.images) do
            if image.texture.name == path then return image end
        end
    end
    check(icon("ACH_FULL_ARSENAL") and icon("ACH_TOUGH_SHIP") and icon("ACH_BURNING"), "each achievement has its icon")
    check(icon("ACH_TOUGH_SHIP").alpha > icon("ACH_FULL_ARSENAL").alpha, "the one done is in full colour")
    check(sim.drawnText(apT("dash.checks.general")), "general achievements have their own card")
    check(#overflowing() == 0, "nothing leaves the window")
    sim.gameTexts.ACH_BURNING_name = "Pyromane"
    pointAt(icon("ACH_BURNING"))
    check(sim.drawnText("Pyromane"), "pointing at an achievement names it in the game's language")
    check(not sim.drawnText("Achievement: Burning"), "not with the seed's English location name")
    sim.gameTexts.ACH_BURNING_name = nil
    closeDashboard()
end)

test("dashboard: victories show each layout's ship, in colour once won", function()
    sim.startRun(true)
    applySeed({ items = {}, loc = { ["PLAYER_SHIP_HARD:victory"] = "Kestrel Cruiser A: Defeat the Flagship",
                                    ["PLAYER_SHIP_HARD_2:victory"] = "Kestrel Cruiser B: Defeat the Flagship" } })
    apSendCheck("PLAYER_SHIP_HARD_2:victory", "test")
    sim.images = {}
    openDashboard("checks")
    local minis = imagesNamed("^customizeUI/miniship_")
    equals(#minis, 2, "one ship picture per layout")
    local a, b
    for _, image in ipairs(minis) do
        if image.texture.name == "customizeUI/miniship_player_ship_hard.png" then a = image end
        if image.texture.name == "customizeUI/miniship_player_ship_hard_2.png" then b = image end
    end
    check(a ~= nil and b ~= nil, "each layout shows its own picture")
    check(a ~= nil and b ~= nil and b.alpha > a.alpha, "the layout won is in full colour")
    check(sim.drawnText(apT("dash.ships.type", { letter = "B" })), "and its letter")
    closeDashboard()
end)

test("dashboard: a seed with one ship keeps its card a normal height", function()
    sim.startRun(true)
    applySeed({ items = {}, loc = { ["PLAYER_SHIP_HARD:victory"] = "Kestrel Cruiser A: Defeat the Flagship" } })
    local saved = _G.apGameData.ships
    _G.apGameData.ships = { { name = "PLAYER_SHIP_HARD", layouts = 1 } }
    sim.rects = {}
    openDashboard("ships")
    local tallest = 0
    for _, r in ipairs(sim.rects) do
        if r.w < DASH.w - 100 then tallest = math.max(tallest, r.h) end
    end
    _G.apGameData.ships = saved
    check(tallest <= 120, "no card stretched over the whole page (" .. tallest .. ")")
    closeDashboard()
end)

test("dashboard: rows go ship flown, then what counts on any ship, then the other ships", function()
    sim.startRun(true)
    applySeed({ items = {}, loc = { ["sys:shields"] = "Install Shields",
                                    ["PLAYER_SHIP_CIRCLE:sys:cloaking"] = "Engi Cruiser: Install Cloaking",
                                    ["PLAYER_SHIP_HARD:sys:cloaking"] = "Kestrel Cruiser: Install Cloaking" } })
    openDashboard("checks")
    local y = {}
    for _, draw in ipairs(sim.draws) do
        for _, name in ipairs({ apShipLabel("PLAYER_SHIP_HARD"), apSystemLabel("shields"), apShipLabel("PLAYER_SHIP_CIRCLE") }) do
            if draw.text == name and draw.size == 10 and draw.x > DASH.x + 300 then y[name] = y[name] or draw.y end
        end
    end
    local kestrel, shields, engi = y[apShipLabel("PLAYER_SHIP_HARD")], y[apSystemLabel("shields")], y[apShipLabel("PLAYER_SHIP_CIRCLE")]
    check(kestrel and shields and engi and kestrel < shields and shields < engi,
        "Kestrel, then Shields, then the Engi Cruiser, whatever the names")
    closeDashboard()
end)

test("dashboard: the ships page shows each layout's picture, faded until unlocked", function()
    sim.startRun(true)
    dashboardSeed()
    _G.apInventory.ships = { "PLAYER_SHIP_HARD" }
    sim.images = {}
    openDashboard("ships")
    local a, b
    for _, image in ipairs(sim.images) do
        if image.texture.name == "customizeUI/miniship_player_ship_hard.png" then a = image end
        if image.texture.name == "customizeUI/miniship_player_ship_hard_2.png" then b = image end
    end
    check(a ~= nil and b ~= nil, "the Kestrel's layouts have their pictures")
    check(a ~= nil and b ~= nil and a.alpha > b.alpha, "the layout unlocked is in colour, the other faded")
    closeDashboard()
end)

test("dashboard: a category on the overview opens it on the checks page", function()
    sim.startRun(true)
    dashboardSeed()
    openDashboard("overview")
    local target
    for _, draw in ipairs(sim.draws) do
        if draw.text == apT("dash.cat.victory") then target = draw end
    end
    check(target ~= nil, "the victories are listed on the overview")
    sim.click(target.x + 4, target.y + 4)
    sim.renderGui()
    check(sim.drawnText(apT("dash.checks.remaining", { n = 1 })) and sim.drawnText(apT("dash.ships.type", { letter = "A" })),
        "the click opens the checks page on the victories")
    closeDashboard()
end)

test("dashboard: the ship flown comes first, with what is left for it and in this sector", function()
    sim.startRun(true)
    applySeed({ items = {}, loc = {
        ["PLAYER_SHIP_CIRCLE:sector:2"] = "Engi Cruiser A: Reach sector 2",
        ["PLAYER_SHIP_HARD:sector:2"] = "Kestrel Cruiser A: Reach sector 2",
        ["PLAYER_SHIP_HARD:sector:3"] = "Kestrel Cruiser A: Reach sector 3",
        ["PLAYER_SHIP_HARD_2:sector:2"] = "Kestrel Cruiser B: Reach sector 2",
        ["shop:1"] = "Archipelago Shop 1", ["shop:2"] = "Archipelago Shop 2", ["shop:3"] = "Archipelago Shop 3",
        ["shop:4"] = "Archipelago Shop 4",
    } })
    _G.apShopConfig.owners = { "PLAYER_SHIP_HARD", "PLAYER_SHIP_CIRCLE" }
    _G.apShopConfig.sectors = 2
    openDashboard("checks")
    local kestrel = apShipLabel("PLAYER_SHIP_HARD")
    check(sim.drawnText(apT("dash.checks.ship", { ship = kestrel })), "the banner names the ship flown")
    check(sim.drawnText(apT("dash.checks.remaining", { n = 2 })), "the Kestrel has two shop slots left")
    check(sim.drawnText(apT("dash.checks.ship_sector", { n = 1 })), "one of them sold in this sector")
    local kestrelY, engiY
    for _, draw in ipairs(sim.draws) do
        if draw.text == kestrel then kestrelY = kestrelY or draw.y end
        if draw.text == apShipLabel("PLAYER_SHIP_CIRCLE") then engiY = engiY or draw.y end
    end
    check(kestrelY ~= nil and engiY ~= nil and kestrelY < engiY, "the ship flown is the first row")

    sim.click(DASH.x + 20 + 40, DASH.y + 96 + 46 + 6 + 10)
    sim.renderGui()
    check(sim.drawnText(apT("dash.checks.ship", { ship = kestrel .. " A" })), "sectors are counted per layout")
    check(sim.drawnText(apT("dash.checks.remaining", { n = 2 })), "the layout A has two sectors left")
    check(sim.drawnText(kestrel .. " B"), "the layout B has its own row")
    apSendCheck("PLAYER_SHIP_HARD:sector:2", "test")
    apSendCheck("PLAYER_SHIP_HARD:sector:3", "test")
    sim.renderGui()
    check(sim.drawnText(apT("dash.checks.ship_clear")), "nothing left for this ship: the banner says so")
    _G.apShopConfig.owners, _G.apShopConfig.sectors = nil, nil
    closeDashboard()
end)

test("dashboard: the journal keeps the items received, newest first, and the hints", function()
    sim.startRun(true)
    dashboardSeed()
    _G.apReceivedHistory = {}
    apRecordReceived("First Item", nil)
    apRecordReceived("Second Item", "Axel")
    apHintReceived({ item = "Glaive Beam", location = "Archipelago Shop 2", solo = true })
    openDashboard("journal")
    local first, second
    for index, draw in ipairs(sim.draws) do
        if draw.text == "Second Item" then second = draw.y end
        if draw.text == "First Item" then first = draw.y end
    end
    check(second ~= nil and first ~= nil and second < first, "the newest item is on top")
    check(sim.drawnText("Glaive Beam"), "the hint is listed")
    closeDashboard()
end)

test("dashboard: a bundle in the journal lists what it brought", function()
    sim.startRun(true)
    applySeed({ items = { ["Drone Bundle 2"] = { k = "bundle", bps = { "COMBAT_1", "DEFENSE_1" },
                                                 names = { "Combat Drone I", "Defense Drone I" }, c = "u" } } })
    _G.apReceivedHistory = {}
    apReceiveItem("Drone Bundle 2", "Axel")
    openDashboard("journal")
    local bundle, member
    for _, draw in ipairs(sim.draws) do
        if draw.text == "Drone Bundle 2" then bundle = draw end
        if draw.text == "Defense Drone I" then member = draw end
    end
    check(bundle ~= nil and member ~= nil, "the bundle and its drones are listed")
    check(bundle ~= nil and member ~= nil and member.y > bundle.y and member.x > bundle.x,
        "each drone under the bundle, set in")
    check(sim.drawnText("Combat Drone I"), "every one of them")
    closeDashboard()
end)

test("dashboard: a delivered item goes into the journal, a replayed one does not", function()
    sim.startRun(true)
    applySeed({ items = { ["50 Scrap"] = { k = "filler", res = "scrap", n = 50 } } })
    _G.apReceivedHistory = {}
    apReceiveItem("50 Scrap", "Axel")
    apReceiveItem("50 Scrap", "Axel", true)
    equals(#_G.apReceivedHistory, 1, "only the new item is recorded")
    equals(_G.apReceivedHistory[1].sender, "Axel", "with its sender")
end)

local function drawnColor(value)
    for _, draw in ipairs(sim.draws) do
        if draw.text == value then return draw.color end
    end
end

local function sameColor(drawn, tone)
    local c = (_G.apUi or {}).COLOR and apUi.COLOR[tone]
    return drawn ~= nil and c ~= nil and drawn.r == c[1] and drawn.g == c[2] and drawn.b == c[3]
end

test("dashboard: the journal colours each item by its Archipelago class, guessed for an older seed", function()
    sim.startRun(true)
    applySeed({ items = {
        ["Kestrel Key"] = { k = "ship", ship = "PLAYER_SHIP_HARD", c = "p" },
        ["Glaive Beam"] = { k = "weapon", bp = "BEAM_3", c = "u" },
        ["Breach Trap"] = { k = "trap", eff = "breach", c = "t" },
        ["50 Scrap"] = { k = "filler", res = "scrap", n = 50, c = "f" },
        ["Old Archive"] = { k = "archive" },
        ["Old Trap"] = { k = "trap", eff = "fire" },
    } })
    _G.apReceivedHistory = {}
    for _, name in ipairs({ "Kestrel Key", "Glaive Beam", "Breach Trap", "50 Scrap", "Old Archive", "Old Trap" }) do
        apReceiveItem(name, "Axel")
    end
    openDashboard("journal")
    check(sameColor(drawnColor("Kestrel Key"), "good"), "progression is green")
    check(sameColor(drawnColor("Glaive Beam"), "useful"), "useful is blue")
    check(sameColor(drawnColor("Breach Trap"), "bad"), "a trap is red")
    check(sameColor(drawnColor("50 Scrap"), "dim"), "filler is grey")
    check(sameColor(drawnColor("Old Archive"), "good"), "a seed without classes: an archive reads as progression")
    check(sameColor(drawnColor("Old Trap"), "bad"), "and a trap as a trap")
    check(sim.drawnText(apT("dash.class.t")), "the colours are explained on the page")
    closeDashboard()
end)

test("journal: an item's class survives a restart, and a journal saved before classes still loads", function()
    sim.startRun(true)
    sim.durable = {}
    applySeed({ seed_hash = "journal-class", items = { ["Breach Trap"] = { k = "trap", eff = "breach", c = "t" } } })
    _G.apReceivedHistory = {}
    apReceiveItem("Breach Trap", "Axel")
    local key = "ap_journal_" .. tostring(apSeedFingerprint())
    sim.durable[key] = sim.durable[key] .. "\30Glaive Beam\31Axel"

    _G.apReceivedHistory = {}
    apContractResetForTesting()
    applySeed({ seed_hash = "journal-class", items = { ["Breach Trap"] = { k = "trap", eff = "breach", c = "t" } } })
    openDashboard("journal")
    check(sameColor(drawnColor("Breach Trap"), "bad"), "the trap is still red after the restart")
    check(drawnColor("Glaive Beam") ~= nil, "an entry from an older journal is still listed")
    equals(_G.apReceivedHistory[2].sender, "Axel", "with its sender")
    closeDashboard()
end)

test("dashboard: a system already on the ship counts its upgrades, its blueprint missing", function()
    applySeed({ caps = { shields = 7 } })
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    sim.startRun(true)
    apToggleHud()
    apDashboardPage(3)
    sim.renderGui()
    apToggleHud()
    check(sim.drawnText(apT("dash.system.aboard", { received = 0, total = 7 })),
        "shields on the ship read 0/7, blueprint missing, like the other systems")
    check(sim.drawnText(apT("dash.system.locked")), "and a system the ship lacks still reads as locked")
end)

test("dashboard: the ships page only lists the seed's layouts", function()
    sim.startRun(true)
    applySeed({
        goal = { kind = "victories", count = 1 },
        layouts = { "PLAYER_SHIP_HARD", "PLAYER_SHIP_ROCK", "PLAYER_SHIP_ROCK_3" },
        loc = { ["PLAYER_SHIP_HARD:victory"] = "Kestrel Cruiser A: Defeat the Flagship" },
    })
    _G.apInventory.ships = { "PLAYER_SHIP_HARD" }
    openDashboard("ships")
    check(sim.drawnText(apT("dash.ships.header", { done = 1, total = 3 })), "three layouts in the seed")
    check(not sim.drawnText(apShipLabel("PLAYER_SHIP_MANTIS")), "a ship left out is not listed")
    check(sim.drawnText(apT("dash.ships.type", { letter = "C" })), "the Rock C is")
    closeDashboard()
end)

test("dashboard: Multiverse ships come from the seed, not from the base game's list", function()
    sim.startRun(true)
    applySeed({
        goal = { kind = "victories", count = 1 },
        multiverse = true,
        layouts = { "PLAYER_SHIP_MVKESTREL", "PLAYER_SHIP_UNION", "PLAYER_SHIP_UNION_2" },
        loc = { ["PLAYER_SHIP_UNION_2:victory"] = "Union Cruiser B: Defeat the Flagship" },
    })
    _G.apInventory.ships = { "PLAYER_SHIP_MVKESTREL" }
    -- Multiverse's ships are not in the base game's ftl.dat, the fake only knows them here.
    sim.shipNames.PLAYER_SHIP_UNION, sim.shipClasses.PLAYER_SHIP_UNION = "Chrysippus", "Union Cruiser"
    openDashboard("ships")
    check(sim.drawnText(apT("dash.ships.header", { done = 1, total = 3 })), "three Multiverse layouts")
    check(sim.drawnText(apShipLabel("PLAYER_SHIP_UNION")), "the Union Cruiser has its row")
    check(sim.drawnText("Union Cruiser"), "under its class, as the seed names it")
    check(not sim.drawnText("Chrysippus"), "not under the name of the ship itself")
    check(sim.drawnText(apT("dash.ships.remaining", { n = 1 })), "with its check left")
    closeDashboard()
end)

test("dashboard: a Multiverse ship shows the race of most of its crew, a base game seed does not", function()
    sim.startRun(true)
    applySeed({
        goal = { kind = "victories", count = 1 },
        multiverse = true,
        layouts = { "PLAYER_SHIP_ZOLTAN", "PLAYER_SHIP_UNION" },
    })
    sim.shipNames.PLAYER_SHIP_ZOLTAN, sim.shipClasses.PLAYER_SHIP_ZOLTAN = "Paragon", "Ministry Cruiser"
    sim.shipNames.PLAYER_SHIP_UNION, sim.shipClasses.PLAYER_SHIP_UNION = "Chrysippus", "Union Cruiser"
    sim.shipCrews = { PLAYER_SHIP_ZOLTAN = { "human", "zoltan", "zoltan" }, PLAYER_SHIP_UNION = {} }
    sim.crewTitles = { zoltan = "Zoltan", human = "Human" }
    openDashboard("ships")
    check(sim.drawnText("Zoltan"), "the Ministry Cruiser is flown by Zoltans")
    check(not sim.drawnText("Human"), "the race of most of the crew, not the first one")
    closeDashboard()
    equals(apShipSpecies("PLAYER_SHIP_UNION"), nil, "a ship without a crew list shows no race")
    sim.shipNames.PLAYER_SHIP_MILITIA = "Militia"
    sim.shipCrews.PLAYER_SHIP_MILITIA = { "human", "LIST_CREW_MILITIA_RANDOM", "LIST_CREW_MILITIA_RANDOM" }
    sim.crewTitles.LIST_CREW_MILITIA_RANDOM = "Rock"
    equals(apShipSpecies("PLAYER_SHIP_MILITIA"), nil, "a crew drawn from a random list shows no race")

    applySeed({ goal = { kind = "victories", count = 1 }, layouts = { "PLAYER_SHIP_HARD" } })
    sim.shipCrews = { PLAYER_SHIP_HARD = { "human" } }
    equals(apShipSpecies("PLAYER_SHIP_HARD"), nil, "base game names already say the race")
    sim.shipCrews, sim.crewTitles = nil, nil
end)

test("dashboard: the systems page counts the upgrades of the ship being flown", function()
    sim.startRun(true)
    dashboardSeed()
    _G.apInventory.systemCaps = { shields = 1 }
    _G.apInventory.blueprints = { shields = true }
    _G.apInventory.shipCaps = { PLAYER_SHIP_HARD = { shields = 2 }, PLAYER_SHIP_ROCK = { shields = 5 } }
    openDashboard("systems")
    check(sim.drawnText(apT("hud.system.received", { n = 2 })), "the Kestrel's two upgrades, not the Rock's")
    closeDashboard()
    _G.apInventory.shipCaps = {}
end)

test("profile: a Multiverse ship already unlocked counts, the MV Kestrel does not", function()
    sim.unlocked = {}
    sim.unlocked["PLAYER_SHIP_MVKESTREL"] = true
    check(not apProfileHasShips({ "PLAYER_SHIP_MVKESTREL", "PLAYER_SHIP_UNION_2" }), "a fresh Multiverse profile")
    sim.unlocked["PLAYER_SHIP_UNION_2"] = true
    check(apProfileHasShips({ "PLAYER_SHIP_MVKESTREL", "PLAYER_SHIP_UNION_2" }), "the Union B was unlocked before")
    sim.unlocked = {}
end)

test("dashboard: checks of a ship whose name has an underscore are counted on its row", function()
    sim.startRun(true)
    applySeed({
        goal = { kind = "victories", count = 1 },
        layouts = { "PLAYER_SHIP_AUTO", "PLAYER_SHIP_AUTO_FED" },
        loc = { ["PLAYER_SHIP_AUTO_FED:victory"] = "Federation Auto-Cruiser A: Defeat the Flagship",
                ["PLAYER_SHIP_AUTO:victory"] = "Auto-Cruiser A: Defeat the Flagship" },
    })
    _G.apInventory.ships = {}
    openDashboard("ships")
    local remaining = apT("dash.ships.remaining", { n = 1 })
    local found = 0
    for _, draw in ipairs(sim.draws) do
        if draw.text == remaining then found = found + 1 end
    end
    equals(found, 2, "one check left on each row, not two on the Auto-Cruiser's")
    closeDashboard()
end)

test("dashboard: the This run card only promises what the seed's settings let an option do", function()
    local function seed(options, extra)
        local data = { goal = { kind = "victories", count = 3 }, items = {}, loc = { ["shop:1"] = "Archipelago Shop 1" },
                       options = options }
        for key, value in pairs(extra or {}) do data[key] = value end
        applySeed(data)
    end
    sim.startRun(true)

    seed({ free_upgrades = 1, system_install = 1 })
    openDashboard("overview")
    check(sim.drawnText(apT("dash.run.free_upgrades")), "free upgrades with capped systems: said")
    check(sim.drawnText(apT("dash.run.install.start")), "systems put aboard with blueprints in the seed: said")
    closeDashboard()

    seed({ free_upgrades = 1, system_install = 2 }, { system_caps = false, system_blueprints = false })
    openDashboard("overview")
    check(not sim.drawnText(apT("dash.run.free_upgrades")), "no progressive upgrades: nothing to give for free")
    check(not sim.drawnText(apT("dash.run.install.now")), "no blueprints: nothing to put aboard")
    closeDashboard()

    seed({})
    openDashboard("overview")
    check(not sim.drawnText(apT("dash.run.free_upgrades")), "and nothing without the options")
    closeDashboard()
end)
