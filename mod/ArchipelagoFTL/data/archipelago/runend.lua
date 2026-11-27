local TAG = "[AP-end] "

local function endLog(message)
    log(TAG .. message)
end

local run = {
    active = false,
    ended = false,
    crewSeen = false,
    cloneLogged = false,
}

local CLONE_BAY = 13
-- A crew member teleporting is in neither ship for a moment: a whole crew boarding the enemy reads as no crew at
-- all. The crew is lost only after this long with nobody (15 ticks between two looks, about 4 seconds).
local CREW_LOSS_POLLS = 16

-- With every crew member dead but some waiting in a working Clone Bay, FTL goes on: they come back. The dead
-- only join its queue on the next frame: until then they still lie in the crew list, marked dead.
local function cloneBayWaiting(player)
    local ok, waiting = pcall(function()
        if not player:HasSystem(CLONE_BAY) then
            return false
        end
        if Hyperspace.CrewFactory:GetCloneReadyList(true):size() > 0 then
            return true
        end
        local crew = player.vCrewList
        for i = 0, crew:size() - 1 do
            if crew[i] ~= nil and crew[i].bDead and crew[i].iShipId == 0 then
                return true
            end
        end
        return false
    end)
    return ok and waiting == true
end

function apOnRunEnd(cause, detail)
    endLog("RUN END: " .. cause .. (detail and (" - " .. detail) or ""))
end

local function declareEnd(cause, detail)
    if run.ended then
        return
    end
    run.ended = true
    run.cause = cause
    apOnRunEnd(cause, detail)
end

-- Our crew away on the enemy ship sits in the enemy's list: the whole crew boarding is not the whole crew dying.
local function countRealCrew(shipManager)
    local alive = 0
    for _, ship in ipairs({ shipManager, Hyperspace.ships.enemy }) do
        local crewList = ship and ship.vCrewList
        if crewList ~= nil then
            for i = 0, crewList:size() - 1 do
                local crew = crewList[i]
                if crew ~= nil and crew:CountForVictory() and crew.iShipId == 0 then
                    alive = alive + 1
                end
            end
        end
    end
    return alive
end

function apEndSnapshot(prefix)
    local ok, message = pcall(function()
        local world = Hyperspace.App.world
        local parts = { "started=" .. tostring(world.bStartedGame) }

        local player = Hyperspace.ships.player
        if player ~= nil then
            parts[#parts + 1] = string.format("player{hull=%d/%d destroyed=%s crew=%d}",
                player.ship.hullIntegrity.first, player.ship.hullIntegrity.second,
                tostring(player.bDestroyed), countRealCrew(player))
        end

        local starMap = world.starMap
        if starMap ~= nil then
            local loc = starMap.currentLoc
            parts[#parts + 1] = string.format("sector=%d boss=%s",
                math.floor(starMap.worldLevel) + 1,
                loc ~= nil and tostring(loc.boss) or "?")
        end

        return table.concat(parts, " ")
    end)
    endLog((prefix or "state") .. " " .. (ok and message or ("unreadable: " .. tostring(message))))
end

script.on_game_event("BOSS_DESTROYED", false, function()
    declareEnd("victory", "flagship destroyed")
end)

local pollDivider = 0

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    pollDivider = (pollDivider + 1) % 15
    if pollDivider ~= 0 then
        return
    end

    pcall(function()
        local world = Hyperspace.App.world
        local started = world.bStartedGame

        if started ~= run.active then
            run.active = started
            if not started and not run.ended then
                declareEnd("menu", "back to main menu")
            end
        end

        if not started then
            return
        end

        local player = Hyperspace.ships.player
        if player == nil then
            return
        end

        if run.ended then
            -- A crew loss was declared, yet someone is aboard and the run goes on: it was not over, so its end
            -- (a victory above all) must still count.
            if run.cause == "crew" and not player.bDestroyed and countRealCrew(player) > 0 then
                run.ended, run.cause, run.crewZero = false, nil, 0
                endLog("crew aboard again: the run was not over, run-end detection armed again")
            end
            return
        end

        if player.bDestroyed then
            apEndSnapshot("state at destruction:")
            declareEnd("destroyed", "hull destroyed")
            return
        end

        local alive = countRealCrew(player)
        if alive > 0 then
            run.crewSeen = true
            run.cloneLogged = false
            run.crewZero = 0
        elseif run.crewSeen then
            if cloneBayWaiting(player) then
                if not run.cloneLogged then
                    run.cloneLogged = true
                    endLog("no living crew, but the Clone Bay brings some back: the run goes on")
                end
                return
            end
            run.crewZero = (run.crewZero or 0) + 1
            if run.crewZero < CREW_LOSS_POLLS then
                return
            end
            apEndSnapshot("state at loss of crew:")
            declareEnd("crew", "no living crew left")
        end
    end)
end)

script.on_init(function(newGame)
    run.active = true
    run.ended = false
    run.cause = nil
    run.crewZero = 0
    run.crewSeen = false
    run.cloneLogged = false
    endLog("run started (newGame=" .. tostring(newGame) .. "), detection armed")
end)

endLog("run-end detection module loaded")
