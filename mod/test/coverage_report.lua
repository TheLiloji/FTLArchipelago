local out = sim.realPrint
local coverage = _G.apCoverage
local untested, tested = {}, 0

for _, name in ipairs(coverage.names) do
    if coverage.calls[name] == 0 then
        untested[#untested + 1] = name
    else
        tested = tested + 1
    end
end

out("")
out(string.format("Coverage: %d/%d global functions exercised by the tests (%d%%)",
    tested, #coverage.names, math.floor(tested * 100 / math.max(1, #coverage.names))))

if #untested > 0 then
    out("")
    out("Never called during the tests:")
    for _, name in ipairs(untested) do
        out("  " .. name)
    end
end

local locals_ = _G.apCoverageLocals
if locals_ ~= nil then
    local never, seen = {}, 0
    for _, name in ipairs(locals_.names) do
        if (locals_.calls[name] or 0) == 0 then
            never[#never + 1] = name
        else
            seen = seen + 1
        end
    end
    out("")
    out(string.format("Coverage: %d/%d local functions exercised by the tests (%d%%)",
        seen, #locals_.names, math.floor(seen * 100 / math.max(1, #locals_.names))))
    if #never > 0 then
        out("")
        out("Locals never called during the tests:")
        for _, name in ipairs(never) do
            out("  " .. name)
        end
    end
end

local branches = _G.apCoverageBranches
if branches ~= nil then
    local never, seen = {}, 0
    for _, mark in ipairs(branches.names) do
        if (branches.calls[mark] or 0) == 0 then
            never[#never + 1] = mark
        else
            seen = seen + 1
        end
    end
    out("")
    out(string.format("Coverage: %d/%d branches taken by the tests (%d%%)",
        seen, #branches.names, math.floor(seen * 100 / math.max(1, #branches.names))))
    if branches.unmeasured > 0 then
        out(string.format("  (%d single-line branches are not measured)",
            branches.unmeasured))
    end
    if #never > 0 then
        out("")
        out("Branches never taken during the tests:")
        for _, mark in ipairs(never) do
            out("  " .. mark)
        end
    end
end
out("")
