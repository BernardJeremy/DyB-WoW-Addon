local L = DyBAddon.L

local f = CreateFrame("Frame")

f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "DyBAddon" then return end
    self:UnregisterEvent("ADDON_LOADED")

    if not DyBAddon_SavedVars then
        DyBAddon_SavedVars = {}
    end

    -- Reference: https://warcraft.wiki.gg/wiki/Settings_API
    local category = Settings.RegisterVerticalLayoutCategory("DyBAddon")

    -- -------------------------------------------------------------------------
    -- General (root)
    -- -------------------------------------------------------------------------

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_ForceMilitaryTime", "forceMilitaryTime",
            DyBAddon_SavedVars, type(true),
            L["opt_military_time_label"], true)
        setting:SetValueChangedCallback(DyBAddon.OnMilitaryTimeChanged)
        Settings.CreateCheckbox(category, setting, L["opt_military_time_tooltip"])
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_HideNpcBubbles", "hideNpcBubbles",
            DyBAddon_SavedVars, type(false),
            L["opt_hide_bubbles_label"], false)
        setting:SetValueChangedCallback(DyBAddon.OnHideBubblesChanged)
        Settings.CreateCheckbox(category, setting, L["opt_hide_bubbles_tooltip"])
    end

    do
        local setting = Settings.RegisterAddOnSetting(category,
            "DyBAddon_CombatTimer", "combatTimer",
            DyBAddon_SavedVars, type(true),
            L["opt_combat_timer_label"], true)
        setting:SetValueChangedCallback(DyBAddon.OnCombatTimerChanged)
        Settings.CreateCheckbox(category, setting, L["opt_combat_timer_tooltip"])
    end

    -- -------------------------------------------------------------------------
    -- Inspection
    -- -------------------------------------------------------------------------
    local catInspect = Settings.RegisterVerticalLayoutSubcategory(category, L["opt_category_inspect"])

    do
        local setting = Settings.RegisterAddOnSetting(catInspect,
            "DyBAddon_GroupInspect", "groupInspect",
            DyBAddon_SavedVars, type(true),
            L["opt_group_inspect_label"], true)
        setting:SetValueChangedCallback(DyBAddon.OnGroupInspectChanged)
        Settings.CreateCheckbox(catInspect, setting, L["opt_group_inspect_tooltip"])
    end

    do
        local setting = Settings.RegisterAddOnSetting(catInspect,
            "DyBAddon_GroupInspectRaid", "groupInspectRaid",
            DyBAddon_SavedVars, type(false),
            L["opt_group_inspect_raid_label"], false)
        setting:SetValueChangedCallback(DyBAddon.OnGroupInspectRaidChanged)
        Settings.CreateCheckbox(catInspect, setting, L["opt_group_inspect_raid_tooltip"])
    end

    do
        local setting = Settings.RegisterAddOnSetting(catInspect,
            "DyBAddon_InspectItemLevel", "inspectItemLevel",
            DyBAddon_SavedVars, type(true),
            L["opt_inspect_ilvl_label"], true)
        setting:SetValueChangedCallback(DyBAddon.OnInspectItemLevelChanged)
        Settings.CreateCheckbox(catInspect, setting, L["opt_inspect_ilvl_tooltip"])
    end

    -- -------------------------------------------------------------------------
    -- Character Sheet
    -- -------------------------------------------------------------------------
    local catChar = Settings.RegisterVerticalLayoutSubcategory(category, L["opt_category_char"])

    do
        local setting = Settings.RegisterAddOnSetting(catChar,
            "DyBAddon_DecimalItemLevel", "decimalItemLevel",
            DyBAddon_SavedVars, type(true),
            L["opt_decimal_ilvl_label"], true)
        setting:SetValueChangedCallback(DyBAddon.OnDecimalItemLevelChanged)
        Settings.CreateCheckbox(catChar, setting, L["opt_decimal_ilvl_tooltip"])
    end

    do
        local setting = Settings.RegisterAddOnSetting(catChar,
            "DyBAddon_ShowDurability", "showDurability",
            DyBAddon_SavedVars, type(true),
            L["opt_durability_label"], true)
        setting:SetValueChangedCallback(DyBAddon.OnShowDurabilityChanged)
        Settings.CreateCheckbox(catChar, setting, L["opt_durability_tooltip"])
    end

    -- -------------------------------------------------------------------------
    -- Damage Meter
    -- -------------------------------------------------------------------------
    local catMeter = Settings.RegisterVerticalLayoutSubcategory(category, L["opt_category_meter"])

    do
        local setting = Settings.RegisterAddOnSetting(catMeter,
            "DyBAddon_MeterResetOnGroup", "meterResetOnGroup",
            DyBAddon_SavedVars, type(true),
            L["opt_meter_reset_group_label"], true)
        setting:SetValueChangedCallback(DyBAddon.OnMeterResetOnGroupChanged)
        Settings.CreateCheckbox(catMeter, setting, L["opt_meter_reset_group_tooltip"])
    end

    do
        local setting = Settings.RegisterAddOnSetting(catMeter,
            "DyBAddon_MeterResetOnInstance", "meterResetOnInstance",
            DyBAddon_SavedVars, type(true),
            L["opt_meter_reset_instance_label"], true)
        setting:SetValueChangedCallback(DyBAddon.OnMeterResetOnInstanceChanged)
        Settings.CreateCheckbox(catMeter, setting, L["opt_meter_reset_instance_tooltip"])
    end

    -- -------------------------------------------------------------------------
    -- Buff Checker
    -- -------------------------------------------------------------------------
    local catBuff = Settings.RegisterVerticalLayoutSubcategory(category, L["opt_category_buff"])

    do
        local setting = Settings.RegisterAddOnSetting(catBuff,
            "DyBAddon_ReadyCheckConsumables", "readyCheckConsumables",
            DyBAddon_SavedVars, type(true),
            L["opt_ready_check_label"], true)
        setting:SetValueChangedCallback(DyBAddon.OnReadyCheckConsumablesChanged)
        Settings.CreateCheckbox(catBuff, setting, L["opt_ready_check_tooltip"])
    end

    do
        local setting = Settings.RegisterAddOnSetting(catBuff,
            "DyBAddon_MinimapReadyCheckConsumables", "minimapReadyCheckConsumables",
            DyBAddon_SavedVars, type(true),
            L["opt_minimap_btn_label"], true)
        setting:SetValueChangedCallback(DyBAddon.OnMinimapReadyCheckConsumablesChanged)
        Settings.CreateCheckbox(catBuff, setting, L["opt_minimap_btn_tooltip"])
    end

    -- -------------------------------------------------------------------------
    -- Cursor Circle
    -- -------------------------------------------------------------------------
    local catCursor = Settings.RegisterVerticalLayoutSubcategory(category, L["opt_cursor_circle_category"])

    do
        local setting = Settings.RegisterAddOnSetting(catCursor,
            "DyBAddon_CursorCircle", "cursorCircle",
            DyBAddon_SavedVars, type(false),
            L["opt_cursor_circle_label"], false)
        setting:SetValueChangedCallback(DyBAddon.OnCursorCircleChanged)
        Settings.CreateCheckbox(catCursor, setting, L["opt_cursor_circle_tooltip"])
    end

    do
        local function GetCursorCircleColorOptions()
            local container = Settings.CreateControlTextContainer()
            container:Add("white",  L["cursor_circle_color_white"])
            container:Add("red",    L["cursor_circle_color_red"])
            container:Add("green",  L["cursor_circle_color_green"])
            container:Add("blue",   L["cursor_circle_color_blue"])
            container:Add("yellow", L["cursor_circle_color_yellow"])
            container:Add("purple", L["cursor_circle_color_purple"])
            container:Add("cyan",   L["cursor_circle_color_cyan"])
            container:Add("orange", L["cursor_circle_color_orange"])
            return container:GetData()
        end

        local setting = Settings.RegisterAddOnSetting(catCursor,
            "DyBAddon_CursorCircleColor", "cursorCircleColor",
            DyBAddon_SavedVars, type(""),
            L["opt_cursor_circle_color_label"], "white")
        setting:SetValueChangedCallback(DyBAddon.OnCursorCircleColorChanged)
        Settings.CreateDropdown(catCursor, setting, GetCursorCircleColorOptions,
            L["opt_cursor_circle_color_tooltip"])
    end

    do
        local setting = Settings.RegisterAddOnSetting(catCursor,
            "DyBAddon_CursorCircleSize", "cursorCircleSize",
            DyBAddon_SavedVars, type(1),
            L["opt_cursor_circle_size_label"], 96)
        setting:SetValueChangedCallback(DyBAddon.OnCursorCircleSizeChanged)
        -- Reference: https://warcraft.wiki.gg/wiki/Settings_API
        local options = Settings.CreateSliderOptions(32, 128, 8)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right,
            function(value) return value .. " px" end)
        Settings.CreateSlider(catCursor, setting, options,
            L["opt_cursor_circle_size_tooltip"])
    end

    do
        local setting = Settings.RegisterAddOnSetting(catCursor,
            "DyBAddon_CursorCircleOnlyCombat", "cursorCircleOnlyCombat",
            DyBAddon_SavedVars, type(false),
            L["opt_cursor_circle_combat_label"], false)
        setting:SetValueChangedCallback(DyBAddon.OnCursorCircleOnlyCombatChanged)
        Settings.CreateCheckbox(catCursor, setting, L["opt_cursor_circle_combat_tooltip"])
    end

    Settings.RegisterAddOnCategory(category)
end)
