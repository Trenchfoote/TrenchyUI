local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NP = E:GetModule('NamePlates')

local CreateFrame = CreateFrame
local C_Spell_GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local ipairs = ipairs

function TUI:InitElvNP()
	local np = self.db.profile.nameplates
	if not np then return end

	if np.classificationInstanceOnly then
		self:HookClassificationInstanceOnly()
	end

	if np.classificationOverThreat then
		self:HookNameplateThreat()
	end

	if np.interruptCastbarColors then
		self:HookCastbarInterrupt()
	end

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

	local function GetOrCreateMarker(castbar)
		if castbar.TUI_InterruptMarker then
			return castbar.TUI_InterruptMarker
		end
		local marker = castbar:CreateTexture(nil, 'OVERLAY')
		marker:SetDrawLayer('OVERLAY', 4)
		marker:SetBlendMode('ADD')
		marker:SetSize(3, castbar:GetHeight())
		marker:SetColorTexture(1, 1, 1)
		marker:Hide()
		castbar.TUI_InterruptMarker = marker
		return marker
	end

	local function GetOrCreateCDPositioner(castbar)
		if castbar.TUI_CDPositioner then
			return castbar.TUI_CDPositioner, castbar.TUI_CDClipper
		end

		local clip = CreateFrame('Frame', nil, castbar)
		clip:SetAllPoints(castbar)
		clip:SetClipsChildren(true)
		clip:SetFrameLevel(castbar:GetFrameLevel() + 1)
		castbar.TUI_CDClipper = clip

		local pos = CreateFrame('StatusBar', nil, clip)
		pos:SetStatusBarTexture(E.media.blankTex)
		pos:GetStatusBarTexture():SetAlpha(0)
		pos:SetMinMaxValues(0, 1)
		pos:SetValue(0)
		castbar.TUI_CDPositioner = pos

		return pos, clip
	end

	local activeCastbars = {}

	local function CancelInterruptTicker(castbar)
		if castbar.TUI_InterruptTicker then
			castbar.TUI_InterruptTicker:Cancel()
			castbar.TUI_InterruptTicker = nil
		end
	end

	local function ResetInterruptOverlay(castbar)
		CancelInterruptTicker(castbar)
		if castbar.TUI_InterruptMarker then castbar.TUI_InterruptMarker:Hide() end
		if castbar.TUI_CDClipper then castbar.TUI_CDClipper:Hide() end
		castbar.TUI_InterruptUnit = nil
		activeCastbars[castbar] = nil
	end

	local function ApplyInterruptColor(castbar, notInt, isReady)
		local db = TUI.db.profile.nameplates
		local readyC = db.castbarInterruptReady
		local onCDC = db.castbarInterruptOnCD

		local iR = EvalColorBool(isReady, readyC.r, onCDC.r)
		local iG = EvalColorBool(isReady, readyC.g, onCDC.g)
		local iB = EvalColorBool(isReady, readyC.b, onCDC.b)

		local noIntC = NP.db.colors.castNoInterruptColor
		castbar:SetStatusBarColor(
			EvalColorBool(notInt, noIntC.r, iR),
			EvalColorBool(notInt, noIntC.g, iG),
			EvalColorBool(notInt, noIntC.b, iB)
		)

		if castbar.TUI_CDClipper then
			local showAlpha = EvalColorBool(isReady, 0, 1)
			castbar.TUI_CDClipper:SetAlpha(EvalColorBool(notInt, 0, showAlpha))
		end
	end

	local function ResetAllOverlays(interrupted)
		local cdDuration = currentInterrupt and C_Spell_GetSpellCooldownDuration(currentInterrupt)
		for cb in pairs(activeCastbars) do
			if cb == interrupted then
				ResetInterruptOverlay(cb)
			else
				-- Hide marker but keep ticker alive for color updates
				if cb.TUI_InterruptMarker then cb.TUI_InterruptMarker:Hide() end
				if cb.TUI_CDClipper then cb.TUI_CDClipper:Hide() end
				-- Immediately apply on-CD color so ElvUI can't override before next tick
				if cdDuration then
					local isReady = cdDuration:IsZero()
					ApplyInterruptColor(cb, cb.notInterruptible, isReady)
				end
			end
		end
	end

	local function InterruptPreamble(castbar, unit)
		ResetInterruptOverlay(castbar)
		castbar.TUI_WasInterrupted = nil

		if not castbar.casting and not castbar.channeling then return nil end
		if unit == 'vehicle' then unit = 'player' end
		if not UnitCanAttack('player', unit) then return nil end
		if not currentInterrupt then return nil end

		return unit
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

		local function PlaceMarker(castbar, unit)
			local cdDuration = C_Spell_GetSpellCooldownDuration(currentInterrupt)
			local isReady = cdDuration:IsZero()
			local notInt = castbar.notInterruptible

			local markerAlpha = EvalColorBool(isReady, 0, 1)
			markerAlpha = EvalColorBool(notInt, 0, markerAlpha)

			local castDuration = UnitCastingDuration(unit) or UnitChannelDuration(unit)
			if not castDuration then
				if castbar.TUI_CDClipper then castbar.TUI_CDClipper:SetAlpha(0) end
				return
			end

			local pos, clip = GetOrCreateCDPositioner(castbar)
			local reverseFill = castbar:GetReverseFill()

			pos:ClearAllPoints()
			pos:SetPoint('TOPLEFT', castbar, 'TOPLEFT')
			pos:SetPoint('BOTTOMRIGHT', castbar, 'BOTTOMRIGHT')
			pos:SetReverseFill(reverseFill)
			pos:SetMinMaxValues(0, castDuration:GetTotalDuration())
			pos:SetValue(cdDuration:GetRemainingDuration())
			clip:SetAlpha(markerAlpha)
			clip:Show()

			local marker = GetOrCreateMarker(castbar)
			marker:SetParent(clip)
			local mc = TUI.db.profile.nameplates.castbarMarkerColor
			marker:SetColorTexture(mc.r, mc.g, mc.b)
			marker:SetSize(3, castbar:GetHeight())
			marker:ClearAllPoints()
			if reverseFill then
				marker:SetPoint('RIGHT', pos:GetStatusBarTexture(), 'LEFT', 0, 0)
			else
				marker:SetPoint('LEFT', pos:GetStatusBarTexture(), 'RIGHT', 0, 0)
			end
			marker:Show()
		end

		local function UpdateMarker(castbar)
			if not castbar.TUI_CDClipper then return end
			local cdDuration = C_Spell_GetSpellCooldownDuration(currentInterrupt)
			local isReady = cdDuration:IsZero()
			local notInt = castbar.notInterruptible
			local showAlpha = EvalColorBool(isReady, 0, 1)
			castbar.TUI_CDClipper:SetAlpha(EvalColorBool(notInt, 0, showAlpha))
			if castbar.TUI_InterruptMarker then
				castbar.TUI_InterruptMarker:SetAlpha(showAlpha)
			end
		end

		hooksecurefunc(NP, 'Castbar_CheckInterrupt', function(castbar, unit)
			if castbar.TUI_WasInterrupted and not (castbar.casting or castbar.channeling) then return end
			unit = InterruptPreamble(castbar, unit)
			if not unit then return end

			local notInt = castbar.notInterruptible
			local cdDuration = C_Spell_GetSpellCooldownDuration(currentInterrupt)
			local isReady = cdDuration:IsZero()

			ApplyInterruptColor(castbar, notInt, isReady)
			castbar.TUI_InterruptUnit = unit
			activeCastbars[castbar] = true
			PlaceMarker(castbar, unit)

			castbar.TUI_InterruptTicker = C_Timer.NewTicker(0.1, function()
				if not castbar:IsShown() or not (castbar.casting or castbar.channeling) then
					if castbar.TUI_WasInterrupted and castbar:IsShown() then
						local c = NP.db.colors.castInterruptedColor
						if c then castbar:SetStatusBarColor(c.r, c.g, c.b) end
					end
					ResetInterruptOverlay(castbar)
					return
				end
				local notInt2 = castbar.notInterruptible
				local cdDuration2 = C_Spell_GetSpellCooldownDuration(currentInterrupt)
				local isReady2 = cdDuration2:IsZero()
				ApplyInterruptColor(castbar, notInt2, isReady2)
				UpdateMarker(castbar)
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
