local passed, failed = 0, 0
local failures = {}
local currentTest = "?"

local function check(condition, description)
    if condition then
        passed = passed + 1
    else
        failed = failed + 1
        failures[#failures + 1] = currentTest .. " : " .. description
    end
    return condition
end

local function equals(actual, expected, description)
    return check(actual == expected,
        description .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
end

local function utf8Valid(text)
    local i, n = 1, #text
    while i <= n do
        local byte = text:byte(i)
        local extra
        if byte < 0x80 then extra = 0
        elseif byte >= 0xF0 then extra = 3
        elseif byte >= 0xE0 then extra = 2
        elseif byte >= 0xC0 then extra = 1
        else return false end
        if i + extra > n then return false end
        for k = 1, extra do
            local c = text:byte(i + k)
            if c == nil or c < 0x80 or c >= 0xC0 then return false end
        end
        i = i + extra + 1
    end
    return true
end

local FROZEN_GLOBALS = {}
for name, value in pairs(_G) do
    if type(name) == "string" and name:match("^ap") and type(value) == "function" then
        FROZEN_GLOBALS[name] = value
    end
end

local function restoreGlobals()
    local touched = {}
    for name, original in pairs(FROZEN_GLOBALS) do
        if rawget(_G, name) ~= original then
            touched[#touched + 1] = name
            _G[name] = original
        end
    end
    return touched
end

local function test(name, body)
    restoreGlobals()
    currentTest = name
    sim.currentTestName = name
    sim.reset()
    local seed = 0
    for i = 1, #name do
        seed = (seed * 31 + name:byte(i)) % 2147483647
    end
    math.randomseed(seed)
    if _G.apForgetChecksForTesting then _G.apForgetChecksForTesting() end
    if _G.apShopGiftsResetForTesting then _G.apShopGiftsResetForTesting() end
    if _G.apFillerResetForTesting then _G.apFillerResetForTesting() end
    if _G.apContractResetForTesting then _G.apContractResetForTesting() end
    if _G.apInventoryResetForTesting then _G.apInventoryResetForTesting() end
    if _G.apVictoriesResetForTesting then _G.apVictoriesResetForTesting() end
    if _G.apNotifyResetForTesting then _G.apNotifyResetForTesting() end
    if _G.apNetResetForTesting then _G.apNetResetForTesting() end
    if _G.apSoloResetForTesting then _G.apSoloResetForTesting() end
    _G.apRunStartCheckForTesting = false
    local ok, err = pcall(body)
    if not ok then
        failed = failed + 1
        failures[#failures + 1] = name .. " : ERROR - " .. tostring(err)
    end
end

local function stub(name, replacement)
    local previous = _G[name]
    _G[name] = replacement
    return function() _G[name] = previous end
end

local function drain(times)
    for _ = 1, (times or 3) do
        sim.jumpArrive()
    end
    apNotifyFlushForTesting()
end

local CONTRACT = 2

local function applySeed(fields)
    local seed = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {}, loc = {},
    }
    for key, value in pairs(fields or {}) do
        seed[key] = value
    end
    local accepted = apApplySlotData(seed)
    check(accepted ~= false, "the test seed is accepted by the contract")
    if accepted ~= false and _G.apRunSeedForTesting then apRunSeedForTesting(apSeedFingerprint()) end
    return accepted
end

local function shownKey(key, params)
    local expected = apT(key, params)
    local longest = ""
    for piece in expected:gmatch("[^{}]+") do
        local trimmed = piece:gsub("^%s+", ""):gsub("%s+$", "")
        if #trimmed > #longest then
            longest = trimmed
        end
    end
    if #longest < 3 then
        longest = expected
    end
    return sim.shown(longest)
end

local function crewCount()
    local alive = 0
    local crew = sim.player.vCrewList
    for i = 0, crew:size() - 1 do
        if not crew[i].bDead then alive = alive + 1 end
    end
    return alive
end

test("all modules load without error", function()
    equals(_G.__syntaxErrors, nil, "no syntax error")
    equals(_G.__loadErrors, nil, "no load error")
    check(type(_G.apQueueItem) == "function", "filler exposes apQueueItem")
    check(type(_G.apDeliverEquipment) == "function", "equipment exposes apDeliverEquipment")
    check(type(_G.apApplyShopRules) == "function", "shop exposes apApplyShopRules")
    check(type(_G.apDeathLinkReceive) == "function", "deathlink exposes apDeathLinkReceive")
    check(type(_G.apEnergyLinkContribute) == "function", "energylink exposes apEnergyLinkContribute")
end)

test("language: defaults to English", function()
    apLangResolve(nil)
    equals(_G.apLang.code, "en", "falls back to English")
    equals(apT("energylink.empty"), _G.apLangTables.en["energylink.empty"],
           "the string really comes from the English table")
end)

test("changing FTL's language is picked up back at the menu, without restarting the game", function()
    sim.gameLanguage = "en"
    apLangResolve(nil)
    sim.gameLanguage = "fr"
    sim.mainMenu()
    sim.clearLog()
    apLangStatus()
    check(sim.logged("language fr (jeu)"), "going through the menu was enough")
end)

test("a language requested by the seed overrides the game setting", function()
    sim.gameLanguage = "en"
    apLangResolve("es")
    sim.gameLanguage = "fr"
    sim.mainMenu()
    sim.clearLog()
    apLangStatus()
    check(sim.logged("language es (yaml)"), "the seed's choice sticks")
    apLangResolve(nil)
end)

test("language: a French game gives a French mod", function()
    sim.gameLanguage = "fr"
    apLangResolve(nil)
    equals(_G.apLang.code, "fr", "the game's language is picked up")
    equals(_G.apLang.source, "jeu", "and the source is recorded")
    equals(apT("energylink.empty"), _G.apLangTables.fr["energylink.empty"],
           "the string really comes from the French table")
    check(apT("energylink.empty") ~= _G.apLangTables.en["energylink.empty"],
          "and it's not the same as in English")
    sim.gameLanguage = ""
end)

test("language: a system is named the way the game names it, not by its id", function()
    equals(apSystemLabel("medbay"), "Medbay", "the game's name")
    equals(apSystemLabel("shields"), "Shields", "and not the id")
    equals(apSystemLabel("weapons"), "Weapon Control",
           "even when the two have nothing in common")
end)

test("language: a name that's too long is truncated between two characters, never mid-character", function()
    equals(apTruncate("Navigator", 12), "Navigator", "a short name passes through unchanged")
    equals(apTruncate("Navigator123", 12), "Navigator123", "exactly twelve characters too")
    equals(apTruncate("Navigator1234", 12), "Navigator12.", "thirteen get cut and marked")

    local accents = string.rep("é", 11)
    local truncated = apTruncate(accents, 12)
    equals(truncated, accents, "eleven accented characters fit, despite twenty-two bytes")

    local long = string.rep("é", 20)
    truncated = apTruncate(long, 12)
    equals(#truncated, 23, "eleven two-byte characters, plus the dot")
    check(truncated:sub(-1) == ".", "and the cut is marked")
    check(utf8Valid(truncated), "and the result is still valid UTF-8")

    check(not utf8Valid(long:sub(1, 11) .. "."),
          "whereas cutting at the byte, like before, produces invalid UTF-8")
end)

test("language: an achievement carries the name the game gives it", function()
    equals(apAchievementLabel("ACH_SECTOR_5"), "Just Getting Started", "the game's name")
    equals(apAchievementLabel("ACH_DOES_NOT_EXIST"), "ACH_DOES_NOT_EXIST",
           "and the id as a fallback, better than a blank")
    equals(apAchievementLabel(nil), "?", "nil breaks nothing")
end)

test("language: a system unknown to the game keeps its id instead of a blank", function()
    equals(apSystemLabel("a_system_that_does_not_exist"), "a_system_that_does_not_exist",
           "falls back to the id")
    equals(apSystemLabel(nil), "?", "nil breaks nothing")
end)

test("language: a quantity of one puts the sentence in the singular", function()
    apLangResolve("fr")
    equals(apT("hud.goal", { n = 1 }), "Objectif : battre le vaisseau amiral", "goal in the singular")
    equals(apT("hud.goal", { n = 3 }), "Objectif : battre le vaisseau amiral 3 fois", "and plural beyond that")
    equals(apT("check.resent", { n = 1 }), "1 check rattrapé auprès du serveur.", "one check")
    check(apT("trap.fuel_leak", { n = 1 }):find("cellule perdue", 1, true) ~= nil,
          "one cell lost, not '1 cellules perdues'")
    check(apT("trap.fuel_leak", { n = 4 }):find("cellules perdues", 1, true) ~= nil,
          "and 'cellules perdues' for four too")
    apLangResolve(nil)
end)

test("language: the singular holds in every language, not just French", function()
    for _, code in ipairs({ "en", "fr", "es", "de", "it", "pt" }) do
        apLangResolve(code)
        local one = apT("hud.summary.ships", { count = 1 })
        local three = apT("hud.summary.ships", { count = 3 })
        check(one ~= three:gsub("3", "1"),
              code .. ": the singular is not the plural with a different number (" .. one .. ")")
    end
    apLangResolve(nil)
end)

test("language: an integer arriving as a float still prints without a decimal point", function()
    apLangResolve("fr")
    equals(apT("hud.goal", { n = 3.0 }), "Objectif : battre le vaisseau amiral 3 fois", "not '3.0 fois'")
    equals(apT("hud.goal", { n = 1.0 }), "Objectif : battre le vaisseau amiral",
           "and the singular recognizes the float as one")
    equals(apT("trap.hull_damage", { n = 2.0 }), "Intégrité de coque : -2. Aucun impact enregistré.",
           "in an ordinary sentence too")
    apLangResolve(nil)
end)

test("language: with no quantity, or above one, the base key is used", function()
    apLangResolve("fr")
    equals(apT("check.sent", { location = "Sector 1 Clear" }), "Check validé : Sector 1 Clear",
           "no quantity: nothing changes")
    equals(apT("dash.checks.remaining", { n = 0 }), "0 restants",
           "zero stays plural, and that's written in i18n.lua")
    apLangResolve(nil)
end)

test("language: a missing singular variant doesn't break anything", function()
    apLangResolve("fr")
    equals(apT("energylink.empty", { n = 1 }), _G.apLangTables.fr["energylink.empty"],
           "the base key is rendered as-is")
    apLangResolve(nil)
end)

test("language: the YAML choice wins over the game's", function()
    sim.gameLanguage = ""
    apLangResolve("fr")
    equals(_G.apLang.code, "fr", "YAML decides")
    equals(_G.apLang.source, "yaml", "and the source says so")
    apLangResolve(nil)
end)

test("language: an unsupported language falls back to the game, then to English", function()
    sim.gameLanguage = "fr"
    apLangResolve("kl")
    equals(_G.apLang.code, "fr", "falls back to the game's language")

    sim.gameLanguage = "ja"
    apLangResolve("kl")
    equals(_G.apLang.code, "en", "then to English")
    sim.gameLanguage = ""
    apLangResolve(nil)
end)

test("language: parameters are substituted, never translated", function()
    sim.gameLanguage = "fr"
    apLangResolve(nil)
    local line = apT("item.received.from", { item = "20 Scrap", sender = "Nina" })
    check(line:find("20 Scrap", 1, true), "the item's name passes through untouched")
    check(line:find("Nina", 1, true), "so does the player's name")
    check(line:find("Reçu", 1, true), "but the sentence is in French")
    sim.gameLanguage = ""
    apLangResolve(nil)
end)

test("language: an unknown key is never shown raw", function()
    local shown = apT("an.id.that.does.not.exist")
    check(not shown:find("an.id.that", 1, true), "the key doesn't leak onto the screen")
    check(#shown > 0, "and something readable comes out anyway")
    check(sim.logged("UNKNOWN KEY"), "the log, though, names it")
end)

test("language: a forgotten parameter shows up instead of leaving a gap", function()
    local line = apT("item.received.from", { sender = "Nina" })
    check(line:find("{item}", 1, true), "the missing parameter stays visible")
end)

test("language: every supported language is complete and invents nothing", function()
    local english = _G.apLangTables.en
    check(english ~= nil, "English table present")

    local checked = 0
    for code, table_ in pairs(_G.apLangTables) do
        if code ~= "en" then
            checked = checked + 1
            local extra, missing = {}, {}
            for key in pairs(table_) do
                if english[key] == nil then extra[#extra + 1] = key end
            end
            for key in pairs(english) do
                if table_[key] == nil then missing[#missing + 1] = key end
            end
            equals(#extra, 0, code .. " invents no key (" .. table.concat(extra, ", ") .. ")")
            if #missing > 0 then
                log("[TEST] " .. code .. ": " .. #missing .. " untranslated key(s)")
            end
        end
    end
    check(checked >= 5, "at least five languages besides English (" .. checked .. ")")
end)

test("language: every supported language actually applies", function()
    for code in pairs(_G.apLangTables) do
        apLangResolve(code)
        equals(_G.apLang.code, code, "language " .. code .. " is accepted")
        local sample = apT("hud.close")
        check(#sample > 0, code .. " renders something readable")
    end
    apLangResolve(nil)
end)

test("language: French is complete, it's the project's reference language", function()
    local english = _G.apLangTables.en
    local french = _G.apLangTables.fr
    check(english ~= nil, "English table present")
    check(french ~= nil, "French table present")

    local extra = {}
    for key in pairs(french or {}) do
        if english[key] == nil then extra[#extra + 1] = key end
    end
    equals(#extra, 0, "no French key missing from English (" .. table.concat(extra, ", ") .. ")")

    local missing = 0
    for key in pairs(english or {}) do
        if french[key] == nil then missing = missing + 1 end
    end
    equals(missing, 0, "French is complete")
end)

test("language: each string carries the same parameters in both languages", function()
    local function placeholders(text)
        local found = {}
        for name in text:gmatch("{(%w+)}") do found[name] = true end
        return found
    end
    local wrong = {}
    for key, english in pairs(_G.apLangTables.en) do
        local french = _G.apLangTables.fr[key]
        if french ~= nil then
            local a, b = placeholders(english), placeholders(french)
            for name in pairs(a) do
                if not b[name] then wrong[#wrong + 1] = key .. " (missing {" .. name .. "})" end
            end
            for name in pairs(b) do
                if not a[name] then wrong[#wrong + 1] = key .. " ({" .. name .. "} extra)" end
            end
        end
    end
    equals(#wrong, 0, "parameters aligned (" .. table.concat(wrong, ", ") .. ")")
end)

test("language: a French player reads their run in French", function()
    sim.gameLanguage = "fr"
    apLangResolve(nil)
    sim.startRun(true)
    sim.clearLog()

    apQueueItem({ kind = "filler", res = "scrap", n = 20 })
    apQueueItem({ kind = "trap", eff = "fleet_advance" })
    drain()

    check(shownKey("item.received"), "the received item is announced in French")
    check(shownKey("trap.sprung"), "so is the trap")
    check(shownKey("trap.fleet_advance"), "and its description")
    check(not sim.shown("Received "), "no leftover English")
    check(not sim.shown("Trap:"), "not for traps either")

    sim.gameLanguage = ""
    apLangResolve(nil)
end)

test("a trap this mod doesn't know says so, instead of doing nothing", function()
    sim.startRun(true)
    sim.clearLog()
    apQueueItem({ kind = "trap", eff = "a_future_effect", display = "Reactor Meltdown" })
    drain()

    check(shownKey("item.unknown", { name = "Reactor Meltdown" }),
        "the player reads the Archipelago name of what just arrived")
    check(not sim.shown("a_future_effect"), "and not the technical id")
    check(sim.logged("unknown trap: a_future_effect"), "that the log, though, keeps")
end)

test("boarding trap: an intruder comes aboard, on the enemy side", function()
    sim.startRun(true)
    local before = sim.player.vCrewList:size()

    apQueueItem({ kind = "trap", eff = "boarding" })
    drain()

    equals(sim.player.vCrewList:size(), before + 1, "someone came aboard")
    local last = sim.player.vCrewList[sim.player.vCrewList:size() - 1]
    check(last.intruder == true, "and it is HOSTILE, not a recruit")
    equals(last.iShipId, 1, "it belongs to the enemy ship, so it doesn't count for us")
    check(last.iRoomId ~= nil, "it appears in a room of the ship")
    check(shownKey("trap.boarding", { room = last.iRoomId }), "and the player sees it arrive")
    check(sim.logged("trap triggered: trap.boarding"), "the log names the effect, not the item")
end)

test("boarding trap: refused when only one crew member is left", function()
    sim.startRun(true)
    for i = 1, sim.player.vCrewList:size() - 1 do
        sim.player.vCrewList[i].bDead = true
    end
    local before = sim.player.vCrewList:size()

    apQueueItem({ kind = "trap", eff = "boarding" })
    drain()

    equals(sim.player.vCrewList:size(), before, "no one comes aboard")
    check(sim.logged("trap boarding impossible (floor reached), falling back to"),
        "it falls back to a gentler effect, and the log says which")
end)

test("DeathLink: boarding is a receivable effect, with the same floor", function()
    apDeathLinkConfigure({ enabled = true, effect = "boarding" })
    sim.startRun(true)
    local before = sim.player.vCrewList:size()

    apDeathLinkReceive("Nina", "died")

    equals(sim.player.vCrewList:size(), before + 1, "an intruder came aboard")
    check(shownKey("deathlink.effect.boarding"), "and the received death is announced as such")
end)

test("an item whose delivery raises an error says so, instead of vanishing", function()
    sim.startRun(true)
    local restore = stub("apDeliverEquipment", function() error("the engine blew up") end)
    sim.clearLog()

    apQueueItem({ kind = "weapon", bp = "LASER_BURST_2", display = "Burst Laser Mark II" })
    drain()

    check(shownKey("item.failed", { name = "Burst Laser Mark II" }),
        "the player reads the Archipelago name of what didn't arrive")
    check(sim.logged("delivery failed"), "and the log carries the cause")
    restore()
end)

test("language: the dashboard follows the language", function()
    sim.gameLanguage = "fr"
    apLangResolve(nil)
    sim.startRun(true)
    sim.renderGui()
    apToggleHud()
    sim.renderGui()

    check(sim.drawnText("Vaisseaux"), "headers are translated")
    check(sim.drawnText("TAB ou Échap"), "so is the footer line")
    check(not sim.drawnText("TAB or Esc"), "no leftover English")

    apToggleHud()
    sim.gameLanguage = ""
    apLangResolve(nil)
end)

test("language: the Archipelago shop speaks the player's language", function()
    sim.gameLanguage = "fr"
    apLangResolve(nil)
    sim.startRun(true)
    apApplyShopGifts()

    local deal = sim.rarityFor("AP_DEAL_1", 0)
    check(deal.title.data:find("Pacte", 1, true), "the deal is announced in French")
    check(deal.description.data:find("ferraille", 1, true),
          "and the running text uses the French word")
    check(apT("filler.scrap", { n = 20 }):find("ferraille", 1, true),
          "and so does the item label, like in the other five languages")

    sim.gameLanguage = ""
    apLangResolve(nil)
end)

test("language: an Archipelago item's name is never translated", function()
    sim.gameLanguage = "fr"
    apLangResolve(nil)
    sim.startRun(true)
    sim.clearLog()

    apQueueItem({ kind = "filler", res = "scrap", n = 20,
                  display = "20 Scrap", sender = "Berserker" })
    drain()
    check(sim.shown("20 Scrap"), "the Archipelago name passes through untouched")
    check(sim.shown("Berserker"), "so does the player's name")

    sim.gameLanguage = ""
    apLangResolve(nil)
end)

test("language: the seed picks the language as soon as it's received", function()
    sim.gameLanguage = ""
    apLangResolve(nil)
    applySeed({
        contract = CONTRACT, language = "fr",
        kinds = { "filler" }, kinds_required = {},
        items = {}, loc = {},
    })
    equals(_G.apLang.code, "fr", "the seed forces its language")
    equals(_G.apLang.source, "yaml", "and the mod knows where it came from")

    apLangResolve(nil)
end)

test("language: a seed with no choice lets the game decide", function()
    sim.gameLanguage = "fr"
    apLangResolve(nil)
    applySeed({
        contract = CONTRACT,
        kinds = { "filler" }, kinds_required = {},
        items = {}, loc = {},
    })
    equals(_G.apLang.code, "fr", "follows FTL")
    equals(_G.apLang.source, "jeu", "and the mod says so")

    sim.gameLanguage = ""
    apLangResolve(nil)
end)

test("an item received outside a run waits, it isn't lost", function()
    sim.started = false
    apQueueItem({ kind = "filler", res = "scrap", n = 20 })
    apDeliverPending()
    equals(sim.player.currentScrap, 0, "nothing is delivered outside a run")

    sim.startRun(true)
    sim.jumpArrive()
    equals(sim.player.currentScrap, 20, "the waiting item is delivered on the first jump")
end)

test("nothing is delivered during combat", function()
    sim.startRun(true)
    sim.enemy = sim.makeShip(1)
    apQueueItem({ kind = "filler", res = "scrap", n = 50 })
    sim.jumpArrive()
    equals(sim.player.currentScrap, 0, "combat in progress: delivery postponed")

    sim.enemy = nil
    sim.jumpArrive()
    equals(sim.player.currentScrap, 50, "combat over: the item arrives")
end)

test("all six of the apworld's resources are applied", function()
    sim.startRun(true)
    local before = { fuel = sim.player.fuel_count, missiles = sim.player._missiles,
                     parts = sim.player._droneParts, crew = crewCount() }
    sim.player.ship.hullIntegrity.first = 20

    for _, descriptor in ipairs({
        { kind = "filler", res = "scrap", n = 20 },
        { kind = "filler", res = "fuel", n = 5 },
        { kind = "filler", res = "missiles", n = 3 },
        { kind = "filler", res = "drone_parts", n = 2 },
        { kind = "filler", res = "hull", n = 5 },
        { kind = "filler", res = "crew", n = 1 },
    }) do
        apQueueItem(descriptor)
    end
    drain()

    equals(sim.player.currentScrap, 20, "scrap")
    equals(sim.player.fuel_count, before.fuel + 5, "fuel")
    equals(sim.player._missiles, before.missiles + 3, "missiles")
    equals(sim.player._droneParts, before.parts + 2, "drone_parts")
    equals(sim.player.ship.hullIntegrity.first, 25, "hull")
    equals(crewCount(), before.crew + 1, "crew - the resource the mod used to ignore")
end)

test("a crew member received while the crew is full stays queued", function()
    sim.startRun(true)
    sim.player._crewCap = 3
    apQueueItem({ kind = "filler", res = "crew", n = 1 })
    drain()
    equals(crewCount(), 3, "the crew member isn't delivered")
    check(sim.logged("delivery deferred"), "and the mod says so in the log")

    sim.player.vCrewList[0].bDead = true
    drain()
    equals(crewCount(), 3, "the item set aside is indeed delivered later")
end)

test("all five of the apworld's traps are applied", function()
    sim.startRun(true)
    sim.player.ship.hullIntegrity.first = 30

    apQueueItem({ kind = "trap", eff = "fire" })
    apQueueItem({ kind = "trap", eff = "breach" })
    apQueueItem({ kind = "trap", eff = "fuel_leak" })
    apQueueItem({ kind = "trap", eff = "system_damage" })
    apQueueItem({ kind = "trap", eff = "fleet_advance" })
    drain()

    check(#sim.player._fires > 0, "fire: a fire started")
    check(sim.player._breaches > 0, "breach: a breach opened")
    check(sim.player.fuel_count < 16, "fuel_leak: fuel disappeared")
    check(sim.logged("trap.system_damage"), "system_damage: a system was hit")
    equals(sim.pursuit, 1, "fleet_advance: the rebel fleet advanced")
end)

test("an unknown kind doesn't break anything", function()
    sim.startRun(true)
    apQueueItem({ kind = "a_future_kind", bp = "X" })
    drain()
    equals(sim.errors, 0, "no error reported to the engine")
end)

test("a sent check is visible on screen", function()
    sim.startRun(true)
    applySeed({ loc = { ["a:1"] = "Kestrel Cruiser A: Reach sector 3" } })
    sim.clearLog()
    apSendCheck("a:1", "a sector")
    apNotifyFlushForTesting()
    check(sim.shown("Kestrel Cruiser A: Reach sector 3"),
          "the player sees the Archipelago name of the location")
end)

test("many checks at once are summarized, they don't flood the screen", function()
    sim.startRun(true)
    applySeed({ loc = {
        ["m:1"] = "Location 1", ["m:2"] = "Location 2", ["m:3"] = "Location 3",
        ["m:4"] = "Location 4", ["m:5"] = "Location 5", ["m:6"] = "Location 6",
    } })
    sim.clearLog()
    for index = 1, 6 do
        apSendCheck("m:" .. index, "batch")
    end
    apNotifyFlushForTesting()

    local lines = 0
    for _, line in ipairs(sim.screen) do
        if line:find("check", 1, true) or line:find("Check", 1, true) then lines = lines + 1 end
    end
    equals(lines, 1, "a single line for all six")
    check(sim.shown("6"), "and it gives the count")
end)

test("three checks or fewer keep their name", function()
    sim.startRun(true)
    applySeed({ loc = { ["p:1"] = "Location A", ["p:2"] = "Location B" } })
    sim.clearLog()
    apSendCheck("p:1", "one")
    apSendCheck("p:2", "two")
    apNotifyFlushForTesting()
    check(sim.shown("Location A"), "the first one is named")
    check(sim.shown("Location B"), "so is the second")
end)

test("a check outside the seed is still announced, with what is known", function()
    sim.startRun(true)
    applySeed({})
    sim.clearLog()
    apSendCheck("unknown:1", "an achievement")
    apNotifyFlushForTesting()
    check(sim.shown("an achievement") or sim.shown("unknown:1"), "something is shown")
end)

test("offline, a sent check doesn't raise any error", function()
    sim.startRun(true)
    check(type(_G.apNetSendCheck) == "function", "the network module is indeed loaded")
    apSendCheck("PLAYER_SHIP_HARD:sector:3", "a sector")
    sim.tick(2)
    equals(sim.errors, 0, "no error reported to the engine")
    equals(apLocationNameFor("something:else"), nil, "and the lookup cleanly returns nil")
end)

test("the kinds announced to the contract are the ones the mod can actually handle", function()
    for _, kind in ipairs({ "ship", "cap", "start", "filler", "trap", "weapon", "drone", "augment" }) do
        check(_G.apSupportedKinds[kind] == true, "kind announced: " .. kind)
    end
end)

local function scrapCalls()
    return sim.player._scrapCalls
end

local function everyCreditIsAGift()
    for _, call in ipairs(scrapCalls()) do
        if call.n > 0 and call.income ~= false then
            return false, tostring(call.n) .. " credited with income=" .. tostring(call.income)
        end
    end
    return true, ""
end

test("scrap: a gift arrives whole", function()
    sim.startRun(true)
    apQueueItem({ kind = "filler", res = "scrap", n = 20 })
    drain()
    equals(sim.player.currentScrap, 20, "20 asked, 20 received")
    equals(#scrapCalls(), 1, "a single call to the engine")
end)

test("scrap: a gift is never combat income", function()
    sim.startRun(true)
    apQueueItem({ kind = "filler", res = "scrap", n = 50 })
    apQueueItem({ kind = "filler", res = "scrap", n = 20 })
    drain()
    local ok, why = everyCreditIsAGift()
    check(ok, "every credit is a gift: " .. why)
end)

test("scrap: gifts add up, they don't replace each other", function()
    sim.startRun(true)
    for _ = 1, 4 do
        apQueueItem({ kind = "filler", res = "scrap", n = 20 })
    end
    apQueueItem({ kind = "filler", res = "scrap", n = 50 })
    drain()
    equals(sim.player.currentScrap, 130, "4 x 20 + 50")
end)

test("scrap: the amount comes from the descriptor, not a hardcoded value", function()
    sim.startRun(true)
    apQueueItem({ kind = "filler", res = "scrap", n = 137 })
    drain()
    equals(sim.player.currentScrap, 137, "137 asked, 137 received")
end)

test("scrap: a gift of zero credits nothing and breaks nothing", function()
    sim.startRun(true)
    apQueueItem({ kind = "filler", res = "scrap", n = 0 })
    drain()
    equals(sim.player.currentScrap, 0, "balance unchanged")
    equals(sim.errors, 0, "no error reported to the engine")
end)

test("scrap: the queue keeps the exact amount during combat", function()
    sim.startRun(true)
    sim.enemy = sim.makeShip(1)
    apQueueItem({ kind = "filler", res = "scrap", n = 50 })
    apQueueItem({ kind = "filler", res = "scrap", n = 20 })
    drain()
    equals(sim.player.currentScrap, 0, "combat: nothing goes through")
    equals(#scrapCalls(), 0, "and the engine isn't even called")

    sim.enemy = nil
    drain()
    equals(sim.player.currentScrap, 70, "combat over: both gifts arrive, whole")
end)

test("scrap: the player is told what they just received", function()
    sim.startRun(true)
    apQueueItem({ kind = "filler", res = "scrap", n = 20 })
    drain()
    check(sim.shown("20 Scrap") or sim.shown("20 scrap"),
          "the on-screen message names the amount")
end)

test("scrap: Archipelago's name wins over our own label", function()
    sim.startRun(true)
    apQueueItem({ kind = "filler", res = "scrap", n = 20, display = "20 Scrap", sender = "Nina" })
    drain()
    check(sim.shown("Nina"), "the sender is named")
end)

test("scrap: no module drops the balance below zero", function()
    sim.startRun(true)
    sim.setStore(true)
    apQueueItem({ kind = "filler", res = "scrap", n = 20 })
    drain()

    sim.player.currentScrap = 0
    if _G.apEnergyLinkContribute then pcall(_G.apEnergyLinkContribute) end
    drain(2)
    sim.tick(200)
    check(not sim.player._scrapWentNegative, "the balance never went below zero")
end)

test("scrap: EnergyLink only deposits what is above the threshold", function()
    if _G.apEnergyLink == nil or _G.apEnergyLinkContribute == nil then
        check(true, "EnergyLink absent from this build: nothing to check")
        return
    end
    sim.startRun(true)
    _G.apEnergyLink.enabled = true
    _G.apEnergyLink.depositScrapAbove = 100
    _G.apEnergyLink.depositScrapShare = 0.25
    sim.player.currentScrap = 200
    local sent = 0
    local restore = stub("apNetEnergyLinkDeposit", function(joules) sent = sent + joules end)
    pcall(_G.apEnergyLinkContribute)
    restore()

    equals(sim.player.currentScrap, 175, "25% of the 100 surplus, not a cent more")
    check(not sim.player._scrapWentNegative, "and never below zero")
    _G.apEnergyLink.depositScrapAbove = 0
end)

test("scrap: below the threshold, EnergyLink takes nothing", function()
    if _G.apEnergyLink == nil or _G.apEnergyLinkContribute == nil then
        check(true, "EnergyLink absent from this build: nothing to check")
        return
    end
    sim.startRun(true)
    _G.apEnergyLink.enabled = true
    _G.apEnergyLink.depositScrapAbove = 100
    _G.apEnergyLink.depositScrapShare = 0.25
    sim.player.currentScrap = 40
    local restore = stub("apNetEnergyLinkDeposit", function() end)
    pcall(_G.apEnergyLinkContribute)
    restore()

    equals(sim.player.currentScrap, 40, "nothing is taken below the threshold")
    _G.apEnergyLink.depositScrapAbove = 0
end)

test("inventory: a ship key really unlocks the ship", function()
    sim.startRun(true)
    local before = #_G.apInventory.ships
    apQueueItem({ kind = "ship", bp = "PLAYER_SHIP_TESTE", display = "Test Cruiser Key" })
    drain()
    equals(#_G.apInventory.ships, before + 1, "the ship enters the inventory")
    check(sim.unlocked["PLAYER_SHIP_TESTE"] == true, "and it's unlocked on the game's side")
    check(sim.shown("Test Cruiser Key"), "the player sees what they received")
end)

test("inventory: receiving the same ship twice only counts once", function()
    sim.startRun(true)
    local before = #_G.apInventory.ships
    apQueueItem({ kind = "ship", bp = "PLAYER_SHIP_TESTE", display = "Test Cruiser Key" })
    apQueueItem({ kind = "ship", bp = "PLAYER_SHIP_TESTE", display = "Test Cruiser Key" })
    drain()
    equals(#_G.apInventory.ships, before + 1, "a single addition")
end)

test("inventory: a system cap accumulates and applies", function()
    sim.startRun(true)
    local before = _G.apSystemCap("shields")
    apQueueItem({ kind = "cap", sys = "shields", n = 1, display = "Progressive Shields" })
    apQueueItem({ kind = "cap", sys = "shields", n = 1, display = "Progressive Shields" })
    drain()
    equals(_G.apInventory.systemCaps.shields, before + 2, "both copies count")
    check(_G.apSystemCap("shields") >= before + 2,
          "the applied cap follows (" .. tostring(_G.apSystemCap("shields")) .. ")")
    check(sim.shown("Progressive Shields"), "and the player sees them arrive")
end)

test("on startup, a single line summarizes the starting bonuses", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.startRun(true)
    apQueueItem({ kind = "start", sys = "engines", n = 2, display = "Engines Head Start" })
    apQueueItem({ kind = "start", sys = "reactor", n = 1, display = "Reactor Power" })
    drain()

    sim.clearLog()
    sim.startRun(true)

    check(shownKey("start.summary"), "the player reads what they start with")
    check(sim.shown("+2"), "with the number of levels granted")
end)

test("inventory: a starting bonus accumulates for the next run", function()
    sim.startRun(true)
    local before = _G.apInventory.startingUpgrades.engines or 0
    sim.clearLog()
    apQueueItem({ kind = "start", sys = "engines", n = 2, display = "Engines Head Start" })
    drain()
    equals(_G.apInventory.startingUpgrades.engines, before + 2, "the bonus is recorded")
    check(shownKey("start.received"),
        "and it's announced as a starting bonus, not as an item received from someone")
    check(not shownKey("item.received.from"),
        "otherwise the player thinks they can use it right away")
end)

test("inventory: an incomplete descriptor is refused, not swallowed", function()
    sim.startRun(true)
    local before = #_G.apInventory.ships
    apQueueItem({ kind = "ship", display = "Key without a blueprint" })
    apQueueItem({ kind = "cap", n = 1, display = "Cap without a system" })
    drain()
    equals(#_G.apInventory.ships, before, "nothing was added")
    check(sim.logged("without a blueprint") or sim.logged("without a system"), "and the log says so")
    equals(sim.errors, 0, "without reporting anything to the engine")
end)

test("inventory: the dashboard sees new ships arrive", function()
    sim.startRun(true)
    applySeed({})
    local function summaryLine()
        for _, line in ipairs(sim.drawn) do
            if line:find("ship", 1, true) then return line end
        end
        return nil
    end
    sim.renderMenu()
    local before = summaryLine()
    apQueueItem({ kind = "ship", bp = "PLAYER_SHIP_TESTE2", display = "Test Cruiser Key" })
    drain()
    sim.renderMenu()
    check(summaryLine() ~= before,
          "the menu summary changed after the ship was received (" .. tostring(before)
          .. " -> " .. tostring(sim.drawn[1]) .. ")")
end)

test("equipment: an impossible delivery is requeued, not lost", function()
    sim.startRun(true)
    local saved = Hyperspace.App.gui.equipScreen
    Hyperspace.App.gui.equipScreen = nil

    apQueueItem({ kind = "weapon", bp = "LASER_BURST_3", display = "Burst Laser Mark II" })
    drain()
    equals(#_G.apFillerPendingForTesting(), 1, "the item waits its turn")
    check(sim.logged("delivery deferred"), "and the log says why")

    Hyperspace.App.gui.equipScreen = saved
    drain()
    equals(#_G.apFillerPendingForTesting(), 0, "the item is delivered as soon as possible")
    check(sim.shown("Burst Laser Mark II"), "and the player sees it arrive")
end)

test("inventory: the three kinds announced to the contract are truly deliverable", function()
    sim.startRun(true)
    local descriptors = {
        { kind = "ship", bp = "PLAYER_SHIP_TESTE3" },
        { kind = "cap", sys = "oxygen", n = 1 },
        { kind = "start", sys = "reactor", n = 1 },
        { kind = "filler", res = "scrap", n = 5 },
        { kind = "trap", eff = "fire" },
        { kind = "weapon", bp = "LASER_BURST_3" },
        { kind = "drone", bp = "DEFENSE_1" },
        { kind = "augment", bp = "SCRAP_COLLECTOR" },
    }
    for _, descriptor in ipairs(descriptors) do
        check(_G.apSupportedKinds[descriptor.kind] == true,
              descriptor.kind .. " is announced to the contract")
        sim.clearLog()
        apFillerResetForTesting()
        apQueueItem(descriptor)
        drain()
        check(sim.logged("item(s) delivered"),
              descriptor.kind .. " is actually delivered, not just accepted")
        equals(#_G.apFillerPendingForTesting(), 0,
               descriptor.kind .. " doesn't stay queued")
    end
end)

local function springTrapNow(effect)
    apQueueItem({ kind = "trap", eff = effect })
    drain()
end

test("trap: hull never drops below the floor", function()
    sim.startRun(true)
    for _, start in ipairs({ 1, 2, 3, 4, 10 }) do
        sim.player.ship.hullIntegrity.first = start
        sim.player.bDestroyed = false
        springTrapNow("hull_damage")
        check(sim.player.ship.hullIntegrity.first >= math.min(start, _G.apTrapLimits.hullFloor),
              "hull " .. start .. " -> " .. sim.player.ship.hullIntegrity.first)
        check(not sim.player.bDestroyed, "ship alive, started from " .. start)
    end
end)

test("trap: a ship at one hull point is not finished off", function()
    sim.startRun(true)
    sim.player.ship.hullIntegrity.first = 1
    springTrapNow("hull_damage")
    equals(sim.player.ship.hullIntegrity.first, 1, "the hull hasn't moved")
    check(not sim.player.bDestroyed, "and the ship is alive")
    check(#sim.player._fires > 0 or sim.player._breaches > 0 or sim.logged("trap triggered"),
          "a gentler fallback was applied")
end)

test("trap: the fuel leak leaves enough to jump", function()
    sim.startRun(true)
    for _, start in ipairs({ 0, 1, 2, 3, 8, 20 }) do
        sim.player.fuel_count = start
        springTrapNow("fuel_leak")
        check(sim.player.fuel_count >= math.min(start, _G.apTrapLimits.fuelFloor),
              "fuel " .. start .. " -> " .. sim.player.fuel_count)
    end
end)

test("trap: the message names the system the way the game names it", function()
    sim.startRun(true)
    sim.clearLog()
    springTrapNow("system_damage")
    check(sim.shown("Shields") or sim.shown("Engines") or sim.shown("Medbay")
          or sim.shown("Weapon Control") or sim.shown("Piloting") or sim.shown("Oxygen"),
          "a game system name is shown")
    check(not sim.shown("shields") and not sim.shown("medbay") and not sim.shown("weapons"),
          "and no blueprint id reaches the screen")
end)

test("trap: a system is damaged, never disabled", function()
    sim.startRun(true)
    local systems = sim.player.vSystemList
    for i = 0, systems:size() - 1 do
        systems[i].healthState.first = 2
    end
    for _ = 1, 10 do
        springTrapNow("system_damage")
    end
    local dead = 0
    for i = 0, systems:size() - 1 do
        if systems[i].healthState.first < _G.apTrapLimits.systemFloor then
            dead = dead + 1
        end
    end
    equals(dead, 0, "no system below the floor")
end)

test("trap: the rebel fleet isn't pushed indefinitely", function()
    sim.startRun(true)
    for _ = 1, 20 do
        springTrapNow("fleet_advance")
    end
    check(sim.pursuit <= _G.apTrapLimits.pursuitCeiling,
          "the fleet was pushed " .. sim.pursuit .. " times, cap "
          .. _G.apTrapLimits.pursuitCeiling)
end)

test("trap: the fleet cap resets to zero every run", function()
    sim.startRun(true)
    for _ = 1, 20 do
        springTrapNow("fleet_advance")
    end
    local first = sim.pursuit
    check(first > 0, "the first run did push the fleet")

    sim.reset()
    sim.startRun(true)
    springTrapNow("fleet_advance")
    equals(sim.pursuit, 1, "the new run can be pushed again")
end)

test("trap: an impossible trap falls back, it doesn't vanish", function()
    sim.startRun(true)
    sim.player.ship.hullIntegrity.first = _G.apTrapLimits.hullFloor
    sim.clearLog()
    springTrapNow("hull_damage")
    check(sim.logged("falling back to"), "the log names the fallback")
    check(shownKey("trap.sprung"), "and the player sees that something happened")
end)

test("trap: when nothing more is possible, the mod says so", function()
    sim.startRun(true)
    sim.player.ship.hullIntegrity.first = _G.apTrapLimits.hullFloor
    sim.player.fuel_count = _G.apTrapLimits.fuelFloor
    local systems = sim.player.vSystemList
    for i = 0, systems:size() - 1 do
        systems[i].healthState.first = _G.apTrapLimits.systemFloor
    end
    local failing = function() error("engine unavailable") end
    sim.player.StartFire = failing
    sim.player.DamageArea = failing
    sim.player.GetRandomRoomCenter = failing

    sim.clearLog()
    springTrapNow("hull_damage")
    check(shownKey("trap.fizzled"),
          "the player is told the trap couldn't do anything")
    equals(sim.errors, 0, "and nothing is reported to the engine")
end)

test("trap: the player knows it comes from Archipelago, not the game", function()
    sim.startRun(true)
    sim.player.ship.hullIntegrity.first = 20
    sim.clearLog()
    springTrapNow("fire")
    check(shownKey("trap.sprung"), "the message is marked as a trap")
end)

test("trap: no trap destroys the ship, whatever the situation", function()
    for _, effect in ipairs({ "fire", "breach", "fuel_leak", "system_damage",
                              "hull_damage", "fleet_advance" }) do
        sim.reset()
        sim.startRun(true)
        sim.player.ship.hullIntegrity.first = 1
        sim.player.fuel_count = 0
        springTrapNow(effect)
        check(not sim.player.bDestroyed, effect .. " didn't destroy the ship")
        check(sim.player.ship.hullIntegrity.first >= 1, effect .. " left at least one point")
    end
end)

test("weapons, drones and augments are delivered", function()
    sim.startRun(true)
    apQueueItem({ kind = "weapon", bp = "LASER_BURST_3" })
    apQueueItem({ kind = "drone", bp = "DEFENSE_1" })
    apQueueItem({ kind = "augment", bp = "SCRAP_COLLECTOR" })
    drain()

    equals(sim.delivered(), 2, "the weapon and drone are delivered")
    equals(#sim.player._augments, 1, "the augment is installed on the ship")
end)

test("a delivered weapon is mounted if there is a slot, otherwise stored in cargo", function()
    sim.startRun(true)
    sim.slots.weapon = 1
    apQueueItem({ kind = "weapon", bp = "LASER_BURST_3" })
    apQueueItem({ kind = "weapon", bp = "BEAM_2" })
    drain()
    equals(#sim.equipped.weapon, 1, "the first takes the free slot")
    equals(#sim.cargo, 1, "the second goes to cargo, for lack of room")
end)

test("a nonexistent blueprint is REFUSED, not silently swallowed", function()
    sim.startRun(true)
    apQueueItem({ kind = "weapon", bp = "BURST_LASER_2" })
    drain()
    equals(sim.delivered(), 0, "nothing is added")
    check(sim.logged("unknown blueprint, item NOT delivered"), "and the refusal is logged")
    check(shownKey("item.unknown"), "and the player is warned on screen")
end)

test("the game is the authority on a blueprint's type", function()
    sim.startRun(true)
    apQueueItem({ kind = "weapon", bp = "DEFENSE_1" })
    drain()
    equals(sim.delivered(), 1, "the item is delivered anyway")
    check(sim.logged("kind corrected"), "and the correction is traced")
end)

test("a received item makes an unfindable object available", function()
    sim.weaponBlueprints.MISSILES_2 = 0
    sim.resetBlueprints()
    _G.apInventory = { ships = {}, shopAvailability = { MISSILES_2 = 1 } }
    apApplyShopRules()

    local desc = sim.rarityFor("MISSILES_2", 0)
    check(desc.rarity > 0, "the unfindable object can now be generated")
    check(desc.rarity >= 3, "but it stays rare on the first copy (got: " .. desc.rarity .. ")")
end)

test("further copies make the object more common", function()
    sim.weaponBlueprints.BEAM_2 = 4
    sim.resetBlueprints()
    _G.apInventory = { ships = {}, shopAvailability = { BEAM_2 = 3 } }
    apApplyShopRules()
    local desc = sim.rarityFor("BEAM_2", 4)
    equals(desc.rarity, 1, "three copies from 4 bring it to the most common")
end)

test("applying it twice doesn't drift the rarity", function()
    sim.weaponBlueprints.LASER_BURST_3 = 5
    sim.resetBlueprints()
    _G.apInventory = { ships = {}, shopAvailability = { LASER_BURST_3 = 2 } }
    apApplyShopRules()
    local first = sim.rarityFor("LASER_BURST_3", 5).rarity
    apApplyShopRules()
    apApplyShopRules()
    equals(sim.rarityFor("LASER_BURST_3", 5).rarity, first, "idempotent")
end)

test("a made-up blueprint name is reported, not silently applied", function()
    _G.apInventory = { ships = {}, shopAvailability = { NOT_A_REAL_NAME = 2 } }
    sim.clearLog()
    apApplyShopRules()
    check(sim.logged("unknown blueprint"), "the mod refuses and says so")
end)

test("a shop item makes the object more frequent, for good", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apShopConfigure({ mode = "rarity_boost", deliver = false, baseline = {} })
    sim.startRun(true)

    local before = sim.rarityFor("LASER_BURST_3", 5).rarity
    apQueueItem({ kind = "shop", bp = "LASER_BURST_3" })
    drain()
    check(sim.rarityFor("LASER_BURST_3", 5).rarity < before,
        "the rarity dropped, so the object is more common")
    equals(_G.apInventory.shopAvailability.LASER_BURST_3, 1, "the inventory keeps count")
end)

test("in locked mode, the object disappears from shops until its item arrives", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apShopConfigure({ mode = "locked", deliver = false, baseline = { "BEAM_2" } })
    sim.startRun(true)
    equals(sim.rarityFor("BEAM_2", 4).rarity, 0, "the object is unfindable at first")

    apQueueItem({ kind = "shop", bp = "BEAM_2" })
    drain()
    check(sim.rarityFor("BEAM_2", 4).rarity > 0, "the received item makes it appear")
end)

test("a reconnect doesn't relock what's already unlocked", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apShopConfigure({ mode = "locked", deliver = false, baseline = { "BEAM_2" } })
    sim.startRun(true)
    apQueueItem({ kind = "shop", bp = "BEAM_2" })
    drain()
    local unlocked = sim.rarityFor("BEAM_2", 4).rarity
    check(unlocked > 0, "the object is indeed unlocked before reconnecting")

    apShopConfigure({ mode = "locked", deliver = false, baseline = { "BEAM_2" } })
    equals(sim.rarityFor("BEAM_2", 4).rarity, unlocked, "it still is afterward")
end)

test("unlocking an object gives back its original rarity, no more, no less", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.droneBlueprints.COMBAT_1 = 2
    sim.resetBlueprints()
    apShopConfigure({ mode = "locked", deliver = false, baseline = { "COMBAT_1" } })
    sim.startRun(true)
    equals(sim.rarityFor("COMBAT_1", 2).rarity, 0, "removed from shops at first")

    apQueueItem({ kind = "shop", bp = "COMBAT_1" })
    drain()
    equals(sim.rarityFor("COMBAT_1", 2).rarity, 2, "the first item gives it vanilla rarity")

    apQueueItem({ kind = "shop", bp = "COMBAT_1" })
    drain()
    equals(sim.rarityFor("COMBAT_1", 2).rarity, 1, "the second makes it more common")
end)

test("a rare object stays rare when unlocked", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.weaponBlueprints.BEAM_2 = 4
    sim.resetBlueprints()
    apShopConfigure({ mode = "locked", deliver = false, baseline = { "BEAM_2" } })
    sim.startRun(true)
    apQueueItem({ kind = "shop", bp = "BEAM_2" })
    drain()
    equals(sim.rarityFor("BEAM_2", 4).rarity, 4, "it gets back its starting rarity, no better")
end)

test("immediate delivery gives one copy, and only one", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apShopConfigure({ mode = "rarity_boost", deliver = true, baseline = {} })
    sim.startRun(true)

    apQueueItem({ kind = "shop", bp = "LASER_BURST_3" })
    apQueueItem({ kind = "shop", bp = "LASER_BURST_3" })
    drain()
    equals(sim.delivered(), 1, "two items received, only one copy delivered")
    equals(_G.apInventory.shopAvailability.LASER_BURST_3, 2, "but both count in the shop")
end)

test("a shop object delivered right away is announced only once", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apShopConfigure({ mode = "rarity_boost", deliver = true, baseline = {} })
    sim.startRun(true)
    sim.clearLog()

    apQueueItem({ kind = "shop", bp = "MISSILES_2", display = "Artemis Missiles", sender = "Nina" })
    drain()

    local shownCount = 0
    for _, line in ipairs(sim.screen) do
        if line:find("Artemis Missiles", 1, true) then
            shownCount = shownCount + 1
        end
    end
    equals(shownCount, 1, "a single line on screen for a single item")
    check(shownKey("shop.unlocked.aboard"),
        "and it states both effects: sold in the shop, and one copy aboard")
    equals(sim.delivered(), 1, "the copy is delivered anyway")
end)

test("an augment received as a shop item is installed, not put in cargo", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apShopConfigure({ mode = "rarity_boost", deliver = true, baseline = {} })
    sim.startRun(true)
    apQueueItem({ kind = "shop", bp = "SCRAP_COLLECTOR" })
    drain()
    equals(#sim.player._augments, 1, "installed on the ship")
    equals(#sim.cargo, 0, "and not stored in cargo")
end)

test("an unknown shop object is refused", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apShopConfigure({ mode = "rarity_boost", deliver = true, baseline = {} })
    sim.startRun(true)
    sim.clearLog()
    apQueueItem({ kind = "shop", bp = "IMAGINARY_WEAPON" })
    drain()
    check(sim.logged("shop item NOT applied"), "the mod refuses and says so")
    equals(_G.apInventory.shopAvailability.IMAGINARY_WEAPON, nil, "nothing is counted")
end)

test("hints: the mod says where to look, not just how many are left", function()
    sim.startRun(true)
    _G.apShopSlotCount = 3
    applySeed({
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {},
        loc = {
            ["PLAYER_SHIP_HARD:sector:1"] = "Kestrel Cruiser A: Reach sector 1",
            ["PLAYER_SHIP_HARD:sector:2"] = "Kestrel Cruiser A: Reach sector 2",
            ["PLAYER_SHIP_HARD:victory"] = "Kestrel Cruiser A: Defeat the Flagship",
            ["shop:1"] = "Archipelago Shop 1",
        },
    })

    local leads = apNextLeads(3)
    check(#leads > 0, "at least one hint")
    for _, lead in ipairs(leads) do
        check(lead.name ~= nil and #lead.name > 0, "each hint carries a readable name")
        check(not lead.name:find("PLAYER_SHIP", 1, true),
              "and it's the Archipelago name: " .. lead.name)
        check(not lead.name:find("shop:", 1, true), "not the shop key: " .. lead.name)
    end
end)

test("hints: a location already done is no longer offered", function()
    sim.startRun(true)
    _G.apShopSlotCount = 0
    applySeed({
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {},
        loc = { ["PLAYER_SHIP_HARD:sector:1"] = "Kestrel Cruiser A: Reach sector 1" },
    })
    local before = #apNextLeads(3)
    apSendCheck("PLAYER_SHIP_HARD:sector:1", "done")
    local after = #apNextLeads(3)
    check(after < before, "the hint disappears once the check is sent")
end)

test("hints: no hint is invented outside the seed", function()
    sim.startRun(true)
    _G.apShopSlotCount = 0
    applySeed({
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {}, loc = { ["PLAYER_SHIP_HARD:victory"] = "Kestrel Cruiser A: Defeat the Flagship" },
    })
    local leads = apNextLeads(5)
    equals(#leads, 1, "a single hint, the one that exists")
    equals(leads[1].name, "Kestrel Cruiser A: Defeat the Flagship", "and it's the right one")
end)

test("hints: offline, nothing is offered rather than a guess", function()
    sim.startRun(true)
    equals(#apNextLeads(3), 0, "no hints as long as the seed isn't known")
end)

test("the dashboard says which run we are in", function()
    sim.startRun(true)
    applySeed({
        goal = { kind = "victories", count = 3 },
        start_ship = "PLAYER_SHIP_ROCK",
        seed_name = "42424242",
        links = { death = { enabled = true, trigger = "both", effect = "fire" },
                  energy = { enabled = true }, trap = { enabled = false } },
    })
    local summary = apSeedSummary()
    check(summary ~= nil, "the summary exists once connected")
    equals(summary.ship, "PLAYER_SHIP_ROCK", "it carries the starting ship")
    equals(summary.name, "42424242", "and the seed's name")

    apToggleHud()
    sim.renderGui()
    check(sim.drawnText("3"), "the goal is shown")
    check(sim.drawnText("DeathLink"), "so are active links")
    check(not sim.drawnText("TrapLink"), "and not the inactive ones")
    apToggleHud()
end)

test("the seed summary doesn't exist offline", function()
    sim.startRun(true)
    equals(apSeedSummary(), nil, "nothing to summarize without a seed")
end)

test("the dashboard no longer says where to look next", function()
    sim.startRun(true)
    _G.apShopSlotCount = 2
    applySeed({
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {}, loc = { ["shop:1"] = "Archipelago Shop 1" },
    })
    apToggleHud()
    sim.renderGui()
    check(not sim.drawnText("Archipelago Shop 1"),
        "the list of places to visit taught the player nothing")
    check(not sim.drawnText("OÙ CHERCHER") and not sim.drawnText("WHERE TO LOOK"),
        "and its header went away with it")
    apToggleHud()
end)

local STATUS_FUNCTIONS = {
    "apCargoStatus", "apCheckStatus", "apContractStatus", "apDeathLinkStatus",
    "apEnergyLinkStatus", "apEventStatus", "apFillerStatus", "apGoalStatus", "apLangStatus",
    "apNetStatus", "apShopGiftsStatus", "apShopStatus", "apSoloStatus", "apSystemStatus",
    "apTrapLinkStatus", "apUnlockStatus",
}

test("status: no status function crashes offline", function()
    sim.startRun(true)
    for _, name in ipairs(STATUS_FUNCTIONS) do
        local fn = _G[name]
        check(type(fn) == "function", name .. " exists")
        if type(fn) == "function" then
            local ok, err = pcall(fn)
            check(ok, name .. " doesn't raise: " .. tostring(err))
        end
    end
end)

test("status: no status function crashes once the seed is applied", function()
    sim.startRun(true)
    _G.apShopSlotCount = 3
    applySeed({
        goal = { kind = "victories", count = 2 },
        loc = { ["shop:1"] = "Archipelago Shop 1" },
        items = { ["20 Scrap"] = { k = "filler", res = "scrap", n = 20 } },
        links = { death = { enabled = true }, energy = { enabled = true },
                  trap = { enabled = true } },
    })
    apShopGiftsConfigure({
        { location = "shop:1", slot = "Nina", item = "Dice", sphere = 1, kind = "progression",
          cost = 40 },
    })
    for _, name in ipairs(STATUS_FUNCTIONS) do
        local ok, err = pcall(_G[name])
        check(ok, name .. " doesn't raise: " .. tostring(err))
    end
    equals(sim.errors, 0, "and nothing is reported to the engine")
end)

test("status: the display utilities respond", function()
    check(#apLangAvailable() >= 6, "at least six supported languages")
    local human = _G.apEnergyLinkHuman and _G.apEnergyLinkHuman(1500) or nil
    check(type(human) == "string" and #human > 0, "joules get formatted")
end)

test("status: the shared pool syncs from the server", function()
    sim.startRun(true)
    local ok = pcall(apEnergyLinkSync, 12000)
    check(ok, "the sync doesn't raise")
    apEnergyLinkStatus()
    check(sim.logged("12000") or sim.logged("J"), "and the status reflects what the server said")
end)

test("status: unlocking all ships at once works", function()
    sim.startRun(true)
    local count = apUnlockAll()
    check(type(count) ~= "boolean", "the function returns a count, not a boolean")
    local unlocked = 0
    for _ in pairs(sim.unlocked) do unlocked = unlocked + 1 end
    check(unlocked > 5, "several ships are unlocked (" .. unlocked .. ")")
end)

test("status: manually unlocking a ship works", function()
    sim.startRun(true)
    check(apUnlock("PLAYER_SHIP_ROCK", 0) ~= false, "unlocking returns a result")
    check(sim.unlocked["PLAYER_SHIP_ROCK"] == true, "and the ship is unlocked")
end)

local function connectNow()
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = "{}" })
    sim.tick(1)
end

local function seconds(count)
    sim.tick(count * 60)
end

test("network: a successful connection is told to the player", function()
    sim.startRun(true)
    connectNow()
    check(_G.apNetState.connected, "the mod knows it's connected")
    check(sim.shown("Navigator"), "and the player sees under which slot")
end)

test("network: slot_data received as a table is applied", function()
    sim.startRun(true)
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {}, loc = { ["shop:1"] = "Archipelago Shop 1" },
    } })
    sim.tick(1)
    check(_G.apContractState.connected == true, "the seed has been applied")
    equals(apLocationNameFor("shop:1"), "Archipelago Shop 1", "and its tables are in place")
end)

test("network: a refused password says so, and says what to do", function()
    sim.startRun(true)
    apNetConnect("ws://localhost:38281", "Navigator", "wrong")
    sim.netEvent("refused", { extra = "InvalidPassword" })
    sim.tick(1)
    check(shownKey("net.refused.password"), "the player knows it's the password")
    check(not _G.apNetState.connected, "and the mod doesn't think it's connected")
end)

test("network: after a refusal, a dropped socket doesn't restart the loop", function()
    sim.startRun(true)
    apNetConnect("ws://localhost:38281", "Navigator", "wrong")
    sim.netEvent("refused", { extra = "InvalidSlot" })
    sim.tick(1)
    sim.clearLog()
    sim.netEvent("disconnected", {})
    sim.tick(1)
    check(_G.apNetState.retryAt == nil, "no reconnection is scheduled")
    local before = sim.netCalls("Connect")
    sim.tick(60 * 120)
    equals(sim.netCalls("Connect"), before, "and none is attempted")
end)

test("network: several refusal reasons are all reported", function()
    sim.startRun(true)
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("refused", { extra = "InvalidSlot,InvalidGame" })
    sim.tick(1)
    check(shownKey("net.refused.slot"), "the slot name")
    check(shownKey("net.refused.game"), "and the game")
end)

test("network: an unknown refusal reason is shown as-is, not swallowed", function()
    sim.startRun(true)
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("refused", { extra = "AReasonThatDoesNotExistYet" })
    sim.tick(1)
    check(sim.shown("AReasonThatDoesNotExistYet"), "the token reaches the screen")
end)

test("network: a refusal with no reason is still reported", function()
    sim.startRun(true)
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("refused", { extra = "" })
    sim.tick(1)
    check(shownKey("net.refused.unknown"), "the player isn't left staring at a silent screen")
end)

test("network: checks already done are recovered from the server on reconnect", function()
    sim.startRun(true)
    apForgetChecksForTesting()
    sim.net.checked = { "Archipelago Shop 1", "Archipelago Shop 3" }
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {}, loc = {
            ["shop:1"] = "Archipelago Shop 1",
            ["shop:2"] = "Archipelago Shop 2",
            ["shop:3"] = "Archipelago Shop 3",
        },
    } })
    sim.tick(1)
    equals(apCheckCount().sent, 2, "the counter shows what the server knows")
    equals(apCheckCount().total, 3, "out of the seed's total")
    check(sim.shown("2"), "and the player learns it, in one line")
end)

test("closing FTL mid-run and coming back tomorrow doesn't double any bonus", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    sim.startRun(true)
    applySeed({ loc = {}, kinds = { "start" }, items = {
        ["Engines Head Start"] = { k = "start", sys = "engines", n = 2 },
    } })
    sim.netEvent("item", { name = "Engines Head Start", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()
    equals(_G.apInventory.startingUpgrades.engines, 2, "the bonus is acquired")

    apInventoryClear()
    apForgetChecksForTesting()
    apFillerForgetSeed()
    apContractResetForTesting()
    local reactorBeforeResume = sim.powerManager.currentPower.second

    sim.startRun(false)
    sim.powerManager.currentPower.second = reactorBeforeResume
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "start" }, kinds_required = {}, loc = {},
        items = { ["Engines Head Start"] = { k = "start", sys = "engines", n = 2 } },
    } })
    sim.netEvent("item", { name = "Engines Head Start", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()

    equals(_G.apInventory.startingUpgrades.engines, 2,
        "the inventory is rebuilt identically, not doubled")
    equals(sim.powerManager.currentPower.second, reactorBeforeResume,
        "and the current run doesn't receive its bonuses a second time")
end)

test("network: a recovered check is not resent to the server", function()
    sim.startRun(true)
    apForgetChecksForTesting()
    sim.net.checked = { "Archipelago Shop 1" }
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {}, loc = { ["shop:1"] = "Archipelago Shop 1" },
    } })
    sim.tick(1)
    local before = sim.netCalls("SendCheck")
    check(apSendCheck("shop:1", "Shop 1") == false, "the check is already done, it doesn't go out again")
    equals(sim.netCalls("SendCheck"), before, "and nothing went out over the network")
end)

test("network: a name the seed doesn't know is not recovered", function()
    sim.startRun(true)
    apForgetChecksForTesting()
    sim.net.checked = { "Archipelago Shop 1", "A location from another world" }
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {}, loc = { ["shop:1"] = "Archipelago Shop 1" },
    } })
    sim.tick(1)
    equals(apCheckCount().sent, 1, "only the name the seed declares is recovered")
end)

test("network: a first connection says nothing about recovery", function()
    sim.startRun(true)
    apForgetChecksForTesting()
    sim.net.checked = {}
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {}, loc = { ["shop:1"] = "Archipelago Shop 1" },
    } })
    sim.tick(1)
    check(not shownKey("check.adopted"), "nothing is said")
    equals(apCheckCount().sent, 0, "and the counter does start from zero")
end)

test("network: slot_data arrives as JSON and the mod decodes it", function()
    sim.startRun(true)
    apNetResetForTesting()
    apContractResetForTesting()
    apNetConnect("ws://localhost:38281", "Navigator", "")

    local json = '{"contract":1,"kinds":["filler"],"kinds_required":[],"items":{},"loc":{}}'
    sim.netEvent("connected", { name = "Navigator", extra = json })
    sim.tick(1)

    equals(_G.apContractState.connected, true, "the server's seed is applied")
end)

test("network: unreadable slot_data is reported, it isn't silent", function()
    sim.startRun(true)
    apNetResetForTesting()
    apContractResetForTesting()
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = '{"contract":1,"kinds":[' })
    sim.tick(1)
    check(not (_G.apContractState.connected == true), "nothing was applied")
    check(shownKey("net.slot_data_unreadable"), "and the player is warned")
end)

test("json: Archipelago's types pass through the decoder", function()
    local t = apJsonDecode('{"a":1,"b":-2.5,"c":"x","d":true,"e":null,"f":[1,2,3],"g":{"h":1}}')
    check(t ~= nil, "the JSON is read")
    equals(t.a, 1, "an integer stays an integer")
    equals(t.b, -2.5, "a negative float passes")
    equals(t.c, "x", "a string passes")
    equals(t.d, true, "a true boolean passes")
    equals(t.e, false, "null becomes false, not nil")
    equals(#t.f, 3, "an array keeps its length")
    equals(t.g.h, 1, "and objects nest")
end)

test("json: escapes and UTF-8 in slot names", function()
    local t = apJsonDecode('{"s":"a\\"b","t":"line\\nnext","u":"\\u00e9","v":"\\ud83d\\ude00"}')
    check(t ~= nil, "the JSON is read")
    equals(t.s, 'a"b', "an escaped quote")
    equals(t.t, "line\nnext", "a line break")
    equals(t.u, "é", "an accented character via \\u")
    equals(#t.v, 4, "an emoji reassembled into four UTF-8 bytes")
end)

test("json: a broken entry returns nil, never a half-filled table", function()
    local broken = {
        '{"a":1', '{"a"1}', '[1,2', '{"a":}', 'tru', '{"a":1}garbage', '', '{"a":"not finished}',
    }
    for _, text in ipairs(broken) do
        local t, err = apJsonDecode(text)
        equals(t, nil, "refused: '" .. text .. "'")
        check(type(err) == "string" and #err > 0, "and says why: " .. tostring(err))
    end
end)

test("network: a lost connection is announced, only once", function()
    sim.startRun(true)
    connectNow()
    sim.clearLog()

    sim.netEvent("disconnected", {})
    sim.tick(1)
    check(not _G.apNetState.connected, "the mod knows it's offline")
    check(shownKey("net.disconnected"), "the player is warned")

    local before = #sim.screen
    sim.netEvent("disconnected", {})
    sim.tick(1)
    equals(#sim.screen - before, 1, "only the new-attempt notice is added")
end)

test("network: after a drop, the mod retries on its own", function()
    sim.startRun(true)
    connectNow()
    sim.netEvent("disconnected", {})
    sim.tick(1)

    local before = sim.netCalls("Connect")
    seconds(4)
    equals(sim.netCalls("Connect"), before, "not yet: the delay hasn't elapsed")
    seconds(2)
    equals(sim.netCalls("Connect"), before + 1, "the attempt went out")
end)

test("network: attempts space out instead of hammering the server", function()
    sim.startRun(true)
    connectNow()

    local delays = {}
    for attempt = 1, 4 do
        sim.netEvent("disconnected", {})
        sim.tick(1)
        local before = sim.netCalls("Connect")
        local waited = 0
        while sim.netCalls("Connect") == before and waited < 120 do
            seconds(1)
            waited = waited + 1
        end
        delays[attempt] = waited
    end
    check(delays[2] > delays[1], "the 2nd wait is longer than the 1st ("
          .. delays[1] .. " then " .. delays[2] .. " s)")
    check(delays[3] > delays[2], "and the 3rd more than the 2nd (" .. delays[3] .. " s)")
    check(delays[4] <= 61, "but it caps out (" .. delays[4] .. " s)")
end)

test("network: the connection's return is reported, and isn't confused with a fresh connection", function()
    sim.startRun(true)
    connectNow()
    sim.netEvent("disconnected", {})
    sim.tick(1)
    seconds(6)
    sim.clearLog()

    sim.netEvent("connected", { name = "Navigator", extra = "{}" })
    sim.tick(1)
    check(_G.apNetState.connected, "we're connected again")
    check(shownKey("net.reconnected"),
          "the message says it's a RETURN, not a first connection")
end)

test("network: an intentional disconnect doesn't trigger a reconnect", function()
    sim.startRun(true)
    connectNow()
    apNetDisconnect()
    local before = sim.netCalls("Connect")
    seconds(120)
    equals(sim.netCalls("Connect"), before, "no attempt after an intentional disconnect")
end)

test("network: checks done offline go out once the connection returns", function()
    sim.startRun(true)
    connectNow()
    applySeed({ loc = {
        ["a:1"] = "Location A", ["a:2"] = "Location B", ["a:3"] = "Location C",
    } })

    sim.netEvent("disconnected", {})
    sim.tick(1)
    apSendCheck("a:1", "offline")
    apSendCheck("a:2", "offline")
    equals(apPendingCheckCount(), 2, "both checks are waiting")

    local sentNames = {}
    sim.net.calls = {}
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {},
        loc = { ["a:1"] = "Location A", ["a:2"] = "Location B", ["a:3"] = "Location C" },
    } })
    sim.tick(1)

    equals(apPendingCheckCount(), 0, "nothing is waiting anymore")
    equals(sim.netCalls("SendCheck"), 2, "both checks went out to the server")
    check(shownKey("check.resent", { n = 2 }), "and the player knows they were caught up")
end)

test("a jump by the ENEMY ship triggers nothing at all", function()
    sim.startRun(true)
    applySeed({ loc = { ["PLAYER_SHIP_HARD:sector:1"] = "Sector 1" } })
    _G.apEnergyLink.enabled = true
    sim.net.calls = {}
    sim.clearLog()

    local enemy = sim.makeShip(1)
    sim.jumpArrive(enemy)

    equals(apCheckCount().sent, 0, "no sector check is validated")
    check(not sim.logged("JUMP_ARRIVE"), "the mod doesn't even log the arrival")

    sim.jumpArrive(sim.player)
    check(sim.logged("CHECK PLAYER_SHIP_HARD:sector:1"),
        "the player's jump, though, validates its sector")
    check(sim.logged("JUMP_ARRIVE"), "and it is logged")
end)

test("installing a system sends a check, and so does each tier", function()
    sim.startRun(true)
    applySeed({ loc = {
        ["sys:shields"] = "Install Shields",
        ["sys:shields:2"] = "Shields level 2",
        ["sys:engines"] = "Install Engines",
    } })
    sim.net.calls = {}
    sim.clearLog()

    sim.jumpArrive(sim.player)

    check(sim.logged("CHECK sys:shields"), "the installed system goes out as a check")
    check(sim.logged("CHECK sys:shields:2"),
        "and the tier already reached too, since it really is")
    check(sim.logged("CHECK sys:engines"), "every system on the ship counts")
    check(not sim.logged("CHECK sys:shields:8"),
        "but never a tier the ship hasn't reached")
end)

test("an earned achievement becomes a check, with its readable name", function()
    sim.startRun(true)
    applySeed({ loc = { ["ach:ACH_TOUGH_SHIP"] = "Achievement: solid hull" } })
    sim.net.calls = {}
    sim.clearLog()

    sim.earnAchievement("ACH_TOUGH_SHIP", 1)
    sim.jumpArrive()

    check(sim.logged("CHECK ach:ACH_TOUGH_SHIP"), "the achievement is reported, under the expected key")
    check(not sim.shown("ACH_TOUGH_SHIP"), "and the engine's id isn't shown")
end)

test("a locked achievement is not reported", function()
    sim.startRun(true)
    applySeed({ loc = { ["ach:ACH_TOUGH_SHIP"] = "Achievement: solid hull" } })
    sim.net.calls = {}

    sim.clearLog()
    sim.jumpArrive()

    check(not sim.logged("CHECK ach:"), "nothing goes out until it's earned")
end)

test("network: a check done offline that the server already knew about is not resent", function()
    sim.startRun(true)
    connectNow()
    applySeed({ loc = { ["a:1"] = "Location A", ["a:2"] = "Location B" } })

    sim.netEvent("disconnected", {})
    sim.tick(1)
    apSendCheck("a:1", "offline")
    apSendCheck("a:2", "offline")
    equals(apPendingCheckCount(), 2, "both are waiting")

    sim.net.checked = { "Location A" }
    sim.net.calls = {}
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {},
        loc = { ["a:1"] = "Location A", ["a:2"] = "Location B" },
    } })
    sim.tick(1)

    equals(sim.netCalls("SendCheck"), 1, "only the check the server doesn't know about goes out")
    equals(apPendingCheckCount(), 0, "and the queue is empty")
    check(sim.logged("the server already knew about"), "the log says why the other one stays")
    check(not shownKey("check.adopted", { n = 1 }), "and it isn't announced as a recovery")
    sim.net.checked = {}
end)

test("network: a check done online is not sent a second time", function()
    sim.startRun(true)
    connectNow()
    applySeed({ loc = { ["a:1"] = "Location A" } })
    sim.net.calls = {}
    apSendCheck("a:1", "online")
    equals(sim.netCalls("SendCheck"), 1, "sent once")
    equals(apPendingCheckCount(), 0, "and nothing pending")

    sim.netEvent("disconnected", {})
    sim.tick(1)
    seconds(6)
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {},
        loc = { ["a:1"] = "Location A" },
    } })
    sim.tick(1)
    equals(sim.netCalls("SendCheck"), 1, "and it doesn't go out again on reconnect")
end)

test("network: the dashboard shows what is waiting for the server", function()
    sim.startRun(true)
    connectNow()
    applySeed({ loc = { ["a:1"] = "Location A" } })
    sim.netEvent("disconnected", {})
    sim.tick(1)
    apSendCheck("a:1", "offline")

    apToggleHud()
    sim.renderGui()
    check(sim.drawnText("1"), "the count is shown")
    check(sim.drawnText("attente") or sim.drawnText("waiting"),
          "and it's presented as pending, not as done")
    apToggleHud()
end)

test("network: a location absent from the seed doesn't clog the queue", function()
    sim.startRun(true)
    connectNow()
    applySeed({ loc = { ["a:1"] = "Location A" } })
    apSendCheck("not:in:the:seed", "outside the seed")
    equals(apPendingCheckCount(), 0, "nothing is waiting")
end)

test("network: an item replayed after reconnecting is not applied twice", function()
    sim.startRun(true)
    connectNow()
    sim.netEvent("item", { name = "20 Scrap", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()
    local afterFirst = sim.player.currentScrap

    sim.netEvent("disconnected", {})
    sim.tick(1)
    seconds(6)
    sim.netEvent("connected", { name = "Navigator", extra = "{}" })
    sim.netEvent("item", { name = "20 Scrap", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()
    equals(sim.player.currentScrap, afterFirst, "the scrap wasn't credited twice")
end)

test("a lost run doesn't lose the queued items", function()
    sim.startRun(true)
    apQueueItem({ kind = "filler", res = "scrap", n = 25 })
    apQueueItem({ kind = "ship", bp = "PLAYER_SHIP_TESTE9", display = "Test Key" })

    sim.player.bDestroyed = true
    drain(2)
    equals(#_G.apFillerPendingForTesting(), 1,
        "the filler waits for a ship, the ship key is already stored")

    sim.player = sim.makeShip(0)
    sim.startRun(true)
    drain(2)
    equals(#_G.apFillerPendingForTesting(), 0, "and they're delivered on the next run")
    equals(sim.player.currentScrap, 25, "the scrap did arrive")
end)

test("network: a module error is translated, never echoed to the screen", function()
    sim.startRun(true)
    sim.netEvent("error", { name = "socket", extra = "Connection refused" })
    sim.tick(1)
    check(shownKey("net.error.socket"), "the player reads a sentence in THEIR language")
    check(not sim.shown("Connection refused"), "and not the C++ exception message")
    check(sim.logged("Connection refused"), "which is, however, in the log")
end)

test("network: an unknown error token echoes nothing to the screen", function()
    sim.startRun(true)
    sim.netEvent("error", { name = "a_future_token", extra = "" })
    sim.tick(1)
    check(shownKey("net.error.unknown"), "the player knows there's a network error")
    check(not sim.shown("a_future_token"), "without reading the token")
    check(sim.logged("a_future_token"), "that the log keeps")
end)

test("network: a received death reaches DeathLink with its sender and cause", function()
    apDeathLinkConfigure({ enabled = true, effect = "hull_damage" })
    sim.startRun(true)
    sim.netEvent("death", { sender = "Nina", name = "hull breach" })
    sim.tick(1)
    check(sim.logged("death received from Nina (hull breach)"),
        "the sender is the sender, the cause is the cause")
end)

test("network: a received trap reaches TrapLink with its sender and name", function()
    _G.apTrapLink.enabled = true
    sim.startRun(true)
    sim.netEvent("trap", { sender = "Axel", name = "Bomb Trap" })
    sim.tick(1)
    check(sim.logged("trap from Axel: 'Bomb Trap'"),
        "the trap is named, and so is its sender")
end)

test("network: the shared pool distinguishes what we get from what it holds", function()
    _G.apEnergyLink.enabled = true
    sim.startRun(true)
    local before = sim.player.fuel_count

    sim.netEvent("energy", { name = "EnergyLink1", value = 7000000, index = -1 })
    sim.tick(1)
    equals(sim.player.fuel_count, before, "a mere announcement doesn't give fuel")
    sim.clearLog()
    apEnergyLinkStatus()
    check(sim.logged("known pool=7.0 MJ"), "it updates what we know about the pool")

    sim.netEvent("energy", { name = "EnergyLink1", value = 0, index = 2500000 })
    sim.tick(1)
    equals(sim.player.fuel_count, before + 2, "a withdrawal, though, gives fuel")
end)

test("changing seed resets the tables cleanly, without mixing two runs", function()
    sim.startRun(true)
    applySeed({ loc = { ["old:1"] = "Old location" },
                items = { ["Old item"] = { k = "filler", res = "scrap", n = 5 } } })
    equals(apLocationNameFor("old:1"), "Old location", "the first seed is in place")

    applySeed({ loc = { ["new:1"] = "New location" },
                items = { ["New item"] = { k = "filler", res = "fuel", n = 2 } } })
    equals(apLocationNameFor("old:1"), nil, "the old location is gone")
    equals(apLocationNameFor("new:1"), "New location", "the new one is there")

    sim.clearLog()
    equals(apReceiveItem("Old item", "Nina"), false, "the old item is no longer recognized")
    check(sim.logged("without descriptor"), "and the mod says so")
end)

test("changing slot within the SAME multiworld also wipes the past", function()
    sim.startRun(true)
    apApplySlotData({
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {},
        loc = { ["a:1"] = "Location A" }, seed_hash = "MEME_HASH",
    }, "Navigator")
    apSendCheck("a:1", "first slot")
    equals(apCheckCount().sent, 1, "a check is made on the first slot")

    apApplySlotData({
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {},
        loc = { ["a:1"] = "Location A" }, seed_hash = "MEME_HASH",
    }, "Nina")
    equals(apCheckCount().sent, 0, "the second slot starts from zero")
    check(sim.logged("seed change"), "and the log says why")
end)

test("load: three hundred items received at once all arrive", function()
    sim.startRun(true)
    local before = sim.player.currentScrap
    for index = 1, 300 do
        apQueueItem({ kind = "filler", res = "scrap", n = 1,
                      display = "20 Scrap", sender = "Nina" })
    end
    equals(#_G.apFillerPendingForTesting(), 300, "all three hundred are queued")

    drain(2)
    equals(#_G.apFillerPendingForTesting(), 0, "and the queue empties entirely")
    equals(sim.player.currentScrap, before + 300, "each item produced its effect")
    equals(sim.errors, 0, "no error")
end)

test("load: a full queue doesn't drain mid-combat", function()
    sim.startRun(true)
    sim.enemy = sim.makeShip(1)
    for index = 1, 300 do
        apQueueItem({ kind = "filler", res = "scrap", n = 1 })
    end
    drain(3)
    equals(#_G.apFillerPendingForTesting(), 300, "nothing is delivered during combat")

    sim.enemy = nil
    drain(2)
    equals(#_G.apFillerPendingForTesting(), 0, "and everything goes out once combat is over")
end)

test("load: the dashboard holds up with sixty shop slots", function()
    sim.startRun(true)
    _G.apShopSlotCount = 60
    local locations = {}
    for slot = 1, 60 do
        locations["shop:" .. slot] = "Archipelago Shop " .. slot
    end
    applySeed({ loc = locations })

    apToggleHud()
    for _ = 1, 30 do
        sim.renderGui()
    end
    equals(sim.errors, 0, "thirty frames without error")
    equals(#apNextLeads(3), 3, "three hints, not sixty")
    apToggleHud()
end)

test("network: sends go through the C++ module when it's there", function()
    sim.startRun(true)
    connectNow()
    sim.net.calls = {}

    check(apNetSendGoal(), "the goal goes out")
    equals(sim.netCalls("SendGoal"), 1, "once")
    check(apNetSendTrap("Fire Trap"), "the trap goes out")
    equals(sim.netCalls("SendTrap"), 1, "once too")
    check(apNetSendDeath("hull destroyed"), "the death goes out")
    equals(sim.netCalls("SendDeath"), 1, "once as well")
end)

test("network: offline, sends return false without trying anything", function()
    sim.startRun(true)
    apNetDisconnect()
    sim.net.calls = {}
    equals(apNetSendGoal(), false, "the goal doesn't go out")
    equals(apNetSendTrap("Fire Trap"), false, "neither does the trap")
    equals(sim.netCalls("SendGoal") + sim.netCalls("SendTrap"), 0, "and nothing was attempted")
end)

test("network: without the C++ module, nothing crashes and the mod stays playable", function()
    sim.startRun(true)
    sim.net.present = false
    equals(apNetConnect("ws://localhost:38281", "Navigator", ""), false,
           "the connection fails cleanly")
    equals(apNetSendCheck("Archipelago Shop 1"), false, "and sends return false")
    seconds(10)
    equals(sim.errors, 0, "no error reported to the engine")
    sim.net.present = true
end)

local DEMO = {
    { slot = "Navigator", item = "Burst Laser Mark II", sphere = 2, kind = "progression",
      location = "PLAYER_SHIP_HARD:sector:3", cost = 45 },
    { slot = "Berserker", item = "20 Scrap", sphere = 1, kind = "filler",
      location = "PLAYER_SHIP_HARD:sector:4", cost = 20 },
}

test("a gift shows who it's meant for", function()
    apShopGiftsConfigure(DEMO)
    local desc = sim.rarityFor("AP_GIFT_2", 0)
    equals(desc.title.data, "Package for Berserker", "the title says what it is and for whom")
    check(desc.title.isLiteral, "and it's literal, otherwise FTL would show it empty")
    equals(desc.shortTitle.data, "Berserker", "and the box shows the recipient, not 'AP'")
end)

test("a package addressed to the player themselves says so in plain words", function()
    apApplySlotData({ contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {} }, "Navigator")
    apShopGiftsConfigure(DEMO)
    local desc = sim.rarityFor("AP_GIFT_1", 0)
    equals(desc.title.data, apT("shop.slot.title.self"),
        "paying for your own item without knowing it is where you lose the player")
    equals(desc.shortTitle.data, apT("shop.slot.self.short"),
        "and the box shouts it, it doesn't settle for the slot name")
end)

test("a slot name that's too long is truncated rather than overflowing", function()
    apShopGiftsConfigure({ { slot = "APlayerWithAnEndlessName", item = "X" } })
    local short = sim.rarityFor("AP_GIFT_1", 0).shortTitle.data
    check(#short <= 12, "truncated to 12 characters (got " .. #short .. ")")
    check(short:sub(1, 6) == "APlaye", "the start of the name stays readable")
end)

test("the details give the item, the sphere and the type", function()
    apShopGiftsConfigure(DEMO)
    local text = sim.rarityFor("AP_GIFT_1", 0).description.data
    check(text:find("Burst Laser Mark II", 1, true), "the item is named")
    check(text:find("Sphere 2", 1, true), "the sphere is there")
    check(text:find("progression", 1, true), "so is the type, lowercase within the sentence")
    check(text:find(" - ", 1, true) == nil,
        "and the details are separated by a comma, not a dash: " .. text)
end)

test("the price comes from the server", function()
    apShopGiftsConfigure(DEMO)
    equals(sim.rarityFor("AP_GIFT_1", 0).cost, 45, "first gift's price")
    equals(sim.rarityFor("AP_GIFT_2", 0).cost, 20, "second one's price")
end)

test("a slot with no gift doesn't show the raw template", function()
    apShopGiftsConfigure(DEMO)
    local desc = sim.rarityFor("AP_GIFT_3", 0)
    equals(desc.title.data, apT("shop.slot.empty.title"), "the third one announces it's empty")
    check(not desc.description.data:find("Sphere", 1, true), "and shows no detail")
end)

test("with no seed loaded, the shop says we're offline - not that it's exhausted", function()
    apShopGiftsConfigure({})
    apApplyShopGifts()

    local desc = sim.rarityFor("AP_GIFT_1", 0)
    equals(desc.shortTitle.data, apT("shop.slot.noseed.short"), "the box states the real status")
    check(desc.description.data:find("Archipelago", 1, true) ~= nil,
        "and the tooltip explains you need to connect to a multiworld")
    equals(desc.cost, 0, "and it costs nothing: there's nothing behind it")
end)

test("a package already sent elsewhere doesn't come back in the shop", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    applySeed({ loc = { ["shop:1"] = "Archipelago Shop 1", ["shop:2"] = "Archipelago Shop 2" } })
    apAdoptCheckedLocations({ "Archipelago Shop 1" })

    apShopGiftsConfigure({
        { slot = "Nina", item = "Progressive Shields", location = "shop:1", cost = 30 },
        { slot = "Axel", item = "20 Scrap", location = "shop:2", cost = 20 },
    })
    apApplyShopGifts()

    local first = sim.rarityFor("AP_GIFT_1", 0)
    check(first.description.data:find("Progressive Shields", 1, true) == nil,
        "the server already has it: offering it again would be false hope")
    check(first.description.data:find("20 Scrap", 1, true) ~= nil,
        "the first slot shows the one that's genuinely still to be sent")
end)

test("an empty slot says on the box that it's empty", function()
    apShopGiftsConfigure(DEMO)
    apApplyShopGifts()

    local desc = sim.rarityFor("AP_GIFT_3", 0)
    equals(desc.title.data, apT("shop.slot.empty.title"),
        "the box's title says so before the click, not after")
    equals(desc.cost, 0, "and emptiness isn't charged for")
end)

test("an empty slot next to full ones does say the queue is exhausted", function()
    apShopGiftsConfigure(DEMO)
    apApplyShopGifts()

    equals(sim.rarityFor("AP_GIFT_3", 0).shortTitle.data, apT("shop.slot.empty.short"),
        "the third slot is empty, not disconnected")
end)

test("buying a gift sends the check and removes the object", function()
    sim.startRun(true)
    apShopGiftsConfigure(DEMO)
    local sent = {}
    local restore_apSendCheck = stub("apSendCheck", function(key) sent[#sent + 1] = key end)

    sim.buy("AP_GIFT_1")
    sim.tick(60)

    equals(#sent, 1, "a check went out")
    equals(sent[1], "PLAYER_SHIP_HARD:sector:3", "the one for this gift")
    equals(sim.player:GetWeaponList():size(), 0, "and the object was removed from the ship")
    check(sim.shown("Burst Laser Mark II") and sim.shown("Navigator"),
          "the player sees where it's going")
    restore_apSendCheck()
end)

test("a silent apSendCheck doesn't make the send look like a duplicate", function()
    sim.startRun(true)
    apShopGiftsConfigure(DEMO)
    local restore_apSendCheck = stub("apSendCheck", function() end)
    sim.buy("AP_GIFT_1")
    sim.tick(60)
    check(sim.shown("Burst Laser Mark II"), "the send is treated as successful")
    restore_apSendCheck()
end)

test("a purchased gift's slot goes back to neutral", function()
    sim.startRun(true)
    apShopGiftsConfigure(DEMO)
    sim.buy("AP_GIFT_1")
    sim.tick(60)
    equals(sim.rarityFor("AP_GIFT_1", 0).title.data, apT("shop.slot.empty.title"),
        "you can't buy the same gift twice")
end)

test("a freed-up slot takes in the next gift", function()
    apApplySlotData({ contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {} }, "Navigator")
    local three = {
        { slot = "Navigator", item = "Burst Laser Mark II", location = "loc:1", cost = 45 },
        { slot = "Berserker", item = "20 Scrap", location = "loc:2", cost = 20 },
        { slot = "Axel", item = "Zoltan Shield", location = "loc:3", cost = 70 },
        { slot = "Nina", item = "Halberd Beam", location = "loc:4", cost = 55 },
    }
    _G.apShopSlotCount = 4
    sim.startRun(true)
    apShopGiftsConfigure(three)
    equals(sim.rarityFor("AP_GIFT_1", 0).shortTitle.data, apT("shop.slot.self.short"),
        "at first")

    local restore_apSendCheck = stub("apSendCheck", function() return true end)
    sim.buy("AP_GIFT_1")
    sim.tick(60)
    equals(sim.rarityFor("AP_GIFT_1", 0).shortTitle.data, "Nina",
        "the fourth gift takes the first one's place")
    restore_apSendCheck()
end)

test("a large shop shows more packages per beacon", function()
    apApplySlotData({ contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {} }, "Navigator")
    local packages = {}
    for index = 1, 12 do
        packages[index] = { slot = "Nina", item = "Item " .. index, location = "loc:" .. index, cost = 20 }
    end
    for _, case in ipairs({ { 20, 1, 3 }, { 45, 2, 6 }, { 80, 3, 9 }, { 150, 4, 12 } }) do
        _G.apShopSlotCount = case[1]
        sim.startRun(true)
        apShopGiftsConfigure(packages)
        equals(Hyperspace.playerVariables.ap_shop_pages, case[2],
            case[1] .. " slots: the beacon loads the shop with " .. case[2] .. " page(s)")
        equals(sim.rarityFor("AP_GIFT_" .. case[3], 0).shortTitle.data, "Nina",
            "the last visible package is filled")
        if case[3] < 12 then
            check(sim.rarityFor("AP_GIFT_" .. (case[3] + 1), 0).shortTitle.data ~= "Nina",
                "and no package is hidden in a slot this shop doesn't have")
        end
    end
    _G.apShopSlotCount = nil
end)

test("a gift whose check already went out is refunded, and the slot empties", function()
    sim.startRun(true)
    apShopGiftsConfigure({
        { slot = "Berserker", item = "Seashell", location = "already:1", cost = 45 },
    })
    local before = sim.player.currentScrap
    local restore_apSendCheck = stub("apSendCheck", function() return false end)

    sim.buy("AP_GIFT_1")
    sim.tick(60)

    equals(sim.player.currentScrap, before + 45, "the price paid is refunded to the player")
    check(shownKey("shop.gift.already_sent"), "and they're told why")
    equals(sim.rarityFor("AP_GIFT_1", 0).shortTitle.data,
        apT("shop.slot.empty.short"), "the slot empties, a dead gift isn't rebought")
    restore_apSendCheck()
end)

test("gifts don't change places before the player's eyes", function()
    local three = {
        { slot = "Navigator", item = "A", location = "stable:1", cost = 45 },
        { slot = "Berserker", item = "B", location = "stable:2", cost = 20 },
        { slot = "Axel", item = "C", location = "stable:3", cost = 70 },
        { slot = "Nina", item = "D", location = "stable:4", cost = 55 },
    }
    sim.startRun(true)
    apShopGiftsConfigure(three)
    local restore_apSendCheck = stub("apSendCheck", function() return true end)

    sim.buy("AP_GIFT_1")
    sim.tick(60)
    equals(sim.rarityFor("AP_GIFT_2", 0).shortTitle.data, "Berserker", "the second one hasn't moved")
    equals(sim.rarityFor("AP_GIFT_3", 0).shortTitle.data, "Axel", "neither has the third")
    restore_apSendCheck()
end)

test("when there's nothing left to offer, the slot refunds", function()
    sim.startRun(true)
    apShopGiftsConfigure({ { slot = "Navigator", item = "A", location = "solo:1", cost = 45 } })
    local restore_apSendCheck = stub("apSendCheck", function() return true end)
    sim.buy("AP_GIFT_1")
    sim.tick(60)
    restore_apSendCheck()

    equals(sim.rarityFor("AP_GIFT_1", 0).title.data, apT("shop.slot.empty.title"),
        "it announces it's empty")
    sim.player.currentScrap = 0
    sim.buy("AP_GIFT_1")
    sim.tick(60)
    equals(sim.player:GetWeaponList():size(), 0, "buying nothing doesn't leave a useless object")
end)

test("a gift bought into cargo is detected too", function()
    sim.startRun(true)
    apShopGiftsConfigure(DEMO)
    local sent = 0
    local restore_apSendCheck = stub("apSendCheck", function() sent = sent + 1 end)
    sim.cargo[#sim.cargo + 1] = "AP_GIFT_2"
    sim.tick(60)
    equals(sent, 1, "detected from cargo")
    restore_apSendCheck()
end)

test("slot_data says how many shop slots exist", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplySlotData({
        contract = 1, kinds = {}, kinds_required = {}, items = {},
        shop = { mode = "rarity_boost", deliver = false, baseline = {}, slots = 12 },
        links = {},
    })
    equals(_G.apShopSlotCount, 12, "the count is picked up")
    equals(#apShopSlotKeys(), 12, "and the keys to scout follow from it")
    equals(apShopSlotKeys()[1], "shop:1", "in the format the apworld expects")
end)

test("a seed with no shop scouts nothing", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplySlotData({
        contract = 1, kinds = {}, kinds_required = {}, items = {},
        shop = { mode = "rarity_boost", deliver = false, baseline = {}, slots = 0 },
        links = {},
    })
    equals(#apShopSlotKeys(), 0, "no key")
end)

test("scouted slots feed the shop", function()
    sim.startRun(true)
    apShopGiftsScouted({
        { slot = "Berserker", item = "Seashell", sphere = 2, kind = "progression",
          location = "shop:1", cost = 80 },
        { slot = "Axel", item = "Roll Fragment", sphere = 1, kind = "useful",
          location = "shop:2", cost = 50 },
    })
    equals(sim.rarityFor("AP_GIFT_1", 0).shortTitle.data, "Berserker", "the first one is shown")
    check(sim.rarityFor("AP_GIFT_1", 0).description.data:find("Seashell", 1, true),
        "with the item it carries")
end)

local function connectWithShop(slots, offers)
    local loc = {}
    local names = {}
    for i = 1, slots do
        loc["shop:" .. i] = "Archipelago Shop " .. i
        names[i] = "Archipelago Shop " .. i
    end
    sim.startRun(true)
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {},
        loc = loc,
        shop = { mode = "rarity_boost", deliver = false, baseline = {}, slots = slots,
                 offers = offers },
        links = {},
    } })
    sim.tick(1)
    return names
end

test("network: connecting requests the contents of the shop slots", function()
    local names = connectWithShop(3)
    equals(sim.netCalls("ScoutLocations"), 1, "a scout request went out")
    local request
    for _, call in ipairs(sim.net.calls) do
        if call[1] == "ScoutLocations" then request = call end
    end
    equals(request.count, 3, "with the three slots the seed declares")
    equals(#names, 3, "translated into Archipelago names, the only ones the server knows")
end)

test("network: a received scout fills the shop slot", function()
    connectWithShop(2)
    sim.netEvent("scout", { name = "Archipelago Shop 1", sender = "Berserker",
        extra = "Seashell", value = 1 })
    sim.netEvent("scout", { name = "Archipelago Shop 2", sender = "Axel",
        extra = "Roll Fragment", value = 2 })
    sim.tick(1)
    equals(sim.rarityFor("AP_GIFT_1", 0).shortTitle.data, "Berserker",
        "the player sees who the first gift goes to")
    check(sim.rarityFor("AP_GIFT_1", 0).description.data:find("Seashell", 1, true),
        "and what it contains")
    equals(_G.apShopGifts[1].location, "shop:1",
        "the Archipelago name is translated back into a check key, otherwise buying would send nothing")
end)

test("network: a shop that fails to configure doesn't cut the tick", function()
    connectWithShop(1)
    _G.apShopGiftsScouted = function() error("shop broken") end
    sim.netEvent("scout", { name = "Archipelago Shop 1", sender = "Berserker",
        extra = "Seashell", value = 1 })

    local ok = pcall(sim.tick, 1)
    check(ok, "the error stays inside the network module, the tick continues")
    check(sim.logged("shop not configured"), "and it's written to the log, not swallowed")
end)

test("shop: a gift arriving after an empty slot is never free", function()
    connectWithShop(1)
    apShopGiftsConfigure({})
    equals(sim.rarityFor("AP_GIFT_1", 0).cost, 0, "the empty slot costs nothing")

    sim.netEvent("scout", { name = "Archipelago Shop 1", sender = "Berserker",
        extra = "Seashell", value = 1 })
    sim.tick(1)
    equals(sim.rarityFor("AP_GIFT_1", 0).cost, 70,
        "the progression gift gets a real price, without inheriting the empty slot's zero")
end)

test("shop: the price and sphere computed by the seed are displayed", function()
    connectWithShop(2, { ["shop:1"] = { price = 95, sphere = 4, kind = "progression" },
                         ["shop:2"] = { price = 20, sphere = 1, kind = "filler" } })
    sim.netEvent("scout", { name = "Archipelago Shop 1", sender = "Berserker",
        extra = "Seashell", value = 1 })
    sim.netEvent("scout", { name = "Archipelago Shop 2", sender = "Axel",
        extra = "10 Points", value = 0 })
    sim.tick(1)
    equals(sim.rarityFor("AP_GIFT_1", 0).cost, 95, "the important object costs what the seed set")
    equals(sim.rarityFor("AP_GIFT_2", 0).cost, 20, "filler stays cheap")
    check(sim.rarityFor("AP_GIFT_1", 0).description.data:find(apT("shop.slot.sphere", { n = 4 }), 1, true),
        "the sphere is shown, even when the server doesn't give it in the scout")
end)

test("shop: with no price from the seed, importance sets the price", function()
    connectWithShop(3)
    sim.netEvent("scout", { name = "Archipelago Shop 1", sender = "A", extra = "X", value = 1 })
    sim.netEvent("scout", { name = "Archipelago Shop 2", sender = "B", extra = "Y", value = 2 })
    sim.netEvent("scout", { name = "Archipelago Shop 3", sender = "C", extra = "Z", value = 0 })
    sim.tick(1)
    local prices = {}
    for i = 1, 3 do prices[i] = sim.rarityFor("AP_GIFT_" .. i, 0).cost end
    table.sort(prices)
    equals(table.concat(prices, ","), "10,30,70", "filler, useful, progression: cheapest to priciest")
end)

test("network: a scout's flags decide the announced type", function()
    connectWithShop(8)
    local expected = {
        [0] = "filler", [1] = "progression", [2] = "useful", [3] = "progression",
        [4] = "trap", [5] = "trap", [6] = "trap", [7] = "trap",
    }
    for flags = 0, 7 do
        sim.netEvent("scout", { name = "Archipelago Shop " .. (flags + 1),
            sender = "Nina", extra = "Item " .. flags, value = flags })
    end
    sim.tick(1)
    for flags = 0, 7 do
        equals(_G.apShopGifts[flags + 1].kind, expected[flags],
            "flags " .. flags .. " -> " .. expected[flags])
    end
end)

test("network: a scout doesn't invent a sphere", function()
    connectWithShop(1)
    sim.netEvent("scout", { name = "Archipelago Shop 1", sender = "Berserker",
        extra = "Seashell", value = 1 })
    sim.tick(1)
    equals(_G.apShopGifts[1].sphere, nil, "no sphere is announced")
    check(not sim.rarityFor("AP_GIFT_1", 0).description.data:find("Sphere", 1, true),
        "and the slot doesn't show one")
end)

test("network: the batch of scouts is delivered only once", function()
    connectWithShop(1)
    sim.netEvent("scout", { name = "Archipelago Shop 1", sender = "Berserker",
        extra = "Seashell", value = 1 })
    sim.tick(1)
    check(sim.logged("location(s) scouted from the server"), "the batch is delivered")
    sim.clearLog()
    sim.netEvent("item", { name = "20 Scrap", sender = "Nina", index = 0 })
    sim.tick(1)
    check(not sim.logged("location(s) scouted from the server"),
        "and a tick carrying a different event doesn't redeliver it")
end)

test("a deal announces its payoff and its risks", function()
    sim.startRun(true)
    apShopGiftsConfigure(DEMO)
    local desc = sim.rarityFor("AP_DEAL_1", 0)

    check(desc.title.data:find("scrap", 1, true), "the payoff is in the title")
    check(desc.shortTitle.data:find("+", 1, true), "and in the box, which is narrow")
    check(desc.description.data:find("fire", 1, true), "the possible traps are listed")
    check(desc.description.data:find("hull breach", 1, true), "all of them, not just the first")
    check(desc.description.data:find("Two times out of three", 1, true),
        "and the odds of getting hit by one yourself")
end)

test("signing a deal earns scrap", function()
    sim.startRun(true)
    apShopGiftsConfigure(DEMO)
    sim.player.currentScrap = 0
    sim.sign("AP_DEAL_1")
    sim.tick(60)
    check(sim.player.currentScrap > 0, "the scrap arrives (got: "
        .. sim.player.currentScrap .. ")")
    equals(sim.player:GetWeaponList():size(), 0, "and the object doesn't stay in cargo")
end)

test("a deal always produces a trap, here or elsewhere", function()
    apShopGiftsConfigure(DEMO)
    _G.apTrapLink.enabled = true
    local outward = 0
    _G.apNetSendTrap = function() outward = outward + 1 end

    local selfTraps, otherTraps = 0, 0
    for run = 1, 30 do
        sim.reset()
        apShopGiftsConfigure(DEMO)
        _G.apTrapLink.enabled = true
        sim.startRun(true)
        outward = 0
        sim.sign("AP_DEAL_2")
        sim.tick(60)
        if outward > 0 then
            otherTraps = otherTraps + 1
        else
            selfTraps = selfTraps + 1
        end
    end

    equals(selfTraps + otherTraps, 30, "every deal does have an effect")
    check(selfTraps > 0, "some backfire on us (" .. selfTraps .. "/30)")
    check(otherTraps > 0, "and most go out to others (" .. otherTraps .. "/30)")
    check(otherTraps > selfTraps, "a deal must stay tempting, so it mostly points outward")
    _G.apNetSendTrap = nil
end)

test("an unknown blueprint is announced by its Archipelago name, not its id", function()
    sim.startRun(true)
    apLangResolve("fr")
    sim.clearLog()
    apQueueItem({ kind = "weapon", bp = "A_BLUEPRINT_THAT_DOES_NOT_EXIST",
                  display = "Progressive Cloaking" })
    sim.jumpArrive()
    sim.tick(60)
    if _G.apNotifyFlushForTesting then apNotifyFlushForTesting() end
    check(sim.shown("Progressive Cloaking"), "the player reads the name they know")
    check(not sim.shown("A_BLUEPRINT_THAT_DOES_NOT_EXIST"),
          "and not the engine's id")
    check(sim.logged("A_BLUEPRINT_THAT_DOES_NOT_EXIST"),
          "that the log, though, keeps to help find the cause")
    apLangResolve(nil)
end)

test("solo: pressing S a second time doesn't destroy the current run", function()
    sim.startRun(true)
    apForgetChecksForTesting()
    if not apSoloStart() then return end

    apSendCheck("solo:one", "test")
    sim.jumpArrive()
    sim.tick(60)
    local received = _G.apSoloState.delivered
    check(received > 0, "an item was indeed received (" .. received .. ")")

    sim.clearLog()
    check(apSoloStart() == false, "the second press is refused")
    equals(_G.apSoloState.delivered, received, "and nothing is erased")
    check(shownKey("solo.already"), "the player learns where their run stands")

    check(apSoloStart(true) == true, "and an explicit restart is still possible")
    equals(_G.apSoloState.delivered, 0, "that one does start from zero")
    apSoloStop()
end)

test("solo: a received item doesn't have a made-up sender", function()
    sim.startRun(true)
    apForgetChecksForTesting()
    if apSoloStart() then
        apLangResolve("fr")
        sim.clearLog()
        apSendCheck("solo:test", "test")
        sim.jumpArrive()
        sim.tick(120)
        if _G.apNotifyFlushForTesting then apNotifyFlushForTesting() end
        check(not sim.shown(", de solo"), "no made-up sender")
        check(sim.shown("Reçu") or sim.shown("objets reçus"),
            "but the item is indeed announced, alone or in a batch")
        apSoloStop()
    end
    apLangResolve(nil)
end)

test("traplink: the counter only counts traps that actually went out", function()
    sim.startRun(true)
    _G.apTrapLink.enabled = true
    local previous = _G.apNetSendTrap

    _G.apNetSendTrap = function() return true end
    local sentCount = _G.apTrapLinkState.sent
    local unsentCount = _G.apTrapLinkState.unsent or 0
    apTrapLinkOnTrap({ kind = "trap", eff = "fire" })
    equals(_G.apTrapLinkState.sent, sentCount + 1, "a trap that went out is counted as sent")
    equals(_G.apTrapLinkState.unsent or 0, unsentCount, "and not as blocked")

    _G.apNetSendTrap = function() return false end
    sentCount = _G.apTrapLinkState.sent
    unsentCount = _G.apTrapLinkState.unsent or 0
    check(apTrapLinkOnTrap({ kind = "trap", eff = "breach" }) == false,
          "offline, the broadcast fails outright")
    equals(_G.apTrapLinkState.sent, sentCount, "nothing is counted as sent")
    equals(_G.apTrapLinkState.unsent or 0, unsentCount + 1, "and the block is counted separately")
    _G.apNetSendTrap = previous
end)

test("deathlink: a sent death is announced, so is one that stays here", function()
    sim.startRun(true)
    _G.apDeathLink.enabled = true
    local previous = _G.apNetSendDeath

    _G.apNetSendDeath = function() return true end
    sim.clearLog()
    check(apDeathLinkSend("test") == true, "the death goes out")
    check(shownKey("deathlink.sent"), "and it's said")
    check(not shownKey("deathlink.not_sent"), "without contradicting itself")

    sim.tick(60 * 60)
    _G.apNetSendDeath = function() return false end
    sim.clearLog()
    check(apDeathLinkSend("test") == false, "offline, the death doesn't go out")
    check(shownKey("deathlink.not_sent"), "and it's said plainly")
    check(not shownKey("deathlink.sent"), "a send that didn't happen isn't announced")
    _G.apNetSendDeath = previous
end)

test("offline, no deal promises someone else will pay", function()
    local previous = _G.apNetSendTrap
    local backfired, selfPaid = 0, 0
    for attempt = 1, 20 do
        sim.reset()
        apShopGiftsConfigure(DEMO)
        _G.apTrapLink.enabled = true
        sim.startRun(true)
        _G.apNetSendTrap = function() return false end
        sim.clearLog()
        sim.player.currentScrap = 0

        sim.sign("AP_DEAL_2")
        sim.tick(120)

        check(not shownKey("deal.other"),
              "attempt " .. attempt .. ": no promise of a payer that doesn't exist")
        if shownKey("deal.backfired") then backfired = backfired + 1 end
        if shownKey("deal.self") then selfPaid = selfPaid + 1 end
    end
    equals(backfired + selfPaid, 20, "every deal says what it does")
    check(backfired > 0, "and the backfire path is indeed alive (" .. backfired .. "/20)")
    _G.apNetSendTrap = previous
end)

test("online, a deal always promises someone else will pay", function()
    local previous = _G.apNetSendTrap
    local outward = 0
    for attempt = 1, 20 do
        sim.reset()
        apShopGiftsConfigure(DEMO)
        _G.apTrapLink.enabled = true
        sim.startRun(true)
        _G.apNetSendTrap = function() return true end
        sim.clearLog()

        sim.sign("AP_DEAL_2")
        sim.tick(120)
        check(not shownKey("deal.backfired"),
              "attempt " .. attempt .. ": nothing backfires when the trap went out")
        if shownKey("deal.other") then outward = outward + 1 end
    end
    check(outward > 0, "and most do go outward (" .. outward .. "/20)")
    _G.apNetSendTrap = previous
end)

test("signing the same deal twice earns nothing more", function()
    sim.startRun(true)
    apShopGiftsConfigure(DEMO)
    sim.sign("AP_DEAL_3")
    sim.tick(60)
    local after = sim.player.currentScrap

    sim.sign("AP_DEAL_3")
    sim.tick(60)
    equals(sim.player.currentScrap, after, "no extra scrap")
    check(shownKey("deal.closed"), "and the player is told")
end)

test("a system given by an event is NOT removed", function()
    sim.startRun(true)
    _G.apInventory.systemCaps.cloaking = nil
    sim.jumpArrive()
    sim.setStore(false)

    sim.constructSystem("cloaking", 0, 0)
    sim.tick(5)

    equals(#sim.player._removed, 0, "the system stays with the player")
    check(sim.logged("GIVEN by an event"), "and the mod says so")
end)

test("an Archipelago event sets its backdrop, even on a beacon already drawn", function()
    sim.startRun(true)
    equals(sim.decor.background, nil, "no backdrop before")

    sim.openChoiceBox("AP_EVT_ZOLTAN_TITHE")

    equals(sim.decor.background, "AP_BACKGROUND", "the purple sky is requested")
    equals(sim.decor.planet, "AP_PLANET", "and the six worlds in orbit with it")
    equals(sim.starMap.currentLoc.planetImage, "AP_PLANET",
        "the location retains its planet, otherwise FTL would redraw it on the next tick")
end)

test("an item arriving before the data packet isn't lost", function()
    sim.startRun(true)
    connectNow()
    sim.clearLog()

    sim.netEvent("item", { name = "Unknown", sender = "", index = 0 })
    sim.tick(1)
    check(not sim.shown("Unknown"), "nothing is announced under apclientpp's fallback name")

    sim.netEvent("item", { name = "20 Scrap", sender = "Nina", index = 0 })
    sim.tick(1)
    check(sim.shown("20 Scrap"), "and the item comes back once the data packet is there")
end)

test("an item from the server isn't announced under the word 'Server'", function()
    sim.startRun(true)
    connectNow()
    applySeed({ items = { ["50 Scrap"] = { k = "filler", res = "scrap", n = 50 } } })
    sim.clearLog()

    sim.netEvent("item", { name = "50 Scrap", sender = "", index = 5 })
    sim.tick(1)
    drain()

    check(shownKey("item.received.server"),
        "it has its own sentence, instead of a sender name slapped on")
    check(sim.shown("50 Scrap"), "and the item is indeed announced")
end)

test("a player named Server keeps their name on what they send", function()
    sim.startRun(true)
    connectNow()
    applySeed({ items = { ["50 Scrap"] = { k = "filler", res = "scrap", n = 50 } } })
    sim.clearLog()

    sim.netEvent("item", { name = "50 Scrap", sender = "Server", index = 5 })
    sim.tick(1)
    drain()

    check(sim.shown("Server"), "their name is the one they chose, the mod doesn't mistake it for the server")
    check(not shownKey("item.received.server"), "the object isn't mistaken for a gift from the server")
end)

test("the demo doesn't overwrite a real run's shop", function()
    sim.startRun(true)
    connectNow()
    apShopGiftsConfigure({ { slot = "Nina", item = "Reactor Power", sphere = 2, kind = "progression" } })

    local applied = apShopGiftsConfigure(DEMO, "demo")

    equals(applied, false, "the demo is refused as long as a server responds")
    equals(#_G.apShopGifts, 1, "the shop keeps what the server scouted")
    equals(_G.apShopGifts[1].slot, "Nina", "and the recipient stays the multiworld's")
end)

test("offline, the demo fills the shop", function()
    sim.startRun(true)
    apNetDisconnect()
    sim.tick(1)
    apShopGiftsConfigure({})

    local applied = apShopGiftsConfigure(DEMO, "demo")

    equals(applied, true, "with no server, the demo is the only thing to show")
    check(#_G.apShopGifts > 0, "and the shop fills up")
end)

test("the Archipelago shop arrives under the same sky as events", function()
    sim.startRun(true)
    equals(sim.decor.background, nil, "no backdrop before")

    sim.gameEvent("AP_STORE_EVENT")

    equals(sim.decor.background, "AP_BACKGROUND", "the purple sky, like for an event")
    equals(sim.decor.planet, "AP_PLANET", "and the six worlds in orbit")
    equals(sim.decor.x, 830, "placed at the same spot, otherwise the backdrop would jump between screens")

    sim.startRun(true)
    sim.openChoiceBox("AP_STORE_EVENT")
    equals(sim.decor.background, "AP_BACKGROUND",
        "also via the dialog box, depending on how FTL opens the shop")
end)

test("the Archipelago rosette always lands in the same spot", function()
    sim.startRun(true)
    sim.openChoiceBox("AP_EVT_ZOLTAN_TITHE")

    equals(sim.decor.x, 830, "the planet goes to the right: the player's ship holds the center")
    equals(sim.decor.y, 10, "and to the top: the event's dialog box covers the bottom")
    check(sim.decor.refreshed,
        "UpdatePlanetImage must be called: without it the screen keeps the cached image")
    equals(sim.starMap.currentLoc.planet.x, 830,
        "the location retains the position, otherwise the backdrop would jump when coming back to the beacon")
end)

test("the planet the beacon already shows isn't requested again - the game used to freeze there", function()
    sim.startRun(true)
    sim.starMap.currentLoc.planetImage = "AP_PLANET"
    sim.starMap.currentLoc.planet.w = 460

    sim.openChoiceBox("AP_EVT_ANOTHER_WORLD")

    equals(sim.decor.planetCalls, 0, "SwitchPlanet isn't called again: that's what used to freeze FTL")
    equals(sim.decor.x, 830, "the position is still enforced, that's all that was left to do")
end)

test("a beacon that doesn't have our planet yet receives it", function()
    sim.startRun(true)

    sim.openChoiceBox("AP_EVT_ANOTHER_WORLD")

    equals(sim.decor.planetCalls, 1, "a single call, and it happened")
    equals(sim.decor.planet, "AP_PLANET", "the rosette is placed")
end)

test("an event branch keeps its parent's backdrop", function()
    sim.startRun(true)
    sim.openChoiceBox("AP_EVT_ZOLTAN_TITHE_A")
    equals(sim.decor.planet, "AP_PLANET", "the branch carries the same backdrop")
end)

test("an FTL event keeps its own", function()
    sim.startRun(true)
    sim.openChoiceBox("STORE")
    equals(sim.decor.background, nil, "the mod doesn't touch events that aren't its own")
end)

test("a system on the ENEMY ship is ignored", function()
    sim.startRun(true)
    _G.apInventory.systemCaps.cloaking = nil
    sim.jumpArrive()
    sim.setStore(true)

    sim.constructSystem("cloaking", 1, 90)
    sim.tick(5)

    equals(#sim.player._removed, 0, "the player's ship isn't touched")
    check(not sim.logged("PURCHASE REFUSED"), "and no refusal is announced")
end)

test("a shop purchase of a not-yet-unlocked system is refused and refunded", function()
    sim.startRun(true)
    _G.apInventory.systemCaps.cloaking = nil
    sim.jumpArrive()
    sim.setStore(true)
    sim.player.currentScrap = 0

    sim.constructSystem("cloaking", 0, 90)
    sim.tick(5)

    equals(#sim.player._removed, 1, "the system is removed")
    equals(sim.player.currentScrap, 90, "and the scrap refunded, for the right amount")
    check(sim.logged("90 scrap refunded"), "the log states the real amount")
end)

test("a refund that didn't happen isn't announced", function()
    sim.startRun(true)
    _G.apInventory.systemCaps.cloaking = nil
    sim.jumpArrive()
    sim.setStore(true)
    sim.clearLog()

    sim.constructSystem("cloaking", 0, 0)
    sim.tick(5)

    check(not shownKey("shop.gift.already_sent", { price = 0 }),
          "no promise of a zero refund")
end)

test("the energy link announces what it deposits in the player's language", function()
    sim.gameLanguage = "fr"
    apLangResolve(nil)
    sim.startRun(true)
    _G.apEnergyLink.enabled = true
    _G.apEnergyLink.depositFuelAbove = 5
    _G.apEnergyLink.depositScrapAbove = 100
    _G.apEnergyLink.depositScrapShare = 0.25
    sim.player.fuel_count = 15
    sim.player.currentScrap = 200
    local restore = stub("apNetEnergyLinkDeposit", function() end)
    apEnergyLinkContribute()
    restore()

    check(not sim.shown("fuel"), "no 'fuel' on screen")
    check(not sim.shown("scrap"), "no 'scrap' either")
    check(sim.shown("carburant"), "but fuel does appear, in French")
    check(sim.shown("ferraille"), "and so does scrap")

    _G.apEnergyLink.depositScrapAbove = 0
    sim.gameLanguage = ""
    apLangResolve(nil)
end)

test("a crew member with no name keeps a readable name in their language", function()
    sim.gameLanguage = "fr"
    apLangResolve(nil)
    sim.startRun(true)
    apDeathLinkConfigure({ enabled = true, trigger = "both", effect = "crew_member" })
    for i = 0, sim.player.vCrewList:size() - 1 do
        sim.player.vCrewList[i].GetName = function() return nil end
    end
    sim.clearLog()
    apDeathLinkReceive("Nina", "died")
    check(not sim.shown("a crew member"), "no English fallback on screen")
    _G.apDeathLink.effect = "major_incident"
    sim.gameLanguage = ""
    apLangResolve(nil)
end)

test("contract: a failed module configuration no longer goes unnoticed", function()
    sim.startRun(true)
    local previous = _G.apShopConfigure
    _G.apShopConfigure = function() error("shop broken") end
    sim.clearLog()

    local accepted = apApplySlotData({
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {},
        seed_hash = 4242, shop = { mode = "off", slots = 3 },
    }, "Navigator")

    check(accepted ~= false, "the seed stays playable: items will still arrive")
    check(sim.logged("CONFIGURATION FAILED"), "the log names the module at fault")
    check(shownKey("contract.partial"), "and the player is warned that something won't work")
    _G.apShopConfigure = previous
end)

test("contract: a healthy seed triggers no warning", function()
    sim.startRun(true)
    sim.clearLog()
    apApplySlotData({
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {}, loc = {},
        seed_hash = 4343, shop = { mode = "off", slots = 3 },
    }, "Navigator")
    check(not sim.logged("CONFIGURATION FAILED"), "nothing failed")
    check(not shownKey("contract.partial"), "and the player isn't warned for nothing")
end)

test("unlock: all ten ships and their twenty-eight layouts are covered", function()
    sim.reset()
    sim.unlocked = {}
    apUnlockAll()

    local ships, layouts = {}, 0
    for name in pairs(sim.unlocked) do
        layouts = layouts + 1
        ships[(name:gsub("_%d$", ""))] = true
    end
    local distinct = 0
    for _ in pairs(ships) do distinct = distinct + 1 end

    equals(distinct, 10, "FTL's ten ships")
    equals(layouts, 28, "and their twenty-eight layouts (the Lanius and Crystal have no C)")
end)

test("run end: all three links of the chain are exercised", function()
    sim.startRun(true)
    apDeathLinkConfigure({ enabled = true, trigger = "ship_destroyed" })
    apVictoriesResetForTesting()
    local deaths = _G.apDeathLinkState.sent
    local restore = stub("apNetSendDeath", function() return true end)
    sim.clearLog()

    apOnRunEnd("destroyed", "hull destroyed")

    check(sim.logged("RUN END"), "the base link was reached (runend.lua)")
    equals(_G.apDeathLinkState.sent, deaths + 1, "the DeathLink link did its part")
    restore()

    sim.startRun(true)
    apVictoriesResetForTesting()
    apForgetChecksForTesting()
    applySeed({ loc = { ["PLAYER_SHIP_HARD:victory"] = "Kestrel A victory" },
                goal = { kind = "victories", count = 1 } })
    restore = stub("apNetSendGoal", function() return true end)
    local before = apCheckCount().sent
    apOnRunEnd("victory", nil)
    check(apCheckCount().sent > before, "the checks.lua link sent the victory")
    restore()
end)

test("DeathLink off sends nothing", function()
    apDeathLinkConfigure({ enabled = false })
    sim.startRun(true)
    sim.clearLog()
    local before = _G.apDeathLinkState.sent
    apOnRunEnd("destroyed", "hull destroyed")
    equals(_G.apDeathLinkState.sent, before, "no death sent")
end)

test("the trigger setting decides what counts as a death", function()
    apDeathLinkConfigure({ enabled = true, trigger = "ship_destroyed" })
    sim.startRun(true)

    local before = _G.apDeathLinkState.sent
    apOnRunEnd("destroyed", "hull destroyed")
    equals(_G.apDeathLinkState.sent, before + 1, "ship_destroyed sends on destruction")

    apDeathLinkConfigure({ trigger = "crew_death" })
    apOnRunEnd("destroyed", "hull destroyed")
    equals(_G.apDeathLinkState.sent, before + 1,
        "crew_death alone does NOT send on ship destruction")
end)

test("winning is not dying", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both" })
    sim.startRun(true)
    local before = _G.apDeathLinkState.sent
    apOnRunEnd("victory", "flagship destroyed")
    apOnRunEnd("menu", "back to main menu")
    equals(_G.apDeathLinkState.sent, before, "neither victory nor quitting sends anything")
end)

test("a victory whose ship isn't recognized tells the player", function()
    sim.startRun(true)
    applySeed({ loc = {} })
    local original = sim.player.myBlueprint.blueprintName
    sim.player.myBlueprint.blueprintName = ""
    sim.clearLog()

    apOnRunEnd("victory", nil)

    check(shownKey("check.victory.unknown_ship"), "the player knows there's something to say")
    check(sim.logged("victory detected but unknown ship"), "and the log says what")
    sim.player.myBlueprint.blueprintName = original
end)

test("quitting a run to the menu is a run end, not a death", function()
    apDeathLinkConfigure({ enabled = true, effect = "hull_damage", trigger = "both" })
    sim.startRun(true)
    applySeed({ loc = {} })
    sim.tick(20)
    sim.net.calls = {}
    sim.clearLog()

    sim.started = false
    sim.tick(20)

    check(sim.logged("RUN END: menu"), "the run end is announced, with its cause")
    equals(sim.netCalls("SendDeath"), 0, "and no death goes out over the link")
    equals(sim.netCalls("SendGoal"), 0, "quitting is not winning")

    sim.clearLog()
    sim.tick(20)
    check(not sim.logged("RUN END"), "and it's announced only once")
    sim.started = true
end)

test("a DeathLink with nothing left to break says so, instead of staying silent", function()
    apDeathLinkConfigure({ enabled = true, effect = "major_incident" })
    sim.startRun(true)
    for i = 0, sim.player.vSystemList:size() - 1 do
        sim.player.vSystemList[i].healthState.first = 0
    end
    sim.player.ship.hullIntegrity.first = 1
    for i = 1, sim.player.vCrewList:size() - 1 do
        sim.player.vCrewList[i].bDead = true
    end
    local restore_apRandomRoomId = stub("apRandomRoomId", function() return nil end)
    sim.clearLog()

    apDeathLinkReceive("Berserker", "died")
    restore_apRandomRoomId()

    check(shownKey("deathlink.fizzled"), "the player knows the death did arrive")
    check(sim.logged("no effect applicable"), "and the log says why it did nothing")

end)

test("a disabled link does nothing, and that's the player's setting", function()
    sim.startRun(true)
    apDeathLinkConfigure({ enabled = false, effect = "hull_damage" })
    _G.apTrapLink.enabled = false
    _G.apEnergyLink.enabled = false
    local hull = sim.player.ship.hullIntegrity.first
    local queued = #_G.apFillerPendingForTesting()
    sim.clearLog()

    check(apDeathLinkReceive("Nina", "hull breach") == false, "the received death is refused")
    equals(sim.player.ship.hullIntegrity.first, hull, "and the hull hasn't moved")
    check(apTrapLinkReceive("Axel", "Bomb Trap") == false, "the received trap is refused")
    equals(#_G.apFillerPendingForTesting(), queued, "and nothing enters the delivery queue")
    check(apEnergyLinkRequestFuel(2) == false, "the fuel request is refused")
    equals(sim.netCalls("EnergyLinkRequest"), 0, "and nothing goes out to the server")
end)

test("'both' is the default and covers both kinds of death", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both" })
    sim.startRun(true)
    sim.tick(30)
    local before = _G.apDeathLinkState.sent

    apOnRunEnd("destroyed", "hull destroyed")
    equals(_G.apDeathLinkState.sent, before + 1, "destruction counts")

    apDeathLinkConfigure({ graceSeconds = 0 })
    sim.player.vCrewList[0].bDead = true
    sim.tick(30)
    equals(_G.apDeathLinkState.sent, before + 2, "so does a crew member's death")
end)

test("the major incident breaks a system room, without touching the hull", function()
    apDeathLinkConfigure({ enabled = true, effect = "major_incident" })
    sim.startRun(true)
    local hull = sim.player.ship.hullIntegrity.first

    apDeathLinkReceive("Berserker", "died")

    check(sim.player._breaches > 0, "a breach opened")
    check(#sim.player._fires > 0, "a fire started")
    equals(sim.player.ship.hullIntegrity.first, hull, "but the hull is intact")

    local damaged = false
    local systems = sim.player.vSystemList
    for i = 0, systems:size() - 1 do
        if systems[i].healthState.first < systems[i].healthState.second then
            damaged = true
        end
    end
    check(damaged, "and a system was damaged")
end)

test("the incident targets a room WITH A SYSTEM, not a corridor", function()
    apDeathLinkConfigure({ enabled = true, effect = "major_incident" })
    sim.startRun(true)
    apDeathLinkReceive("Berserker", "died")
    local roomsWithSystem = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true }
    for _, room in ipairs(sim.player._fires) do
        check(roomsWithSystem[room] == true, "the fire is in a room with a system (room "
            .. tostring(room) .. ")")
    end
end)

test("the incident never destroys a system completely", function()
    apDeathLinkConfigure({ enabled = true, effect = "major_incident" })
    sim.startRun(true)
    for _ = 1, 20 do
        apDeathLinkReceive("Berserker", "died")
    end
    local systems = sim.player.vSystemList
    for i = 0, systems:size() - 1 do
        check(systems[i].healthState.first >= 1,
            "system " .. tostring(systems[i].name) .. " keeps at least one point")
    end
end)

test("'varied' never rolls the major incident", function()
    apDeathLinkConfigure({ enabled = true, effect = "varied" })
    sim.startRun(true)
    for _ = 1, 40 do
        apDeathLinkReceive("Berserker", "died")
        sim.player.ship.hullIntegrity.first = 30
    end
    equals(sim.player._breaches, 0, "no breach, so no major incident")
end)

test("a fallback is always gentler than the requested effect", function()
    apDeathLinkConfigure({ enabled = true, effect = "crew_member" })
    sim.startRun(true)
    sim.player.vCrewList[1].bDead = true
    sim.player.vCrewList[2].bDead = true

    apDeathLinkReceive("Berserker", "died")
    equals(sim.player._breaches, 0, "no breach in a fallback")
end)

test("a received death can never destroy the ship", function()
    apDeathLinkConfigure({ enabled = true, effect = "hull_damage" })
    sim.startRun(true)
    sim.player.ship.hullIntegrity.first = 1

    for _ = 1, 20 do
        apDeathLinkReceive("Berserker", "ran into a wall")
    end
    check(sim.player.ship.hullIntegrity.first >= 1, "the hull never drops to zero")
    check(not sim.player.bDestroyed, "and the ship isn't destroyed")
end)

test("a received death never kills the last crew member", function()
    apDeathLinkConfigure({ enabled = true, effect = "crew_member" })
    sim.startRun(true)
    for _ = 1, 10 do
        apDeathLinkReceive("Berserker", "died")
    end
    check(crewCount() >= 1, "there is always someone left aboard (left: " .. crewCount() .. ")")
end)

test("a received death always produces a visible effect", function()
    apDeathLinkConfigure({ enabled = true, effect = "crew_member" })
    sim.startRun(true)
    sim.player.vCrewList[1].bDead = true
    sim.player.vCrewList[2].bDead = true
    sim.clearLog()
    apDeathLinkReceive("Berserker", "died")
    check(sim.logged("death received from Berserker"), "a fallback effect was indeed applied")
end)

test("receiving a death doesn't send one back: no loop", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both", effect = "hull_damage",
                           graceSeconds = 15 })
    sim.startRun(true)
    apDeathLinkReceive("Berserker", "died")

    local before = _G.apDeathLinkState.sent
    apOnRunEnd("destroyed", "hull destroyed")
    equals(_G.apDeathLinkState.sent, before, "nothing is resent during the grace period")
    check(sim.logged("grace period"), "and the reason is logged")
end)

test("the grace period eventually expires", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both", graceSeconds = 1 })
    sim.startRun(true)
    apDeathLinkReceive("Berserker", "died")
    sim.tick(120)
    local before = _G.apDeathLinkState.sent
    apOnRunEnd("destroyed", "hull destroyed")
    equals(_G.apDeathLinkState.sent, before + 1, "once the delay is past, it sends again")
end)

test("a death received outside a run is ignored, not queued", function()
    apDeathLinkConfigure({ enabled = true, effect = "hull_damage" })
    sim.started = false
    sim.clearLog()
    local hull = sim.player.ship.hullIntegrity.first
    apDeathLinkReceive("Berserker", "died")
    equals(sim.player.ship.hullIntegrity.first, hull, "the ship isn't touched")
    check(sim.logged("outside a run"), "and it's said")
end)

test("losing a crew member sends a death", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both" })
    sim.startRun(true)
    sim.tick(30)
    local before = _G.apDeathLinkState.sent

    sim.player.vCrewList[0].bDead = true
    sim.tick(30)
    equals(_G.apDeathLinkState.sent, before + 1, "a single crew member's death is enough")
end)

test("a crew member gone boarding doesn't count as a death", function()
    apDeathLinkConfigure({ enabled = true, trigger = "both" })
    sim.startRun(true)
    sim.tick(30)
    local before = _G.apDeathLinkState.sent

    local boarder = sim.player.vCrewList[0]
    table.remove(sim.player.vCrewList._store, 1)
    sim.enemy = sim.makeShip(1)
    boarder.currentShipId = 1
    sim.enemy.vCrewList:push_back(boarder)

    sim.tick(30)
    equals(_G.apDeathLinkState.sent, before, "no death sent for a boarding")
end)

test("EnergyLink off touches nothing", function()
    apEnergyLinkConfigure({ enabled = false })
    sim.startRun(true)
    sim.player.fuel_count = 30
    sim.jumpArrive()
    equals(sim.player.fuel_count, 30, "fuel isn't taken")
end)

test("surplus fuel goes into the shared pool", function()
    apEnergyLinkConfigure({ enabled = true, depositFuelAbove = 20 })
    sim.startRun(true)
    connectNow()
    sim.player.fuel_count = 26
    sim.jumpArrive()
    equals(sim.player.fuel_count, 20, "only the surplus is given")
    check(_G.apEnergyLinkState.deposited > 0, "and it arrives in the pool")
end)

test("the deposit loses 25%, like in Factorio", function()
    apEnergyLinkConfigure({ enabled = true, depositFuelAbove = 20 })
    sim.startRun(true)
    connectNow()
    _G.apEnergyLinkState.deposited = 0
    sim.player.fuel_count = 24
    sim.jumpArrive()
    equals(_G.apEnergyLinkState.deposited, 3000000, "a quarter is lost on deposit")
end)

test("energy: a deposit refused by the server credits nothing, and keeps the fuel", function()
    apEnergyLinkConfigure({ enabled = true, depositFuelAbove = 20 })
    sim.startRun(true)
    _G.apEnergyLinkState.deposited = 0
    sim.player.fuel_count = 26
    sim.jumpArrive()

    equals(_G.apEnergyLinkState.deposited, 0, "nothing is credited")
    equals(sim.player.fuel_count, 26, "and the fuel stays aboard, it doesn't evaporate")
end)

test("nothing is given when there's no surplus", function()
    apEnergyLinkConfigure({ enabled = true, depositFuelAbove = 20 })
    sim.startRun(true)
    sim.player.fuel_count = 5
    _G.apEnergyLinkState.deposited = 0
    sim.jumpArrive()
    equals(sim.player.fuel_count, 5, "the fuel stays with the player")
    equals(_G.apEnergyLinkState.deposited, 0, "nothing is deposited")
end)

test("a failed deposit doesn't cost the player fuel", function()
    apEnergyLinkConfigure({ enabled = true, depositFuelAbove = 20 })
    sim.startRun(true)
    sim.player.fuel_count = 26
    _G.apNetEnergyLinkDeposit = function() error("network down") end
    sim.jumpArrive()
    equals(sim.player.fuel_count, 26, "the fuel stays aboard")
    _G.apNetEnergyLinkDeposit = nil
end)

test("granted fuel arrives on the ship", function()
    apEnergyLinkConfigure({ enabled = true })
    sim.startRun(true)
    sim.player.fuel_count = 1
    apEnergyLinkGranted(2000000)
    equals(sim.player.fuel_count, 3, "two units received")
    check(shownKey("energylink.received", { n = 2 }), "and the player sees it")
end)

test("a remainder too small for one unit goes back into the shared pot", function()
    apEnergyLinkConfigure({ enabled = true })
    sim.startRun(true)
    sim.player.fuel_count = 1
    _G.apEnergyLinkState.deposited = 0
    local returned = 0
    local restore = stub("apNetEnergyLinkDeposit", function(joules) returned = returned + joules; return true end)
    apEnergyLinkGranted(400000)
    restore()
    equals(sim.player.fuel_count, 1, "no unit is given")
    check(returned > 0, "and the remainder goes back to the server instead of being lost")
end)

test("an empty pool is told to the player, not passed over in silence", function()
    apEnergyLinkConfigure({ enabled = true })
    sim.startRun(true)
    sim.clearLog()
    apEnergyLinkGranted(0)
    check(shownKey("energylink.empty"), "the player knows the pool is empty")
end)

test("only one request per beacon", function()
    apEnergyLinkConfigure({ enabled = true, withdrawFuelBelow = 3, withdrawFuelAmount = 2 })
    sim.startRun(true)
    sim.player.fuel_count = 1
    local calls = 0
    _G.apNetEnergyLinkRequest = function() calls = calls + 1 end

    sim.jumpArrive()
    sim.tick(300)
    equals(calls, 1, "a single request for this beacon")

    sim.jumpArrive()
    equals(calls, 2, "the next beacon reopens the right to ask")
    _G.apNetEnergyLinkRequest = nil
end)

test("nothing is requested when fuel is comfortable", function()
    apEnergyLinkConfigure({ enabled = true, withdrawFuelBelow = 3 })
    sim.startRun(true)
    sim.player.fuel_count = 10
    local calls = 0
    _G.apNetEnergyLinkRequest = function() calls = calls + 1 end
    sim.jumpArrive()
    equals(calls, 0, "no needless request")
    _G.apNetEnergyLinkRequest = nil
end)

test("goal: a victory below the requested difficulty doesn't count", function()
    sim.startRun(true)
    apVictoriesResetForTesting()
    applySeed({ goal = { kind = "victories", count = 1, difficulty = "hard" } })
    local sent = 0
    local restore = stub("apNetSendGoal", function() sent = sent + 1 end)

    sim.difficulty = 1
    apVictoryWith("PLAYER_SHIP_HARD")
    equals(sent, 0, "winning on normal doesn't fulfill a hard-difficulty goal")
    check(shownKey("goal.too_easy"), "and the player knows why")
    equals(apGoalProgress().done, 0, "the counter doesn't move")

    sim.difficulty = 2
    apVictoryWith("PLAYER_SHIP_HARD")
    equals(apGoalProgress().done, 1, "the same victory on hard, though, counts")
    equals(sent, 1, "and the goal goes out to the server")
    sim.difficulty = 0
    restore()
end)

test("goal: any two victories trigger the declaration", function()
    sim.startRun(true)
    applySeed({ goal = { kind = "victories", count = 2 } })
    local sent = 0
    local restore = stub("apNetSendGoal", function() sent = sent + 1 end)

    apVictoryWith("PLAYER_SHIP_HARD")
    equals(sent, 0, "a single victory isn't enough")
    apVictoryWith("PLAYER_SHIP_ROCK")
    equals(sent, 1, "the second one triggers the declaration")
    check(shownKey("goal.reached"), "and the player sees it")

    apVictoryWith("PLAYER_SHIP_MANTIS")
    equals(sent, 1, "one more victory doesn't resend it")
    restore()
end)

test("seed: another seed wipes the previous one's checks, victories and goal", function()
    sim.startRun(true)
    apVictoriesResetForTesting()
    apForgetChecksForTesting()

    apApplySlotData({ contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
                      items = {}, loc = { ["a:1"] = "Location A" },
                      seed_hash = 111, goal = { kind = "victories", count = 1 } }, "Navigator")
    check(apSendCheck("a:1", "first seed"), "the first seed's check goes out")
    equals(apCheckCount().sent, 1, "it is counted")

    apApplySlotData({ contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
                      items = {}, loc = { ["a:1"] = "Location A" },
                      seed_hash = 222, goal = { kind = "victories", count = 1 } }, "Navigator")
    equals(apCheckCount().sent, 0, "the second seed starts from zero")
    check(apSendCheck("a:1", "second seed"), "and the same check goes out again for it")
end)

test("seed: items still queued don't carry into the next seed", function()
    sim.startRun(true)
    apFillerResetForTesting()
    apApplySlotData({ contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
                      items = {}, loc = {}, seed_hash = 444 }, "Navigator")
    apQueueItem({ kind = "filler", res = "scrap", n = 20 })
    apQueueItem({ kind = "filler", res = "fuel", n = 5 })
    equals(#_G.apFillerPendingForTesting(), 2, "two items are waiting")

    apApplySlotData({ contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
                      items = {}, loc = {}, seed_hash = 555 }, "Navigator")
    equals(#_G.apFillerPendingForTesting(), 0, "the next seed starts with an empty queue")
    check(sim.logged("queued item(s) dropped"), "and the log says so")
end)

test("seed: gifts sold under the previous seed become available again", function()
    sim.startRun(true)
    apShopGiftsConfigure(DEMO)
    apApplySlotData({ contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
                      items = {}, loc = {}, seed_hash = 666 }, "Navigator")
    sim.sign("AP_GIFT_1")
    sim.tick(60)

    sim.clearLog()
    apApplySlotData({ contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
                      items = {}, loc = {}, seed_hash = 777 }, "Navigator")
    check(sim.logged("gifts and deals become available again"),
          "the new seed starts with gifts available")
end)

test("seed: EVERYTHING belonging to a seed starts from zero with the next one", function()
    sim.startRun(true)
    apVictoriesResetForTesting()
    apForgetChecksForTesting()
    apFillerResetForTesting()
    apShopGiftsConfigure(DEMO)

    local seedA = { contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {},
                    loc = { ["a:1"] = "Location A" }, seed_hash = 888,
                    goal = { kind = "victories", count = 1 } }
    apApplySlotData(seedA, "Navigator")

    apSendCheck("a:1", "seed A")
    local restore = stub("apNetSendGoal", function() return true end)
    apVictoryWith("PLAYER_SHIP_HARD")
    restore()
    apQueueItem({ kind = "filler", res = "scrap", n = 20 })
    sim.sign("AP_GIFT_1")
    sim.tick(30)

    check(apCheckCount().sent > 0, "seed A did leave traces")

    local seedB = { contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {},
                    loc = { ["a:1"] = "Location A" }, seed_hash = 999,
                    goal = { kind = "victories", count = 1 } }
    sim.clearLog()
    apApplySlotData(seedB, "Navigator")

    equals(apCheckCount().sent, 0, "no inherited check")
    equals(apPendingCheckCount(), 0, "no inherited pending check")
    equals(#_G.apFillerPendingForTesting(), 0, "no inherited queued item")
    check(sim.logged("gifts and deals become available again"), "the gifts are given back")
    check(apSendCheck("a:1", "seed B"), "and the same check can go out again for seed B")

    local sent = 0
    restore = stub("apNetSendGoal", function() sent = sent + 1 return true end)
    apVictoryWith("PLAYER_SHIP_HARD")
    equals(sent, 1, "and its victory is declared")
    restore()
end)

test("seed: a mere reconnect wipes nothing, especially not offline checks", function()
    sim.startRun(true)
    apVictoriesResetForTesting()
    apForgetChecksForTesting()

    local seed = { contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, items = {},
                   loc = { ["a:1"] = "Location A", ["a:2"] = "Location B" }, seed_hash = 333 }
    apApplySlotData(seed, "Navigator")
    apSendCheck("a:1", "before the drop")
    local done = apCheckCount().sent

    apApplySlotData(seed, "Navigator")
    equals(apCheckCount().sent, done, "nothing is erased")

    apApplySlotData(seed, nil)
    equals(apCheckCount().sent, done, "a missing piece of information isn't a difference")
end)

test("goal: offline, the victory isn't announced as sent", function()
    sim.startRun(true)
    applySeed({ goal = { kind = "victories", count = 1 } })
    apVictoriesResetForTesting()
    local restore = stub("apNetSendGoal", function() return false end)

    apVictoryWith("PLAYER_SHIP_HARD")
    check(shownKey("goal.not_sent"), "it says the multiworld doesn't know yet")
    check(not shownKey("goal.reached"), "and especially not the opposite")
    restore()
end)

test("goal: what didn't go out is retried, and only once", function()
    sim.startRun(true)
    applySeed({ goal = { kind = "victories", count = 1 } })
    apVictoriesResetForTesting()

    local restore = stub("apNetSendGoal", function() return false end)
    apVictoryWith("PLAYER_SHIP_HARD")
    restore()

    local sent = 0
    restore = stub("apNetSendGoal", function() sent = sent + 1 return true end)
    check(apDeclareGoal() == true, "the connection returns, the goal goes out")
    equals(sent, 1, "once")
    check(apDeclareGoal() == true, "and a new call resends nothing")
    equals(sent, 1, "still once")
    restore()
end)

test("goal: reconnecting catches up on a victory earned offline", function()
    sim.startRun(true)
    apVictoriesResetForTesting()
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {}, loc = {}, goal = { kind = "victories", count = 1 },
    } })
    sim.tick(1)

    local restore = stub("apNetSendGoal", function() return false end)
    apVictoryWith("PLAYER_SHIP_HARD")
    restore()

    local sent = 0
    restore = stub("apNetSendGoal", function() sent = sent + 1 return true end)
    sim.netEvent("connected", { name = "Navigator", extra = {
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {},
        items = {}, loc = {}, goal = { kind = "victories", count = 1 },
    } })
    sim.tick(1)
    equals(sent, 1, "reconnecting declares the goal that was left pending")
    restore()
end)

test("goal: the same victory twice counts only once", function()
    sim.startRun(true)
    applySeed({ goal = { kind = "victories", count = 2 } })
    local sent = 0
    local restore = stub("apNetSendGoal", function() sent = sent + 1 end)
    apVictoryWith("PLAYER_SHIP_HARD")
    apVictoryWith("PLAYER_SHIP_HARD")
    equals(sent, 0, "winning twice with the same ship doesn't finish the seed")
    restore()
end)

test("goal: in selection mode, only the named layouts count", function()
    sim.startRun(true)
    applySeed({ goal = { kind = "victories", count = 2,
                         layouts = { "PLAYER_SHIP_STEALTH_2", "PLAYER_SHIP_CIRCLE_2" } } })
    local sent = 0
    local restore = stub("apNetSendGoal", function() sent = sent + 1 end)

    apVictoryWith("PLAYER_SHIP_HARD")
    apVictoryWith("PLAYER_SHIP_ROCK")
    equals(sent, 0, "two victories off the list don't count")

    apVictoryWith("PLAYER_SHIP_STEALTH_2")
    equals(sent, 0, "only one of the two targeted layouts")
    apVictoryWith("PLAYER_SHIP_CIRCLE_2")
    equals(sent, 1, "both: goal reached")
    restore()
end)

test("goal: an in-game victory goes through detection", function()
    sim.startRun(true)
    applySeed({ goal = { kind = "victories", count = 1 },
                loc = { ["PLAYER_SHIP_HARD:victory"] = "Kestrel Cruiser A: Defeat the Flagship" } })
    local sent = 0
    local restore = stub("apNetSendGoal", function() sent = sent + 1 end)

    apOnRunEnd("victory", "test")
    equals(sent, 1, "the goal was declared")
    restore()
end)

test("goal: offline, nothing is declared and nothing crashes", function()
    sim.startRun(true)
    local sent = 0
    local restore = stub("apNetSendGoal", function() sent = sent + 1 end)
    apVictoryWith("PLAYER_SHIP_HARD")
    equals(sent, 0, "with no seed, no goal to reach")
    equals(sim.errors, 0, "and no error")
    restore()
end)

local function playBranch(name)
    sim.gameEvent(name)
end

local function twoGifts()
    apShopGiftsConfigure({
        { location = "shop:1", slot = "Nina", item = "Progressive Shields",
          sphere = 1, kind = "progression", cost = 40 },
        { location = "shop:2", slot = "Axel", item = "20 Scrap",
          sphere = 2, kind = "filler", cost = 25 },
    })
end

test("event: the relay sends a package without making it payable in the shop", function()
    sim.startRun(true)
    _G.apShopSlotCount = 2
    twoGifts()
    apEventsResetForTesting()

    local sent = {}
    local restore = stub("apSendCheck", function(id) sent[#sent + 1] = id; return true end)
    playBranch("AP_EVT_PACKAGE_A")
    restore()

    equals(#sent, 1, "a check went out")
    equals(sent[1], "shop:1", "the one for the first unsold slot")
    check(sim.shown("Nina"), "the player sees who it went to")
end)

test("event: a gift already sent isn't shipped twice", function()
    sim.startRun(true)
    _G.apShopSlotCount = 2
    twoGifts()
    apEventsResetForTesting()

    local restore = stub("apSendCheck", function() return false end)
    playBranch("AP_EVT_PACKAGE_A")
    restore()

    local gift = apShopGiftPeekNext()
    check(gift ~= nil, "the gift is still there")
    equals(gift.location, "shop:1", "and it's indeed the same one")
end)

test("event: an empty shop says so, it doesn't fake it", function()
    sim.startRun(true)
    apShopGiftsConfigure({})
    apEventsResetForTesting()
    playBranch("AP_EVT_PACKAGE_A")
    check(shownKey("event.gift.nothing"), "the player is warned")
end)

test("event: the Zoltan tithe pays into the shared pool", function()
    sim.startRun(true)
    apEventsResetForTesting()
    local deposited = 0
    local restore = stub("apEnergyLinkDeposit", function(joules) deposited = deposited + joules end)
    playBranch("AP_EVT_ZOLTAN_TITHE_A")
    restore()
    check(deposited > 0, "energy went out to others (" .. deposited .. " J)")
end)

test("event: the toll draws from the shared pool", function()
    sim.startRun(true)
    apEventsResetForTesting()
    local asked = 0
    local restore = stub("apEnergyLinkRequestFuel", function(units) asked = units; return true end)
    playBranch("AP_EVT_ZOLTAN_TITHE_B")
    restore()
    check(asked > 0, "fuel was requested from the pool")
    check(not shownKey("event.link.empty"), "and the player is not told the pool is empty before it answers")
end)

test("event: an empty pool doesn't lie to the player", function()
    sim.startRun(true)
    apEventsResetForTesting()
    local restore = stub("apEnergyLinkRequestFuel", function() return false end)
    playBranch("AP_EVT_ZOLTAN_TITHE_B")
    restore()
    check(shownKey("event.link.empty"), "the player knows the pool was empty")
end)

test("event: jamming the signal sends a trap to others", function()
    sim.startRun(true)
    apEventsResetForTesting()
    local sent = 0
    local restore = stub("apNetSendTrap", function() sent = sent + 1 end)
    playBranch("AP_EVT_ANOTHER_WORLD_B")
    restore()
    equals(sent, 1, "a trap went out to the multiworld")
end)

test("event: offline, the power surge doesn't pretend it hit someone", function()
    sim.startRun(true)
    apEventsResetForTesting()
    local restore = stub("apNetSendTrap", function() return false end)
    sim.clearLog()
    playBranch("AP_EVT_ANOTHER_WORLD_B")
    restore()
    check(shownKey("event.trap.nobody"), "it says the surge dies at the relay")
    check(not shownKey("event.trap.sent"), "and especially not that it hit someone")
end)

test("event: the Zoltan tithe is the ONLY event that touches the shared pool", function()
    sim.startRun(true)

    for branch in pairs(_G.apEventBranchEffects) do
        if branch ~= "AP_EVT_ZOLTAN_TITHE_A" and branch ~= "AP_EVT_ZOLTAN_TITHE_B" then
            apEventsResetForTesting()
            local paid, drawn = 0, 0
            local rd = stub("apEnergyLinkDeposit", function(j) paid = paid + j end)
            local rp = stub("apEnergyLinkRequestFuel", function() drawn = drawn + 1; return 0 end)
            playBranch(branch)
            rp()
            rd()
            equals(paid, 0, branch .. " doesn't pay anything into the shared pool")
            equals(drawn, 0, branch .. " doesn't draw from it either")
        end
    end

    apEventsResetForTesting()
    local zoltan = 0
    local restore = stub("apEnergyLinkDeposit", function(joules) zoltan = zoltan + joules end)
    playBranch("AP_EVT_ZOLTAN_TITHE_A")
    restore()
    check(zoltan > 0, "and the Zoltan tithe, though, does pay (" .. zoltan .. " J)")
end)

test("event: absorbing the power surge doesn't touch the multiworld at all", function()
    sim.startRun(true)
    _G.apShopSlotCount = 2
    twoGifts()
    apEventsResetForTesting()

    local sent, deposited, traps = 0, 0, 0
    local restoreCheck = stub("apSendCheck", function() sent = sent + 1; return true end)
    local restoreLink = stub("apEnergyLinkDeposit", function(j) deposited = deposited + j end)
    local restoreTrap = stub("apNetSendTrap", function() traps = traps + 1; return true end)
    playBranch("AP_EVT_ANOTHER_WORLD_A")
    restoreTrap()
    restoreLink()
    restoreCheck()

    equals(sent, 0, "no check: that's no longer this event's job")
    equals(deposited, 0, "no energy either")
    equals(traps, 0, "and the trap is the OTHER branch's job")
    check(_G.apEventBranchEffects["AP_EVT_ANOTHER_WORLD_A"] == nil,
        "the branch has no Lua effect at all anymore: everything happens on the XML side")
end)

test("event: the relay names both packages in its two responses", function()
    sim.startRun(true)
    _G.apShopSlotCount = 2
    twoGifts()

    local box = sim.openChoiceBox("AP_EVT_PACKAGE")

    check(box.choices[1].text:find("Nina", 1, true) ~= nil,
        "the first response names the recipient: " .. box.choices[1].text)
    check(box.choices[1].text:find("Progressive Shields", 1, true) ~= nil,
        "and what's inside")
    check(box.choices[2].text:find("Axel", 1, true) ~= nil,
        "the second names the other one: " .. box.choices[2].text)
end)

test("event: each relay response ships THE package it announces", function()
    sim.startRun(true)
    _G.apShopSlotCount = 2
    twoGifts()
    sim.openChoiceBox("AP_EVT_PACKAGE")
    apEventsResetForTesting()

    local sent = {}
    local restore = stub("apSendCheck", function(key) sent[#sent + 1] = key; return true end)
    playBranch("AP_EVT_PACKAGE_B")
    restore()

    equals(#sent, 1, "a single check went out")
    equals(sent[1], "shop:2", "and it's the one for the SECOND response, not the first in queue")

    sim.startRun(true)
    _G.apShopSlotCount = 2
    twoGifts()
    sim.openChoiceBox("AP_EVT_PACKAGE")
    apEventsResetForTesting()

    sent = {}
    restore = stub("apSendCheck", function(key) sent[#sent + 1] = key; return true end)
    playBranch("AP_EVT_PACKAGE_A")
    restore()

    equals(sent[1], "shop:1", "the first response ships the first package")
end)

test("event: with no package to name, the relay still ships what it can", function()
    sim.startRun(true)
    _G.apShopSlotCount = 1
    apShopGiftsConfigure({
        { location = "shop:1", slot = "Nina", item = "Progressive Shields",
          sphere = 1, kind = "progression", cost = 40 },
    })
    sim.openChoiceBox("AP_EVT_PACKAGE")
    apEventsResetForTesting()

    local sent = {}
    local restore = stub("apSendCheck", function(key) sent[#sent + 1] = key; return true end)
    playBranch("AP_EVT_PACKAGE_B")
    restore()

    equals(#sent, 1, "the only available package still goes out")
    equals(sent[1], "shop:1", "and that's the one")
end)

test("event: offline, nothing crashes and everything gets logged", function()
    sim.startRun(true)
    apShopGiftsConfigure({})
    apEventsResetForTesting()

    local restoreTrap = stub("apNetSendTrap", nil)
    local restoreFuel = stub("apEnergyLinkRequestFuel", nil)
    local restoreDeposit = stub("apEnergyLinkDeposit", nil)
    for branch in pairs(_G.apEventBranchEffects) do
        playBranch(branch)
    end
    restoreDeposit()
    restoreFuel()
    restoreTrap()

    equals(sim.errors, 0, "no error reported to the engine")
    check(#_G.apEventLog > 0, "and every branch left a trace in the log")
end)

test("event: every wired branch carries a branch name from the XML", function()
    local count = 0
    for branch, effect in pairs(_G.apEventBranchEffects) do
        check(type(effect) == "function", branch .. " has an effect")
        check(branch:match("^AP_EVT_[A-Z_]+_[AB]$") ~= nil,
              branch .. " follows the form AP_EVT_<name>_<A|B>")
        count = count + 1
    end
    check(count >= 6, "at least six branches have an Archipelago effect (" .. count .. ")")
end)

test("TrapLink off broadcasts nothing", function()
    _G.apTrapLink.enabled = false
    sim.startRun(true)
    local sent = 0
    _G.apNetSendTrap = function() sent = sent + 1 end
    apQueueItem({ kind = "trap", eff = "fire" })
    drain()
    equals(sent, 0, "no broadcast")
    _G.apNetSendTrap = nil
end)

test("a trap received from our seed is broadcast to others", function()
    _G.apTrapLink.enabled = true
    sim.startRun(true)
    local sent = {}
    _G.apNetSendTrap = function(name) sent[#sent + 1] = name end
    apQueueItem({ kind = "trap", eff = "fire", display = "Fire Trap" })
    drain()
    equals(#sent, 1, "the trap goes out to the multiworld")
    equals(sent[1], "Fire Trap", "under its Archipelago name")
    _G.apNetSendTrap = nil
end)

test("a trap coming from the link is NOT rebroadcast", function()
    _G.apTrapLink.enabled = true
    sim.startRun(true)
    local sent = 0
    _G.apNetSendTrap = function() sent = sent + 1 end
    apTrapLinkReceive("Berserker", "Fire Trap")
    drain()
    equals(sent, 0, "nothing goes back out")
    check(#sim.player._fires > 0, "but the trap was indeed applied")
    _G.apNetSendTrap = nil
end)

test("a foreign trap's name is translated by keywords", function()
    equals(apTrapLinkTranslate("Ice Trap"), "system_damage", "'Ice', the project's classic")
    equals(apTrapLinkTranslate("Fire Trap"), "fire", "'Fire' starts a fire")
    equals(apTrapLinkTranslate("Hull Breach Trap"), "breach", "'Breach' wins over 'Hull'")
    equals(apTrapLinkTranslate("Damage Trap"), "hull_damage", "'Damage' damages the hull")
    equals(apTrapLinkTranslate("Gas Trap"), "fuel_leak", "'Gas' leaks fuel")
    equals(apTrapLinkTranslate("Explosion Trap"), "hull_damage", "'Explosion' is not 'ion'")
    equals(apTrapLinkTranslate("Confusion Trap"), "system_damage", "neither is 'Confusion'")
end)

test("a trap whose name says nothing still produces an effect", function()
    local effect = apTrapLinkTranslate("Banana Peel Of Doom")
    local known = false
    for _, name in ipairs({ "fire", "breach", "fuel_leak", "system_damage", "fleet_advance", "hull_damage" }) do
        if effect == name then known = true end
    end
    check(known, "the fallback picks one of our traps (got: " .. tostring(effect) .. ")")
end)

test("TrapLink does apply others' traps", function()
    _G.apTrapLink.enabled = true
    sim.startRun(true)
    apTrapLinkReceive("Berserker", "Hull Breach Trap")
    drain()
    check(sim.player._breaches > 0, "the requested breach opened")
end)

local function slotData(overrides)
    local base = {
        contract = 1,
        kinds = { "ship", "cap", "start", "filler" },
        kinds_required = { "ship", "cap" },
        items = {
            ["Rock Cruiser Key"] = { k = "ship", bp = "PLAYER_SHIP_ROCK" },
            ["20 Scrap"] = { k = "filler", res = "scrap", n = 20 },
            ["Halberd Beam"] = { k = "shop", bp = "BEAM_2" },
        },
        shop = { mode = "rarity_boost", deliver = false, baseline = {} },
        links = {
            death = { enabled = false, trigger = "run_lost", effect = "crew_member" },
            energy = { enabled = false },
            trap = { enabled = false },
        },
    }
    for key, value in pairs(overrides or {}) do
        base[key] = value
    end
    return base
end

test("a compliant seed is accepted", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    check(apApplySlotData(slotData()), "the seed is playable")
    equals(_G.apContractState.refusal, nil, "no refusal")
end)

test("a check absent from the seed is neither announced nor sent", function()
    sim.startRun(true)
    connectNow()
    apApplySlotData(slotData({ loc = { ["sector:2"] = "Sector 2" } }))
    sim.clearLog()

    check(not apSendCheck("sector:7"), "the mod refuses a check the seed doesn't contain")
    check(not sim.shown("sector:7"), "and announces nothing to the player")

    check(apSendCheck("sector:2"), "the one in the seed goes out normally")
    apNotifyFlushForTesting()
    check(sim.shown("Sector 2"), "and is announced under its Archipelago name")
end)

local function connectOnSeed(fingerprint)
    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = slotData({
        seed_hash = fingerprint,
        items = {
            ["20 Scrap"] = { k = "filler", res = "scrap", n = 20 },
            ["Progressive Shields"] = { k = "cap", sys = "shields", n = 1 },
        },
    }) })
    sim.tick(1)
end

test("an item replayed on launch is applied without announcing anything", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.startRun(true)
    connectOnSeed("CCC")
    sim.netEvent("item", { name = "Progressive Shields", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()

    apNetResetForTesting()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    connectOnSeed("CCC")
    sim.clearLog()
    sim.netEvent("item", { name = "Progressive Shields", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()

    equals((_G.apInventory.systemCaps or {}).shields, 2, "the cap is indeed rebuilt")
    check(not sim.shown("Progressive Shields"),
        "but the player doesn't see the announcement again on every launch")

    sim.netEvent("item", { name = "Progressive Shields", sender = "Nina", index = 1 })
    sim.tick(1)
    drain()
    check(sim.shown("Progressive Shields"), "a genuinely new item, though, is announced")
end)

test("a resource received at the menu isn't lost if the game closes before delivery", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.started = false
    connectOnSeed("DDD")
    sim.netEvent("item", { name = "20 Scrap", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()

    apNetResetForTesting()
    apFillerResetForTesting()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.startRun(true)
    connectOnSeed("DDD")
    local before = sim.player.currentScrap
    sim.netEvent("item", { name = "20 Scrap", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()

    equals(sim.player.currentScrap, before + 20,
        "never delivered, so never consumed: it comes back in the next session")
end)

test("resources already received don't come back on the next launch", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.startRun(true)
    connectOnSeed("AAA")
    sim.netEvent("item", { name = "20 Scrap", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()
    local scrap = sim.player.currentScrap

    apNetResetForTesting()
    connectOnSeed("AAA")
    sim.netEvent("item", { name = "20 Scrap", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()

    equals(sim.player.currentScrap, scrap,
        "the server replays everything, but the scrap is only given once")
end)

test("a cap, though, reapplies on every launch", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.startRun(true)
    connectOnSeed("BBB")
    sim.netEvent("item", { name = "Progressive Shields", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()

    apNetResetForTesting()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    connectOnSeed("BBB")
    sim.netEvent("item", { name = "Progressive Shields", sender = "Nina", index = 0 })
    sim.tick(1)
    drain()

    equals((_G.apInventory.systemCaps or {}).shields, 2,
        "the cap is rebuilt from history, otherwise it would be lost")
end)

test("changing seed with unlocked ships on the profile cuts the connection and asks the question", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.unlocked = { PLAYER_SHIP_MANTIS = true }
    sim.durable["ap_seed_tag"] = "4242"
    _G.apNetState.connected = true
    sim.clearLog()

    local accepted = apApplySlotData(slotData({ seed_hash = "UNE_AUTRE" }))

    equals(accepted, false, "the seed isn't applied")
    check(apSeedChangeLeftovers(), "the question is asked to the player")
    check(sim.netCalls("Disconnect") > 0, "and the mod disconnects instead of playing the seed")
    sim.durable["ap_seed_tag"] = nil
    sim.unlocked = {}
    apSeedChangeAcknowledged()
end)

test("a non-empty profile with no known seed also asks the question", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.durable = {}
    sim.unlocked = { PLAYER_SHIP_MANTIS = true }
    _G.apNetState.connected = true
    sim.clearLog()

    equals(apApplySlotData(slotData({ seed_hash = "FIRST" })), false,
        "first seed on an already-played profile: refused")
    check(apSeedChangeLeftovers(), "the question is asked")
    equals(apSeedChangeReason(), "foreign",
        "and it states the real reason: these ships didn't come from Archipelago")

    sim.unlocked = {}
    apSeedChangeAcknowledged()
end)

test("answering no records the seed: the question doesn't come back", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.durable = {}
    sim.unlocked = { PLAYER_SHIP_MANTIS = true }
    _G.apNetState.connected = true

    equals(apApplySlotData(slotData({ seed_hash = "FIRST" })), false, "refused once")
    local fingerprint = apSeedChangeFingerprint()
    check(fingerprint ~= nil and fingerprint ~= 0, "the mod remembers the refused fingerprint")

    apNetRememberSeed(fingerprint)
    apSeedChangeAcknowledged()

    _G.apNetState.connected = true
    check(apApplySlotData(slotData({ seed_hash = "FIRST" })) ~= false,
        "on the next launch the same seed goes through, the player has decided")
    check(not apSeedChangeLeftovers(), "and no more question")

    sim.unlocked = {}
    sim.durable = {}
end)

test("a refused seed doesn't record its fingerprint", function()
    apNetResetForTesting()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.durable = {}
    sim.unlocked = { PLAYER_SHIP_MANTIS = true }

    apNetConnect("ws://localhost:38281", "Navigator", "")
    sim.netEvent("connected", { name = "Navigator", extra = slotData({ seed_hash = "AAA" }) })
    sim.tick(1)

    equals(sim.durable["ap_seed_tag"], nil,
        "otherwise the next launch would think the seed is settled and would ask nothing")

    sim.unlocked = {}
    sim.durable = {}
    apNetResetForTesting()
    apSeedChangeAcknowledged()
end)

test("changing seed with a blank profile bothers no one", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.unlocked = { PLAYER_SHIP_HARD = true }
    sim.durable["ap_seed_tag"] = "4242"
    _G.apNetState.connected = true

    check(apApplySlotData(slotData({ seed_hash = "ENCORE_UNE" })) ~= false,
        "the Kestrel is still there: it's not progress to lose")
    check(not apSeedChangeLeftovers(), "and no question")
    sim.durable["ap_seed_tag"] = nil
end)

test("the seed fingerprint survives an abrupt game close", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.durable = {}
    sim.meta = {}
    connectOnSeed("AAA")
    local written = sim.durable["ap_seed_tag"]
    check(written ~= nil and written ~= "0",
        "the fingerprint goes into the network module's memory, not just the FTL profile")

    sim.meta = {}
    apNetResetForTesting()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.unlocked = { PLAYER_SHIP_MANTIS = true }
    _G.apNetState.connected = true

    check(apApplySlotData(slotData({ seed_hash = "UNE_AUTRE" })) == false,
        "on the next launch the foreign seed is refused, whether the FTL profile is empty or not")
    check(apSeedChangeLeftovers(), "and the question is asked")
    sim.unlocked = {}
    sim.durable = {}
    apSeedChangeAcknowledged()
end)

test("with no durable memory the mod falls back to the FTL profile", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    sim.durable = {}
    sim.net.durableMemory = false
    apNetResetForTesting()
    sim.unlocked = { PLAYER_SHIP_MANTIS = true }
    Hyperspace.metaVariables["ap_seed_tag"] = 4242
    _G.apNetState.connected = true

    check(apApplySlotData(slotData({ seed_hash = "UNE_AUTRE" })) == false,
        "an old Hyperspace still keeps the protection, less reliably")
    check(apSeedChangeLeftovers(), "and the question is asked anyway")
    Hyperspace.metaVariables["ap_seed_tag"] = 0
    sim.unlocked = {}
    sim.net.durableMemory = true
    apNetResetForTesting()
    apSeedChangeAcknowledged()
end)

test("a seed from a too-recent contract is REFUSED", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    check(not apApplySlotData(slotData({ contract = 99 })), "the seed is refused")
    check(sim.logged("SEED REFUSED"), "and the refusal is logged")
    check(shownKey("contract.refused"), "and shown to the player")
    check(sim.logged("update the mod"), "with what to do, in the player's language")
end)

test("a seed from a too-old contract is REFUSED", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    check(not apApplySlotData(slotData({ contract = 0 })), "the seed is refused")
    check(sim.logged("regenerate the seed"), "with what to do, in the player's language")
end)

test("a required kind that isn't implemented makes the seed REFUSED", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    check(not apApplySlotData(slotData({ kinds_required = { "ship", "telepathy" } })),
        "the seed is refused")
    check(sim.logged("telepathy"), "and the offending kind is named")
end)

test("a kind carried only by filler only warns", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    check(apApplySlotData(slotData({ kinds = { "ship", "confetti" } })), "the seed stays playable")
    check(sim.logged("WARNING"), "but the warning is there")
    check(shownKey("contract.partial"), "and the player is warned")
end)

test("unreadable slot_data is refused rather than half-applied", function()
    check(not apApplySlotData(nil), "nil is refused")
    check(not apApplySlotData({ kinds = {} }), "with no contract number, also refused")
end)

test("slot_data really configures all three links", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplySlotData(slotData({
        links = {
            death = { enabled = true, trigger = "any_crew_death", effect = "fire" },
            energy = { enabled = true },
            trap = { enabled = true },
        },
    }))
    equals(_G.apDeathLink.enabled, true, "DeathLink on")
    equals(_G.apDeathLink.trigger, "any_crew_death", "with its trigger")
    equals(_G.apDeathLink.effect, "fire", "and its effect")
    equals(_G.apEnergyLink.enabled, true, "EnergyLink on")
    equals(_G.apTrapLink.enabled, true, "TrapLink on")
end)

test("slot_data does lock shops before any item", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplySlotData(slotData({
        shop = { mode = "locked", deliver = false, baseline = { "BEAM_2" } },
    }))
    equals(sim.rarityFor("BEAM_2", 4).rarity, 0, "the object is removed from shops")
end)

test("a received item is translated into a game action", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplySlotData(slotData())
    sim.startRun(true)
    check(apReceiveItem("20 Scrap", "Berserker"), "the item is accepted")
    drain()
    equals(sim.player.currentScrap, 20, "and applied")
end)

test("an item without a descriptor is counted, not swallowed", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplySlotData(slotData())
    sim.startRun(true)
    check(not apReceiveItem("An Item That Does Not Exist", "Berserker"), "it is refused")
    equals(_G.apContractState.unknownItems, 1, "and counted")
    check(sim.logged("without descriptor"), "and logged")
end)

test("an item this mod doesn't know how to deliver says so, instead of counting it silently", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplySlotData({
        contract = CONTRACT, kinds = { "filler" }, kinds_required = {}, loc = {},
        items = { ["Future Thing"] = { k = "a_future_kind", n = 1 } },
    })
    sim.startRun(true)
    sim.clearLog()

    check(not apReceiveItem("Future Thing", "Berserker"), "the item is refused")
    equals(_G.apContractState.unknownKinds["a_future_kind"], 1, "and counted")
    check(shownKey("item.unknown", { name = "Future Thing" }),
        "the player reads the Archipelago name of what they just lost")
    check(not sim.shown("a_future_kind"), "and not the technical kind")

    sim.clearLog()
    check(not apReceiveItem("An Item That Does Not Exist", "Nina"), "same thing with no descriptor")
    check(shownKey("item.unknown", { name = "An Item That Does Not Exist" }), "and they read that too")
end)

test("the anomaly counter is shown back at the menu", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplySlotData(slotData())
    apReceiveItem("Unknown", nil)
    sim.clearLog()
    sim.mainMenu()
    check(sim.logged("without descriptor"), "the player sees it at the menu, not never")
end)

test("the mod thinks in keys, the protocol in names", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplySlotData({
        contract = 1, kinds = {}, kinds_required = {}, items = {},
        loc = {
            ["shop:1"] = "Archipelago Shop 1",
            ["PLAYER_SHIP_HARD:sector:3"] = "Kestrel Cruiser A: Reach sector 3",
        },
        shop = { mode = "rarity_boost", deliver = false, baseline = {}, slots = 1 },
        links = {},
    })
    equals(apLocationNameFor("shop:1"), "Archipelago Shop 1", "key -> name")
    equals(apCheckKeyFor("Archipelago Shop 1"), "shop:1", "name -> key")
    equals(apLocationNameFor("shop:99"), nil,
        "a location absent from the seed has no name, and that's expected")
end)

test("a check goes out over the network under its Archipelago name", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    apApplySlotData({
        contract = 1, kinds = {}, kinds_required = {}, items = {},
        loc = { ["shop:1"] = "Archipelago Shop 1" },
        shop = { mode = "rarity_boost", deliver = false, baseline = {}, slots = 1 },
        links = {},
    })
    local sent = {}
    local restore = stub("apNetSendCheck", function(name) sent[#sent + 1] = name end)

    apSendCheck("shop:1")
    equals(#sent, 1, "one send")
    equals(sent[1], "Archipelago Shop 1", "under the name the server knows")

    apSendCheck("shop:1")
    equals(#sent, 1, "and never twice")
    restore()
end)

test("the panel is closed by default", function()
    sim.startRun(true)
    sim.renderGui()
    equals(#sim.drawn, 0, "nothing is drawn until it's opened")
end)

test("TAB opens and closes the panel", function()
    sim.startRun(true)
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.renderGui()
    check(sim.drawnText("ARCHIPELAGO"), "open on the first press")

    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.renderGui()
    equals(#sim.drawn, 0, "closed on the second")
end)

local function systemNamed(name)
    for i = 0, sim.player.vSystemList:size() - 1 do
        if sim.player.vSystemList[i].name == name then
            return sim.player.vSystemList[i]
        end
    end
    return nil
end

test("cap: a system with no item stays stuck at level 1", function()
    sim.startRun(true)
    _G.apInventory.systemCaps.shields = nil
    local shields = systemNamed("shields")
    shields.powerState.second = 1
    apSystemsForgetStartingPower()

    apApplySystemRules()
    equals(shields.maxLevel, 1, "shields are stuck at level 1")
end)

test("cap: each received item raises the cap by one notch", function()
    sim.startRun(true)
    local shields = systemNamed("shields")
    shields.powerState.second = 1
    apSystemsForgetStartingPower()

    for expected = 1, 4 do
        _G.apInventory.systemCaps.shields = expected
        apApplySystemRules()
        equals(shields.maxLevel, expected, "cap " .. expected)
    end
end)

test("cap: the FIRST item counts, even on a system that starts above 1", function()
    sim.startRun(true)
    apInventoryClear()
    local shields = systemNamed("shields")
    shields.powerState.second = 2
    apSystemsForgetStartingPower()
    apApplySystemRules()
    equals(shields.maxLevel, 2, "with no item, the ship keeps what it had")

    apInventoryAdd({ kind = "cap", sys = "shields", n = 1 })
    apApplySystemRules()
    equals(shields.maxLevel, 3, "the FIRST item gives one MORE notch, not the same one")

    apInventoryAdd({ kind = "cap", sys = "shields", n = 1 })
    apApplySystemRules()
    equals(shields.maxLevel, 4, "and the next one another")
end)

test("cap: a starting bonus opens its own notch, otherwise it's inert", function()
    sim.startRun(true)
    apInventoryClear()
    local engines = systemNamed("engines")
    engines.powerState.second = 2
    apSystemsForgetStartingPower()
    apApplySystemRules()
    equals(engines.maxLevel, 2, "with nothing, the cap equals what the ship had")

    apInventoryAdd({ kind = "start", sys = "engines", n = 1 })
    apApplySystemRules()
    equals(engines.maxLevel, 3, "the cap opens by one notch so the bonus can fit")
end)

test("cap: the game's maximum is never exceeded", function()
    sim.startRun(true)
    local shields = systemNamed("shields")
    shields.powerState.second = 1
    _G.apInventory.systemCaps.shields = 99

    apApplySystemRules()
    check(shields.maxLevel <= 8, "the game's maximum holds (" .. shields.maxLevel .. ")")
end)

test("cap: a starting bonus opens the notches it needs", function()
    sim.startRun(false)
    _G.apInventory.systemCaps.shields = 1
    _G.apInventory.startingUpgrades.shields = 3

    local shields
    for i = 0, sim.player.vSystemList:size() - 1 do
        if sim.player.vSystemList[i].name == "shields" then
            shields = sim.player.vSystemList[i]
        end
    end
    check(shields ~= nil, "the ship has shields")
    shields.powerState.second = 1

    apSystemsForgetStartingPower()
    sim.startRun(true)
    equals(shields.powerState.second, 4,
           "the three granted levels are applied: 1 starting + 3")
end)

test("cap: the same bonus applies as soon as the cap rises", function()
    sim.startRun(false)
    _G.apInventory.systemCaps.shields = 4
    _G.apInventory.startingUpgrades.shields = 2

    local shields
    for i = 0, sim.player.vSystemList:size() - 1 do
        if sim.player.vSystemList[i].name == "shields" then
            shields = sim.player.vSystemList[i]
        end
    end
    shields.powerState.second = 1

    sim.startRun(true)
    check(shields.powerState.second > 1,
          "the bonus is applied (" .. shields.powerState.second .. ")")
    check(shields.powerState.second <= 4, "without exceeding the cap")
end)

test("cap: a cap never drops below the level already reached", function()
    sim.startRun(true)
    local shields
    for i = 0, sim.player.vSystemList:size() - 1 do
        if sim.player.vSystemList[i].name == "shields" then
            shields = sim.player.vSystemList[i]
        end
    end
    shields.powerState.second = 4
    _G.apInventory.systemCaps.shields = 1

    apApplySystemRules()
    check(shields.maxLevel >= 4, "the cap stays at the level reached (" .. shields.maxLevel .. ")")
end)

test("the panel shows what the player has earned", function()
    _G.apInventory = {
        ships = { "PLAYER_SHIP_ROCK", "PLAYER_SHIP_MANTIS" },
        systemCaps = { shields = 3, cloaking = 1 },
        startingUpgrades = { shields = 2, reactor = 4 },
        shopAvailability = {},
    }
    sim.startRun(true)
    sim.keyDown(Defines.SDL.KEY_TAB)
    apDashboardPage("ships")
    sim.renderGui()
    check(sim.drawnText("Ship layouts unlocked: 2 of 28"), "the ships")

    apDashboardPage("systems")
    sim.renderGui()
    local function numbersAfter(name)
        for index, line in ipairs(sim.drawn) do
            if line == name then return sim.drawn[index + 1] end
        end
        return nil
    end

    equals(numbersAfter("Shields"), "2 upgrades received",
          "a cap of 3 means two upgrades received: level 1 is the game's own")
    equals(numbersAfter("Cloaking"), "0 upgrades received",
          "and never the ship's level, which is already visible on the ship screen")
    check(not sim.drawnText("4/8") and not sim.drawnText("level 4"),
          "especially not the game's cap or the level, that's what used to read wrong")
    check(not sim.drawnText("shields") and not sim.drawnText("cloaking"),
          "and no blueprint id in the list")
    check(sim.drawnText("+2 at start"), "the starting bonus sits on its system")
    check(sim.drawnText("Reactor +4 at start"), "and the energy granted at the start")
    sim.keyDown(Defines.SDL.KEY_TAB)
end)

test("the energy granted at startup is really applied to the reactor", function()
    _G.apInventory = {
        ships = {}, systemCaps = { shields = 3 },
        startingUpgrades = { shields = 2, reactor = 4 }, shopAvailability = {},
    }
    sim.startRun(true)

    equals(sim.powerManager.currentPower.second, 8 + 4,
        "the four granted bars are added to the reactor's maximum")
    check(sim.logged("reactor: +4"), "and the log says so")
end)

test("loading a save doesn't regrant the starting energy", function()
    _G.apInventory = {
        ships = {}, systemCaps = {}, startingUpgrades = { reactor = 4 }, shopAvailability = {},
    }
    sim.startRun(false)

    equals(sim.powerManager.currentPower.second, 8, "the reactor hasn't moved")
end)

test("the panel also shows what stays LOCKED", function()
    _G.apInventory = {
        ships = {}, systemCaps = { shields = 1 }, startingUpgrades = {}, shopAvailability = {},
    }
    sim.startRun(true)
    sim.keyDown(Defines.SDL.KEY_TAB)
    apDashboardPage("systems")
    sim.renderGui()

    check(sim.drawnText("Systems: 1 of 16 unlocked"), "the count is shown")
    check(sim.drawnText("Cloaking"), "a locked system is still listed")
    check(sim.drawnText("Locked"), "and marked locked")
    check(not sim.drawnText("Cloaking 1/3"), "but with no cap: there's nothing to say about it")
    sim.keyDown(Defines.SDL.KEY_TAB)
end)

test("the panel shows WHERE the goal stands, not just what it asks for", function()
    sim.startRun(true)
    apVictoriesResetForTesting()
    applySeed({ goal = { kind = "victories", count = 3 } })
    apToggleHud()
    sim.renderGui()
    check(sim.drawnText("defeat the Flagship 3 times"), "with no victory yet, what to do")
    apToggleHud()

    local restore = stub("apNetSendGoal", function() return true end)
    apVictoryWith("PLAYER_SHIP_HARD")
    apVictoryWith("PLAYER_SHIP_ROCK")
    restore()
    apToggleHud()
    sim.renderGui()
    check(sim.drawnText("2 of 3"), "then two out of three")
    check(not sim.drawnText("Goal reached"), "and it's not reached yet")
    apToggleHud()
end)

test("the panel says when the goal is reached", function()
    sim.startRun(true)
    apVictoriesResetForTesting()
    applySeed({ goal = { kind = "victories", count = 1 } })
    local restore = stub("apNetSendGoal", function() return true end)
    apVictoryWith("PLAYER_SHIP_HARD")
    restore()

    apToggleHud()
    sim.renderGui()
    check(sim.drawnText("Goal reached"), "the panel announces the goal reached")
    check(sim.drawnText("Goal reached: Flagship defeated"), "in the singular, since only one was needed")
    apToggleHud()
end)

test("the panel says what it shows isn't a run, as long as there's no seed",
function()
    apContractResetForTesting()
    sim.startRun(true)
    apToggleHud()
    sim.renderGui()

    check(sim.drawnText("No seed loaded"), "the panel says no seed is loaded")
    check(sim.drawnText("local profile"), "and that what follows is the local profile")
    check(not sim.drawnText("0 / 0"), "no zero-over-zero ratio")
    apToggleHud()
end)

test("the panel says plainly there's nothing yet", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    sim.startRun(true)
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.renderGui()
    check(sim.drawnText(apT("dash.plus", { n = 0 })), "nothing is granted at the start, and it's stated")
    apDashboardPage("systems")
    sim.renderGui()
    check(sim.drawnText("Systems: 0 of 16 unlocked"), "the count is zero, and it's stated")
    sim.keyDown(Defines.SDL.KEY_TAB)
end)

test("the check counter only counts THIS seed's locations", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    apApplySlotData({
        contract = 1, kinds = {}, kinds_required = {}, items = {},
        loc = { ["shop:1"] = "Archipelago Shop 1", ["shop:2"] = "Archipelago Shop 2" },
        shop = { mode = "rarity_boost", deliver = false, baseline = {}, slots = 2 },
        links = {},
    })
    local count = apCheckCount()
    equals(count.total, 2, "two locations in this seed")
    equals(count.sent, 0, "none sent")

    apSendCheck("shop:1")
    equals(apCheckCount().sent, 1, "one sent")
end)

test("the main menu says what to do as long as no run is loaded", function()
    apContractResetForTesting()
    sim.renderMenu()
    check(sim.drawnText(apT("connect.title")), "the connection form is there")
    check(sim.drawnText(apT("connect.button")), "with its button")
    check(sim.drawnText("TAB"), "and the keys are named")
    check(sim.drawnText(apT("connect.solo")), "and the solo mode button, to play without a server")
end)

test("connection panel: no text can overflow, whatever the language", function()
    apContractResetForTesting()
    sim.renderMenu()
    local texts = { apT("connect.title"), apT("connect.button"), apT("connect.keys"),
                     apT("connect.solo") }
    for _, field in ipairs({ "connect.field.address", "connect.field.port",
                             "connect.field.slot", "connect.field.password" }) do
        texts[#texts + 1] = apT(field)
    end
    for _, expected in ipairs(texts) do
        local found = nil
        for _, draw in ipairs(sim.draws) do
            if draw.text == expected then found = draw end
        end
        check(found ~= nil, expected .. " is drawn")
        if found then
            check(found.maxWidth ~= nil and found.maxWidth > 0,
                expected .. " has a maximum width, so it shrinks instead of overflowing")
            check(found.x + (found.maxWidth or 0) <= 24 + 372,
                expected .. " stays inside the panel")
        end
    end
end)

test("a single item received reads as one upgrade, not two", function()
    _G.apInventory = { ships = {}, shopAvailability = {}, systemCaps = {}, startingUpgrades = {} }
    applySeed({ items = { ["Progressive Door System"] = { k = "cap", sys = "doors", n = 1 } } })
    sim.startRun(true)
    apQueueItem({ kind = "cap", sys = "doors", n = 1, display = "Progressive Door System" })
    drain()

    apToggleHud()
    apDashboardPage("systems")
    sim.renderGui()
    local detail = nil
    for index, line in ipairs(sim.drawn) do
        if line == "Door System" then detail = sim.drawn[index + 1] end
    end
    equals(detail, "1 upgrade received",
        "the internal cap is 2, but the player only received one item")
    apToggleHud()
end)

test("an incomplete system is never announced as finished", function()
    _G.apInventory = {
        ships = {}, systemCaps = { shields = 3 }, startingUpgrades = {}, shopAvailability = {},
    }
    applySeed({ caps = { shields = 6 } })
    sim.startRun(true)
    apToggleHud()
    apDashboardPage("systems")
    sim.renderGui()

    local detail = nil
    for index, line in ipairs(sim.drawn) do
        if line == "Shields" then detail = sim.drawn[index + 1] end
    end
    check(detail ~= nil and detail:find("2/6", 1, true),
        "two upgrades out of the seed's six, and it's stated")
    check(not (detail or ""):find("all upgrades", 1, true),
        "never 'all received' while some remain")
    apToggleHud()
end)

test("the panel says how many upgrades the seed still holds", function()
    _G.apInventory = {
        ships = {}, systemCaps = { doors = 3 }, startingUpgrades = {}, shopAvailability = {},
    }
    applySeed({ caps = { doors = 2 } })
    sim.startRun(true)
    apToggleHud()
    apDashboardPage("systems")
    sim.renderGui()

    local detail = nil
    for index, line in ipairs(sim.drawn) do
        if line == "Door System" then detail = sim.drawn[index + 1] end
    end
    check(detail ~= nil and (detail:find("all upgrades", 1, true)
            or detail:find("toutes les", 1, true)),
        "two upgrades received out of the two the seed holds: the system is finished")
    apToggleHud()
end)

test("the menu banner says whether the mod is connected", function()
    apNetDisconnect()
    sim.tick(1)
    check(apModBanner():find("ffline") or apModBanner():find("hors ligne"),
        "offline, it says so")

    connectNow()
    check(not (apModBanner():find("ffline") or apModBanner():find("hors ligne")),
        "connected, it no longer talks about an offline prototype")
end)

test("once the run has started, nothing from the menu stays on screen", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ goal = { kind = "victories", count = 5 } })
    sim.menuOpen = false
    sim.renderMenu()
    local drawn = #sim.drawn + #(sim.images or {})
    sim.menuOpen = true

    equals(drawn, 0, "no title, no logo, no goal, no connection panel")
end)

test("the hangar stays clean: nothing from the mod on top of the ship selection", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ goal = { kind = "victories", count = 5 } })
    sim.hangarOpen = true
    sim.renderMenu()
    local drawn = #sim.drawn + #(sim.images or {})
    sim.hangarOpen = false

    equals(drawn, 0, "the ship selection isn't covered by the title or the goal")
end)

test("a received archive counts, and the goal waits for it", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    apVictoriesResetForTesting()
    applySeed({ goal = { kind = "victories", count = 1, archives = 2 },
                kinds = { "archive" }, kinds_required = {} })
    sim.startRun(true)
    local sent = 0
    local restore = stub("apNetSendGoal", function() sent = sent + 1 end)

    apVictoryWith("PLAYER_SHIP_HARD")
    equals(sent, 0, "the victory isn't enough while archives are missing")

    apQueueItem({ kind = "archive", n = 1, display = "Archipelago Archive" })
    drain()
    equals(apReceivedArchives(), 1, "the first archive is counted")
    equals(sent, 0, "one out of two doesn't unlock anything")

    apQueueItem({ kind = "archive", n = 1, display = "Archipelago Archive" })
    drain()
    equals(apReceivedArchives(), 2, "the second one arrives")
    equals(sent, 1, "the last archive is enough: no need to win another run")
    apVictoryWith("PLAYER_SHIP_ROCK")
    equals(sent, 1, "and one more victory declares nothing again")
    restore()
end)

test("the requested difficulty is written under the goal, in small text", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ goal = { kind = "victories", count = 5, difficulty = "hard" } })
    sim.renderMenu()

    local big, small = nil, nil
    for _, draw in ipairs(sim.draws) do
        if draw.text:find("5", 1, true) and draw.size >= 20 then big = draw end
        if draw.text:find(apT("difficulty.hard"), 1, true) and draw.size < 20 then small = draw end
    end
    check(big ~= nil, "the goal stays big")
    check(small ~= nil, "and the difficulty is written small")
    check(small and big and small.y > big.y, "below, not beside")

    applySeed({ goal = { kind = "victories", count = 5 } })
    sim.renderMenu()
    local free = false
    for _, draw in ipairs(sim.draws) do
        if draw.text == apT("hud.goal.difficulty.any") then free = true end
    end
    check(free, "with no requirement, the line says so instead of disappearing")
end)

test("the main menu shows the goal and progress at the top", function()
    _G.apInventory = { ships = {}, systemCaps = {}, startingUpgrades = {}, shopAvailability = {} }
    applySeed({ goal = { kind = "victories", count = 5 } })
    sim.renderMenu()

    check(sim.drawnText("5") and (sim.drawnText("victor") or sim.drawnText("Victor")),
        "the goal can be read without opening the dashboard")

    local line = nil
    for _, draw in ipairs(sim.draws) do
        if draw.centered and draw.text:find("5", 1, true) then line = draw end
    end
    check(line ~= nil, "it's centered in its frame")
    check(line and line.x < 640, "on the Archipelago side of the screen, under its logo")
    check(line and line.size >= 20, "and written large")

    local frame = nil
    for _, rect in ipairs(sim.rects) do
        if rect.y < 240 and rect.w > 100 then frame = rect end
    end
    check(frame ~= nil, "inside a frame, at the top of the screen")
    check(frame and frame.x + frame.w <= 850, "clear of FTL's logo on the right")

    local title, image = false, false
    for _, draw in ipairs(sim.draws) do
        if draw.text == apT("hud.title") and draw.size >= 24 then title = true end
    end
    for _, draw in ipairs(sim.images or {}) do
        if draw.y < 80 and draw.w >= 40 then image = true end
    end
    check(title, "with the Archipelago name written large above")
    check(image, "and the logo beside it")
end)

test("the main menu shows a summary as soon as a run is loaded", function()
    _G.apInventory = {
        ships = { "PLAYER_SHIP_ROCK" }, systemCaps = { shields = 2 },
        startingUpgrades = { engines = 1 }, shopAvailability = {},
    }
    applySeed({})
    sim.renderMenu()
    check(sim.drawnText("Archipelago"), "the summary is there")
    check(sim.drawnText("1 ship"), "with the ships")
    check(sim.drawnText("/" .. #_G.apGameData.systems .. " systems"),
          "and the systems total comes from the same source as the panel")
    check(not sim.drawnText("1 ships"), "and in the singular, since there's only one")
    check(not sim.drawnText("multiworld"), "and the explanation is gone")
end)

local function soloSlotData(items)
    local descriptors = {}
    for _, name in ipairs(items) do
        descriptors[name] = { k = "filler", res = "scrap", n = 10 }
    end
    return {
        contract = 1,
        kinds = { "filler" },
        kinds_required = {},
        items = descriptors,
        loc = { ["shop:1"] = "Archipelago Shop 1", ["shop:2"] = "Archipelago Shop 2",
                ["shop:3"] = "Archipelago Shop 3" },
        shop = { mode = "rarity_boost", deliver = false, baseline = {}, slots = 3 },
        links = {},
    }
end

test("solo: starting solo mode is enough, no need to simulate a connection", function()
    sim.startRun(true)
    check(apSoloStart(), "solo mode starts")
    check(_G.apContractState.connected == true, "and it applied its seed's slot_data")

    local before = sim.player.currentScrap
    apSendCheck("PLAYER_SHIP_HARD:sector:2", "a sector")
    drain()
    check(sim.logged("item(s) delivered") or sim.player.currentScrap ~= before
          or #_G.apInventory.ships > 0,
          "and the first check did deliver something")
    check(not sim.logged("without descriptor"), "no item falls into the void")
    apSoloStop()
end)

test("solo: the status says how many items remain, and never drops below zero", function()
    sim.startRun(true)
    check(apSoloStart(), "solo mode starts")
    local total = #_G.apSoloOrder

    sim.clearLog()
    apSoloStatus()
    check(sim.logged("0/" .. total .. " items received, " .. total .. " remaining"),
        "before the first check, everything is still to be earned")

    local keys = {}
    for key in pairs(_G.apContractState.locNames) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        apSendCheck(key, "a check of the seed")
        drain()
    end

    sim.clearLog()
    apSoloStatus()
    check(sim.logged(total .. "/" .. total .. " items received, 0 remaining"),
        "at the end, the count is right and the remainder is zero")
    apSoloStop()
end)

test("solo: an ENTIRE run, from the first check to the last item", function()
    sim.startRun(true)
    check(apSoloStart(), "solo mode starts")

    local order = _G.apSoloOrder
    equals(#_G.apInventory.ships, 0, "we start with no ship unlocked")
    local shipsBefore = #_G.apInventory.ships
    local received = 0

    for index = 1, #order do
        if apSendCheck(apCheckKeyFor(order[index].location), "simulated run") then
            received = received + 1
        end
        drain(1)
    end
    drain(3)

    check(received > 0, "the checks went out")
    equals(_G.apSoloState.delivered, #order, "each location of the seed handed out its item")
    local waiting = 0
    for _, descriptor in ipairs(_G.apFillerPendingForTesting()) do
        if descriptor.kind == "filler" and descriptor.res == "crew" and sim.player:IsCrewFull() then
            waiting = waiting + 1
        end
    end
    equals(#_G.apFillerPendingForTesting(), waiting,
           "the queue only holds crew members waiting for a free seat")
    equals(sim.errors, 0, "no error reported to the engine throughout the whole run")

    check(#_G.apInventory.ships > shipsBefore,
          "ships were unlocked (" .. shipsBefore .. " -> "
          .. #_G.apInventory.ships .. ")")
    local caps = 0
    for _, value in pairs(_G.apInventory.systemCaps) do caps = caps + value end
    check(caps > 0, "system caps went up (" .. caps .. ")")
    check(not sim.logged("without descriptor"), "no item fell into the void")
    check(not sim.logged("kind not implemented"), "no unknown kind")

    local seen = 0
    for _, line in ipairs(sim.screen) do
        if line:find("Re") or line:find("Received") then seen = seen + 1 end
    end
    check(seen > 10, "the player saw their items arrive (" .. seen .. " messages)")

    apSoloStop()
end)

test("solo: the Archipelago shop is filled, not empty", function()
    sim.startRun(true)
    apShopGiftsResetForTesting()
    _G.apShopGifts = {}
    check(apSoloStart(), "solo mode starts")
    check(#(_G.apShopGifts or {}) > 0, "gifts are installed")
    local first = sim.rarityFor("AP_GIFT_1", 0)
    check(first.shortTitle.data ~= "Rien" and first.shortTitle.data ~= "Nothing",
          "and the first slot shows a recipient ('"
          .. tostring(first.shortTitle.data) .. "')")
    apSoloStop()
end)

test("solo: an already-applied seed takes priority over solo mode's own", function()
    sim.startRun(true)
    applySeed({ loc = { ["shop:1"] = "Archipelago Shop 1" } })
    local before = apLocationNameFor("shop:1")
    apSoloStart()
    equals(apLocationNameFor("shop:1"), before, "the seed already in place hasn't moved")
    apSoloStop()
end)

test("solo: with no data, solo mode tells the player instead of pretending", function()
    sim.startRun(true)
    local savedOrder = _G.apSoloOrder
    local savedData = _G.apSoloSlotData
    _G.apSoloSlotData = nil
    equals(apSoloStart(), false, "solo mode refuses to start")
    check(shownKey("solo.no_slot_data"), "and the player is warned on screen")

    _G.apSoloOrder = {}
    equals(apSoloStart(), false, "no order either")
    check(shownKey("solo.no_order"), "and they're warned there too")

    _G.apSoloOrder = savedOrder
    _G.apSoloSlotData = savedData
end)

test("solo mode is inactive until it's turned on", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    _G.apSoloOrder = { { item = "A", location = "x" } }
    apApplySlotData(soloSlotData({ "A" }))
    sim.startRun(true)

    apSendCheck("shop:1")
    equals(_G.apSoloState.delivered, 0, "no item delivered")
end)

test("each check delivers the next item", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    _G.apSoloOrder = {
        { item = "20 Scrap", location = "Archipelago Shop 1" },
        { item = "50 Scrap", location = "Archipelago Shop 2" },
    }
    apApplySlotData(soloSlotData({ "20 Scrap", "50 Scrap" }))
    sim.startRun(true)
    apSoloStart()

    apSendCheck("shop:1")
    equals(_G.apSoloState.delivered, 1, "the first check gives the first item")

    apSendCheck("shop:2")
    equals(_G.apSoloState.delivered, 2, "the second gives the next one")
    apSoloStop()
end)

test("a check already sent delivers nothing more", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    _G.apSoloOrder = {
        { item = "20 Scrap", location = "a" }, { item = "50 Scrap", location = "b" },
    }
    apApplySlotData(soloSlotData({ "20 Scrap", "50 Scrap" }))
    sim.startRun(true)
    apSoloStart()

    apSendCheck("shop:1")
    apSendCheck("shop:1")
    equals(_G.apSoloState.delivered, 1, "a single item for a single check")
    apSoloStop()
end)

test("the item takes the same path as a networked item", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    _G.apSoloOrder = { { item = "20 Scrap", location = "a" } }
    apApplySlotData(soloSlotData({ "20 Scrap" }))
    sim.startRun(true)
    apSoloStart()

    sim.player.currentScrap = 0
    apSendCheck("shop:1")
    drain()
    equals(sim.player.currentScrap, 10, "the item is really applied to the ship")
    apSoloStop()
end)

test("the end of the list is announced only once", function()
    _G.apInventory = { ships = {}, shopAvailability = {} }
    _G.apSoloOrder = { { item = "20 Scrap", location = "a" } }
    apApplySlotData(soloSlotData({ "20 Scrap" }))
    sim.startRun(true)
    apSoloStart()

    sim.clearLog()
    apSendCheck("shop:1")
    apSendCheck("shop:2")
    apSendCheck("shop:3")
    local count = 0
    for _, line in ipairs(sim.log) do
        if line:find("all items", 1, true) then count = count + 1 end
    end
    equals(count, 1, "announced once, not on every check")
    apSoloStop()
end)

test("ship destruction is detected", function()
    sim.startRun(true)
    sim.clearLog()
    sim.player.bDestroyed = true
    sim.tick(30)
    check(sim.logged("RUN END: destroyed"), "destruction triggers the run end")
end)

test("losing the whole crew is detected, ship intact", function()
    sim.startRun(true)
    sim.tick(30)
    sim.clearLog()
    for i = 0, sim.player.vCrewList:size() - 1 do
        sim.player.vCrewList[i].bDead = true
    end
    sim.tick(30)
    check(sim.logged("RUN END: crew"), "a run is also lost with no crew")
end)

test("the run end is declared only once", function()
    sim.startRun(true)
    sim.player.bDestroyed = true
    sim.tick(30)
    sim.clearLog()
    sim.tick(300)
    check(not sim.logged("RUN END"), "no repeat after the first declaration")
end)

local SCREEN_W, SCREEN_H = 1280, 720

local function offScreen()
    for _, d in ipairs(sim.draws or {}) do
        local bottom = d.y + d.size + 5
        if d.x < 0 or d.y < 0 or d.x >= SCREEN_W or bottom > SCREEN_H then
            return string.format("size %d at (%d, %d), bottom at %d: '%s'",
                                 d.size, d.x, d.y, bottom, d.text)
        end
    end
    return nil
end

test("screen: the main menu's home view fits entirely on screen", function()
    apContractResetForTesting()
    sim.renderMenu()
    check(#sim.draws >= 3, "the three home lines are drawn (" .. #sim.draws .. ")")
    local issue = offScreen()
    check(issue == nil, "nothing off-screen at the main menu: " .. tostring(issue))
end)

local function overlap(draws)
    local function box(d)
        return d.x, d.x + #d.text * 4, d.y, d.y + d.size + 3
    end
    for i = 1, #draws do
        for j = i + 1, #draws do
            local ax1, ax2, ay1, ay2 = box(draws[i])
            local bx1, bx2, by1, by2 = box(draws[j])
            if ax1 < bx2 and bx1 < ax2 and ay1 < by2 and by1 < ay2 then
                return string.format("'%s' (%d,%d) and '%s' (%d,%d)",
                    draws[i].text, draws[i].x, draws[i].y,
                    draws[j].text, draws[j].x, draws[j].y)
            end
        end
    end
    return nil
end

test("screen: nothing is drawn on top of anything else at the main menu", function()
    apContractResetForTesting()
    sim.renderMenu()
    check(#sim.draws >= 4, "the banner and the three home lines (" .. #sim.draws .. ")")
    local issue = overlap(sim.draws)
    check(issue == nil, "no overlap: " .. tostring(issue))
end)

test("screen: nothing overlaps either once the seed is applied", function()
    sim.startRun(true)
    applySeed({})
    sim.renderMenu()
    local issue = overlap(sim.draws)
    check(issue == nil, "no overlap: " .. tostring(issue))
end)

test("screen: the menu summary fits on screen once the seed is applied", function()
    sim.startRun(true)
    applySeed({})
    sim.renderMenu()
    check(#sim.draws >= 1, "the summary is drawn")
    local issue = offScreen()
    check(issue == nil, "nothing off-screen once connected: " .. tostring(issue))
end)

test("screen: system names are constrained to a column's width", function()
    _G.apInventory = {
        ships = {}, systemCaps = { weapons = 3, shields = 2 },
        startingUpgrades = {}, shopAvailability = {},
    }
    sim.startRun(true)
    applySeed({})
    apToggleHud()
    apDashboardPage("systems")
    sim.renderGui()
    local constrained, unconstrained = 0, {}
    for _, d in ipairs(sim.draws) do
        if d.text == "Weapon Control" or d.text == "Shields" then
            if d.maxWidth ~= nil and d.maxWidth > 0 and d.maxWidth <= 220 then
                constrained = constrained + 1
            else
                unconstrained[#unconstrained + 1] = d.text
            end
        end
    end
    check(constrained >= 2, "system lines go through a constrained width")
    check(#unconstrained == 0, "none is written unconstrained: " .. (unconstrained[1] or ""))

    local noWidth = {}
    for _, d in ipairs(sim.draws) do
        if d.maxWidth == nil or d.maxWidth <= 0 then
            noWidth[#noWidth + 1] = d.text
        end
    end
    check(#noWidth == 0, #noWidth .. " panel line(s) with no width constraint: " .. (noWidth[1] or ""))
    apToggleHud()
end)

test("screen: the panel fits in its box, even packed full", function()
    local caps, starts = {}, {}
    for _, entry in ipairs(_G.apGameData.systems) do
        caps[entry.id] = entry.maxLevel
        starts[entry.id] = 1
    end
    starts.reactor = 8
    _G.apInventory = {
        ships = { "PLAYER_SHIP_ROCK", "PLAYER_SHIP_MANTIS", "PLAYER_SHIP_HARD" },
        systemCaps = caps, startingUpgrades = starts, shopAvailability = {},
    }
    sim.startRun(true)
    applySeed({})
    apToggleHud()
    for _, page in ipairs({ "overview", "ships", "systems" }) do
        apDashboardPage(page)
        sim.renderGui()
        local box
        for _, r in ipairs(sim.rects) do
            if r.w == 1000 then box = r end
        end
        check(box ~= nil, page .. ": the panel draws its box")
        local outside = {}
        for _, d in ipairs(sim.draws) do
            if box and (d.y < box.y or d.y + d.size + 3 > box.y + box.h) then
                outside[#outside + 1] = string.format("y=%d '%s'", d.y, d.text)
            end
        end
        check(#outside == 0, page .. ": " .. #outside .. " line(s) outside the box: " .. (outside[1] or ""))
        check(box ~= nil and box.y + box.h <= 710, page .. ": and the box itself doesn't go off-screen")
    end
    apToggleHud()
end)

test("screen: the dashboard fits on screen", function()
    sim.startRun(true)
    applySeed({})
    apToggleHud()
    sim.renderGui()
    check(#sim.draws >= 5, "the panel draws its lines (" .. #sim.draws .. ")")
    local issue = offScreen()
    check(issue == nil, "nothing off-screen in the panel: " .. tostring(issue))
    apToggleHud()
end)

test("safety net: no resource ever drops below zero, in any test", function()
    local offenders = {}
    for where, count in pairs(sim.resourceNegativeIn or {}) do
        offenders[#offenders + 1] = where .. " (" .. count .. " times)"
    end
    table.sort(offenders)
    check(#offenders == 0, #offenders .. " drop(s) below zero: " .. (offenders[1] or ""))
end)

test("safety net: scrap never drops below zero, in any test", function()
    local offenders = {}
    for name, count in pairs(sim.scrapWentNegativeIn or {}) do
        offenders[#offenders + 1] = name .. " (" .. count .. " times)"
    end
    table.sort(offenders)
    check(#offenders == 0, #offenders .. " test(s) made scrap drop below zero: "
          .. (offenders[1] or ""))
end)

local SYSTEM_IDS = {
    "shields", "engines", "oxygen", "medbay", "clonebay", "weapons", "drones", "teleporter",
    "cloaking", "pilot", "sensors", "doors", "hacking", "mind", "battery", "artillery",
}

test("safety net: no system id ever reached the screen across the whole suite", function()
    local offenses = {}
    for _, line in ipairs(sim.everShown or {}) do
        for _, id in ipairs(SYSTEM_IDS) do
            if line:find("%f[%w]" .. id .. "%f[%W]") ~= nil then
                offenses[#offenses + 1] = id .. " in '" .. line .. "'"
            end
        end
    end
    check(#offenses == 0, "none: " .. (offenses[1] or "") ..
          (#offenses > 1 and (" (and " .. (#offenses - 1) .. " more)") or ""))
end)

test("safety net: no ship blueprint name ever reached the screen", function()
    local offenses = {}
    for _, line in ipairs(sim.everShown or {}) do
        if line:find("PLAYER_SHIP_", 1, true) ~= nil
            and line:find("PLAYER_SHIP_TESTE", 1, true) == nil then
            offenses[#offenses + 1] = line
        end
    end
    check(#offenses == 0, "none: " .. (offenses[1] or ""))
end)

local function onTheHomeScreen()
    apContractResetForTesting()
    apConnectResetForTesting()
    sim.renderMenu()
end

test("home screen: typing fills the focused field", function()
    onTheHomeScreen()
    sim.type("Navigator")
    equals(apConnectState().slot, "Navigator", "the slot name is typed, including the capital")
    equals(apConnectState().uri, "archipelago.gg", "and the default address hasn't moved")
end)

test("home screen: no default slot name, ever", function()
    onTheHomeScreen()
    local state = apConnectState()
    equals(state.slot, "", "the slot field is empty on startup")
    equals(state.password, "", "and so is the password")
    equals(state.uri, "archipelago.gg", "the address, though, has a value useful to everyone")
    equals(state.port, "38281", "and Archipelago's standard port")

    sim.renderMenu()
    check(not sim.drawnText("Navigator"),
        "and none of our test data names shows up in the form")
end)

test("home screen: a successful connection is offered again on the next launch", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    sim.net.last = { uri = "archipelago.gg:60438", slot = "Navigator" }
    sim.renderMenu()

    local state = apConnectState()
    equals(state.uri, "archipelago.gg", "the address is picked up")
    equals(state.port, "60438", "so is the port, split off at the last colon")
    equals(state.slot, "Navigator", "and the slot name")
    equals(state.password, "", "the password, though, is never remembered")
    equals(state.focus, 4, "the cursor waits where there's still something to type")
end)

test("home screen: with no successful connection, nothing is offered again", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    sim.net.last = { uri = "", slot = "" }
    sim.renderMenu()

    equals(apConnectState().slot, "", "the slot field stays empty")
    equals(apConnectState().uri, "archipelago.gg", "and the address keeps its value useful to everyone")
end)

test("network: an unresponsive server is reported, only once", function()
    sim.startRun(true)
    apNetResetForTesting()
    apNetConnect("archipelago.gg:60438", "Navigator", "")
    sim.clearLog()

    for _ = 1, 3 do
        sim.netEvent("error", { name = "unreachable", extra = "Timer Expired" })
    end
    sim.tick(400)

    check(shownKey("net.error.unreachable"), "the player learns the server isn't responding")
    local said = 0
    for _, line in ipairs(sim.screen) do
        if line:find(apT("net.error.unreachable"), 1, true) then said = said + 1 end
    end
    equals(said, 1, "and only once, not on every retry")
end)

test("home screen: Advanced Edition off is announced under the goal", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    apInventoryClear()
    applySeed({ goal = { kind = "victories", count = 3 } })

    sim.dlc = true
    sim.renderMenu()
    check(not sim.drawnText(apT("hud.advanced_off")),
        "nothing to say while advanced content is active")

    sim.dlc = false
    sim.renderMenu()
    check(sim.drawnText(apT("hud.advanced_off")),
        "off, the player is warned: the seed hands out systems that don't exist without it")
    sim.dlc = true
end)

test("home screen: nothing is drawn on top of options, stats, credits or saves", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    apInventoryClear()
    applySeed({ goal = { kind = "victories", count = 3 } })

    sim.subScreen = nil
    sim.renderMenu()
    check(#sim.drawn > 0, "on the bare home screen, the mod is displayed")

    for _, screen in ipairs({ "options", "scores", "credits", "sauvegardes" }) do
        sim.subScreen = screen
        sim.renderMenu()
        equals(#sim.drawn, 0, "screen '" .. screen .. "' open: the mod stays silent")
    end
    sim.subScreen = nil
end)

test("a check outside the seed is logged only once", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    applySeed({ loc = { ["ach:ACH_TEST"] = "A check" } })
    _G.apNetState.connected = true
    sim.clearLog()

    for _ = 1, 5 do
        equals(apSendCheck("sys:shields:2", "Shields 2"), false, "nothing goes out")
    end

    local count = 0
    for _, line in ipairs(sim.log) do
        if line:find("out of seed", 1, true) then count = count + 1 end
    end
    equals(count, 1,
        "otherwise every jump repeats the same line and the log becomes unreadable")

    _G.apNetState.connected = false
end)

test("tutorial: no check goes out, and the screen says so in big letters", function()
    apContractResetForTesting()
    apForgetChecksForTesting()
    applySeed({ loc = { ["ach:ACH_TEST"] = "A check" } })
    sim.tutorial = true
    sim.clearLog()

    equals(apSendCheck("ach:ACH_TEST", "A check"), false,
        "the tutorial sends nothing to the server")
    equals(apSendCheck("ach:ACH_AUTRE", "Another one"), false, "nor the next one")

    sim.renderGui()
    check(sim.drawnText(apT("tutorial.blocked")),
        "the banner is there without opening anything: it's the first thing you see")

    sim.pauseOpen = true
    sim.renderGui()
    check(not sim.drawnText(apT("tutorial.blocked")),
        "ESC opens the menu: the message clears to let it be read")
    sim.pauseOpen = false

    sim.tutorial = false
    sim.renderGui()
    check(not sim.drawnText(apT("tutorial.blocked")),
        "outside the tutorial, the screen is given back to the game")
    check(apSendCheck("ach:ACH_TEST", "A check"), "and the check goes out again")
end)

test("tutorial with the dashboard open: the banner goes on top", function()
    sim.startRun(true)
    sim.tutorial = true
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.renderGui()

    local bannerRow, panelRow
    for i, line in ipairs(sim.drawn) do
        if line:find(apT("tutorial.blocked"), 1, true) then bannerRow = i end
        if line:find(apT("dash.footer"), 1, true) then panelRow = i end
    end
    check(bannerRow ~= nil and panelRow ~= nil, "both are drawn")
    check(bannerRow > panelRow, "the banner comes last, so on top: it stays readable")

    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.tutorial = false
end)

test("the startup self-check leaves no fake seed and no active links", function()
    apContractResetForTesting()
    apDeathLinkConfigure({ enabled = false })
    apEnergyLinkConfigure({ enabled = false })
    _G.apTrapLink = _G.apTrapLink or {}
    _G.apTrapLink.enabled = false
    local ships = #((_G.apInventory or {}).ships or {})

    apRunIsolated(function()
        apApplySlotData({ contract = 1, kinds = { "ship" }, kinds_required = {}, seed_hash = 1234,
            items = {}, links = { death = { enabled = true }, energy = { enabled = true },
                                  trap = { enabled = true } } }, "")
        apInventory.ships[#apInventory.ships + 1] = "PLAYER_SHIP_FAKE"
    end)

    check(not apContractState.connected, "no seed is considered applied after the test")
    equals(apSeedFingerprint(), 0, "and no fake seed fingerprint stays in memory")
    check(not apDeathLink.enabled, "DeathLink stays off until a real seed activates it")
    check(not apEnergyLink.enabled, "so does EnergyLink")
    check(not (apTrapLink and apTrapLink.enabled), "and TrapLink")
    equals(#((_G.apInventory or {}).ships or {}), ships, "the inventory is the one from before")
end)

test("home screen: nothing is drawn on top of the ship selection", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    sim.renderMenu()
    check(sim.drawnText(apT("connect.title")), "on the home screen, the panel is there")

    sim.hangarOpen = true
    sim.renderMenu()
    check(not sim.drawnText(apT("connect.title")), "at the hangar, it disappears")
    check(not sim.drawnText(apT("connect.keys")), "so does the shortcuts line")
end)

test("home screen: at the hangar, the keyboard goes back to the game", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    sim.renderMenu()
    sim.hangarOpen = true
    sim.renderMenu()

    sim.type("Kestrel")
    equals(apConnectState().slot, "", "nothing is typed during ship selection")
end)

test("network: the scout passes a real vector, not a table", function()
    sim.startRun(true)
    apNetResetForTesting()
    apContractResetForTesting()
    apNetConnect("ws://localhost:38281", "Navigator", "")

    local received = nil
    sim.net.client.ScoutLocations = function(_, names) received = names; return true end

    local json = '{"contract":1,"kinds":["filler"],"kinds_required":[],"items":{},'
        .. '"loc":{"shop:1":"Archipelago Shop 1","shop:2":"Archipelago Shop 2"},'
        .. '"shop":{"slots":2}}'
    sim.netEvent("connected", { name = "Navigator", extra = json })
    sim.tick(1)

    check(received ~= nil, "the scout did take place")
    check(type(received) ~= "table" or received.size ~= nil,
        "and it received a vector, not a bare table")
    equals(received:size(), 2, "with the seed's two slots")
end)

test("filler: an item whose delivery raises is retried, not dropped", function()
    sim.startRun(true)
    apFillerResetForTesting()
    local raising = true
    local restore = stub("apInventoryAdd", function()
        if raising then error("item not ready yet") end
        return true
    end)

    local delivered = 0
    local restoreNotify = stub("apNotifyItem", function() delivered = delivered + 1 end)

    apQueueItem({ kind = "ship", bp = "PLAYER_SHIP_ROCK", display = "Kestrel Cruiser Key" })
    sim.tick(130)
    check(not shownKey("item.failed"), "the failure isn't declared on the first attempt")

    raising = false
    sim.tick(130)
    restoreNotify()
    restore()

    equals(delivered, 1, "the item is delivered on the second pass, it wasn't lost")
    check(not shownKey("item.failed"), "and no failure was announced")
end)

test("filler: an item that always raises eventually gets reported, instead of looping", function()
    sim.startRun(true)
    apFillerResetForTesting()
    local restore = stub("apInventoryAdd", function() error("permanent fault") end)

    apQueueItem({ kind = "ship", bp = "PLAYER_SHIP_ROCK", display = "Kestrel Cruiser Key" })
    sim.tick(400)
    restore()

    check(shownKey("item.failed"), "after three attempts, the player is warned")
end)

test("home screen: auto-connect remembers, and triggers only once", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    sim.durable = { ap_autoconnect = "1" }
    sim.net.last = { uri = "localhost:38281", slot = "Navigator" }

    local attempts = 0
    local restore = stub("apNetConnect", function() attempts = attempts + 1; return true end)
    sim.renderMenu()
    sim.renderMenu()

    sim.hangarOpen = true
    sim.renderMenu()
    sim.hangarOpen = false
    sim.renderMenu()
    restore()

    equals(attempts, 1, "a single attempt per session, even coming back from the hangar")
end)

test("home screen: the auto-connect switch survives a crash", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    sim.durable = {}
    sim.meta = {}
    sim.net.last = { uri = "localhost:38281", slot = "Navigator" }

    sim.renderMenu()
    for y = 0, 719 do
        if sim.durable["ap_autoconnect"] == "1" then break end
        sim.click(200, y)
    end
    check(sim.durable["ap_autoconnect"] == "1",
        "the switch goes into the module's memory, not just the FTL profile")

    sim.meta = {}
    apConnectResetForTesting()
    local attempts = 0
    local restore = stub("apNetConnect", function() attempts = attempts + 1; return true end)
    sim.renderMenu()
    restore()

    equals(attempts, 1, "on the next launch it reconnects, whether the FTL profile is empty or not")
    sim.durable = {}
end)

test("home screen: without the switch, nothing connects on its own", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    sim.durable = {}
    sim.net.last = { uri = "localhost:38281", slot = "Navigator" }

    local attempts = 0
    local restore = stub("apNetConnect", function() attempts = attempts + 1; return true end)
    sim.renderMenu()
    restore()

    equals(attempts, 0, "the game doesn't connect behind the player's back")
end)

test("home screen: with no slot remembered, auto-connect attempts nothing", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    sim.durable = { ap_autoconnect = "1" }
    sim.net.last = { uri = "", slot = "" }

    local attempts = 0
    local restore = stub("apNetConnect", function() attempts = attempts + 1; return true end)
    sim.renderMenu()
    restore()

    equals(attempts, 0, "nothing to attempt as long as no connection has succeeded")
end)

test("inventory: clearing it doesn't destroy the template it relies on", function()
    apInventoryClear()

    check(type(_G.apInventory.ships) == "table", "the ships still exist")
    check(type(_G.apInventory.systemCaps) == "table", "so do the caps")
    check(type(_G.apInventory.startingUpgrades) == "table", "so do the starting bonuses")

    apInventoryClear()
    apInventoryClear()
    check(type(_G.apInventory.systemCaps) == "table", "even after three clears")

    equals(apInventoryAdd({ kind = "cap", sys = "shields", n = 1 }), true,
        "a system cap gets applied")
    equals(apInventoryAdd({ kind = "ship", bp = "PLAYER_SHIP_ROCK" }), true,
        "and so does a ship key")

    _G.apInventory.systemCaps = nil
    _G.apInventory.ships = nil
    equals(apInventoryAdd({ kind = "cap", sys = "engines", n = 1 }), true,
        "a gutted inventory is rebuilt rather than refusing the item")
    equals(_G.apInventory.systemCaps.engines, 2, "and the cap is indeed applied: 1 + the received item")
    check(sim.logged("MOD BUG"), "and the mod says it's ITS fault, not the server's")
end)

test("inventory: the FIRST cap item really raises the cap", function()
    apInventoryClear()

    equals(apSystemCap("doors"), 1, "at first, a system is capped at 1")
    apInventoryAdd({ kind = "cap", sys = "doors", n = 1 })
    equals(apSystemCap("doors"), 2, "the FIRST copy raises it to 2")
    apInventoryAdd({ kind = "cap", sys = "doors", n = 1 })
    equals(apSystemCap("doors"), 3, "and the next one to 3")
end)

test("deathlink: restarting a run kills no one", function()
    sim.startRun(true)
    apDeathLinkConfigure({ enabled = true, trigger = "both" })
    sim.tick(60)

    local deaths = 0
    local restore = stub("apNetSendDeath", function() deaths = deaths + 1; return true end)

    sim.started = false
    sim.player.vCrewList = sim.vector({})
    sim.tick(120)
    restore()

    equals(deaths, 0, "no death is sent outside a run")
end)

test("deathlink: DURING a run, a crew member dying does go out over the link", function()
    sim.startRun(true)
    apDeathLinkConfigure({ enabled = true, trigger = "both" })
    sim.tick(60)

    local deaths = 0
    local restore = stub("apNetSendDeath", function() deaths = deaths + 1; return true end)
    sim.player.vCrewList[0].bDead = true
    sim.tick(60)
    restore()

    check(deaths >= 1, "a crew member's death does go out (" .. deaths .. ")")
end)

test("systems: an original maximum of 1 is never trusted", function()
    sim.startRun(true)
    apInventoryClear()
    apInventoryAdd({ kind = "cap", sys = "doors", n = 1 })

    local doors = sim.constructSystem("doors", 1, 0)
    doors.maxLevel = 1
    sim.player.vSystemList:push_back(doors)
    apApplySystemRules()
    equals(doors.maxLevel, 1, "nothing is set in stone while the value isn't believable")

    doors.maxLevel = 3
    apApplySystemRules()
    equals(doors.maxLevel, 2, "the Archipelago cap then applies: 2, not 1")
end)

test("delivery: a cap received AT THE MENU is applied before the run starts", function()
    sim.started = false
    apFillerResetForTesting()
    apInventoryClear()

    apQueueItem({ kind = "cap", sys = "doors", n = 1, display = "Progressive Door System" })
    apQueueItem({ kind = "ship", bp = "PLAYER_SHIP_ROCK", display = "Rock Cruiser Key" })
    apQueueItem({ kind = "filler", res = "scrap", n = 25, display = "25 Scrap" })
    drain(3)

    equals(_G.apSystemCap("doors"), 2, "the cap is applied without waiting for the run")
    equals(#_G.apInventory.ships, 1, "so is the ship key: the hangar will see it")
    equals(#_G.apFillerPendingForTesting(), 1,
        "the scrap, though, waits for a ship to pour into")
end)

test("delivery: outside a run, scrap isn't poured into the void", function()
    sim.started = false
    apFillerResetForTesting()

    apQueueItem({ kind = "filler", res = "fuel", n = 5, display = "5 Fuel" })
    drain(3)
    equals(#_G.apFillerPendingForTesting(), 1, "it stays queued")

    sim.startRun(true)
    drain(3)
    equals(#_G.apFillerPendingForTesting(), 0, "and goes out as soon as the run starts")
end)

test("systems: the mod doesn't trap itself with its own cap from one run to the next", function()
    sim.startRun(true)
    apInventoryClear()

    local doors = sim.constructSystem("doors", 1, 0)
    doors.maxLevel = 3
    sim.player.vSystemList:push_back(doors)
    apApplySystemRules()
    equals(doors.maxLevel, 1, "with no item, the mod caps at 1")

    sim.startRun(true)
    apInventoryAdd({ kind = "cap", sys = "doors", n = 1 })
    apApplySystemRules()

    equals(doors.maxLevel, 2, "the mod remembers the game allows 3, and applies 2")
end)

test("menu: the summary counts UNLOCKED systems, not the game's sixteen", function()
    apContractResetForTesting()
    apInventoryClear()
    applySeed({})
    sim.renderMenu()
    check(not sim.drawnText("16 / 16"), "an empty inventory doesn't announce sixteen systems")

    apInventoryAdd({ kind = "cap", sys = "shields", n = 1 })
    apInventoryAdd({ kind = "cap", sys = "engines", n = 1 })
    sim.renderMenu()
    check(sim.drawnText("2 / 16") or sim.drawnText("2/16"),
        "two unlocked out of sixteen: " .. table.concat(sim.drawn, " | "))
end)

test("seed: changing seed asks the question, and only once", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    apInventoryClear()
    sim.net.last = { uri = "", slot = "" }

    applySeed({ seed_hash = "seed-A" })
    apInventoryAdd({ kind = "ship", bp = "PLAYER_SHIP_ROCK" })
    applySeed({ seed_hash = "seed-B" })

    sim.quitCalled = false
    check(apSeedChangeLeftovers(), "the mod knows an orphaned progress is left")
    sim.renderMenu()
    check(sim.drawnText(apT("reset.yes")), "the question is shown on screen")

    local requests = 0
    local restore = stub("apNetRequestProfileReset", function()
        requests = requests + 1
        return true
    end)
    local clickY = nil
    for y = 150, 400 do
        sim.click(640 - 200, y)
        if requests > 0 then clickY = y break end
    end
    restore()

    equals(requests, 1, "a click on 'yes' makes the request (y = " .. tostring(clickY) .. ")")
    check(sim.quitCalled, "and the game closes itself, so the launcher can clean up")
    check(not apSeedChangeLeftovers(), "and the question is closed")
    sim.renderMenu()
    check(not sim.drawnText(apT("reset.yes")), "it doesn't come back on the next pass")
end)

test("seed: clearing progress keeps the auto-connect setting", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    apInventoryClear()
    sim.durable = { ap_autoconnect = "1", ap_seed_tag = "4242", ap_items_done = "7" }
    sim.net.last = { uri = "localhost:38281", slot = "Navigator" }

    applySeed({ seed_hash = "seed-A" })
    apInventoryAdd({ kind = "ship", bp = "PLAYER_SHIP_ROCK" })
    applySeed({ seed_hash = "seed-B" })

    sim.quitCalled = false
    sim.renderMenu()
    local restore = stub("apNetRequestProfileReset", function() return true end)
    for y = 150, 400 do
        sim.click(640 - 200, y)
        if sim.quitCalled then break end
    end
    restore()

    check(sim.quitCalled, "the player did click yes")
    equals(sim.durable["ap_autoconnect"], "1",
        "clearing progress doesn't clear the connection preference")
    equals(sim.durable["ap_seed_tag"], "0", "the old seed's fingerprint is forgotten")
    equals(sim.durable["ap_items_done"], "0", "and so is the counter of items already received")
    sim.durable = {}
    apConnectResetForTesting()
end)

test("seed: the first seed asks nothing", function()
    apContractResetForTesting()
    apConnectResetForTesting()
    apInventoryClear()

    applySeed({ seed_hash = "seed-A" })
    check(not apSeedChangeLeftovers(), "no question on a first seed")
end)

test("home screen: TAB moves to the next field, in a loop", function()
    onTheHomeScreen()
    equals(apConnectState().focus, 3, "starts on the slot")
    sim.keyDown(Defines.SDL.KEY_TAB)
    equals(apConnectState().focus, 4, "then the password")
    sim.keyDown(Defines.SDL.KEY_TAB)
    equals(apConnectState().focus, 1, "then back to the address")
end)

test("home screen: the port only accepts digits", function()
    onTheHomeScreen()
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.keyDown(Defines.SDL.KEY_TAB)
    equals(apConnectState().focus, 2, "we are indeed on the port")
    for _ = 1, 5 do sim.keyDown(Defines.SDL.KEY_BACKSPACE) end
    sim.type("12ab34")
    equals(apConnectState().port, "1234", "letters are refused, digits go through")
end)

test("home screen: clicking a field gives it focus", function()
    onTheHomeScreen()
    local found = false
    for y = 380, 700 do
        sim.click(200, y)
        if apConnectState().focus == 1 then found = true; break end
    end
    check(found, "a click inside the address box gives it focus")
end)

test("home screen: with no slot name, the panel says so and calls no one", function()
    onTheHomeScreen()
    local calls = 0
    local restore = stub("apNetConnect", function() calls = calls + 1; return true end)
    apConnectNow()
    restore()

    equals(calls, 0, "no connection is opened without a slot")
    equals(apConnectState().message, apT("connect.need_slot"), "and it says why")
end)

test("home screen: the button sends address, port and slot to the network module", function()
    onTheHomeScreen()
    sim.type("Navigator")

    local received = nil
    local restore = stub("apNetConnect", function(uri, slot, password)
        received = { uri = uri, slot = slot, password = password }
        return true
    end)
    apConnectNow()
    restore()

    equals(received.uri, "archipelago.gg:38281", "the address carries the port")
    equals(received.slot, "Navigator", "and the slot is the one that was typed")
end)

test("home screen: with no network module, the panel blames the mod, not the player", function()
    onTheHomeScreen()
    sim.type("Navigator")
    local restore = stub("apNetConnect", function() return false end)
    apConnectNow()
    restore()

    equals(apConnectState().message, apT("connect.no_module"), "the message names the real cause")
end)

test("home screen: the password isn't shown and isn't logged", function()
    onTheHomeScreen()
    sim.type("Navigator")
    sim.keyDown(Defines.SDL.KEY_TAB)
    sim.type("hunter2")
    equals(apConnectState().password, "hunter2", "the field does retain the input")

    local restore = stub("apNetConnect", function() return true end)
    apConnectNow()
    restore()

    sim.renderMenu()
    check(not sim.drawnText("hunter2"), "the field displays as stars, never in plain text")
    check(not sim.shown("hunter2"), "and no notification repeats it")
    for _, line in ipairs(sim.log) do
        check(not line:find("hunter2", 1, true), "and nothing in the log: " .. line)
    end
end)

test("home screen: the panel clears as soon as a run is loaded", function()
    onTheHomeScreen()
    sim.renderMenu()
    check(sim.drawnText(apT("connect.title")),
        "the panel is there as long as no seed is loaded")

    applySeed({})
    sim.renderMenu()
    check(not sim.drawnText(apT("connect.title")),
        "and it disappears once the run is loaded")
end)

test("home screen: the shortcuts are written on screen", function()
    onTheHomeScreen()
    sim.renderMenu()
    check(sim.drawnText(apT("connect.keys")), "the shortcuts line is drawn")
end)

test("home screen: typing doesn't hijack the keyboard during a run", function()
    onTheHomeScreen()
    sim.startRun(true)
    sim.type("abc")
    equals(apConnectState().slot, "", "nothing is typed outside the home screen")
end)

test("shop: after solo mode, a real game shows who each package is for", function()
    apNetResetForTesting()
    if not apSoloStart() then return end
    apSoloStop()
    connectWithShop(2)
    sim.netEvent("scout", { name = "Archipelago Shop 1", sender = "Berserker",
        extra = "Seashell", value = 1 })
    sim.netEvent("scout", { name = "Archipelago Shop 2", sender = "Axel",
        extra = "Roll Fragment", value = 2 })
    sim.tick(1)
    equals(sim.rarityFor("AP_GIFT_1", 0).shortTitle.data, "Berserker", "not FOR YOU left over from solo")
    equals(sim.rarityFor("AP_GIFT_2", 0).shortTitle.data, "Axel", "for every package")
    apNetResetForTesting()
end)

test("shop: joining a real game while solo mode is still on leaves solo behind", function()
    apNetResetForTesting()
    if not apSoloStart() then return end
    connectWithShop(2)
    sim.netEvent("scout", { name = "Archipelago Shop 1", sender = "Berserker",
        extra = "Seashell", value = 1 })
    sim.netEvent("scout", { name = "Archipelago Shop 2", sender = "Axel",
        extra = "Roll Fragment", value = 2 })
    sim.tick(1)
    check(not _G.apSoloEnabled, "solo mode is off once a real seed is loaded")
    apSendCheck("shop:2", "Archipelago Shop 2")
    equals(sim.rarityFor("AP_GIFT_1", 0).shortTitle.data, "Berserker",
        "a check does not restock the shop with solo packages marked FOR YOU")
    apNetResetForTesting()
end)
