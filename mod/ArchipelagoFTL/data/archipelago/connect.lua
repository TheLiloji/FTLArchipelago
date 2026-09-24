
local TAG = "[AP-connect] "

local function connectLog(message)
    log(TAG .. message)
end

local COLOR = {
    panel = { 0.08, 0.09, 0.12, 0.92 },
    border = { 0.59, 0.55, 0.86, 1.0 },
    title = { 0.72, 0.68, 0.92, 1.0 },
    text = { 0.88, 0.92, 0.86, 1.0 },
    dim = { 0.52, 0.55, 0.52, 1.0 },
    focus = { 0.16, 0.14, 0.24, 1.0 },
    good = { 0.55, 0.80, 0.55, 1.0 },
    warn = { 0.85, 0.72, 0.42, 1.0 },
}

local function color(name)
    local c = COLOR[name]
    return Graphics.GL_Color(c[1], c[2], c[3], c[4])
end

local PANEL_X, PANEL_W = 10, 300
local LINE_H = 15
local FIELD_X, FIELD_W = 96, 194
local BUTTON_H = 17
local SOLO_W = 96

local FIELDS = {
    { key = "uri", label = "connect.field.address", value = "archipelago.gg", max = 40 },
    { key = "port", label = "connect.field.port", value = "38281", max = 5, digitsOnly = true },
    { key = "slot", label = "connect.field.slot", value = "", max = 24 },
    { key = "password", label = "connect.field.password", value = "", max = 24, masked = true },
}

local DEFAULTS = {}
for index, field in ipairs(FIELDS) do DEFAULTS[index] = field.value end

local FOCUS_INITIAL = 3
local focus = FOCUS_INITIAL
local message = nil
local attempt = nil
local messageTone = "dim"
local shiftHeld = false

local onMenu = false

local AUTO_KEY = "ap_autoconnect"
local autoTried = false

local function autoActive()
    if _G.apNetRecall then
        return _G.apNetRecall(AUTO_KEY) == 1
    end
    local ok, value = pcall(function()
        return Hyperspace.metaVariables[AUTO_KEY]
    end)
    return ok and value == 1
end

local function toggleSolo()
    if _G.apSoloEnabled then
        connectLog("solo mode stopped from the panel")
        if _G.apSoloStop then _G.apSoloStop() end
    else
        connectLog("solo mode started from the panel")
        if _G.apSoloStart then _G.apSoloStart() end
    end
end

local function toggleAuto()
    local newValue = autoActive() and 0 or 1
    if _G.apNetRemember then
        _G.apNetRemember(AUTO_KEY, newValue)
    else
        pcall(function()
            Hyperspace.metaVariables[AUTO_KEY] = newValue
        end)
    end
    connectLog("automatic connection: " .. (newValue == 1 and "enabled" or "disabled"))
end

local SCREEN_W = 1280
local QUESTION_W = 720
local QUESTION_Y = 150
local QUESTION_H = 190
local QUESTION_BUTTON_H = 34

local resetAsked = false

local function resetQuestionText()
    local reason = _G.apSeedChangeReason and _G.apSeedChangeReason() or "seedchange"
    if reason == "foreign" then
        return apT("reset.question.foreign")
    end
    return apT("reset.question.seedchange")
end

local function questionOpen()
    if resetAsked then
        return false
    end
    if _G.apNetProfileResetRequested and _G.apNetProfileResetRequested() then
        return false
    end
    return _G.apSeedChangeLeftovers ~= nil and _G.apSeedChangeLeftovers() == true
end

local function acceptReset()
    resetAsked = true
    local autoBefore = autoActive()
    local done = _G.apNetRequestProfileReset and _G.apNetRequestProfileReset()
    if done and _G.apNetForgetProgress then _G.apNetForgetProgress() end
    if autoBefore and _G.apNetRemember then _G.apNetRemember(AUTO_KEY, 1) end
    if _G.apSeedChangeAcknowledged then _G.apSeedChangeAcknowledged() end
    if done then
        local relaunch = _G.apNetRelaunchWhenClosed and _G.apNetRelaunchWhenClosed() or false
        message, messageTone = apT(relaunch and "reset.relaunch" or "reset.asked"), "good"
        connectLog("profile erased, dated copy kept alongside"
            .. (relaunch and ", automatic relaunch planned" or ", relaunch by hand"))
        local closed = pcall(function() Hyperspace.App:OnExit() end)
        connectLog(closed and "game close requested" or "close failed, do it by hand")
    else
        message, messageTone = apT("reset.failed"), "warn"
        connectLog("reset failed: nothing was erased, progress is kept")
    end
end

local function declineReset()
    resetAsked = true
    if _G.apSeedChangeFingerprint and _G.apNetRememberSeed then
        local fingerprint = _G.apSeedChangeFingerprint()
        if fingerprint ~= nil then _G.apNetRememberSeed(fingerprint) end
    end
    if _G.apSeedChangeAcknowledged then _G.apSeedChangeAcknowledged() end
    message, messageTone = apT("reset.kept"), "dim"
    connectLog("the player keeps their progress despite the seed change")
end

local function hangarOpen()
    local ok, closed = pcall(function()
        return Hyperspace.App.menu.bOpen ~= true
    end)
    if ok and closed then
        return true
    end
    local open = _G.apMenuSubScreen and _G.apMenuSubScreen()
    return open == true
end

local function geometry()
    local bottom = 720 - 10 - 14
    local shortcutsHeight = LINE_H
    local panelHeight = LINE_H + #FIELDS * LINE_H + BUTTON_H + LINE_H + 12
    local panelTop = bottom - shortcutsHeight - panelHeight
    local g = { panel = { x = PANEL_X, y = panelTop, w = PANEL_W, h = panelHeight },
                fields = {}, button = nil }
    local y = panelTop + LINE_H + 2
    for index = 1, #FIELDS do
        g.fields[index] = { x = PANEL_X + FIELD_X, y = y, w = FIELD_W, h = LINE_H - 2 }
        y = y + LINE_H
    end
    g.button = { x = PANEL_X + 6, y = y + 2, w = 112, h = BUTTON_H }
    g.auto = { x = PANEL_X + 6, y = y + 2 + BUTTON_H + 3, w = PANEL_W - 12 - SOLO_W - 6,
               h = LINE_H - 2 }
    g.solo = { x = PANEL_X + PANEL_W - 6 - SOLO_W, y = y + 2 + BUTTON_H + 3, w = SOLO_W,
               h = LINE_H - 2 }
    local width = QUESTION_W
    local left = math.floor((SCREEN_W - width) / 2)
    g.question = { x = left, y = QUESTION_Y, w = width, h = QUESTION_H }
    local buttonsBottom = QUESTION_Y + QUESTION_H - QUESTION_BUTTON_H - 14
    local buttonWidth = math.floor((width - 3 * 16) / 2)
    g.resetYes = { x = left + 16, y = buttonsBottom, w = buttonWidth, h = QUESTION_BUTTON_H }
    g.resetNo = { x = left + 32 + buttonWidth, y = buttonsBottom,
                   w = buttonWidth, h = QUESTION_BUTTON_H }
    g.shortcuts = panelTop + panelHeight + 2
    return g
end

local function inside(box, x, y)
    return x >= box.x and x <= box.x + box.w
        and y >= box.y and y <= box.y + box.h
end

local function displayValue(field)
    if field.masked then
        return string.rep("*", #field.value)
    end
    return field.value
end

local function resumeLast()
    if _G.apNetLastConnection == nil then
        return
    end
    local ok, last = pcall(_G.apNetLastConnection)
    if not ok or last == nil then
        return
    end
    local address, port = tostring(last.uri):match("^(.*):(%d+)$")
    if address == nil then
        address, port = tostring(last.uri), nil
    end
    if address ~= "" then FIELDS[1].value = address end
    if port then FIELDS[2].value = port end
    if last.slot then
        FIELDS[3].value = last.slot
        focus = 4
    end
end

local function followAttempt()
    if attempt == nil then
        return
    end
    local contract = _G.apContractState
    if contract ~= nil and contract.refusal ~= nil then
        message, messageTone = apT("contract.refused", { reason = contract.refusal }), "warn"
        attempt = nil
    elseif _G.apNetConnected and _G.apNetConnected() and contract ~= nil and contract.connected then
        message, messageTone = apT("net.connected", { slot = attempt.slot }), "good"
        attempt = nil
    elseif _G.apNetState ~= nil and _G.apNetState.unreachableShown then
        message, messageTone = apT("net.error.unreachable"), "warn"
        attempt = nil
    end
end

function apConnectNow()
    local values = {}
    for _, field in ipairs(FIELDS) do values[field.key] = field.value end

    if values.slot == "" then
        message, messageTone = apT("connect.need_slot"), "warn"
        return false
    end

    local address = values.uri
    if values.port ~= "" then
        address = address .. ":" .. values.port
    end

    connectLog("attempting to " .. address .. ", slot " .. values.slot)
    if _G.apContractState then
        _G.apContractState.refusal = nil
    end

    local ok = false
    if _G.apNetConnect then
        local succeeded, result = pcall(_G.apNetConnect, address, values.slot, values.password)
        ok = succeeded and result ~= false
    end

    if ok then
        message, messageTone = apT("connect.trying", { uri = address }), "good"
        attempt = { slot = values.slot }
    else
        attempt = nil
        message, messageTone = apT("connect.no_module"), "warn"
    end
    return ok
end

function apConnectResetForTesting()
    attempt = nil
    for index, field in ipairs(FIELDS) do
        field.value = DEFAULTS[index]
    end
    focus, message, messageTone, shiftHeld = FOCUS_INITIAL, nil, "dim", false
    onMenu = false
    autoTried = false
    resetAsked = false
end

function apConnectState()
    local state = { focus = focus, message = message, onMenu = onMenu }
    for _, field in ipairs(FIELDS) do state[field.key] = field.value end
    return state
end

local WITH_SHIFT = {
    [Defines.SDL.KEY_SEMICOLON] = ":",
    [Defines.SDL.KEY_MINUS] = "_",
    [Defines.SDL.KEY_SLASH] = "?",
    [Defines.SDL.KEY_PERIOD] = ">",
}
local WITHOUT_SHIFT = {
    [Defines.SDL.KEY_PERIOD] = ".",
    [Defines.SDL.KEY_MINUS] = "-",
    [Defines.SDL.KEY_SLASH] = "/",
    [Defines.SDL.KEY_SEMICOLON] = ";",
}

local function character(key)
    if key >= Defines.SDL.KEY_a and key <= Defines.SDL.KEY_z then
        local letter = string.char(key)
        return shiftHeld and letter:upper() or letter
    end
    if key >= Defines.SDL.KEY_0 and key <= Defines.SDL.KEY_9 then
        return string.char(key)
    end
    local keyMap = shiftHeld and WITH_SHIFT or WITHOUT_SHIFT
    return keyMap[key]
end

script.on_internal_event(Defines.InternalEvents.ON_KEY_UP, function(key)
    if key == Defines.SDL.KEY_LSHIFT or key == Defines.SDL.KEY_RSHIFT then
        shiftHeld = false
    end
    return Defines.Chain.CONTINUE
end)

script.on_internal_event(Defines.InternalEvents.ON_KEY_DOWN, function(key)
    if not onMenu then
        return Defines.Chain.CONTINUE
    end
    if key == Defines.SDL.KEY_LSHIFT or key == Defines.SDL.KEY_RSHIFT then
        shiftHeld = true
        return Defines.Chain.CONTINUE
    end

    if key == Defines.SDL.KEY_TAB or key == Defines.SDL.KEY_DOWN then
        focus = focus % #FIELDS + 1
        return Defines.Chain.PREEMPT
    end
    if key == Defines.SDL.KEY_UP then
        focus = (focus - 2) % #FIELDS + 1
        return Defines.Chain.PREEMPT
    end
    if key == Defines.SDL.KEY_RETURN or key == Defines.SDL.KEY_KP_ENTER then
        apConnectNow()
        return Defines.Chain.PREEMPT
    end
    if key == Defines.SDL.KEY_BACKSPACE then
        local field = FIELDS[focus]
        field.value = field.value:sub(1, -2)
        return Defines.Chain.PREEMPT
    end

    local c = character(key)
    if c ~= nil then
        local field = FIELDS[focus]
        if field.digitsOnly and not c:match("%d") then
            return Defines.Chain.PREEMPT
        end
        if #field.value < field.max then
            field.value = field.value .. c
        end
        return Defines.Chain.PREEMPT
    end
    return Defines.Chain.CONTINUE
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    if not onMenu then
        return Defines.Chain.CONTINUE
    end
    local g = geometry()
    for index, box in ipairs(g.fields) do
        if inside(box, x, y) then
            focus = index
            return Defines.Chain.PREEMPT
        end
    end
    if inside(g.button, x, y) then
        apConnectNow()
        return Defines.Chain.PREEMPT
    end
    if inside(g.auto, x, y) then
        toggleAuto()
        return Defines.Chain.PREEMPT
    end
    if inside(g.solo, x, y) then
        toggleSolo()
        return Defines.Chain.PREEMPT
    end
    if questionOpen() then
        if inside(g.resetYes, x, y) then
            acceptReset()
            return Defines.Chain.PREEMPT
        end
        if inside(g.resetNo, x, y) then
            declineReset()
            return Defines.Chain.PREEMPT
        end
    end
    return Defines.Chain.CONTINUE
end)

script.on_init(function() onMenu = false end)
script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function()
    onMenu = false
    return Defines.Chain.CONTINUE
end)

script.on_render_event(
    Defines.RenderEvents.MAIN_MENU,
    function() end,
    function()
        if not onMenu then
            pcall(resumeLast)

            if not autoTried and autoActive() then
                autoTried = true
                local state = apConnectState()
                if state.slot ~= "" then
                    connectLog("automatic connection: " .. state.uri .. ":" .. state.port)
                    pcall(apConnectNow)
                end
            end
        end
        pcall(followAttempt)
        if hangarOpen() then
            onMenu = false
            return
        end
        onMenu = true

        if questionOpen() then
            pcall(function()
                local g = geometry()
                local q = g.question

                Graphics.CSurface.GL_DrawRect(q.x, q.y, q.w, q.h, color("panel"))
                Graphics.CSurface.GL_DrawRect(q.x, q.y, q.w, 3, color("warn"))
                Graphics.CSurface.GL_DrawRect(q.x, q.y + q.h - 3, q.w, 3, color("warn"))

                Graphics.CSurface.GL_SetColor(color("warn"))
                Graphics.freetype.easy_printNewlinesCentered(13, q.x + q.w / 2, q.y + 20,
                    q.w - 40, resetQuestionText())

                for _, button in ipairs({ { g.resetYes, "reset.yes", "warn" },
                                          { g.resetNo, "reset.no", "dim" } }) do
                    local b = button[1]
                    Graphics.CSurface.GL_DrawRect(b.x, b.y, b.w, b.h, color("focus"))
                    Graphics.CSurface.GL_DrawRect(b.x, b.y, b.w, 2, color(button[3]))
                    Graphics.CSurface.GL_SetColor(color(button[3]))
                    Graphics.freetype.easy_printCenter(13, b.x + b.w / 2, b.y + 8,
                        apT(button[2]))
                end
            end)
        end

        if _G.apContractState ~= nil and _G.apContractState.connected then
            return
        end
        pcall(function()
            local g = geometry()
            local p = g.panel

            Graphics.CSurface.GL_DrawRect(p.x, p.y, p.w, p.h, color("panel"))
            Graphics.CSurface.GL_DrawRect(p.x, p.y, p.w, 1, color("border"))

            Graphics.CSurface.GL_SetColor(color("title"))
            Graphics.freetype.easy_printAutoShrink(10, p.x + 6, p.y + 3, p.w - 12, false,
                apT("connect.title"))

            for index, field in ipairs(FIELDS) do
                local box = g.fields[index]
                Graphics.CSurface.GL_SetColor(color("dim"))
                Graphics.freetype.easy_printAutoShrink(9, p.x + 6, box.y, box.x - p.x - 10, false,
                    apT(field.label))

                Graphics.CSurface.GL_DrawRect(box.x, box.y - 1, box.w, box.h,
                    color(index == focus and "focus" or "panel"))
                Graphics.CSurface.GL_SetColor(color(index == focus and "title" or "text"))
                local text = displayValue(field)
                if index == focus then
                    text = text .. "_"
                end
                Graphics.freetype.easy_print(9, box.x + 3, box.y, text)
            end

            local b = g.button
            Graphics.CSurface.GL_DrawRect(b.x, b.y, b.w, b.h, color("focus"))
            Graphics.CSurface.GL_DrawRect(b.x, b.y, b.w, 1, color("border"))
            Graphics.CSurface.GL_SetColor(color("title"))
            Graphics.freetype.easy_printAutoShrink(10, b.x + 8, b.y + 2, b.w - 16, false,
                apT("connect.button"))

            if message ~= nil then
                Graphics.CSurface.GL_SetColor(color(messageTone))
                Graphics.freetype.easy_printAutoShrink(9, b.x + b.w + 8, b.y + 3,
                    p.w - b.w - 20, false, message)
            end

            local a = g.auto
            Graphics.CSurface.GL_SetColor(color(autoActive() and "good" or "dim"))
            Graphics.freetype.easy_printAutoShrink(9, a.x, a.y, a.w, false,
                (autoActive() and "[x] " or "[ ] ") .. apT("connect.auto"))

            local s = g.solo
            Graphics.CSurface.GL_DrawRect(s.x, s.y, s.w, s.h, color("focus"))
            Graphics.CSurface.GL_DrawRect(s.x, s.y, s.w, 1, color("border"))
            Graphics.CSurface.GL_SetColor(color(_G.apSoloEnabled and "good" or "title"))
            Graphics.freetype.easy_printAutoShrink(9, s.x + 4, s.y, s.w - 8, false,
                apT(_G.apSoloEnabled and "connect.solo.stop" or "connect.solo"))

            Graphics.CSurface.GL_SetColor(color("dim"))
            Graphics.freetype.easy_printAutoShrink(9, p.x, g.shortcuts, p.w, false,
                apT("connect.keys"))
        end)
    end
)

connectLog("connection panel loaded (home screen)")
