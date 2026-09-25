local function quote(value)
    return '"' .. tostring(value):gsub('"', '\\"') .. '"'
end

local function sortedKeys(t)
    local keys = {}
    for key in pairs(t or {}) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    return keys
end

local function jsonArray(t)
    local parts = {}
    for _, key in ipairs(sortedKeys(t)) do
        parts[#parts + 1] = quote(key)
    end
    return "[" .. table.concat(parts, ", ") .. "]"
end

sim.realPrint("CONTRACT_DUMP_BEGIN")
sim.realPrint("{")
sim.realPrint('  "kinds": ' .. jsonArray(_G.apSupportedKinds) .. ",")
sim.realPrint('  "resources": ' .. jsonArray(_G.apSupportedResources) .. ",")
sim.realPrint('  "trap_effects": ' .. jsonArray(_G.apSupportedTrapEffects) .. ",")
local plage = _G.apContractRange or {}
sim.realPrint('  "contract_min": ' .. tostring(plage.min) .. ",")
sim.realPrint('  "contract_max": ' .. tostring(plage.max) .. ",")
sim.realPrint('  "death_link_triggers": ' .. jsonArray(_G.apDeathLinkTriggers) .. ",")
sim.realPrint('  "death_link_effects": ' .. jsonArray(_G.apDeathLinkEffects) .. ",")
sim.realPrint('  "shop_modes": ' .. jsonArray(_G.apShopModes))
sim.realPrint("}")
sim.realPrint("CONTRACT_DUMP_END")
