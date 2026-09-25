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

local SMALLEST_FONT = 9

-- The big title fonts do not shrink on their own: pick the largest one the text fits in.
function ui.fittingFont(sizes, maxWidth, value)
    for _, size in ipairs(sizes) do
        if ui.width(size, value) <= maxWidth then
            return size
        end
    end
    return sizes[#sizes]
end

-- FTL shrinks a text down to its smallest font and no further: past that it would overflow, so it is cut.
local function fit(value, maxWidth)
    if ui.width(SMALLEST_FONT, value) <= maxWidth then
        return value
    end
    local cut = value
    while #cut > 1 and ui.width(SMALLEST_FONT, cut .. "...") > maxWidth do
        local last = utf8 and utf8.offset(cut, -1) or #cut
        cut = cut:sub(1, (last or #cut) - 1)
    end
    return cut .. "..."
end

function ui.text(font, x, y, maxWidth, tone, value, alpha)
    maxWidth = math.max(8, maxWidth)
    Graphics.CSurface.GL_SetColor(ui.color(tone, alpha))
    Graphics.freetype.easy_printAutoShrink(font, x, y, maxWidth, false, fit(tostring(value), maxWidth))
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

function ui.window(x, y, w, h, accent)
    ui.rect(x, y, w, h, "window")
    ui.outline(x, y, w, h, accent or "border", 2)
end

_G.apUi = ui
