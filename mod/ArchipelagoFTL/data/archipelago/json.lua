
local TAG = "[AP-json] "

local ESCAPES = {
    ['"'] = '"', ["\\"] = "\\", ["/"] = "/",
    b = "\b", f = "\f", n = "\n", r = "\r", t = "\t",
}

local decodeValue

local function skipBlanks(text, i)
    local _, stop = text:find("^[ \t\r\n]*", i)
    return stop + 1
end

local function toUtf8(code)
    if code < 0x80 then
        return string.char(code)
    elseif code < 0x800 then
        return string.char(0xC0 + math.floor(code / 0x40), 0x80 + code % 0x40)
    elseif code < 0x10000 then
        return string.char(0xE0 + math.floor(code / 0x1000),
                           0x80 + math.floor(code / 0x40) % 0x40,
                           0x80 + code % 0x40)
    end
    return string.char(0xF0 + math.floor(code / 0x40000),
                       0x80 + math.floor(code / 0x1000) % 0x40,
                       0x80 + math.floor(code / 0x40) % 0x40,
                       0x80 + code % 0x40)
end

local function decodeString(text, i)
    local parts = {}
    local j = i + 1
    while true do
        local c = text:sub(j, j)
        if c == "" then
            return nil, j, "unterminated string"
        elseif c == '"' then
            return table.concat(parts), j + 1
        elseif c == "\\" then
            local escNext = text:sub(j + 1, j + 1)
            if escNext == "u" then
                local hex = text:sub(j + 2, j + 5)
                local code = tonumber(hex, 16)
                if code == nil then
                    return nil, j, "invalid \\u escape"
                end
                if code >= 0xD800 and code <= 0xDBFF and text:sub(j + 6, j + 7) == "\\u" then
                    local low = tonumber(text:sub(j + 8, j + 11), 16)
                    if low and low >= 0xDC00 and low <= 0xDFFF then
                        code = 0x10000 + (code - 0xD800) * 0x400 + (low - 0xDC00)
                        j = j + 6
                    end
                end
                parts[#parts + 1] = toUtf8(code)
                j = j + 6
            else
                local replacement = ESCAPES[escNext]
                if replacement == nil then
                    return nil, j, "unknown escape: \\" .. escNext
                end
                parts[#parts + 1] = replacement
                j = j + 2
            end
        else
            local _, stop = text:find('^[^"\\]+', j)
            parts[#parts + 1] = text:sub(j, stop)
            j = stop + 1
        end
    end
end

local function decodeArray(text, i)
    local result = {}
    local j = skipBlanks(text, i + 1)
    if text:sub(j, j) == "]" then
        return result, j + 1
    end
    while true do
        local value, next_, err = decodeValue(text, j)
        if err then return nil, next_, err end
        result[#result + 1] = value
        j = skipBlanks(text, next_)
        local c = text:sub(j, j)
        if c == "]" then
            return result, j + 1
        elseif c ~= "," then
            return nil, j, "expected comma or closing bracket"
        end
        j = skipBlanks(text, j + 1)
    end
end

local function decodeObject(text, i)
    local result = {}
    local j = skipBlanks(text, i + 1)
    if text:sub(j, j) == "}" then
        return result, j + 1
    end
    while true do
        if text:sub(j, j) ~= '"' then
            return nil, j, "expected key"
        end
        local key, next_, err = decodeString(text, j)
        if err then return nil, next_, err end
        j = skipBlanks(text, next_)
        if text:sub(j, j) ~= ":" then
            return nil, j, "expected colon"
        end
        j = skipBlanks(text, j + 1)
        local value, next2, err2 = decodeValue(text, j)
        if err2 then return nil, next2, err2 end
        result[key] = value
        j = skipBlanks(text, next2)
        local c = text:sub(j, j)
        if c == "}" then
            return result, j + 1
        elseif c ~= "," then
            return nil, j, "expected comma or closing brace"
        end
        j = skipBlanks(text, j + 1)
    end
end

decodeValue = function(text, i)
    local c = text:sub(i, i)
    if c == "{" then
        return decodeObject(text, i)
    elseif c == "[" then
        return decodeArray(text, i)
    elseif c == '"' then
        return decodeString(text, i)
    elseif text:sub(i, i + 3) == "true" then
        return true, i + 4
    elseif text:sub(i, i + 4) == "false" then
        return false, i + 5
    elseif text:sub(i, i + 3) == "null" then
        return false, i + 4
    end
    local _, stop = text:find("^%-?%d+%.?%d*[eE]?[-+]?%d*", i)
    if stop == nil or stop < i then
        return nil, i, "unexpected value: '" .. text:sub(i, i + 12) .. "'"
    end
    local number = tonumber(text:sub(i, stop))
    if number == nil then
        return nil, i, "invalid number"
    end
    return number, stop + 1
end

function apJsonDecode(text)
    if type(text) ~= "string" or text == "" then
        return nil, "nothing to decode"
    end
    local i = skipBlanks(text, 1)
    local value, next_, err = decodeValue(text, i)
    if err then
        return nil, err .. " (position " .. tostring(next_) .. ")"
    end
    local stop = skipBlanks(text, next_)
    if stop <= #text then
        return nil, "extra text after value (position " .. tostring(stop) .. ")"
    end
    return value
end

log(TAG .. "JSON reader loaded")
