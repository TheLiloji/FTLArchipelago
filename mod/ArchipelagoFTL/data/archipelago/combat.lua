local TAG = "[AP-combat] "

local function combatLog(message)
    log(TAG .. message)
end

-- Combat checks: with each ship, the first fights won in a run send "<ship>:fight:<n>". A fight that sends
-- one gives part of its scrap only; missiles, fuel and drone parts stay as they are.
local countedHere = false

local function fightsWon()
    -- The game keeps run variables as floats: 1.0 would make the key "fight:1.0".
    local ok, value = pcall(function() return Hyperspace.playerVariables.ap_fights_won end)
    return ok and math.floor(tonumber(value) or 0) or 0
end

local function setFightsWon(n)
    pcall(function() Hyperspace.playerVariables.ap_fights_won = n end)
end

local function enemyBeaten(enemy)
    if enemy == nil then
        return false
    end
    -- bDestroyed only comes once the explosion is over, after the reward box: an empty hull is enough.
    local okHull, hull = pcall(function() return enemy.ship.hullIntegrity.first end)
    if enemy.bDestroyed or (okHull and tonumber(hull) and hull <= 0) then
        return true
    end
    -- An automated ship has no crew to kill: only its destruction counts.
    if enemy.bAutomated then
        return false
    end
    local ok, crew = pcall(function() return enemy:CountCrew(false) end)
    return ok and crew == 0
end

local function currentShip()
    local ok, name = pcall(function() return Hyperspace.ships.player.myBlueprint.blueprintName end)
    return ok and name and (tostring(name):gsub("_[23]$", "")) or nil
end

-- For the dashboard: fights won this run and the fight checks this ship still has.
function apCombatStatus()
    local ship = currentShip()
    local total, left, nextSends = 0, 0, false
    local won = fightsWon()
    for n = 1, 10 do
        local key = ship and (ship .. ":fight:" .. n) or nil
        if key and _G.apLocationNameFor and apLocationNameFor(key) then
            total = total + 1
            if not apCheckAlreadySent(key) then
                left = left + 1
                if n == won + 1 then
                    nextSends = true
                end
            end
        end
    end
    return { won = won, total = total, left = left, nextSends = nextSends }
end

function apCombatReward(event)
    if countedHere or not enemyBeaten(Hyperspace.ships.enemy) then
        return false
    end
    countedHere = true
    local n = fightsWon() + 1
    setFightsWon(n)
    local ship = currentShip()
    if ship == nil then
        return false
    end
    local key = ship .. ":fight:" .. n
    if not (_G.apLocationNameFor and apLocationNameFor(key)) or apCheckAlreadySent(key) then
        return false
    end
    local label = apT("check.label.fight", { n = n, ship = (_G.apShipLabel and apShipLabel(ship)) or ship })
    if not apSendCheck(key, label) then
        return false
    end
    local percent = tonumber(_G.apSeedOption and apSeedOption("combat_check_scrap") or 100) or 100
    local ok, scrap = pcall(function() return event.stuff.scrap end)
    if ok and tonumber(scrap) and scrap > 0 and percent < 100 then
        local kept = math.floor(scrap * percent / 100)
        pcall(function() event.stuff.scrap = kept end)
        combatLog(string.format("fight %d won: check sent, scrap %d -> %d", n, scrap, kept))
    else
        combatLog(string.format("fight %d won: check sent", n))
    end
    return true
end

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
    apTry(TAG, function() apCombatReward(event) end)
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager.iShipId == 0 then
        countedHere = false
    end
end)

script.on_init(function(newGame)
    countedHere = false
    if newGame then
        setFightsWon(0)
    end
end)

combatLog("combat module loaded")
