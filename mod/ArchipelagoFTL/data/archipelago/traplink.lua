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
    -- Seconds since the last trap from another slot, nil when none came since connecting. Archipelago never says who
    -- is on the link: a trap that came in recently is the only sign someone still is.
    partnerAge = nil,
}

local PARTNER_WINDOW = 600

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
    state.partnerAge = 0

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

-- A trap the mod makes (a pact, the surge from another world) only goes out once a trap from another slot showed
-- someone else is on the link this session: alone on it, the trap would vanish, so it hits the player instead.
function apTrapLinkPartnerSeen()
    return _G.apTrapLink ~= nil and _G.apTrapLink.enabled == true and state.partnerAge ~= nil
end

-- Called on a disconnect: whoever was on the link may be gone by the time we are back.
function apTrapLinkForgetPartner()
    state.partnerAge = nil
end

function apTrapLinkAgePartner(seconds)
    if state.partnerAge == nil then
        return
    end
    state.partnerAge = state.partnerAge + seconds
    if state.partnerAge > PARTNER_WINDOW then
        state.partnerAge = nil
        trapLog("no trap from another slot for " .. PARTNER_WINDOW .. " s: no partner assumed any more")
    end
end

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    local ok, factor = pcall(function() return Hyperspace.FPS.SpeedFactor end)
    factor = ok and tonumber(factor) or nil
    apTrapLinkAgePartner((factor ~= nil and factor > 0) and math.min(factor * 0.0625, 0.25) or 1 / 60)
end)

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
