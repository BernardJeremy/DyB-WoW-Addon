local inspectIlvlText = nil

local function GetOrCreateInspectIlvlText()
	if inspectIlvlText then return inspectIlvlText end
	if not InspectFrame then return nil end
	inspectIlvlText = InspectFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	-- Position in the bottom-left corner of the inspect frame
	inspectIlvlText:SetPoint("BOTTOMLEFT", InspectFrame, "BOTTOMLEFT", 15, 15)
	return inspectIlvlText
end

local function UpdateInspectItemLevel()
	local text = GetOrCreateInspectIlvlText()
	if not text then return end

	-- Reference: https://warcraft.wiki.gg/wiki/API_C_PaperDollInfo.GetInspectItemLevel
	-- InspectFrame.unit is set by Blizzard to the currently inspected player's unit ID
	local unit = InspectFrame and InspectFrame.unit
	if not unit then return end
	local ilvl = C_PaperDollInfo.GetInspectItemLevel(unit)
	if ilvl and ilvl > 0 then
		text:SetText(string.format("|cFFFFD100iLvl: %.0f|r", ilvl))
		text:Show()
	else
		text:Hide()
	end
end

local inspectEventFrame = CreateFrame("Frame")
-- Reason: Update the inspect item level overlay once full inspection data is available
inspectEventFrame:RegisterEvent("INSPECT_READY")
inspectEventFrame:SetScript("OnEvent", function(self, event)
	if event == "INSPECT_READY" then
		UpdateInspectItemLevel()
	end
end)
