
sim.reset()
apForgetChecksForTesting()
apFillerResetForTesting()
if _G.apContractResetForTesting then apContractResetForTesting() end
if _G.apInventoryResetForTesting then apInventoryResetForTesting() end
sim.startRun(true)

if not apSoloStart() then
    sim.realPrint("solo mode did not start: run apworld/multiworld/make.sh")
    return
end

local order = _G.apSoloOrder
sim.realPrint("")
sim.realPrint("Curve of a solo game: " .. #order .. " items, in the order of a real seed.")
sim.realPrint("")
sim.realPrint(" checks        ships   system levels   starting given")
sim.realPrint(" " .. string.rep("-", 66))

local function snapshot(index)
    local caps, starts = 0, 0
    for _, value in pairs(_G.apInventory.systemCaps) do caps = caps + value end
    for _, value in pairs(_G.apInventory.startingUpgrades) do starts = starts + value end
    sim.realPrint(string.format(" %3d (%3d%%)  %9d %20d %19d",
        index, math.floor(index * 100 / #order), #_G.apInventory.ships, caps, starts))
end

local step = math.max(1, math.floor(#order / 10))
for index = 1, #order do
    apSendCheck("curve:check:" .. index, "curve")
    sim.jumpArrive()
    if index % step == 0 or index == #order then
        snapshot(index)
    end
end

sim.realPrint("")
sim.realPrint(string.format(" queue remaining: %d item(s) | errors: %d",
    #_G.apFillerPendingForTesting(), sim.errors))
sim.realPrint("")
