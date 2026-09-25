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
    check(sim.drawnText("0 of 3"), "the goal and where it stands")
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
    _G.apInventory.systemCaps = { shields = 3 }
    _G.apInventory.startingUpgrades = { shields = 1, reactor = 2 }
    openDashboard("systems")
    check(sim.drawnText(apT("dash.systems.header", { done = 1, total = 16 })), "one system unlocked out of sixteen")
    check(sim.drawnText(apT("dash.system.locked")), "the others are locked")
    check(sim.drawnText(apT("dash.system.start", { n = 1 })), "the head start is shown on its system")
    check(sim.drawnText(apT("dash.systems.reactor", { n = 2 })), "and the reactor bonus in the header")
    closeDashboard()
end)

test("dashboard: the checks page lists what is left in the chosen category, and scrolls", function()
    sim.startRun(true)
    local loc = {}
    for i = 1, 60 do loc["shop:" .. i] = string.format("Archipelago Shop %02d", i) end
    loc["sys:shields"] = "Install Shields"
    applySeed({ items = {}, loc = loc })
    apSendCheck("shop:1", "test")
    openDashboard("checks")
    check(sim.drawnText(apT("dash.checks.remaining", { n = 59 })), "59 shop slots left")
    check(not sim.drawnText("Archipelago Shop 01"), "the one already bought is not listed")
    check(sim.drawnText("Archipelago Shop 02"), "the next one is")
    check(not sim.drawnText("Archipelago Shop 60"), "the end of the list waits below")

    sim.scroll(1)
    sim.renderGui()
    check(sim.drawnText("Archipelago Shop 02"), "the wheel only scrolls where the mouse is")

    local rowH = 46
    sim.click(DASH.x + 20 + 40, DASH.y + 96 + (rowH + 6) + 10)
    sim.renderGui()
    check(sim.drawnText("Install Shields"), "clicking the systems category lists its checks")
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

test("dashboard: a delivered item goes into the journal, a replayed one does not", function()
    sim.startRun(true)
    applySeed({ items = { ["50 Scrap"] = { k = "filler", res = "scrap", n = 50 } } })
    _G.apReceivedHistory = {}
    apReceiveItem("50 Scrap", "Axel")
    apReceiveItem("50 Scrap", "Axel", true)
    equals(#_G.apReceivedHistory, 1, "only the new item is recorded")
    equals(_G.apReceivedHistory[1].sender, "Axel", "with its sender")
end)
