local f = CreateFrame("Frame")

f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(self, event)
    if DyBAddon_SavedVars and DyBAddon_SavedVars.forceMilitaryTime then
        SetCVar("timeMgrUseMilitaryTime", 1)
    end
end)

function DyBAddon.OnMilitaryTimeChanged(_, value)
    SetCVar("timeMgrUseMilitaryTime", value and 1 or 0)
end