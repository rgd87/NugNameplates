local addonName, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")

local AuraHeader = {}
ns.AuraHeader = AuraHeader

local MakeBorder = function(self, tex, left, right, top, bottom, level)
    local t = self:CreateTexture(nil,"BORDER",nil,level)
    t:SetTexture(tex)
    t:SetPoint("TOPLEFT", self, "TOPLEFT", left, -top)
    t:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -right, bottom)
    return t
end

local function SetIconTexCoord(texture, w, h)
    local vscale = math.min(w/h, 1)
    local hscale = math.min(h/w, 1)
    local hm = 0.8 * (1-hscale) * 0.5 -- half of the texcoord height * scale difference
    local vm = 0.8 * (1-vscale) * 0.5
    texture:SetTexCoord(0.1+vm, 0.9-vm, 0.1+hm, 0.9-hm)
end

local function AddStackText(parent, anchorRegion)
    local stackframe = CreateFrame("Frame", nil, parent)
    stackframe:SetAllPoints(parent)
    local stacktext = stackframe:CreateFontString(nil,"ARTWORK")
    stacktext:SetDrawLayer("ARTWORK",1)
    stacktext:SetJustifyH"RIGHT"
    stacktext:SetPoint("BOTTOMRIGHT", anchorRegion, "BOTTOMRIGHT", 3,-1)
    stacktext:SetTextColor(1,1,1)
    return stacktext
end
local function UpdateFontStringSettings(text, fontName, fontSize, effect)
    local font = LSM:Fetch("font",  fontName)
    local flags = effect == "OUTLINE" and "OUTLINE"
    if effect == "SHADOW" then
        text:SetShadowOffset(1,-1)
    else
        text:SetShadowOffset(0,0)
    end
    text:SetFont(font, fontSize, flags)
end

local function FillIcon(f, icon, count, debuffType, duration, expirationTime, isStealable)
    f.icon:SetTexture(icon)
    f.stacktext:SetText(count > 1 and count or "")
    f.cooldown:SetCooldown(expirationTime-duration, duration)
    if isStealable then
        f.dispel:Show()
    else
        f.dispel:Hide()
    end
end

local function CreateIcon(parent, prev, width, height)

    local f = CreateFrame("Frame", nil, parent)

    f:SetWidth(width);
    f:SetHeight(height)

    local p = ns.pixelperfect(1)
    local blackLayer = MakeBorder(f, "Interface\\BUTTONS\\WHITE8X8", -1, -1, -1, -1, -2)
    blackLayer:SetVertexColor(0,0,0,0.4)
    blackLayer:SetDrawLayer("ARTWORK", -2)

    local border = 1

    local tex = f:CreateTexture(nil,"ARTWORK")
    f.icon = tex
    tex:SetAllPoints()
    SetIconTexCoord(tex, width, height)

    local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cooldown = cd
    cd.noCooldownCount = true -- disable OmniCC for this cooldown
    -- cd:SetHideCountdownNumbers(true)
    cd:SetReverse(true)
    cd:SetDrawEdge(false)
    cd:SetAllPoints()

    local dispelAlert = f:CreateTexture(nil, "ARTWORK", nil, 3)
    dispelAlert:SetAtlas("hud-microbutton-highlightalert")
    dispelAlert:SetPoint("CENTER",0,0)
    dispelAlert:SetSize(width, height)
    dispelAlert:SetScale(1.6)
    dispelAlert:Hide()
    f.dispel = dispelAlert

    local stacktext = AddStackText(f, f)
    UpdateFontStringSettings(stacktext, "ClearFont", 10, "OUTLINE")
    f.stacktext = stacktext

    f.Fill = FillIcon

    if prev then
        f:SetPoint(parent.point, prev, parent.relativePoint, parent.gap, 0)
    else
        f:SetPoint(parent.point, parent, parent.point, 0,0)
    end

    return f
end

function AuraHeader:Create(name, parent, auraType, max)
    local f = CreateFrame("Frame", name, parent)

    Mixin(f, AuraHeader)

    f.cur = 0
    f.max = max
    f.auraType = auraType
    f.icons = {}

    return f
end

function AuraHeader:SetAuraFilter(func)
    self.filterFunc = func
end

function AuraHeader:SetAttachPoints(point, relativePoint, gap)
    self.point = point
    self.relativePoint = relativePoint
    self.gap = gap
end

function AuraHeader:SetIconSize(width, height)
    self.width = width
    self.height = height
end

function AuraHeader:SetMasterHeader(hdr)
    self.masterHeader = hdr
    self.slaveHeader = nil
    hdr.slaveHeader = self
    hdr.masterHeader = nil

    self:SetAllPoints(hdr)
    self.width = hdr.width
    self.height = hdr.height
end


function AuraHeader:Update(unit)
    local shown = 1
    local i = 1
    local masterSlotsOccuptied = self.masterHeader and self.masterHeader.cur or 0
    local curLimit = self.max - masterSlotsOccuptied
    while (shown <= curLimit) do
        local name, icon, count, debuffType, duration, expirationTime, caster, isStealable,
        nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer,
        nameplateShowAll, timeMod = UnitAura(unit, i, self.auraType)

        if not name then break end

        if not self.filterFunc or self.filterFunc(name, icon, count, debuffType, duration, expirationTime, caster, isStealable,
        nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer,
        nameplateShowAll) then

            if not self.icons[shown] then
                self.icons[shown] = CreateIcon(self, self.icons[shown-1], self.width, self.height)
            end
            local aura = self.icons[shown]
            aura:Show()
            aura:Fill(icon, count, debuffType, duration, expirationTime, isStealable)

            shown = shown + 1
        end
        i = i + 1
    end
    local hideStartPoint = math.min(curLimit, shown-1) + 1
    for j=hideStartPoint, self.max do
        if self.icons[j] then
            self.icons[j]:Hide()
        end
    end

    self.cur = shown-1

    local slave = self.slaveHeader
    if slave then
        while (slave.cur + self.cur > slave.max ) do
            slave.icons[slave.cur]:Hide()
            slave.cur = slave.cur - 1
        end
    end
end
