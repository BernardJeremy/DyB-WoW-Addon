-- Cursor Circle ----------------------------------------------------------------
-- Displays a colored circle ring around the mouse cursor.
-- A single ring texture covers the frame; OnUpdate only runs when the frame is shown.

local L = DyBAddon.L

-- Color presets (r, g, b)
local CURSOR_CIRCLE_COLORS = {
    white  = { 1,   1,   1   },
    red    = { 1,   0.2, 0.2 },
    green  = { 0.2, 1,   0.2 },
    blue   = { 0.2, 0.6, 1   },
    yellow = { 1,   1,   0   },
    purple = { 0.8, 0.2, 1   },
    cyan   = { 0,   1,   1   },
    orange = { 1,   0.5, 0   },
}

-- The ring stroke width is baked into the texture, so stacking several copies at
-- decreasing sizes (all centered on the frame) effectively multiplies the stroke
-- thickness without any external art assets.
local CIRCLE_SIZE_DEFAULT = 96   -- fallback diameter used before SavedVariables load
local CIRCLE_LAYER_STEP   = 6    -- size delta between each stacked layer
local CIRCLE_LAYER_COUNT  = 1    -- number of stacked layers (more = thicker ring)

-- Reference: https://warcraft.wiki.gg/wiki/API_CreateFrame
local circleFrame = CreateFrame("Frame", "DyBCursorCircleFrame", UIParent)
circleFrame:SetSize(CIRCLE_SIZE_DEFAULT, CIRCLE_SIZE_DEFAULT)
circleFrame:SetFrameStrata("TOOLTIP")
circleFrame:Hide()

-- Stack CIRCLE_LAYER_COUNT ring textures at decreasing sizes, all centered.
-- MiniMap-TrackingBorder is a built-in white ring outline that scales cleanly
-- and supports SetVertexColor.
-- Reference: https://warcraft.wiki.gg/wiki/API_Texture_SetTexture
local circleTextures = {}
for i = 1, CIRCLE_LAYER_COUNT do
    local size = CIRCLE_SIZE_DEFAULT - (i - 1) * CIRCLE_LAYER_STEP
    local t = circleFrame:CreateTexture(nil, "OVERLAY")
    t:SetSize(size, size)
    t:SetPoint("CENTER", circleFrame, "CENTER", 0, 0)
    t:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    circleTextures[i] = t
end

local function ApplyColor(key)
    local color = CURSOR_CIRCLE_COLORS[key] or CURSOR_CIRCLE_COLORS["white"]
    for i = 1, CIRCLE_LAYER_COUNT do
        circleTextures[i]:SetVertexColor(color[1], color[2], color[3], 1)
    end
end

local function ApplySize(size)
    circleFrame:SetSize(size, size)
    for i = 1, CIRCLE_LAYER_COUNT do
        circleTextures[i]:SetSize(size - (i - 1) * CIRCLE_LAYER_STEP,
                                  size - (i - 1) * CIRCLE_LAYER_STEP)
    end
end

-- Track the cursor every frame while the feature is enabled.
-- GetCursorPosition returns physical screen pixels; divide by effective scale
-- for virtual (UI) coordinates.  The default arrow cursor hotspot sits at the
-- very tip of the arrow; its body extends ~16 screen px to the right and
-- downward, so we shift the ring center by that amount so it visually
-- encircles the cursor icon rather than being centered on the click tip.
-- Reference: https://warcraft.wiki.gg/wiki/API_GetCursorPosition
local CURSOR_HOTSPOT_OFFSET_PX = 16   -- screen pixels from tip to cursor body center
circleFrame:SetScript("OnUpdate", function(self)
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
        (x + CURSOR_HOTSPOT_OFFSET_PX) / scale,
        (y - CURSOR_HOTSPOT_OFFSET_PX) / scale)
end)

local cursorCircleEventFrame = CreateFrame("Frame")
-- Reason: Initialize saved variables and apply initial state after addon files load
cursorCircleEventFrame:RegisterEvent("ADDON_LOADED")
-- Reason: Show the ring on combat entry when combat-only mode is enabled
cursorCircleEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
-- Reason: Hide the ring on combat exit when combat-only mode is enabled
cursorCircleEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

cursorCircleEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= "DyBAddon" then return end
        self:UnregisterEvent("ADDON_LOADED")
        -- cursorCircle defaults to false (disabled); only show if explicitly enabled
        if DyBAddon_SavedVars and DyBAddon_SavedVars.cursorCircle == true then
            ApplySize(DyBAddon_SavedVars.cursorCircleSize or CIRCLE_SIZE_DEFAULT)
            ApplyColor(DyBAddon_SavedVars.cursorCircleColor or "white")
            if DyBAddon_SavedVars.cursorCircleOnlyCombat then
                -- Show only if a /reload happened while the player was already in combat
                if UnitAffectingCombat("player") then
                    circleFrame:Show()
                end
            else
                circleFrame:Show()
            end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat: show ring if the feature is enabled and combat-only mode is on
        if DyBAddon_SavedVars
            and DyBAddon_SavedVars.cursorCircle == true
            and DyBAddon_SavedVars.cursorCircleOnlyCombat == true then
            circleFrame:Show()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat: hide ring if combat-only mode is on
        if DyBAddon_SavedVars and DyBAddon_SavedVars.cursorCircleOnlyCombat == true then
            circleFrame:Hide()
        end
    end
end)

-- Callbacks for options -------------------------------------------------------

function DyBAddon.OnCursorCircleChanged(_, value)
    if value then
        ApplySize((DyBAddon_SavedVars and DyBAddon_SavedVars.cursorCircleSize) or CIRCLE_SIZE_DEFAULT)
        ApplyColor((DyBAddon_SavedVars and DyBAddon_SavedVars.cursorCircleColor) or "white")
        if DyBAddon_SavedVars and DyBAddon_SavedVars.cursorCircleOnlyCombat then
            -- Combat-only: only show if player is currently in combat
            if UnitAffectingCombat("player") then
                circleFrame:Show()
            end
        else
            circleFrame:Show()
        end
    else
        circleFrame:Hide()
    end
end

function DyBAddon.OnCursorCircleColorChanged(_, value)
    ApplyColor(value or "white")
end

function DyBAddon.OnCursorCircleSizeChanged(_, value)
    ApplySize(value or CIRCLE_SIZE_DEFAULT)
end

function DyBAddon.OnCursorCircleOnlyCombatChanged(_, value)
    -- Has no effect when the main feature is disabled
    if not (DyBAddon_SavedVars and DyBAddon_SavedVars.cursorCircle == true) then return end
    if value then
        -- Switching to combat-only: hide the ring unless currently in combat
        if not UnitAffectingCombat("player") then
            circleFrame:Hide()
        end
    else
        -- Switching off combat-only: show the ring immediately
        circleFrame:Show()
    end
end
