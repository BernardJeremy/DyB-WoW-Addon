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
            "Forcer le format 24 heures", true)
        setting:SetValueChangedCallback(DyBAddon.OnMilitaryTimeChanged)
        Settings.CreateCheckbox(category, setting,
            "Force l'horloge du jeu au format 24 heures à la connexion.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_HideNpcBubbles", "hideNpcBubbles",
            DyBAddon_SavedVars, type(false),
            "Masquer les bulles de discussion", false)
        setting:SetValueChangedCallback(DyBAddon.OnHideBubblesChanged)
        Settings.CreateCheckbox(category, setting,
            "Masque toutes les bulles de discussion en jeu au-dessus des personnages.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_GroupInspect", "groupInspect",
            DyBAddon_SavedVars, type(true),
            "Inspecter les membres du groupe", true)
        setting:SetValueChangedCallback(DyBAddon.OnGroupInspectChanged)
        Settings.CreateCheckbox(category, setting,
            "Affiche les informations des nouveaux membres du groupe dans le tchat.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_GroupInspectRaid", "groupInspectRaid",
            DyBAddon_SavedVars, type(false),
            "Activer l'inspection en raid", false)
        setting:SetValueChangedCallback(DyBAddon.OnGroupInspectRaidChanged)
        Settings.CreateCheckbox(category, setting,
            "L'inspection des membres fonctionne également dans les groupes de raid.")
    end

    Settings.RegisterAddOnCategory(category)
end)
