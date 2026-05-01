DyBAddon = {}

-- Slots used by WoW's average item level formula (16 slots; off-hand counts 0 for 2H)
-- Reference: https://warcraft.wiki.gg/wiki/API_GetInventoryItemLink
local ILVL_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17 }

-- Returns the precise (decimal) average item level for the given unit, matching
-- Blizzard's formula: always divides by 16, and if the off-hand slot is empty
-- (2H weapon equipped), the main-hand item level is counted for both weapon slots.
-- Reference: https://warcraft.wiki.gg/wiki/API_C_Item.GetDetailedItemLevelInfo
function DyBAddon.GetItemLevelPrecise(unit)
    local total = 0
    local mainHandIlvl = 0
    local hasOffHand = false

    for _, slot in ipairs(ILVL_SLOTS) do
        local link = GetInventoryItemLink(unit, slot)
        if link then
            local ilvl = C_Item.GetDetailedItemLevelInfo(link)
            if ilvl and ilvl > 0 then
                total = total + ilvl
                if slot == 16 then mainHandIlvl = ilvl end
                if slot == 17 then hasOffHand = true end
            end
        end
    end

    -- 2H weapon: off-hand slot is empty but Blizzard counts it as main-hand ilvl
    if mainHandIlvl > 0 and not hasOffHand then
        total = total + mainHandIlvl
    end

    return total / 16
end
