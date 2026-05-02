-- DyBReadyCheckConsumables.lua
-- Shows a consumable status popup (flask / food / weapon enchant) when a ready
-- check fires while the player is inside an instance.

local L = DyBAddon.L

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

local SPELLS_TO_TRACK = {
    {
        spellID = { 1459, 432778 },
        key = "intellect",
        name = "Intelligence des Arcanes",
        class = "MAGE",
        levelRequired = 8,
        icon = "Interface\\Icons\\spell_holy_magicalsentry",
    },
    { 
        spellID = { 6673 },
        key = "attackPower",
        name = "Cri de guerre",
        class = "WARRIOR",
        levelRequired = 10,
        icon = "Interface\\Icons\\ability_warrior_battleshout",
    },
    {
        spellID = {
            381732,
            381741,
            381746,
            381748,
            381749,
            381750,
            381751,
            381752,
            381753,
            381754,
            381756,
            381757,
            381758,
        },
        key = "bronze",
        name = "Bénédiction du bronze",
        class = "EVOKER",
        levelRequired = 30,
        icon = "Interface\\Icons\\ability_evoker_blessingofthebronze",
    },
    {
        spellID = { 1126, 432661 },
        key = "versatility",
        name = "Marque du fauve",
        class = "DRUID",
        icon = "Interface\\Icons\\spell_nature_regeneration",
        levelRequired = 10,
    }, -- 432661 = NPC version
    {
        spellID = { 21562 },
        key = "stamina",
        name = "Mot de pouvoir : Robustesse",
        class = "PRIEST",
        levelRequired = 10,
        icon = "Interface\\Icons\\spell_holy_wordfortitude",
    },
    {
        spellID = { 462854 },
        key = "skyfury",
        name = "Fureur-du-ciel",
        class = "SHAMAN",
        levelRequired = 16,
        icon = "Interface\\Icons\\achievement_raidprimalist_windelemental",
    },
}

local function FormatTimeRemaining(seconds)
    if not seconds or seconds <= 0 then return nil end
    if seconds > 3600 then
        return "1h+"
    elseif seconds >= 60 then
        return math.floor(seconds / 60) .. "m"
    else
        return math.floor(seconds) .. "s"
    end
end

-- ---- Buff detection ----

local function HasSpecificBuff(targetSpellID)
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end
        if aura.spellId == targetSpellID then
            local remaining = (aura.expirationTime and aura.expirationTime > 0)
                and (aura.expirationTime - GetTime()) or 0
            return true, remaining
        end
    end
    return false, 0
end

local function HasFlaskBuff()
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end
        if FLASK_SPELL_IDS[aura.spellId] then
            local remaining = (aura.expirationTime and aura.expirationTime > 0)
                and (aura.expirationTime - GetTime()) or 0
            return true, remaining
        end
    end
    return false, 0
end

local function HasFoodBuff()
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end
        if aura.icon == FOOD_BUFF_ICON then
            local remaining = (aura.expirationTime and aura.expirationTime > 0)
                and (aura.expirationTime - GetTime()) or 0
            return true, remaining
        end
    end
    return false, 0
end

local function HasWeaponBuff()
    -- Reference: https://warcraft.wiki.gg/wiki/API_GetWeaponEnchantInfo
    local hasMainHandEnchant, mainHandExpiration = GetWeaponEnchantInfo()
    if hasMainHandEnchant then
        -- mainHandExpiration is in milliseconds
        return true, (mainHandExpiration or 0) / 1000
    end
    return false, 0
end

local classInGroup = {}

local function GetNeededSpellData()
    local needed = {}
    for _, spellInfo in ipairs(SPELLS_TO_TRACK) do
        local classLevel = classInGroup[spellInfo.class]
        if classLevel and classLevel >= spellInfo.levelRequired then
            table.insert(needed, spellInfo)
        end
    end
    return needed
end

local function GetBuffStatus()
    local neededSpells = GetNeededSpellData()
    local status = {}
    for _, spellInfo in ipairs(neededSpells) do
        status[spellInfo.key] = { active = false, remaining = 0 }
        for _, spellID in ipairs(spellInfo.spellID) do
            local found, remaining = HasSpecificBuff(spellID)
            if found then
                status[spellInfo.key] = { active = true, remaining = remaining }
                break
            end
        end
    end
    return status
end

local function IsValidGroupMember(unit)
    local isValid = UnitExists(unit)
        and UnitIsConnected(unit)
        and UnitCanAssist("player", unit)
    return isValid
end

local function GetGroupMembers()
    local numGroupMembers = GetNumGroupMembers()
    wipe(classInGroup)
    if numGroupMembers > 0 then
        for i = 1, numGroupMembers do
            local unit
            if IsInRaid() then
                unit = "raid" .. i
            else
                if i == 1 then
                    unit = "player"
                else
                    unit = "party" .. (i - 1)
                end
            end
            if IsValidGroupMember(unit) then
                local _, class = UnitClass(unit)
                local level = UnitLevel(unit)
                if not classInGroup[class] or classInGroup[class] < level then
                    classInGroup[class] = level
                end
            end
        end
    else
        -- Solo player; treat self as the only group member
        if IsValidGroupMember("player") then
            local _, class = UnitClass("player")
            local level = UnitLevel("player")
            if not classInGroup[class] or classInGroup[class] < level then
                classInGroup[class] = level
            end
        end
    end
    return classInGroup
end

-- ---- Popup UI ----

local ICON_SIZE  = 52
local ICON_PAD   = 14
local H_PAD      = 16
local TOP_BAR    = 24
local LABEL_GAP  = 4
local LABEL_H    = 14
local BOTTOM_PAD = 12
local ROW_GAP    = 10

local CATEGORIES = {
    { key = "flask",  label = L["rcc_cat_flask"],  icon = "Interface\\Icons\\inv_flask_red" },
    { key = "food",   label = L["rcc_cat_food"],   icon = "Interface\\Icons\\spell_misc_food" },
    { key = "weapon", label = L["rcc_cat_weapon"],  icon = "Interface\\Icons\\inv_12_profession_enchanting_manaoil_purple" },
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

popup:SetMovable(true)
popup:EnableMouse(true)
popup:RegisterForDrag("LeftButton")

popup:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

popup:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if DyBAddon_SavedVars then
        local point, _, _, x, y = self:GetPoint()
        DyBAddon_SavedVars.rccPopupPoint = { point = point, x = x, y = y }
    end
end)

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

    slot.lbl = lbl
    slot.originalLabel = cat.label
    slot.key = cat.key
    iconSlots[i] = slot
end

-- Build class buff icon slots (one per SPELLS_TO_TRACK entry, shown/positioned dynamically)
local classIconSlotByKey = {}

for _, spellInfo in ipairs(SPELLS_TO_TRACK) do
    local slot = CreateFrame("Frame", nil, popup)
    slot:SetSize(ICON_SIZE, ICON_SIZE)

    local tex = slot:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture(spellInfo.icon)
    slot.tex = tex

    local checkTex = slot:CreateTexture(nil, "OVERLAY")
    checkTex:SetSize(26, 26)
    checkTex:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 4, -4)
    checkTex:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    checkTex:Hide()
    slot.checkTex = checkTex

    local crossTex = slot:CreateTexture(nil, "OVERLAY")
    crossTex:SetSize(26, 26)
    crossTex:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 4, -4)
    crossTex:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    crossTex:Hide()
    slot.crossTex = crossTex

    -- Use the class name as a short label (e.g. "Mage", "Warrior")
    local classLabel = spellInfo.class:sub(1, 1):upper() .. spellInfo.class:sub(2):lower()
    local lbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOP", slot, "BOTTOM", 0, -LABEL_GAP)
    lbl:SetText(classLabel)
    lbl:SetTextColor(1, 1, 1)
    slot.lbl = lbl
    slot.originalLabel = classLabel

    slot.key = spellInfo.key
    slot:Hide()
    lbl:Hide()

    classIconSlotByKey[spellInfo.key] = slot
end

-- Resize the popup and position class buff slots based on the current group composition
local function UpdatePopupLayout()
    local neededSpells = GetNeededSpellData()
    local numClassBuffs = #neededSpells
    local numCols = math.max(#CATEGORIES, numClassBuffs)

    local newFW = numCols * ICON_SIZE + (numCols - 1) * ICON_PAD + 2 * H_PAD
    local newFH = TOP_BAR + ICON_SIZE + LABEL_GAP + LABEL_H + BOTTOM_PAD
    if numClassBuffs > 0 then
        newFH = newFH + ROW_GAP + ICON_SIZE + LABEL_GAP + LABEL_H
    end
    popup:SetSize(newFW, newFH)

    -- Center the consumable row within the (possibly wider) popup
    local consumableRowWidth = #CATEGORIES * ICON_SIZE + (#CATEGORIES - 1) * ICON_PAD
    local consumableStartX = (newFW - consumableRowWidth) / 2
    for i, slot in ipairs(iconSlots) do
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", popup, "TOPLEFT", consumableStartX + (i - 1) * (ICON_SIZE + ICON_PAD), -(TOP_BAR + 4))
    end

    -- Hide all class buff slots first
    for _, slot in pairs(classIconSlotByKey) do
        slot:Hide()
        slot.lbl:Hide()
    end

    -- Position and show the slots for classes present in the group (centered)
    local classRowWidth = numClassBuffs * ICON_SIZE + (numClassBuffs - 1) * ICON_PAD
    local classStartX = (newFW - classRowWidth) / 2
    local classRow_yOff = -(TOP_BAR + 4 + ICON_SIZE + LABEL_GAP + LABEL_H + ROW_GAP)
    for idx, spellInfo in ipairs(neededSpells) do
        local slot = classIconSlotByKey[spellInfo.key]
        local xOff = classStartX + (idx - 1) * (ICON_SIZE + ICON_PAD)
        slot:ClearAllPoints()
        slot:SetPoint("TOPLEFT", popup, "TOPLEFT", xOff, classRow_yOff)
        slot:Show()
        slot.lbl:Show()
    end
end

-- Update icon visuals without repositioning (called on live buff changes)
local function RefreshIcons()
    local flaskOk,  flaskTime  = HasFlaskBuff()
    local foodOk,   foodTime   = HasFoodBuff()
    local weaponOk, weaponTime = HasWeaponBuff()
    local consumableStatus = {
        flask  = { active = flaskOk,  remaining = flaskTime },
        food   = { active = foodOk,   remaining = foodTime },
        weapon = { active = weaponOk, remaining = weaponTime },
    }

    for _, slot in ipairs(iconSlots) do
        local s = consumableStatus[slot.key]
        local ok = s.active
        slot.tex:SetDesaturated(not ok)
        if ok then
            slot.tex:SetVertexColor(1, 1, 1, 1)
            slot.checkTex:Show()
            slot.crossTex:Hide()
            slot.lbl:SetText(FormatTimeRemaining(s.remaining) or slot.originalLabel)
        else
            slot.tex:SetVertexColor(0.45, 0.45, 0.45, 1)
            slot.checkTex:Hide()
            slot.crossTex:Show()
            slot.lbl:SetText(slot.originalLabel)
        end
    end

    -- Class buff slots
    local buffStatus = GetBuffStatus()
    for _, slot in pairs(classIconSlotByKey) do
        if slot:IsShown() then
            local s = buffStatus[slot.key]
            local ok = s and s.active
            slot.tex:SetDesaturated(not ok)
            if ok then
                slot.tex:SetVertexColor(1, 1, 1, 1)
                slot.checkTex:Show()
                slot.crossTex:Hide()
                slot.lbl:SetText(FormatTimeRemaining(s.remaining) or slot.originalLabel)
            else
                slot.tex:SetVertexColor(0.45, 0.45, 0.45, 1)
                slot.checkTex:Hide()
                slot.crossTex:Show()
                slot.lbl:SetText(slot.originalLabel)
            end
        end
    end
end

-- Position, fill, and show the popup
local function ShowConsumableStatus()
    popup:ClearAllPoints()
    local saved = DyBAddon_SavedVars and DyBAddon_SavedVars.rccPopupPoint
    if saved then
        popup:SetPoint(saved.point, UIParent, saved.point, saved.x, saved.y)
    else
        -- Default: center horizontally, top at 33% from the screen top
        popup:SetPoint("TOP", UIParent, "TOP", 0, -(UIParent:GetHeight() * 0.33))
    end
    GetGroupMembers()
    UpdatePopupLayout()
    RefreshIcons()
    popup:Show()
end

-- ---- Minimap Button ----

local MINIMAP_BUTTON_SIZE = 16

-- Reference: https://warcraft.wiki.gg/wiki/UIOBJECT_Button
local minimapBtn = CreateFrame("Button", "DyBBuffCheckMinimapBtn", Minimap)
minimapBtn:SetSize(MINIMAP_BUTTON_SIZE, MINIMAP_BUTTON_SIZE)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:SetClampedToScreen(false)

-- Circular border ring slightly larger than the icon
local mmRing = minimapBtn:CreateTexture(nil, "BACKGROUND")
mmRing:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
mmRing:SetSize(MINIMAP_BUTTON_SIZE + 4, MINIMAP_BUTTON_SIZE + 4)
mmRing:SetPoint("CENTER", minimapBtn, "CENTER")
mmRing:SetVertexColor(0.2, 0.2, 0.2, 1)

-- Circular icon using a round mask — avoids the black square from square background textures
local mmIcon = minimapBtn:CreateTexture(nil, "ARTWORK")
mmIcon:SetTexture("Interface\\Icons\\inv_flask_red")
mmIcon:SetAllPoints()
local mmMask = minimapBtn:CreateMaskTexture()
mmMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
mmMask:SetAllPoints(mmIcon)
mmIcon:AddMaskTexture(mmMask)

local function SetMinimapButtonPosition(angle)
    local rad = math.rad(angle)
    -- Compute radius dynamically so button sits just outside the actual minimap edge
    local r = (Minimap:GetWidth() / 2) + (MINIMAP_BUTTON_SIZE / 2)
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(rad) * r,
        math.sin(rad) * r)
end

local minimapDragging = false

minimapBtn:RegisterForDrag("LeftButton")

minimapBtn:SetScript("OnDragStart", function(self)
    minimapDragging = true
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local scale  = UIParent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        local angle  = math.deg(math.atan2((cy / scale) - my, (cx / scale) - mx))
        if DyBAddon_SavedVars then
            DyBAddon_SavedVars.minimapAngle = angle
        end
        SetMinimapButtonPosition(angle)
    end)
end)

minimapBtn:SetScript("OnDragStop", function(self)
    minimapDragging = false
    self:SetScript("OnUpdate", nil)
end)

minimapBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" and not minimapDragging then
        -- Toggle: close if already open
        if popup:IsShown() then
            popup:Hide()
            return
        end
        -- Reference: https://warcraft.wiki.gg/wiki/API_C_ChallengeMode.IsChallengeModeActive
        if C_ChallengeMode.IsChallengeModeActive() then
            print(L["rcc_mythic_blocked"])
            return
        end
        ShowConsumableStatus()
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine(L["rcc_minimap_tooltip"])
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Defer initial positioning until DyBAddon's SavedVariables are loaded
local mmInitFrame = CreateFrame("Frame")
-- Reason: Read the saved minimap angle and visibility once DyBAddon's SavedVariables are available
mmInitFrame:RegisterEvent("ADDON_LOADED")
mmInitFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "DyBAddon" then return end
    self:UnregisterEvent("ADDON_LOADED")
    local angle = (DyBAddon_SavedVars and DyBAddon_SavedVars.minimapAngle) or 225
    SetMinimapButtonPosition(angle)
    local show = DyBAddon_SavedVars and DyBAddon_SavedVars.minimapReadyCheckConsumables
    if show == nil then show = true end  -- default on
    if show then minimapBtn:Show() else minimapBtn:Hide() end
end)

-- Callback exposed to the options panel for the minimap button toggle
function DyBAddon.OnMinimapReadyCheckConsumablesChanged(_, value)
    if value then
        minimapBtn:Show()
    else
        minimapBtn:Hide()
    end
end

-- ---- Live buff tracking while the popup is visible ----
-- Register UNIT_AURA (flask / food aura changes) and PLAYER_EQUIPMENT_CHANGED
-- (weapon enchant applied/removed) only while the popup is shown, to avoid
-- unnecessary event overhead the rest of the time.

local f = CreateFrame("Frame")
-- Reason: React to ready checks to display consumable status when inside an instance
f:RegisterEvent("READY_CHECK")
-- Reason: Close the popup after any loading screen (zone changes, instance entry, /reload)
f:RegisterEvent("PLAYER_ENTERING_WORLD")
-- Reason: Close the popup when a Mythic+ run starts (no loading screen occurs, so PLAYER_ENTERING_WORLD does not fire)
f:RegisterEvent("CHALLENGE_MODE_START")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" or event == "CHALLENGE_MODE_START" then
        popup:Hide()
    elseif event == "READY_CHECK" then
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
    elseif event == "GROUP_ROSTER_UPDATE" then
        if popup:IsShown() then
            -- Defer one second: GROUP_ROSTER_UPDATE can fire before UnitClass() is
            -- available for newly joined members, causing their class to be missed.
            C_Timer.After(1, function()
                GetGroupMembers()
                UpdatePopupLayout()
                RefreshIcons()
            end)
        end
    end
end)

popup:SetScript("OnShow", function()
    -- Reason: Keep icons up-to-date while the popup is visible
    f:RegisterEvent("UNIT_AURA")
    f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
end)

popup:SetScript("OnHide", function()
    f:UnregisterEvent("UNIT_AURA")
    f:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
    f:UnregisterEvent("GROUP_ROSTER_UPDATE")
end)

-- Callback exposed to the options panel
function DyBAddon.OnReadyCheckConsumablesChanged(_, value)
    if not value then
        popup:Hide()
    end
end
