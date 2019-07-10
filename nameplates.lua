local addonName, ns = ...

local isClassic = select(4,GetBuildInfo()) <= 19999

local filterOwnSpells = true

local texture = "Interface\\BUTTONS\\WHITE8X8"
local barTexture = "Interface\\AddOns\\oUF_NugNameplates\\bar.tga"
local flat = "Interface\\BUTTONS\\WHITE8X8"
local targetGlowTexture = "Interface\\AddOns\\oUF_NugNameplates\\target-glow.tga"

local healthbar_width = 85
local healthbar_height = 6
local castbar_height = 9
local total_height = castbar_height + healthbar_height + 2



local LibAuraTypes = LibStub("LibAuraTypes", true)
local ROOT_PRIO = LibAuraTypes and LibAuraTypes.GetDebuffTypePriority("ROOT") or 0

local font3 = [[Interface\AddOns\oUF_NugNameplates\fonts\ClearFont.ttf]]

local colors = setmetatable({
    health = { .7, 0.2, 0.1},
    execute = { 1, 0, 0.8 },
    lostaggro = { 0.6, 0, 1},
	power = setmetatable({
		["MANA"] = mana,
		["RAGE"] = {0.9, 0, 0},
		["ENERGY"] = {1, 1, 0.4},
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

local execute_range
function ns.UpdateExecute(new_execute)
    execute_range = new_execute
end

local isPlayerTank
function ns.UpdateTankingStatus(new)
    isPlayerTank = new
end

local nameplateEventHandler = CreateFrame("Frame", nil, UIParent)
nameplateEventHandler:RegisterEvent("PLAYER_TARGET_CHANGED")
nameplateEventHandler:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
nameplateEventHandler:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, event, ...)
end)

local nonTargeAlpha = 0.7
-- local mouseoverAlpha = 0.7

function nameplateEventHandler:PLAYER_TARGET_CHANGED(event)

    -- print(event)
    local targetFrame = C_NamePlate.GetNamePlateForUnit("target")
    local mouseoverFrame = C_NamePlate.GetNamePlateForUnit("mouseover")
    local playerFrame = C_NamePlate.GetNamePlateForUnit("player")
    for _, frame in pairs(C_NamePlate.GetNamePlates()) do
        if frame ~= playerFrame then
            if frame == targetFrame or not UnitExists("target") then
                if frame.unitFrame then
                    frame.unitFrame:SetAlpha(1)
                    frame.unitFrame.Health.highlight:Hide()
                    -- frame.unitFrame.Health.lost:Show()
                    if frame == targetFrame then
                        frame.unitFrame.TargetGlow:Show()
                    else
                        frame.unitFrame.TargetGlow:Hide()
                    end
                end
            else
                if frame.unitFrame then
                    frame.unitFrame:SetAlpha(nonTargeAlpha)
                    frame.unitFrame.Health.highlight:Hide()
                    -- frame.unitFrame.Health.lost:Hide()
                    frame.unitFrame.TargetGlow:Hide()
                end
            end

            if frame == mouseoverFrame and UnitExists("mouseover") and mouseoverFrame ~= targetFrame then
                if frame.unitFrame then
                    frame.unitFrame.Health.highlight:Show()
                end
            else
                if frame.unitFrame then
                    frame.unitFrame.Health.highlight:Hide()
                end
            end
        end
	end
end
nameplateEventHandler.UPDATE_MOUSEOVER_UNIT = nameplateEventHandler.PLAYER_TARGET_CHANGED

-- function ns.oUF_NugNameplatesOnTargetChanged(nameplate, event, unit)
    -- print(nameplate and nameplate:GetName(), event, unit)
-- end


local MakeBorder = function(self, tex, left, right, top, bottom, level)
    local t = self:CreateTexture(nil,"BORDER",nil,level)
    t:SetTexture(tex)
    t:SetPoint("TOPLEFT", self, "TOPLEFT", left, -top)
    t:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -right, bottom)
    return t
end

--[[
local pmult = 1
local function pixelperfect(size)
    return floor(size/pmult + 0.5)*pmult
end

local res = GetCVar("gxWindowedResolution")
if res then
    local w,h = string.match(res, "(%d+)x(%d+)")
    pmult = (768/h) / UIParent:GetScale()
end
]]

local PostCreate = function (self, button, icons, index, debuff)
    local width = button:GetWidth()
    button:SetHeight(width*0.7)

    button.cd:SetReverse(true)
    -- button.cd:SetDrawEdge(false);
    -- button.cd.noCooldownCount = true -- for OmniCC
    button.icon:SetTexCoord(0.05, 0.95, 0.20, 0.80)


    local overlay = button.overlay
    overlay:Hide()
    overlay.Show = overlay.Hide

    local border = 1
    local frameborder = MakeBorder(button, "Interface\\BUTTONS\\WHITE8X8", -border, -border, -border, -border, -2)
    frameborder:SetVertexColor(0,0,0,1)
    -- overlay:SetTexCoord(0,1,0,1)
    -- overlay:SetTexture([[Interface\AddOns\oUF_NugNameplates\buffBorder]])
    if not button.isDebuff then
        overlay:Show()
        overlay:SetVertexColor(0.6,0.6,0.6, 1)
        overlay.Hide = overlay.Show
    end
end

local UnitGotAggro
local UnitEngaged
if isClassic then
    UnitGotAggro = function(unit)
        local unitTarget = unit.."target"
        return not UnitAffectingCombat(unit) or not UnitExists(unitTarget) or UnitIsUnit(unitTarget, "player")
    end
    UnitEngaged = UnitAffectingCombat
else
    UnitGotAggro = function(unit)
        local status = UnitThreatSituation('player',unit)
        -- if status and status >= 2 then
            -- return true, status == 2
        -- end
        return not UnitAffectingCombat(unit) or (status and status >= 2)

        -- if not status or status < 3 then
        --     -- player isn't tanking; get current target
        --     local tank_unit = unit..'target'

        --     if UnitExists(tank_unit) and not UnitIsUnit(tank_unit,'player') then
        --         local s = UnitThreatSituation(tank_unit, unit)
        --         if s and s >= 2 then
        --                 -- unit is attacking another tank
        --                 f.state.tank_mode_offtank = true
        --         end
        --     end
        -- end
    end
    UnitEngaged = UnitThreatSituation
end

local PostUpdateHealth = function(element, unit, cur, max)
    local parent = element.__owner

	local r, g, b, t
	if(element.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
		t = parent.colors.tapped
	elseif(element.colorDisconnected and element.disconnected) then
        t = parent.colors.disconnected
    elseif(element.colorClass and UnitIsPlayer(unit)) then
    --     (element.colorClassNPC and not UnitIsPlayer(unit)) or
    --     (element.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
        local _, class = UnitClass(unit)
        t = parent.colors.class[class]


    elseif isPlayerTank and not UnitIsPlayer(unit) and not UnitGotAggro(unit) then
        t = parent.colors.lostaggro
    elseif execute_range and cur/max < execute_range then
        t = parent.colors.execute
    elseif(element.colorReaction and not UnitEngaged(unit, 'player') and UnitReaction(unit, 'player')) then
        t = parent.colors.reaction[UnitReaction(unit, 'player')]
    elseif(element.colorHealth) then
		t = parent.colors.health
    end

    if(t) then
        r, g, b = t[1], t[2], t[3]
    end

    if(b) then
        element:SetStatusBarColor(r, g, b)

        local bg = element.bg
        if(bg) then local mu = bg.multiplier or 1
            bg:SetVertexColor(r * mu, g * mu, b * mu)
        end
    end
end


local CustomNameplateDebuffFilter = function(element, unit, button, name, texture,
    count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
    canApply, isBossDebuff, casterIsPlayer, nameplateShowAll)

    if element.onlyShowPlayer and not button.isPlayer then return end

    if not filterOwnSpells and button.isPlayer then return true end
    local rootSpellID, spellType, prio = LibAuraTypes.GetDebuffInfo(spellID)
    if prio and prio >= ROOT_PRIO then return true end
end


local defaultUIFilter = function(element, unit, button, name, texture,
    count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
    canApply, isBossDebuff, casterIsPlayer, nameplateShowAll)

    return nameplateShowAll or
		   (nameplateShowSelf and (caster == "player" or caster == "pet" or caster == "vehicle"));
end


function ns.oUF_NugNameplates(self, unit)
    if unit:match("nameplate") then

        self.colors = colors
        -- set size and points

        self:SetSize(85, healthbar_height)
        self:SetPoint("CENTER", 0, 0)

        -- health bar
        local health = CreateFrame("StatusBar", nil, self)
        health:SetAllPoints()
        health:SetStatusBarTexture(barTexture)
        health.colorHealth = true
        health.colorReaction = true
        health.colorClass = true
        health.frequentUpdates = true
        health.colorTapping = true
        -- health.colorDisconnected = true
        health:SetAlpha(1)


        healthlost = health:CreateTexture(nil, "ARTWORK")
        healthlost:SetTexture(texture)
        healthlost:SetVertexColor(1, 0.7, 0.7)
        health.lost = healthlost

        health._SetValue = health.SetValue
        health.SetValue = function(self, v)
            local min, max = self:GetMinMaxValues()
            local vp = v/max
            local offsetx = vp*healthbar_width
            self.lost:SetPoint("TOPLEFT", self, "TOPLEFT", offsetx, 0)
            self.lost:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", offsetx, 0)
            -- self.lost:SmoothFade(v)
            self.lost:SetNewHealthTarget(vp)
            self:_SetValue(v)
        end

        healthlost:SetPoint("TOPLEFT", health, "TOPLEFT", 0, 0)
        healthlost:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", 0, 0)

        -- healthlost:SetMinMaxValues(0,100)
        -- healthlost:SetValue(60)
        -- health._SetMinMaxValues = health.SetMinMaxValues
        -- health.SetMinMaxValues = function(self, min, max)
        --     self.lost:SetMinMaxValues(min, max)
        --     self:_SetMinMaxValues(min, max)
        -- end

        healthlost.currentvalue = 0
        healthlost.endvalue = 0

        healthlost.UpdateDiff = function(self)
            local diff = self.currentvalue - self.endvalue
            if diff > 0 then
                self:SetWidth((diff)*healthbar_width)
                self:SetAlpha(1)
            else
                self:SetWidth(1)
                self:SetAlpha(0)
            end
        end

        health:SetScript("OnUpdate", function(self, time)
            self._elapsed = (self._elapsed or 0) + time
            if self._elapsed < 0.025 then return end
            self._elapsed = 0


            local hl = self.lost
            local diff = hl.currentvalue - hl.endvalue
            if diff > 0 then
                local d = (diff > 0.1) and diff/15 or 0.006
                hl.currentvalue = hl.currentvalue - d
                -- self:SetValue(self.currentvalue)
                hl:UpdateDiff()
            end
        end)

        healthlost.SetNewHealthTarget = function(self, vp)
            if vp >= self.currentvalue or not UnitAffectingCombat("player") then
                self.currentvalue = vp
                self.endvalue = vp
                -- self:SetValue(vp)
                self:UpdateDiff()
            else
                self.endvalue = vp
            end
        end


        health.bg = health:CreateTexture(nil, "BACKGROUND")
        health.bg:SetAllPoints(health)
        health.bg:SetTexture(texture)
        health.bg.multiplier = 0.4

        self.Health = health
        self.Health.PostUpdate = PostUpdateHealth


        local hl = health:CreateTexture(nil, "OVERLAY")
        hl:SetTexture(texture)
        hl:SetVertexColor(0.1,0.1,0.1)
        hl:SetBlendMode("ADD")
        hl:SetAllPoints()
        -- hl:SetAlpha(0)
        hl:Hide()
        health.highlight = hl

        -- local healthborder = MakeBorder(health, flat, -1, -1, -1, -1, -2)
        -- healthborder:SetVertexColor(0,0,0,1)
        health:SetBackdrop({
            bgFile = flat,
            insets = { top = -1, right = -1, bottom= -1, left = -1 },
        })
        health:SetBackdropColor(0,0,0,1)

        -- Frame background

        -- hbg:SetAllPoints()
        -- hbg:SetColorTexture(0.2, 0.2, 0.2)

        local targetGlow = health:CreateTexture(nil, "BACKGROUND", nil, -6)
        targetGlow:SetPoint("TOPLEFT", health, "BOTTOMLEFT",0,-1)
        targetGlow:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT",0,-11)
        targetGlow:SetBlendMode("ADD")
        -- targetGlow:SetVertexColor(1, 0.7, 0.7)
        targetGlow:SetVertexColor(1, 0.2, 0.2)
        targetGlow:SetTexture(targetGlowTexture)
        targetGlow:Hide()
        self.TargetGlow = targetGlow


        if not isClassic then
            local castbar = CreateFrame("StatusBar", nil, self)
            castbar:SetHeight(castbar_height)
            castbar:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -3)
            castbar:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -3)
            castbar:SetStatusBarTexture(barTexture)
            local r,g,b = 1, 0.65, 0
            castbar:SetStatusBarColor(r,g,b)

            local cbbg = castbar:CreateTexture(nil, "BACKGROUND")
            cbbg:SetAllPoints()
            -- cbbg:SetColorTexture(r*0.4, g*0.4, b*0.4)
            cbbg:SetColorTexture(r*0.2, g*0.2, b*0.2)

            -- local castbarborder = MakeBorder(castbar, flat, -1, -1, -1, -1, -2)
            -- castbarborder:SetVertexColor(0,0,0,1)
            castbar:SetBackdrop({
                bgFile = flat,
                insets = { top = -1, right = -1, bottom= -1, left = -1 },
            })
            castbar:SetBackdropColor(0,0,0,1)

            local ict = castbar:CreateTexture(nil,"ARTWORK",nil,0)
            ict:SetPoint("TOPRIGHT",health,"TOPLEFT", -3, 0)
            ict:SetHeight(total_height)
            ict:SetWidth(total_height * 8/6)
            ict:SetTexCoord(.1, .9, .2, .8)

            local iconborder = castbar:CreateTexture(nil,"BORDER",nil, -2)
            iconborder:SetTexture(flat)
            iconborder:SetPoint("TOPLEFT", ict, "TOPLEFT", -1, 1)
            iconborder:SetPoint("BOTTOMRIGHT", ict, "BOTTOMRIGHT", 1, -1)
            iconborder:SetVertexColor(0,0,0,1)

            castbar.Icon = ict


            local spellText = castbar:CreateFontString("");
            spellText:SetFont(font3, 11, "OUTLINE")
            spellText:SetWidth(80+total_height)
            spellText:SetHeight(healthbar_height)
            spellText:SetJustifyH("CENTER")
            spellText:SetTextColor(1,1,1)
            spellText:SetPoint("TOP", castbar, "BOTTOM",-1,0)
            castbar.Text = spellText

            self.Castbar = castbar
        end

        -- Debuffs
        local debuffs = CreateFrame("Frame", "$parentDebuffs", self)
        debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT",0,-4)
        debuffs:SetHeight(25)
        debuffs:SetWidth(150)
        debuffs.debuffFilter = "HARMFUL|INCLUDE_NAME_PLATE_ONLY"; -- namepalte filter doesn't work in classic
        debuffs.num = 4
        debuffs.PostCreateIcon = PostCreate

        debuffs.PostUpdateIcon = function(icons, unit, button, index, position, duration, expiration, debuffType, isStealable)
            local width = button:GetWidth()
            button:SetHeight(width*0.7)
            if button.caster == "player" or button.caster == "pet" or UnitIsFriend("player", unit) then
                button:SetAlpha(1)
            else
                button:SetAlpha(.5)
            end
        end

        debuffs.showDebuffType = true
        debuffs.initialAnchor = "TOPLEFT"
        if isClassic then
            if LibAuraTypes then
                debuffs.CustomFilter = CustomNameplateDebuffFilter
            end
        else
            debuffs.CustomFilter = defaultUIFilter
        end

        debuffs["spacing-x"] = 3
        debuffs["growth-x"] = "RIGHT"
        debuffs["growth-y"] = "UP"
        debuffs.size = 19

        self.Debuffs = debuffs



        local OnHealthEvent = function(self, event, unit)
            if(not unit or self.unit ~= unit) then return end
            self.Health:ForceUpdate()
        end

        if isClassic then
            self:RegisterEvent("UNIT_TARGET", OnHealthEvent)
            -- self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
            -- frame.UPDATE_SHAPESHIFT_FORM = function(self)
            --     ns.UpdateTankingStatus(ns.IsTanking(class))
            -- end
        else
            self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", OnHealthEvent)
        end


    end
end


oUF:RegisterStyle("oUF_NugNameplates", ns.oUF_NugNameplates)
oUF:SetActiveStyle"oUF_NugNameplates"
oUF:SpawnNamePlates("oUF_Nameplate", ns.oUF_NugNameplatesOnTargetChanged)