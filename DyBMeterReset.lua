local ADDON_PREFIX = "|cFFFFD100[DyBAddon]|r "

-- Reference: https://warcraft.wiki.gg/wiki/API_C_DamageMeter.ResetAllCombatSessions
-- Reference: https://warcraft.wiki.gg/wiki/API_StaticPopup_Show

StaticPopupDialogs["DYBADDON_RESET_METER"] = {
    text = "Voulez-vous réinitialiser les compteurs de combat ?",
    button1 = "Oui",
    button2 = "Non",
    OnAccept = function()
        C_DamageMeter.ResetAllCombatSessions()
        print(ADDON_PREFIX .. "Compteurs de combat réinitialisés.")
    end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

local wasInGroup = false

local f = CreateFrame("Frame")

-- Reason: Initialise wasInGroup after the player enters the world
f:RegisterEvent("PLAYER_LOGIN")
-- Reason: Detect when the player newly joins a group to offer a meter reset
f:RegisterEvent("GROUP_ROSTER_UPDATE")
-- Reason: Detect when the player enters an instance to offer a meter reset
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        wasInGroup = IsInGroup()

    elseif event == "GROUP_ROSTER_UPDATE" then
        local inGroup = IsInGroup()
        if not wasInGroup and inGroup then
            if DyBAddon_SavedVars and DyBAddon_SavedVars.meterResetOnGroup then
                StaticPopup_Show("DYBADDON_RESET_METER")
            end
        end
        wasInGroup = inGroup

    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        -- Skip login and UI reloads; only react to actual zone transitions
        if isInitialLogin or isReloadingUi then return end
        local inInstance = IsInInstance()
        if inInstance and DyBAddon_SavedVars and DyBAddon_SavedVars.meterResetOnInstance then
            StaticPopup_Show("DYBADDON_RESET_METER")
        end
    end
end)

-- Callbacks for options -------------------------------------------------------

function DyBAddon.OnMeterResetOnGroupChanged(_, value)
    -- Takes effect on next group join
end

function DyBAddon.OnMeterResetOnInstanceChanged(_, value)
    -- Takes effect on next instance entry
end
