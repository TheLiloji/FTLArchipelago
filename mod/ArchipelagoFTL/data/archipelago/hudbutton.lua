local TAG = "[AP-button] "

-- A button in the top right corner of a run opens the dashboard, like TAB. Art by Trapper444: the plain
-- button, and the coloured one under the mouse.
local IMAGE = "ap_button.png"
local IMAGE_HOVER = "ap_button_hover.png"
local SIZE = { w = 51, h = 53 } -- the 128x132 art at 40 %
local AREA = { x = 1280 - 51 - 12, y = 14, w = SIZE.w, h = SIZE.h }

local textures = {}
local hovering = false

local function texture(name)
    if textures[name] == nil then
        local ok, id = pcall(function() return Hyperspace.Resources:GetImageId(name) end)
        textures[name] = (ok and id) or false
    end
    return textures[name] or nil
end

local function inRun()
    local ok, yes = pcall(function()
        return Hyperspace.App.world.bStartedGame == true and Hyperspace.App.menu.bOpen ~= true
    end)
    return ok and yes
end

local function inside(x, y)
    return x >= AREA.x and x < AREA.x + AREA.w and y >= AREA.y and y < AREA.y + AREA.h
end

function apHudButtonArea()
    return AREA
end

local function draw()
    if not inRun() or (_G.apDashboardOpen and apDashboardOpen()) then
        hovering = false
        return
    end
    local mx, my = apMousePosition(-1, -1)
    hovering = inside(mx, my)
    local id = texture(hovering and IMAGE_HOVER or IMAGE)
    if id then
        Graphics.CSurface.GL_BlitImage(id, AREA.x, AREA.y, AREA.w, AREA.h, 0, Graphics.GL_Color(1, 1, 1, 1), false)
    end
    if hovering then
        Hyperspace.Mouse.tooltip = apT("button.dashboard")
    end
end

script.on_render_event(Defines.RenderEvents.GUI_CONTAINER, function() end, function()
    pcall(draw)
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    if not inRun() or (_G.apDashboardOpen and apDashboardOpen()) then
        return Defines.Chain.CONTINUE
    end
    x, y = apMousePosition(x, y)
    if not inside(x, y) then
        return Defines.Chain.CONTINUE
    end
    apToggleHud()
    log(TAG .. "dashboard opened by the button")
    return Defines.Chain.PREEMPT
end)

log(TAG .. "dashboard button loaded")
