local addonName, ns = ...

local IsPlayerSpell = IsPlayerSpell
local UnitClass = UnitClass
local GetShapeshiftForm = GetShapeshiftForm

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...)
	return self[event](self, event, ...)
end)
frame:RegisterEvent("SPELLS_CHANGED")



frame:RegisterEvent("PLAYER_ENTERING_WORLD")
function frame:PLAYER_ENTERING_WORLD()
    local _, instanceType = GetInstanceInfo()
    if not InCombatLockdown() then
        local inPVEInstance = instanceType == "party" or instanceType == "raid"
        local val = inPVEInstance and "0" or "1"
        SetCVar("nameplateShowFriends", val)
    end
end

local isClassic = select(4,GetBuildInfo()) <= 19999
local GetSpecialization = isClassic and function() return 1 end or _G.GetSpecialization

local ranges

local function SimplePercentCheck(threshold)
    return function(p, unit, cur, max)
        return p < threshold
    end
end

local function CondemnExecute()
    local isMassacre = IsPlayerSpell(281001) or IsPlayerSpell(206315) -- arms, fury massacres
    local lowT = isMassacre and 0.35 or 0.2
    local isCondemn = IsPlayerSpell(317320) or IsPlayerSpell(317485) -- arms/prot, fury condemn
    local highT = isCondemn and 0.8 or 1
    return function(p, unit, cur, max)
        return p < lowT or p > highT
    end
end

--[[
local function TouchOfDeath()
    local pressurePoints = IsPlayerSpell(287599)
    return function(p, unit, cur, max)
        -- local playerMaxHealth = UnitHealthMax("player")
        -- local isWeak = max < playerMaxHealth
        -- if isWeak then
        --     return true
        -- else
        return p < 0.15
        -- end
    end
end
]]

local function Wrap(func)
    return function()
        return func
    end
end

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
            function() return IsAnySpellKnown(20662, 20661, 20660, 20658, 5308) and SimplePercentCheck(0.2) end,
        },
        PALADIN = {
            function() return IsAnySpellKnown(24275, 24274, 24239) and SimplePercentCheck(0.2) end,
        },
    }
else

ranges = {
    WARRIOR = {
        CondemnExecute, CondemnExecute, CondemnExecute,
    },
    ROGUE = {
        function() return IsPlayerSpell(328085) and SimplePercentCheck(0.35) end, -- blindside
    },
    WARLOCK = {
        function() return IsPlayerSpell(198590) and SimplePercentCheck(0.20) end, -- drain soul
        nil,
        function() return IsPlayerSpell(17877) and SimplePercentCheck(0.20) end, -- Shadowburn
    },
    PRIEST = {
        Wrap(SimplePercentCheck(0.20)), Wrap(SimplePercentCheck(0.20)), Wrap(SimplePercentCheck(0.20)), -- SWD
    },
    PALADIN = {
        Wrap(SimplePercentCheck(0.20)), Wrap(SimplePercentCheck(0.20)), Wrap(SimplePercentCheck(0.20)), -- HoW
    },
    HUNTER = {
        Wrap(SimplePercentCheck(0.20)), Wrap(SimplePercentCheck(0.20)), Wrap(SimplePercentCheck(0.20)), -- Kill Shot
    },
    MONK = {
        Wrap(SimplePercentCheck(0.15)), Wrap(SimplePercentCheck(0.15)), Wrap(SimplePercentCheck(0.15)), -- Death Touch
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
        if range then
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


-- default colors data below copied from oUF

ns.colors = {
    health = {49 / 255, 207 / 255, 37 / 255},
    disconnected = {0.6, 0.6, 0.6},
    tapped = {0.6, 0.6, 0.6},

    class = {},
	debuff = {},
	reaction = {},
	power = {},
	threat = {},
}
local colors = ns.colors

local function customClassColors()
	if(CUSTOM_CLASS_COLORS) then
		local function updateColors()
			for classToken, color in next, CUSTOM_CLASS_COLORS do
				colors.class[classToken] = {color.r, color.g, color.b}
			end

			for _, obj in next, oUF.objects do
				obj:UpdateAllElements('CUSTOM_CLASS_COLORS')
			end
		end

		updateColors()
		CUSTOM_CLASS_COLORS:RegisterCallback(updateColors)

		return true
	end
end

if(not customClassColors()) then
	for classToken, color in next, RAID_CLASS_COLORS do
		colors.class[classToken] = {color.r, color.g, color.b}
	end

	local eventHandler = CreateFrame('Frame')
	eventHandler:RegisterEvent('ADDON_LOADED')
	eventHandler:SetScript('OnEvent', function(self)
		if(customClassColors()) then
			self:UnregisterEvent('ADDON_LOADED')
			self:SetScript('OnEvent', nil)
		end
	end)
end

for debuffType, color in next, DebuffTypeColor do
	colors.debuff[debuffType] = {color.r, color.g, color.b}
end

for eclass, color in next, FACTION_BAR_COLORS do
	colors.reaction[eclass] = {color.r, color.g, color.b}
end

for power, color in next, PowerBarColor do
	if (type(power) == 'string') then
		if(type(select(2, next(color))) == 'table') then
			colors.power[power] = {}

			for index, color in next, color do
				colors.power[power][index] = {color.r, color.g, color.b}
			end
		else
			colors.power[power] = {color.r, color.g, color.b, atlas = color.atlas}
		end
	end
end


for i = 0, 3 do
	colors.threat[i] = {GetThreatStatusColor(i)}
end

-- sourced from FrameXML/Constants.lua
colors.power[0] = colors.power.MANA
colors.power[1] = colors.power.RAGE
colors.power[2] = colors.power.FOCUS
colors.power[3] = colors.power.ENERGY
colors.power[4] = colors.power.COMBO_POINTS
colors.power[5] = colors.power.RUNES
colors.power[6] = colors.power.RUNIC_POWER
colors.power[7] = colors.power.SOUL_SHARDS
colors.power[8] = colors.power.LUNAR_POWER
colors.power[9] = colors.power.HOLY_POWER
colors.power[11] = colors.power.MAELSTROM
colors.power[12] = colors.power.CHI
colors.power[13] = colors.power.INSANITY
colors.power[16] = colors.power.ARCANE_CHARGES
colors.power[17] = colors.power.FURY
colors.power[18] = colors.power.PAIN

-- alternate power, sourced from FrameXML/CompactUnitFrame.lua
colors.power.ALTERNATE = {0.7, 0.7, 0.6}
colors.power[10] = colors.power.ALTERNATE
