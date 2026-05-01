-- DyBDurability.lua
-- Displays average item durability percentage in the bottom-left corner
-- of the character frame, mirroring the inspect item level overlay position.

local L = DyBAddon.L

local durabilityText = nil

local function GetOrCreateDurabilityText()
    if durabilityText then return durabilityText end
    if not CharacterFrame then return nil end
    durabilityText = CharacterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    -- Same position as the inspect item level overlay in DybInspectItemLevel.lua
    durabilityText:SetPoint("BOTTOMLEFT", CharacterFrame, "BOTTOMLEFT", 15, 15)
    return durabilityText
end

local function GetDurabilityColor(pct)
    if pct >= 70 then
        return "|cFF00FF00"   -- green
    elseif pct >= 40 then
        return "|cFFFFD100"   -- gold / yellow
    else
        return "|cFFFF3333"   -- red
    end
end

local function UpdateDurabilityDisplay()
    local text = GetOrCreateDurabilityText()
    if not text then return end

    if DyBAddon_SavedVars and DyBAddon_SavedVars.showDurability == false then
        text:Hide()
        return
    end

    -- Only show on the main character tab (PaperDollFrame visible)
    if not PaperDollFrame or not PaperDollFrame:IsShown() then
        text:Hide()
        return
    end

    local totalCurrent, totalMax = 0, 0
    -- Reference: https://warcraft.wiki.gg/wiki/API_GetInventoryItemDurability
    -- Iterate all equipment slots; returns nil for slots that don't have durability
    for slot = 1, 17 do
        local current, max = GetInventoryItemDurability(slot)
        if current and max and max > 0 then
            totalCurrent = totalCurrent + current
            totalMax = totalMax + max
        end
    end

    if totalMax > 0 then
        local pct = math.floor((totalCurrent / totalMax) * 100 + 0.5)
        text:SetText(string.format(L["dur_display"], GetDurabilityColor(pct), pct))
        text:Show()
    else
        text:Hide()
    end
end

-- Event handling --------------------------------------------------------------

local f = CreateFrame("Frame")
-- Reason: Hook CharacterFrame.OnShow once all UI frames are initialized after login
f:RegisterEvent("PLAYER_LOGIN")
-- Reason: Refresh durability display when item durability changes (combat, death, repairs)
f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
-- Reason: Refresh durability display when the player equips or unequips an item
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        if CharacterFrame then
            CharacterFrame:HookScript("OnShow", UpdateDurabilityDisplay)
        end
        -- Hook PaperDollFrame to react to tab switches within CharacterFrame
        if PaperDollFrame then
            PaperDollFrame:HookScript("OnShow", UpdateDurabilityDisplay)
            PaperDollFrame:HookScript("OnHide", function()
                if durabilityText then durabilityText:Hide() end
            end)
        end
    elseif CharacterFrame and CharacterFrame:IsShown() then
        UpdateDurabilityDisplay()
    end
end)

-- Callback for options --------------------------------------------------------

function DyBAddon.OnShowDurabilityChanged(_, value)
    if not value and durabilityText then
        durabilityText:Hide()
    elseif value and CharacterFrame and CharacterFrame:IsShown() then
        UpdateDurabilityDisplay()
    end
end
