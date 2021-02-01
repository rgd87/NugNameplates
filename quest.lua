local addonName, ns = ...

local scantip = CreateFrame("GameTooltip", "NugNameplatesQuestTooltip", UIParent, "GameTooltipTemplate")




function NugNameplates:IsQuestUnit(unit)
    scantip:SetOwner(UIParent,ANCHOR_NONE)
    scantip:SetUnit(unit)
    -- local r = scantipScanLines(func)
    scantip:Hide()
end
