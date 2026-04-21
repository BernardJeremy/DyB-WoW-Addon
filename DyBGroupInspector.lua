local ADDON_PREFIX = "|cFFFFD100[DyBAddon]|r "
local ICON_SIZE = 14

local announcedGUIDs = {}
local inspectQueue = {}
local isInspecting = false
local pendingUnit = nil
local scanPending = false

local f = CreateFrame("Frame")

-- Icon helpers ----------------------------------------------------------------

local function GetRaceIcon(unit)
    local _, raceFile = UnitRace(unit)
    if not raceFile then return "" end
    local sex = UnitSex(unit)
    local gender = (sex == 3) and "female" or "male"
    -- Reference: https://warcraft.wiki.gg/wiki/UI_escape_sequences#Texture_atlas
    local atlas = "raceicon128-" .. raceFile:lower() .. "-" .. gender
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        return CreateAtlasMarkup(atlas, ICON_SIZE, ICON_SIZE)
    end
    return ""
end

local function GetClassIcon(classFile)
    if not classFile then return "" end
    return CreateAtlasMarkup("classicon-" .. classFile:lower(), ICON_SIZE, ICON_SIZE)
end

local function GetSpecMarkup(specID)
    if not specID or specID == 0 then return "", "?" end
    -- Reference: https://warcraft.wiki.gg/wiki/API_GetSpecializationInfoByID
    local id, name, _, icon = GetSpecializationInfoByID(specID)
    if not id then return "", "?" end
    return "|T" .. icon .. ":" .. ICON_SIZE .. "|t", name
end

local function GetClassColoredText(text, classFile)
    if not classFile or not RAID_CLASS_COLORS[classFile] then return text end
    local c = RAID_CLASS_COLORS[classFile]
    return string.format("|cFF%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, text)
end

-- Output ----------------------------------------------------------------------

local function PrintMemberInfo(unit, specID, ilvl)
    local name = UnitName(unit)
    if not name then return end

    local _, classFile = UnitClass(unit)
    local raceIcon = GetRaceIcon(unit)
    local classIcon = GetClassIcon(classFile)
    local specIcon, specName = GetSpecMarkup(specID)
    local coloredName = GetClassColoredText(name, classFile)
    local ilvlStr = (ilvl and ilvl > 0) and string.format("%.0f", ilvl) or "?"

    -- Build icon string, skipping empty race icon
    local icons = ""
    if raceIcon ~= "" then icons = raceIcon .. " " end
    icons = icons .. classIcon .. " " .. specIcon

    print(string.format("%s%s %s - %s - iLvl %s",
        ADDON_PREFIX, icons, coloredName, specName, ilvlStr))
end

-- Inspect queue ---------------------------------------------------------------

local function ProcessNextInspect()
    if isInspecting or #inspectQueue == 0 then return end

    local entry = table.remove(inspectQueue, 1)
    local unitId = entry.unit
    local guid = entry.guid

    -- Unit may have changed slot or left the group
    if not UnitExists(unitId) or UnitGUID(unitId) ~= guid then
        ProcessNextInspect()
        return
    end

    -- Reference: https://warcraft.wiki.gg/wiki/API_NotifyInspect
    if CanInspect(unitId) then
        isInspecting = true
        pendingUnit = unitId
        NotifyInspect(unitId)
        -- Safety timeout if INSPECT_READY never fires (throttled / out of range)
        C_Timer.After(5, function()
            if isInspecting and pendingUnit == unitId then
                PrintMemberInfo(unitId, 0, 0)
                isInspecting = false
                pendingUnit = nil
                ClearInspectPlayer()
                ProcessNextInspect()
            end
        end)
    else
        -- Out of range — print available info without spec / ilvl
        PrintMemberInfo(unitId, 0, 0)
        C_Timer.After(0.5, ProcessNextInspect)
    end
end

-- Group scanning --------------------------------------------------------------

local function ScanGroup()
    if not DyBAddon_SavedVars or not DyBAddon_SavedVars.groupInspect then return end
    if not IsInGroup() then return end
    if IsInRaid() and not DyBAddon_SavedVars.groupInspectRaid then return end

    local newMembers = {}
    local prefix, count

    if IsInRaid() then
        prefix = "raid"
        count = GetNumGroupMembers()
    else
        prefix = "party"
        count = GetNumGroupMembers() - 1
    end

    for i = 1, count do
        local unit = prefix .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") and UnitIsPlayer(unit) then
            local guid = UnitGUID(unit)
            if guid and not announcedGUIDs[guid] then
                announcedGUIDs[guid] = true
                table.insert(newMembers, { unit = unit, guid = guid })
            end
        end
    end

    if #newMembers > 0 then
        for _, entry in ipairs(newMembers) do
            table.insert(inspectQueue, entry)
        end
        ProcessNextInspect()
    end
end

-- Events ----------------------------------------------------------------------

-- Reason: Detect group composition changes to log new members' info
f:RegisterEvent("GROUP_ROSTER_UPDATE")
-- Reason: Receive inspect results for specialization and item level data
f:RegisterEvent("INSPECT_READY")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "GROUP_ROSTER_UPDATE" then
        if not IsInGroup() then
            wipe(announcedGUIDs)
            wipe(inspectQueue)
            isInspecting = false
            pendingUnit = nil
            return
        end
        -- Debounce: GROUP_ROSTER_UPDATE can fire multiple times in a burst
        if not scanPending then
            scanPending = true
            C_Timer.After(1, function()
                scanPending = false
                ScanGroup()
            end)
        end

    elseif event == "INSPECT_READY" then
        if not isInspecting or not pendingUnit then return end
        local inspectGUID = ...
        local unit = pendingUnit

        if UnitExists(unit) and UnitGUID(unit) == inspectGUID then
            local specID = GetInspectSpecialization(unit)
            -- Reference: https://warcraft.wiki.gg/wiki/API_C_PaperDollInfo.GetInspectItemLevel
            local ilvl = C_PaperDollInfo.GetInspectItemLevel(unit)
            PrintMemberInfo(unit, specID, ilvl)
        end

        isInspecting = false
        pendingUnit = nil
        ClearInspectPlayer()
        C_Timer.After(0.5, ProcessNextInspect)
    end
end)

-- Slash command ---------------------------------------------------------------

local function InspectAllMembers()
    if not IsInGroup() then
        print(ADDON_PREFIX .. "Vous n'êtes dans aucun groupe.")
        return
    end

    local prefix, count
    if IsInRaid() then
        prefix = "raid"
        count = GetNumGroupMembers()
    else
        prefix = "party"
        count = GetNumGroupMembers() - 1
    end

    local members = {}
    for i = 1, count do
        local unit = prefix .. i
        if UnitExists(unit) and not UnitIsUnit(unit, "player") and UnitIsPlayer(unit) then
            local guid = UnitGUID(unit)
            if guid then
                table.insert(members, { unit = unit, guid = guid })
            end
        end
    end

    if #members == 0 then
        print(ADDON_PREFIX .. "Aucun membre à inspecter.")
        return
    end

    -- Queue all members for inspection (skip announcedGUIDs check)
    for _, entry in ipairs(members) do
        table.insert(inspectQueue, entry)
    end
    ProcessNextInspect()
end

SLASH_DYBINFO1 = "/info"
SlashCmdList["DYBINFO"] = InspectAllMembers

-- Callbacks for options -------------------------------------------------------

function DyBAddon.OnGroupInspectChanged(_, value)
    -- Takes effect on next group change
end

function DyBAddon.OnGroupInspectRaidChanged(_, value)
    -- Takes effect on next group change
end
