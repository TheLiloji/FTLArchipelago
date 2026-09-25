local TAG = "[AP-energy] "

local function energyLog(message)
    log(TAG .. message)
end

local JOULES_PER_FUEL = 1000000

local SCRAP_JOULES = JOULES_PER_FUEL / 30

local DEPOSIT_LOSS = 0.25

_G.apEnergyLink = {
    enabled = false,
    depositFuelAbove = 20,
    depositScrapAbove = 0,
    depositScrapShare = 0.25,
    withdrawFuelBelow = 3,
    withdrawFuelAmount = 2,
}

local state = {
    pool = 0,
    deposited = 0,
    withdrawn = 0,
    pendingRequest = 0,
    withdrawnThisBeacon = false,
    lastError = nil,
}

_G.apEnergyLinkState = state

function apEnergyLinkConfigure(settings)
    if type(settings) ~= "table" then
        return false
    end
    local config = _G.apEnergyLink
    for key, value in pairs(settings) do
        if config[key] ~= nil then
            config[key] = value
        end
    end
    energyLog("configure: enabled=" .. tostring(config.enabled))
    return true
end

local function joulesToFuel(joules)
    local units = math.floor(joules / JOULES_PER_FUEL)
    return units, joules - (units * JOULES_PER_FUEL)
end

local function humanJoules(joules)
    if joules >= 1000000 then
        return string.format("%.1f MJ", joules / 1000000)
    end
    if joules >= 1000 then
        return string.format("%.0f kJ", joules / 1000)
    end
    return string.format("%d J", joules)
end

_G.apEnergyLinkHuman = humanJoules
_G.apEnergyLinkJoulesPerFuel = JOULES_PER_FUEL

-- whole: skip the deposit loss (energy going back to the pool, or already net).
function apEnergyLinkDeposit(joules, whole)
    if joules <= 0 then
        return 0
    end
    if not (_G.apEnergyLink and _G.apEnergyLink.enabled) then
        energyLog("energy link disabled by the seed: nothing deposited")
        return 0
    end
    local net = whole and math.floor(joules) or math.floor(joules * (1 - DEPOSIT_LOSS))
    if net <= 0 then
        return 0
    end

    if _G.apNetEnergyLinkDeposit then
        local ok, sent = pcall(_G.apNetEnergyLinkDeposit, net)
        if not ok then
            state.lastError = tostring(sent)
            energyLog("deposit failed: " .. tostring(sent))
            return 0
        end
        if sent == false then
            state.lastError = "deposit refused by the server"
            energyLog("deposit REFUSED: " .. humanJoules(net) .. " did not go through")
            return 0
        end
        energyLog("deposited to the server: " .. humanJoules(net))
    else
        energyLog("(offline) would have deposited " .. humanJoules(net))
    end

    state.deposited = state.deposited + net
    state.pool = state.pool + net
    return net
end

function apEnergyLinkContribute()
    local config = _G.apEnergyLink
    if not config.enabled then
        return 0
    end
    local player = Hyperspace.ships.player
    if player == nil then
        return 0
    end

    local joules = 0
    local given = {}
    local fuelToTake = 0
    local scrapToTake = 0

    local surplus = player.fuel_count - config.depositFuelAbove
    if surplus > 0 then
        fuelToTake = surplus
        joules = joules + surplus * JOULES_PER_FUEL
        given[#given + 1] = apT("energylink.part.fuel", { n = surplus })
    end

    if config.depositScrapAbove > 0 then
        local ok, scrap = pcall(function()
            return Hyperspace.ships.player.currentScrap
        end)
        if ok and type(scrap) == "number" and scrap > config.depositScrapAbove then
            local share = math.floor((scrap - config.depositScrapAbove) * config.depositScrapShare)
            if share > 0 then
                scrapToTake = share
                joules = joules + share * SCRAP_JOULES
                given[#given + 1] = apT("energylink.part.scrap", { n = share })
            end
        end
    end

    if joules <= 0 then
        return 0
    end

    local net = apEnergyLinkDeposit(joules)
    if net <= 0 then
        return 0
    end

    player.fuel_count = player.fuel_count - fuelToTake
    if scrapToTake > 0 then
        player:ModifyScrapCount(-scrapToTake, false)
    end

    if net > 0 then
        energyLog("deposited " .. table.concat(given, " + ") .. " = " .. humanJoules(net)
            .. " (after " .. math.floor(DEPOSIT_LOSS * 100) .. "% loss)")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("energylink.sent", { what = table.concat(given, " + ") }))
        end
    end
    return net
end

function apEnergyLinkRequestFuel(units)
    local config = _G.apEnergyLink
    if not config.enabled then
        return false
    end
    units = units or config.withdrawFuelAmount
    if units <= 0 then
        return false
    end

    local joules = units * JOULES_PER_FUEL
    state.pendingRequest = state.pendingRequest + joules

    if _G.apNetEnergyLinkRequest then
        local ok, sent = pcall(_G.apNetEnergyLinkRequest, joules)
        if not ok then
            state.pendingRequest = state.pendingRequest - joules
            state.lastError = tostring(sent)
            energyLog("request failed: " .. tostring(sent))
            return false
        end
        if sent == false then
            state.pendingRequest = state.pendingRequest - joules
            state.lastError = "request refused by the server"
            energyLog("request REFUSED: " .. humanJoules(joules))
            return false
        end
    else
        state.pendingRequest = state.pendingRequest - joules
        energyLog("(offline) would have requested " .. humanJoules(joules))
        return false
    end
    return true
end

function apEnergyLinkGranted(joules)
    state.pendingRequest = math.max(0, state.pendingRequest - joules)
    if joules <= 0 then
        energyLog("pool empty: no fuel granted")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("energylink.empty"))
        end
        return 0
    end

    local units, remainder = joulesToFuel(joules)
    if units <= 0 then
        apEnergyLinkDeposit(joules, true)
        energyLog("granted " .. humanJoules(joules) .. ", not enough for one unit: returned")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("energylink.empty"))
        end
        return 0
    end

    local player = Hyperspace.ships.player
    if player == nil then
        apEnergyLinkDeposit(joules, true)
        return 0
    end

    player.fuel_count = player.fuel_count + units
    state.withdrawn = state.withdrawn + (units * JOULES_PER_FUEL)
    state.pool = math.max(0, state.pool - joules)

    if remainder > 0 then
        apEnergyLinkDeposit(remainder, true)
    end

    energyLog("received " .. units .. " fuel unit(s) from the shared pool")
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT("energylink.received", { n = units }))
    end
    return units
end

function apEnergyLinkSync(joules)
    state.pool = joules or 0
end

local function considerWithdrawal()
    local config = _G.apEnergyLink
    if not config.enabled or state.withdrawnThisBeacon then
        return
    end
    local player = Hyperspace.ships.player
    if player == nil or player.fuel_count > config.withdrawFuelBelow then
        return
    end
    state.withdrawnThisBeacon = true
    energyLog("fuel at " .. player.fuel_count .. ": requesting from the shared pool")
    apEnergyLinkRequestFuel(config.withdrawFuelAmount)
end

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager.iShipId ~= 0 then
        return
    end
    state.withdrawnThisBeacon = false
    considerWithdrawal()
    apTry(TAG, apEnergyLinkContribute)
end)

script.on_init(function()
    state.withdrawnThisBeacon = false
    state.pendingRequest = 0
end)

function apEnergyLinkStatus()
    local config = _G.apEnergyLink
    energyLog("EnergyLink " .. (config.enabled and "active" or "inactive")
        .. " | 1 fuel = " .. humanJoules(JOULES_PER_FUEL)
        .. ", deposit loss " .. math.floor(DEPOSIT_LOSS * 100) .. "%")
    energyLog(string.format("  known pool=%s deposited=%s withdrawn=%s",
        humanJoules(state.pool), humanJoules(state.deposited), humanJoules(state.withdrawn)))
    energyLog(string.format("  deposit above %d fuel, request below %d",
        config.depositFuelAbove, config.withdrawFuelBelow))
end

energyLog("EnergyLink module loaded (console: LUA apEnergyLinkStatus())")
