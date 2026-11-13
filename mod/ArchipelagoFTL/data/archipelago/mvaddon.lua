local TAG = "[AP-mvaddon] "

-- Multiverse draws an icon for each addon (mv_scripts/addon-icon.lua). Ours is lit while connected to the
-- server and dark when not: the picture of its entry is swapped, Multiverse still draws it and handles the click.
local NAME = "FTL_ARCHIPELAGO"
local pictures = {}
local shown = nil

local function picture(file)
    if pictures[file] == nil then
        local ok, made = pcall(function()
            return Hyperspace.Resources:CreateImagePrimitiveString("addons/" .. file, 0, 0, 0,
                Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
        end)
        pictures[file] = (ok and made) or false
    end
    return pictures[file] or nil
end

local function entry()
    local ok, found = pcall(function()
        for _, icon in ipairs(mods.multiverse.icons) do
            if icon.name == NAME then return icon end
        end
    end)
    return ok and found or nil
end

function apMvAddonRefresh()
    local icon = entry()
    if icon == nil then return nil end
    local connected = _G.apNetConnected and apNetConnected() or false
    local state = connected and "on" or "off"
    if shown ~= state then
        local image = picture("ftl_archipelago_" .. state .. ".png")
        if image then
            icon.image = image
            shown = state
            log(TAG .. "addon icon " .. state)
        end
    end
    return shown
end

script.on_render_event(Defines.RenderEvents.SHIP_STATUS, function()
    pcall(apMvAddonRefresh)
end, function() end)

log(TAG .. "Multiverse addon icon loaded")
