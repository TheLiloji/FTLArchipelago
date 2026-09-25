local TAG = "[AP-i18n] "

local FALLBACK = "en"

local state = {
    code = FALLBACK,
    source = "defaut",
    missing = {},
}

_G.apLang = state

local function tableFor(code)
    return code and _G.apLangTables and _G.apLangTables[code] or nil
end

local function humanize(key)
    local tail = key:match("[^.]+%.(.+)$") or key
    local words = tail:gsub("[._]", " ")
    return (words:gsub("^%l", string.upper))
end

function apLangSet(code, source)
    if type(code) ~= "string" or code == "" then
        return false
    end
    code = code:lower()
    if tableFor(code) == nil then
        log(TAG .. "language not supported by this mod: " .. code)
        return false
    end
    state.code = code
    state.source = source or "?"
    state.missing = {}
    log(TAG .. "language: " .. code .. " (" .. state.source .. ")")
    return true
end

function apLangFromGameSetting()
    local ok, raw = pcall(function()
        return tostring(Hyperspace.Settings.language)
    end)
    if not ok then
        return nil
    end
    return _G.apLangFromGame and _G.apLangFromGame[raw] or nil
end

function apLangResolve(explicit)
    if apLangSet(explicit, "yaml") then
        return state.code
    end
    if apLangSet(apLangFromGameSetting(), "jeu") then
        return state.code
    end
    state.code = FALLBACK
    state.source = "defaut"
    return state.code
end

local function interpolate(text, params)
    if params == nil then
        return text
    end
    return (text:gsub("{(%w+)}", function(name)
        local value = params[name]
        if value == nil then
            return "{" .. name .. "}"
        end
        if type(value) == "number" and value == math.floor(value)
            and math.tointeger ~= nil and math.tointeger(value) ~= nil then
            return tostring(math.tointeger(value))
        end
        return tostring(value)
    end))
end

local COUNT_PARAMS = { "n", "count", "levels", "done" }

-- A call with one of these params set to exactly 1 first tries "<key>.one"; lang files
-- only need that suffix for the languages where the singular actually reads differently.
local function pluralKey(key, params, dict)
    if type(params) ~= "table" then
        return key
    end
    for _, name in ipairs(COUNT_PARAMS) do
        local value = params[name]
        if value ~= nil then
            if value == 1 then
                local singular = key .. ".one"
                if dict ~= nil and dict[singular] ~= nil then
                    return singular
                end
            end
            return key
        end
    end
    return key
end

function apT(key, params)
    if type(key) ~= "string" then
        return ""
    end

    local current = tableFor(state.code) or {}
    key = pluralKey(key, params, current)
    local text = current[key]
    if text == nil and state.code ~= FALLBACK then
        local fallback = tableFor(FALLBACK) or {}
        text = fallback[pluralKey((key:gsub("%.one$", "")), params, fallback)]
        if text ~= nil and not state.missing[key] then
            state.missing[key] = true
            log(TAG .. "not translated in " .. state.code .. ", falling back to English: " .. key)
        end
    end

    if text == nil then
        if not state.missing[key] then
            state.missing[key] = true
            log(TAG .. "UNKNOWN KEY (mod default): " .. key)
        end
        return interpolate(humanize(key), params)
    end

    return interpolate(text, params)
end

function apLangAvailable()
    local codes = {}
    for code in pairs(_G.apLangTables or {}) do
        codes[#codes + 1] = code
    end
    table.sort(codes)
    return codes
end

function apLangStatus()
    log(TAG .. "language " .. state.code .. " (" .. state.source .. "), supported: "
        .. table.concat(apLangAvailable(), ", "))
end

apLangResolve(nil)

script.on_internal_event(Defines.InternalEvents.MAIN_MENU, function()
    if state.source ~= "yaml" then
        local previous = state.code
        apLangResolve(nil)
        if state.code ~= previous then
            log(TAG .. "language now follows the game setting: " .. previous .. " -> " .. state.code)
        end
    end
end)

log(TAG .. "language module loaded (console: LUA apLangStatus())")

local SPECIAL_TITLES = {
    artillery = "weapon_ARTILLERY_FED_title",
}

-- Looks a key up in FTL's own text library; nil (never the raw key) on any failure, so
-- callers can fall back to a readable identifier instead of displaying the lookup key.
local function textLibraryLookup(key)
    local ok, text = pcall(function()
        return Hyperspace.Global.GetInstance():GetTextLibrary():GetText(key)
    end)
    if ok and type(text) == "string" and text ~= "" then
        return text
    end
    return nil
end

function apSystemLabel(name)
    if name == nil or name == "" then
        return "?"
    end
    local key = SPECIAL_TITLES[name] or ("system_" .. name .. "_title")
    return textLibraryLookup(key) or tostring(name)
end
function apRaceLabel(name)
    if name == nil or name == "" then
        return "?"
    end
    return textLibraryLookup("crew_" .. name .. "_title") or tostring(name)
end
function apShipLabel(name)
    if name == nil or name == "" then
        return "?"
    end
    local ok, text = pcall(function()
        local bp = Hyperspace.Global.GetInstance():GetBlueprints():GetShipBlueprint(name, -1)
        return bp ~= nil and bp.name:GetText() or nil
    end)
    if ok and type(text) == "string" and text ~= "" then
        return text
    end
    return tostring(name)
end

function apAchievementLabel(id)
    if id == nil or id == "" then
        return "?"
    end
    return textLibraryLookup(tostring(id) .. "_name") or tostring(id)
end

function apHumaniseId(name)
    if name == nil or name == "" then
        return "?"
    end
    local words = tostring(name):gsub("_", " "):lower()
    return (words:gsub("^%l", string.upper))
end

function apTruncate(text, maximum)
    text = tostring(text or "")
    maximum = maximum or 12

    local starts = {}
    for i = 1, #text do
        local byte = text:byte(i)
        if byte < 0x80 or byte >= 0xC0 then
            starts[#starts + 1] = i
        end
    end
    if #starts <= maximum then
        return text
    end
    return text:sub(1, starts[maximum] - 1) .. "."
end
