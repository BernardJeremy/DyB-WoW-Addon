local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "DyBAddon" then return end
    self:UnregisterEvent("ADDON_LOADED")

    if not DyBAddon_SavedVars then
        DyBAddon_SavedVars = {}
    end

    local category = Settings.RegisterVerticalLayoutCategory("DyBAddon")

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_ForceMilitaryTime", "forceMilitaryTime",
            DyBAddon_SavedVars, type(true),
            "Force 24-Hour Clock on Login", true)
        setting:SetValueChangedCallback(DyBAddon.OnMilitaryTimeChanged)
        Settings.CreateCheckbox(category, setting,
            "When enabled, the game clock is forced to 24-hour format on login.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_HideNpcBubbles", "hideNpcBubbles",
            DyBAddon_SavedVars, type(false),
            "Hide NPC Chat Bubbles", false)
        setting:SetValueChangedCallback(DyBAddon.OnHideBubblesChanged)
        Settings.CreateCheckbox(category, setting,
            "When enabled, all in-game chat bubbles above characters are hidden.")
    end

    Settings.RegisterAddOnCategory(category)
end)
