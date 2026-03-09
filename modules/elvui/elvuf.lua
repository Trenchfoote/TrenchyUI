local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM
local LCG = E.Libs.CustomGlow

local hooksecurefunc = hooksecurefunc
local GetSpecialization = GetSpecialization
local UnitClass = UnitClass
local UnitPower = UnitPower
local UnitPowerType = UnitPowerType
local UnitPowerPercent = UnitPowerPercent
local format = format

local ScaleTo100 = CurveConstants and CurveConstants.ScaleTo100

-- Smart Power tag: shows percentage for mana users, current value otherwise
E:AddTag('tui-smartpower', 'UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER', function(unit)
	local powerType = UnitPowerType(unit)
	if powerType == Enum.PowerType.Mana then
		return format('%d', UnitPowerPercent(unit, nil, true, ScaleTo100))
	else
		return UnitPower(unit)
	end
end)
E:AddTagInfo('tui-smartpower', 'Power', 'Shows power percentage for mana specs, current power for others')

-- Fake Power fix
hooksecurefunc(UF, 'Configure_ClassBar', function(_, frame)
	if not frame or not frame.ClassBar then return end
	if frame.ClassBar ~= 'ClassPower' and frame.ClassBar ~= 'Runes' and frame.ClassBar ~= 'Totems' then return end

	local bars = frame[frame.ClassBar]
	if not bars then return end

	local containerW = bars:GetWidth()
	if not containerW or containerW <= 0 then return end

	local MAX_CLASS_BAR = frame.MAX_CLASS_BAR or 0
	if MAX_CLASS_BAR < 1 then return end

	for i = 1, MAX_CLASS_BAR do
		local bar = bars[i]
		if not bar then break end
		if bar:GetWidth() > containerW then
			bar:Width(containerW)
		end
	end
end)

-- VDH Soul Fragments
local SOUL_FRAGMENT_MAX = 6
local SOUL_CLEAVE_SPELL = 228477
local C_Spell_GetSpellCastCount = C_Spell and C_Spell.GetSpellCastCount

local sfBar, sfHolder, sfEventFrame
local sfCells = {}

local function GetClassBarDB()
	return E.db.unitframe and E.db.unitframe.units and E.db.unitframe.units.player and E.db.unitframe.units.player.classbar
end

local function UpdateSoulFragmentColors()
	if not sfBar then return end

	local custom_backdrop = UF.db.colors.customclasspowerbackdrop and UF.db.colors.classpower_backdrop
	local _, powers, fallback = UF:ClassPower_GetColor(UF.db.colors, 'SOUL_FRAGMENTS')
	local color = powers or fallback

	for i = 1, SOUL_FRAGMENT_MAX do
		local cell = sfCells[i]
		if cell then
			UF:SetStatusBarColor(cell, color.r, color.g, color.b, custom_backdrop)
		end
	end
end

local function UpdateSoulFragments()
	if not sfBar then return end

	local current = C_Spell_GetSpellCastCount and C_Spell_GetSpellCastCount(SOUL_CLEAVE_SPELL) or 0

	for i = 1, SOUL_FRAGMENT_MAX do
		local cell = sfCells[i]
		if cell then
			cell:SetMinMaxValues(i - 1, i)
			cell:SetValue(current)
		end
	end

	UpdateSoulFragmentColors()
end

local function LayoutSoulFragments()
	if not sfBar or not sfHolder then return end

	local cbdb = GetClassBarDB()
	if not cbdb then return end

	local BORDER = UF.BORDER or 2
	local UISPACING = UF.SPACING or 1
	local SPACING = (BORDER + UISPACING) * 2

	local playerFrame = UF.player
	local CLASSBAR_WIDTH
	if playerFrame and playerFrame.CLASSBAR_DETACHED then
		CLASSBAR_WIDTH = cbdb.detachedWidth or 250
	elseif playerFrame and playerFrame.USE_MINI_CLASSBAR then
		local baseW = E:Scale(playerFrame.CLASSBAR_WIDTH or 250)
		CLASSBAR_WIDTH = baseW * (SOUL_FRAGMENT_MAX - 1) / SOUL_FRAGMENT_MAX
	else
		CLASSBAR_WIDTH = playerFrame and E:Scale(playerFrame.CLASSBAR_WIDTH or 250) or 250
	end

	local holderH = cbdb.height or 10

	sfHolder:SetSize(CLASSBAR_WIDTH, holderH)
	sfBar:SetSize(CLASSBAR_WIDTH - SPACING, holderH - SPACING)

	sfBar:ClearAllPoints()
	sfBar:SetPoint('BOTTOMLEFT', sfHolder, 'BOTTOMLEFT', BORDER + UISPACING, BORDER + UISPACING)

	local isMini = (playerFrame and playerFrame.USE_MINI_CLASSBAR) or (playerFrame and playerFrame.CLASSBAR_DETACHED)
	local gap, cellW

	if isMini then
		local spacing = (playerFrame.CLASSBAR_DETACHED and cbdb.spacing or 5)
		gap = spacing + BORDER * 2 + UISPACING * 2
		cellW = (CLASSBAR_WIDTH - (gap * (SOUL_FRAGMENT_MAX - 1)) - BORDER * 2) / SOUL_FRAGMENT_MAX
	else
		gap = BORDER * 2 - UISPACING
		cellW = (CLASSBAR_WIDTH - ((SOUL_FRAGMENT_MAX - 1) * gap)) / SOUL_FRAGMENT_MAX
	end

	local texture = LSM:Fetch('statusbar', E.db.unitframe and E.db.unitframe.statusbar or 'ElvUI Norm')
	local borderColor = E.db.unitframe and E.db.unitframe.colors and E.db.unitframe.colors.borderColor

	for i = 1, SOUL_FRAGMENT_MAX do
		local cell = sfCells[i]
		cell:SetSize(cellW, sfBar:GetHeight())
		cell:ClearAllPoints()

		if i == 1 then
			cell:SetPoint('LEFT', sfBar)
		elseif isMini then
			cell:SetPoint('LEFT', sfCells[i - 1], 'RIGHT', gap, 0)
		elseif i == SOUL_FRAGMENT_MAX then
			cell:SetPoint('LEFT', sfCells[i - 1], 'RIGHT', BORDER - UISPACING, 0)
			cell:SetPoint('RIGHT', sfBar)
		else
			cell:SetPoint('LEFT', sfCells[i - 1], 'RIGHT', BORDER - UISPACING, 0)
		end

		cell:SetStatusBarTexture(texture)
		cell:GetStatusBarTexture():SetHorizTile(false)
		cell.bg:SetTexture(texture)
		cell.bg:SetInside(cell.backdrop)

		if cell.backdrop then
			cell.backdrop:SetShown(isMini)
			if borderColor and not cell.backdrop.forcedBorderColors then
				cell.backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
			end
		end

		cell.bg:SetParent(isMini and cell.backdrop or sfBar)
	end

	if sfBar.backdrop then
		sfBar.backdrop:SetShown(not isMini)
		if not isMini and borderColor and not sfBar.backdrop.forcedBorderColors then
			sfBar.backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
		end
	end

	sfBar:SetFrameStrata(cbdb.strataAndLevel and cbdb.strataAndLevel.useCustomStrata and cbdb.strataAndLevel.frameStrata or 'LOW')

	UpdateSoulFragments()
end

local function CreateSoulFragmentBar()
	if sfHolder then return end

	local anchor = _G['ClassBarMover'] or E.UIParent
	sfHolder = CreateFrame('Frame', 'TUI_SoulFragmentsHolder', E.UIParent)
	sfHolder:SetAllPoints(anchor)

	sfBar = CreateFrame('Frame', 'TUI_SoulFragments', sfHolder)
	sfBar:CreateBackdrop(nil, nil, nil, nil, true)

	for i = 1, SOUL_FRAGMENT_MAX do
		local cell = CreateFrame('StatusBar', 'TUI_SoulFragment' .. i, sfBar)
		cell:SetStatusBarTexture(E.media.blankTex)
		cell:GetStatusBarTexture():SetHorizTile(false)
		cell:SetMinMaxValues(0, 1)
		cell:SetValue(0)

		cell:CreateBackdrop(nil, nil, nil, nil, true)
		cell.backdrop:SetParent(sfBar)

		cell.bg = sfBar:CreateTexture(nil, 'BORDER')
		cell.bg:SetTexture(E.media.blankTex)
		cell.bg:SetInside(cell.backdrop)

		sfCells[i] = cell
	end

	hooksecurefunc(UF, 'Configure_ClassBar', function(_, frame)
		if not sfHolder or not sfHolder:IsShown() then return end
		if frame ~= UF.player then return end
		LayoutSoulFragments()
	end)

	LayoutSoulFragments()
end

local function ShowSoulFragments()
	if not sfHolder then
		CreateSoulFragmentBar()
	end

	if not sfEventFrame then
		sfEventFrame = CreateFrame('Frame')
		sfEventFrame:SetScript('OnEvent', UpdateSoulFragments)
	end

	sfEventFrame:RegisterUnitEvent('UNIT_AURA', 'player')
	sfHolder:Show()
	UpdateSoulFragments()
end

local function HideSoulFragments()
	if sfHolder then sfHolder:Hide() end
	if sfEventFrame then sfEventFrame:UnregisterAllEvents() end
end

local function OnSpecChanged()
	local spec = GetSpecialization()
	if spec == 2 then -- Vengeance
		ShowSoulFragments()
	else
		HideSoulFragments()
	end
end

function TUI:InitSoulFragments()
	local _, class = UnitClass('player')
	if class ~= 'DEMONHUNTER' then return end

	C_Timer.After(0, function()
		OnSpecChanged()

		local specFrame = CreateFrame('Frame')
		specFrame:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
		specFrame:SetScript('OnEvent', OnSpecChanged)
	end)
end

-- Guardian Druid Ironfur Bar
local IRONFUR_SPELL = 192081
local IRONFUR_BASE_DUR = 7
local ifBar, ifHolder, ifEventFrame
local ifExpiry, ifDuration = 0, 0
local ifAnimGroup

local function StartIronfurDrain()
	if not ifBar or not ifAnimGroup then return end
	local now = GetTime()
	local remaining = ifExpiry - now
	if remaining <= 0 then
		ifBar:SetMinMaxValues(0, 1)
		ifBar:SetValue(0)
		ifExpiry, ifDuration = 0, 0
		ifAnimGroup:Hide()
		return
	end

	ifBar:SetMinMaxValues(0, ifDuration)
	ifBar:SetValue(remaining)
	ifAnimGroup:Show()
end

local function StopIronfurDrain()
	if ifAnimGroup then ifAnimGroup:Hide() end
	if ifBar then
		ifBar:SetMinMaxValues(0, 1)
		ifBar:SetValue(0)
	end
	ifExpiry, ifDuration = 0, 0
end

local function OnIronfurCast()
	local now = GetTime()
	local remaining = ifExpiry > 0 and (ifExpiry - now) or 0
	if remaining < 0 then remaining = 0 end

	-- Pandemic: can extend up to 130% of base duration
	local maxDur = IRONFUR_BASE_DUR * 1.3
	local newRemaining = remaining + IRONFUR_BASE_DUR
	if newRemaining > maxDur then newRemaining = maxDur end

	ifDuration = newRemaining
	ifExpiry = now + newRemaining
	StartIronfurDrain()
end

local BEAR_FORM = 1

local function UpdateIronfurVisibility()
	if not ifHolder then return end
	local inBear = GetShapeshiftForm() == BEAR_FORM
	if inBear then
		ifHolder:Show()
	else
		ifHolder:Hide()
		StopIronfurDrain()
	end
end

local function OnIronfurEvent(_, event, ...)
	if event == 'UNIT_SPELLCAST_SUCCEEDED' then
		local _, _, spellID = ...
		if spellID == IRONFUR_SPELL then
			OnIronfurCast()
		end
	elseif event == 'UPDATE_SHAPESHIFT_FORM' then
		UpdateIronfurVisibility()
	elseif event == 'PLAYER_REGEN_ENABLED' then
		-- Out of combat: sync with actual aura data
		local aura = C_UnitAuras.GetPlayerAuraBySpellID(IRONFUR_SPELL)
		if aura and aura.duration and aura.duration > 0 then
			ifDuration = aura.duration
			ifExpiry = aura.expirationTime
			StartIronfurDrain()
		else
			StopIronfurDrain()
		end
	end
end

local ifCachedW, ifCachedH = 0, 0

local function LayoutIronfurBar()
	if not ifBar or not ifHolder then return end

	local cbdb = GetClassBarDB()
	if not cbdb then return end

	local BORDER = UF.BORDER or 2
	local UISPACING = UF.SPACING or 1
	local SPACING = (BORDER + UISPACING) * 2

	local playerFrame = UF.player
	local CLASSBAR_WIDTH
	if playerFrame and playerFrame.CLASSBAR_DETACHED then
		CLASSBAR_WIDTH = cbdb.detachedWidth or 250
	elseif playerFrame and playerFrame.USE_MINI_CLASSBAR then
		CLASSBAR_WIDTH = E:Scale(playerFrame.CLASSBAR_WIDTH or 250)
	else
		CLASSBAR_WIDTH = playerFrame and E:Scale(playerFrame.CLASSBAR_WIDTH or 250) or 250
	end

	local holderH = cbdb.height or 10

	if CLASSBAR_WIDTH == ifCachedW and holderH == ifCachedH then return end
	ifCachedW, ifCachedH = CLASSBAR_WIDTH, holderH

	ifHolder:SetSize(CLASSBAR_WIDTH, holderH)
	ifBar:SetSize(CLASSBAR_WIDTH - SPACING, holderH - SPACING)

	ifBar:ClearAllPoints()
	ifBar:SetPoint('BOTTOMLEFT', ifHolder, 'BOTTOMLEFT', BORDER + UISPACING, BORDER + UISPACING)

	local texture = LSM:Fetch('statusbar', E.db.unitframe and E.db.unitframe.statusbar or 'ElvUI Norm')
	ifBar:SetStatusBarTexture(texture)
	ifBar:GetStatusBarTexture():SetHorizTile(false)
	ifBar.bg:SetTexture(texture)

	local borderColor = E.db.unitframe and E.db.unitframe.colors and E.db.unitframe.colors.borderColor
	if ifBar.backdrop and borderColor and not ifBar.backdrop.forcedBorderColors then
		ifBar.backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
	end

	ifBar:SetFrameStrata(cbdb.strataAndLevel and cbdb.strataAndLevel.useCustomStrata and cbdb.strataAndLevel.frameStrata or 'LOW')

	local custom_backdrop = UF.db.colors.customclasspowerbackdrop and UF.db.colors.classpower_backdrop
	local cc = E:ClassColor('DRUID')
	if cc then
		UF:SetStatusBarColor(ifBar, cc.r, cc.g, cc.b, custom_backdrop)
	end

	local aura = C_UnitAuras.GetPlayerAuraBySpellID(IRONFUR_SPELL)
	if aura and aura.duration and aura.duration > 0 then
		ifDuration = aura.duration
		ifExpiry = aura.expirationTime
		StartIronfurDrain()
	end
end

local function CreateIronfurBar()
	if ifHolder then return end

	local anchor = _G['ClassBarMover'] or E.UIParent
	ifHolder = CreateFrame('Frame', 'TUI_IronfurHolder', E.UIParent)
	ifHolder:SetAllPoints(anchor)

	ifBar = CreateFrame('StatusBar', 'TUI_IronfurBar', ifHolder)
	ifBar:SetStatusBarTexture(E.media.blankTex)
	ifBar:GetStatusBarTexture():SetHorizTile(false)
	ifBar:SetMinMaxValues(0, 1)
	ifBar:SetValue(0)
	ifBar:CreateBackdrop(nil, nil, nil, nil, true)

	ifBar.bg = ifBar:CreateTexture(nil, 'BORDER')
	ifBar.bg:SetTexture(E.media.blankTex)
	ifBar.bg:SetInside(ifBar.backdrop)

	-- Ticker frame for smooth drain (updates every frame)
	local ticker = CreateFrame('Frame')
	ticker:Hide()
	ticker:SetScript('OnUpdate', function()
		if ifExpiry == 0 then ticker:Hide() return end
		local remaining = ifExpiry - GetTime()
		if remaining > 0 then
			ifBar:SetValue(remaining)
		else
			ifBar:SetValue(0)
			ifExpiry, ifDuration = 0, 0
			ticker:Hide()
		end
	end)
	ifAnimGroup = ticker

	hooksecurefunc(UF, 'Configure_ClassBar', function(_, frame)
		if not ifHolder then return end
		if frame ~= UF.player then return end
		C_Timer.After(0, LayoutIronfurBar)
	end)

	LayoutIronfurBar()
end

local function ShowIronfurBar()
	if not ifHolder then
		CreateIronfurBar()
	end

	if not ifEventFrame then
		ifEventFrame = CreateFrame('Frame')
		ifEventFrame:SetScript('OnEvent', OnIronfurEvent)
	end

	ifEventFrame:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player')
	ifEventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
	ifEventFrame:RegisterEvent('UPDATE_SHAPESHIFT_FORM')

	UpdateIronfurVisibility()

	if GetShapeshiftForm() == BEAR_FORM then
		local aura = C_UnitAuras.GetPlayerAuraBySpellID(IRONFUR_SPELL)
		if aura and aura.duration and aura.duration > 0 then
			ifDuration = aura.duration
			ifExpiry = aura.expirationTime
			StartIronfurDrain()
		end
	end
end

local function HideIronfurBar()
	if ifHolder then ifHolder:Hide() end
	if ifEventFrame then ifEventFrame:UnregisterAllEvents() end
	ifExpiry, ifDuration = 0, 0
end

local function OnDruidSpecChanged()
	local spec = GetSpecialization()
	if spec == 3 then -- Guardian
		ShowIronfurBar()
	else
		HideIronfurBar()
	end
end

function TUI:InitIronfurBar()
	local _, class = UnitClass('player')
	if class ~= 'DRUID' then return end

	C_Timer.After(0, function()
		OnDruidSpecChanged()

		local specFrame = CreateFrame('Frame')
		specFrame:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
		specFrame:SetScript('OnEvent', OnDruidSpecChanged)
	end)
end

-- Pixel Glow
local GLOW_KEY = 'TUI_PixelGlow'

local function GetPixelGlowDB()
	local db = TUI.db and TUI.db.profile and TUI.db.profile.pixelGlow
	if not db then return false, 8, 0.25, 2 end
	return db.enabled, db.lines, db.speed, db.thickness
end

local function AfterElvUIPostUpdate(element, frame, unit, aura, debuffType, texture, wasFiltered, style, color)
	if not LCG or not LCG.PixelGlow_Start then return end

	local _, lines, speed, thickness = GetPixelGlowDB()
	local glowTarget = frame.Health or frame

	if aura or debuffType then
		local r, g, b, a = element:GetVertexColor()

		element:SetVertexColor(0, 0, 0, 0)
		if frame.AuraHightlightGlow then frame.AuraHightlightGlow:Hide() end

		LCG.PixelGlow_Start(glowTarget, { r, g, b, a }, lines, speed, nil, thickness, 0, 0, false, GLOW_KEY)
	else
		element:SetVertexColor(0, 0, 0, 0)
		if frame.AuraHightlightGlow then frame.AuraHightlightGlow:Hide() end
		LCG.PixelGlow_Stop(glowTarget, GLOW_KEY)
	end
end

function TUI:InitPixelGlow()
	local enabled = GetPixelGlowDB()
	if not enabled then return end

	if E.db.unitframe.debuffHighlighting == 'NONE' then
		E.db.unitframe.debuffHighlighting = 'FILL'
	end

	hooksecurefunc(UF, 'Configure_AuraHighlight', function(_, frame)
		if not frame or not frame.AuraHighlight then return end

		frame.AuraHighlightBackdrop = false
		if frame.AuraHightlightGlow then frame.AuraHightlightGlow:Hide() end

		local elvuiPostUpdate = frame.AuraHighlight.PostUpdate
		frame.AuraHighlight.PostUpdate = function(element, fr, ...)
			if elvuiPostUpdate then elvuiPostUpdate(element, fr, ...) end
			AfterElvUIPostUpdate(element, fr, ...)
		end
	end)
end
