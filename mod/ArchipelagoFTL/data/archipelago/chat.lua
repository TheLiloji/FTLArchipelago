-- In-game text client: the server's lines (chat, command results, hints, goals and releases) and what the
-- player says or asks, like "!hint Burst Laser II" or "!release". The dashboard's Chat page shows it.
local TAG = "[AP-chat] "
local MAX_LINES = 200
local MAX_INPUT = 200

local state = { lines = {}, unread = 0 }

local function chatLog(message)
    log(TAG .. message)
end

-- The tone of each kind of line in the list: what the player typed back reads apart from the server.
local TONES = {
    Chat = "text", ServerChat = "title", CommandResult = "good", AdminCommandResult = "good",
    Hint = "useful", Countdown = "warn", Goal = "good", Release = "dim", Collect = "dim", Tutorial = "dim",
    local_info = "warn",
}

local function clean(line)
    -- Control characters would draw as boxes; tabs read as spaces.
    return (line:gsub("\t", "  "):gsub("[%c]", ""))
end

local function push(kind, line)
    table.insert(state.lines, 1, { kind = kind, text = line, tone = TONES[kind] or "text" })
    while #state.lines > MAX_LINES do
        table.remove(state.lines)
    end
    state.unread = state.unread + 1
end

-- From the network module: one event per server message, which may span several lines.
function apChatReceive(kind, text)
    kind = tostring(kind or "Chat")
    for line in (tostring(text or "") .. "\n"):gmatch("(.-)\r?\n") do
        line = clean(line)
        if line:match("%S") then
            push(kind, line)
        end
    end
end

-- Sends what the player typed: a chat line or a "!" command. Refused (and said so) when offline.
function apChatSend(text)
    text = tostring(text or ""):match("^%s*(.-)%s*$")
    if text == "" then
        return false
    end
    if #text > MAX_INPUT then
        text = text:sub(1, MAX_INPUT)
    end
    local sent = _G.apNetSay ~= nil and apNetSay(text)
    if not sent then
        push("local_info", apT("chat.offline"))
        chatLog("not sent, offline: " .. text)
        return false
    end
    chatLog("sent: " .. text)
    return true
end

-- The character a key types. SDL names keys by the character they carry without Shift, so any printable
-- one is itself; with Shift, letters go upper case and the US number row gives its symbols.
local SHIFTED = {
    ["1"] = "!", ["2"] = "@", ["3"] = "#", ["4"] = "$", ["5"] = "%", ["6"] = "^", ["7"] = "&", ["8"] = "*",
    ["9"] = "(", ["0"] = ")", ["-"] = "_", ["="] = "+", ["["] = "{", ["]"] = "}", [";"] = ":", ["'"] = '"',
    [","] = "<", ["."] = ">", ["/"] = "?", ["`"] = "~", ["\\"] = "|",
}

function apChatKeyCharacter(key, shift)
    key = tonumber(key)
    if key == nil then
        return nil
    end
    if key >= 256 and key <= 265 then -- the keypad's digits
        return tostring(key - 256)
    end
    if key < 32 or key > 126 then
        return nil
    end
    local c = string.char(key)
    if not shift then
        return c
    end
    if c:match("%l") then
        return c:upper()
    end
    return SHIFTED[c] or c
end

function apChatLines()
    return state.lines
end

function apChatUnread()
    return state.unread
end

function apChatMarkRead()
    state.unread = 0
end

function apChatClearForTesting()
    state.lines, state.unread = {}, 0
end

chatLog("text client loaded (TAB, page 6)")
