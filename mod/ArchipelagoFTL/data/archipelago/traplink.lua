local TAG = "[AP-traplink] "

local function trapLog(message)
    log(TAG .. message)
end

_G.apTrapLink = _G.apTrapLink or { enabled = false }

local state = {
    sent = 0,
    unsent = 0,
    received = 0,
    ignored = 0,
}

_G.apTrapLinkState = state

local OUR_EFFECTS = { "fire", "breach", "fuel_leak", "system_damage", "fleet_advance", "hull_damage" }

local KEYWORDS = {
    { "ice", "system_damage" },
    { "frost", "system_damage" },
    { "freeze", "system_damage" },
    { "cold", "system_damage" },
    { "breach", "breach" },
    { "leak", "fuel_leak" },
    { "fire", "fire" },
    { "burn", "fire" },
    { "flame", "fire" },
    { "fuel", "fuel_leak" },
    { "gas", "fuel_leak" },
    { "system", "system_damage" },
    { "jam", "system_damage" },
    { "stun", "system_damage" },
    { "paralys", "system_damage" },
    { "confus", "system_damage" },
    { "blind", "system_damage" },
    { "reverse", "system_damage" },
    { "damage", "hull_damage" },
    { "bomb", "hull_damage" },
    { "explos", "hull_damage" },
    { "hurt", "hull_damage" },
    { "poison", "hull_damage" },
    { "hull", "hull_damage" },
    { "chase", "fleet_advance" },
    { "timer", "fleet_advance" },
    { "speed", "fleet_advance" },
    { "slow", "fleet_advance" },
}

function apTrapLinkTranslate(trapName)
    local lowered = string.lower(tostring(trapName or ""))
    for _, entry in ipairs(KEYWORDS) do
        if lowered:find(entry[1], 1, true) then
            return entry[2], "keyword '" .. entry[1] .. "'"
        end
    end
    return OUR_EFFECTS[math.random(1, #OUR_EFFECTS)], "no keyword matched, random pick"
end

function apTrapLinkReceive(source, trapName)
    if not _G.apTrapLink.enabled then
        return false
    end
    state.received = state.received + 1

    local effect, why = apTrapLinkTranslate(trapName)
    trapLog(string.format("trap from %s: '%s' -> %s (%s)",
        tostring(source), tostring(trapName), effect, why))

    return apQueueItem({
        kind = "trap",
        eff = effect,
        display = apT("trap.from", { trap = tostring(trapName), slot = tostring(source or "?") }),
        fromLink = true,
    })
end

function apTrapLinkOnTrap(descriptor)
    if not _G.apTrapLink.enabled then
        return false
    end
    if descriptor.fromLink then
        state.ignored = state.ignored + 1
        return false
    end

    local name = descriptor.display or descriptor.eff

    local sent = false
    if _G.apNetSendTrap then
        local ok, result = pcall(_G.apNetSendTrap, name)
        if not ok then
            trapLog("broadcast failed: " .. tostring(result))
            return false
        end
        sent = result ~= false
    end

    if sent then
        state.sent = state.sent + 1
    else
        state.unsent = (state.unsent or 0) + 1
        trapLog("(offline) the trap was not broadcast to anyone: " .. tostring(name))
    end
    return sent
end

function apTrapLinkStatus()
    trapLog("TrapLink " .. (_G.apTrapLink.enabled and "active" or "inactive")
        .. string.format(" | sent=%d unsent=%d received=%d ignored=%d",
            state.sent, state.unsent or 0, state.received, state.ignored))
end

trapLog("TrapLink module loaded (console: LUA apTrapLinkStatus())")
