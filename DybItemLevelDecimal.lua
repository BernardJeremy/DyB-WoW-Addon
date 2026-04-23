local DecimalItemLevel = {}

function DecimalItemLevel:RoundNumberWithDecimals(number, decimals)
	if not number then return nil end
    local multiplier = 10^(decimals or 0)
    return math.floor(number * multiplier + 0.5)/multiplier
end

hooksecurefunc('PaperDollFrame_SetItemLevel', function(statFrame, unit)
	if ( unit ~= "player" ) then
		statFrame:Hide()
		return
	end

	local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvP = GetAverageItemLevel()
	local minItemLevel = C_PaperDollInfo.GetMinItemLevel()
	
	avgItemLevel = DecimalItemLevel:RoundNumberWithDecimals(avgItemLevel, 2)
	avgItemLevelEquipped = DecimalItemLevel:RoundNumberWithDecimals(avgItemLevelEquipped, 2)
	avgItemLevelPvP = DecimalItemLevel:RoundNumberWithDecimals(avgItemLevelPvP, 2)
	minItemLevel = DecimalItemLevel:RoundNumberWithDecimals(minItemLevel, 2)

	local displayItemLevel = math.max(minItemLevel or 0, avgItemLevelEquipped)

	PaperDollFrame_SetLabelAndText(statFrame, STAT_AVERAGE_ITEM_LEVEL, displayItemLevel, false, displayItemLevel)
	statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_AVERAGE_ITEM_LEVEL).." "..avgItemLevel
	if ( displayItemLevel ~= avgItemLevel ) then
		statFrame.tooltip = statFrame.tooltip .. "  " .. format("(Equipped %.2f)", avgItemLevelEquipped)
	end
	statFrame.tooltip = statFrame.tooltip .. FONT_COLOR_CODE_CLOSE
	statFrame.tooltip2 = STAT_AVERAGE_ITEM_LEVEL_TOOLTIP

	if ( avgItemLevel ~= avgItemLevelPvP ) then
		statFrame.tooltip2 = statFrame.tooltip2 .. "\n\n" .. ("PvP Item Level: %.2f"):format(avgItemLevelPvP)
	end
end)
