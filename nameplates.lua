local addonName, ns = ...

NugNameplates = CreateFrame("Frame", nil, UIParent)
local NugNameplates = NugNameplates
NugNameplates:RegisterEvent("ADDON_LOADED")

NugNameplates:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, event, ...)
end)

local apiLevel = math.floor(select(4,GetBuildInfo())/10000)
local isClassic = apiLevel <= 2
local isBC = apiLevel == 2
local isMainline = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE -- WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local filterOwnSpells = false

local LSM = LibStub("LibSharedMedia-3.0")
-- LSM:Register("statusbar", "Gradient", [[Interface\AddOns\Aptechka\gradient.tga]])
-- LSM:Register("font", "AlegreyaSans-Medium", [[Interface\AddOns\Nug\AlegreyaSans-Medium.ttf]],  GetLocale() ~= "enUS" and 15)

local texture = "Interface\\BUTTONS\\WHITE8X8"
local shieldTexture = "Interface\\AddOns\\NugNameplates\\shieldtex.tga"
local barTexture = "Interface\\AddOns\\NugNameplates\\bar.tga"
local flat = "Interface\\BUTTONS\\WHITE8X8"
local targetGlowTexture = "Interface\\AddOns\\NugNameplates\\target-glow.tga"

local healthbar_width = 85
local healthbar_height = 7
local castbar_height = 10
local total_height = castbar_height + healthbar_height + 2

local hsv_shift = ns.hsv_shift

local LibAuraTypes = LibStub("LibAuraTypes", true)
local ROOT_PRIO = LibAuraTypes and LibAuraTypes.GetDebuffTypePriority("ROOT") or 0

local font3 = [[Interface\AddOns\NugNameplates\fonts\AlegreyaSans-Medium.ttf]]

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
local UnitClass = UnitClass
local UnitIsTapDenied = UnitIsTapDenied
local UnitReaction = UnitReaction

local SpecialThreatStatus
local UnitEngaged

-- local healthColor = { 1, 0.12, 0 }
local healthColor = { 1, 0.3, 0.22 }
local importantNPC = { hsv_shift(healthColor, -0.1, 0, 0.0) }
local importantNPC2 = { hsv_shift(healthColor, -0.2, 0, 0.0) }
local importantNPC3 = { hsv_shift(healthColor, 0.1, 0, 0.0) }
local gtfo = { 1, 0.8, 0.8 }
local MPlusAffix = { 0.8, 0.4, 0 }
local garbage = {0.4, 0.4, 0.4}

local colors = setmetatable({
    -- health = { .7, 0.2, 0.1},
    health = healthColor,
    execute = { 1, 0, 0.8 },
    aggro_lost = { 0.6, 0, 1},
    aggro_transitioning = { 1, 0.4, 0},
    aggro_offtank = { 0, 1, 0.5},

    notInterruptible = {0.7, 0.7, 0.7},
    casting = {1, 0.65, 0},
    channeling = {0.8, 1, 0.3},
}, {__index = ns.colors})

local defaults = {
    profile = {
        nameFont = "AlegreyaSans-Medium"
    }
}


NugNameplates:RegisterEvent("PLAYER_TARGET_CHANGED")
NugNameplates:RegisterEvent("PLAYER_FOCUS_CHANGED")
NugNameplates:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
NugNameplates:RegisterEvent("NAME_PLATE_UNIT_ADDED")
NugNameplates:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
NugNameplates:RegisterEvent("QUEST_LOG_UPDATE")

function NugNameplates:ADDON_LOADED(event, loadedName)
    if loadedName ~= addonName then return end

    NugNameplatesDB = NugNameplatesDB or {}
    -- self:DoMigrations(NugNameplatesDB)
    self.db = LibStub("AceDB-3.0"):New("NugNameplatesDB", defaults, "Default") -- Create a DB using defaults and using a shared default profile
    -- db = self.db

    self.db.RegisterCallback(self, "OnProfileChanged", "Reconfigure")
    self.db.RegisterCallback(self, "OnProfileCopied", "Reconfigure")
    self.db.RegisterCallback(self, "OnProfileReset", "Reconfigure")

end

function NugNameplates:Reconfigure()
end



local IsInExecuteRange
function ns.UpdateExecute(new_execute)
    IsInExecuteRange = new_execute
end

local isPlayerTanking
function ns.UpdateTankingStatus(new)
    isPlayerTanking = new
end


local unitNameplates = {}

function NugNameplates:ForEachNameplate(func)
    for unit, nameplate in pairs(unitNameplates) do
        func(nameplate.NugPlate, unit)
    end
end

local nonTargeAlpha = 0.6
-- local mouseoverAlpha = 0.7

function NugNameplates:PLAYER_TARGET_CHANGED(event)
    local targetFrame = C_NamePlate.GetNamePlateForUnit("target")
    local focusFrame = C_NamePlate.GetNamePlateForUnit("focus")
    local mouseoverFrame = C_NamePlate.GetNamePlateForUnit("mouseover")
    local playerFrame = C_NamePlate.GetNamePlateForUnit("player")
    for _, frame in pairs(C_NamePlate.GetNamePlates()) do
        if frame ~= playerFrame then
            if frame == targetFrame or frame == focusFrame or not UnitExists("target") then
                if frame.NugPlate then
                    frame.NugPlate:SetAlpha(1)
                    frame.NugPlate.Health.highlight:Hide()
                    -- frame.NugPlate.Health.lost:Show()
                    if frame == targetFrame then
                        frame.NugPlate.TargetGlow:Show()
                    else
                        frame.NugPlate.TargetGlow:Hide()
                    end

                    if frame == focusFrame then
                        frame.NugPlate.FocusGlow:Show()
                    else
                        frame.NugPlate.FocusGlow:Hide()
                    end
                end
            else
                if frame.NugPlate then
                    frame.NugPlate:SetAlpha(nonTargeAlpha)
                    frame.NugPlate.Health.highlight:Hide()
                    -- frame.NugPlate.Health.lost:Hide()
                    frame.NugPlate.TargetGlow:Hide()
                    frame.NugPlate.FocusGlow:Hide()
                end
            end

            -- propblem here is UPDATE_MOUSEOVER_UNIT doesn't fire when mouseover becomes nil
            -- So ideally could try using a state driver
            -- RegisterStateDriver(YourCustomFrame, "visibility", "[@mouseover,exists] show; hide")
            if frame == mouseoverFrame and UnitExists("mouseover") and mouseoverFrame ~= targetFrame then
                if frame.NugPlate then
                    frame.NugPlate.Health.highlight:Show()
                end
            else
                if frame.NugPlate then
                    frame.NugPlate.Health.highlight:Hide()
                end
            end
        end
	end
end
NugNameplates.UPDATE_MOUSEOVER_UNIT = NugNameplates.PLAYER_TARGET_CHANGED
NugNameplates.PLAYER_FOCUS_CHANGED = NugNameplates.PLAYER_TARGET_CHANGED

local function GetUnitNPCID(unit)
    local guid = UnitGUID(unit)
    local _, _, _, _, _, npcID = strsplit("-", guid);
    return tonumber(npcID)
end

hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
	if not frame:IsForbidden() then
        -- frame.name:SetText(GetUnitName(frame.unit, true))
        frame.name:SetText(GetUnitName(frame.unit, false))
    end
end)


NugNameplates:RegisterEvent("RAID_TARGET_UPDATE")

local function UpdateRaidIcon(frame, unit)
    local index = GetRaidTargetIndex(unit)
    local raidicon = frame.RaidTargetIndicator
    if(index) then
		SetRaidTargetIconTexture(raidicon, index)
        raidicon:Show()
        if index ~= raidicon.current then
            if raidicon.anim:IsPlaying() then
                raidicon.anim:Stop()
            end
            raidicon.anim:Play()
        end
	else
		raidicon:Hide()
    end
    raidicon.current = index
end
function NugNameplates:RAID_TARGET_UPDATE(event)
    for unit, nameplate in pairs(unitNameplates) do
        UpdateRaidIcon(nameplate.NugPlate, unit)
    end
end


local NugPlate = {}

local UnitEventHandler = CreateFrame("Frame", nil, UIParent)

UnitEventHandler:SetScript("OnEvent", function(self, event, unit, ...)
    local np = unitNameplates[unit]
    if not np then return end
    local frame = np.NugPlate

    return self[event](frame, event, unit, ...)
end)

-- Name
UnitEventHandler:RegisterEvent('UNIT_NAME_UPDATE')

local function UpdateName(frame, unit)
    -- local name = ns.GetCustomName(unit)
    local name = UnitName(unit)
    frame.Name:SetText(name)

    local guild = GetGuildInfo(unit)
    if guild == 0 then guild = nil end
    frame.GuildName:SetText(guild)
end
function UnitEventHandler:UNIT_NAME_UPDATE(event, unit)
    UpdateName(self, unit)
end


-- UnitEventHandler:RegisterEvent('UNIT_AURA')
local function UpdateAuras(frame, unit)

end
--[[
function UnitEventHandler:UNIT_AURA(event, unit)
    UpdateAuras(self, unit)
end
]]

-- Health
UnitEventHandler:RegisterEvent('UNIT_HEALTH')
UnitEventHandler:RegisterEvent('UNIT_MAXHEALTH')
-- if(element.colorDisconnected) then
UnitEventHandler:RegisterEvent('UNIT_CONNECTION')
-- if(element.colorSelection) then
UnitEventHandler:RegisterEvent('UNIT_FLAGS')
-- if(element.colorTapping) then
UnitEventHandler:RegisterEvent('UNIT_FACTION')
-- if(element.colorThreat) then
UnitEventHandler:RegisterEvent('UNIT_THREAT_LIST_UPDATE')

UnitEventHandler:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED')
local function UpdateAbsorb(frame, unit)
    local absorbBar = frame.Health.absorb
    local healCalc = frame.Health.healCalc
    UnitGetDetailedHealPrediction(unit, nil, healCalc)

    local absorb, isOverabsorb = healCalc:GetDamageAbsorbs()

    absorbBar:SetValue(absorb)
    -- local unclampedAbsorb = healCalc:GetTotalDamageAbsorbs()
    -- frame.absorbOverflow:SetValue(unclampedAbsorb)
    -- frame.absorbOverflow:SetAlphaFromBoolean(isOverabsorb, 1, 0)
end
function UnitEventHandler:UNIT_ABSORB_AMOUNT_CHANGED(event, unit)
    UpdateAbsorb(self, unit)
end

UnitEventHandler:RegisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED')
local function UpdateHealAbsorb(frame, unit)
    local healAbsorbBar = frame.Health.healAbsorb
    local healCalc = frame.Health.healCalc
    UnitGetDetailedHealPrediction(unit, nil, healCalc)

    local healAbsorb, isHealOverabsorb = healCalc:GetHealAbsorbs()
    healAbsorbBar:SetValue(healAbsorb)
end
function UnitEventHandler:UNIT_HEAL_ABSORB_AMOUNT_CHANGED(event, unit)
    UpdateHealAbsorb(self, unit)
end


local function UpdateHealthColor(frame, unit)
    local parent = frame:GetParent()

    local sts = SpecialThreatStatus(unit)
    local reaction = UnitReaction(unit, 'player')
    local health = frame.Health

    -- local npcID = frame["npcID"]
    -- local npcColor = npc_colors[npcID]

	local r, g, b, t
	if(health.colorTapping and not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
		t = colors.tapped
	elseif(health.colorDisconnected and health.disconnected) then
        t = colors.disconnected
    elseif(health.colorClass and UnitIsPlayer(unit)) then
    --     (health.colorClassNPC and not UnitIsPlayer(unit)) or
    --     (health.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
        local _, class = UnitClass(unit)
        t = colors.class[class]


    elseif not UnitIsPlayer(unit) and sts then
        t = colors[sts]
    -- elseif IsInExecuteRange and IsInExecuteRange(unit) then
        -- t = colors.execute
    elseif(health.colorReaction and not UnitEngaged(unit, 'player') and reaction >= 4) then
        t = colors.reaction[reaction]
    -- elseif npcColor then
    --     t = npcColor
    elseif(health.colorHealth) then
		t = colors.health
    end

    if(t) then
        r, g, b = t[1], t[2], t[3]
    end

    if(b) then
        health:SetColor(r, g, b)
    end
end


local function UpdateMaxHealth(frame, unit)
    local hm = UnitHealthMax(unit)

    local health = frame.Health
    health:SetMinMaxValues(0, hm)
    health.lost:SetMinMaxValues(0, hm)
    health.absorb:SetMinMaxValues(0, hm)
    health.healAbsorb:SetMinMaxValues(0, hm)
end


local sparkCurve = C_CurveUtil.CreateCurve();
sparkCurve:SetType(Enum.LuaCurveType.Step)
sparkCurve:AddPoint(0.0, 1);
sparkCurve:AddPoint(1.0, 0);
local function UpdateHealth(frame, unit)
    local healthBar = frame.Health
    local healCalc = frame.Health.healCalc
    UnitGetDetailedHealPrediction(unit, nil, healCalc)
    local health = healCalc:GetCurrentHealth()
    local healthPercent = healCalc:GetCurrentHealthPercent()
    local healthMissing = healCalc:GetMissingHealth()
    local incomingHeal = healCalc:GetIncomingHeals()
    local absorb, isOverabsorb = healCalc:GetDamageAbsorbs()
    local healAbsorb, isHealOverabsorb = healCalc:GetHealAbsorbs()
    local unclampedAbsorb = healCalc:GetTotalDamageAbsorbs()
    local healthMax = healCalc:GetMaximumHealth()

    local sparkAlpha = UnitHealthPercent(unit, nil, sparkCurve)

    -- health = 10000
    -- absorb = 5000
    -- healAbsorb = 5000


    if UnitIsConnected(unit) then
		healthBar:SetValue(health)
        healthBar.lost:SetValue(health, 1)
        healthBar.absorb:SetValue(absorb)
        healthBar.healAbsorb:SetValue(healAbsorb)
        healthBar.spark:SetAlpha(sparkAlpha)
	else
		healthBar:SetValue(healthMax)
        healthBar.lost:SetValue(0)
        healthBar.absorb:SetValue(0)
        healthBar.healAbsorb:SetValue(0)
        healthBar.spark:SetAlpha(0)
    end

    UpdateHealthColor(frame, unit)
end

function UnitEventHandler:UNIT_HEALTH(event, unit)
    UpdateHealth(self, unit)
end
function UnitEventHandler:UNIT_MAXHEALTH(event, unit)
    UpdateMaxHealth(self, unit)
end
UnitEventHandler.UNIT_CONNECTION = UnitEventHandler.UNIT_HEALTH
UnitEventHandler.UNIT_FLAGS = UnitEventHandler.UNIT_HEALTH
UnitEventHandler.UNIT_THREAT_LIST_UPDATE = UnitEventHandler.UNIT_HEALTH



UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_START")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_DELAYED")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_STOP")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_FAILED")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_EMPOWER_START")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_EMPOWER_UPDATE")
UnitEventHandler:RegisterEvent("UNIT_SPELLCAST_EMPOWER_STOP")


-- local CastOnUpdate = function(self, elapsed)
--     local v = self.elapsed + elapsed
--     local remains = self.endTime - (v+self.startTime)
--     self.elapsed = v

--     if self.fadingStartTime then
--         local t = GetTime() - self.fadingStartTime
--         local a = 4* math.max(0, 0.25 - t)
--         self:SetAlpha(a)
--         self:SetValue(self.endTime)
--         if a < 0 then
--             self:Hide()
--         end
--     else
--         local val
--         if self.channeling then val = self.startTime + remains
--         else val = self.endTime - remains end
--         self:SetValue(val)
--         -- self.timeText:SetFormattedText("%.1f",remains)
--         if remains <= -0.5 then
--             self:Hide()
--         end
--     end
-- end

local coloredSpells = {}
local function UpdateCastingInfo(self,name,texture,startTime,duration,castID, notInterruptible, spellID)
    if not startTime then return end
    self.castID = castID
    self:SetTimerDuration(duration)
    -- self.startTime = startTime / 1000
    -- self.endTime = endTime / 1000
    -- self:SetMinMaxValues(self.startTime, self.endTime)
    -- self.elapsed = GetTime() - self.startTime
    self.Icon:SetTexture(texture)
    self.Text:SetText(name)

    local color = self.channeling and colors.channeling or colors.casting
    self:SetColor(unpack(color))
    self.isActive = true
    self:Show()

    if self.shield then
        self.shield:Show()
        self.shield:SetAlphaFromBoolean(notInterruptible, 1, 0)
    end
end


local function CastStart(frame, unit)
    if frame.NAME_ONLY then return end
    local castbar = frame.Castbar
    local name, text, texture, startTime, endTime, isTradeSkill, castGUID, notInterruptible, spellID, castID, delayTimeMs = UnitCastingInfo(unit)
    local duration = UnitCastingDuration(unit)
    castbar.channeling = false
    castbar.empowered = false
    if castbar.fader:IsPlaying() then
        castbar.fader:Stop()
    end
    castbar:SetAlpha(1)
    UpdateCastingInfo(castbar, name, texture, startTime, duration, castID, notInterruptible, spellID)
end
function UnitEventHandler:UNIT_SPELLCAST_START(event, unit)
    CastStart(self, unit)
end
UnitEventHandler.UNIT_SPELLCAST_DELAYED = UnitEventHandler.UNIT_SPELLCAST_START

local function ChannelStart(frame, unit)
    if frame.NAME_ONLY then return end
    -- if unit ~= frame.unit then return end
    local castbar = frame.Castbar
    local name, text, texture, startTime, endTime, isTradeSkill,         notInterruptible, spellID, isEmpowered, numStages, castID = UnitChannelInfo(unit)
    local duration
    if(isEmpowered) then
        duration = UnitEmpoweredChannelDuration(unit)
    else
        duration = UnitChannelDuration(unit)
    end
    castbar.channeling = not isEmpowered
    castbar.empowered = isEmpowered
    if castbar.fader:IsPlaying() then
        castbar.fader:Stop()
    end
    castbar:SetAlpha(1)
    UpdateCastingInfo(castbar, name,texture,startTime,duration, castID, notInterruptible, spellID)
end
function UnitEventHandler:UNIT_SPELLCAST_CHANNEL_START(event,unit)
    ChannelStart(self, unit)
end
UnitEventHandler.UNIT_SPELLCAST_EMPOWER_START = UnitEventHandler.UNIT_SPELLCAST_CHANNEL_START
UnitEventHandler.UNIT_SPELLCAST_CHANNEL_UPDATE = UnitEventHandler.UNIT_SPELLCAST_CHANNEL_START
UnitEventHandler.UNIT_SPELLCAST_EMPOWER_UPDATE = UnitEventHandler.UNIT_SPELLCAST_CHANNEL_START

local function CastStop(frame, unit, castIGUID, spellID, castID, interruptedBy, empowerComplete)
    local castbar = frame.Castbar

    if castbar.castID ~= castID then return end

    if interruptedBy then
        castbar:SetColor(1,0,0)
    end
    if empowerComplete then
        castbar:SetColor(0,1,0)
    end

    castbar:SetMinMaxValues(0,1)
    castbar:SetValue(castbar.channeling and 0 or 1)
    castbar.fader:Play()
end
local function CastStopInstant(frame, unit)
    local castbar = frame.Castbar
    castbar.fadingStartTime = GetTime() - 3
    castbar:Hide()
end
function UnitEventHandler:UNIT_SPELLCAST_STOP(event, unit, castGUID, spellID, ...)
    local castID, interruptedBy, empowerComplete
	if(event == 'UNIT_SPELLCAST_STOP') then
		castID = ...
	elseif(event == 'UNIT_SPELLCAST_EMPOWER_STOP') then
		empowerComplete, interruptedBy, castID = ...
	elseif(event == 'UNIT_SPELLCAST_CHANNEL_STOP') then
		interruptedBy, castID = ...
	end

    CastStop(self, unit, castGUID, spellID, castID, interruptedBy, empowerComplete)
end
UnitEventHandler.UNIT_SPELLCAST_CHANNEL_STOP = UnitEventHandler.UNIT_SPELLCAST_STOP
UnitEventHandler.UNIT_SPELLCAST_EMPOWER_STOP = UnitEventHandler.UNIT_SPELLCAST_STOP

local function CastFailed(frame, unit, castGUID, spellID, castID, interruptedBy)
    -- if unit ~= frame.unit then return end
    local castbar = frame.Castbar
    if castbar.castID == castID then
        CastStop(frame, unit, castGUID, spellID, castID, interruptedBy)
        castbar:SetColor(1,0,0)
    end
end
function UnitEventHandler:UNIT_SPELLCAST_FAILED(event, unit, castGUID, spellID, ...)
    local castID, interruptedBy
	if(event == 'UNIT_SPELLCAST_INTERRUPTED') then
		interruptedBy, castID = ...
	elseif(event == 'UNIT_SPELLCAST_FAILED') then
		castID = ...
	end

    CastFailed(self, unit, castGUID, spellID, castID, interruptedBy)
end
UnitEventHandler.UNIT_SPELLCAST_INTERRUPTED = UnitEventHandler.UNIT_SPELLCAST_FAILED



local function CastUpdateInterruptible(frame, isInterruptible)
    local castbar = frame.Castbar
    if isInterruptible then -- in this case it's not a secret value, it is in CastStart tho
        local color = castbar.channeling and colors.channeling or colors.casting
        castbar:SetColor(unpack(color))
    else
        castbar:SetColor(unpack(colors.notInterruptible))
    end
    castbar.shield:Show()
    castbar.shield:SetAlphaFromBoolean(notInterruptible, 1, 0)
end
function UnitEventHandler:UNIT_SPELLCAST_INTERRUPTIBLE(event,unit)
    CastUpdateInterruptible(self, true)
end
function UnitEventHandler:UNIT_SPELLCAST_NOT_INTERRUPTIBLE(event,unit)
    CastUpdateInterruptible(self, false)
end

local function CastSucceeded(frame, unit, castGUID, spellID, castID)
    local castbar = frame.Castbar
    if castbar.channeling then return end
    if castbar.empowered then return end
    if castbar.castID == castID then
        CastStop(frame, unit, castGUID, spellID, castID)
        castbar:SetColor(0,1,0)
    end
end
function UnitEventHandler:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellID, castID)
    CastSucceeded(self, unit, castGUID, spellID, castID)
end

local function UpdateUnitCast(frame, unit)
    if UnitCastingInfo(unit) then return CastStart(frame, unit) end
    if UnitChannelInfo(unit) then return ChannelStart(frame, unit) end
    CastStopInstant(frame, unit)
end


local function ToggleNameOnly(frame, enable)
    local nameFont = LSM:Fetch("font", NugNameplates.db.profile.nameFont)
    if enable then
        frame.NAME_ONLY = true
        frame.Name:SetFont(nameFont, 17, "OUTLINE")
        frame.Name:SetPoint("BOTTOM", frame.Health, "TOP",0,-15)
        frame.Name:SetShadowOffset(1,-1)
        frame.GuildName:Show()
        frame.Health:Hide()
        frame.Castbar:Hide()
        frame.Buffs:Hide()
        frame.Debuffs:Hide()
    else
        frame.NAME_ONLY = false
        -- frame.Name:SetScale(1)
        frame.Name:SetFont(nameFont, 10, "OUTLINE")
        frame.Name:SetPoint("BOTTOM", frame.Health, "TOP",0,1)
        frame.Name:SetShadowOffset(0,0)
        frame.GuildName:Hide()
        frame.Health:Show()
        frame.Castbar:Show()
        frame.Buffs:Show()
        frame.Debuffs:Show()
    end
end

local function UpdateQuestStatus(frame, unit)
    --[[
    if NugNameplates:IsQuestUnit(unit) then
        frame.questIcon:Show()
    else
        frame.questIcon:Hide()
    end
    ]]
end
function NugNameplates:QUEST_LOG_UPDATE(event, unit)
    self:ForEachNameplate(UpdateQuestStatus)
end

function NugNameplates:NAME_PLATE_UNIT_ADDED(event, unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end

    unitNameplates[unit] = nameplate

    NugNameplates:PLAYER_TARGET_CHANGED()

    -- Create
    if not nameplate.NugPlate then
        nameplate.NugPlate = CreateFrame('Frame', "$parentNugPlate", nameplate)
        nameplate.NugPlate:EnableMouse(false)

        ns.SetupFrame(nameplate.NugPlate, unit)
        -- nameplate.NugPlate.isNamePlate = true
    end

    local frame = nameplate.NugPlate -- our root custom nameplate frame

    local isPlayer = UnitIsPlayer(unit)
    local isAttackable = UnitCanAttack("player", unit)
    local isFriendly = UnitReaction(unit, "player") >= 4
    if isPlayer and not isAttackable and isFriendly then
        ToggleNameOnly(frame, true)
    else
        ToggleNameOnly(frame, false)
    end
    --
    -- Update for fresh added unit

    UpdateName(frame, unit)
    UpdateMaxHealth(frame, unit)
    UpdateHealth(frame, unit)
    UpdateAbsorb(frame, unit)
    UpdateHealAbsorb(frame, unit)
    UpdateQuestStatus(frame, unit)
    UpdateUnitCast(frame, unit)
    UpdateRaidIcon(frame, unit)
    UpdateAuras(frame, unit)

    -- frame.npcID = GetUnitNPCID(unit)

    -- default unitframes
    local default_nameplate = nameplate.UnitFrame
    default_nameplate:Hide()
    default_nameplate.selectionHighlight:Hide()
    default_nameplate:SetAlpha(0)
    default_nameplate.selectionHighlight:SetAlpha(0)


    --[[
    local parent = C_NamePlate.GetNamePlateForUnit(unit)
    if not UnitCanAttack(unit, "player") then
        parent.unitFrame:Hide() -- oUF

        -- default unitframes
        parent.UnitFrame:Show()
        -- parent.UnitFrame.selectionHighlight:Show()
        parent.UnitFrame:SetAlpha(1)
        parent.UnitFrame.selectionHighlight:SetAlpha(1)
    else
        parent.unitFrame:Show() -- oUF

        -- default unitframes
        parent.UnitFrame:Hide()
        parent.UnitFrame.selectionHighlight:Hide()
        parent.UnitFrame:SetAlpha(0)
        parent.UnitFrame.selectionHighlight:SetAlpha(0)
    end
    ]]
end

-- if faction changes need to reinit nameplate
UnitEventHandler.UNIT_FACTION = NugNameplates.NAME_PLATE_UNIT_ADDED

function NugNameplates:NAME_PLATE_UNIT_REMOVED(event, unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    nameplate.npcID = nil

    unitNameplates[unit] = nil
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
    -- overlay:SetTexture([[Interface\AddOns\NugNameplates\buffBorder]])
    if not button.isDebuff then
        overlay:Show()
        overlay:SetVertexColor(0.6,0.6,0.6, 1)
        overlay.Hide = overlay.Show
    end
end

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


local defaultUIFilter = function(name, icon, count, debuffType, duration, expirationTime, caster, isStealable,
    nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer,
    nameplateShowAll)

    return nameplateShowAll or
		   (nameplateShowPersonal and (caster == "player" or caster == "pet" or caster == "vehicle"));
end

-- oUF.Tags.Events["customName"] = "UNIT_NAME_UPDATE"
-- oUF.Tags.Methods["customName"] = function(unit)

-- end

function ns.GetCustomName(unit)
    if UnitIsPlayer(unit) then

        local name = UnitName(unit)
        local _, instanceType = GetInstanceInfo()
        if instanceType == "arena" then
            for i=1,3 do
                local arenaUnit = "arena"..i
                if UnitIsUnit(unit, arenaUnit) then
                    name = tostring(i)
                end
            end
        end

        local _, class = UnitClass(unit)
        local colorStr = RAID_CLASS_COLORS[class].colorStr

        return string.format("|c%s%s|r", colorStr, name)
    else
        local reaction = UnitReaction(unit, "player")
        local npcID = GetUnitNPCID(unit)
        if npcID then
            local newName = ns.npc_names[npcID]
            if newName then
                local lastWord = string.match(newName, "%s*([%w%.%'%-]+)$")
                return lastWord
            end
        end
        -- local isFriendly = reaction >= 4
        -- if isFriendly then
        --     return UnitName(unit)
        -- end
    end
    return ""
end

local function pixelperfect(val, region)
    if not PixelUtil then return val end
    region = region or UIParent
    return PixelUtil.GetNearestPixelSize(val, region:GetEffectiveScale(), val)
end
ns.pixelperfect = pixelperfect


local function MakeCompatibleAnimation(anim)
    if anim:GetObjectType() == "Scale" and anim.SetScaleFrom then
        return anim
    else
        anim.SetScaleFrom = anim.SetFromScale
        anim.SetScaleTo = anim.SetToScale
    end
    return anim
end

function ns.SetupFrame(self, unit)

        -- local healthbar_width = 85
        -- local healthbar_height = 7
        -- local castbar_height = 10
        -- local total_height = castbar_height + healthbar_height + 2
        local hmul = 0.90
        -- local vmul = 0.2
        local healthbar_width = pixelperfect(self:GetParent():GetWidth()*hmul, self)
        -- local healthbar_height = pixelperfect(self:GetParent():GetHeight()*vmul, self)
        local healthbar_height = pixelperfect(7, self)
        local castbar_height = pixelperfect(10, self)
        local total_height = castbar_height + healthbar_height + pixelperfect(2)
        local white = "Interface\\BUTTONS\\WHITE8X8"

        hooksecurefunc(self, "SetAlpha", function(self, alpha)
            if alpha == 1 then
                self.Health.lost:Show()
            else
                self.Health.lost:Hide()
            end
        end)

        self.colors = colors
        -- set size and points
        local width = healthbar_width
        local height = healthbar_height
        local ppw = width
        local pph = height
        healthbar_width = ppw
        castbar_height = pixelperfect(castbar_height, self)
        local pp1 = pixelperfect(1, self)
        self:SetSize(ppw, pph)
        self:SetPoint("CENTER", 0, 0)

        -- health bar
        local health = CreateFrame("StatusBar", nil, self)
        health:SetAllPoints()
        health:SetStatusBarTexture(barTexture)
        health:SetFrameLevel(6)
        -- health:SetPoint("LEFT")
        -- health:SetPoint("RIGHT")
        -- health:SetHeight(healthbar_height * 4)
        -- health:SetStatusBarTexture("Interface\\AddOns\\NugNameplates\\barSoft")
        health.colorHealth = true
        health.colorReaction = true
        health.colorClass = true
        health.colorTapping = true
        -- health.colorDisconnected = true
        health:SetAlpha(1)

        local spark = health:CreateTexture(nil, "OVERLAY")
		spark:SetTexture("Interface\\AddOns\\NugNameplates\\spark.tga")
        spark:SetAlpha(1)
        spark:SetWidth(10)
        spark:SetHeight(pph)
        spark:SetVertexColor(1,0.7,0)
        spark:SetPoint("CENTER",health:GetStatusBarTexture(), "RIGHT", 0,0)
		spark:SetBlendMode('ADD')
        health.spark = spark

        local healCalc = CreateUnitHealPredictionCalculator()
        healCalc:SetIncomingHealClampMode(0) -- Missing Health Clamp
        healCalc:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MissingHealthWithoutIncomingHeals) -- Missing Health Clamp
        healCalc:SetHealAbsorbClampMode(Enum.UnitHealAbsorbClampMode.CurrentHealth)
        healCalc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.Total)
        health.healCalc = healCalc

        self.Health = health

        local nameFont = LSM:Fetch("font", NugNameplates.db.profile.nameFont)
        local unitName = self:CreateFontString();
        unitName:SetFont(nameFont, 10, "OUTLINE")
        -- unitName:SetWidth(85)
        -- unitName:SetHeight(healthbar_height)
        unitName:SetJustifyH("CENTER")
        unitName:SetTextColor(1,1,1)
        unitName:SetPoint("BOTTOM", health, "TOP",0,1)
        -- self:Tag(unitName, '[customName]')
        self.Name = unitName

        local guildName = self:CreateFontString();
        guildName:SetFont(nameFont, 9, "OUTLINE")
        guildName:SetJustifyH("CENTER")
        guildName:SetTextColor(0.8,0.7,0.7)
        guildName:SetPoint("TOP", unitName, "BOTTOM",0,-1)
        -- self:Tag(guildName, '[customName]')
        self.GuildName = guildName

        health.SetColor = function(element, r,g,b)
            element:SetStatusBarColor(r, g, b)

            local bg = element.bg
            if(bg) then local mu = bg.multiplier or 1
                bg:SetVertexColor(r * mu, g * mu, b * mu)
            end

            -- local r2 = math.min(1, r+0.45)
            -- local g2 = math.min(1, g+0.45)
            -- local b2 = math.min(1, b+0.45)

            -- element.lost:SetStatusBarColor(r2,g2,b2)
            -- if element.absorb then
                -- element.absorb:SetStatusBarColor(r,g,b)
            -- end
        end

            -----------------
            -- ABSORB BAR
            -----------------
            local hpEdgeTexture = health:GetStatusBarTexture()

            local absorb = CreateFrame("StatusBar", nil, health)

            absorb:SetStatusBarTexture(shieldTexture)
            absorb:GetStatusBarTexture():SetHorizTile(true)
            absorb:GetStatusBarTexture():SetVertTile(true)
            absorb:SetStatusBarColor(0.8, 0.8, 1, 1)
            absorb:SetPoint("TOPLEFT", hpEdgeTexture, "TOPRIGHT")
            absorb:SetPoint("BOTTOMLEFT", hpEdgeTexture, "BOTTOMRIGHT")
            absorb:SetWidth(health:GetWidth())
            absorb:SetWidth(health:GetWidth())

            health.absorb = absorb

            ----------------------
            -- HEAL ABSORB
            ----------------------


            local healAbsorb = CreateFrame("StatusBar", nil, health)
            healAbsorb:SetStatusBarTexture(shieldTexture)
            healAbsorb:GetStatusBarTexture():SetHorizTile(true)
            healAbsorb:GetStatusBarTexture():SetVertTile(true)
            healAbsorb:SetStatusBarColor(0,0,0, 0.6)
            healAbsorb:SetPoint("TOPRIGHT", hpEdgeTexture, "TOPRIGHT")
            healAbsorb:SetPoint("BOTTOMRIGHT", hpEdgeTexture, "BOTTOMRIGHT")
            healAbsorb:SetWidth(healthbar_height)
            healAbsorb:SetWidth(health:GetWidth())
            healAbsorb:SetFillStyle(3) -- Reverse
            -- healAbsorb:SetStatusBarTexture("Interface\\AddOns\\Aptechka\\shieldtex")



            health.healAbsorb = healAbsorb

            --[[
            self.HealthPrediction = {
                -- myBar = myBar,
                -- otherBar = otherBar,
                absorbBar = absorb,
                healAbsorbBar = healAbsorb,
                -- overAbsorb = overAbsorb,
                -- overHealAbsorb = overHealAbsorb,
                -- maxOverflow = 1.05,
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
            ]]


        -----------------------
        -- HEALTH LOSS EFFECT
        -----------------------

        local healthlost = CreateFrame("StatusBar", nil, self)
        healthlost:SetStatusBarTexture(texture)
        healthlost:SetStatusBarColor(1, 0.6, 0.6)
        healthlost:SetAllPoints(health)
        health.lost = healthlost


        health.bg = self:CreateTexture(nil, "BACKGROUND", nil, 1)
        health.bg:SetAllPoints(health)
        health.bg:SetTexture(texture)
        -- health.bg:SetTexture("Interface\\AddOns\\NugNameplates\\barSoft")
        health.bg.multiplier = 0.15

        -- self.Health.PostUpdate = PostUpdateHealth
        self.Health.UpdateColor = function(frame, event, unit)
            local element = frame.Health
            local cur, max = UnitHealth(unit), UnitHealthMax(unit)
            element:PostUpdate(unit, cur, max)
        end

        local hl = health:CreateTexture(nil, "OVERLAY")
        hl:SetTexture(texture)
        hl:SetVertexColor(0.1,0.1,0.1)
        hl:SetBlendMode("ADD")
        hl:SetAllPoints()
        -- hl:SetAlpha(0)
        hl:Hide()
        health.highlight = hl


        local border = self:CreateTexture(nil, "BACKGROUND")
        border:SetTexture("Interface\\AddOns\\NugNameplates\\SoftEdgeBG2")
        border:SetVertexColor(0,0,0)
        border:SetTextureSliceMargins(10, 10, 10, 10)
        local offset = pixelperfect(2, self)
        border:SetPoint("TOPLEFT", health, "TOPLEFT", -offset, offset)
        border:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT", offset, -offset)
        --[[
        local sizeMul = 1.60
        local borderCENTER = self:CreateTexture(nil, "BACKGROUND")
        borderCENTER:SetTexture("Interface\\AddOns\\NugNameplates\\SoftEdgeBG2")
        borderCENTER:SetVertexColor(0,0,0)
        borderCENTER:SetTexCoord(11/64, 53/64, 0, 1)
        borderCENTER:SetPoint("LEFT",0,0)
        borderCENTER:SetPoint("RIGHT",0,0)
        borderCENTER:SetHeight(pph*sizeMul)

        local borderLEFT = self:CreateTexture(nil, "BACKGROUND")
        borderLEFT:SetTexture("Interface\\AddOns\\NugNameplates\\SoftEdgeBG2")
        borderLEFT:SetVertexColor(0,0,0)
        borderLEFT:SetTexCoord(0/64, 11/64, 0, 1)
        borderLEFT:SetPoint("RIGHT", borderCENTER, "LEFT", 0,0)
        borderLEFT:SetWidth(pph*sizeMul * 11/64)
        borderLEFT:SetHeight(pph*sizeMul)

        local borderRIGHT = self:CreateTexture(nil, "BACKGROUND")
        borderRIGHT:SetTexture("Interface\\AddOns\\NugNameplates\\SoftEdgeBG2")
        borderRIGHT:SetVertexColor(0,0,0)
        borderRIGHT:SetTexCoord(53/64, 64/64, 0, 1)
        borderRIGHT:SetPoint("LEFT", borderCENTER, "RIGHT", 0,0)
        borderRIGHT:SetWidth(pph*sizeMul * 11/64)
        borderRIGHT:SetHeight(pph*sizeMul)
        ]]

        -- local healthborder = MakeBorder(health, flat, -1, -1, -1, -1, -2)
        -- healthborder:SetVertexColor(0,0,0,1)

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

        -- local focusGlow = CreateFrame("Frame", nil, self, "BackdropTemplate")
        -- focusGlow:SetFrameLevel(health:GetFrameLevel()-1)
        -- local border_backdrop = {
        --     edgeFile = "Interface\\Addons\\NugNameplates\\glow", tileEdge = true, edgeSize = 6,
        -- }
        -- focusGlow:SetBackdrop(border_backdrop)

        -- focusGlow:SetPoint("TOPLEFT", health, "TOPLEFT",-6,6)
        -- focusGlow:SetPoint("BOTTOMRIGHT", health, "BOTTOMRIGHT",6,-6)
        -- focusGlow:SetBackdropBorderColor(0.2, 0.2, 1, 1)
        -- focusGlow:Hide()

        local focusGlow = health:CreateTexture(nil, "ARTWORK", nil, 6)
        focusGlow:SetAllPoints()
        -- focusGlow:SetBlendMode("ADD")
        -- focusGlow:SetHorizTile(true)
        focusGlow:SetVertexColor(0,0,0, 0.35)
        focusGlow:SetTexture("Interface\\Addons\\NugNameplates\\focusOverlay")
        focusGlow:Hide()
        self.FocusGlow = focusGlow

        local questIcon = health:CreateTexture(nil, "ARTWORK", nil, -3)
        questIcon:SetAtlas("questnormal")
        questIcon:SetPoint("RIGHT", health, "LEFT", 0, 0)
        questIcon:SetSize(16, 16)
        questIcon:Hide()
        self.questIcon = questIcon


        -- if not isClassic then
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

            local castbarborder = MakeBorder(castbar, flat, -pp1, -pp1, -pp1, -pp1, -2)
            castbarborder:SetVertexColor(0,0,0,1)

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


            local spellText = castbar:CreateFontString();
            spellText:SetFont(nameFont, 11, "OUTLINE")
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


            local faderGroup = castbar:CreateAnimationGroup()
            local fadeAnim = faderGroup:CreateAnimation("Alpha")
            fadeAnim:SetFromAlpha(1)
            fadeAnim:SetToAlpha(0)
            fadeAnim:SetDuration(0.5)
            faderGroup:SetScript("OnFinished", function(self)
                local parent = self:GetParent()
                parent:Hide()
            end)
            castbar.fader = faderGroup


            castbar.shield = castbar:CreateTexture(nil, "ARTWORK")


            self.Castbar = castbar
        -- end

        local buffs = ns.AuraHeader:Create("$parentBuffs", self, "HELPFUL", 3)
        buffs:SetIconSize(pixelperfect(17), pixelperfect(17*0.7))
        buffs:SetAttachPoints("BOTTOMRIGHT", "BOTTOMLEFT", -3)
        buffs:SetSize(healthbar_width, 30)
        buffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 5)

        local debuffs = ns.AuraHeader:Create("$parentDebuffs", self, "HARMFUL|INCLUDE_NAME_PLATE_ONLY", 5)
        debuffs:SetIconSize(pixelperfect(17), pixelperfect(17*0.7))
        debuffs:SetAuraFilter(defaultUIFilter)
        debuffs:SetAttachPoints("BOTTOMLEFT", "BOTTOMRIGHT", 3)
        debuffs:SetSize(healthbar_width, 30)
        debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 5)

        debuffs:SetMasterHeader(buffs)

        self.Buffs = buffs
        self.Debuffs = debuffs




        --[==[
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

        -- Dispellable buffs header
        if not isClassic then
            -- Buffs
            local buffs = CreateFrame("Frame", "$parentDispellableBuffs", self)
            buffs:SetPoint("LEFT", self, "RIGHT", 5,-3)
            buffs:SetHeight(20)
            buffs:SetWidth(100)
            buffs.filter = "HELPFUL"; -- namepalte filter doesn't work in classic
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

        --]==]

        --[===[
        -- all buffs
        if not isClassic then
            -- Buffs
            local buffs = CreateFrame("Frame", "$parentBuffs", self)
            buffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 4)
            buffs:SetHeight(25)
            buffs:SetWidth(150)
            buffs.filter = "HELPFUL|INCLUDE_NAME_PLATE_ONLY"; -- namepalte filter doesn't work in classic
            buffs.size = 15
            buffs.num = 3
            buffs.PostCreateIcon = PostCreate

            buffs.PostUpdateIcon = function(icons, unit, button, index, position, duration, expiration, debuffType, isStealable)
                local width = button:GetWidth()
                button:SetHeight(width*0.7)
            end

            buffs.initialAnchor = "BOTTOMRIGHT"

            buffs["spacing-x"] = 3
            buffs["growth-x"] = "LEFT"
            buffs["growth-y"] = "UP"


            self.Buffs = buffs
        end
        ]===]



        local OnHealthEvent = function(self, event, unit)
            if(not unit or self.unit ~= unit) then return end
            self.Health:ForceUpdate()
        end


        self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", OnHealthEvent)


        do
            local raidicon = self:CreateTexture(nil, "OVERLAY")
            raidicon:SetHeight(26)
            raidicon:SetWidth(26)
            raidicon:Hide()
            raidicon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
            raidicon:SetPoint("LEFT", self.Health, "RIGHT",5,0)
            self.RaidTargetIndicator = raidicon

            local ag = raidicon:CreateAnimationGroup()

            local a1 = MakeCompatibleAnimation(ag:CreateAnimation("Scale"))
            a1:SetOrigin("CENTER",0,0)
            a1:SetScaleFrom(0.3, 0.3)
            a1:SetScaleTo(1.2, 1.2)
            a1:SetDuration(0.1)
            a1:SetOrder(1)

            local a2 = MakeCompatibleAnimation(ag:CreateAnimation("Scale"))
            a2:SetOrigin("CENTER",0,0)
            a2:SetScaleFrom(1, 1)
            a2:SetScaleTo(1/1.2, 1/1.2)
            a2:SetDuration(0.08)
            a2:SetOrder(2)
            raidicon.anim = ag
        end


end


-- oUF:RegisterStyle("NugNameplates", ns.NugNameplates)
-- oUF:SetActiveStyle"NugNameplates"
-- oUF:SpawnNamePlates("oUF_Nameplate", ns.NameplateCallback)
