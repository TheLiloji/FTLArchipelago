local TAG = "[AP-death] "

local function deathLog(message)
    log(TAG .. message)
end

local TICKS_PER_SECOND = 60

_G.apDeathLink = {
    enabled = false,
    trigger = "both",
    effect = "major_incident",
    graceSeconds = 15,
}

_G.apDeathLinkTriggers = { ship_destroyed = true, crew_death = true, both = true }
_G.apDeathLinkEffects = {
    major_incident = true, crew_member = true, hull_damage = true, fire = true,
    boarding = true, varied = true,
}

local state = {
    ticks = 0,
    lastReceivedAt = nil,
    lastSentAt = nil,
    sent = 0,
    received = 0,
    ignored = 0,
    knownCrew = nil,
    dying = {},
    applying = false,
}

_G.apDeathLinkState = state

function apDeathLinkConfigure(settings)
    if type(settings) ~= "table" then
        return false
    end
    local config = _G.apDeathLink
    for _, key in ipairs({ "enabled", "trigger", "effect", "graceSeconds" }) do
        if settings[key] ~= nil then
            config[key] = settings[key]
        end
    end
    deathLog(string.format("configure: enabled=%s trigger=%s effect=%s grace=%ss",
        tostring(config.enabled), config.trigger, config.effect, tostring(config.graceSeconds)))
    return true
end

local function triggerCoversRunEnd()
    local trigger = _G.apDeathLink.trigger
    return trigger == "ship_destroyed" or trigger == "both"
end

local function triggerCoversCrew()
    local trigger = _G.apDeathLink.trigger
    return trigger == "crew_death" or trigger == "both"
end

local function inGracePeriod()
    if state.lastReceivedAt == nil then
        return false
    end
    local grace = (_G.apDeathLink.graceSeconds or 0) * TICKS_PER_SECOND
    return (state.ticks - state.lastReceivedAt) < grace
end

local SEND_COOLDOWN_SECONDS = 10

function apDeathLinkSend(cause)
    local config = _G.apDeathLink
    if not config.enabled then
        return false
    end
    if state.applying then
        state.ignored = state.ignored + 1
        deathLog("death not sent: it came from a received DeathLink")
        return false
    end
    if inGracePeriod() then
        state.ignored = state.ignored + 1
        deathLog("death not sent: grace period active")
        return false
    end
    -- The last crew member dying also ends the run: one event, so the others die once.
    if state.lastSentAt ~= nil and state.ticks - state.lastSentAt < SEND_COOLDOWN_SECONDS * TICKS_PER_SECOND then
        state.ignored = state.ignored + 1
        deathLog("death not sent: one already went out a moment ago (" .. tostring(cause) .. ")")
        return false
    end

    state.sent = state.sent + 1
    state.lastSentAt = state.ticks

    local sent = false
    if _G.apNetSendDeath then
        local ok, result = pcall(_G.apNetSendDeath, cause)
        if not ok then
            deathLog("send failed: " .. tostring(result))
            return false
        end
        sent = result ~= false
    else
        deathLog("(offline) would have sent a death: " .. tostring(cause))
    end

    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT(sent and "deathlink.sent" or "deathlink.not_sent"))
    end
    return sent
end

local SENT_CAUSES = {
    destroyed = "hull destroyed",
    crew = "crew wiped out",
}

function apDeathLinkOnRunEnd(cause, detail)
    if cause == "victory" or cause == "menu" then
        return false
    end
    if not triggerCoversRunEnd() then
        deathLog("run end '" .. tostring(cause) .. "' ignored by trigger setting")
        return false
    end
    return apDeathLinkSend(SENT_CAUSES[cause] or "ship lost")
end

function apDeathLinkCrewDied(name, species)
    if not triggerCoversCrew() then
        return false
    end
    return apDeathLinkSend((species or "crew") .. " " .. (name or "crew member") .. " died")
end

-- Crew actually stationed on this ship (not a boarder on the enemy's), still alive.
local function aliveCrew(player)
    local alive = {}
    local crew = player.vCrewList
    for i = 0, crew:size() - 1 do
        local member = crew[i]
        if member ~= nil and member.iShipId == 0 and not member.bDead then
            alive[#alive + 1] = member
        end
    end
    return alive
end

local EFFECTS = {}

EFFECTS.major_incident = function(player)
    local candidates = {}
    local systems = player.vSystemList
    for i = 0, systems:size() - 1 do
        local system = systems[i]
        if system ~= nil and system.healthState.first > 0 then
            candidates[#candidates + 1] = system
        end
    end
    if #candidates == 0 then
        return nil
    end

    local target = candidates[math.random(1, #candidates)]
    local roomId = math.floor(target.roomId)
    local label = _G.apSystemLabel and _G.apSystemLabel(target.name) or tostring(target.name)

    local damage = Hyperspace.Damage()
    damage.iDamage = 0
    damage.breachChance = 100
    damage.fireChance = 100
    damage.bFriendlyFire = true
    damage.ownerId = 0
    pcall(function()
        player:DamageArea(player:GetRoomCenter(roomId), damage, true)
    end)

    pcall(function()
        player:StartFire(roomId)
    end)

    local amount = math.min(2, math.max(0, target.healthState.first - 1))
    if amount > 0 then
        pcall(function() target:AddDamage(amount) end)
    end

    return "deathlink.effect.major", { system = label }
end

EFFECTS.crew_member = function(player)
    local alive = aliveCrew(player)
    if #alive < 2 then
        return nil
    end
    local victim = alive[math.random(1, #alive)]
    local name = victim.GetName and victim:GetName() or apT("deathlink.crew.unnamed")
    victim:Kill(true)
    return "deathlink.effect.crew", { name = tostring(name) }
end

EFFECTS.hull_damage = function(player)
    local hull = player.ship.hullIntegrity
    local amount = math.min(3, hull.first - 1)
    if amount <= 0 then
        return nil
    end
    player:DamageHull(amount, true)
    return "deathlink.effect.hull", { n = amount }
end

EFFECTS.boarding = function(player)
    if #aliveCrew(player) < 2 then
        return nil
    end
    local room = _G.apRandomRoomId and _G.apRandomRoomId(player) or nil
    if room == nil then
        return nil
    end
    local ok = pcall(function()
        player:AddCrewMemberFromString("", "mantis", true, room, false, true)
    end)
    if not ok then
        return nil
    end
    return "deathlink.effect.boarding"
end

EFFECTS.fire = function(player)
    local room = _G.apRandomRoomId and _G.apRandomRoomId(player) or nil
    if room == nil then
        return nil
    end
    player:StartFire(room)
    return "deathlink.effect.fire"
end

local FALLBACK_ORDER = { "hull_damage", "fire", "crew_member" }

local function applyEffect(player, wanted)
    local order = { wanted }
    for _, name in ipairs(FALLBACK_ORDER) do
        if name ~= wanted then
            order[#order + 1] = name
        end
    end
    for _, name in ipairs(order) do
        local effect = EFFECTS[name]
        if effect ~= nil then
            local ok, key, params = pcall(effect, player)
            if ok and key ~= nil then
                return key, params
            end
        end
    end
    return nil
end

function apDeathLinkReceive(source, cause)
    local config = _G.apDeathLink
    if not config.enabled then
        return false
    end

    state.received = state.received + 1
    state.lastReceivedAt = state.ticks

    local world = Hyperspace.App.world
    local player = Hyperspace.ships.player
    if world == nil or not world.bStartedGame or player == nil or player.bDestroyed then
        deathLog("death received outside a run, ignored (" .. tostring(source) .. ")")
        return false
    end

    local wanted = config.effect
    if wanted == "varied" then
        local names = { "crew_member", "fire", "hull_damage", "boarding" }
        wanted = names[math.random(1, #names)]
    end

    state.applying = true
    local key, params = applyEffect(player, wanted)
    state.applying = false

    if key == nil then
        deathLog("no effect applicable for the death of " .. tostring(source))
        if _G.apNotifyTrap then
            _G.apNotifyTrap(apT("deathlink.fizzled"))
        end
        return false
    end

    deathLog(string.format("death received from %s (%s) -> %s", tostring(source), tostring(cause), key))
    if _G.apNotifyTrap then
        local who = (source and source ~= "") and source or apT("deathlink.someone")
        _G.apNotifyTrap(apT("deathlink.received",
                            { who = who, effect = apT(key, params) }))
    end
    return true
end

-- Our crew on both ships: the living by name, and those already marked dead.
local function livingCrew()
    local living, dead = {}, {}
    for _, ship in ipairs({ Hyperspace.ships.player, Hyperspace.ships.enemy }) do
        if ship ~= nil then
            local crew = ship.vCrewList
            for i = 0, crew:size() - 1 do
                local member = crew[i]
                local name = member ~= nil and tostring(member.GetName and member:GetName() or ("crew" .. i))
                local health = member ~= nil and member.health and tonumber(member.health.first) or 1
                if member ~= nil and member.iShipId == 0 and member.bDead then
                    dead[name] = health
                elseif member ~= nil and member.iShipId == 0 then
                    living[name] = { species = member.species or "crew", health = health }
                end
            end
        end
    end
    return living, dead
end

-- A crew member who dies lies a few seconds at zero health before FTL marks them dead. One dismissed from
-- the crew screen is marked dead at once, without that moment: the player's choice, not a death.
local function dismissed(name, dead)
    return dead[name] ~= nil and dead[name] <= 0 and not state.dying[name]
end

-- The hangar keeps bStartedGame on while you browse ships, and each ship shown comes with its own crew.
local function runInProgress()
    local ok, started = pcall(function()
        local app = Hyperspace.App
        return app.world.bStartedGame == true and app.menu.shipBuilder.bOpen ~= true
    end)
    return ok and started == true
end

local function sampleCrew()
    if not triggerCoversCrew() then
        state.knownCrew = nil
        return
    end

    if not runInProgress() then
        state.knownCrew = nil
        return
    end

    local ok, current, dead = pcall(livingCrew)
    if not ok then
        return
    end

    if state.knownCrew ~= nil then
        for name, last in pairs(state.knownCrew) do
            if current[name] == nil then
                if dismissed(name, dead) then
                    deathLog(tostring(name) .. " was dismissed: no DeathLink")
                else
                    apDeathLinkCrewDied(name, last.species)
                end
                state.dying[name] = nil
            end
        end
    end
    for name, member in pairs(current) do
        state.dying[name] = member.health <= 0 or nil
    end
    state.knownCrew = current
end

local previousOnRunEnd = _G.apOnRunEnd
_G.apOnRunEnd = function(cause, detail)
    if previousOnRunEnd then
        apTry(TAG, previousOnRunEnd, cause, detail)
    end
    apTry(TAG, apDeathLinkOnRunEnd, cause, detail)
end

local sampleDivider = 0

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    state.ticks = state.ticks + 1
    sampleDivider = (sampleDivider + 1) % 30
    if sampleDivider == 0 and _G.apDeathLink.enabled then
        sampleCrew()
    end
end)

script.on_init(function()
    state.knownCrew = nil
    state.dying = {}
    state.lastSentAt = nil
    state.lastReceivedAt = nil
end)

function apDeathLinkStatus()
    local config = _G.apDeathLink
    deathLog(string.format("DeathLink %s | trigger=%s effect=%s grace=%ss",
        config.enabled and "active" or "inactive", config.trigger, config.effect,
        tostring(config.graceSeconds)))
    deathLog(string.format("  sent=%d received=%d ignored=%d%s",
        state.sent, state.received, state.ignored,
        inGracePeriod() and " (grace period active)" or ""))
end

deathLog("DeathLink module loaded (console: LUA apDeathLinkStatus())")
