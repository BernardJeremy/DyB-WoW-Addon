local ADDON_PREFIX = "|cFFFFD100[DyBAddon]|r "

-- Reference: https://warcraft.wiki.gg/wiki/API_C_PartyInfo.DoCountdown

local function CanTriggerCountdown()
    -- Allow when not in a group (solo use)
    if not IsInGroup() then return true end
    -- Allow for party/raid leader
    if UnitIsGroupLeader("player") then return true end
    -- Allow for raid assistant (co-leader)
    -- Reference: https://warcraft.wiki.gg/wiki/API_UnitIsRaidOfficer
    if UnitIsRaidOfficer("player") then return true end
    return false
end

local function RegisterPullCommand()
    SLASH_DYBPULL1 = "/pull"
    SlashCmdList["DYBPULL"] = function(msg)
        local trimmed = msg and msg:match("^%s*(.-)%s*$") or ""

        if trimmed == "" then
            print(ADDON_PREFIX .. "Usage: /pull <secondes> — Lance le compte à rebours de pull. Utilisez 0 pour annuler.")
            return
        end

        local seconds = tonumber(trimmed)
        if not seconds or seconds ~= math.floor(seconds) or seconds < 0 then
            print(ADDON_PREFIX .. "|cFFFF0000Erreur :|r Paramètre invalide. Utilisez un nombre entier positif (ex: /pull 5) ou 0 pour annuler.")
            return
        end

        if not CanTriggerCountdown() then
            print(ADDON_PREFIX .. "|cFFFF0000Erreur :|r Vous devez être chef de groupe, chef de raid ou officier de raid pour lancer le compte à rebours.")
            return
        end

        -- Reference: https://warcraft.wiki.gg/wiki/API_C_PartyInfo.DoCountdown
        C_PartyInfo.DoCountdown(seconds)

        if seconds == 0 then
            print(ADDON_PREFIX .. "Compte à rebours de pull annulé.")
        else
            print(ADDON_PREFIX .. "Compte à rebours de pull lancé : " .. seconds .. " seconde" .. (seconds > 1 and "s" or "") .. ".")
        end
    end
end

local pullTimerInitFrame = CreateFrame("Frame")
-- Reason: SavedVariables are available at ADDON_LOADED; only register /pull if the option is enabled
pullTimerInitFrame:RegisterEvent("ADDON_LOADED")
pullTimerInitFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "DyBAddon" then return end
    self:UnregisterEvent("ADDON_LOADED")
    -- Default to true if the key is absent (first load before Options initialises defaults)
    if DyBAddon_SavedVars and DyBAddon_SavedVars.pullTimer == false then return end
    RegisterPullCommand()
end)

-- Callback for options --------------------------------------------------------

function DyBAddon.OnPullTimerChanged(_, value)
    -- The /pull command is registered at load time; a /reload is required for changes to take effect
    print(ADDON_PREFIX .. "Le changement de cette option prendra effet au prochain chargement de l'interface (/reload).")
end
