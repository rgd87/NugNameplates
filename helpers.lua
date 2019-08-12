local addonName, ns = ...

local IsPlayerSpell = IsPlayerSpell
local UnitClass = UnitClass
local GetShapeshiftForm = GetShapeshiftForm

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, event, ...)
end)
frame:RegisterEvent("SPELLS_CHANGED")

local isClassic = select(4,GetBuildInfo()) <= 19999
local GetSpecialization = isClassic and function() return 1 end or _G.GetSpecialization

local ranges

if isClassic then
    local IsAnySpellKnown = function (...)
        for i=1, select("#", ...) do
            local spellID = select(i, ...)
            if not spellID then break end
            if IsPlayerSpell(spellID) then return spellID end
        end
    end

    ranges = {
        WARRIOR = {
            function() return IsAnySpellKnown(20662, 20661, 20660, 20658, 5308) and 0.2 end,
        },
        PALADIN = {
            function() return IsAnySpellKnown(24275, 24274, 24239) and 0.2 end,
        },
    }
else
ranges = {
    WARRIOR = {
        function() return IsPlayerSpell(281001) and 0.35 or 0.2 end, -- massacre
        function() return IsPlayerSpell(206315) and 0.35 or 0.2 end, -- fury massacre
    },
    ROGUE = {
        function() return IsPlayerSpell(111240) and 0.30 end, -- blindside
    },
    WARLOCK = {
        function() return IsPlayerSpell(198590) and 0.20 end, -- drain soul
    },
    PRIEST = {
        [3] = function() return (IsPlayerSpell(109142) and 0.35) or (IsPlayerSpell(32379) and 0.20) end, -- twist of fate or swd
    },
    PALADIN = {
        [3] = function() return IsPlayerSpell(24275) and 0.20 end, -- HoW
    },
    HUNTER = {
        function() return IsPlayerSpell(273887) and 0.35 end, -- Killer Instinct
        function() return IsPlayerSpell(260228) and 0.30 end, -- Careful Aim
    },
    MONK = {
        [3] = function() return IsPlayerSpell(287599) and 0.10 end, -- Pressure Points
    },
}
end

local _, class = UnitClass("player")

local IsTanking
if isClassic then
    IsTanking = function(class)
        return  (class == "WARRIOR" and GetShapeshiftForm() == 2) or (class == "DRUID" and GetShapeshiftForm() == 1)
    end
    frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    frame.UPDATE_SHAPESHIFT_FORM = function(self)
        ns.UpdateTankingStatus(IsTanking(class))
    end
else
    IsTanking = function(class, spec)
        if
            ((class == "WARRIOR" and spec == 3) or
            (class == "DEATHKNIGHT" and spec == 1) or
            (class == "PALADIN" and spec == 2) or
            (class == "DRUID" and spec == 3) or
            (class == "DEMONHUNTER" and spec == 2) or
            (class == "MONK" and spec == 1))
        then
            return true
        end
    end
end


function frame:SPELLS_CHANGED()
    local spec = GetSpecialization()
    if not spec then ns.UpdateExecute(nil) return end
    local classopts = ranges[class]
    local range
    if classopts then
        range = classopts[spec]
        if type(range) == "function" then
            range = range()
        end
    end
    ns.UpdateExecute(range)

    ns.UpdateTankingStatus(IsTanking(class, spec))
end


local function rgb2hsv (r, g, b)
    local rabs, gabs, babs, rr, gg, bb, h, s, v, diff, diffc, percentRoundFn
    rabs = r
    gabs = g
    babs = b
    v = math.max(rabs, gabs, babs)
    diff = v - math.min(rabs, gabs, babs);
    diffc = function(c) return (v - c) / 6 / diff + 1 / 2 end
    -- percentRoundFn = function(num) return math.floor(num * 100) / 100 end
    if (diff == 0) then
        h = 0
        s = 0
    else
        s = diff / v;
        rr = diffc(rabs);
        gg = diffc(gabs);
        bb = diffc(babs);

        if (rabs == v) then
            h = bb - gg;
        elseif (gabs == v) then
            h = (1 / 3) + rr - bb;
        elseif (babs == v) then
            h = (2 / 3) + gg - rr;
        end
        if (h < 0) then
            h = h + 1;
        elseif (h > 1) then
            h = h - 1;
        end
    end
    return h, s, v
end

local function hsv2rgb(h,s,v)
    local r,g,b
    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);
    local rem = i % 6
    if rem == 0 then
        r = v; g = t; b = p;
    elseif rem == 1 then
        r = q; g = v; b = p;
    elseif rem == 2 then
        r = p; g = v; b = t;
    elseif rem == 3 then
        r = p; g = q; b = v;
    elseif rem == 4 then
        r = t; g = p; b = v;
    elseif rem == 5 then
        r = v; g = p; b = q;
    end

    return r,g,b
end

local function hsv_shift(src, hm,sm,vm)
    local r,g,b = unpack(src)
    local h,s,v = rgb2hsv(r,g,b)

    -- rollover on hue
    local h2 = h + hm
    if h2 < 0 then h2 = h2 + 1 end
    if h2 > 1 then h2 = h2 - 1 end

    local s2 = s + sm
    if s2 < 0 then s2 = 0 end
    if s2 > 1 then s2 = 1 end

    local v2 = v + vm
    if v2 < 0 then v2 = 0 end
    if v2 > 1 then v2 = 1 end

    local r2,g2,b2 = hsv2rgb(h2, s2, v2)

    return r2, g2, b2
end

ns.rgb2hsv = rgb2hsv
ns.hsv2rgb = hsv2rgb
ns.hsv_shift = hsv_shift