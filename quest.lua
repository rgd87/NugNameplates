local addonName, ns = ...

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
    if C_Secrets.ShouldUnitIdentityBeSecret(unit) then return false end

    local info = C_TooltipInfo.GetUnit(unit)
    if not info then return false end
    local match
    for i=3,#info.lines do
        local line = info.lines[i]
        local text = line and line.leftText
        if not text then break end

        match = matchProgress(text)
        if match then break end
    end
    return match
end
