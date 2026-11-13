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
    check(sim.drawnText(apT("chat.empty")) or #apChatLines() > 0, "left arrow wraps around to the chat")
    sim.keyDown(Defines.SDL.KEY_LEFT)
    sim.renderGui()
    check(sim.drawnText(apT("dash.journal.items")), "and once more to the journal")
    sim.keyDown(Defines.SDL.KEY_4)
    sim.renderGui()
    check(sim.drawnText(apT("dash.cat.shop")), "4 opens the checks page")

    local tabW = math.floor((DASH.w - 32 - 6 * 5) / 6)
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

test("dashboard: upgrades received before the blueprint are counted, not shown as locked", function()
    applySeed({ caps = { cloaking = 3 } })
    _G.apInventory = { ships = {}, systemCaps = { cloaking = 3 }, blueprints = {}, startingUpgrades = {}, shopAvailability = {} }
    sim.startRun(true)
    check(not apSystemUnlocked("cloaking"), "no cloaking blueprint in this test")
    apToggleHud()
    apDashboardPage(3)
    sim.renderGui()
    apToggleHud()
    check(sim.drawnText(apT("dash.system.aboard", { received = 2, total = 3 })),
        "cloaking reads 2/3, blueprint missing, not locked")
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

test("dashboard: a seed with many ships scrolls the ships page instead of drawing names over each other", function()
    sim.startRun(true)
    dashboardSeed()
    local gameShips, seedShips, inSeed = _G.apGameData.ships, _G.apSeedShips, _G.apLayoutInSeed
    local many = {}
    for index = 1, 28 do many[index] = { name = "PLAYER_SHIP_HARD", layouts = 1 } end
    _G.apGameData.ships = many
    if seedShips then _G.apSeedShips = function() return many end end
    _G.apLayoutInSeed = function() return true end
    openDashboard("ships")
    local names, counts = {}, {}
    for _, draw in ipairs(sim.draws) do
        if draw.text == apShipLabel("PLAYER_SHIP_HARD") then names[#names + 1] = draw end
        local value = tostring(draw.text)
        if value == apT("dash.ships.clear") or value:find(apT("dash.ships.remaining", { n = 0 }):gsub("0", ""), 1, true) then
            counts[#counts + 1] = draw
        end
    end
    _G.apGameData.ships, _G.apSeedShips, _G.apLayoutInSeed = gameShips, seedShips, inSeed
    check(#names > 0 and #names < 28, "only the cards that fit are drawn")
    local apart = #counts > 0
    for _, name in ipairs(names) do
        for _, count in ipairs(counts) do
            if count.x == name.x and math.abs(count.y - name.y) < 16 then apart = false end
        end
    end
    check(apart, "a ship's name and its checks left keep their own lines")
    closeDashboard()
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

test("in logic: a check is in logic once its layout's items and its blueprints are received", function()
    apContractResetForTesting()
    applySeed({ loc = { ["PLAYER_SHIP_ROCK:sector:3"] = "Rock Cruiser A: Reach sector 3" },
                items = { ["Rock Cruiser Key"] = { k = "ship", bp = "PLAYER_SHIP_ROCK" },
                          ["Shields blueprint"] = { k = "cap", sys = "shields" } },
                logic = { layouts = { PLAYER_SHIP_ROCK = { "Rock Cruiser Key" } },
                          checks = { ["PLAYER_SHIP_ROCK:sector:3"] = { ways = { { l = "PLAYER_SHIP_ROCK", i = {} } },
                                                                        bp = 1, pass = 0 } },
                          blueprint_items = { "Shields blueprint" } } })
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:3"), false, "nothing received yet")
    apReceiveItem("Rock Cruiser Key", "Nina", false, 0)
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:3"), false, "the ship, not the blueprint")
    apReceiveItem("Shields blueprint", "Nina", false, 1)
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:3"), true, "both: in logic")
    apContractResetForTesting()
    applySeed({})
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:3"), nil, "a seed without the logic copy says nothing")
end)

test("progressive unlocks the system: the first Progressive item unlocks its system and is its blueprint in logic", function()
    apContractResetForTesting()
    _G.apInventory.blueprints = {}
    applySeed({ kinds = { "ship", "cap", "cap_unlock" }, kinds_required = { "cap_unlock" },
                loc = { ["PLAYER_SHIP_ROCK:sector:3"] = "Rock Cruiser A: Reach sector 3" },
                items = { ["Rock Cruiser Key"] = { k = "ship", bp = "PLAYER_SHIP_ROCK" },
                          ["Progressive Shields"] = { k = "cap", sys = "shields", ub = true } },
                logic = { layouts = { PLAYER_SHIP_ROCK = { "Rock Cruiser Key" } },
                          checks = { ["PLAYER_SHIP_ROCK:sector:3"] = { ways = { { l = "PLAYER_SHIP_ROCK",
                                                                                  i = { "Shields blueprint" } } },
                                                                        bp = 1, pass = 0 } },
                          blueprint_items = { "Shields blueprint" },
                          unlocks = { ["Progressive Shields"] = "Shields blueprint" } } })
    check(not sim.logged("SEED REFUSED"), "the mod knows the seed's kind")
    apReceiveItem("Rock Cruiser Key", "Nina", false, 0)
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:3"), false, "no shields yet")
    apReceiveItem("Progressive Shields", "Nina", false, 1)
    sim.tick(240)
    equals(_G.apInventory.blueprints.shields, true, "the shields are unlocked")
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:3"), true, "and count as the blueprint: in logic")
end)

test("in logic: a shared shop slot past sector 4 needs one layout holding both its key and its pass", function()
    apContractResetForTesting()
    applySeed({ loc = { ["shop:6:1"] = "AP Store: Sector 6, slot 1" },
                logic = { layouts = { PLAYER_SHIP_ROCK = { "Rock Cruiser Key" }, PLAYER_SHIP_STEALTH = { "Stealth Cruiser Key" } },
                          passes = { PLAYER_SHIP_ROCK = "Sector Pass (Rock)", PLAYER_SHIP_STEALTH = "Sector Pass (Stealth)" },
                          checks = { ["shop:6:1"] = { ways = { { l = "PLAYER_SHIP_ROCK", i = {} },
                                                               { l = "PLAYER_SHIP_STEALTH", i = {} } }, bp = 0, pass = 1 } },
                          blueprint_items = {} } })
    apReceiveItem("Rock Cruiser Key", "Nina", false, 0)
    apReceiveItem("Sector Pass (Stealth)", "Nina", false, 1)
    equals(apInLogic("shop:6:1"), false, "the Rock without its pass, a pass for a Stealth not received: not in logic")
    apReceiveItem("Sector Pass (Rock)", "Nina", false, 2)
    equals(apInLogic("shop:6:1"), true, "the Rock with its own pass: in logic")
    apContractResetForTesting()
    applySeed({})
end)

test("in logic: with shop_per_ship, a deep shop slot only counts its owner's pass, even from an older seed", function()
    apContractResetForTesting()
    local saved = _G.apShopConfig.owners
    _G.apShopConfig.owners, _G.apShopConfig.sectors, _G.apShopConfig.per = { "PLAYER_SHIP_ROCK", "PLAYER_SHIP_STEALTH" }, 8, nil
    applySeed({ loc = { ["shop:14"] = "AP Store: slot 14" },
                logic = { layouts = { PLAYER_SHIP_ROCK = { "Rock Cruiser Key" }, PLAYER_SHIP_STEALTH = { "Stealth Cruiser Key" } },
                          passes = { PLAYER_SHIP_ROCK = "Sector Pass (Rock)", PLAYER_SHIP_STEALTH = "Sector Pass (Stealth)" },
                          checks = { ["shop:14"] = { ways = { { l = "PLAYER_SHIP_ROCK", i = {} },
                                                              { l = "PLAYER_SHIP_STEALTH", i = {} } }, bp = 0, pass = 1 } },
                          blueprint_items = {} } })
    apReceiveItem("Rock Cruiser Key", "Nina", false, 0)
    apReceiveItem("Stealth Cruiser Key", "Nina", false, 1)
    apReceiveItem("Sector Pass (Rock)", "Nina", false, 2)
    equals(apInLogic("shop:14"), false, "slot 14 is sold aboard the Stealth: the Rock's pass does not open it")
    apReceiveItem("Sector Pass (Stealth)", "Nina", false, 3)
    equals(apInLogic("shop:14"), true, "the Stealth's own pass does")
    _G.apShopConfig.owners, _G.apShopConfig.sectors = saved, nil
    apContractResetForTesting()
    applySeed({})
end)

test("in logic: Sector Passes, the ship's own systems and unowned ships count like the apworld's logic", function()
    apContractResetForTesting()
    applySeed({ loc = { ["PLAYER_SHIP_ROCK:sector:5"] = "Rock Cruiser A: Reach sector 5",
                        ["sys:cloaking"] = "Install Cloaking", ["crew:engi"] = "First Engi aboard" },
                logic = { layouts = { PLAYER_SHIP_ROCK = { "Rock Cruiser Key" }, PLAYER_SHIP_STEALTH = { "Stealth Cruiser Key" } },
                          passes = { PLAYER_SHIP_ROCK = "Sector Pass (Rock)", PLAYER_SHIP_STEALTH = "Sector Pass (Stealth)" },
                          checks = {
                              ["PLAYER_SHIP_ROCK:sector:5"] = { ways = { { l = "PLAYER_SHIP_ROCK", i = {} } }, bp = 0, pass = 1 },
                              ["sys:cloaking"] = { ways = { { l = "PLAYER_SHIP_ROCK", i = { "Cloaking blueprint" } },
                                                            { l = "PLAYER_SHIP_STEALTH", i = {} } }, bp = 0, pass = 0 },
                              ["crew:engi"] = { ways = { { l = "PLAYER_SHIP_ROCK", i = {} } }, bp = 0, pass = 0 },
                          },
                          blueprint_items = {} } })
    equals(apInLogic("crew:engi"), false, "no ship received: nothing in logic")
    apReceiveItem("Rock Cruiser Key", "Nina", false, 0)
    equals(apInLogic("crew:engi"), true, "the Rock: the Engi check is in logic")
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:5"), false, "sector 5 needs the Rock's first Sector Pass")
    apReceiveItem("Sector Pass (Stealth)", "Nina", false, 1)
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:5"), false, "another ship's pass does not count")
    apReceiveItem("Sector Pass (Rock)", "Nina", false, 2)
    equals(apInLogic("PLAYER_SHIP_ROCK:sector:5"), true, "its own pass does")
    equals(apInLogic("sys:cloaking"), false, "Cloaking on the Rock needs its blueprint")
    apReceiveItem("Stealth Cruiser Key", "Nina", false, 3)
    equals(apInLogic("sys:cloaking"), true, "the Stealth starts with it")
    apContractResetForTesting()
    applySeed({})
end)

test("dashboard: the EnergyLink chip shows the shared pool in fuel, and a look at it is no empty answer", function()
    sim.startRun(true)
    dashboardSeed()
    apEnergyLinkConfigure({ enabled = true })
    _G.apEnergyLinkState.poolKnown = false
    local summary = apSeedSummary
    local restore = stub("apSeedSummary", function()
        local s = summary()
        s.links.energy = true
        return s
    end)
    openDashboard("overview")
    check(sim.drawnText(apT("dash.links.energy", { n = "?" })), "unknown until the server tells")
    closeDashboard()
    sim.clearLog()
    sim.netEvent("energy", { index = 0, value = 3500000 })
    sim.tick(2)
    openDashboard("overview")
    check(sim.drawnText(apT("dash.links.energy", { n = "3" })), "3.5 fuel worth of joules: 3 fuel")
    local said = false
    for _, line in ipairs(sim.screen) do
        if line:find(apT("energylink.empty"), 1, true) then said = true end
    end
    check(not said, "a look at the pool does not say it is empty")
    closeDashboard()

    -- The three links in French, with the pool's long label: TrapLink still gets its chip (Windows, 11/11).
    local trapRestore = stub("apSeedSummary", function()
        local s = summary()
        s.links.energy, s.links.death, s.links.trap = true, true, true
        return s
    end)
    apLangResolve("fr")
    -- A pool long enough that its label cannot share the card with the two other chips.
    local poolRestore = stub("apEnergyLinkPoolFuel", function() return 123456789012345678 end)
    openDashboard("overview")
    poolRestore()
    check(sim.drawnText("TrapLink"), "TrapLink is not pushed out by the pool's label")
    check(sim.drawnText(apT("dash.links.energy_short", { n = "123456789012345678" })),
        "the pool keeps its figure in the short label (Windows, 11/11)")
    check(sim.drawnText("DeathLink"), "nor DeathLink")
    closeDashboard()
    apLangResolve(nil)
    trapRestore()
    restore()
    apEnergyLinkConfigure({ enabled = false })
end)

test("EnergyLink: fuel the other players put in the shared reserve is announced, our own is not", function()
    sim.startRun(true)
    apEnergyLinkConfigure({ enabled = true })
    _G.apEnergyLinkState.poolKnown = false
    apEnergyLinkSync(2000000)
    sim.clearLog()
    apEnergyLinkSync(7500000)
    local said = false
    for _, line in ipairs(sim.screen) do
        if line:find(apT("energylink.others", { n = 5 }), 1, true) then said = true end
    end
    check(said, "5 fuel came from the others: the player reads it")
    sim.clearLog()
    _G.apEnergyLinkState.pool = _G.apEnergyLinkState.pool + 3000000
    apEnergyLinkSync(10500000)
    local quiet = true
    for _, line in ipairs(sim.screen) do
        if line:find(apT("energylink.others", { n = 3 }), 1, true) then quiet = false end
    end
    check(quiet, "our own deposit, already counted, is not taken for the others'")
    apEnergyLinkConfigure({ enabled = false })
end)

local function hangarWithSeed()
    sim.started = true
    sim.menuOpen = nil
    sim.hangarOpen = true
    dashboardSeed()
end

local function leaveHangar()
    if apDashboardOpen() then apToggleHud() end
    sim.hangarOpen = false
end

test("dashboard: TAB in the hangar opens it on the ships page, without pausing, and TAB or Esc closes it", function()
    hangarWithSeed()
    local gui = Hyperspace.App.gui
    gui.bPaused = false
    sim.keyDown(Defines.SDL.KEY_TAB)
    check(apDashboardOpen(), "TAB opens it in the hangar")
    sim.renderMenu()
    check(sim.drawnText(apT("dash.ships.header", { done = 0, total = 28 }):sub(1, 10)), "on the ships page")
    check(sim.drawnText(apT("dash.footer.hangar")), "and the footer does not say the game is paused")
    equals(gui.bPaused, false, "there is no game to pause")
    sim.keyDown(Defines.SDL.KEY_TAB)
    check(not apDashboardOpen(), "TAB closes it")
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.keyDown(Defines.SDL.KEY_ESCAPE)
    check(not apDashboardOpen(), "Esc closes it")
    equals(gui.bPaused, false, "and nothing was left paused")
    leaveHangar()
end)

test("dashboard: TAB does nothing on the title screen or in the hangar without a seed", function()
    sim.started = true
    sim.menuOpen = nil
    sim.hangarOpen = false
    dashboardSeed()
    sim.keyDown(Defines.SDL.KEY_TAB)
    check(not apDashboardOpen(), "the title screen keeps TAB for the connection form")
    apContractResetForTesting()
    sim.hangarOpen = true
    sim.keyDown(Defines.SDL.KEY_TAB)
    check(not apDashboardOpen(), "no seed, no dashboard in the hangar")
    leaveHangar()
end)

test("dashboard: what depends on the run says to start one in the hangar", function()
    hangarWithSeed()
    sim.keyDown(Defines.SDL.KEY_TAB)
    for _, page in ipairs({ "overview", "systems" }) do
        apDashboardPage(page)
            sim.renderMenu()
        check(apDashboardOpen(), page .. " draws without a run")
        check(sim.drawnText(apT("dash.need_run")), page .. " says to start a run")
    end
    leaveHangar()
end)

test("dashboard: starting a run with it open closes it and the run plays", function()
    hangarWithSeed()
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.hangarOpen = false
    sim.startRun(true)
    check(not apDashboardOpen(), "the run starts with the dashboard closed")
    local gui = Hyperspace.App.gui
    gui.bPaused = false
    sim.keyDown(Defines.SDL.KEY_TAB)
    equals(gui.bPaused, true, "in the run TAB pauses again")
    sim.keyDown(Defines.SDL.KEY_TAB)
    equals(gui.bPaused, false, "and resumes")
end)

test("dashboard: the title screen closes a dashboard left open in the hangar", function()
    hangarWithSeed()
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.hangarOpen = false
    sim.renderMenu()
    check(not apDashboardOpen(), "closed once the hangar is gone")
end)

local function shipsDrawn()
    local names = {}
    sim.renderMenu()
    for _, draw in ipairs(sim.draws) do
        names[#names + 1] = tostring(draw.text)
    end
    return names
end

local function positionOf(names, wanted)
    for index, name in ipairs(names) do
        if name == wanted then return index end
    end
    return nil
end

test("dashboard: ships go by checks left, none left at the very end, and U or the button hides the locked ones", function()
    hangarWithSeed()
    apDashboardResetFilterForTesting()
    local label = function(name) return apShipLabel(name) end
    _G.apInventory.ships = { "PLAYER_SHIP_HARD", "PLAYER_SHIP_FED", "PLAYER_SHIP_STEALTH" }
    local contract = _G.apContractState
    contract.locNames = {
        ["PLAYER_SHIP_FED:sector:2"] = "a",
        ["PLAYER_SHIP_HARD:sector:2"] = "b", ["PLAYER_SHIP_HARD:sector:3"] = "c",
        ["PLAYER_SHIP_ROCK:sector:2"] = "d", ["PLAYER_SHIP_ROCK:sector:3"] = "e", ["PLAYER_SHIP_ROCK:sector:4"] = "f",
    }
    sim.keyDown(Defines.SDL.KEY_TAB)
    local names = shipsDrawn()
    check(positionOf(names, label("PLAYER_SHIP_HARD")) < positionOf(names, label("PLAYER_SHIP_FED")),
        "the most checks left comes first")
    check(positionOf(names, label("PLAYER_SHIP_FED")) < positionOf(names, label("PLAYER_SHIP_STEALTH")),
        "a ship with nothing left goes last")
    check(positionOf(names, label("PLAYER_SHIP_ROCK")) == nil, "from the hangar, ships not unlocked are hidden")

    sim.keyDown(Defines.SDL.KEY_u)
    names = shipsDrawn()
    check(positionOf(names, label("PLAYER_SHIP_ROCK")) ~= nil, "U shows them again")
    check(positionOf(names, label("PLAYER_SHIP_FED")) < positionOf(names, label("PLAYER_SHIP_ROCK")),
        "after what can be flown, even with more checks left")
    check(positionOf(names, label("PLAYER_SHIP_ROCK")) < positionOf(names, label("PLAYER_SHIP_STEALTH")),
        "but before what has nothing left")

    local filter = apDashboardAreaForTesting("filter:1")
    sim.click(filter.x + 4, filter.y + 4)
    names = shipsDrawn()
    check(positionOf(names, label("PLAYER_SHIP_ROCK")) == nil, "the button hides them")
    _G.apInventory.ships = {}
    apDashboardResetFilterForTesting()
    leaveHangar()
end)

test("dashboard: checks left count every layout of a class, and a class with an underscore in its name", function()
    sim.startRun(true)
    applySeed({
        goal = { kind = "victories", count = 1 },
        layouts = { "PLAYER_SHIP_HARD" },
        loc = { ["PLAYER_SHIP_HARD:victory"] = "a", ["PLAYER_SHIP_HARD_2:victory"] = "b",
                ["PLAYER_SHIP_HARD_3:sector:2"] = "c" },
    })
    openDashboard("ships")
    check(sim.drawnText(apT("dash.ships.remaining", { n = 3 })), "A, B and C count for the class")
    closeDashboard()
    local saved = _G.apGameData.ships
    _G.apGameData.ships = { { name = "PLAYER_SHIP_AUTO_FED", layouts = 1 } }
    applySeed({
        goal = { kind = "victories", count = 1 },
        loc = { ["PLAYER_SHIP_AUTO_FED:victory"] = "a", ["PLAYER_SHIP_AUTO_FED_2:victory"] = "b" },
    })
    openDashboard("ships")
    _G.apGameData.ships = saved
    check(sim.drawnText(apT("dash.ships.remaining", { n = 2 })), "the whole name counts")
    closeDashboard()
end)

test("dashboard: from a run the ships page keeps every ship, until the filter is asked for, and it stays", function()
    apDashboardResetFilterForTesting()
    sim.startRun(true)
    dashboardSeed()
    openDashboard("ships")
    check(sim.drawnText(apShipLabel("PLAYER_SHIP_ROCK")), "a run lists the ships not unlocked")
    sim.keyDown(Defines.SDL.KEY_u)
    closeDashboard()
    openDashboard("ships")
    check(not sim.drawnText(apShipLabel("PLAYER_SHIP_ROCK")), "the choice holds when it opens again")
    closeDashboard()
    apDashboardResetFilterForTesting()
end)

test("dashboard: the run card counts the crew waiting for a free seat", function()
    sim.startRun(true)
    dashboardSeed()
    local restore = _G.apOwedCrewCount
    _G.apOwedCrewCount = function() return 2 end
    openDashboard("overview")
    _G.apOwedCrewCount = restore
    check(sim.drawnText(apT("dash.run.crew_waiting", { n = 2 })), "the wait stays visible after the message")
    closeDashboard()
end)

local function connectForChat()
    apContractResetForTesting()
    apNetResetForTesting()
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = slotData({ seed_hash = "CHAT" }) })
    sim.net.connected = true
    sim.tick(1)
    sim.net.said = {}
    apChatClearForTesting()
end

test("chat: what is typed on the Chat page goes to the server on Enter", function()
    connectForChat()
    sim.startRun(true)
    openDashboard("chat")
    sim.type("!hint Burst Laser")
    sim.keyDown(Defines.SDL.KEY_RETURN)
    equals(sim.net.said and sim.net.said[1], "!hint Burst Laser", "the text typed is sent as it is")
    equals(sim.fireForTesting("ON_KEY_DOWN", string.byte("w")), Defines.Chain.PREEMPT,
        "a letter typed there never reaches the game (W would fire a weapon)")
    equals(apDashboardPage("chat") and apDashboardOpen(), true, "the window stays open on its page")
    closeDashboard()
end)

test("chat: the text comes from the keyboard layout, not from the key codes (AZERTY)", function()
    connectForChat()
    sim.startRun(true)
    openDashboard("chat")
    equals(sim.net.capture, true, "the Chat page asks the module for the typed text")
    sim.layoutText = false
    -- On AZERTY the key that types "1" with Shift has the code of "&", and "é" has none of its own.
    sim.keyDown(304)
    sim.keyDown(string.byte("&"))
    sim.keyUp(304)
    sim.net.typed = sim.net.typed .. "1"
    sim.keyDown(50)
    sim.net.typed = sim.net.typed .. "\195\169"
    sim.renderGui()
    sim.keyDown(Defines.SDL.KEY_BACKSPACE)
    sim.layoutText = nil
    sim.type("e!")
    sim.keyDown(Defines.SDL.KEY_RETURN)
    equals(sim.net.said and sim.net.said[1], "1e!", "what FTL read is typed, and Backspace takes a whole letter")
    apDashboardPage("overview")
    sim.renderGui()
    equals(sim.net.capture, false, "another page lets the game have its text again")
    closeDashboard()
end)

test("dashboard: the top row turns the pages on an AZERTY keyboard too", function()
    sim.startRun(true)
    openDashboard("overview")
    sim.keyDown(string.byte("("))
    equals(apDashboardPageForTesting(), "journal", "the ( key, where 5 is, opens page 5")
    sim.keyDown(233)
    equals(apDashboardPageForTesting(), "ships", "and the key of 2 types an e with an accent")
    closeDashboard()
end)

test("chat: with an older module, the keys are read as on a US keyboard", function()
    connectForChat()
    local capture, take = sim.net.client.CaptureText, sim.net.client.TakeText
    sim.net.client.CaptureText, sim.net.client.TakeText = nil, nil
    sim.startRun(true)
    openDashboard("chat")
    sim.keyDown(304)
    sim.keyDown(string.byte("1"))
    sim.keyUp(304)
    sim.type("hint Burst Laser")
    sim.keyDown(Defines.SDL.KEY_RETURN)
    sim.net.client.CaptureText, sim.net.client.TakeText = capture, take
    equals(sim.net.said and sim.net.said[1], "!hint Burst Laser", "Shift+1 types the !, the rest follows")
    closeDashboard()
end)

test("chat: the server's lines are listed newest first, and the tab counts the unread ones", function()
    connectForChat()
    sim.startRun(true)
    sim.netEvent("chat", { name = "CommandResult", extra = "Hint: Burst Laser II is at\nKestrel B: Reach sector 5" })
    sim.netEvent("chat", { name = "Chat", extra = "Axel: gg" })
    sim.tick(1)
    equals(#apChatLines(), 3, "one entry per line")
    equals(apChatLines()[1].text, "Axel: gg", "newest first")
    equals(apChatLines()[2].text, "Hint: Burst Laser II is at", "a message of several lines reads top down")
    openDashboard("overview")
    check(sim.drawnText(apT("dash.tab.chat", { n = 6 }) .. " (3)"), "the Chat tab shows 3 unread lines")
    apDashboardPage("chat")
    sim.renderGui()
    check(sim.drawnText("Axel: gg"), "the Chat page lists the line")
    equals(apChatUnread(), 0, "and reading it clears the count")
    closeDashboard()
end)

test("chat: offline, nothing is sent and the page says why", function()
    connectForChat()
    sim.net.connected = false
    apNetResetForTesting()
    sim.startRun(true)
    openDashboard("chat")
    sim.type("hello")
    sim.keyDown(Defines.SDL.KEY_RETURN)
    equals(#sim.net.said, 0, "nothing said")
    equals(apChatLines()[1].text, apT("chat.offline"), "the page explains it")
    closeDashboard()
end)
