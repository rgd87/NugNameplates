local addonName, ns = ...

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
    if not spec then execute_range = nil; return end
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

