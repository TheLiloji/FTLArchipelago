local TAG = "[AP-check] "

local function checkLog(message)
    log(TAG .. message)
end

local sent = {}
local lastSector = nil

local unsent = {}

local SENT, PENDING, NO_LOCATION = "sent", "pending", "no_location"

local function pushToServer(id)
    if _G.apNetSendCheck == nil or _G.apLocationNameFor == nil then
        return PENDING
    end
    local name = _G.apLocationNameFor(id)
    if name == nil then
        if _G.apSeedKnowsLocations and _G.apSeedKnowsLocations() then
            return NO_LOCATION
        end
        return PENDING
    end
    local ok, accepted = pcall(_G.apNetSendCheck, name)
    if ok and accepted ~= false then
        return SENT
    end
    return PENDING
end

function apResendPendingChecks()
    if #unsent == 0 then
        return 0
    end
    local still = {}
    local sentCount = 0
    for _, id in ipairs(unsent) do
        local issue = pushToServer(id)
        if issue == SENT then
            sentCount = sentCount + 1
        elseif issue == PENDING then
            still[#still + 1] = id
        end
    end
    unsent = still
    if sentCount > 0 then
        checkLog(sentCount .. " pending check(s) resent, " .. #unsent .. " remaining")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("check.resent", { n = sentCount }))
        end
    end
    return sentCount
end

function apPendingCheckCount()
    return #unsent
end

local tutorialWarned = false
local outOfSeed = {}

-- A run only counts for a seed that was loaded when it started, and still is: a run played without one
-- has none of the seed's limits.
local runSeed = nil
local seedlessWarned = false

local function seedLoaded()
    local contract = _G.apContractState
    return contract ~= nil and contract.connected == true
end

local function currentSeed()
    return seedLoaded() and (_G.apSeedFingerprint and apSeedFingerprint() or 0) or nil
end

function apRunCounts()
    local seed = currentSeed()
    local started = runSeed == seed or (_G.apRunStartCheckForTesting == false and seed ~= nil)
    if seed ~= nil and started then
        return true
    end
    if not seedlessWarned then
        seedlessWarned = true
        checkLog("this run was not started with the current seed loaded: nothing it does counts")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("check.run_without_seed"))
        end
    end
    return false
end

function apSendCheck(id, label)
    if sent[id] then
        return false
    end

    if not apRunCounts() then
        return false
    end

    if _G.apTutorialRunning and _G.apTutorialRunning() then
        if not tutorialWarned then
            tutorialWarned = true
            checkLog("tutorial in progress: no check is sent to the server")
        end
        return false
    end

    local name = _G.apLocationNameFor and _G.apLocationNameFor(id) or nil
    local onServer = (_G.apNetConnected and _G.apNetConnected()) or _G.apSoloEnabled
    if name == nil and onServer and _G.apSeedKnowsLocations and _G.apSeedKnowsLocations() then
        if not outOfSeed[id] then
            outOfSeed[id] = true
            checkLog("out of seed, nothing announced or sent: " .. tostring(id))
        end
        return false
    end

    sent[id] = true
    checkLog("CHECK " .. id .. (label and ("  (" .. label .. ")") or ""))

    if pushToServer(id) == PENDING then
        unsent[#unsent + 1] = id
    end

    if _G.apNotifyCheck then
        _G.apNotifyCheck(name or label or id)
    end
    return true
end

function apCheckAlreadySent(id)
    return sent[id] == true
end

function apCheckCount()
    local sentCount = 0
    for _ in pairs(sent) do
        sentCount = sentCount + 1
    end

    local total = 0
    if _G.apContractState and _G.apContractState.locNames then
        for _ in pairs(_G.apContractState.locNames) do
            total = total + 1
        end
    end

    return { sent = sentCount, total = total }
end

function apAdoptCheckedLocations(names)
    if type(names) ~= "table" then
        return 0
    end
    local adopted = 0
    for _, name in ipairs(names) do
        local key = _G.apCheckKeyFor and _G.apCheckKeyFor(name) or nil
        if key ~= nil and _G.apLocationNameFor and _G.apLocationNameFor(key) ~= nil
            and not sent[key] then
            sent[key] = true
            adopted = adopted + 1
        end
    end

    local still = {}
    for _, id in ipairs(unsent) do
        local known = false
        for _, name in ipairs(names) do
            if _G.apLocationNameFor and _G.apLocationNameFor(id) == name then
                known = true
                break
            end
        end
        if not known then still[#still + 1] = id end
    end
    local already = #unsent - #still
    unsent = still
    if already > 0 then
        checkLog(already .. " pending check(s) the server already knew about: not resent")
    end

    if adopted > 0 then
        checkLog(adopted .. " check(s) recovered from the server")
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("check.adopted", { n = adopted }))
        end
    end
    return adopted
end

function apForgetChecks()
    sent = {}
    unsent = {}
    outOfSeed = {}
end

function apRestoreSentChecks(keys)
    for _, key in ipairs(keys) do
        sent[key] = true
    end
end

function apForgetChecksForTesting()
    sent = {}
    unsent = {}
    tutorialWarned = false
    outOfSeed = {}
    checkLog("checks forgotten (tests)")
end

local function currentLayout()
    local ok, name = pcall(function()
        return Hyperspace.ships.player.myBlueprint.blueprintName
    end)
    if ok and name and name ~= "" then
        return name
    end
    return nil
end

local function watchedAchievements(layout)
    local data = _G.apGameData
    if data == nil then
        return {}
    end

    local watched = {}
    for _, ach in ipairs(data.generalAchievements) do
        watched[#watched + 1] = ach
    end

    local base = layout and layout:gsub("_[23]$", "") or nil
    if base and data.shipAchievements[base] then
        for _, ach in ipairs(data.shipAchievements[base]) do
            watched[#watched + 1] = ach
        end
    end
    return watched
end

local function pollAchievements(layout)
    local tracker = Hyperspace.CustomAchievementTracker.instance
    for _, ach in ipairs(watchedAchievements(layout)) do
        local ok, status = pcall(function()
            return tracker:GetAchievementStatus(ach)
        end)
        if ok and status ~= nil and status >= 0 then
            apSendCheck("ach:" .. ach,
                apT("check.label.achievement", { name = apAchievementLabel(ach) }))
        end
    end
end

local function pollSystems()
    local player = Hyperspace.ships.player
    if player == nil then
        return
    end
    local systems = player.vSystemList
    for index = 0, systems:size() - 1 do
        local system = systems[index]
        local name = Hyperspace.ShipSystem.SystemIdToName(system.iSystemType)
        if name ~= nil and name ~= "" then
            local label = (_G.apSystemLabel and _G.apSystemLabel(name)) or name
            apSendCheck("sys:" .. name, apT("check.label.system", { name = label }))
            local level = system.powerState and system.powerState.second or 1
            for tier = 2, level do
                apSendCheck("sys:" .. name .. ":" .. tier,
                    apT("check.label.system.level", { name = label, n = tier }))
            end
        end
    end
end

local startingRaces = nil

local function racesAboard()
    local races = {}
    local player = Hyperspace.ships.player
    if player == nil then
        return nil
    end
    local list = player.vCrewList
    for index = 0, list:size() - 1 do
        local member = list[index]
        local drone = false
        if member.IsDrone ~= nil then
            local ok, result = pcall(function() return member:IsDrone() end)
            drone = ok and result == true
        end
        if member.iShipId == 0 and not member.bDead and not drone then
            local species = tostring(member.species or "")
            if species ~= "" then
                races[species] = true
            end
        end
    end
    return races
end

local function pollCrew()
    local present = racesAboard()
    if present == nil then
        return
    end
    if startingRaces == nil then
        startingRaces = present
        return
    end
    for species in pairs(present) do
        if not startingRaces[species] then
            local label = (_G.apRaceLabel and _G.apRaceLabel(species)) or species
            apSendCheck("crew:" .. species, apT("check.label.crew", { name = label }))
        end
    end
end

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if startingRaces == nil then
        pcall(function()
            startingRaces = racesAboard()
        end)
    end
end)

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager.iShipId ~= 0 then
        return
    end

    apTry(TAG, function()
        local layout = currentLayout()
        local starMap = Hyperspace.App.world.starMap
        local sector = math.floor(starMap.worldLevel) + 1

        if layout and sector ~= lastSector then
            lastSector = sector
            apSendCheck(layout .. ":sector:" .. sector,
                apT("check.label.sector",
                    { n = sector, ship = (_G.apShipLabel and _G.apShipLabel(layout)) or layout }))
        end

        pollAchievements(layout)
        pollSystems()
        pollCrew()
    end)
end)

local previousOnRunEnd = apOnRunEnd

function apOnRunEnd(cause, detail)
    if previousOnRunEnd then
        previousOnRunEnd(cause, detail)
    end
    if cause ~= "victory" then
        return
    end
    apTry(TAG, function()
        local layout = currentLayout()
        if layout then
            apSendCheck(layout .. ":victory",
                apT("check.label.victory",
                    { ship = (_G.apShipLabel and _G.apShipLabel(layout)) or layout }))
            apVictoryWith(layout)
        else
            checkLog("victory detected but unknown ship")
            if _G.apNotifyStatus then
                _G.apNotifyStatus(apT("check.victory.unknown_ship"))
            end
        end
    end)
end

script.on_init(function()
    lastSector = nil
    startingRaces = nil
    runSeed = currentSeed()
    seedlessWarned = false
end)

-- Solo started from the test key during a run: the run had no seed yet and takes this one.
function apRunAdoptSeed()
    if runSeed == nil then
        runSeed = currentSeed()
    end
end

function apRunSeedForTesting(value)
    runSeed = value
    seedlessWarned = false
end

local victories = {}
local goalAnnounced = false
local victoriesFor = nil

local function victoryKey(layout)
    return "ap_goalwin_" .. tostring(_G.apSeedFingerprint and apSeedFingerprint() or 0) .. "_" .. layout
end

local function allLayouts()
    local layouts = {}
    local data = _G.apGameData or {}
    for _, ship in ipairs(data.ships or {}) do
        for index = 0, (ship.layouts or 1) - 1 do
            layouts[#layouts + 1] = ship.name .. ((data.variantSuffix or {})[index] or "")
        end
    end
    return layouts
end

-- Victories that counted are kept per seed, so a goal of several wins can span several sessions.
local function loadVictories()
    local contract = _G.apContractState
    if contract == nil or contract.connected ~= true or not _G.apNetRecall then
        return
    end
    local seed = apSeedFingerprint()
    if victoriesFor == seed then
        return
    end
    victoriesFor = seed
    for _, layout in ipairs(allLayouts()) do
        if apNetRecall(victoryKey(layout)) == 1 then
            victories[layout] = true
        end
    end
end

local LEVELS = { any = 0, normal = 1, hard = 2 }

local function gameDifficulty()
    local ok, value = pcall(function()
        return Hyperspace.Settings.difficulty
    end)
    return (ok and tonumber(value)) or 0
end

function apAdvancedEditionOff()
    local ok, active = pcall(function()
        return Hyperspace.Settings.bDlcEnabled
    end)
    return ok and active == false
end

local function difficultyEnough()
    local goal = _G.apGoal and _G.apGoal() or nil
    local required = LEVELS[(goal or {}).difficulty or "any"] or 0
    if required == 0 then
        return true, required
    end
    return gameDifficulty() >= required, required
end

local DIFFICULTY_NAME = { [0] = "difficulty.easy", [1] = "difficulty.normal", [2] = "difficulty.hard" }

function apGoalArchives()
    local goal = _G.apGoal and _G.apGoal() or nil
    local requested = (goal or {}).archives or 0
    if requested <= 0 then
        return nil
    end
    return requested
end

function apReceivedArchives()
    return ((_G.apInventory or {}).archives) or 0
end

function apGoalDifficulty()
    local goal = _G.apGoal and _G.apGoal() or nil
    local requested = (goal or {}).difficulty or "any"
    if requested == "any" then
        return nil
    end
    return apT(DIFFICULTY_NAME[LEVELS[requested]] or "difficulty.normal")
end

local function archivesMissing()
    local archives = apGoalArchives()
    if archives == nil then
        return 0
    end
    return math.max(0, archives - apReceivedArchives())
end

function apGoalArchivesMissing()
    return archivesMissing()
end

local function goalIsReached()
    loadVictories()
    local goal = _G.apGoal and _G.apGoal() or nil
    if type(goal) ~= "table" or goal.kind ~= "victories" then
        return false, 0
    end

    local archives = apGoalArchives()
    if archives ~= nil and apReceivedArchives() < archives then
        local counted = 0
        if goal.layouts ~= nil then
            for _, blueprint in ipairs(goal.layouts) do
                if victories[blueprint] then counted = counted + 1 end
            end
        else
            for _ in pairs(victories) do counted = counted + 1 end
        end
        return false, counted
    end

    local counted = 0
    if goal.layouts ~= nil then
        for _, blueprint in ipairs(goal.layouts) do
            if victories[blueprint] then
                counted = counted + 1
            end
        end
        return counted >= #goal.layouts, counted
    end

    for _ in pairs(victories) do
        counted = counted + 1
    end
    return counted >= (goal.count or 1), counted
end

function apGoalWonWith()
    loadVictories()
    local won = {}
    for layout in pairs(victories) do
        won[#won + 1] = layout
    end
    table.sort(won)
    return won
end

function apGoalProgress()
    local goal = _G.apGoal and _G.apGoal() or nil
    if type(goal) ~= "table" or goal.kind ~= "victories" then
        return nil
    end
    local reached, counted = goalIsReached()
    return {
        done = counted,
        total = goal.layouts and #goal.layouts or (goal.count or 1),
        reached = reached,
    }
end

function apVictoryWith(layout)
    loadVictories()
    if layout == nil or victories[layout] then
        return
    end
    if not apRunCounts() then
        return
    end

    local enough, required = difficultyEnough()
    if not enough then
        checkLog(string.format("victory at difficulty %d, the goal requires %d: not counted",
            gameDifficulty(), required))
        if _G.apNotifyStatus then
            _G.apNotifyStatus(apT("goal.too_easy", { difficulty = apGoalDifficulty() or "" }))
        end
        return
    end

    victories[layout] = true
    if _G.apNetRemember then apNetRemember(victoryKey(layout), 1) end

    local reached, counted = goalIsReached()
    local goal = _G.apGoal and _G.apGoal() or nil
    local needed = goal and (goal.layouts and #goal.layouts or goal.count) or nil

    if needed then
        checkLog(string.format("victory %d/%d towards the goal", counted, needed))
    end

    if not reached or goalAnnounced then
        if needed and _G.apNotifyStatus then
            local missing = archivesMissing()
            if counted >= needed and missing > 0 then
                _G.apNotifyStatus(apT("goal.archives_missing", { n = missing, done = counted, total = needed }))
            else
                _G.apNotifyStatus(apT("goal.progress", { done = counted, total = needed }))
            end
        end
        return
    end

    checkLog("GOAL REACHED: declaring to the server")
    apDeclareGoal()
end

function apDeclareGoal()
    if goalAnnounced then
        return true
    end
    local reached = goalIsReached()
    if not reached then
        return false
    end

    local goalSent = false
    if _G.apNetSendGoal then
        local ok, result = pcall(_G.apNetSendGoal)
        goalSent = ok and result ~= false
    end

    if goalSent then
        goalAnnounced = true
        checkLog("goal declared to the server")
    else
        checkLog("goal NOT declared: no connection, will retry on reconnect")
    end
    if _G.apNotifyStatus then
        _G.apNotifyStatus(apT(goalSent and "goal.reached" or "goal.not_sent"))
    end
    return goalSent
end

function apChecksForgetSeed()
    sent = {}
    unsent = {}
    outOfSeed = {}
    victories = {}
    victoriesFor = nil
    goalAnnounced = false
    lastSector = nil
    checkLog("new seed: checks, victories and goal reset")
end

function apVictoriesResetForTesting()
    victories = {}
    victoriesFor = nil
    goalAnnounced = false
end

function apGoalStatus()
    local goal = _G.apGoal and _G.apGoal() or nil
    if goal == nil then
        checkLog("no known goal (offline)")
        return
    end
    local reached, counted = goalIsReached()
    local needed = goal.layouts and #goal.layouts or goal.count
    checkLog(string.format("goal: %d/%s victory(ies)%s", counted, tostring(needed),
        reached and " - REACHED" or ""))
    if goal.layouts then
        for _, blueprint in ipairs(goal.layouts) do
            checkLog("  " .. blueprint .. (victories[blueprint] and ": done" or ": pending"))
        end
    end
end

local function isOpenLead(key)
    if sent[key] then
        return false
    end
    return _G.apLocationNameFor and _G.apLocationNameFor(key) ~= nil
end

function apNextLeads(limit)
    limit = limit or 3
    local leads = {}

    local function add(key)
        if #leads < limit and isOpenLead(key) then
            leads[#leads + 1] = { key = key, name = _G.apLocationNameFor(key) }
        end
    end

    local ok = pcall(function()
        local layout = currentLayout()
        local starMap = Hyperspace.App.world.starMap
        local sector = math.floor(starMap.worldLevel) + 1

        if layout then
            for ahead = 0, 3 do
                add(layout .. ":sector:" .. (sector + ahead))
            end
        end

        for slot = 1, (_G.apShopSlotCount or 0) do
            add("shop:" .. slot)
        end

        if layout then
            add(layout .. ":victory")
        end
    end)

    if not ok then
        return {}
    end
    return leads
end

function apCheckStatus()
    local count = 0
    for _ in pairs(sent) do
        count = count + 1
    end
    checkLog(count .. " checks sent since the game started:")
    for id in pairs(sent) do
        checkLog("  " .. id)
    end
end

checkLog("check detection module loaded")
