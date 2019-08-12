local addonName, ns = ...

local isClassic = select(4,GetBuildInfo()) <= 19999

local filterOwnSpells = true

local texture = "Interface\\BUTTONS\\WHITE8X8"
local shieldTexture = "Interface\\AddOns\\oUF_NugNameplates\\shieldtex.tga"
local barTexture = "Interface\\AddOns\\oUF_NugNameplates\\bar.tga"
local flat = "Interface\\BUTTONS\\WHITE8X8"
local targetGlowTexture = "Interface\\AddOns\\oUF_NugNameplates\\target-glow.tga"

local healthbar_width = 85
local healthbar_height = 7
local castbar_height = 10
local total_height = castbar_height + healthbar_height + 2

local hsv_shift = ns.hsv_shift

local LibAuraTypes = LibStub("LibAuraTypes", true)
local ROOT_PRIO = LibAuraTypes and LibAuraTypes.GetDebuffTypePriority("ROOT") or 0

local font3 = [[Interface\AddOns\oUF_NugNameplates\fonts\ClearFont.ttf]]

local UnitAffectingCombat = UnitAffectingCombat
local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitThreatSituation = UnitThreatSituation
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitIsPlayer = UnitIsPlayer
local UnitPlayerControlled = UnitPlayerControlled
local IsInGroup = IsInGroup
local IsInInstance = IsInInstance
local UnitIsPlayer = UnitIsPlayer
local UnitIsFriend = UnitIsFriend
local GetTime = GetTime
local UnitGUID = UnitGUID
local C_NamePlate = C_NamePlate
local oUF = oUF
local UnitClass = UnitClass
local UnitIsTapDenied = UnitIsTapDenied
local UnitReaction = UnitReaction

local SpecialThreatStatus
local UnitEngaged

local healthColor = { 1, 0.12, 0 }
local importantNPC = { hsv_shift(healthColor, -0.1, 0, 0.0) }
local importantNPC2 = { hsv_shift(healthColor, -0.2, 0, 0.0) }
local colors = setmetatable({
    -- health = { .7, 0.2, 0.1},
    health = healthColor,
    execute = { 1, 0, 0.8 },
    aggro_lost = { 0.6, 0, 1},
    aggro_transitioning = { 1, 0.4, 0},
    aggro_offtank = { 0, 1, 0.5},
}, {__index = oUF.colors})


local npc_colors
if not isClassic then
    npc_colors = {
        [120651] = { 0.8, 0.4, 0 }, -- M+ explosive affix spheres

        [130909] = importantNPC, -- Underrot, Fetid Maggot, uninterruptible cone aoe
        [131492] = importantNPC, -- Underrot, Devout Blood Priest, casts Gift of G'huun and Heal
        -- [134284] = importantNPC, -- Underrot, Fallen Deathspeaker, the main guy in the pack

        [128434] = importantNPC, -- Atal'Dazar, Feasting Skyscreamer, casts Fear

        [127111] = importantNPC, -- Freehold, Irontide Oarsman, casts Sea Spout

        [134174] = importantNPC, -- King's Rest, Shadow-Borne Witch Doctor, casts Shadow Bolt Volley
        [134331] = importantNPC, -- King's Rest, King Rahu'ai, casts aoe lightning

        [135167] = importantNPC, -- King's Rest, Spectral Berserker, casts Severing Blade (insane bleed)
        [135235] = importantNPC2, -- King's Rest, Spectral Beastmaster, casts Poison Barrage

        [134139] = importantNPC, -- Shrine of the Storm, Shrine Templar, casts Protective Aura
        [134150] = importantNPC2, -- Shrine of the Storm, Runecarver Sorn, miniboss dude with Reinforcing Ward
        [134417] = importantNPC, -- Shrine of the Storm, Deepsea Ritualist, cast Unending Darkness

        [141283] = importantNPC, -- Siege of Boralus, Kul Tiran Halberd, casts frontal aoe
        [132481] = importantNPC, -- Siege of Boralus, Kul Tiran Halberd, casts frontal aoe
        [128969] = importantNPC, -- Siege of Boralus, Ashvane Commander, casts Bolstering Shout which applies an 8 second magic buff to all nearby trash, reducing the damage they take by 75%.
        [136549] = importantNPC, -- Siege of Boralus, Ashvane Cannoneer, casts frontal aoe
        -- [137516] = importantNPC, -- Siege of Boralus, Ashvane Invader, casts Stinging Venom Coating (id:275835) which buffs their melee attacks

        [134990] = importantNPC, -- Temple of Sethraliss, Charged Dust Devil, casts Heal
        -- Aspix Lightning Shield Spell ID: 263246
        -- [134629] = importantNPC, -- Temple of Sethraliss, Scaled Krolusk Rider, frontal aoe
        [134364] = importantNPC, -- Temple of Sethraliss, Faithless Tender, casts Heal
        [139949] = importantNPC, -- Temple of Sethraliss, Plague Doctor, casts Chain Lightning & CC

        [134232] = importantNPC, -- MOTHERLODE, Hired Assassin, casts Poison & AoE
        [134012] = importantNPC, -- MOTHERLODE, Taskmaster Askari, casts Cover (id:263275) which will redirect 50% of damage taken by nearby allies to the Taskmaster. This buff also reduces all damage taken by 75%.
        [133432] = importantNPC, -- MOTHERLODE, Venture Co. Alchemist, casts Transmute: Enemy to Goo
        [133593] = importantNPC, -- MOTHERLODE, Expert Technician, casts Overcharge & Repair

        [130025] = importantNPC, -- Tol Dagor, Irontide Thug, casts Debilitating Shout
        [130026] = importantNPC, -- Tol Dagor, Bilge Rat Seaspeaker, casts Watery Dome applies a magic buff to all nearby trash mobs which reduces all incoming damage by 75% for 8 seconds. This buff also applies a damage absorption shield.
        [130655] = importantNPC, -- Tol Dagor, Bobby Howlis, casts Vicious Mauling
        [135699] = importantNPC, -- Tol Dagor, Ashvane Jailer, will buff (id:258317) themselves and any trash within 10 yards when they channel  Riot Shield. This reduces incoming damage by 75% and redirects all spells back to the player that cast them

        -- [131677] = importantNPC, -- Waycrest, Heartsbane Runeweaver, casts Etch & frontal  Marking Cleave
        -- Some Devouring Maggots (npcID:134024) have the Parasitic (id:278431) buff. This grants them access to the Infest spell.
        [137830] = importantNPC, -- Waycrest, Pallid Gorger, will leap to the furthest target with their Ravaging Leap cast & frontal aoe
        [131586] = importantNPC, -- Waycrest, Banquet Steward, will cast Dinner Bell
        [131812] = importantNPC, -- Waycrest, Heartsbane Soulcharmer, casts Soul Valley & Warding Candles (id:264027)

        [150292] = importantNPC2, -- Mechagon, Mechagon Cavalry, casts Rapid Fire
        [150297] = importantNPC, -- Mechagon, Mechagon Renormalizer, casts Shrink & Enlarge
        [150251] = importantNPC, -- Mechagon, Pistonhead Mechanic, casts Heal & buffs others with Overclock Enrage(id:299588)
        [144295] = importantNPC, -- Mechagon, Mechagon Mechanic, casts Heal & buffs others with Overclock Enrage(id:293930)
    }
else
    npc_colors = {}
end

local execute_range
function ns.UpdateExecute(new_execute)
    execute_range = new_execute
end

local isPlayerTanking
function ns.UpdateTankingStatus(new)
    isPlayerTanking = new
end

local nameplateEventHandler = CreateFrame("Frame", nil, UIParent)
nameplateEventHandler:RegisterEvent("PLAYER_TARGET_CHANGED")
nameplateEventHandler:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
nameplateEventHandler:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, event, ...)
end)

local nonTargeAlpha = 0.6
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

function ns.NameplateCallback(nameplate, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local guid = UnitGUID(unit)
        local _, _, _, _, _, npcID = strsplit("-", guid);
        nameplate.npcID = tonumber(npcID)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        nameplate.npcID = nil
    end
    -- print(nameplate and nameplate:GetName(), event, unit)
end


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
    SpecialThreatStatus = function(unit)
        if not UnitAffectingCombat(unit) then return nil end

        local unitTarget = unit.."target"

        if not UnitExists(unitTarget) then return nil end

        local isPlayerUnitTarget = UnitIsUnit(unitTarget, "player")

        local threatStatus = nil
        if isPlayerTanking and not isPlayerUnitTarget then
            threatStatus = "aggro_lost"
        -- elseif not isPlayerTanking and isPlayerUnitTarget then
        --     threatStatus = "aggro_lost"
        end

        return threatStatus
    end
    UnitEngaged = UnitAffectingCombat
else
    SpecialThreatStatus = function(unit)
        -- if unit == 'player' or UnitIsUnit('player',unit) then return end

        if not UnitAffectingCombat(unit) then return nil end

        local threatStatus = nil
        if isPlayerTanking then
            local status = UnitThreatSituation('player',unit)

            if status then
                if status == 3 then
                    threatStatus = nil
                elseif status >= 1 then
                    threatStatus = "aggro_transitioning"
                else
                    threatStatus = "aggro_lost"
                end
            end

            -- Kui tankmode
            if not status or status < 3 then
                -- player isn't tanking; get current target
                local tank_unit = unit..'target'

                if UnitExists(tank_unit) and not UnitIsUnit(tank_unit,'player') then
                    if  UnitGroupRolesAssigned(tank_unit) == "TANK" or
                        (not UnitIsPlayer(tank_unit) and UnitPlayerControlled(tank_unit))
                    then
                        threatStatus = "aggro_offtank"
                    else
                        threatStatus = "aggro_lost"
                    end
                end
            end
        --[[
        else
            if status and IsInGroup() and IsInInstance() and not UnitIsPlayer(unit) then
                if status == 1 then
                    threatStatus = "aggro_transitioning"
                elseif status >= 2 then
                    threatStatus = "aggro_lost"
                end
            end
        ]]
        end

        return threatStatus
    end
    UnitEngaged = function(unit)
        return UnitThreatSituation("player", unit)
    end
end

local PostUpdateHealth = function(element, unit, cur, max)
    local parent = element.__owner

    local sts = SpecialThreatStatus(unit)
    local reaction = UnitReaction(unit, 'player')

    local npcID = element:GetParent()["npcID"]
    local npcColor = npc_colors[npcID]

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


    elseif not UnitIsPlayer(unit) and sts then
        t = parent.colors[sts]
    elseif execute_range and cur/max < execute_range then
        t = parent.colors.execute
    elseif(element.colorReaction and not UnitEngaged(unit, 'player') and reaction >= 4) then
        t = parent.colors.reaction[reaction]
    elseif npcColor then
        t = npcColor
    elseif(element.colorHealth) then
		t = parent.colors.health
    end

    if(t) then
        r, g, b = t[1], t[2], t[3]
    end

    if(b) then
        element:SetColor(r, g, b)
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

local BuffsPurgeableFilter = function(element, unit, button, name, texture,
    count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
    canApply, isBossDebuff, casterIsPlayer, nameplateShowAll)

    -- if not UnitIsFriend("player", unit) then
        return isStealable
    -- end
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

        health.SetColor = function(element, r,g,b)
            element:SetStatusBarColor(r, g, b)

            local bg = element.bg
            if(bg) then local mu = bg.multiplier or 1
                bg:SetVertexColor(r * mu, g * mu, b * mu)
            end

            local r2 = math.min(1, r+0.6)
            local g2 = math.min(1, g+0.6)
            local b2 = math.min(1, b+0.6)

            element.lost:SetVertexColor(r2,g2,b2)
            element.absorb:SetVertexColor(r,g,b)
        end

        if not isClassic then
            -----------------
            -- ABSORB BAR
            -----------------

            local absorb = health:CreateTexture(nil, "ARTWORK", nil, 3)
            absorb:SetHorizTile(true)
            -- absorb:SetVertTile(true)
            absorb:SetTexture(shieldTexture, "REPEAT", "REPEAT")
            absorb:Hide()

            absorb.Update = function(self, absorbValue, health, maxHealth)
                local p
                if absorbValue then
                    p = absorbValue/maxHealth
                    self.absorbPercent = p
                else
                    p = self.absorbPercent
                end
                local parent = self:GetParent()
                local healthPercent = health/maxHealth

                if p == 0 then
                    self:Hide()
                elseif p + healthPercent >= 1 then
                    local p2 = 1 - healthPercent
                    local offsetx = healthPercent*healthbar_width
                    if p2 == 0 then
                        self:Hide()
                    else
                        self:SetWidth(p2*healthbar_width)
                        self:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetx, 0)
                        self:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", offsetx, 0)
                        self:Show()
                    end
                else
                    local offsetx = healthPercent*healthbar_width
                    self:SetWidth(p*healthbar_width)
                    self:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetx, 0)
                    self:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", offsetx, 0)
                    self:Show()
                end
            end
            health.absorb = absorb

            ----------------------
            -- HEAL ABSORB
            ----------------------

            local healAbsorb = health:CreateTexture(nil, "ARTWORK", nil, 4)
            healAbsorb:SetTexture(texture)
            healAbsorb:SetVertexColor(0,0,0, 0.4)
            healAbsorb.Update = function(self, healAbsorbValue, health, maxHealth)
                local p
                if healAbsorbValue then
                    p = healAbsorbValue/maxHealth
                    self.healAbsorbPercent = p
                else
                    p = self.healAbsorbPercent
                end
                local parent = self:GetParent()
                local healthPercent = health/maxHealth

                if p > healthPercent then
                    p = healthPercent
                end

                if p == 0 then
                    self:Hide()
                else
                    local offsetx = (healthPercent-p)*healthbar_width
                    self:SetWidth(p*healthbar_width)
                    self:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetx, 0)
                    self:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", offsetx, 0)
                    self:Show()
                end
            end
            health.healAbsorb = healAbsorb

            self.HealthPrediction = {
                -- myBar = myBar,
                -- otherBar = otherBar,
                absorbBar = absorb,
                healAbsorbBar = healAbsorb,
                -- overAbsorb = overAbsorb,
                -- overHealAbsorb = overHealAbsorb,
                -- maxOverflow = 1.05,
                frequentUpdates = true,
                Override = function(self, event, unit)
                    local element = self.HealthPrediction

                    -- local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
                    local absorb = UnitGetTotalAbsorbs(unit) or 0
                    local healAbsorb = UnitGetTotalHealAbsorbs(unit) or 0
                    local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)

                    element.absorbBar:Update(absorb, health, maxHealth)
                    element.healAbsorbBar:Update(healAbsorb, health, maxHealth)
                end,
            }
        end

        -----------------------
        -- HEALTH LOSS EFFECT
        -----------------------

        local healthlost = health:CreateTexture(nil, "ARTWORK")
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
            castbar.bg = cbbg

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


            local highlight = castbar:CreateTexture(nil, "ARTWORK", nil, 3)
            highlight:SetAllPoints(castbar)
            highlight:SetTexture(flat)
            highlight:SetBlendMode("ADD")
            highlight:SetVertexColor(0.3, 0.3, 0.3)
            highlight:SetAlpha(0)

            local ag = highlight:CreateAnimationGroup()
            local sa1 = ag:CreateAnimation("Alpha")
            sa1:SetFromAlpha(0)
            sa1:SetToAlpha(1)
            sa1:SetSmoothing("OUT")
            sa1:SetDuration(0.1)
            sa1:SetOrder(1)

            local sa2 = ag:CreateAnimation("Alpha")
            sa2:SetFromAlpha(1)
            sa2:SetToAlpha(0)
            -- sa2:SetSmoothing("IN")
            sa2:SetDuration(0.15)
            sa2:SetOrder(1)

            castbar.flash = ag


            castbar.SetColor = function(self, r,g,b)
                self:SetStatusBarColor(r, g, b)
                self.bg:SetColorTexture(r*0.2, g*0.2, b*0.2)
            end

            local updateCastBarColor = function(self, unit, name)
                if self.notInterruptible then
                    local r,g,b = 0.7, 0.7, 0.7
                    self:SetColor(r,g,b)
                elseif self.channeling then
                    local r,g,b = 0.8, 1, 0.3
                    self:SetColor(r,g,b)
                else
                    local r,g,b = 1, 0.65, 0
                    self:SetColor(r,g,b)
                end
            end
            castbar.PostCastNotInterruptible = updateCastBarColor
            castbar.PostCastInterruptible = updateCastBarColor
            -- castbar.PostCastStart = updateCastBarColor

            castbar.PostCastInterrupted = function(self, unit)
                self.status = "Interrupted"
                self.fading = true
                self.fadeStartTime = GetTime()
            end
            castbar.PostCastFailed = function(self, unit)
                self.status = "Failed"
                self.fading = true
                self.fadeStartTime = GetTime()
            end
            castbar.PostChannelFailed = function(self, unit)
                self.status = "Failed"
                self.fading = true
                self.fadeStartTime = GetTime()
            end
            castbar.PostCastStop = function(self, unit)
                -- self.status = "Stopped"
                -- self.fading = true
                self.flash:Play()
            end
            castbar.PostCastStart = function(self, unit)
                self.status = nil
                self.fading = nil
                self.fadeStartTime = nil
                self:SetAlpha(1)
                updateCastBarColor(self, unit)
            end
            castbar.PostChannelStart = castbar.PostCastStart

            castbar.OnUpdate = function(self, elapsed)
                if(self.casting) then
                    local duration = self.duration + elapsed
                    if(duration >= self.max) then
                        self.casting = nil
                        self.channeling = nil
                        self.fading = true
                        self.fadeStartTime = GetTime()
                    end

                    self.duration = duration
                    self:SetValue(duration)
                elseif(self.channeling) then
                    local duration = self.duration - elapsed
                    if(duration <= 0) then
                        self.channeling = nil
                        self.casting = nil
                        self.fading = true
                        self.fadeStartTime = GetTime()
                    end

                    self.duration = duration
                    self:SetValue(duration)
                elseif(self.holdTime > 0) then
                    self.holdTime = self.holdTime - elapsed
                else
                    self.casting = nil
                    self.castID = nil
                    self.channeling = nil
                    self.fading = true
                    if not self.fadeStartTime then
                        self.fadeStartTime = GetTime()
                    end
                end

                if(self.fading) then
                    local timePassed = GetTime() - self.fadeStartTime

                    local status = self.status
                    if status then
                        if status == "Interrupted" or status == "Failed" then
                            self:SetColor(1, 0.3, 0.3)
                        end
                    else
                        self:SetColor(0.8, 1, 0.3)
                    end

                    self:SetAlpha(1 - timePassed*2)
                    if timePassed*2 >= 1 then
                        self.fading = nil
                        self:Hide()
                    end
                end

            end


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

        if not isClassic then
            -- Buffs
            local buffs = CreateFrame("Frame", "$parentBuffs", self)
            buffs:SetPoint("LEFT", self, "RIGHT", 5,-3)
            buffs:SetHeight(20)
            buffs:SetWidth(100)
            buffs.debuffFilter = "HELPFUL"; -- namepalte filter doesn't work in classic
            buffs.num = 3
            buffs.PostCreateIcon = PostCreate

            buffs.PostUpdateIcon = function(icons, unit, button, index, position, duration, expiration, debuffType, isStealable)
                local width = button:GetWidth()
                button:SetHeight(width*0.7)
            end

            buffs.initialAnchor = "TOPLEFT"
            buffs.CustomFilter = BuffsPurgeableFilter

            buffs["spacing-x"] = 3
            buffs["growth-x"] = "RIGHT"
            buffs["growth-y"] = "UP"
            buffs.size = 20

            self.Buffs = buffs

        end



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


        local raidicon = self.Health:CreateTexture(nil, "OVERLAY")
        raidicon:SetHeight(26)
        raidicon:SetWidth(26)
        raidicon:SetPoint("LEFT", self.Health, "RIGHT",5,0)
        self.RaidTargetIndicator = raidicon

    end
end


oUF:RegisterStyle("oUF_NugNameplates", ns.oUF_NugNameplates)
oUF:SetActiveStyle"oUF_NugNameplates"
oUF:SpawnNamePlates("oUF_Nameplate", ns.NameplateCallback)