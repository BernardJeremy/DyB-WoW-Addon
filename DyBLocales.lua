-- DyBLocales.lua
-- Provides DyBAddon.L, a flat key→string table.
-- English is the default; French (frFR) strings override the keys below.
-- Any locale that is not frFR falls back to English automatically.
--
-- Reference: https://warcraft.wiki.gg/wiki/API_GetLocale

local L = {}
DyBAddon.L = L

-- ============================================================
-- English (default for all non-frFR locales)
-- ============================================================

-- Options panel – category names
L["opt_category_inspect"]              = "Inspection"
L["opt_category_char"]                 = "Character Sheet"
L["opt_category_meter"]                = "Damage Meter"
L["opt_category_buff"]                 = "Buff Checker"

-- Options panel – labels and tooltips
L["opt_military_time_label"]           = "Force 24-Hour Clock"
L["opt_military_time_tooltip"]         = "Forces the in-game clock to 24-hour format on login."

L["opt_hide_bubbles_label"]            = "Hide Chat Bubbles"
L["opt_hide_bubbles_tooltip"]          = "Hides all in-game chat bubbles above characters."

L["opt_combat_timer_label"]            = "Combat Timer"
L["opt_combat_timer_tooltip"]          = "Displays a movable timer showing elapsed combat time. Shift + Left Click to move."

L["opt_group_inspect_label"]           = "Print Group Members"
L["opt_group_inspect_tooltip"]         = "Prints new group members' info to chat."

L["opt_group_inspect_raid_label"]      = "Inspect in Raids"
L["opt_group_inspect_raid_tooltip"]    = "Inspection also runs inside raid groups."

L["opt_inspect_ilvl_label"]            = "Show iLvl on Inspect"
L["opt_inspect_ilvl_tooltip"]          = "Shows the inspected player's iLvl in the inspect frame."

L["opt_decimal_ilvl_label"]            = "Decimal Item Level"
L["opt_decimal_ilvl_tooltip"]          = "Shows your item level with two decimals on the character sheet."

L["opt_durability_label"]              = "Show Durability"
L["opt_durability_tooltip"]            = "Shows the average equipment durability percentage on the character sheet."

L["opt_meter_reset_group_label"]       = "Offer Reset (Group)"
L["opt_meter_reset_group_tooltip"]     = "Prompts to reset the damage meter when joining a group."

L["opt_meter_reset_instance_label"]    = "Offer Reset (Instance)"
L["opt_meter_reset_instance_tooltip"]  = "Prompts to reset the damage meter when entering an instance."

L["opt_ready_check_label"]             = "Buff Check (Ready)"
L["opt_ready_check_tooltip"]           = "Shows a consumable and class buff summary when a ready check fires in an instance."

L["opt_minimap_btn_label"]             = "Buff Check (Minimap)"
L["opt_minimap_btn_tooltip"]           = "Shows a consumable and class buff summary via a minimap button."

-- Group Inspector
L["gi_not_in_group"]                   = "You are not in any group."
L["gi_no_members"]                     = "No members to inspect."
L["gi_ilvl"]                           = "iLvl %s"

-- Meter Reset dialog
L["mr_dialog_text"]                    = "Do you want to reset combat meters?"
L["mr_dialog_yes"]                     = "Yes"
L["mr_dialog_no"]                      = "No"
L["mr_reset_done"]                     = "Combat meters reset."

-- Durability display
L["dur_display"]                       = "Durability: %s%d%%|r"

-- Ready Check Consumables – popup labels
L["rcc_cat_flask"]                     = "Flask"
L["rcc_cat_food"]                      = "Food"
L["rcc_cat_weapon"]                    = "Weapon"
L["rcc_minimap_tooltip"]               = "DyBAddon - Buff Checker"

-- Item level decimal – tooltip additions
L["ilvl_equipped_tooltip"]             = "(Equipped %.2f)"
L["ilvl_pvp_tooltip"]                  = "PvP Item Level: %.2f"

-- ============================================================
-- French overrides (frFR)
-- ============================================================

if GetLocale() == "frFR" then

    -- Options panel – category names
    L["opt_category_inspect"]              = "Inspection"
    L["opt_category_char"]                 = "Fiche perso"
    L["opt_category_meter"]                = "Compteur de dégâts"
    L["opt_category_buff"]                 = "Buff Checker"

    -- Options panel – labels and tooltips
    L["opt_military_time_label"]           = "Horloge 24 heures"
    L["opt_military_time_tooltip"]         = "Force l'horloge du jeu au format 24 heures à la connexion."

    L["opt_hide_bubbles_label"]            = "Masquer les bulles"
    L["opt_hide_bubbles_tooltip"]          = "Masque toutes les bulles de discussion en jeu au-dessus des personnages."

    L["opt_combat_timer_label"]            = "Chrono de combat"
    L["opt_combat_timer_tooltip"]          = "Affiche un chrono déplaçable affichant le temps écoulé en combat. Shift + Click gauche pour déplacer."

    L["opt_group_inspect_label"]           = "Print les membres du groupe"
    L["opt_group_inspect_tooltip"]         = "Affiche les informations des nouveaux membres du groupe dans le tchat."

    L["opt_group_inspect_raid_label"]      = "Print inspection en raid"
    L["opt_group_inspect_raid_tooltip"]    = "L'inspection des membres fonctionne également dans les groupes de raid."

    L["opt_inspect_ilvl_label"]            = "Afficher l'iLvl à l'inspection"
    L["opt_inspect_ilvl_tooltip"]          = "Affiche l'iLvl du joueur inspecté dans la fenêtre d'inspection."

    L["opt_decimal_ilvl_label"]            = "Décimales dans son iLvl"
    L["opt_decimal_ilvl_tooltip"]          = "Affiche votre iLvl avec deux décimales sur la fiche de personnage."

    L["opt_durability_label"]              = "Afficher la durabilité"
    L["opt_durability_tooltip"]            = "Affiche le pourcentage de durabilité moyen des équipements sur la fiche de personnage."

    L["opt_meter_reset_group_label"]       = "Proposer RaZ (groupe)"
    L["opt_meter_reset_group_tooltip"]     = "Propose le reset du recount lorsque vous rejoignez un groupe."

    L["opt_meter_reset_instance_label"]    = "Proposer RaZ (instance)"
    L["opt_meter_reset_instance_tooltip"]  = "Propose le reset du recount à l'entrée d'une instance."

    L["opt_ready_check_label"]             = "Check buff (Ready)"
    L["opt_ready_check_tooltip"]           = "Affiche un résumé des consommables et des buff de classes lors d'un ready check en instance."

    L["opt_minimap_btn_label"]             = "Check buff (Minimap)"
    L["opt_minimap_btn_tooltip"]           = "Affiche un résumé des consommables et des buff de classes via un bouton sur la minimap."

    -- Group Inspector
    L["gi_not_in_group"]                   = "Vous n'êtes dans aucun groupe."
    L["gi_no_members"]                     = "Aucun membre à inspecter."
    L["gi_ilvl"]                           = "iLvl %s"

    -- Meter Reset dialog
    L["mr_dialog_text"]                    = "Voulez-vous réinitialiser les compteurs de combat ?"
    L["mr_dialog_yes"]                     = "Oui"
    L["mr_dialog_no"]                      = "Non"
    L["mr_reset_done"]                     = "Compteurs de combat réinitialisés."

    -- Durability display
    L["dur_display"]                       = "Durabilité : %s%d%%|r"

    -- Ready Check Consumables – popup labels
    L["rcc_cat_flask"]                     = "Flask"
    L["rcc_cat_food"]                      = "Food"
    L["rcc_cat_weapon"]                    = "Weapon"
    L["rcc_minimap_tooltip"]               = "DyBAddon - Buff Checker"

    -- Item level decimal – tooltip additions
    L["ilvl_equipped_tooltip"]             = "(Équipé %.2f)"
    L["ilvl_pvp_tooltip"]                  = "iLvl PvP : %.2f"
end
