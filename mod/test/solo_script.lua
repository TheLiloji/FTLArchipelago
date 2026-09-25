local LANGUAGE = _G.apScriptLanguage or "fr"

sim.reset()
apForgetChecksForTesting()
apFillerResetForTesting()
if _G.apContractResetForTesting then apContractResetForTesting() end
if _G.apInventoryResetForTesting then apInventoryResetForTesting() end

sim.gameLanguage = LANGUAGE
sim.startRun(true)
apLangResolve(nil)

local seen = 0
local function show(title)
    local newLines = {}
    for index = seen + 1, #sim.screen do
        newLines[#newLines + 1] = sim.screen[index]
    end
    seen = #sim.screen
    if #newLines == 0 then
        return
    end
    sim.realPrint("")
    sim.realPrint("  " .. title)
    for _, line in ipairs(newLines) do
        sim.realPrint("      " .. line)
    end
end

sim.realPrint("")
sim.realPrint(string.rep("=", 92))
sim.realPrint("  A SOLO GAME, AS THE PLAYER READS IT   (language: " .. LANGUAGE .. ")")
sim.realPrint(string.rep("=", 92))

apSoloStart()
sim.tick(5)
show("Presses S")

local order = _G.apSoloOrder or {}
for index = 1, #order do
    apSendCheck("script:check:" .. index, "test")
    sim.jumpArrive()
    sim.tick(5)
    if index <= 6 or index == math.floor(#order / 2) or index >= #order - 2 then
        show("Check " .. index .. " of " .. #order)
    else
        seen = #sim.screen
    end
end

sim.realPrint("")
sim.realPrint("  Presses TAB")
apToggleHud()
sim.renderGui()
for _, line in ipairs(sim.drawn) do
    sim.realPrint("      " .. line)
end
apToggleHud()

sim.realPrint("")
sim.realPrint(string.format("  (%d messages total, %d errors)", #sim.screen, sim.errors))
sim.realPrint("")
