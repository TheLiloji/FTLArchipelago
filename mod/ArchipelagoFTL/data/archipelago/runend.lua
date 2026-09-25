local TAG = "[AP-end] "

local function endLog(message)
    log(TAG .. message)
end

local run = {
    active = false,
    ended = false,
    crewSeen = false,
}

function apOnRunEnd(cause, detail)
    endLog("RUN END: " .. cause .. (detail and (" - " .. detail) or ""))
end

local function declareEnd(cause, detail)
    if run.ended then
        return
    end
    run.ended = true
    apOnRunEnd(cause, detail)
end

local function countRealCrew(shipManager)
    local alive = 0
    local crewList = shipManager.vCrewList
    for i = 0, crewList:size() - 1 do
        local crew = crewList[i]
        if crew ~= nil and crew:CountForVictory() and crew.iShipId == 0 then
            alive = alive + 1
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

        if not started or run.ended then
            return
        end

        local player = Hyperspace.ships.player
        if player == nil then
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
        elseif run.crewSeen then
            apEndSnapshot("state at loss of crew:")
            declareEnd("crew", "no living crew left")
        end
    end)
end)

script.on_init(function(newGame)
    run.active = true
    run.ended = false
    run.crewSeen = false
    endLog("run started (newGame=" .. tostring(newGame) .. "), detection armed")
end)

endLog("run-end detection module loaded")
