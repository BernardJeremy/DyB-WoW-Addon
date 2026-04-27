-- DyBReadyCheckConsumables.lua
-- Shows a consumable status popup (flask / food / weapon enchant) when a ready
-- check fires while the player is inside an instance.

-- Flask buff spell IDs (Midnight 12.0.0)
-- Reference: https://warcraft.wiki.gg/wiki/API_C_UnitAuras.GetAuraDataByIndex
local FLASK_SPELL_IDS = {
    [1235057] = true, -- Flask of Thalassian Resistance (Versatility)
    [1235108] = true, -- Flask of the Magisters (Mastery)
    [1235110] = true, -- Flask of the Blood Knights (Haste)
    [1235111] = true, -- Flask of the Shattered Sun (Critical Strike)
    [1239355] = true, -- Vicious Thalassian Flask of Honor
}

-- "Well Fed" food buffs all share icon file ID 136000
local FOOD_BUFF_ICON = 136000

-- ---- Buff detection ----

local function HasFlaskBuff()
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end
        if FLASK_SPELL_IDS[aura.spellId] then return true end
    end
    return false
end

local function HasFoodBuff()
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end
        if aura.icon == FOOD_BUFF_ICON then return true end
    end
    return false
end

local function HasWeaponBuff()
    -- Reference: https://warcraft.wiki.gg/wiki/API_GetWeaponEnchantInfo
    local hasMainHandEnchant = GetWeaponEnchantInfo()
    if hasMainHandEnchant then return true end
    return false
end

-- ---- Popup UI ----

local ICON_SIZE  = 52
local ICON_PAD   = 14
local H_PAD      = 16
local TOP_BAR    = 24
local LABEL_GAP  = 4
local LABEL_H    = 14
local BOTTOM_PAD = 12

local CATEGORIES = {
    { key = "flask",  label = "Flask", icon = "Interface\\Icons\\inv_flask_red" },
    { key = "food",   label = "Food", icon = "Interface\\Icons\\spell_misc_food" },
    { key = "weapon", label = "Weapon",  icon = "Interface\\Icons\\inv_12_profession_enchanting_manaoil_purple" },
}

local FW = #CATEGORIES * ICON_SIZE + (#CATEGORIES - 1) * ICON_PAD + 2 * H_PAD
local FH = TOP_BAR + ICON_SIZE + LABEL_GAP + LABEL_H + BOTTOM_PAD

-- Reference: https://warcraft.wiki.gg/wiki/UIOBJECT_Frame
local popup = CreateFrame("Frame", "DyBReadyCheckConsumablesPopup", UIParent, "BackdropTemplate")
popup:SetSize(FW, FH)
popup:SetFrameStrata("HIGH")
popup:Hide()

popup:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
popup:SetBackdropColor(0, 0, 0, 0.85)
popup:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

-- Close button in the top-left corner
local closeBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
closeBtn:SetSize(22, 22)
closeBtn:SetPoint("TOPLEFT", popup, "TOPLEFT", 2, -2)
closeBtn:SetScript("OnClick", function() popup:Hide() end)

-- Build icon slots (one per category)
local iconSlots = {}

for i, cat in ipairs(CATEGORIES) do
    local xOff = H_PAD + (i - 1) * (ICON_SIZE + ICON_PAD)
    local yOff = -(TOP_BAR + 4)

    local slot = CreateFrame("Frame", nil, popup)
    slot:SetSize(ICON_SIZE, ICON_SIZE)
    slot:SetPoint("TOPLEFT", popup, "TOPLEFT", xOff, yOff)

    -- Category icon
    local tex = slot:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture(cat.icon)
    slot.tex = tex

    -- Green checkmark overlay (bottom-right, shown when buff is active)
    local checkTex = slot:CreateTexture(nil, "OVERLAY")
    checkTex:SetSize(26, 26)
    checkTex:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 4, -4)
    checkTex:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    checkTex:Hide()
    slot.checkTex = checkTex

    -- Red cross overlay (bottom-right, shown when buff is missing)
    local crossTex = slot:CreateTexture(nil, "OVERLAY")
    crossTex:SetSize(26, 26)
    crossTex:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 4, -4)
    crossTex:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    crossTex:Hide()
    slot.crossTex = crossTex

    -- Label beneath the icon
    local lbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOP", slot, "BOTTOM", 0, -LABEL_GAP)
    lbl:SetText(cat.label)
    lbl:SetTextColor(1, 1, 1)

    slot.key = cat.key
    iconSlots[i] = slot
end

-- Update icon visuals without repositioning (called on live buff changes)
local function RefreshIcons()
    local status = {
        flask  = HasFlaskBuff(),
        food   = HasFoodBuff(),
        weapon = HasWeaponBuff(),
    }

    for _, slot in ipairs(iconSlots) do
        local ok = status[slot.key]
        slot.tex:SetDesaturated(not ok)
        if ok then
            slot.tex:SetVertexColor(1, 1, 1, 1)
            slot.checkTex:Show()
            slot.crossTex:Hide()
        else
            slot.tex:SetVertexColor(0.45, 0.45, 0.45, 1)
            slot.checkTex:Hide()
            slot.crossTex:Show()
        end
    end
end

-- Position, fill, and show the popup
local function ShowConsumableStatus()
    -- Center horizontally; place the top of the popup at 33% from the screen top
    popup:ClearAllPoints()
    popup:SetPoint("TOP", UIParent, "TOP", 0, -(UIParent:GetHeight() * 0.33))
    RefreshIcons()
    popup:Show()
end

-- ---- Live buff tracking while the popup is visible ----
-- Register UNIT_AURA (flask / food aura changes) and PLAYER_EQUIPMENT_CHANGED
-- (weapon enchant applied/removed) only while the popup is shown, to avoid
-- unnecessary event overhead the rest of the time.

local f = CreateFrame("Frame")
-- Reason: React to ready checks to display consumable status when inside an instance
f:RegisterEvent("READY_CHECK")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "READY_CHECK" then
        if not (DyBAddon_SavedVars and DyBAddon_SavedVars.readyCheckConsumables) then return end
        local inInstance = IsInInstance()
        if not inInstance then return end
        ShowConsumableStatus()
    elseif event == "UNIT_AURA" then
        -- arg1 is the unit; only care about the local player
        if arg1 == "player" and popup:IsShown() then
            RefreshIcons()
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        -- Covers weapon-slot changes that affect GetWeaponEnchantInfo()
        if popup:IsShown() then
            RefreshIcons()
        end
    end
end)

popup:SetScript("OnShow", function()
    -- Reason: Keep icons up-to-date while the popup is visible
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
end)

popup:SetScript("OnHide", function()
    f:UnregisterEvent("UNIT_AURA")
    f:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
end)

-- Callback exposed to the options panel
function DyBAddon.OnReadyCheckConsumablesChanged(_, value)
    if not value then
        popup:Hide()
    end
end
