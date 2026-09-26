local function vector(items)
    local store = items or {}
    return setmetatable({}, {
        __index = function(_, key)
            if key == "size" then
                return function() return #store end
            end
            if key == "push_back" then
                return function(_, value) store[#store + 1] = value end
            end
            if key == "_store" then
                return store
            end
            if type(key) == "number" then
                return store[key + 1]
            end
            return nil
        end,
        __len = function() return #store end,
    })
end

local function pair(first, second)
    return { first = first, second = second }
end

local sim = {
    log = {},
    screen = {},
    handlers = {},
    initHandlers = {},
    loadHandlers = {},
    gameEventHandlers = {},
    renderHandlers = {},
    ticks = 0,
}

_G.sim = sim

local function makeSystem(name, level, maxLevel, roomId, shipId)
    return {
        name = name,
        _shipObj = { iShipId = shipId or 0 },
        bpCost = 0,
        powerState = pair(level, level),
        maxLevel = maxLevel or 8,
        healthState = pair(2, 2),
        iSystemType = name,
        roomId = roomId or 0,
        AddDamage = function(self, amount)
            self.healthState.first = math.max(0, self.healthState.first - amount)
        end,
        UpgradeSystem = function(self, amount)
            local before = self.powerState.second
            self.powerState.second = math.min(self.maxLevel, before + amount)
            return self.powerState.second > before
        end,
    }
end

local function makeCrew(name, species, shipId)
    return {
        _name = name,
        species = species or "human",
        iShipId = shipId or 0,
        currentShipId = shipId or 0,
        bDead = false,
        health = pair(100, 100),
        GetName = function(self) return self._name end,
        CountForVictory = function(self) return not self.bDead end,
        IsDead = function(self) return self.bDead end,
        Kill = function(self) self.bDead = true end,
        maitrises = {},
        MasterSkill = function(self, id) self.maitrises[#self.maitrises + 1] = id end,
    }
end

local function makeShip(shipId)
    local rooms = {}
    for i = 0, 5 do
        rooms[#rooms + 1] = { iRoomId = i }
    end

    local ship = {
        iShipId = shipId or 0,
        bDestroyed = false,
        fuel_count = 16,
        currentScrap = 0,
        _scrapCalls = {},
        _scrapWentNegative = false,
        _missiles = 8,
        _droneParts = 2,
        _augments = {},
        _fires = {},
        _breaches = 0,
        _crewCap = 8,
        ship = {
            hullIntegrity = pair(30, 30),
            vRoomList = vector(rooms),
        },
        myBlueprint = { blueprintName = "PLAYER_SHIP_HARD" },
        _weapons = {},
        _removed = {},
    }

    ship.vSystemList = vector({
        makeSystem("shields", 2, 8, 1),
        makeSystem("engines", 2, 8, 2),
        makeSystem("weapons", 3, 8, 3),
        makeSystem("oxygen", 1, 3, 4),
        makeSystem("pilot", 1, 3, 5),
    })
    ship.vCrewList = vector({
        makeCrew("Ruwen", "human", 0),
        makeCrew("Zoltan", "energy", 0),
        makeCrew("Grokk", "rock", 0),
    })

    function ship:ModifyScrapCount(n, income)
        self.currentScrap = self.currentScrap + n
        self._scrapCalls[#self._scrapCalls + 1] = { n = n, income = income }
        if self.currentScrap < 0 then
            self._scrapWentNegative = true
            sim.scrapWentNegativeIn = sim.scrapWentNegativeIn or {}
            local key = tostring(sim.currentTestName or "?")
            sim.scrapWentNegativeIn[key] = (sim.scrapWentNegativeIn[key] or 0) + 1
        end
    end
    local function noteNegative(what, value)
        if value >= 0 then
            return
        end
        sim.resourceNegativeIn = sim.resourceNegativeIn or {}
        local key = tostring(sim.currentTestName or "?") .. " / " .. what
        sim.resourceNegativeIn[key] = (sim.resourceNegativeIn[key] or 0) + 1
    end
    ship._noteNegative = noteNegative

    function ship:ModifyMissileCount(n)
        self._missiles = self._missiles + n
        noteNegative("missiles", self._missiles)
    end
    function ship:ModifyDroneCount(n)
        self._droneParts = self._droneParts + n
        noteNegative("drone parts", self._droneParts)
    end
    function ship:DamageHull(n)
        local before = self.ship.hullIntegrity.first
        self.ship.hullIntegrity.first = math.min(
            self.ship.hullIntegrity.second, before - n)
        if self.ship.hullIntegrity.first <= 0 then
            self.ship.hullIntegrity.first = 0
            self.bDestroyed = true
        end
        return before - self.ship.hullIntegrity.first
    end
    function ship:StartFire(roomId) self._fires[#self._fires + 1] = roomId end
    function ship:DamageArea(_, damage)
        if damage.breachChance and damage.breachChance > 0 then
            self._breaches = self._breaches + 1
        end
        if damage.iDamage and damage.iDamage > 0 then
            self:DamageHull(damage.iDamage)
        end
        return true
    end
    function ship:GetRandomRoomCenter() return { x = 100, y = 100 } end
    function ship:GetRoomCenter(roomId) return { x = roomId * 10, y = roomId * 10 } end
    function ship:IsCrewFull()
        local alive = 0
        for i = 0, self.vCrewList:size() - 1 do
            if not self.vCrewList[i].bDead then alive = alive + 1 end
        end
        return alive >= self._crewCap
    end
    function ship:AddCrewMemberFromString(name, race, intruder, roomId, _, _)
        local hostile = intruder == true
        local crew = makeCrew(name ~= "" and name or ("Crew" .. self.vCrewList:size()),
                              race, hostile and 1 or 0)
        crew.intruder = hostile
        crew.iRoomId = roomId
        self.vCrewList:push_back(crew)
        return crew
    end
    function ship:AddAugmentation(name) self._augments[#self._augments + 1] = name end
    function ship:GetAugmentationList() return vector(ship._augments) end
    function ship:HasAugmentation(name)
        for _, held in ipairs(self._augments) do
            if held == name then return true end
        end
        return false
    end
    function ship:SelectRandomCrew()
        for i = 0, self.vCrewList:size() - 1 do
            local crew = self.vCrewList[i]
            if not crew.bDead then return crew end
        end
        return nil
    end
    function ship:RemoveSystem(systemType) ship._removed[#ship._removed + 1] = systemType end
    function ship:GetWeaponList() return vector(ship._weapons) end
    function ship:RemoveItem(name, _)
        for i, held in ipairs(ship._weapons) do
            if held.blueprint.name == name then
                table.remove(ship._weapons, i)
                return
            end
        end
        for i, held in ipairs(sim.cargo) do
            if held == name then
                table.remove(sim.cargo, i)
                return
            end
        end
        for i, held in ipairs(ship._augments) do
            if held == name then
                table.remove(ship._augments, i)
                return
            end
        end
    end
    function ship:GetSystem(_) return nil end
    function ship:HasSystem(_) return false end

    return ship
end

sim.makeShip = makeShip
sim.makeCrew = makeCrew
sim.vector = vector

function sim.makeLocation()
    return {
        boss = false,
        planet = { tex = nil, x = 0, y = 0, w = 0, h = 0 },
        space = { tex = nil, x = 0, y = 0, w = 0, h = 0 },
        planetImage = "",
        spaceImage = "",
        loc = { x = 0, y = 0 },
    }
end

local function resetWorld()
    sim.player = makeShip(0)
    sim.space = {
        currentPlanet = { tex = nil, x = 0, y = 0, w = 0, h = 0 },
        SwitchBackground = function(_, name)
            sim.decor.background = name
            return { tex = "texture:" .. name, x = 0, y = 0, w = 1280, h = 720 }
        end,
        SwitchPlanet = function(self, name)
            sim.decor.planet = name
            sim.decor.planetCalls = (sim.decor.planetCalls or 0) + 1
            self.currentPlanet = { tex = "texture:" .. name, x = 733, y = 41, w = 460, h = 460 }
            return { tex = "texture:" .. name, x = 733, y = 41, w = 460, h = 460 }
        end,
        UpdatePlanetImage = function(self)
            sim.decor.x, sim.decor.y = self.currentPlanet.x, self.currentPlanet.y
            sim.decor.refreshed = true
        end,
    }
    sim.decor = { background = nil, planet = nil, x = nil, y = nil, refreshed = false,
                  planetCalls = 0 }
    sim.powerManager = { currentPower = pair(0, 8) }
    sim.achievements = {}
    sim.enemy = nil
    sim.cargo = {}
    sim.equipped = { weapon = {}, drone = {} }
    sim.slots = { weapon = 4, drone = 2 }
    sim.pursuit = 0
    sim.unlocked = {}
    sim.rarities = {}
    sim.gameLanguage = ""
    sim.hangarOpen = false
    sim.subScreen = nil
    sim.pauseOpen = false
    sim.tutorial = false
    sim.dlc = true
    sim.meta = {}
    sim.durable = {}

    sim.net = { present = true, calls = {}, events = {}, connectResult = true, checked = {},
                last = { uri = "", slot = "" } }
    sim.net.client = {
        LastUri = function() return sim.net.last.uri end,
        LastSlot = function() return sim.net.last.slot end,
        Connect = function(_, uri, slot, password)
            sim.net.calls[#sim.net.calls + 1] =
                { "Connect", uri = uri, slot = slot, password = password }
            return sim.net.connectResult
        end,
        Disconnect = function() sim.net.calls[#sim.net.calls + 1] = { "Disconnect" } end,
        IsConnected = function() return sim.net.connected == true end,
        CheckedLocations = function()
            sim.net.calls[#sim.net.calls + 1] = { "CheckedLocations" }
            return vector(sim.net.checked or {})
        end,
        RequestProfileReset = function()
            sim.net.calls[#sim.net.calls + 1] = { "RequestProfileReset" }
            sim.net.resetRequested = true
            return sim.net.durableMemory ~= false
        end,
        ProfileResetRequested = function() return sim.net.resetRequested == true end,
        RelaunchWhenClosed = function()
            sim.net.calls[#sim.net.calls + 1] = { "RelaunchWhenClosed" }
            return sim.net.relaunchPossible ~= false
        end,
        TakeEvents = function()
            local taken = sim.net.events
            sim.net.events = {}
            return vector(taken)
        end,
        SendCheck = function(_, name)
            sim.net.calls[#sim.net.calls + 1] = { "SendCheck", name = name }
            return true
        end,
        SetTags = function(_, tags)
            local list = {}
            for i = 0, tags:size() - 1 do list[#list + 1] = tags[i] end
            sim.net.calls[#sim.net.calls + 1] = { "SetTags", tags = list }
            return sim.net.connected == true
        end,
        HintLocation = function(_, name)
            sim.net.calls[#sim.net.calls + 1] = { "HintLocation", name = name }
            return sim.net.connected == true
        end,
        ScoutLocations = function(_, names)
            sim.net.calls[#sim.net.calls + 1] = { "ScoutLocations", count = #names }
            return true
        end,
        SendGoal = function() sim.net.calls[#sim.net.calls + 1] = { "SendGoal" }; return true end,
        SendDeath = function(_, cause)
            sim.net.calls[#sim.net.calls + 1] = { "SendDeath", cause = cause }
            return true
        end,
        SendTrap = function(_, name)
            sim.net.calls[#sim.net.calls + 1] = { "SendTrap", name = name }
            return true
        end,
        EnergyDeposit = function(_, joules)
            sim.net.calls[#sim.net.calls + 1] = { "EnergyDeposit", joules = joules }
            return true
        end,
        EnergyRequest = function(_, joules)
            sim.net.calls[#sim.net.calls + 1] = { "EnergyRequest", joules = joules }
            return true
        end,
        RememberState = function(_, key, value)
            if not sim.net.durableMemory then error("no durable memory", 0) end
            sim.net.calls[#sim.net.calls + 1] = { "RememberState", key = key, value = value }
            sim.durable[key] = tostring(value)
        end,
        RecallState = function(_, key)
            if not sim.net.durableMemory then error("no durable memory", 0) end
            return sim.durable[key] or ""
        end,
    }
    sim.net.durableMemory = true

    _G.Hyperspace = {
        version = "1.23.1-test",

        Resources = {
            GetImageId = function(_, name)
                return { name = name, width = 460, height = 460 }
            end,
        },

        ships = setmetatable({}, {
            __index = function(_, key)
                if key == "player" then return sim.player end
                if key == "enemy" then return sim.enemy end
                return nil
            end,
        }),

        metaVariables = setmetatable({}, {
            __index = function(_, key) return sim.meta[key] or 0 end,
            __newindex = function(_, key, value) sim.meta[key] = value end,
        }),

        playerVariables = setmetatable({}, {
            __index = function(_, key) return (sim.runVariables or {})[key] or 0 end,
            __newindex = function(_, key, value)
                sim.runVariables = sim.runVariables or {}
                sim.runVariables[key] = value
            end,
        }),

        vector_string = function() return vector({}) end,

        App = {
            OnExit = function() sim.quitCalled = true end,
            menu = setmetatable({}, {
                __index = function(_, key)
                    if key == "shipBuilder" then return { bOpen = sim.hangarOpen == true } end
                    if key == "bOpen" then return sim.menuOpen ~= false end
                    if key == "bScoreScreen" then return sim.subScreen == "scores" end
                    if key == "bCreditScreen" then return sim.subScreen == "credits" end
                    if key == "bSelectSave" then return sim.subScreen == "sauvegardes" end
                    if key == "optionScreen" then
                        return { bOpen = sim.subScreen == "options" }
                    end
                    return nil
                end,
            }),
            world = setmetatable({}, {
                __index = function(_, key)
                    if key == "bStartedGame" then return sim.started end
                    if key == "starMap" then return sim.starMap end
                    if key == "space" then return sim.space end
                    return nil
                end,
            }),
            gui = setmetatable({
                equipScreen = {
                    AddToCargo = function(_, name)
                        if sim.weaponBlueprints[name] or sim.droneBlueprints[name]
                            or sim.augBlueprints[name] then
                            sim.cargo[#sim.cargo + 1] = name
                        end
                    end,
                    GetCargoHold = function() return vector(sim.cargo) end,
                    AddWeapon = function(_, bp, _, forceCargo)
                        if bp == nil or bp.name == "" then return end
                        if not forceCargo and #sim.equipped.weapon < sim.slots.weapon then
                            sim.equipped.weapon[#sim.equipped.weapon + 1] = bp.name
                        else
                            sim.cargo[#sim.cargo + 1] = bp.name
                        end
                    end,
                    AddDrone = function(_, bp, _, forceCargo)
                        if bp == nil or bp.name == "" then return end
                        if not forceCargo and #sim.equipped.drone < sim.slots.drone then
                            sim.equipped.drone[#sim.equipped.drone + 1] = bp.name
                        else
                            sim.cargo[#sim.cargo + 1] = bp.name
                        end
                    end,
                },
            }, {
                __index = function(_, key)
                    if key == "menu_pause" then return sim.pauseOpen == true end
                    return nil
                end,
            }),
        },

        Damage = function()
            return {
                iDamage = 0, iShieldPiercing = 0, fireChance = 0, breachChance = 0,
                stunChance = 0, iIonDamage = 0, iSystemDamage = 0, iPersDamage = 0,
                bHullBuster = false, ownerId = -1, selfId = -1, bLockdown = false,
                crystalShard = false, bFriendlyFire = true, iStun = 0,
            }
        end,

        Blueprints = {
            GetWeaponBlueprint = function(_, name)
                return sim.blueprintOrEmpty(name, sim.weaponBlueprints)
            end,
            GetDroneBlueprint = function(_, name)
                return sim.blueprintOrEmpty(name, sim.droneBlueprints)
            end,
            GetAugmentBlueprint = function(_, name)
                return sim.blueprintOrEmpty(name, sim.augBlueprints)
            end,
        },

        PrintHelper = {
            GetInstance = function()
                sim.printHelper = sim.printHelper or {}
                return sim.printHelper
            end,
        },

        Global = {
            GetInstance = function()
                return {
                    GetTextLibrary = function()
                        return {
                            GetText = function(_, key)
                                return sim.gameTexts[key] or ""
                            end,
                        }
                    end,
                    GetBlueprints = function()
                        return {
                            GetShipBlueprint = function(_, name, sector)
                                sim.shipBlueprintSector = sector
                                local displayName = sim.shipNames[name]
                                if displayName == nil then return nil end
                                return {
                                    blueprintName = name,
                                    name = { GetText = function() return displayName end },
                                }
                            end,
                        }
                    end,
                }
            end,
        },

        CustomShipUnlocks = {
            instance = {
                UnlockShip = function(_, name) sim.unlocked[name] = true end,
                GetShipUnlocked = function(_, name) return sim.unlocked[name] == true end,
                GetCustomShipUnlocked = function(_, name, variant)
                    local suffixe = ({ [0] = "", [1] = "_2", [2] = "_3" })[variant or 0] or ""
                    return sim.unlocked[name .. suffixe] == true
                end,
            },
        },

        Tutorial = setmetatable({}, {
            __index = function(_, key)
                if key == "bRunning" then return sim.tutorial == true end
                return nil
            end,
        }),

        ShipSystem = {
            SystemIdToName = function(id) return tostring(id) end,
            NameToSystemId = function(name) return name end,
        },

        Settings = setmetatable({}, {
            __index = function(_, key)
                if key == "language" then return sim.gameLanguage end
                if key == "languageSet" then return sim.gameLanguage ~= "" end
                if key == "difficulty" then return sim.difficulty or 0 end
                if key == "bDlcEnabled" then return sim.dlc ~= false end
                return nil
            end,
        }),

        Archipelago = setmetatable({}, {
            __index = function(_, key)
                if key ~= "Instance" then return nil end
                return function()
                    if not sim.net.present then return nil end
                    return sim.net.client
                end
            end,
        }),

        PowerManager = {
            GetPowerManager = function(shipId)
                if shipId ~= 0 then return nil end
                return sim.powerManager
            end,
        },
        CustomAchievementTracker = {
            instance = {
                GetAchievementStatus = function(_, name)
                    return sim.achievements[name] or -1
                end,
            },
        },
        CustomEventsParser = { GetInstance = function() return nil end },
    }

    sim.gameTexts = {
        system_shields_title = "Shields",
        system_engines_title = "Engines",
        system_oxygen_title = "Oxygen",
        system_medbay_title = "Medbay",
        system_clonebay_title = "Clone Bay",
        system_weapons_title = "Weapon Control",
        system_drones_title = "Drone Control",
        system_teleporter_title = "Crew Teleporter",
        system_cloaking_title = "Cloaking",
        system_pilot_title = "Piloting",
        system_sensors_title = "Sensors",
        system_doors_title = "Door System",
        system_hacking_title = "Hacking",
        system_mind_title = "Mind Control",
        system_battery_title = "Backup Battery",
        weapon_ARTILLERY_FED_title = "Artillery Beam",
        ACH_SECTOR_5_name = "Just Getting Started",
    }

    sim.shipNames = {
        PLAYER_SHIP_HARD = "The Kestrel",
        PLAYER_SHIP_HARD_2 = "Red-Tail",
        PLAYER_SHIP_ROCK = "Bulwark",
        PLAYER_SHIP_ROCK_2 = "Shivan",
        PLAYER_SHIP_MANTIS = "The Gila Monster",
        PLAYER_SHIP_STEALTH_2 = "DA-SR 12",
        PLAYER_SHIP_CIRCLE_2 = "The Vortex",
    }

    sim.starMap = {
        worldLevel = 0.0,
        currentLoc = sim.makeLocation(),
        currentSector = { description = { type = "CIVILIAN_SECTOR", name = { GetText = function() return "Civilian" end } } },
        ModifyPursuit = function(_, n) sim.pursuit = sim.pursuit + n end,
    }
end

sim.weaponBlueprints = {
    LASER_BURST_3 = 5, BEAM_2 = 4, MISSILES_2 = 3,
    AP_GIFT_1 = 0, AP_GIFT_2 = 0, AP_GIFT_3 = 0, AP_GIFT_4 = 0, AP_GIFT_5 = 0, AP_GIFT_6 = 0,
    AP_GIFT_7 = 0, AP_GIFT_8 = 0, AP_GIFT_9 = 0, AP_GIFT_10 = 0, AP_GIFT_11 = 0, AP_GIFT_12 = 0,
}

function sim.buy(blueprintName)
    sim.player._weapons[#sim.player._weapons + 1] = { blueprint = { name = blueprintName } }
end

function sim.sign(blueprintName)
    sim.player._augments[#sim.player._augments + 1] = blueprintName
end
sim.droneBlueprints = { DEFENSE_1 = 3, COMBAT_1 = 2 }
sim.augBlueprints = {
    ENERGY_SHIELD = 5, SCRAP_COLLECTOR = 3,
    AP_DEAL_1 = 0, AP_DEAL_2 = 0, AP_DEAL_3 = 0,
}

function sim.delivered()
    return #sim.cargo + #sim.equipped.weapon + #sim.equipped.drone
end

function sim.blueprintOrEmpty(name, family)
    if family[name] == nil then
        return { name = "", type = -1, desc = { rarity = 0, baseRarity = 0, locked = false, title = "" } }
    end
    return { name = name, type = 0, desc = sim.rarityFor(name, family[name]) }
end

local function textString(value, literal)
    return { data = value, isLiteral = literal ~= false,
             GetText = function(self) return self.isLiteral and self.data or "" end }
end

sim.textString = textString

local descCache = {}
function sim.rarityFor(name, base)
    if descCache[name] == nil then
        descCache[name] = {
            rarity = base, baseRarity = base, locked = false, cost = 50,
            title = textString(name), shortTitle = textString(name),
            description = textString(""), tooltip = textString(""), tip = textString(""),
        }
    end
    return descCache[name]
end

function sim.resetBlueprints()
    descCache = {}
end

_G.Defines = {
    InternalEvents = {
        ON_TICK = "ON_TICK", MAIN_MENU = "MAIN_MENU", JUMP_ARRIVE = "JUMP_ARRIVE",
        JUMP_LEAVE = "JUMP_LEAVE", ON_KEY_DOWN = "ON_KEY_DOWN",
        CONSTRUCT_SHIP_SYSTEM = "CONSTRUCT_SHIP_SYSTEM", CREW_LOOP = "CREW_LOOP",
        PRE_CREATE_CHOICEBOX = "PRE_CREATE_CHOICEBOX",
        ON_KEY_UP = "ON_KEY_UP",
        ON_MOUSE_L_BUTTON_DOWN = "ON_MOUSE_L_BUTTON_DOWN",
        ON_MOUSE_SCROLL = "ON_MOUSE_SCROLL",
    },
    RenderEvents = { MAIN_MENU = "MAIN_MENU", GUI_CONTAINER = "GUI_CONTAINER", TABBED_WINDOW = "TABBED_WINDOW" },
    Chain = { CONTINUE = 0, PREEMPT = 1, HALT = 2 },
    SDL = setmetatable({
        KEY_BACKSPACE = 8, KEY_TAB = 9, KEY_RETURN = 13, KEY_ESCAPE = 27, KEY_SPACE = 32,
        KEY_MINUS = 45, KEY_PERIOD = 46, KEY_SLASH = 47, KEY_COLON = 58, KEY_SEMICOLON = 59,
        KEY_KP0 = 256, KEY_KP9 = 265, KEY_KP_PERIOD = 266, KEY_KP_MINUS = 269,
        KEY_KP_ENTER = 271, KEY_UP = 273, KEY_DOWN = 274, KEY_RIGHT = 275, KEY_LEFT = 276,
        KEY_RSHIFT = 303, KEY_LSHIFT = 304,
    }, {
        __index = function(t, key)
            local letter = key:match("^KEY_(%l)$")
            if letter then return string.byte(letter) end
            local digit = key:match("^KEY_(%d)$")
            if digit then return string.byte(digit) end
            local f = key:match("^KEY_F(%d+)$")
            if f then return 281 + tonumber(f) end
            return key
        end,
    }),
}

sim.drawn = {}
sim.draws = {}
sim.rects = {}
sim.images = {}

local function noteDraw(size, x, y, text)
    sim.drawn[#sim.drawn + 1] = tostring(text)
    sim.draws[#sim.draws + 1] = {
        size = tonumber(size) or 0,
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        text = tostring(text),
    }
    return { x = #tostring(text) * 6, y = 12 }
end

_G.Graphics = {
    freetype = {
        easy_print = function(size, x, y, text)
            return noteDraw(size, x, y, text)
        end,
        easy_printAutoNewlines = function(size, x, y, lineLength, text)
            local drawing = noteDraw(size, x, y, text)
            sim.draws[#sim.draws].maxWidth = tonumber(lineLength) or 0
            return drawing
        end,
        easy_printAutoShrink = function(size, x, y, maxWidth, _, text)
            noteDraw(size, x, y, text)
            sim.draws[#sim.draws].maxWidth = tonumber(maxWidth) or 0
        end,
        easy_printNewlinesCentered = function(size, x, y, _, text)
            local drawing = noteDraw(size, x, y, text)
            sim.draws[#sim.draws].centered = true
            return drawing
        end,
        easy_printCenter = function(size, x, y, text)
            local drawing = noteDraw(size, x, y, text)
            sim.draws[#sim.draws].centered = true
            return drawing
        end,
        easy_measureWidth = function(size, text)
            return #tostring(text) * math.max(4, math.floor((tonumber(size) or 10) / 2))
        end,
    },
    GL_Color = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end,
    CSurface = {
        GL_BlitPixelImage = function(texture, x, y, w, h, _, _, _)
            sim.images[#sim.images + 1] = { texture = texture, x = x, y = y, w = w, h = h }
            return true
        end,
        GL_DrawRect = function(x, y, w, h)
            sim.rects[#sim.rects + 1] = { x = x, y = y, w = w, h = h }
            return true
        end,
        GL_DrawRectOutline = function() return true end,
        GL_SetColor = function() return true end,
    },
}

function sim.drawnText(fragment)
    for _, line in ipairs(sim.drawn) do
        if line:find(fragment, 1, true) then return true end
    end
    return false
end

local function replayRender(id)
    sim.drawn = {}
    sim.draws = {}
    sim.rects = {}
    sim.images = {}
    for _, handlers in ipairs(sim.renderHandlers[id] or {}) do
        if handlers.after then
            pcall(handlers.after)
        end
    end
end

function sim.renderGui()
    replayRender("GUI_CONTAINER")
end

function sim.renderMenu()
    replayRender("MAIN_MENU")
end

-- The ship screens window (upgrades, crew, equipment), drawn with the name of its current tab.
function sim.renderTab(name)
    for _, handlers in ipairs(sim.renderHandlers.TABBED_WINDOW or {}) do
        if handlers.after then
            pcall(handlers.after, name)
        end
    end
end

_G.script = {
    on_internal_event = function(id, fn)
        sim.handlers[id] = sim.handlers[id] or {}
        table.insert(sim.handlers[id], fn)
    end,
    on_init = function(fn) table.insert(sim.initHandlers, fn) end,
    on_load = function(fn) table.insert(sim.loadHandlers, fn) end,
    on_game_event = function(name, _, fn)
        sim.gameEventHandlers[name] = sim.gameEventHandlers[name] or {}
        table.insert(sim.gameEventHandlers[name], fn)
    end,
    on_render_event = function(id, before, after)
        sim.renderHandlers[id] = sim.renderHandlers[id] or {}
        local list = sim.renderHandlers[id]
        list[#list + 1] = { before = before, after = after }
    end,
}

_G.log = function(message)
    sim.log[#sim.log + 1] = tostring(message)
end

sim.everShown = {}

local realPrint = print
_G.print = function(message)
    sim.screen[#sim.screen + 1] = tostring(message)
    sim.everShown[#sim.everShown + 1] = tostring(message)
    sim.log[#sim.log + 1] = "[print] " .. tostring(message)
end
sim.realPrint = realPrint

function fire(id, ...)
    for _, fn in ipairs(sim.handlers[id] or {}) do
        local ok, err = pcall(fn, ...)
        if not ok then
            sim.log[#sim.log + 1] = "[HARNESS] error in " .. id .. ": " .. tostring(err)
            sim.errors = (sim.errors or 0) + 1
        end
    end
end

local function watchResources()
    local player = sim.player
    if player == nil or player._noteNegative == nil then
        return
    end
    player._noteNegative("fuel", player.fuel_count or 0)
    player._noteNegative("hull", player.ship and player.ship.hullIntegrity
        and player.ship.hullIntegrity.first or 0)
end

function sim.tick(count)
    for _ = 1, (count or 1) do
        sim.ticks = sim.ticks + 1
        fire("ON_TICK")
    end
    watchResources()
end

function sim.constructSystem(name, shipId, cost)
    local system = makeSystem(name, 1, 3, 0, shipId or 0)
    system.iSystemType = name
    -- Hyperspace fires this from the base constructor, before the level fields exist.
    system.maxLevel = nil
    fire("CONSTRUCT_SHIP_SYSTEM", system)
    system.maxLevel = 3
    system.bpCost = cost or 0
    return system
end

function sim.setStore(hasStore)
    sim.starMap.currentLoc = sim.makeLocation()
    sim.starMap.currentLoc.event = { store = hasStore and true or false }
end

function sim.openChoiceBox(eventName, choiceCount)
    local choices = {}
    for index = 1, (choiceCount or 2) do
        choices[index] = { text = { data = "choice " .. index, isLiteral = false } }
    end
    local event = {
        eventName = eventName,
        text = { data = tostring(eventName), isLiteral = false },
        GetChoices = function() return vector(choices) end,
    }
    fire("PRE_CREATE_CHOICEBOX", event)

    local view = { text = event.text.data, choices = {} }
    for index = 1, #choices do
        view.choices[index] = { text = choices[index].text.data,
                                literal = choices[index].text.isLiteral }
    end
    return view
end

function sim.mainMenu()
    fire("MAIN_MENU")
end

function sim.earnAchievement(name, difficulty)
    sim.achievements[name] = difficulty or 0
end

function sim.startRun(newGame)
    sim.started = true
    if newGame ~= false then
        sim.runVariables = {}
    end
    for _, fn in ipairs(sim.initHandlers) do
        local ok, err = pcall(fn, newGame ~= false)
        if not ok then
            sim.log[#sim.log + 1] = "[HARNESS] error in on_init: " .. tostring(err)
            sim.errors = (sim.errors or 0) + 1
        end
    end
end

function sim.jumpArrive(shipManager)
    fire("JUMP_ARRIVE", shipManager or sim.player)
end

function sim.gameEvent(name)
    for _, fn in ipairs(sim.gameEventHandlers[name] or {}) do
        pcall(fn)
    end
end

function sim.keyDown(key)
    fire("ON_KEY_DOWN", key)
end

function sim.keyUp(key)
    fire("ON_KEY_UP", key)
end

function sim.click(x, y)
    fire("ON_MOUSE_L_BUTTON_DOWN", x, y)
end

function sim.scroll(direction)
    fire("ON_MOUSE_SCROLL", direction)
end

function sim.type(text)
    for index = 1, #text do
        local c = text:sub(index, index)
        local isUpper = c:match("%u") ~= nil
        if isUpper then
            sim.keyDown(304)
            sim.keyDown(string.byte(c:lower()))
            sim.keyUp(304)
        else
            sim.keyDown(string.byte(c))
        end
    end
end

function sim.netEvent(kind, fields)
    local event = { kind = kind, name = "", sender = "", extra = "", other = "", index = -1, value = 0 }
    for key, value in pairs(fields or {}) do
        event[key] = value
    end
    sim.net.events[#sim.net.events + 1] = event
end

function sim.netCalls(name)
    local count = 0
    for _, call in ipairs(sim.net.calls) do
        if call[1] == name then count = count + 1 end
    end
    return count
end

function sim.logged(fragment)
    for _, line in ipairs(sim.log) do
        if line:find(fragment, 1, true) then return true end
    end
    return false
end

function sim.shown(fragment)
    for _, line in ipairs(sim.screen) do
        if line:find(fragment, 1, true) then return true end
    end
    return false
end

function sim.clearLog()
    sim.log = {}
    sim.screen = {}
end

function sim.reset()
    sim.clearLog()
    sim.resetBlueprints()
    sim.started = false
    sim.ticks = 0
    sim.errors = 0
    resetWorld()
end

resetWorld()
sim.errors = 0
