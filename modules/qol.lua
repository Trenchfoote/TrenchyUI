local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local LSM = E.Libs.LSM

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local pairs, ipairs = pairs, ipairs
local select, tonumber, tostring = select, tonumber, tostring
local floor, ceil, min = floor, ceil, min
local GetInstanceInfo = GetInstanceInfo
local IsInInstance = IsInInstance
local InCombatLockdown = InCombatLockdown

do -- Hide Talking Head
	local function KillTalkingHead()
		local thf = TalkingHeadFrame
		if not thf then return end

		thf:UnregisterEvent('TALKINGHEAD_REQUESTED')
		thf:UnregisterEvent('TALKINGHEAD_CLOSE')
		thf:UnregisterEvent('SOUNDKIT_FINISHED')
		thf:UnregisterEvent('LOADING_SCREEN_ENABLED')
		thf:Hide()

		if AlertFrame and AlertFrame.alertFrameSubSystems then
			for i = #AlertFrame.alertFrameSubSystems, 1, -1 do
				local sub = AlertFrame.alertFrameSubSystems[i]
				if sub.anchorFrame and sub.anchorFrame == thf then
					table.remove(AlertFrame.alertFrameSubSystems, i)
				end
			end
		end

		if not TUI:IsHooked(thf, 'Show') then
			TUI:SecureHook(thf, 'Show', function(self) self:Hide() end)
		end
	end

	function TUI:InitHideTalkingHead()
		KillTalkingHead()
	end
end

do -- Auto-fill DELETE confirmation
	local DELETE_DIALOGS = {
		['DELETE_GOOD_ITEM'] = true,
		['DELETE_GOOD_QUEST_ITEM'] = true,
	}

	function TUI:InitAutoFillDelete()
		hooksecurefunc('StaticPopup_Show', function(which)
			if not DELETE_DIALOGS[which] then return end

			for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
				local frame = _G['StaticPopup' .. i]
				if frame and frame:IsShown() and frame.which == which then
					local editBox = frame.editBox or (frame.GetEditBox and frame:GetEditBox())
					if editBox then
						editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
						if StaticPopup_StandardConfirmationTextHandler then
							StaticPopup_StandardConfirmationTextHandler(editBox, DELETE_ITEM_CONFIRM_STRING)
						end
					end
					break
				end
			end
		end)
	end
end

do -- Difficulty Text Replacement
	local DIFF_CATEGORY = {
		[1]   = 'normal',  [14]  = 'normal',  [38]  = 'normal',
		[173] = 'normal',  [198] = 'normal',  [201] = 'normal',
		[2]   = 'heroic',  [15]  = 'heroic',  [39]  = 'heroic',
		[174] = 'heroic',
		[16]  = 'mythic',  [23]  = 'mythic',  [40]  = 'mythic',
		[8]   = 'keystoneMod',
		[24]  = 'timewalking', [33] = 'timewalking', [151] = 'timewalking',
		[7]   = 'lfr',     [17]  = 'lfr',
		[205] = 'follower',
		[208] = 'delve',
		[3]   = 'normal',  [4]   = 'normal',  [9]   = 'normal',
		[175] = 'normal',  [176] = 'normal',  [186] = 'normal',
		[148] = 'normal',  [185] = 'normal',  [215] = 'normal',
		[5]   = 'heroic',  [6]   = 'heroic',
		[193] = 'heroic',  [194] = 'heroic',
	}

	local DIFF_LABEL = {
		normal      = 'N',
		heroic      = 'H',
		mythic      = 'M',
		keystoneMod = 'M+',
		timewalking = 'TW',
		lfr         = 'LFR',
		follower    = 'FD',
		delve       = 'D',
		other       = '?',
	}

	local diffTextFrame, diffFontString, diffLevelString

	local function CreateDifficultyText()
		if diffTextFrame then return end

		diffTextFrame = CreateFrame('Frame', 'TUI_DifficultyText', Minimap)
		diffTextFrame:SetSize(60, 20)
		diffTextFrame:SetFrameStrata('LOW')
		diffTextFrame:SetFrameLevel(10)

		local M = E:GetModule('Minimap')
		local iconDb = M and M.db and M.db.icons and M.db.icons.difficulty
		local position = iconDb and iconDb.position or 'TOPLEFT'
		local xOff = iconDb and iconDb.xOffset or 10
		local yOff = iconDb and iconDb.yOffset or 1
		diffTextFrame:SetPoint(position, Minimap, position, xOff, yOff)

		E:CreateMover(diffTextFrame, 'TUI_DifficultyTextMover', 'Difficulty Text', nil, nil, nil, 'ALL,GENERAL', nil, 'TrenchyUI,qol')

		local db = TUI.db and TUI.db.profile and TUI.db.profile.qol
		local fontPath = LSM:Fetch('font', db and db.difficultyFont or 'Expressway')
		local fontSize = db and db.difficultyFontSize or 14
		local fontOutline = db and db.difficultyFontOutline or 'OUTLINE'

		diffFontString = diffTextFrame:CreateFontString(nil, 'OVERLAY')
		diffFontString:SetFont(fontPath, fontSize, fontOutline)
		diffFontString:SetPoint('CENTER', diffTextFrame, 'CENTER', 0, 0)
		diffFontString:SetJustifyH('CENTER')

		diffLevelString = diffTextFrame:CreateFontString(nil, 'OVERLAY')
		diffLevelString:SetFont(fontPath, fontSize, fontOutline)
		diffLevelString:SetPoint('LEFT', diffFontString, 'RIGHT', 1, 0)
		diffLevelString:SetJustifyH('CENTER')
	end

	function TUI:UpdateDifficultyFont()
		if not diffFontString then return end
		local db = self.db and self.db.profile and self.db.profile.qol
		local fontPath = LSM:Fetch('font', db and db.difficultyFont or 'Expressway')
		local fontSize = db and db.difficultyFontSize or 14
		local fontOutline = db and db.difficultyFontOutline or 'OUTLINE'
		diffFontString:SetFont(fontPath, fontSize, fontOutline)
		diffLevelString:SetFont(fontPath, fontSize, fontOutline)
	end

	local function UpdateDifficultyText()
		if not diffTextFrame then CreateDifficultyText() end

		local _, instanceType, difficultyID = GetInstanceInfo()
		if not difficultyID or difficultyID == 0 or instanceType == 'none' then
			diffTextFrame:Hide()
			return
		end

		local db = TUI.db and TUI.db.profile and TUI.db.profile.qol
		local colors = db and db.difficultyColors or {}
		local category = DIFF_CATEGORY[difficultyID] or 'other'
		local label = DIFF_LABEL[category] or '?'
		local c = colors[category] or colors.other or { r = 1, g = 1, b = 1 }

		diffFontString:SetText(label)
		diffFontString:SetTextColor(c.r, c.g, c.b, 1)

		if category == 'keystoneMod' then
			local level = C_ChallengeMode.IsChallengeModeActive()
				and select(1, C_ChallengeMode.GetActiveKeystoneInfo())
			if level and level > 0 then
				local kc = colors.keystoneMod or { r = 1, g = 0.5, b = 0 }
				diffLevelString:SetText(level)
				diffLevelString:SetTextColor(kc.r, kc.g, kc.b, 1)
				diffLevelString:Show()
			else
				diffLevelString:Hide()
			end
		elseif category == 'delve' then
			local info = C_UIWidgetManager
				and C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo
				and C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(6183)
			local tier = info and tonumber(info.tierText)
			if tier and tier > 0 then
				local dc = colors.delve or { r = 0.8, g = 0.6, b = 0.2 }
				diffLevelString:SetText(tier)
				diffLevelString:SetTextColor(dc.r, dc.g, dc.b, 1)
				diffLevelString:Show()
			else
				diffLevelString:Hide()
			end
		else
			diffLevelString:Hide()
		end

		diffTextFrame:Show()
	end

	local function HideBlizzardDifficultyFlag()
		local difficulty = MinimapCluster and MinimapCluster.InstanceDifficulty
		if not difficulty then return end

		difficulty:SetAlpha(0)
		difficulty:SetSize(1, 1)

		for _, childName in ipairs({ 'Instance', 'Guild', 'ChallengeMode' }) do
			local child = difficulty[childName]
			if child then child:SetAlpha(0); child:Hide() end
		end

		for _, region in ipairs({ difficulty:GetRegions() }) do
			region:SetAlpha(0)
			if region.Hide then region:Hide() end
		end
	end

	function TUI:InitDifficultyText()
		HideBlizzardDifficultyFlag()
		CreateDifficultyText()
		UpdateDifficultyText()

		local eventFrame = CreateFrame('Frame')
		eventFrame:RegisterEvent('PLAYER_DIFFICULTY_CHANGED')
		eventFrame:RegisterEvent('ZONE_CHANGED')
		eventFrame:RegisterEvent('ZONE_CHANGED_INDOORS')
		eventFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
		eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
		eventFrame:RegisterEvent('CHALLENGE_MODE_START')
		eventFrame:RegisterEvent('CHALLENGE_MODE_COMPLETED')
		eventFrame:RegisterEvent('CHALLENGE_MODE_RESET')
		eventFrame:RegisterEvent('UPDATE_INSTANCE_INFO')
		eventFrame:SetScript('OnEvent', function()
			HideBlizzardDifficultyFlag()
			UpdateDifficultyText()
		end)
	end
end

do -- Fast Loot
	function TUI:InitFastLoot()
		local evFrame = CreateFrame('Frame')
		evFrame:RegisterEvent('LOOT_READY')
		evFrame:SetScript('OnEvent', function()
			local slots = GetNumLootItems()
			if slots == 0 then return end
			for i = slots, 1, -1 do
				LootSlot(i)
			end
		end)
	end
end

do -- Moveable Frames
	local hookedFrames = {}

	local function MakeMoveable(frame)
		if hookedFrames[frame] then return end
		if not frame.IsObjectType or not frame:IsObjectType('Frame') then return end
		if frame:IsProtected() and InCombatLockdown() then return end
		if frame.mover then return end

		local name = frame.GetName and frame:GetName() or 'unknown'

		if name == 'MailFrame' or name == 'AchievementFrame' then
			hookedFrames[frame] = true
			frame:EnableMouse(true)
			frame:SetClampedToScreen(true)

			local function StartDrag(parent, button)
				if button ~= 'LeftButton' then return end
				parent.tuiDragging = true
				local cx, cy = GetCursorPosition()
				local scale = parent:GetEffectiveScale()
				parent.tuiDragCursorX = cx / scale
				parent.tuiDragCursorY = cy / scale
				parent.tuiDragLeft = parent:GetLeft()
				parent.tuiDragTop = parent:GetTop()
			end
			local function StopDrag(parent, button)
				if button == 'LeftButton' then parent.tuiDragging = false end
			end

			frame:HookScript('OnMouseDown', function(self, button) StartDrag(self, button) end)
			frame:HookScript('OnMouseUp', function(self, button) StopDrag(self, button) end)
			frame:HookScript('OnUpdate', function(self)
				if not self.tuiDragging then return end
				local cx, cy = GetCursorPosition()
				local scale = self:GetEffectiveScale()
				cx, cy = cx / scale, cy / scale
				local dx = cx - self.tuiDragCursorX
				local dy = cy - self.tuiDragCursorY
				self:ClearAllPoints()
				self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', self.tuiDragLeft + dx, self.tuiDragTop + dy)
			end)

			if name == 'AchievementFrame' and frame.Header then
				frame.Header:HookScript('OnMouseDown', function(_, button) StartDrag(frame, button) end)
				frame.Header:HookScript('OnMouseUp', function(_, button) StopDrag(frame, button) end)
			end

			return
		end

		hookedFrames[frame] = true
		frame:SetMovable(true)
		frame:SetClampedToScreen(true)

		if frame:IsProtected() then
			local handle = CreateFrame('Frame', nil, frame, 'PanelDragBarTemplate')
			handle:SetAllPoints(frame)
			handle:SetFrameLevel(frame:GetFrameLevel() + 1)
			handle:SetPropagateMouseMotion(true)
			handle:SetPropagateMouseClicks(true)
			handle:HookScript('OnMouseDown', function(_, button)
				if button == 'LeftButton' and not InCombatLockdown() then frame:StartMoving() end
			end)
			handle:HookScript('OnMouseUp', function(_, button)
				if button == 'LeftButton' then frame:StopMovingOrSizing() end
			end)
		else
			frame:EnableMouse(true)
			frame:HookScript('OnMouseDown', function(self, button)
				if button == 'LeftButton' then self:StartMoving() end
			end)
			frame:HookScript('OnMouseUp', function(self, button)
				if button == 'LeftButton' then self:StopMovingOrSizing() end
			end)
		end
	end

	local function HookUIPanels()
		if not UIPanelWindows then return end
		for name in pairs(UIPanelWindows) do
			local frame = _G[name]
			if frame and type(frame) == 'table' and frame.IsObjectType then
				MakeMoveable(frame)
			end
		end
	end

	local function HookElvUIBags()
		local B = E:GetModule('Bags')
		if not B then return end

		local function FreeDrag(self) self:StartMoving() end

		if B.BagFrame then B.BagFrame:SetScript('OnDragStart', FreeDrag); hookedFrames[B.BagFrame] = true end
		if B.BankFrame then B.BankFrame:SetScript('OnDragStart', FreeDrag); hookedFrames[B.BankFrame] = true end
	end

	function TUI:InitMoveableFrames()
		C_Timer.After(1, function()
			HookUIPanels()
			HookElvUIBags()
		end)

		hooksecurefunc('ShowUIPanel', function(frame)
			if frame and not hookedFrames[frame] then MakeMoveable(frame) end
		end)
	end
end

do -- Minimap Button Bar
	local mbbBar
	local mbbButtons = {}
	local mbbInCombat = false
	local mbbSkinned = {}

	local MBB_PADDING = 4

	local function GetMBBDB()
		return TUI.db.profile.minimapButtonBar
	end

	local function StripButton(btn)
		if mbbSkinned[btn] then return end
		mbbSkinned[btn] = true

		for _, region in pairs({ btn:GetRegions() }) do
			if region.IsObjectType and region:IsObjectType('Texture') then
				local tex = region:GetTexture()
				local texStr = tex and tostring(tex):lower() or ''

				if texStr:find('border') or texStr:find('overlay') or texStr:find('background')
				or texStr == '136430' or texStr == '136467' then
					region:SetTexture(nil)
					region:SetAlpha(0)
					region:Hide()
				end
			end
		end

		for _, key in ipairs({ 'overlay', 'Border', 'border', 'highlight' }) do
			local child = btn[key]
			if child and child.SetTexture then
				child:SetTexture(nil)
				child:SetAlpha(0)
			end
		end

		local hl = btn.GetHighlightTexture and btn:GetHighlightTexture()
		if hl then
			hl:SetTexture(nil)
			hl:SetAlpha(0)
		end

		local icon = btn.icon
		if not icon then
			for _, region in pairs({ btn:GetRegions() }) do
				if region.IsObjectType and region:IsObjectType('Texture') and region:GetTexture() and region:IsShown() then
					icon = region
					break
				end
			end
		end
		btn.tuiIcon = icon
	end

	local function SkinButton(btn, size)
		StripButton(btn)

		local db = GetMBBDB()
		btn:SetSize(size, size)

		if not btn.tuiBackdrop then
			local bd = CreateFrame('Frame', nil, btn, 'BackdropTemplate')
			bd:SetFrameLevel(btn:GetFrameLevel())
			btn.tuiBackdrop = bd
		end

		local bd = btn.tuiBackdrop
		local bSize = db.buttonBorderSize or 1
		bd:ClearAllPoints()
		bd:SetPoint('TOPLEFT', btn, 'TOPLEFT', -bSize, bSize)
		bd:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', bSize, -bSize)

		if db.buttonBackdrop or db.buttonBorder then
			bd:SetBackdrop({
				bgFile   = db.buttonBackdrop and E.media.blankTex or nil,
				edgeFile = db.buttonBorder and E.media.blankTex or nil,
				edgeSize = db.buttonBorder and bSize or 0,
				insets   = { left = 0, right = 0, top = 0, bottom = 0 },
			})
			if db.buttonBackdrop then
				local c = db.buttonBackdropColor
				bd:SetBackdropColor(c.r, c.g, c.b, c.a)
			else
				bd:SetBackdropColor(0, 0, 0, 0)
			end
			if db.buttonBorder then
				local c = db.buttonBorderColor
				bd:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
			end
			bd:Show()
		else
			bd:SetBackdrop(nil)
			bd:Hide()
		end

		local icon = btn.tuiIcon
		if icon then
			icon:ClearAllPoints()
			icon:SetPoint('TOPLEFT', btn, 'TOPLEFT', 0, 0)
			icon:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', 0, 0)
			icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
		end
	end

	local function LayoutBar()
		if not mbbBar then return end
		local db = GetMBBDB()
		local size = db.buttonSize
		local spacing = db.buttonSpacing
		local perRow = db.buttonsPerRow
		local bdInset = (db.buttonBorder and db.buttonBorderSize or 0)
		local effectiveSpacing = spacing + bdInset * 2

		local count = #mbbButtons
		if count == 0 then
			mbbBar:SetSize(size + MBB_PADDING * 2, size + MBB_PADDING * 2)
			return
		end

		local cols = min(count, perRow)
		local rows = ceil(count / perRow)
		mbbBar:SetSize(MBB_PADDING * 2 + cols * size + (cols - 1) * effectiveSpacing,
		               MBB_PADDING * 2 + rows * size + (rows - 1) * effectiveSpacing)

		for i, btn in ipairs(mbbButtons) do
			btn:ClearAllPoints()
			SkinButton(btn, size)
			local col = (i - 1) % perRow
			local row = floor((i - 1) / perRow)
			btn:SetPoint('TOPLEFT', mbbBar, 'TOPLEFT', MBB_PADDING + col * (size + effectiveSpacing),
			             -(MBB_PADDING + row * (size + effectiveSpacing)))
			btn:SetParent(mbbBar)
			btn:Show()
		end
	end

	local function UpdateBarStyle()
		if not mbbBar then return end
		local db = GetMBBDB()

		if db.backdrop or db.border then
			local bSize = db.borderSize or 1
			mbbBar:SetBackdrop({
				bgFile   = db.backdrop and E.media.blankTex or nil,
				edgeFile = db.border and E.media.blankTex or nil,
				edgeSize = db.border and bSize or 0,
				insets   = { left = 0, right = 0, top = 0, bottom = 0 },
			})
			if db.backdrop then
				local bc = db.backdropColor
				mbbBar:SetBackdropColor(bc.r, bc.g, bc.b, bc.a)
			else
				mbbBar:SetBackdropColor(0, 0, 0, 0)
			end
			if db.border then
				local ec = db.borderColor
				mbbBar:SetBackdropBorderColor(ec.r, ec.g, ec.b, ec.a)
			end
		else
			mbbBar:SetBackdrop(nil)
		end
	end

	local function UpdateVisibility()
		if not mbbBar then return end
		local db = GetMBBDB()

		if db.hideInCombat then
			if mbbInCombat then mbbBar:Hide(); return
			elseif not mbbBar:IsShown() then mbbBar:Show() end
		end

		if db.mouseover then
			mbbBar:SetAlpha(mbbBar:IsMouseOver() and db.mouseoverAlpha or 0)
		else
			mbbBar:SetAlpha(1)
		end
	end

	local function CollectButtons()
		mbbButtons = {}
		local LDB = LibStub and LibStub('LibDBIcon-1.0', true)
		if not LDB then return end

		local objects = LDB:GetButtonList()
		if objects then
			for _, name in ipairs(objects) do
				local btn = LDB:GetMinimapButton(name)
				if btn and btn:IsObjectType('Frame') then
					mbbButtons[#mbbButtons + 1] = btn
				end
			end
		end

		table.sort(mbbButtons, function(a, b)
			return (a:GetName() or '') < (b:GetName() or '')
		end)
	end

	function TUI:UpdateMinimapButtonBar()
		if not mbbBar then return end
		CollectButtons()
		LayoutBar()
		UpdateBarStyle()
		UpdateVisibility()
	end

	function TUI:InitMinimapButtonBar()
		local db = GetMBBDB()
		if not db.enabled then return end

		C_Timer.After(2, function()
			mbbBar = CreateFrame('Frame', 'TrenchyUIMinimapButtonBar', E.UIParent, 'BackdropTemplate')
			mbbBar:SetSize(200, 40)
			mbbBar:SetPoint('TOPRIGHT', E.UIParent, 'TOPRIGHT', -200, -4)
			mbbBar:SetClampedToScreen(true)
			mbbBar:SetFrameStrata('LOW')

			mbbBar:SetScript('OnEnter', UpdateVisibility)
			mbbBar:SetScript('OnLeave', UpdateVisibility)

			local evFrame = CreateFrame('Frame', 'TrenchyUIMBBEvents', E.UIParent)
			evFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
			evFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
			evFrame:SetScript('OnEvent', function(_, event)
				mbbInCombat = (event == 'PLAYER_REGEN_DISABLED')
				UpdateVisibility()
			end)

			E:CreateMover(mbbBar, 'TrenchyUIMinimapButtonBarMover', 'TUI Minimap Buttons', nil, nil, nil, nil, nil, 'TrenchyUI,qol')
			TUI:UpdateMinimapButtonBar()
			C_Timer.After(5, function() TUI:UpdateMinimapButtonBar() end)
		end)
	end
end

function TUI:InitQoL()
	local db = self.db and self.db.profile and self.db.profile.qol
	if not db then return end

	if db.hideTalkingHead then self:InitHideTalkingHead() end
	if db.autoFillDelete then self:InitAutoFillDelete() end
	if db.difficultyText then self:InitDifficultyText() end
	if db.fastLoot then self:InitFastLoot() end
	if db.moveableFrames and not self:IsCompatBlocked('moveableFrames') then self:InitMoveableFrames() end
	if self.InitMinimapButtonBar then self:InitMinimapButtonBar() end
end
