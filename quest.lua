local addonName, ns = ...

local scantip = CreateFrame("GameTooltip", "NugNameplatesQuestTooltip", UIParent, "GameTooltipTemplate")

local function matchCount(text)
    local a, b = text:match('(%d+)/(%d+)')
    a = tonumber(a)
    b = tonumber(b)
    if a and b then
        if a ~= b then
            return a..'/'..b
        end
    end
end

local function matchPercent(text)
    local a = text:match('%((%d+)%%%)')
    a = tonumber(a)
    if a then
        return a..'%'
    end
end

local function matchProgress(text)
    return matchCount(text) or matchPercent(text)
end




function NugNameplates:IsQuestUnit(unit)
    scantip:SetOwner(UIParent,ANCHOR_NONE)
    scantip:SetUnit(unit)

    local match
    for i=3,scantip:NumLines() do
        local line = _G['NugNameplatesQuestTooltipTextLeft'..i]
        local text = line and line:GetText()
        if not text then break end

        -- quest progress text is indented, so...
        if math.floor((select(4,line:GetPoint(2)) or 0)+0.5) == 28 then
            match = matchProgress(text)
            if match then break end
        end
    end

    scantip:Hide()
    return match
end
