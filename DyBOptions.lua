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
            "Forcer le format 24 heures à la connexion", true)
        setting:SetValueChangedCallback(DyBAddon.OnMilitaryTimeChanged)
        Settings.CreateCheckbox(category, setting,
            "Lorsque activé, l'horloge du jeu est forcée au format 24 heures à la connexion.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_HideNpcBubbles", "hideNpcBubbles",
            DyBAddon_SavedVars, type(false),
            "Masquer les bulles de discussion des PNJ", false)
        setting:SetValueChangedCallback(DyBAddon.OnHideBubblesChanged)
        Settings.CreateCheckbox(category, setting,
            "Lorsque activé, toutes les bulles de discussion en jeu au-dessus des personnages sont masquées.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_GroupInspect", "groupInspect",
            DyBAddon_SavedVars, type(true),
            "Inspecter les membres du groupe", true)
        setting:SetValueChangedCallback(DyBAddon.OnGroupInspectChanged)
        Settings.CreateCheckbox(category, setting,
            "Lorsque activé, affiche les informations (race, classe, spécialisation, niveau d'objet) des nouveaux membres du groupe dans le tchat.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_GroupInspectRaid", "groupInspectRaid",
            DyBAddon_SavedVars, type(false),
            "Activer l'inspection en raid", false)
        setting:SetValueChangedCallback(DyBAddon.OnGroupInspectRaidChanged)
        Settings.CreateCheckbox(category, setting,
            "Lorsque activé, l'inspection des membres fonctionne également dans les groupes de raid.")
    end

    Settings.RegisterAddOnCategory(category)
end)
