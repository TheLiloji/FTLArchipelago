local TAG = "[AP-connect] "

local function connectLog(message)
    log(TAG .. message)
end

local ui = apUi

local PANEL = { x = 24, w = 372, bottom = 682 }
local PAD = 16
local ROW_H = 28
local LABEL_W = 100
local BUTTON_H = 28
local STATUS_H = 162
local QUESTION = { x = 320, y = 200, w = 640, h = 220 }
local QUESTION_BUTTON_H = 34

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
local soloTried = false

local function autoActive()
    if _G.apNetRecall then
        return _G.apNetRecall(AUTO_KEY) == 1
    end
    local ok, value = pcall(function()
        return Hyperspace.metaVariables[AUTO_KEY]
    end)
    return ok and value == 1
end

local soloQuestion = false

local function toggleSolo()
    if _G.apSoloEnabled then
        connectLog("solo mode stopped from the panel")
        if _G.apSoloStop then _G.apSoloStop() end
    elseif _G.apSoloSaved and _G.apSoloSaved() then
        soloQuestion = true
    else
        connectLog("solo mode started from the panel")
        if _G.apSoloStart then _G.apSoloStart() end
    end
end

local function continueSolo()
    soloQuestion = false
    connectLog("saved solo run resumed from the panel")
    if _G.apSoloResume then _G.apSoloResume() end
end

local function restartSolo()
    soloQuestion = false
    connectLog("solo run restarted from the panel")
    if _G.apSoloStart then _G.apSoloStart(true) end
end

local function seedActive()
    return _G.apContractState ~= nil and _G.apContractState.connected == true
end

local function leaveSeed()
    message, messageTone = nil, "dim"
    if _G.apSoloEnabled then
        toggleSolo()
        return
    end
    connectLog("disconnected from the panel")
    if _G.apNetDisconnect then pcall(_G.apNetDisconnect) end
    if _G.apContractUnload then apContractUnload() end
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

local resetAsked = false

local function resetQuestionText()
    local reason = _G.apSeedChangeReason and _G.apSeedChangeReason() or "seedchange"
    if reason == "foreign" then
        return apT("reset.question.foreign")
    end
    return apT("reset.question.seedchange")
end

local function resetQuestionOpen()
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
    local solo = _G.apSoloPending
    _G.apSoloPending = false
    local autoBefore = autoActive()
    local done = _G.apNetRequestProfileReset and _G.apNetRequestProfileReset()
    if done and _G.apNetForgetProgress then
        _G.apNetForgetProgress(_G.apSeedChangeFingerprint and apSeedChangeFingerprint() or nil)
    end
    if done and solo and _G.apSoloForgetProgress then _G.apSoloForgetProgress(true) end
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
    if _G.apSeedChangeFingerprint and _G.apNetRememberSeed then
        local fingerprint = _G.apSeedChangeFingerprint()
        if fingerprint ~= nil then _G.apNetRememberSeed(fingerprint) end
    end
    if _G.apSeedChangeAcknowledged then _G.apSeedChangeAcknowledged() end
    message, messageTone = apT("reset.kept"), "dim"
    connectLog("the player keeps their progress despite the seed change")
    if _G.apSoloPending then
        _G.apSoloPending = false
        if _G.apSoloSaved and _G.apSoloSaved() then
            if _G.apSoloResume then _G.apSoloResume() end
        elseif _G.apSoloStart then
            _G.apSoloStart()
        end
    elseif FIELDS[3].value ~= "" then
        apConnectNow()
    end
end

local function currentQuestion()
    if soloQuestion then
        local saved = _G.apSoloSaved and _G.apSoloSaved() or { done = 0, total = 0 }
        return { title = apT("question.solo.title"), text = apT("solo.question", saved),
                 yes = "solo.continue", yesTone = "good", accept = continueSolo,
                 no = "solo.restart", noTone = "warn", decline = restartSolo }
    end
    if resetQuestionOpen() then
        return { title = apT("question.seed.title"), text = resetQuestionText(),
                 yes = "reset.yes", yesTone = "warn", accept = acceptReset,
                 no = "reset.no", noTone = "dim", decline = declineReset }
    end
    return nil
end

function apConnectQuestionOpen()
    return currentQuestion() ~= nil
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
    local fieldsH = #FIELDS * ROW_H
    local height = 44 + fieldsH + 24 + BUTTON_H + 78
    local top = PANEL.bottom - height
    local g = { panel = { x = PANEL.x, y = top, w = PANEL.w, h = height }, fields = {} }
    local y = top + 40
    for index = 1, #FIELDS do
        g.fields[index] = { x = PANEL.x + PAD + LABEL_W, y = y, w = PANEL.w - PAD * 2 - LABEL_W, h = 22 }
        y = y + ROW_H
    end
    g.auto = { x = PANEL.x + PAD, y = y + 2, w = PANEL.w - PAD * 2, h = 16 }
    y = y + 24
    local primaryW = math.floor((PANEL.w - PAD * 2 - 10) * 0.55)
    g.button = { x = PANEL.x + PAD, y = y, w = primaryW, h = BUTTON_H }
    g.solo = { x = PANEL.x + PAD + primaryW + 10, y = y, w = PANEL.w - PAD * 2 - primaryW - 10, h = BUTTON_H }
    g.message = { x = PANEL.x + PAD, y = y + BUTTON_H + 10, w = PANEL.w - PAD * 2 }
    g.status = { x = PANEL.x, y = PANEL.bottom - STATUS_H, w = PANEL.w, h = STATUS_H }
    g.leave = { x = PANEL.x + PAD, y = PANEL.bottom - PAD - BUTTON_H, w = PANEL.w - PAD * 2, h = BUTTON_H }
    g.question = QUESTION
    local buttonsTop = QUESTION.y + QUESTION.h - QUESTION_BUTTON_H - 18
    local buttonWidth = math.floor((QUESTION.w - 3 * 18) / 2)
    g.resetYes = { x = QUESTION.x + 18, y = buttonsTop, w = buttonWidth, h = QUESTION_BUTTON_H }
    g.resetNo = { x = QUESTION.x + 36 + buttonWidth, y = buttonsTop, w = buttonWidth, h = QUESTION_BUTTON_H }
    g.shortcuts = PANEL.bottom - 34
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

local function drawQuestion(question)
    local g = geometry()
    local q = g.question
    ui.shade()
    ui.window(q.x, q.y, q.w, q.h, "warn")
    ui.text(13, q.x + 24, q.y + 20, q.w - 48, "warn", question.title)
    ui.rect(q.x + 24, q.y + 46, q.w - 48, 1, "faint")
    ui.wrapped(10, q.x + 24, q.y + 60, q.w - 48, "text", question.text)
    ui.button(g.resetYes, apT(question.yes), question.yesTone == "warn" and "danger" or "primary")
    ui.button(g.resetNo, apT(question.no), "secondary")
end

local function drawForm()
    local g = geometry()
    local p = g.panel
    ui.rect(p.x, p.y, p.w, p.h, "window", 0.94)
    ui.rect(p.x, p.y, p.w, 2, "border")
    ui.text(10, p.x + PAD, p.y + 14, p.w - PAD * 2, "title", apT("connect.title"))

    for index, field in ipairs(FIELDS) do
        local box = g.fields[index]
        local focused = index == focus
        ui.text(9, p.x + PAD, box.y + 5, LABEL_W - 8, focused and "text" or "dim", apT(field.label))
        ui.rect(box.x, box.y, box.w, box.h, focused and "hover" or "card")
        ui.outline(box.x, box.y, box.w, box.h, focused and "border" or "faint", 1)
        local value = displayValue(field)
        if focused then
            value = value .. "_"
        end
        ui.text(10, box.x + 8, box.y + 5, box.w - 16, focused and "title" or "text", value)
    end

    ui.checkbox(g.auto.x, g.auto.y, autoActive(), apT("connect.auto"), g.auto.w)
    ui.button(g.button, apT("connect.button"), "primary")
    ui.button(g.solo, apT("connect.solo"), "secondary")

    if message ~= nil then
        ui.wrapped(9, g.message.x, g.message.y, g.message.w, messageTone, message)
    end
    ui.wrapped(9, p.x + PAD, g.shortcuts, p.w - PAD * 2, "dim", apT("connect.keys"))
end

local function drawStatus()
    local g = geometry()
    local s = g.status
    local solo = _G.apSoloEnabled == true
    local online = _G.apNetConnected and apNetConnected()
    ui.rect(s.x, s.y, s.w, s.h, "window", 0.94)
    ui.rect(s.x, s.y, s.w, 2, solo and "good" or (online and "good" or "warn"))

    local status
    if solo then
        status = apT("dash.status.solo")
    elseif online then
        status = apT("dash.status.online", { slot = tostring(_G.apOwnSlotName and apOwnSlotName() or "?") })
    else
        status = apT("dash.status.offline")
    end
    ui.text(12, s.x + PAD, s.y + 14, s.w - PAD * 2, "title", status)

    local counts = _G.apCheckCount and apCheckCount() or { sent = 0, total = 0 }
    if counts.total > 0 then
        local line = apT("dash.checks.count", { done = counts.sent, total = counts.total })
        ui.text(10, s.x + PAD, s.y + 44, s.w - PAD * 2 - 60, "text", apT("dash.checks.title") .. "  " .. line)
        ui.textRight(10, s.x + s.w - PAD, s.y + 44, 60, "dim",
            apT("dash.percent", { n = math.floor(100 * counts.sent / counts.total) }))
        ui.bar(s.x + PAD, s.y + 62, s.w - PAD * 2, 5, counts.sent / counts.total,
            counts.sent >= counts.total and "good" or "border")
    end
    if _G.apSeedSummaryLine then
        ui.text(9, s.x + PAD, s.y + 76, s.w - PAD * 2, "dim", apSeedSummaryLine())
    end
    ui.text(9, s.x + PAD, s.y + 94, s.w - PAD * 2, "dim", apT("connect.keys.run"))
    ui.button(g.leave, apT(solo and "connect.solo.stop" or "connect.disconnect"), "secondary")
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

local connectedMessage = nil
local shownRefusal = nil

local function followAttempt()
    local contract = _G.apContractState
    -- A reconnection happens without a click: its outcome must replace a "connected" left from before.
    if attempt == nil then
        local refusal = contract ~= nil and contract.refusal or nil
        -- Shown once when it appears, so the answers to the question that follows are not written over.
        if refusal ~= nil and refusal ~= shownRefusal then
            message, messageTone = apT("contract.refused", { reason = refusal }), "warn"
        elseif connectedMessage ~= nil and message == connectedMessage
            and not (_G.apNetConnected and _G.apNetConnected()) then
            message, messageTone, connectedMessage = nil, "dim", nil
        end
        shownRefusal = refusal
        return
    end
    if contract ~= nil and contract.refusal ~= nil then
        message, messageTone = apT("contract.refused", { reason = contract.refusal }), "warn"
        shownRefusal = contract.refusal
        attempt = nil
    elseif _G.apNetConnected and _G.apNetConnected() and contract ~= nil and contract.connected then
        message, messageTone = apT("net.connected", { slot = attempt.slot }), "good"
        connectedMessage = message
        attempt = nil
    elseif _G.apNetState ~= nil and _G.apNetState.refusal ~= nil then
        message, messageTone = _G.apNetState.refusal, "warn"
        attempt = nil
    elseif _G.apNetState ~= nil and _G.apNetState.unreachableShown then
        message, messageTone = apT("net.error.unreachable"), "warn"
        attempt = nil
    end
end

function apConnectNow()
    local values = {}
    for _, field in ipairs(FIELDS) do values[field.key] = field.value end
    -- Slot names can hold spaces, but not at either end: a stray one would only make the server refuse.
    values.uri = values.uri:match("^%s*(.-)%s*$"):gsub("/+$", "")
    values.slot = values.slot:match("^%s*(.-)%s*$")

    if values.slot == "" then
        message, messageTone = apT("connect.need_slot"), "warn"
        return false
    end

    -- The room page shows "archipelago.gg:54321": pasted whole into the address, its port wins over the field.
    local address = values.uri
    if values.port ~= "" and not address:match(":%d+$") then
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
    soloTried = false
    soloQuestion = false
    resetAsked = false
end

function apConnectState()
    local state = { focus = focus, message = message, onMenu = onMenu }
    for _, field in ipairs(FIELDS) do state[field.key] = field.value end
    return state
end

local WITH_SHIFT = {
    [Defines.SDL.KEY_SPACE] = " ",
    [Defines.SDL.KEY_SEMICOLON] = ":",
    [Defines.SDL.KEY_MINUS] = "_",
    [Defines.SDL.KEY_SLASH] = "?",
    [Defines.SDL.KEY_PERIOD] = ">",
}
local WITHOUT_SHIFT = {
    [Defines.SDL.KEY_SPACE] = " ",
    [Defines.SDL.KEY_COLON] = ":",
    [Defines.SDL.KEY_KP_PERIOD] = ".",
    [Defines.SDL.KEY_KP_MINUS] = "-",
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
    if key >= Defines.SDL.KEY_KP0 and key <= Defines.SDL.KEY_KP9 then
        return tostring(key - Defines.SDL.KEY_KP0)
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
    if not onMenu or seedActive() then
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
        -- On a French keyboard the dot is Shift and the ";" key, which reads as ":" here. An address has no
        -- use for a colon (the port has its own field), so there it is a dot.
        if field.key == "uri" and c == ":" and key == Defines.SDL.KEY_SEMICOLON then
            c = "."
        end
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
    x, y = apMousePosition(x, y)
    local g = geometry()
    local question = currentQuestion()
    if question ~= nil then
        if inside(g.resetYes, x, y) then
            question.accept()
            return Defines.Chain.PREEMPT
        end
        if inside(g.resetNo, x, y) then
            question.decline()
            return Defines.Chain.PREEMPT
        end
    end
    if seedActive() then
        if inside(g.leave, x, y) then
            leaveSeed()
            return Defines.Chain.PREEMPT
        end
        return Defines.Chain.CONTINUE
    end
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

            if not soloTried then
                soloTried = true
                if _G.apSoloWasActive and _G.apSoloWasActive() and not seedActive() then
                    connectLog("solo run active at the last session: resuming")
                    pcall(_G.apSoloResume)
                end
            end

            if not autoTried and autoActive() and not seedActive() then
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

        local question = currentQuestion()
        if seedActive() then
            pcall(drawStatus)
        else
            pcall(drawForm)
        end
        if question ~= nil then
            pcall(drawQuestion, question)
        end
    end
)

connectLog("connection panel loaded (home screen)")
