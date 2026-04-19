local f = CreateFrame("Frame")

f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(self, event)
    if DyBAddon_SavedVars and DyBAddon_SavedVars.hideNpcBubbles then
        SetCVar("chatBubbles", 0)
    end
end)

function DyBAddon.OnHideBubblesChanged(_, value)
    SetCVar("chatBubbles", value and 0 or 1)
end
