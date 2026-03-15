local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NP = E:GetModule('NamePlates')

local CreateFrame = CreateFrame
local C_Spell_GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local ipairs = ipairs
local issecretvalue = issecretvalue

function TUI:InitElvNP()
	local np = self.db.profile.nameplates
	if not np then return end

	-- Pending removal based on ElvUI updates
	if NamePlateFriendlyFrameOptions and TextureLoadingGroupMixin
		and NamePlateFriendlyFrameOptions.updateNameUsesGetUnitName then
		local wrapper = { textures = NamePlateFriendlyFrameOptions }
		NamePlateFriendlyFrameOptions.updateNameUsesGetUnitName = 0
		TextureLoadingGroupMixin.RemoveTexture(wrapper, 'updateNameUsesGetUnitName')
	end

	if np.classificationInstanceOnly then
		self:HookClassificationInstanceOnly()
	end

	-- Pending removal based on ElvUI updates
	if np.classificationOverThreat then
		self:HookNameplateThreat()
	end

	if np.interruptCastbarColors then
		self:HookCastbarInterrupt()
	end

	-- Pending removal based on ElvUI updates
	if np.focusGlow and np.focusGlow.enabled then
		self:InitFocusGlow()
	end

	if np.disableFriendlyHighlight then
		self:HookDisableFriendlyHighlight()
	end

	if np.questColor and np.questColor.enabled then
		self:HookQuestColor()
	end

end

do -- Classification Instance Only
	local IsInInstance = IsInInstance

	function TUI:HookClassificationInstanceOnly()
		if self._hookedClassificationInstance then return end
		self._hookedClassificationInstance = true

		hooksecurefunc(NP, 'Health_SetColors', function(_, nameplate, threatColors)
			if threatColors then return end
			if not IsInInstance() then
				nameplate.Health.colorClassification = nil
			end
		end)
	end
end

do -- Threat Override
	local UnitIsTapDenied = UnitIsTapDenied

	function TUI:HookNameplateThreat()
		if self._hookedThreatPost then return end
		self._hookedThreatPost = true

		hooksecurefunc(NP, 'ThreatIndicator_PostUpdate', function(Indicator, unit, status)
			local nameplate = Indicator.__owner

			if not status then
				-- Abrupt combat drop (Shadowmeld, Feign Death, etc.): restore color flags
				NP:Health_SetColors(nameplate, false)
				NP.Health_UpdateColor(nameplate, nil, unit)
				return
			end

			local db = NP.db.threat
			if not db or not db.enable or not db.useThreatColor or UnitIsTapDenied(unit) then return end

			local isTank = Indicator.isTank
			local isGoodThreat = isTank and (status == 3) or (not isTank and status == 0)
			if not isGoodThreat then return end

			nameplate.threatStatus = status
			nameplate.threatScale = 1
			NP:ScalePlate(nameplate, 1)
			NP:Health_SetColors(nameplate, false)
			NP.Health_UpdateColor(nameplate, nil, unit)
		end)
	end
end

do -- Interrupt Spell Detection (adapted from mMediaTag with permission from Blinkii, 2026-03-07)
	local UnitCanAttack = UnitCanAttack
	local C_SpellBook_IsSpellKnownOrInSpellBook = C_SpellBook.IsSpellKnownOrInSpellBook
	local EvalColorBool = C_CurveUtil.EvaluateColorValueFromBoolean

	local interruptMap = {
		DEATHKNIGHT = { 47528 },
		DEMONHUNTER = { 183752 },
		DRUID       = { 106839, 78675 },
		EVOKER      = { 351338 },
		HUNTER      = { 147362, 187707 },
		MAGE        = { 2139 },
		MONK        = { 116705 },
		PALADIN     = { 96231 },
		PRIEST      = { 15487 },
		ROGUE       = { 1766 },
		SHAMAN      = { 57994 },
		WARLOCK     = { 19647, 89766, 119910, 132409 },
		WARRIOR     = { 6552 },
	}

	local currentInterrupt

	local function UpdateInterruptSpell()
		currentInterrupt = nil
		local spells = interruptMap[E.myclass]
		if not spells then return end
		for _, spellID in ipairs(spells) do
			if C_SpellBook_IsSpellKnownOrInSpellBook(spellID)
			or C_SpellBook_IsSpellKnownOrInSpellBook(spellID, Enum.SpellBookSpellBank.Pet) then
				currentInterrupt = spellID
			end
		end
	end

	do
		local f = CreateFrame('Frame')
		f:RegisterEvent('PLAYER_LOGIN')
		f:RegisterEvent('SPELLS_CHANGED')
		f:SetScript('OnEvent', UpdateInterruptSpell)
	end

	local activeCastbars = {}

	-- Return notInterruptible safe for EvalColorBool: secret values pass through, nil becomes false
	local function GetNotInterruptible(castbar)
		local v = castbar.notInterruptible
		if issecretvalue(v) then return v end
		return v or false
	end

	-- Lazily create marker frames: clip + CD bar + marker texture
	local function EnsureMarkerFrames(castbar)
		if castbar.TUI_InterruptMarker then return end

		local clip = CreateFrame('Frame', nil, castbar)
		clip:SetAllPoints(castbar)
		clip:SetClipsChildren(true)
		clip:SetFrameLevel(castbar:GetFrameLevel() + 1)
		clip:Hide()
		castbar.TUI_Clip = clip

		-- CD bar: transparent fill tracks interrupt CD remaining; marker sits at its fill edge
		local cdBar = CreateFrame('StatusBar', nil, clip)
		cdBar:SetAllPoints(clip)
		cdBar:SetStatusBarTexture(E.media.blankTex)
		cdBar:GetStatusBarTexture():SetAlpha(0)
		cdBar:SetMinMaxValues(0, 1)
		cdBar:SetValue(0)
		castbar.TUI_CDBar = cdBar

		local marker = cdBar:CreateTexture(nil, 'OVERLAY')
		marker:SetDrawLayer('OVERLAY', 4)
		marker:SetBlendMode('ADD')
		marker:SetSize(2, castbar:GetHeight())
		marker:SetColorTexture(1, 1, 1)
		castbar.TUI_InterruptMarker = marker
	end

	local function CancelTicker(castbar)
		if castbar.TUI_InterruptTicker then
			castbar.TUI_InterruptTicker:Cancel()
			castbar.TUI_InterruptTicker = nil
		end
	end

	local function ResetMarker(castbar)
		CancelTicker(castbar)
		if castbar.TUI_Clip then castbar.TUI_Clip:Hide() end
		activeCastbars[castbar] = nil
	end

	local function ApplyInterruptColor(castbar, isNotInt, isReady)
		local db = TUI.db.profile.nameplates
		local readyC = db.castbarInterruptReady
		local onCDC = db.castbarInterruptOnCD

		local iR = EvalColorBool(isReady, readyC.r, onCDC.r)
		local iG = EvalColorBool(isReady, readyC.g, onCDC.g)
		local iB = EvalColorBool(isReady, readyC.b, onCDC.b)

		local noIntC = NP.db.colors.castNoInterruptColor
		castbar:SetStatusBarColor(
			EvalColorBool(isNotInt, noIntC.r, iR),
			EvalColorBool(isNotInt, noIntC.g, iG),
			EvalColorBool(isNotInt, noIntC.b, iB)
		)
	end

	-- Place marker once when cast starts. CD bar value = cdRemaining, static snapshot.
	-- Ticker only updates alpha (visibility), never repositions.
	local function PlaceMarker(castbar, unit)
		local clip = castbar.TUI_Clip
		local cdBar = castbar.TUI_CDBar
		local marker = castbar.TUI_InterruptMarker
		if not clip or not cdBar or not marker then return end

		local castDuration = UnitCastingDuration(unit) or UnitChannelDuration(unit)
		if not castDuration then
			clip:Hide()
			return
		end

		local cdDuration = C_Spell_GetSpellCooldownDuration(currentInterrupt)
		local total = castDuration:GetTotalDuration()
		local isChannel = castbar.channeling

		-- Normal cast: fill L→R, marker at fill RIGHT edge. Channel: fill R→L, marker at fill LEFT edge.
		cdBar:SetReverseFill(isChannel or false)
		cdBar:SetMinMaxValues(0, total)
		cdBar:SetValue(cdDuration:GetRemainingDuration())

		local mc = TUI.db.profile.nameplates.castbarMarkerColor
		marker:SetColorTexture(mc.r, mc.g, mc.b)
		marker:SetSize(2, castbar:GetHeight())
		marker:ClearAllPoints()
		if isChannel then
			marker:SetPoint('RIGHT', cdBar:GetStatusBarTexture(), 'LEFT', 0, 0)
		else
			marker:SetPoint('LEFT', cdBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
		end

		-- Hide if not interruptible or interrupt is ready
		local notInt = GetNotInterruptible(castbar)
		local onCD = EvalColorBool(cdDuration:IsZero(), 0, 1)
		clip:SetAlpha(EvalColorBool(notInt, 0, onCD))
		clip:Show()
	end

	-- Ticker only updates alpha — never repositions
	local function RefreshMarkerAlpha(castbar)
		local clip = castbar.TUI_Clip
		if not clip then return end
		local notInt = GetNotInterruptible(castbar)
		local cdDuration = C_Spell_GetSpellCooldownDuration(currentInterrupt)
		local onCD = EvalColorBool(cdDuration:IsZero(), 0, 1)
		clip:SetAlpha(EvalColorBool(notInt, 0, onCD))
	end

	local function TickCastbar(castbar)
		if not castbar:IsShown() or not (castbar.casting or castbar.channeling) then
			if castbar.TUI_WasInterrupted and castbar:IsShown() then
				local c = NP.db.colors.castInterruptedColor
				if c then castbar:SetStatusBarColor(c.r, c.g, c.b) end
			end
			ResetMarker(castbar)
			return
		end

		local cdDuration = C_Spell_GetSpellCooldownDuration(currentInterrupt)
		ApplyInterruptColor(castbar, GetNotInterruptible(castbar), cdDuration:IsZero())
		RefreshMarkerAlpha(castbar)
	end

	local function ResetAllOverlays(interrupted)
		for cb in pairs(activeCastbars) do
			if cb == interrupted then
				ResetMarker(cb)
			else
				if cb.TUI_Clip then cb.TUI_Clip:Hide() end
				local cdDuration = currentInterrupt and C_Spell_GetSpellCooldownDuration(currentInterrupt)
				if cdDuration then
					ApplyInterruptColor(cb, GetNotInterruptible(cb), cdDuration:IsZero())
				end
			end
		end
	end

	function TUI:HookCastbarInterrupt()
		if self._hookedCastbarInterrupt then return end
		self._hookedCastbarInterrupt = true

		hooksecurefunc(NP, 'Castbar_PostCastFail', function(castbar)
			castbar.TUI_WasInterrupted = true
			ResetAllOverlays(castbar)
		end)

		hooksecurefunc(NP, 'Castbar_PostCastInterrupted', function(castbar)
			castbar.TUI_WasInterrupted = true
			ResetAllOverlays(castbar)
			local c = NP.db.colors.castInterruptedColor
			if c then castbar:SetStatusBarColor(c.r, c.g, c.b) end
		end)

		hooksecurefunc(NP, 'Castbar_CheckInterrupt', function(castbar, unit)
			if castbar.TUI_WasInterrupted and not (castbar.casting or castbar.channeling) then return end
			ResetMarker(castbar)
			castbar.TUI_WasInterrupted = nil

			if not castbar.casting and not castbar.channeling then return end
			if unit == 'vehicle' then unit = 'player' end
			if not UnitCanAttack('player', unit) then return end
			if not currentInterrupt then return end

			local cdDuration = C_Spell_GetSpellCooldownDuration(currentInterrupt)

			ApplyInterruptColor(castbar, GetNotInterruptible(castbar), cdDuration:IsZero())
			activeCastbars[castbar] = unit

			EnsureMarkerFrames(castbar)
			PlaceMarker(castbar, unit)

			castbar.TUI_InterruptTicker = C_Timer.NewTicker(0.1, function()
				TickCastbar(castbar)
			end)
		end)
	end
end

do -- Focus Overlay
	local LSM = E.Libs.LSM
	local UnitIsUnit = UnitIsUnit
	local C_NamePlate_GetNamePlates = C_NamePlate.GetNamePlates
	local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

	local function GetOrCreateFocusOverlay(nameplate)
		if nameplate.TUI_FocusOverlay then
			return nameplate.TUI_FocusOverlay
		end

		local holder = CreateFrame('Frame', nil, nameplate.Health)
		holder:SetAllPoints(nameplate.Health)
		holder:SetFrameLevel(9)

		local overlay = holder:CreateTexture(nil, 'OVERLAY')
		overlay:SetAllPoints(holder)
		overlay:SetBlendMode('BLEND')
		holder:Hide()

		nameplate.TUI_FocusOverlay = holder
		nameplate.TUI_FocusOverlayTex = overlay
		return holder, overlay
	end

	local function UpdateFocusOverlay(nameplate)
		local db = TUI.db.profile.nameplates.focusGlow
		if not nameplate.unit or not nameplate.Health then return end

		if UnitIsUnit(nameplate.unit, 'focus') then
			local holder, tex = GetOrCreateFocusOverlay(nameplate)
			tex = tex or nameplate.TUI_FocusOverlayTex
			tex:SetTexture(LSM:Fetch('statusbar', db.texture or NP.db.statusbar))
			local c = db.color
			tex:SetVertexColor(c.r, c.g, c.b, c.a or 0.3)
			holder:Show()
		elseif nameplate.TUI_FocusOverlay then
			nameplate.TUI_FocusOverlay:Hide()
		end
	end

	local function UpdateAllFocusOverlays()
		for _, nameplate in ipairs(C_NamePlate_GetNamePlates()) do
			if nameplate.unitFrame then
				UpdateFocusOverlay(nameplate.unitFrame)
			end
		end
	end

	function TUI:InitFocusGlow()
		if self._initFocusGlow then return end
		self._initFocusGlow = true

		local f = CreateFrame('Frame')
		f:RegisterEvent('PLAYER_FOCUS_CHANGED')
		f:RegisterEvent('NAME_PLATE_UNIT_ADDED')
		f:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
		f:SetScript('OnEvent', function(_, event, unit)
			if event == 'PLAYER_FOCUS_CHANGED' then
				UpdateAllFocusOverlays()
			elseif event == 'NAME_PLATE_UNIT_ADDED' then
				local nameplate = C_NamePlate_GetNamePlateForUnit(unit)
				if nameplate and nameplate.unitFrame then
					UpdateFocusOverlay(nameplate.unitFrame)
				end
			elseif event == 'NAME_PLATE_UNIT_REMOVED' then
				local nameplate = C_NamePlate_GetNamePlateForUnit(unit)
				if nameplate and nameplate.unitFrame and nameplate.unitFrame.TUI_FocusOverlay then
					nameplate.unitFrame.TUI_FocusOverlay:Hide()
				end
			end
		end)
	end
end

do -- Disable Friendly Highlight
	function TUI:HookDisableFriendlyHighlight()
		if self._hookedFriendlyHighlight then return end
		self._hookedFriendlyHighlight = true

		hooksecurefunc(NP, 'Update_Highlight', function(_, nameplate)
			if not nameplate or not nameplate.frameType then return end
			local ft = nameplate.frameType
			if (ft == 'FRIENDLY_PLAYER' or ft == 'FRIENDLY_NPC') and nameplate:IsElementEnabled('Highlight') then
				nameplate:DisableElement('Highlight')
			end
		end)
	end
end

do -- Quest Color
	local IsInInstance = IsInInstance

	local function ApplyQuestColor(nameplate)
		if IsInInstance() then return end
		if nameplate.TUI_QuestGUID ~= nameplate.unitGUID then return end
		local c = TUI.db.profile.nameplates.questColor.color
		NP:SetStatusBarColor(nameplate.Health, c.r, c.g, c.b)
	end

	function TUI:HookQuestColor()
		if self._hookedQuestColor then return end
		self._hookedQuestColor = true

		hooksecurefunc(NP, 'Health_UpdateColor', function(nameplate, _, unit)
			if not unit then return end
			ApplyQuestColor(nameplate)
		end)

		hooksecurefunc(NP, 'ThreatIndicator_PostUpdate', function(Indicator, _, status)
			if not status then return end
			ApplyQuestColor(Indicator.__owner)
		end)

		-- QuestIcons PostUpdate fires after tooltip scan; stamp GUID so stale data is never trusted
		local function QuestIconsPostUpdate(element)
			local nameplate = element.__owner
			if not nameplate or not nameplate.Health then return end
			nameplate.TUI_QuestGUID = element.lastQuests and nameplate.unitGUID or nil
			ApplyQuestColor(nameplate)
		end

		hooksecurefunc(NP, 'Update_QuestIcons', function(_, nameplate)
			local qi = nameplate and nameplate.QuestIcons
			if qi and qi.PostUpdate ~= QuestIconsPostUpdate then
				qi.PostUpdate = QuestIconsPostUpdate
			end
		end)
	end
end
