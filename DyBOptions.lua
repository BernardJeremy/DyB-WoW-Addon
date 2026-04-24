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
            "Masquer les bulles", false)
        setting:SetValueChangedCallback(DyBAddon.OnHideBubblesChanged)
        Settings.CreateCheckbox(category, setting,
            "Masque toutes les bulles de discussion en jeu au-dessus des personnages.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_GroupInspect", "groupInspect",
            DyBAddon_SavedVars, type(true),
            "Print les membres du groupe", true)
        setting:SetValueChangedCallback(DyBAddon.OnGroupInspectChanged)
        Settings.CreateCheckbox(category, setting,
            "Affiche les informations des nouveaux membres du groupe dans le tchat.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_GroupInspectRaid", "groupInspectRaid",
            DyBAddon_SavedVars, type(false),
            "Print inspection en raid", false)
        setting:SetValueChangedCallback(DyBAddon.OnGroupInspectRaidChanged)
        Settings.CreateCheckbox(category, setting,
            "L'inspection des membres fonctionne également dans les groupes de raid.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_MeterResetOnGroup", "meterResetOnGroup",
            DyBAddon_SavedVars, type(true),
            "Proposer RaZ (groupe)", true)
        setting:SetValueChangedCallback(DyBAddon.OnMeterResetOnGroupChanged)
        Settings.CreateCheckbox(category, setting,
            "Propose le reset du recount lorsque vous rejoignez un groupe.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_MeterResetOnInstance", "meterResetOnInstance",
            DyBAddon_SavedVars, type(true),
            "Proposer RaZ (instance)", true)
        setting:SetValueChangedCallback(DyBAddon.OnMeterResetOnInstanceChanged)
        Settings.CreateCheckbox(category, setting,
            "Propose le reset du recount à l'entrée d'une instance.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_PullTimer", "pullTimer",
            DyBAddon_SavedVars, type(true),
            "Commande /pull", true)
        setting:SetValueChangedCallback(DyBAddon.OnPullTimerChanged)
        Settings.CreateCheckbox(category, setting,
            "Active la commande /pull pour lancer un compte à rebours de pull.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_InspectItemLevel", "inspectItemLevel",
            DyBAddon_SavedVars, type(true),
            "Afficher l'iLvl à l'inspection", true)
        setting:SetValueChangedCallback(DyBAddon.OnInspectItemLevelChanged)
        Settings.CreateCheckbox(category, setting,
            "Affiche l'iLvl du joueur inspecté dans la fenêtre d'inspection.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_DecimalItemLevel", "decimalItemLevel",
            DyBAddon_SavedVars, type(true),
            "Décimales dans son iLvl", true)
        setting:SetValueChangedCallback(DyBAddon.OnDecimalItemLevelChanged)
        Settings.CreateCheckbox(category, setting,
            "Affiche votre iLvl avec deux décimales sur la fiche de personnage.")
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_ShowDurability", "showDurability",
            DyBAddon_SavedVars, type(true),
            "Afficher la durabilité", true)
        setting:SetValueChangedCallback(DyBAddon.OnShowDurabilityChanged)
        Settings.CreateCheckbox(category, setting,
            "Affiche le pourcentage de durabilité moyen des équipements sur la fiche de personnage.")
    end

    Settings.RegisterAddOnCategory(category)
end)
