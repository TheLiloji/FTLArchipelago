sim.realPrint("")
sim.realPrint(string.format("%d tests passed, %d failed", passed, failed))
for _, failure in ipairs(failures) do
    sim.realPrint("  FAIL  " .. failure)
end
if failed == 0 then
    sim.realPrint("TESTS OK")
end
