local TAG = "[AP-crewnames] "

local function namesLog(message)
    log(TAG .. message)
end

-- crew_names: the starting crew of a new run, then each crew member who joins, takes the name of another player
-- of the multiworld, then (multiworld_and_team) of someone who made or tested the mod. Once every name is aboard,
-- FTL's own stay. A continued run keeps the names it was saved with.
-- The people thanked in the README, in short ASCII forms (FTL's own names go up to 15 letters).
local TEAM = { "Liloji", "Trapper", "Eto", "File Missing", "Yunus", "Tom", "Rhythm", "Otto", "Cigogne", "SynthKat",
               "Astron", "Three", "Mulac", "Richard", "Nowi", "Maple", "Jam", "Wyndrose", "Fletchy", "Mongolico",
               "Simba", "Roobyroo", "Studkid", "Duck", "Kholdstare" }

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

-- Holograms, projections, pets and other crew without a crew slot keep FTL's name: see deathlink.lua.
local function temporary(member)
    local ok, result = pcall(function()
        local extend = member.extend
        return extend.deathTimer ~= nil or extend.noSlot == true
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

-- Multiverse's unique characters keep their own names: they are people of its story.
local function unique(member)
    local ok, species = pcall(function() return tostring(member.species or "") end)
    return ok and species:match("^unique") ~= nil
end

-- Our own crew aboard, alive: what gets a name.
local function ownCrew()
    local crew = {}
    local list = Hyperspace.ships.player.vCrewList
    for i = 0, list:size() - 1 do
        local member = list[i]
        if member ~= nil and member.iShipId == 0 and not member.bDead and not memberIs(member, "IsDrone")
            and not temporary(member) and not unique(member) then
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

-- The crew aboard when a run is continued is known and keeps its names; a new run's starting crew is renamed
-- like the crew members who join later.
local known = nil
local renameStart = false

local function giveName(member, crew, pool)
    if #pool == 0 then
        return
    end
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
            return
        end
    end
end

local function sample()
    if not runInProgress() or Hyperspace.ships.player == nil then
        known = nil
        return
    end
    local crew = ownCrew()
    local pool = apCrewNamesPool()
    if known == nil then
        known = {}
        local starting = renameStart
        renameStart = false
        for _, member in ipairs(crew) do
            known[crewKey(member)] = true
            if starting then
                giveName(member, crew, pool)
            end
        end
        return
    end
    for _, member in ipairs(crew) do
        local key = crewKey(member)
        if not known[key] then
            known[key] = true
            giveName(member, crew, pool)
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

script.on_init(function(newGame)
    known = nil
    renameStart = newGame == true
end)

script.on_internal_event(Defines.InternalEvents.MAIN_MENU, function()
    known = nil
end)

namesLog("crew names module loaded")
