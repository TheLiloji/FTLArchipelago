local TAG = "[AP-crewnames] "

local function namesLog(message)
    log(TAG .. message)
end

-- crew_names: a crew member who joins during a run takes the name of another player of the multiworld, then
-- (multiworld_and_team) of someone who made or tested the mod. Once every name is aboard, FTL's own stay.
local TEAM = { "Liloji", "Trapper", "Eto", "File Missing", "Yunus", "Rhythm", "Duck", "Fletchy", "Mongolico",
               "Studkid", "Simba", "Astron" }

local config = { mode = "vanilla", players = {} }

-- FTL's fonts only draw plain ASCII: a slot name with anything else would show holes.
local function drawable(name)
    return type(name) == "string" and name:match("^[ -~]+$") ~= nil and name:match("%S") ~= nil
end

function apCrewNamesConfigure(mode, players)
    config.mode = (mode == "multiworld" or mode == "multiworld_and_team") and mode or "vanilla"
    config.players = {}
    for _, name in ipairs(type(players) == "table" and players or {}) do
        if drawable(name) then
            config.players[#config.players + 1] = name
        end
    end
    namesLog(string.format("mode %s, %d player name(s)", config.mode, #config.players))
end

function apCrewNamesPool()
    local pool = {}
    if config.mode == "vanilla" then
        return pool
    end
    for _, name in ipairs(config.players) do
        pool[#pool + 1] = name
    end
    if config.mode == "multiworld_and_team" then
        for _, name in ipairs(TEAM) do
            pool[#pool + 1] = name
        end
    end
    return pool
end

local function memberIs(member, method)
    local ok, result = pcall(function() return member[method](member) end)
    return ok and result == true
end

-- Holograms, projections and other crew that fade away on their own keep FTL's name: see deathlink.lua.
local function temporary(member)
    local ok, result = pcall(function()
        local extend = member.extend
        return extend.deathTimer ~= nil or (extend.noSlot == true and extend.noClone == true)
    end)
    return ok and result == true
end

local function crewKey(member)
    local ok, id = pcall(function() return member.extend.selfId end)
    if ok and id ~= nil and id >= 0 then
        return "id" .. tostring(id)
    end
    return "name:" .. tostring(member:GetName())
end

local function runInProgress()
    local ok, started = pcall(function()
        local app = Hyperspace.App
        return app.world.bStartedGame == true and app.menu.shipBuilder.bOpen ~= true
    end)
    return ok and started == true
end

-- Our own crew aboard, alive: what gets a name.
local function ownCrew()
    local crew = {}
    local list = Hyperspace.ships.player.vCrewList
    for i = 0, list:size() - 1 do
        local member = list[i]
        if member ~= nil and member.iShipId == 0 and not member.bDead and not memberIs(member, "IsDrone")
            and not temporary(member) then
            crew[#crew + 1] = member
        end
    end
    return crew
end

local function rename(member, name)
    local ok, err = pcall(function()
        local text = Hyperspace.TextString()
        text.data = name
        text.isLiteral = true
        member:SetName(text, true)
    end)
    if not ok then
        namesLog("rename failed: " .. tostring(err))
    end
    return ok
end

-- The crew aboard when a run starts or is continued is known: only those who join later get a new name.
local known = nil

local function sample()
    if not runInProgress() or Hyperspace.ships.player == nil then
        known = nil
        return
    end
    local crew = ownCrew()
    if known == nil then
        known = {}
        for _, member in ipairs(crew) do
            known[crewKey(member)] = true
        end
        return
    end
    local pool = apCrewNamesPool()
    for _, member in ipairs(crew) do
        local key = crewKey(member)
        if not known[key] then
            known[key] = true
            if #pool > 0 then
                local used = {}
                for _, other in ipairs(crew) do
                    used[tostring(other:GetName())] = true
                end
                for _, name in ipairs(pool) do
                    if not used[name] then
                        local before = tostring(member:GetName())
                        if rename(member, name) then
                            namesLog(before .. " joins as " .. name)
                        end
                        break
                    end
                end
            end
        end
    end
end

local divider = 0
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    divider = (divider + 1) % 30
    if divider == 0 then
        apTry(TAG, sample)
    end
end)

script.on_init(function()
    known = nil
end)

script.on_internal_event(Defines.InternalEvents.MAIN_MENU, function()
    known = nil
end)

namesLog("crew names module loaded")
