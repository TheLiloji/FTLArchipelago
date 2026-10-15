local ui = {}

ui.COLOR = {
    shade = { 0.0, 0.0, 0.0, 0.72 },
    window = { 0.07, 0.075, 0.10, 0.97 },
    card = { 0.12, 0.125, 0.17, 0.96 },
    hover = { 0.17, 0.165, 0.24, 1.0 },
    faint = { 0.22, 0.23, 0.30, 1.0 },
    border = { 0.59, 0.55, 0.86, 1.0 },
    accent = { 0.36, 0.32, 0.62, 1.0 },
    title = { 0.78, 0.74, 0.96, 1.0 },
    text = { 0.90, 0.93, 0.88, 1.0 },
    dim = { 0.55, 0.57, 0.62, 1.0 },
    good = { 0.55, 0.82, 0.55, 1.0 },
    warn = { 0.88, 0.74, 0.42, 1.0 },
    bad = { 0.88, 0.45, 0.42, 1.0 },
    useful = { 0.52, 0.68, 0.96, 1.0 },
}

function ui.color(name, alpha)
    local c = ui.COLOR[name] or ui.COLOR.text
    return Graphics.GL_Color(c[1], c[2], c[3], alpha or c[4])
end

function ui.rect(x, y, w, h, tone, alpha)
    Graphics.CSurface.GL_DrawRect(x, y, w, h, ui.color(tone, alpha))
end

function ui.outline(x, y, w, h, tone, thickness)
    Graphics.CSurface.GL_DrawRectOutline(x, y, w, h, ui.color(tone), thickness or 1)
end

function ui.width(font, value)
    return Graphics.freetype.easy_measureWidth(font, tostring(value))
end


-- The big title fonts do not shrink on their own: pick the largest one the text fits in.
function ui.fittingFont(sizes, maxWidth, value)
    for _, size in ipairs(sizes) do
        if ui.width(size, value) <= maxWidth then
            return size
        end
    end
    return sizes[#sizes]
end

-- FTL does not always shrink a text to fit, so a text too wide for its font is cut with an ellipsis.
local function fit(font, value, maxWidth)
    if ui.width(font, value) <= maxWidth then
        return value
    end
    local cut = value
    while #cut > 1 and ui.width(font, cut .. "...") > maxWidth do
        local last = utf8 and utf8.offset(cut, -1) or #cut
        cut = cut:sub(1, (last or #cut) - 1)
    end
    return cut .. "..."
end

function ui.text(font, x, y, maxWidth, tone, value, alpha)
    maxWidth = math.max(8, maxWidth)
    Graphics.CSurface.GL_SetColor(ui.color(tone, alpha))
    Graphics.freetype.easy_printAutoShrink(font, x, y, maxWidth, false, fit(font, tostring(value), maxWidth))
end

function ui.textRight(font, right, y, maxWidth, tone, value, alpha)
    local w = math.min(ui.width(font, value), maxWidth)
    ui.text(font, right - w, y, w, tone, value, alpha)
end

function ui.textCenter(font, center, y, maxWidth, tone, value, alpha)
    local w = math.min(ui.width(font, value), maxWidth)
    ui.text(font, math.floor(center - w / 2), y, w, tone, value, alpha)
end

function ui.wrapped(font, x, y, maxWidth, tone, value, alpha)
    Graphics.CSurface.GL_SetColor(ui.color(tone, alpha))
    Graphics.freetype.easy_printAutoNewlines(font, x, y, math.max(8, maxWidth), tostring(value))
end

function ui.bar(x, y, w, h, ratio, tone)
    ui.rect(x, y, w, h, "faint")
    local filled = math.floor(w * math.max(0, math.min(1, ratio or 0)))
    if filled > 0 then
        ui.rect(x, y, filled, h, tone or "border")
    end
end

function ui.inside(area, x, y)
    return area ~= nil and x >= area.x and x <= area.x + area.w and y >= area.y and y <= area.y + area.h
end

function ui.mouse()
    if _G.apMousePosition then
        return apMousePosition(-1, -1)
    end
    return -1, -1
end

function ui.hovered(area)
    local mx, my = ui.mouse()
    return ui.inside(area, mx, my)
end

-- style: "primary" (filled), "secondary" (outlined) or "danger".
function ui.button(area, label, style, disabled)
    local over = not disabled and ui.hovered(area)
    if style == "primary" then
        ui.rect(area.x, area.y, area.w, area.h, over and "border" or "accent")
        ui.textCenter(10, area.x + area.w / 2, area.y + math.floor((area.h - 12) / 2), area.w - 12,
            disabled and "dim" or "text", label)
        return
    end
    ui.rect(area.x, area.y, area.w, area.h, over and "hover" or "card")
    ui.outline(area.x, area.y, area.w, area.h, style == "danger" and "warn" or (disabled and "faint" or "accent"), 1)
    ui.textCenter(10, area.x + area.w / 2, area.y + math.floor((area.h - 12) / 2), area.w - 12,
        disabled and "dim" or (style == "danger" and "warn" or "title"), label)
end

function ui.checkbox(x, y, checked, label, maxWidth)
    ui.outline(x, y + 1, 12, 12, checked and "good" or "dim", 1)
    if checked then
        ui.rect(x + 3, y + 4, 6, 6, "good")
    end
    ui.text(9, x + 20, y, maxWidth - 20, checked and "text" or "dim", label)
end

function ui.shade()
    ui.rect(0, 0, 1280, 720, "shade")
end

-- Under a full-screen panel the mouse still hovers the ship: FTL's own tooltip must not draw over the panel.
function ui.hideGameTooltip()
    pcall(function()
        local mouse = Hyperspace.Mouse
        mouse.tooltip = ""
        mouse.tooltipTimer = 0
    end)
end

function ui.window(x, y, w, h, accent)
    ui.rect(x, y, w, h, "window")
    ui.outline(x, y, w, h, accent or "border", 2)
end

-- The game's own pictures. Each is looked up once; a missing one is remembered as false, not retried every frame.
local images = {}
function ui.image(path)
    if path == nil then return nil end
    if images[path] == nil then
        local ok, texture = pcall(function() return Hyperspace.Resources:GetImageId(path) end)
        images[path] = (ok and texture and (texture.width or 0) > 0) and texture or false
    end
    return images[path] or nil
end

-- Draws part of a texture (u and v from 0 to 1) in a box.
function ui.blit(texture, x, y, w, h, alpha, u1, u2, v1, v2)
    Graphics.CSurface.GL_BlitImagePartial(texture, x, y, w, h, u1 or 0, u2 or 1, v1 or 0, v2 or 1,
        alpha or 1, Graphics.GL_Color(1, 1, 1, 1), false)
end

-- A race as the ship shows it: the first frame of its sprite sheet, facing down. Works for Multiverse races too.
local CREW_FRAME = 35
function ui.raceSprite(race, x, y, size, alpha)
    local texture = race and ui.image("people/" .. tostring(race) .. "_base.png")
    if texture == nil or (texture.width or 0) < CREW_FRAME then return false end
    ui.blit(texture, x, y, size, size, alpha, 0, CREW_FRAME / texture.width, 0, CREW_FRAME / texture.height)
    return true
end

-- A weapon lying flat, as stores show it: the first frame of its art, turned a quarter, centred in the box.
-- Lua cannot load a weapon animation, so the frame comes from the game data (and Multiverse's).
local function weaponFrame(blueprint)
    local art = (((_G.apGameData or {}).weaponArt) or {})[tostring(blueprint)]
    local texture = art and ui.image(art[1])
    if texture == nil or not texture then return nil end
    local w, h, fw, fh, column, row = art[2], art[3], art[4], art[5], art[6] or 0, art[7] or 0
    -- Rows count from the bottom of the sheet.
    local top = (math.floor(h / fh) - 1 - row) * fh
    return { texture = texture, w = fw, h = fh, u = column * fw / w, v = top / h, du = fw / w, dv = fh / h }
end

function ui.weaponArt(blueprint, x, y, w, h, alpha)
    local frame = weaponFrame(blueprint)
    if frame == nil then return false end
    -- Turned, the frame's height lies across the box: shrink only when it would not fit.
    local scale = math.min(1, w / frame.h, h / frame.w)
    local fw, fh = frame.w * scale, frame.h * scale
    Graphics.CSurface.GL_PushMatrix()
    -- A quarter turn clockwise: the barrel points right, as in a store.
    Graphics.CSurface.GL_Translate(x + (w + fh) / 2, y + (h - fw) / 2, 0)
    Graphics.CSurface.GL_Rotate(90, 0, 0, 1)
    ui.blit(frame.texture, 0, 0, fw, fh, alpha, frame.u, frame.u + frame.du, frame.v, frame.v + frame.dv)
    Graphics.CSurface.GL_PopMatrix()
    return true
end

-- A ship layout as the ship list shows it (its "miniship" picture), fitted in the box.
function ui.shipMini(layout, x, y, w, h, alpha)
    local ok, file = pcall(function()
        return Hyperspace.Global.GetInstance():GetBlueprints():GetShipBlueprint(layout, -1).imgFile
    end)
    local texture = ok and file and ui.image("customizeUI/miniship_" .. tostring(file) .. ".png")
    if texture == nil or not texture then return false end
    local scale = math.min(w / texture.width, h / texture.height)
    local mw, mh = texture.width * scale, texture.height * scale
    ui.blit(texture, x + (w - mw) / 2, y + (h - mh) / 2, mw, mh, alpha)
    return true
end

-- A drone as it flies: its base picture at its own size (the picture has a wide empty border), narrowed only
-- when wider than the box.
function ui.droneArt(blueprint, x, y, w, h, alpha)
    local ok, name = pcall(function() return Hyperspace.Blueprints:GetDroneBlueprint(blueprint).droneImage end)
    local texture = ok and name and ui.image("ship/drones/" .. tostring(name) .. "_base.png")
    if texture == nil or not texture then return false end
    local scale = math.min(1, w / texture.width)
    local dw, dh = texture.width * scale, texture.height * scale
    ui.blit(texture, x + (w - dw) / 2, y + (h - dh) / 2, dw, dh, alpha)
    return true
end

_G.apUi = ui
