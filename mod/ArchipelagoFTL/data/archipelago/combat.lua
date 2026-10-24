local TAG = "[AP-combat] "

local function combatLog(message)
    log(TAG .. message)
end

-- Combat checks: with each ship, the first fights won in a run send "<ship>:fight:<n>". A fight that sends
-- one gives part of its scrap only; missiles, fuel and drone parts stay as they are.
local countedHere = false
-- The enemy here fought us: an enemy that then stops being hostile while still alive accepted its surrender.
local sawHostile = false
-- An enemy that jumped away was not beaten: nothing counts at this beacon after that.
local escapedHere = false
local beatenTicks = 0
local BEATEN_GRACE_TICKS = 180

local function isHostile(enemy)
    local ok, hostile = pcall(function() return enemy._targetable.hostile end)
    return ok and hostile == true
end

local function fightsWon()
    -- The game keeps run variables as floats: 1.0 would make the key "fight:1.0".
    local ok, value = pcall(function() return Hyperspace.playerVariables.ap_fights_won end)
    return ok and math.floor(tonumber(value) or 0) or 0
end

local function setFightsWon(n)
    pcall(function() Hyperspace.playerVariables.ap_fights_won = n end)
end

local function memberIs(member, method)
    local ok, result = pcall(function() return member[method](member) end)
    return ok and result == true
end

-- The enemy's own crew still alive, wherever they are: on their ship or boarding ours. Drones and crew that fade
-- away on their own (Multiverse holograms, projections) are not crew to kill.
local function enemyCrewAlive()
    local alive = 0
    for _, ship in ipairs({ Hyperspace.ships.enemy, Hyperspace.ships.player }) do
        if ship ~= nil then
            local list = ship.vCrewList
            for i = 0, list:size() - 1 do
                local member = list[i]
                if member ~= nil and member.iShipId == 1 and not member.bDead and not memberIs(member, "IsDrone") then
                    local okTemp, temporary = pcall(function()
                        return member.extend.deathTimer ~= nil or member.extend.noSlot == true
                    end)
                    if not (okTemp and temporary) then
                        alive = alive + 1
                    end
                end
            end
        end
    end
    return alive
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
    local ok, crew = pcall(enemyCrewAlive)
    return ok and crew == 0
end

local function enemySurrendered(enemy)
    return enemy ~= nil and sawHostile and not enemy.bDestroyed and not isHostile(enemy)
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
    local enemy = Hyperspace.ships.enemy
    if countedHere or escapedHere or not (enemyBeaten(enemy) or enemySurrendered(enemy)) then
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

local function runStarted()
    local ok, started = pcall(function() return Hyperspace.App.world.bStartedGame == true end)
    return ok and started == true
end

-- Fights the run counted but the server never got: won offline before a crash, the counter comes back with the
-- save while the check was only in memory. Sent on connecting and at each beacon.
function apCombatCatchUp()
    local ship = currentShip()
    if ship == nil or not runStarted() or not (_G.apNetConnected and apNetConnected()) then
        return 0
    end
    local caught = 0
    for n = 1, fightsWon() do
        local key = ship .. ":fight:" .. n
        if _G.apLocationNameFor and apLocationNameFor(key) and not apCheckAlreadySent(key) then
            local label = apT("check.label.fight", { n = n, ship = (_G.apShipLabel and apShipLabel(ship)) or ship })
            if apSendCheck(key, label) then
                caught = caught + 1
            end
        end
    end
    if caught > 0 then
        combatLog(caught .. " fight(s) won earlier in the run sent now")
    end
    return caught
end

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
    apTry(TAG, function() apCombatReward(event) end)
end)

-- A surrender accepted with a reward counts on its choice box; one that only makes peace, on the next frame.
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    local enemy = Hyperspace.ships.enemy
    if enemy == nil or countedHere then
        return
    end
    local okJump, jumping = pcall(function() return enemy.bJumping == true end)
    if okJump and jumping and not enemy.bDestroyed then
        if not escapedHere then
            combatLog("the enemy jumped away: no fight won here")
        end
        escapedHere = true
        return
    end
    if isHostile(enemy) then
        sawHostile = true
        -- The reward box counts the fight and cuts its scrap. A dead crew whose box never came (a Multiverse chain
        -- of events, the last crew member marked dead late) still counts, a few seconds later.
        local okCrew, crewLeft = pcall(enemyCrewAlive)
        local okHull, hull = pcall(function() return enemy.ship.hullIntegrity.first end)
        if not enemy.bAutomated and okCrew and crewLeft == 0 and okHull and tonumber(hull) and hull > 0 then
            beatenTicks = beatenTicks + 1
            if beatenTicks >= BEATEN_GRACE_TICKS then
                apTry(TAG, function() apCombatReward(nil) end)
            end
        else
            beatenTicks = 0
        end
    elseif sawHostile then
        apTry(TAG, function() apCombatReward(nil) end)
    end
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager.iShipId == 0 then
        countedHere = false
        sawHostile = false
        escapedHere = false
        beatenTicks = 0
        apTry(TAG, apCombatCatchUp)
    end
end)

script.on_init(function(newGame)
    countedHere = false
    sawHostile = false
    escapedHere = false
    if newGame then
        setFightsWon(0)
    end
end)

combatLog("combat module loaded")
