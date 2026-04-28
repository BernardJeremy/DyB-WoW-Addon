-- Combat Timer ----------------------------------------------------------------
-- Displays elapsed combat time (mm:ss.c) in a small movable window.
-- Resets on combat enter, freezes on combat exit.

local combatTimerStart  = nil
local combatTimerActive = false

-- Reference: https://warcraft.wiki.gg/wiki/API_CreateFrame
local combatTimerFrame = CreateFrame("Frame", "DyBCombatTimerFrame", UIParent)
combatTimerFrame:SetSize(100, 28)
combatTimerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
combatTimerFrame:SetMovable(true)
combatTimerFrame:EnableMouse(true)
combatTimerFrame:RegisterForDrag("LeftButton")
combatTimerFrame:SetClampedToScreen(true)
-- Reference: https://warcraft.wiki.gg/wiki/Making_a_draggable_frame
combatTimerFrame:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() then
        -- Allow moving only when Shift is held to prevent accidental drags during combat
        self:StartMoving()
    end
end)
combatTimerFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    if DyBAddon_SavedVars then
        DyBAddon_SavedVars.combatTimerPos = { point = point, relativePoint = relativePoint, x = x, y = y }
    end
end)

-- Black background
local combatTimerBg = combatTimerFrame:CreateTexture(nil, "BACKGROUND")
combatTimerBg:SetAllPoints()
combatTimerBg:SetColorTexture(0, 0, 0, 0.85)

-- Thin border for readability
local combatTimerBorder = CreateFrame("Frame", nil, combatTimerFrame, "BackdropTemplate")
combatTimerBorder:SetAllPoints()
combatTimerBorder:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
})
combatTimerBorder:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

-- White timer label (mm:ss.c)
local combatTimerText = combatTimerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
combatTimerText:SetPoint("CENTER")
combatTimerText:SetTextColor(1, 1, 1, 1)
combatTimerText:SetText("00:00.0")

local function FormatCombatTime(elapsed)
    local minutes = math.floor(elapsed / 60)
    local seconds = math.floor(elapsed % 60)
    local tenths  = math.floor((elapsed % 1) * 10)
    return string.format("%02d:%02d.%d", minutes, seconds, tenths)
end

combatTimerFrame:SetScript("OnUpdate", function(self, dt)
    if combatTimerActive and combatTimerStart then
        combatTimerText:SetText(FormatCombatTime(GetTime() - combatTimerStart))
    end
end)

local combatTimerEventFrame = CreateFrame("Frame")
-- Reason: Reset timer when player enters combat
combatTimerEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
-- Reason: Freeze timer when player exits combat
combatTimerEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
-- Reason: Restore saved position and respect the enabled/disabled option after SavedVariables load
combatTimerEventFrame:RegisterEvent("ADDON_LOADED")

combatTimerEventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= "DyBAddon" then return end
        self:UnregisterEvent("ADDON_LOADED")
        -- Hide frame if the option is explicitly disabled
        if DyBAddon_SavedVars and DyBAddon_SavedVars.combatTimer == false then
            combatTimerFrame:Hide()
            return
        end
        -- Restore saved position
        if DyBAddon_SavedVars and DyBAddon_SavedVars.combatTimerPos then
            local pos = DyBAddon_SavedVars.combatTimerPos
            combatTimerFrame:ClearAllPoints()
            combatTimerFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat: reset and start
        if DyBAddon_SavedVars and DyBAddon_SavedVars.combatTimer == false then return end
        combatTimerStart  = GetTime()
        combatTimerActive = true
        combatTimerText:SetText("00:00.0")
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Exiting combat: freeze display, keep last value visible
        combatTimerActive = false
    end
end)

-- Callback for options --------------------------------------------------------

function DyBAddon.OnCombatTimerChanged(_, value)
    if value then
        combatTimerFrame:Show()
    else
        combatTimerActive = false
        combatTimerFrame:Hide()
    end
end
