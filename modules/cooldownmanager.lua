local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local LCG = LibStub('LibCustomGlow-1.0', true)
local LSM = E.Libs.LSM

local hooksecurefunc = hooksecurefunc
local pairs = pairs
local ipairs = ipairs
local wipe = wipe
local math_ceil = math.ceil
local math_min = math.min
local math_floor = math.floor

local VIEWER_KEYS = {
	essential = { global = 'EssentialCooldownViewer', label = 'Essential CDs',  mover = 'TUI_CDM_Essential' },
	utility   = { global = 'UtilityCooldownViewer',  label = 'Utility CDs',    mover = 'TUI_CDM_Utility' },
	buffIcon  = { global = 'BuffIconCooldownViewer', label = 'Buff Icon CDs',  mover = 'TUI_CDM_BuffIcon' },
	buffBar   = { global = 'BuffBarCooldownViewer',  label = 'Buff Bar CDs',   mover = 'TUI_CDM_BuffBar' },
}

local containers = {}   -- [viewerKey] = container frame
local styledFrames = {} -- [itemFrame] = viewerKey — tracks which frames already have text/glow applied
local glowActive = {}   -- [itemFrame] = true — tracks which frames currently have our glow
local previewActive = false
local inCombat = false
local ScheduleRelayout      -- forward declaration
local ShouldShowContainer   -- forward declaration

local sortFunc = function(a, b) return (a.layoutIndex or 0) < (b.layoutIndex or 0) end

-- DB helpers
local function GetDB()
	return TUI.db and TUI.db.profile and TUI.db.profile.cooldownManager
end

local function GetViewerDB(viewerKey)
	local db = GetDB()
	return db and db.viewers and db.viewers[viewerKey]
end

local function GetViewer(viewerKey)
	local info = VIEWER_KEYS[viewerKey]
	return info and _G[info.global]
end

-- Per-spell glow DB helpers
local SPELL_GLOW_DEFAULTS = { enabled = false, type = 'pixel', color = { r = 0.95, g = 0.95, b = 0.32, a = 1 }, lines = 8, speed = 0.25, thickness = 2, particles = 4, scale = 1 }

local function GetSpellGlowDB(spellID)
	local db = GetDB()
	return db and db.spellGlow and db.spellGlow[spellID]
end

local function GetOrCreateSpellGlowDB(spellID)
	local db = GetDB()
	if not db then return nil end
	if not db.spellGlow then db.spellGlow = {} end
	if not db.spellGlow[spellID] then
		local d = SPELL_GLOW_DEFAULTS
		db.spellGlow[spellID] = { enabled = d.enabled, type = d.type, color = { r = d.color.r, g = d.color.g, b = d.color.b, a = d.color.a }, lines = d.lines, speed = d.speed, thickness = d.thickness, particles = d.particles, scale = d.scale }
	end
	return db.spellGlow[spellID]
end

-- Per-spell bar color helpers
local SPELL_BAR_COLOR_DEFAULTS = { enabled = false, fgColor = { r = 0.2, g = 0.6, b = 1 }, bgColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.5 } }

local function GetSpellBarColorDB(spellID)
	local db = GetDB()
	return db and db.spellBarColor and db.spellBarColor[spellID]
end

local function GetOrCreateSpellBarColorDB(spellID)
	local db = GetDB()
	if not db then return nil end
	if not db.spellBarColor then db.spellBarColor = {} end
	if not db.spellBarColor[spellID] then
		local d = SPELL_BAR_COLOR_DEFAULTS
		db.spellBarColor[spellID] = { enabled = d.enabled, fgColor = { r = d.fgColor.r, g = d.fgColor.g, b = d.fgColor.b }, bgColor = { r = d.bgColor.r, g = d.bgColor.g, b = d.bgColor.b, a = d.bgColor.a } }
	end
	return db.spellBarColor[spellID]
end

-- Glow
local function StopGlow(itemFrame)
	if not LCG or not glowActive[itemFrame] then return end
	glowActive[itemFrame] = nil

	LCG.PixelGlow_Stop(itemFrame, 'TUI_CDM')
	LCG.AutoCastGlow_Stop(itemFrame, 'TUI_CDM')
	LCG.ButtonGlow_Stop(itemFrame)
	LCG.ProcGlow_Stop(itemFrame, 'TUI_CDM')

	if itemFrame.tuiAlertHidden then
		itemFrame.tuiAlertHidden = nil
		local alert = itemFrame.SpellActivationAlert
		if alert then alert:SetAlpha(1) end
	end
end

local hookedAlerts = {}

local glowColor = {}    -- reusable color table for glow
local GLOW_PREFIXES = { '_PixelGlow', '_AutoCastGlow', '_ButtonGlow', '_ProcGlow' }

local function ApplyGlow(itemFrame, glowDB, perSpell)
	if not LCG then return end

	local alert = itemFrame.SpellActivationAlert
	if not perSpell then
		if not alert or not alert:IsShown() then
			StopGlow(itemFrame)
			return
		end
	end

	-- Suppress Blizzard's alert animation if it's showing
	if alert and alert:IsShown() then
		alert:SetAlpha(0)
		itemFrame.tuiAlertHidden = true
	end

	-- Hook Show so we keep suppressing Blizzard's alert while glow is enabled
	if alert and not hookedAlerts[itemFrame] then
		hookedAlerts[itemFrame] = true
		hooksecurefunc(alert, 'Show', function(self)
			local vKey = styledFrames[itemFrame]
			if vKey == 'buffIcon' then
				local sid = itemFrame.GetBaseSpellID and itemFrame:GetBaseSpellID()
				local sgdb = sid and GetSpellGlowDB(sid)
				if sgdb and sgdb.enabled then
					self:SetAlpha(0)
					itemFrame.tuiAlertHidden = true
				end
			else
				local vdb = vKey and GetViewerDB(vKey)
				if vdb and vdb.glow and vdb.glow.enabled then
					self:SetAlpha(0)
					itemFrame.tuiAlertHidden = true
				end
			end
		end)
	end

	glowActive[itemFrame] = true

	local glowType = glowDB.type or 'pixel'
	local color = glowDB.color
	if color then
		glowColor[1], glowColor[2], glowColor[3], glowColor[4] = color.r, color.g, color.b, color.a or 1
	else
		glowColor[1], glowColor[2], glowColor[3], glowColor[4] = 0.95, 0.95, 0.32, 1
	end

	local fl = 0
	if glowType == 'pixel' then
		LCG.PixelGlow_Start(itemFrame, glowColor, glowDB.lines or 8, glowDB.speed or 0.25, glowDB.length, glowDB.thickness or 2, 0, 0, nil, 'TUI_CDM', fl)
	elseif glowType == 'autocast' then
		LCG.AutoCastGlow_Start(itemFrame, glowColor, glowDB.particles or 4, glowDB.speed or 0.25, glowDB.scale or 1, 0, 0, 'TUI_CDM', fl)
	elseif glowType == 'button' then
		LCG.ButtonGlow_Start(itemFrame, glowColor, glowDB.speed or 0.25, fl)
	elseif glowType == 'proc' then
		LCG.ProcGlow_Start(itemFrame, {
			color = glowColor,
			startAnim = glowDB.startAnim ~= false,
			key = 'TUI_CDM',
			frameLevel = fl,
		})
	end

	-- Re-anchor glow frame flush with icon edges
	for _, prefix in ipairs(GLOW_PREFIXES) do
		local gf = itemFrame[prefix .. 'TUI_CDM']
		if gf then
			gf:ClearAllPoints()
			gf:SetPoint('TOPLEFT', itemFrame, 'TOPLEFT', 0, 0)
			gf:SetPoint('BOTTOMRIGHT', itemFrame, 'BOTTOMRIGHT', 0, 0)
			break
		end
	end
end

local function ApplyIconZoom(itemFrame, zoom)
	if not zoom or zoom <= 0 then return end
	local icon = itemFrame.Icon
	if icon then
		if icon.SetTexCoord then
			icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
		elseif icon.Icon and icon.Icon.SetTexCoord then
			icon.Icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
		end
	end
end

-- Text styling
local function GetTextColor(tdb)
	if tdb.classColor then
		local cc = E:ClassColor(E.myclass)
		if cc then return cc.r, cc.g, cc.b end
	end
	local c = tdb.color
	return c.r, c.g, c.b
end

local function StyleFontString(fs, tdb)
	if not fs then return end
	fs:ClearAllPoints()
	fs:SetPoint(tdb.position, tdb.xOffset, tdb.yOffset)
	fs:FontTemplate(LSM:Fetch('font', tdb.font), tdb.fontSize, tdb.fontOutline)
	fs:SetTextColor(GetTextColor(tdb))
end

local function ApplyCountText(itemFrame, tdb)
	if not tdb then return end

	local fs
	fs = itemFrame.Applications and itemFrame.Applications.Applications
	if fs then fs:SetIgnoreParentScale(true); StyleFontString(fs, tdb) end
	fs = itemFrame.Count
	if fs then fs:SetIgnoreParentScale(true); StyleFontString(fs, tdb) end
	fs = itemFrame.ChargeCount and itemFrame.ChargeCount.Current
	if fs then fs:SetIgnoreParentScale(true); StyleFontString(fs, tdb) end
end

-- Shield pattern: store ref in cooldown.tuiText, nil cooldown.Text so ElvUI's CooldownText skips font styling
local function ApplyCooldownText(cooldown, tdb)
	if not cooldown or not tdb then return end

	cooldown:SetHideCountdownNumbers(false)

	local text = cooldown.tuiText or cooldown.Text or cooldown:GetRegions()
	if text and text.SetTextColor then
		cooldown.tuiText = text
		cooldown.Text = nil
		text:SetIgnoreParentScale(true)
		StyleFontString(text, tdb)
	end
end

local hookedSwipes = {}

local function ApplySwipeOverride(cooldown, db)
	if not cooldown then return end
	if db.hideSwipe then
		cooldown:SetDrawSwipe(false)

		-- Persistent hook: block Blizzard/ElvUI from re-enabling swipe
		if not hookedSwipes[cooldown] then
			hookedSwipes[cooldown] = true
			hooksecurefunc(cooldown, 'SetDrawSwipe', function(self, draw)
				if draw then
					local cdb = GetDB()
					if cdb and cdb.enabled and cdb.hideSwipe then
						self:SetDrawSwipe(false)
					end
				end
			end)
		end
	end
end

local function ApplyTextOverrides(itemFrame, vdb, db)
	ApplyCountText(itemFrame, vdb.countText)
	ApplyCooldownText(itemFrame.Cooldown, vdb.cooldownText)
	ApplySwipeOverride(itemFrame.Cooldown, db)
end

-- Preview text for config
local function SetPreviewText(itemFrame, show, vdb)
	local bar = itemFrame.Bar
	if bar then
		local nameText = bar.Name and bar.Name:IsShown() and bar.Name:GetText()
		local hasRealName = nameText and (issecretvalue(nameText) or nameText ~= '')
		if show and vdb then
			-- Hide preview name on bars with real buff data, but always show duration preview
			if vdb.nameText and not hasRealName then
				if not bar.tuiPreviewName then
					bar.tuiPreviewName = bar:CreateFontString(nil, 'OVERLAY')
				end
				local pfs = bar.tuiPreviewName
				StyleFontString(pfs, vdb.nameText)
				pfs:SetText('Buff Name')
				pfs:Show()
			elseif bar.tuiPreviewName then
				bar.tuiPreviewName:Hide()
			end
			if vdb.durationText then
				if not bar.tuiPreviewDuration then
					bar.tuiPreviewDuration = bar:CreateFontString(nil, 'OVERLAY')
				end
				local pfs = bar.tuiPreviewDuration
				StyleFontString(pfs, vdb.durationText)
				pfs:SetText('12.5s')
				pfs:Show()
			end
		else
			if bar.tuiPreviewName then bar.tuiPreviewName:Hide() end
			if bar.tuiPreviewDuration then bar.tuiPreviewDuration:Hide() end
		end
		return
	end

	-- Icon viewer
	if show then
		local tdb = vdb and vdb.cooldownText
		if tdb then
			if not itemFrame.tuiCDPreview then
				itemFrame.tuiCDPreview = itemFrame:CreateFontString(nil, 'OVERLAY')
			end
			local pfs = itemFrame.tuiCDPreview
			pfs:SetIgnoreParentScale(true)
			StyleFontString(pfs, tdb)
			pfs:SetText('12')
			pfs:Show()
		end
	elseif itemFrame.tuiCDPreview then
		itemFrame.tuiCDPreview:Hide()
	end
end

local function ShowPreview()
	if previewActive then return end
	previewActive = true

	for viewerKey in pairs(VIEWER_KEYS) do
		local vdb = GetViewerDB(viewerKey)
		local viewer = GetViewer(viewerKey)
		if viewer and vdb and viewer.itemFramePool then
			for frame in viewer.itemFramePool:EnumerateActive() do
				if frame and frame:IsShown() then
					SetPreviewText(frame, true, vdb)
				end
			end
		end
	end
end

local function HidePreview()
	if not previewActive then return end
	previewActive = false

	for viewerKey in pairs(VIEWER_KEYS) do
		local viewer = GetViewer(viewerKey)
		if viewer and viewer.itemFramePool then
			for frame in viewer.itemFramePool:EnumerateActive() do
				if frame then
					SetPreviewText(frame, false)
				end
			end
		end
	end

	ScheduleRelayout()
end

-- Glow Options Panel
do
	local AceGUI = LibStub('AceGUI-3.0')
	local glowPanel, currentSpellID
	local widgets = {}
	local GLOW_TYPES = { pixel = 'Pixel', autocast = 'Autocast', button = 'Button', proc = 'Proc' }
	local GLOW_TYPE_ORDER = { 'pixel', 'autocast', 'button', 'proc' }

	local function RefreshBuffIconGlow()
		local viewer = _G['BuffIconCooldownViewer']
		if not viewer or not viewer.itemFramePool then return end
		for frame in viewer.itemFramePool:EnumerateActive() do
			if frame and frame:IsShown() and frame.GetBaseSpellID then
				local sid = frame:GetBaseSpellID()
				local sgdb = sid and GetSpellGlowDB(sid)
				if sgdb and sgdb.enabled then
					ApplyGlow(frame, sgdb, true)
				else
					StopGlow(frame)
				end
			end
		end
	end

	local function UpdateVisibleSliders()
		if not glowPanel or not currentSpellID then return end
		local sgdb = GetOrCreateSpellGlowDB(currentSpellID)
		if not sgdb then return end
		local isPixel = sgdb.type == 'pixel'
		local isAutocast = sgdb.type == 'autocast'
		widgets.lines.frame:SetShown(isPixel)
		widgets.thickness.frame:SetShown(isPixel)
		widgets.particles.frame:SetShown(isAutocast)
		widgets.scale.frame:SetShown(isAutocast)
		glowPanel:DoLayout()
	end

	local function UpdatePanelWidgets()
		if not glowPanel or not currentSpellID then return end
		local sgdb = GetOrCreateSpellGlowDB(currentSpellID)
		if not sgdb then return end
		widgets.enable:SetValue(sgdb.enabled)
		widgets.glowType:SetValue(sgdb.type)
		widgets.color:SetColor(sgdb.color.r, sgdb.color.g, sgdb.color.b, sgdb.color.a or 1)
		widgets.speed:SetValue(sgdb.speed)
		widgets.lines:SetValue(sgdb.lines)
		widgets.thickness:SetValue(sgdb.thickness)
		widgets.particles:SetValue(sgdb.particles)
		widgets.scale:SetValue(sgdb.scale)
		UpdateVisibleSliders()
	end

	local function CreateGlowPanel()
		local window = AceGUI:Create('Window')
		window:SetTitle('|cffff2f3dTrenchyUI|r Glow Options')
		window:SetWidth(300)
		window:SetHeight(340)
		window:SetLayout('Flow')
		window:EnableResize(false)
		window.frame:SetFrameStrata('DIALOG')

		local enable = AceGUI:Create('CheckBox')
		enable:SetLabel('Enable Glow')
		enable:SetFullWidth(true)
		enable:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.enabled = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(enable)
		widgets.enable = enable

		local glowType = AceGUI:Create('Dropdown')
		glowType:SetLabel('Type')
		glowType:SetList(GLOW_TYPES, GLOW_TYPE_ORDER)
		glowType:SetRelativeWidth(0.5)
		glowType:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.type = val; UpdateVisibleSliders(); RefreshBuffIconGlow() end
		end)
		window:AddChild(glowType)
		widgets.glowType = glowType

		local color = AceGUI:Create('ColorPicker')
		color:SetLabel('Color')
		color:SetRelativeWidth(0.5)
		color:SetHasAlpha(true)

		local function colorChanged(_, _, r, g, b, a)
			local sgdb = GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.color.r, sgdb.color.g, sgdb.color.b, sgdb.color.a = r, g, b, a; RefreshBuffIconGlow() end
		end
		color:SetCallback('OnValueChanged', colorChanged)
		color:SetCallback('OnValueConfirmed', colorChanged)

		window:AddChild(color)
		widgets.color = color

		local speed = AceGUI:Create('Slider')
		speed:SetLabel('Speed')
		speed:SetSliderValues(0.05, 2, 0.05)
		speed:SetFullWidth(true)
		speed:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.speed = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(speed)
		widgets.speed = speed

		local lines = AceGUI:Create('Slider')
		lines:SetLabel('Lines')
		lines:SetSliderValues(1, 20, 1)
		lines:SetFullWidth(true)
		lines:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.lines = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(lines)
		widgets.lines = lines

		local thickness = AceGUI:Create('Slider')
		thickness:SetLabel('Thickness')
		thickness:SetSliderValues(1, 8, 1)
		thickness:SetFullWidth(true)
		thickness:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.thickness = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(thickness)
		widgets.thickness = thickness

		local particles = AceGUI:Create('Slider')
		particles:SetLabel('Particles')
		particles:SetSliderValues(1, 16, 1)
		particles:SetFullWidth(true)
		particles:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.particles = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(particles)
		widgets.particles = particles

		local scale = AceGUI:Create('Slider')
		scale:SetLabel('Scale')
		scale:SetSliderValues(0.5, 3, 0.1)
		scale:SetFullWidth(true)
		scale:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.scale = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(scale)
		widgets.scale = scale

		window:SetCallback('OnClose', function() glowPanel = nil end)
		window:Hide()
		glowPanel = window
	end

	function TUI:HideGlowPanel()
		if glowPanel then glowPanel:Hide() end
	end

	function TUI:ShowGlowPanel(spellID)
		if not glowPanel then CreateGlowPanel() end
		currentSpellID = spellID
		TUI:HideBarColorPanel()

		local spellInfo = C_Spell.GetSpellInfo(spellID)
		local name = spellInfo and spellInfo.name or ('Spell ' .. spellID)
		glowPanel:SetTitle('|cffff2f3dTrenchyUI|r ' .. name)

		-- Anchor to Cooldown Settings panel
		glowPanel.frame:ClearAllPoints()
		local tsf = _G.CooldownViewerSettings
		if tsf and tsf:IsShown() then
			glowPanel.frame:SetPoint('TOPLEFT', tsf, 'TOPRIGHT', 50, 0)
		else
			glowPanel.frame:SetPoint('CENTER', E.UIParent, 'CENTER', 0, 100)
		end

		-- Close glow panel when Cooldown Settings closes or Edit Alert opens
		if tsf and not tsf.tuiGlowHooked then
			tsf:HookScript('OnHide', function() if glowPanel then glowPanel:Hide() end end)
			tsf.tuiGlowHooked = true
		end

		local editAlert = _G.CooldownViewerSettingsEditAlert
		if editAlert then
			if not editAlert.tuiGlowHooked then
				editAlert:HookScript('OnShow', function() if glowPanel then glowPanel:Hide() end end)
				editAlert.tuiGlowHooked = true
			end
			if editAlert:IsShown() then editAlert:Hide() end
		end

		UpdatePanelWidgets()
		glowPanel:Show()
	end
end

local ApplyBarStyle     -- forward declaration
local LayoutBuffBar     -- forward declaration

-- Bar Color Options Panel
do
	local AceGUI = LibStub('AceGUI-3.0')
	local barColorPanel, barColorSpellID
	local bcWidgets = {}

	local function RefreshBuffBarColors()
		local viewer = _G['BuffBarCooldownViewer']
		if not viewer or not viewer.itemFramePool then return end
		local vdb = GetViewerDB('buffBar')
		if not vdb then return end
		for frame in viewer.itemFramePool:EnumerateActive() do
			if frame and frame:IsShown() then
				ApplyBarStyle(frame, vdb)
			end
		end
	end

	local function UpdateBarColorWidgets()
		if not barColorPanel or not barColorSpellID then return end
		local sbc = GetOrCreateSpellBarColorDB(barColorSpellID)
		if not sbc then return end
		bcWidgets.enable:SetValue(sbc.enabled)
		bcWidgets.fgColor:SetColor(sbc.fgColor.r, sbc.fgColor.g, sbc.fgColor.b)
		bcWidgets.bgColor:SetColor(sbc.bgColor.r, sbc.bgColor.g, sbc.bgColor.b, sbc.bgColor.a or 0.5)
	end

	local function CreateBarColorPanel()
		local window = AceGUI:Create('Window')
		window:SetTitle('|cffff2f3dTrenchyUI|r Bar Colors')
		window:SetWidth(280)
		window:SetHeight(180)
		window:SetLayout('Flow')
		window:EnableResize(false)
		window.frame:SetFrameStrata('DIALOG')

		local enable = AceGUI:Create('CheckBox')
		enable:SetLabel('Enable Custom Colors')
		enable:SetFullWidth(true)
		enable:SetCallback('OnValueChanged', function(_, _, val)
			local sbc = GetOrCreateSpellBarColorDB(barColorSpellID)
			if sbc then sbc.enabled = val; RefreshBuffBarColors() end
		end)
		window:AddChild(enable)
		bcWidgets.enable = enable

		local fgColor = AceGUI:Create('ColorPicker')
		fgColor:SetLabel('Foreground')
		fgColor:SetRelativeWidth(0.5)
		fgColor:SetHasAlpha(false)
		local function fgChanged(_, _, r, g, b)
			local sbc = GetOrCreateSpellBarColorDB(barColorSpellID)
			if sbc then sbc.fgColor.r, sbc.fgColor.g, sbc.fgColor.b = r, g, b; RefreshBuffBarColors() end
		end
		fgColor:SetCallback('OnValueChanged', fgChanged)
		fgColor:SetCallback('OnValueConfirmed', fgChanged)
		window:AddChild(fgColor)
		bcWidgets.fgColor = fgColor

		local bgColor = AceGUI:Create('ColorPicker')
		bgColor:SetLabel('Background')
		bgColor:SetRelativeWidth(0.5)
		bgColor:SetHasAlpha(true)
		local function bgChanged(_, _, r, g, b, a)
			local sbc = GetOrCreateSpellBarColorDB(barColorSpellID)
			if sbc then sbc.bgColor.r, sbc.bgColor.g, sbc.bgColor.b, sbc.bgColor.a = r, g, b, a; RefreshBuffBarColors() end
		end
		bgColor:SetCallback('OnValueChanged', bgChanged)
		bgColor:SetCallback('OnValueConfirmed', bgChanged)
		window:AddChild(bgColor)
		bcWidgets.bgColor = bgColor

		window:SetCallback('OnClose', function() barColorPanel = nil end)
		window:Hide()
		barColorPanel = window
	end

	function TUI:HideBarColorPanel()
		if barColorPanel then barColorPanel:Hide() end
	end

	function TUI:ShowBarColorPanel(spellID)
		if not barColorPanel then CreateBarColorPanel() end
		barColorSpellID = spellID
		TUI:HideGlowPanel()

		local spellInfo = C_Spell.GetSpellInfo(spellID)
		local name = spellInfo and spellInfo.name or ('Spell ' .. spellID)
		barColorPanel:SetTitle('|cffff2f3dTrenchyUI|r ' .. name)

		barColorPanel.frame:ClearAllPoints()
		local tsf = _G.CooldownViewerSettings
		if tsf and tsf:IsShown() then
			barColorPanel.frame:SetPoint('TOPLEFT', tsf, 'TOPRIGHT', 50, 0)
		else
			barColorPanel.frame:SetPoint('CENTER', E.UIParent, 'CENTER', 0, 100)
		end

		if tsf and not tsf.tuiBarColorHooked then
			tsf:HookScript('OnHide', function() if barColorPanel then barColorPanel:Hide() end end)
			tsf.tuiBarColorHooked = true
		end

		local editAlert = _G.CooldownViewerSettingsEditAlert
		if editAlert then
			if not editAlert.tuiBarColorHooked then
				editAlert:HookScript('OnShow', function() if barColorPanel then barColorPanel:Hide() end end)
				editAlert.tuiBarColorHooked = true
			end
			if editAlert:IsShown() then editAlert:Hide() end
		end

		UpdateBarColorWidgets()
		barColorPanel:Show()
	end
end

-- Blizzard CDM settings
local function ShowBlizzardCDMSettings()
	if not C_AddOns.IsAddOnLoaded('Blizzard_CooldownViewer') then
		C_AddOns.LoadAddOn('Blizzard_CooldownViewer')
	end
	local settings = _G.CooldownViewerSettings
	if settings and not settings:IsShown() then
		settings:Show()
	end
	ScheduleRelayout()
end

local function HideBlizzardCDMSettings()
	local settings = _G.CooldownViewerSettings
	if settings and settings:IsShown() then
		settings:Hide()
	end
	ScheduleRelayout()
end

local function IsConfigOpen()
	local ACD = E.Libs.AceConfigDialog
	return ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUI
end

local function OpenCDMConfig()
	if not IsConfigOpen() then
		E:ToggleOptions('TrenchyUI')
	end
	C_Timer.After(0.1, function()
		local configGroup = E.Options and E.Options.args and E.Options.args.TrenchyUI
		if configGroup and configGroup.args and configGroup.args.cooldownManager then
			E.Libs.AceConfigDialog:SelectGroup('ElvUI', 'TrenchyUI', 'cooldownManager')
		end
	end)
end

-- Container creation
local CDM_CONFIG_STRING = 'TrenchyUI,cooldownManager'
local moverToViewer = {} -- configString → viewerKey mapping

local function CreateContainer(viewerKey)
	local info = VIEWER_KEYS[viewerKey]
	local vdb = GetViewerDB(viewerKey)

	local w, h
	if viewerKey == 'buffBar' then
		w = vdb and vdb.barWidth or 200
		h = (vdb and vdb.barHeight or 20) * 4
	else
		local iconW = vdb and vdb.iconWidth or 30
		local iconH = (vdb and vdb.keepSizeRatio and iconW) or (vdb and vdb.iconHeight or 30)
		w = iconW * 8
		h = iconH * 2
	end

	local configStr = CDM_CONFIG_STRING .. ',' .. viewerKey

	local frame = CreateFrame('Frame', info.mover .. 'Holder', E.UIParent)
	frame:SetSize(w, h)
	frame:SetPoint('TOPLEFT', E.UIParent, 'CENTER', 0, 0)
	frame:SetFrameStrata('MEDIUM')
	frame:SetFrameLevel(5)

	E:CreateMover(frame, info.mover .. 'Mover', 'TUI ' .. info.label, nil, nil, nil, 'ALL,TRENCHYUI', nil, configStr, true)
	moverToViewer[configStr] = viewerKey

	containers[viewerKey] = frame
	return frame
end

local iconCache = {}    -- [viewerKey] = reusable table for icon collection

-- Re-anchor container to its mover based on growth direction
local function AnchorToMover(viewerKey, growUp)
	local container = containers[viewerKey]
	if not container then return end
	local info = VIEWER_KEYS[viewerKey]
	local mover = _G[info.mover .. 'Mover']
	if not mover then return end

	-- Save the growth-anchor edge before resize
	local fixedEdge = growUp and mover:GetBottom() or mover:GetTop()

	mover:SetSize(container:GetSize())

	-- Adjust mover position to keep the growth-anchor edge at the same screen Y
	local newEdge = growUp and mover:GetBottom() or mover:GetTop()
	if fixedEdge and newEdge then
		local drift = fixedEdge - newEdge
		if drift ~= 0 then
			local p, rel, rp, x, y = mover:GetPoint()
			if p then
				mover:ClearAllPoints()
				mover:SetPoint(p, rel, rp, x, (y or 0) + drift)
			end
		end
	end

	container:ClearAllPoints()
	if growUp then
		container:SetPoint('BOTTOM', mover, 'BOTTOM')
	else
		container:SetPoint('TOP', mover, 'TOP')
	end
end

local function LayoutContainer(viewerKey, isCapture)
	if viewerKey == 'buffBar' then return LayoutBuffBar(viewerKey, isCapture) end

	local container = containers[viewerKey]
	if not container then return end

	local db = GetDB()
	if not db or not db.enabled then return end

	local vdb = GetViewerDB(viewerKey)
	if not vdb then return end

	local viewer = GetViewer(viewerKey)
	if not viewer or not viewer.itemFramePool then return end

	local iconW = E:Scale(vdb.iconWidth or 30)
	local iconH = (vdb.keepSizeRatio and iconW) or E:Scale(vdb.iconHeight or 30)
	local perRow = vdb.iconsPerRow or 12

	local spacing = E:Scale(vdb.spacing or 2)
	local growUp = (vdb.growthDirection == 'UP')

	local icons = iconCache[viewerKey]
	if not icons then icons = {}; iconCache[viewerKey] = icons end
	wipe(icons)

	for frame in viewer.itemFramePool:EnumerateActive() do
		if frame and frame:IsShown() and frame.layoutIndex then
			icons[#icons + 1] = frame
		end
	end

	table.sort(icons, sortFunc)

	local count = #icons
	if count == 0 then
		local minW = perRow * iconW + (perRow - 1) * spacing
		container:SetSize(minW, iconH)
		AnchorToMover(viewerKey, growUp)
		return
	end

	local applyStyle = isCapture
	local vGlow = vdb.glow
	local useGlow = vGlow and vGlow.enabled

	local iconZoom = vdb.iconZoom

	for _, icon in ipairs(icons) do
		icon:SetScale(1)
		icon:SetSize(iconW, iconH)

		ApplyIconZoom(icon, iconZoom)

		if applyStyle or not styledFrames[icon] then
			ApplyTextOverrides(icon, vdb, db)
			styledFrames[icon] = viewerKey
			icon.tuiViewerKey = viewerKey
		end

		if viewerKey == 'buffIcon' then
			local sid = icon.GetBaseSpellID and icon:GetBaseSpellID()
			local sgdb = sid and GetSpellGlowDB(sid)
			if sgdb and sgdb.enabled then
				ApplyGlow(icon, sgdb, true)
			else
				StopGlow(icon)
			end
		elseif useGlow then
			ApplyGlow(icon, vGlow)
		else
			StopGlow(icon)
		end

		if icon.DebuffBorder and not icon.tuiDebuffBorderKilled then
			icon.DebuffBorder:Hide()
			icon.DebuffBorder:SetAlpha(0)
			hooksecurefunc(icon.DebuffBorder, 'Show', function(self) self:Hide() end)
			icon.tuiDebuffBorderKilled = true
		end
	end

	local cols = math_min(count, perRow)
	local rows = math_ceil(count / perRow)
	local totalW = cols * iconW + (cols - 1) * spacing
	local totalH = rows * iconH + (rows - 1) * spacing
	container:SetSize(totalW, totalH)

	for i, icon in ipairs(icons) do
		local row = math_floor((i - 1) / perRow)
		local col = (i - 1) % perRow

		local rowStart = row * perRow + 1
		local rowEnd = math_min(rowStart + perRow - 1, count)
		local rowCount = rowEnd - rowStart + 1
		local rowW = rowCount * iconW + (rowCount - 1) * spacing
		local offsetX = (totalW - rowW) / 2

		local x = offsetX + col * (iconW + spacing)
		local y

		if growUp then
			y = row * (iconH + spacing)
		else
			y = -row * (iconH + spacing)
		end

		icon:ClearAllPoints()
		if growUp then
			icon:SetPoint('BOTTOMLEFT', container, 'BOTTOMLEFT', x, y)
		else
			icon:SetPoint('TOPLEFT', container, 'TOPLEFT', x, y)
		end
	end

	AnchorToMover(viewerKey, growUp)
end

-- Buff Bar styling — completely overrides Blizzard's bar layout
ApplyBarStyle = function(frame, vdb)
	local bar = frame.Bar
	if not bar then return end

	local barH = vdb.barHeight or 20
	local showIcon = vdb.showIcon ~= false
	local iconGap = vdb.iconGap or 2
	local iconSide = frame.tuiBarIconSide or 'LEFT'

	-- Icon sizing and anchoring
	local icon = frame.Icon
	if icon then
		if showIcon then
			icon:Show()
			icon:ClearAllPoints()
			icon:SetSize(barH, barH)
			if iconSide == 'RIGHT' then
				icon:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
			else
				icon:SetPoint('LEFT', frame, 'LEFT', 0, 0)
			end
			if icon.Icon then icon.Icon:SetAllPoints(icon) end
		else
			icon:Hide()
		end
	end

	-- Bar anchoring: fill remaining space
	bar:ClearAllPoints()
	bar:SetReverseFill(iconSide == 'RIGHT')
	if showIcon and icon then
		if iconSide == 'RIGHT' then
			bar:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
			bar:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMLEFT', -iconGap, 0)
		else
			bar:SetPoint('TOPLEFT', icon, 'TOPRIGHT', iconGap, 0)
			bar:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
		end
	else
		bar:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
		bar:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
	end

	-- Foreground texture
	local fgTex = LSM:Fetch('statusbar', vdb.foregroundTexture or 'ElvUI Norm')
	local statusBarTex = bar:GetStatusBarTexture()
	if statusBarTex then
		statusBarTex:SetTexture(fgTex)
		statusBarTex:ClearTextureSlice()
		statusBarTex:SetTextureSliceMode(0)
	end

	-- Background texture
	local bgTex = LSM:Fetch('statusbar', vdb.backgroundTexture or 'ElvUI Norm')
	if bar.BarBG then
		bar.BarBG:SetTexture(bgTex)
		bar.BarBG:ClearAllPoints()
		bar.BarBG:SetAllPoints(bar)
	end

	-- Per-spell bar color override (only touch colors when user has custom enabled)
	local spellID = frame.GetBaseSpellID and frame:GetBaseSpellID()
	local sbc = spellID and GetSpellBarColorDB(spellID)
	local hasCustomColor = sbc and sbc.enabled

	if hasCustomColor then
		bar:SetStatusBarColor(sbc.fgColor.r, sbc.fgColor.g, sbc.fgColor.b)
		if bar.BarBG then
			local bg = sbc.bgColor
			bar.BarBG:SetVertexColor(bg.r, bg.g, bg.b, bg.a or 0.5)
		end
		-- Hook to persist custom color over Blizzard updates
		if not frame.tuiBarColorHooked then
			frame.tuiBarColorHooked = true
			local origSetColor = bar.SetStatusBarColor
			hooksecurefunc(bar, 'SetStatusBarColor', function(self)
				local sid = frame.GetBaseSpellID and frame:GetBaseSpellID()
				local sc = sid and GetSpellBarColorDB(sid)
				if sc and sc.enabled and not frame.tuiSettingColor then
					frame.tuiSettingColor = true
					origSetColor(self, sc.fgColor.r, sc.fgColor.g, sc.fgColor.b)
					frame.tuiSettingColor = false
				end
			end)
		end
	elseif frame.tuiBarColorHooked then
		-- Custom was disabled — clear the hook flag so Blizzard colors show through
		frame.tuiSettingColor = false
	end

	-- Spark (Pip) toggle
	if bar.Pip then
		if vdb.showSpark then
			bar.Pip:SetAlpha(1)
			bar.Pip:Show()
		else
			bar.Pip:SetAlpha(0)
			bar.Pip:Hide()
			if not bar.Pip.tuiKilled then
				bar.Pip.tuiKilled = true
				hooksecurefunc(bar.Pip, 'Show', function(self) self:SetAlpha(0) end)
			end
		end
	end
	if frame.CooldownFlash then frame.CooldownFlash:Hide() end

	-- Hide icon overlay texture (atlas UI-HUD-CoolDownManager-IconOverlay)
	if icon and not frame.tuiIconOverlayKilled then
		for _, region in next, { icon:GetRegions() } do
			if region:IsObjectType('Texture') then
				local atlas = region:GetAtlas()
				if atlas == 'UI-HUD-CoolDownManager-IconOverlay' then
					region:SetAlpha(0)
				end
			end
		end
		frame.tuiIconOverlayKilled = true
	end

	-- Name text
	if bar.Name then
		if vdb.showName ~= false and vdb.nameText then
			bar.Name:Show()
			StyleFontString(bar.Name, vdb.nameText)
		else
			bar.Name:Hide()
		end
	end

	-- Duration text
	if bar.Duration then
		if vdb.showTimer ~= false and vdb.durationText then
			bar.Duration:Show()
			StyleFontString(bar.Duration, vdb.durationText)
		else
			bar.Duration:Hide()
		end
	end

	-- Stacks text on icon
	if icon and showIcon and vdb.stacksText then
		local stackFS = icon.Applications and icon.Applications.Applications
		if stackFS then stackFS:SetIgnoreParentScale(true); StyleFontString(stackFS, vdb.stacksText) end
		stackFS = icon.Count
		if stackFS then stackFS:SetIgnoreParentScale(true); StyleFontString(stackFS, vdb.stacksText) end
		stackFS = icon.ChargeCount and icon.ChargeCount.Current
		if stackFS then stackFS:SetIgnoreParentScale(true); StyleFontString(stackFS, vdb.stacksText) end
	end

	-- DebuffBorder suppression
	if frame.DebuffBorder and not frame.tuiDebuffBorderKilled then
		frame.DebuffBorder:Hide()
		frame.DebuffBorder:SetAlpha(0)
		hooksecurefunc(frame.DebuffBorder, 'Show', function(self) self:Hide() end)
		frame.tuiDebuffBorderKilled = true
	end
end

LayoutBuffBar = function(viewerKey, isCapture)
	local container = containers[viewerKey]
	if not container then return end

	local db = GetDB()
	if not db or not db.enabled then return end

	local vdb = GetViewerDB(viewerKey)
	if not vdb then return end

	local viewer = GetViewer(viewerKey)
	if not viewer then return end

	local barW = vdb.barWidth or 200
	local barH = vdb.barHeight or 20
	local spacing = vdb.spacing or 2
	local growUp = (vdb.growthDirection == 'UP')

	local bars = iconCache[viewerKey]
	if not bars then bars = {}; iconCache[viewerKey] = bars end
	wipe(bars)

	if not viewer.itemFramePool then return end
	for frame in viewer.itemFramePool:EnumerateActive() do
		if frame and frame:IsShown() then
			bars[#bars + 1] = frame
		end
	end

	table.sort(bars, sortFunc)

	local count = #bars

	-- Hide When Inactive: hide container when no bars active, re-show otherwise
	if vdb.hideWhenInactive and count == 0 then
		container:Hide()
		if viewer then viewer:Hide() end
	elseif ShouldShowContainer(viewerKey) then
		container:Show()
		if viewer then viewer:Show() end
	end

	if count == 0 then
		container:SetSize(barW, barH)
		AnchorToMover(viewerKey, growUp)
		return
	end

	local mirroredColumns = vdb.mirroredColumns and count >= 2
	local columnGap = vdb.columnGap or 4
	local anchor = growUp and 'BOTTOMLEFT' or 'TOPLEFT'
	local yDir = growUp and 1 or -1

	if mirroredColumns then
		local colW = (barW - columnGap) / 2
		local rows = math_ceil(count / 2)
		container:SetSize(barW, rows * barH + (rows - 1) * spacing)

		-- Iterate by row, processing left/right pairs together
		for row = 0, rows - 1 do
			local li = row * 2 + 1
			local left = bars[li]
			local right = bars[li + 1]
			local yOff = yDir * row * (barH + spacing)

			-- Left bar: full width if unpaired (odd last), otherwise half
			left:SetScale(1)
			left:SetSize(right and colW or barW, barH)
			left.tuiBarIconSide = right and 'RIGHT' or 'LEFT'
			if isCapture or not styledFrames[left] then
				ApplyBarStyle(left, vdb)
				styledFrames[left] = viewerKey
				left.tuiViewerKey = viewerKey
			end
			left:ClearAllPoints()
			left:SetPoint(anchor, container, anchor, 0, yOff)

			-- Right bar (absent on odd-count last row)
			if right then
				right:SetScale(1)
				right:SetSize(colW, barH)
				right.tuiBarIconSide = 'LEFT'
				if isCapture or not styledFrames[right] then
					ApplyBarStyle(right, vdb)
					styledFrames[right] = viewerKey
					right.tuiViewerKey = viewerKey
				end
				right:ClearAllPoints()
				right:SetPoint(anchor, container, anchor, colW + columnGap, yOff)
			end
		end
	else
		container:SetSize(barW, count * barH + (count - 1) * spacing)

		for i, frame in ipairs(bars) do
			frame:SetScale(1)
			frame:SetSize(barW, barH)
			frame.tuiBarIconSide = 'LEFT'

			if isCapture or not styledFrames[frame] then
				ApplyBarStyle(frame, vdb)
				styledFrames[frame] = viewerKey
				frame.tuiViewerKey = viewerKey
			end

			frame:ClearAllPoints()
			frame:SetPoint(anchor, container, anchor, 0, yDir * (i - 1) * (barH + spacing))
		end
	end

	AnchorToMover(viewerKey, growUp)
end

-- Hook setup
local layoutPending = false

function ScheduleRelayout()
	if layoutPending then return end
	layoutPending = true
	C_Timer.After(0, function()
		layoutPending = false
		local db = GetDB()
		if not db or not db.enabled then return end
		for viewerKey in pairs(VIEWER_KEYS) do
			LayoutContainer(viewerKey, false)
		end
		TUI:UpdateCDMVisibility()
	end)
end

local cdmDisabledByCVar = false

local function OnCDMEvent(_, event, unit, ...)
	if event == 'CVAR_UPDATE' then
		local cvar = unit
		if cvar == 'cooldownViewerEnabled' then
			local val = ...
			if val == '0' then
				cdmDisabledByCVar = true
				for viewerKey in pairs(VIEWER_KEYS) do
					local container = containers[viewerKey]
					if container then container:Hide() end
				end
				E:Print('|cffff2f3dTrenchyUI|r: Cooldown Manager requires Blizzard\'s Cooldown Viewer. Re-enable it in Options > Gameplay Enhancements > Enable Cooldown Manager.')
			else
				cdmDisabledByCVar = false
				TUI:UpdateCDMVisibility()
				ScheduleRelayout()
			end
		end
		return
	end
	if cdmDisabledByCVar then return end
	if event == 'PLAYER_REGEN_DISABLED' then
		inCombat = true
		TUI:UpdateCDMVisibility()
		return
	elseif event == 'PLAYER_REGEN_ENABLED' then
		inCombat = false
		TUI:UpdateCDMVisibility()
		ScheduleRelayout()
		return
	end
	if event == 'UNIT_AURA' and unit ~= 'player' then return end
	ScheduleRelayout()
end

local hookedViewers = {}

local function HookViewer(viewerKey)
	local viewer = GetViewer(viewerKey)
	if not viewer or hookedViewers[viewerKey] then return end
	hookedViewers[viewerKey] = true

	-- Clear stale Edit Mode anchors (e.g. old container names from previous versions)
	local container = containers[viewerKey]
	if container then
		viewer:ClearAllPoints()
		viewer:SetPoint('CENTER', container, 'CENTER', 0, 0)
		viewer:SetParent(container)
	end

	if viewer.itemFramePool then
		hooksecurefunc(viewer.itemFramePool, 'Acquire', function()
			ScheduleRelayout()
		end)
		hooksecurefunc(viewer.itemFramePool, 'Release', function()
			ScheduleRelayout()
		end)
	end

	if viewer.OnAcquireItemFrame then
		hooksecurefunc(viewer, 'OnAcquireItemFrame', function()
			ScheduleRelayout()
		end)
	end

	hooksecurefunc(viewer, 'RefreshLayout', function()
		local db = GetDB()
		if not db or not db.enabled then return end
		LayoutContainer(viewerKey, true)
	end)

	local selection = viewer.Selection
	if selection then
		selection:Hide()
		selection:SetAlpha(0)
		hooksecurefunc(selection, 'Show', function(self)
			self:Hide()
		end)
	end
end

-- Edit Mode HWI — read/write HideWhenInactive for CDM viewers via C_EditMode
local function FindViewerHWISettings(systemIndex)
	if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return end
	local enums = Enum and Enum.EditModeSystem
	if not (enums and enums.CooldownViewer and Enum.EditModeCooldownViewerSystemIndices and Enum.EditModeCooldownViewerSetting) then return end

	local layoutInfo = C_EditMode.GetLayouts()
	if type(layoutInfo) ~= 'table' or type(layoutInfo.layouts) ~= 'table' or type(layoutInfo.activeLayout) ~= 'number' then return end

	-- Preset layouts must be merged so activeLayout index resolves
	if EditModePresetLayoutManager and EditModePresetLayoutManager.GetCopyOfPresetLayouts then
		local presets = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
		if type(presets) == 'table' then
			tAppendAll(presets, layoutInfo.layouts)
			layoutInfo.layouts = presets
		end
	end

	local active = layoutInfo.layouts[layoutInfo.activeLayout]
	if type(active) ~= 'table' or type(active.systems) ~= 'table' then return end

	for _, sys in ipairs(active.systems) do
		if sys.system == enums.CooldownViewer
			and sys.systemIndex == systemIndex
			and type(sys.settings) == 'table' then
			return sys.settings, layoutInfo
		end
	end
end

local VIEWER_SYSTEM_INDEX = {
	buffIcon = Enum.EditModeCooldownViewerSystemIndices and Enum.EditModeCooldownViewerSystemIndices.BuffIcon,
	buffBar = Enum.EditModeCooldownViewerSystemIndices and Enum.EditModeCooldownViewerSystemIndices.BuffBar,
}

function TUI:GetEditModeHWI(viewerKey)
	local sysIdx = VIEWER_SYSTEM_INDEX[viewerKey]
	if not sysIdx then return nil end
	local settings = FindViewerHWISettings(sysIdx)
	if not settings then return nil end
	local hwi = Enum.EditModeCooldownViewerSetting.HideWhenInactive
	for _, s in ipairs(settings) do
		if s.setting == hwi then return s.value == 1 end
	end
	return false
end

function TUI:SetEditModeHWI(viewerKey, enabled)
	local sysIdx = VIEWER_SYSTEM_INDEX[viewerKey]
	if not sysIdx then return 'not_ready' end
	local settings, layoutInfo = FindViewerHWISettings(sysIdx)
	if not settings then return 'not_ready' end
	local hwi = Enum.EditModeCooldownViewerSetting.HideWhenInactive
	local val = enabled and 1 or 0
	for _, s in ipairs(settings) do
		if s.setting == hwi then
			if s.value == val then return 'noop' end
			s.value = val
			C_EditMode.SaveLayouts(layoutInfo)
			return 'applied'
		end
	end
	settings[#settings + 1] = { setting = hwi, value = val }
	C_EditMode.SaveLayouts(layoutInfo)
	return 'applied'
end

ShouldShowContainer = function(viewerKey)
	local vdb = GetViewerDB(viewerKey)
	if not vdb then return true end

	local vis = vdb.visibleSetting or 'ALWAYS'
	if vis == 'HIDDEN' then return false end
	if vis == 'FADER' then return true end
	if vis == 'INCOMBAT' and not inCombat then return false end
	return true
end

function TUI:UpdateCDMVisibility()
	local db = GetDB()
	if not db or not db.enabled then return end

	local playerFrame = _G.ElvUF_Player

	for viewerKey in pairs(VIEWER_KEYS) do
		local vdb = GetViewerDB(viewerKey)
		local show = ShouldShowContainer(viewerKey)
		local container = containers[viewerKey]
		local viewer = GetViewer(viewerKey)

		if container then container:SetShown(show) end
		if viewer then viewer:SetShown(show) end

		-- Sync alpha: FADER mirrors player frame, others reset to full
		if vdb and vdb.visibleSetting == 'FADER' then
			local alpha = playerFrame and playerFrame:GetAlpha() or 1
			if container then container:SetAlpha(alpha) end
			if viewer then viewer:SetAlpha(alpha) end
		else
			if container then container:SetAlpha(1) end
			if viewer then viewer:SetAlpha(1) end
		end
	end
end

-- Public API
function TUI:RefreshCDM()
	local db = GetDB()
	if not db or not db.enabled then return end

	wipe(styledFrames)
	wipe(glowActive)

	for viewerKey in pairs(VIEWER_KEYS) do
		LayoutContainer(viewerKey, true)
	end

	self:UpdateCDMVisibility()

	if previewActive then
		previewActive = false
		ShowPreview()
	end
end

function TUI:InitCooldownManager()
	local db = GetDB()
	if not db or not db.enabled then return end

	-- Force Blizzard CDM on; warn if viewers aren't loaded yet (requires reload)
	if GetCVarBool('cooldownViewerEnabled') ~= true then
		SetCVar('cooldownViewerEnabled', 1)
		if not _G['EssentialCooldownViewer'] then
			C_Timer.After(1, function()
				E:StaticPopup_Show('CONFIG_RL')
			end)
			E:Print('|cffff2f3dTrenchyUI|r: Enabled Blizzard Cooldown Manager. A reload is required.')
			return
		end
	end

	-- Sync our DB to reflect Blizzard's current Edit Mode HWI state
	for _, vk in ipairs({'buffIcon', 'buffBar'}) do
		local vdb = GetViewerDB(vk)
		local blizzHWI = self:GetEditModeHWI(vk)
		if vdb and blizzHWI ~= nil then
			vdb.hideWhenInactive = blizzHWI
		end
	end

	C_Timer.After(0, function()
		for viewerKey in pairs(VIEWER_KEYS) do
			CreateContainer(viewerKey)
			HookViewer(viewerKey)
			LayoutContainer(viewerKey, true)
		end

		-- Resolve viewerKey from a frame or its parents via styledFrames/tuiViewerKey
		local function ResolveViewerKey(frame)
			if not frame then return nil end
			local key = styledFrames[frame] or frame.tuiViewerKey
			if key then return key end
			local parent = frame:GetParent()
			return parent and (styledFrames[parent] or parent.tuiViewerKey) or nil
		end

		-- Post-hook ElvUI Skins to re-apply our text styling after ElvUI overrides it
		local S = E:GetModule('Skins', true)
		if S then
			if S.CooldownManager_UpdateTextContainer then
				hooksecurefunc(S, 'CooldownManager_UpdateTextContainer', function(_, itemFrame)
					local viewerKey = ResolveViewerKey(itemFrame)
					if not viewerKey then return end
					local vdb = GetViewerDB(viewerKey)
					if vdb then
						ApplyCountText(itemFrame, vdb.countText)
					end
				end)
			end
			if S.CooldownManager_SkinIcon then
				hooksecurefunc(S, 'CooldownManager_SkinIcon', function(_, itemFrame)
					local viewerKey = ResolveViewerKey(itemFrame)
					if not viewerKey then return end
					local cdb = GetDB()
					local vdb = GetViewerDB(viewerKey)
					if vdb and cdb then
						ApplyTextOverrides(itemFrame, vdb, cdb)
					end
				end)
			end
			if S.CooldownManager_SkinBar then
				hooksecurefunc(S, 'CooldownManager_SkinBar', function(_, frame)
					local viewerKey = ResolveViewerKey(frame)
					if viewerKey == 'buffBar' then
						local vdb = GetViewerDB('buffBar')
						if vdb then ApplyBarStyle(frame, vdb) end
					end
				end)
			end
			if S.CooldownManager_UpdateTextBar then
				hooksecurefunc(S, 'CooldownManager_UpdateTextBar', function(_, bar)
					local frame = bar:GetParent()
					if frame and ResolveViewerKey(frame) == 'buffBar' then
						local vdb = GetViewerDB('buffBar')
						if vdb then
							if bar.Name and vdb.nameText then StyleFontString(bar.Name, vdb.nameText) end
							if bar.Duration and vdb.durationText then StyleFontString(bar.Duration, vdb.durationText) end
						end
					end
				end)
			end
		end

		-- Re-shield cooldown text after ElvUI's CooldownUpdate sets SetHideCountdownNumbers
		hooksecurefunc(E, 'CooldownUpdate', function(_, cooldown)
			if not cooldown or not cooldown.tuiText then return end
			cooldown:SetHideCountdownNumbers(false)
		end)

		local eventFrame = CreateFrame('Frame')
		eventFrame:RegisterEvent('UNIT_AURA')
		eventFrame:RegisterEvent('SPELL_UPDATE_COOLDOWN')
		eventFrame:RegisterEvent('SPELLS_CHANGED')
		eventFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
		eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
		eventFrame:RegisterEvent('CVAR_UPDATE')
		eventFrame:SetScript('OnEvent', OnCDMEvent)

		TUI:UpdateCDMVisibility()

		-- Mirror player frame fader alpha to FADER-mode CDM containers
		local playerFrame = _G.ElvUF_Player
		if playerFrame then
			hooksecurefunc(playerFrame, 'SetAlpha', function(pf)
				local alpha = pf:GetAlpha()
				for viewerKey in pairs(VIEWER_KEYS) do
					local vdb = GetViewerDB(viewerKey)
					if vdb and vdb.visibleSetting == 'FADER' then
						local container = containers[viewerKey]
						if container then container:SetAlpha(alpha) end
						local viewer = GetViewer(viewerKey)
						if viewer then viewer:SetAlpha(alpha) end
					end
				end
			end)
		end

		-- Right-click context menu for buff CDM items
		-- Category enum: Essential=0, Utility=1, TrackedBuff=2, TrackedBar=3
		local CATEGORY_TRACKED_BUFF = 2
		local CATEGORY_TRACKED_BAR = 3
		local tuiMenuTitle = '|cffff2f3dTrenchyUI|r CDM'

		Menu.ModifyMenu('MENU_COOLDOWN_SETTINGS_ITEM', function(owner, rootDescription)
			if not owner or not owner.GetCooldownInfo then return end
			local cdInfo = owner:GetCooldownInfo()
			if not cdInfo then return end
			local cat = cdInfo.category

			if cat ~= CATEGORY_TRACKED_BUFF and cat ~= CATEGORY_TRACKED_BAR then return end

			rootDescription:CreateDivider()
			rootDescription:CreateTitle(tuiMenuTitle)

			if cat == CATEGORY_TRACKED_BAR then
				rootDescription:CreateButton('Bar Color Options', function()
					local spellID = owner.GetBaseSpellID and owner:GetBaseSpellID()
					if spellID then TUI:ShowBarColorPanel(spellID) end
				end)
			else
				rootDescription:CreateButton('Glow Options', function()
					local spellID = owner.GetBaseSpellID and owner:GetBaseSpellID()
					if spellID then TUI:ShowGlowPanel(spellID) end
				end)
			end
		end)

		SLASH_TUICDM1 = '/cdm'
		SlashCmdList['TUICDM'] = function()
			if cdmDisabledByCVar then
				E:Print('|cffff2f3dTrenchyUI|r: Cooldown Manager requires Blizzard\'s Cooldown Viewer. Re-enable it in Options > Gameplay Enhancements > Enable Cooldown Manager.')
				return
			end
			OpenCDMConfig()
		end
	end)
end

-- Config hooks
local cdmTabActive = false
local configCloseHooked = false

local function TryHookConfigClose()
	if configCloseHooked then return end

	local ACD = E.Libs.AceConfigDialog
	if not ACD or not ACD.OpenFrames then return end

	local configFrame = ACD.OpenFrames.ElvUI
	if not configFrame or not configFrame.frame then return end

	configCloseHooked = true
	configFrame.frame:HookScript('OnHide', function()
		cdmTabActive = false
		HideBlizzardCDMSettings()
		HidePreview()
	end)
end

C_Timer.After(0, function()
	local ACD = E.Libs.AceConfigDialog
	if ACD then
		-- Shared logic for detecting CDM tab navigation
		local function HandleGroupChange(appName, pathContainsCDM)
			if appName ~= 'ElvUI' then return end

			-- Try to hook config close if we haven't yet (frame now exists)
			if not configCloseHooked then
				TryHookConfigClose()
			end

			if pathContainsCDM and not cdmTabActive then
				cdmTabActive = true
				ShowBlizzardCDMSettings()
				ShowPreview()
			elseif not pathContainsCDM and cdmTabActive then
				cdmTabActive = false
				HideBlizzardCDMSettings()
				HidePreview()
			end
		end

		-- Hook SelectGroup for programmatic navigation (e.g. /cdm, mover right-click)
		hooksecurefunc(ACD, 'SelectGroup', function(_, appName, ...)
			local isCDM = false
			for i = 1, select('#', ...) do
				if select(i, ...) == 'cooldownManager' then
					isCDM = true
					break
				end
			end
			HandleGroupChange(appName, isCDM)
		end)

		-- Hook FeedGroup for user clicks — skip parent-level paths to avoid recursive undo
		hooksecurefunc(ACD, 'FeedGroup', function(_, appName, _, _, _, path)
			if appName ~= 'ElvUI' or type(path) ~= 'table' then return end
			if #path == 0 then return end -- root level render, skip

			local hasTrenchyUI = false
			local isCDM = false
			for i = 1, #path do
				if path[i] == 'TrenchyUI' then hasTrenchyUI = true end
				if path[i] == 'cooldownManager' then isCDM = true end
			end

			-- Skip parent TrenchyUI tree setup (path={'TrenchyUI'}) — it's just
			-- rendering the tree container, not an actual tab selection
			if hasTrenchyUI and not isCDM and #path < 2 then return end

			-- Only react when navigating within TrenchyUI or away from CDM
			if not hasTrenchyUI and not cdmTabActive then return end

			HandleGroupChange(appName, isCDM)
		end)
	end

	-- Mover right-click hook
	hooksecurefunc(E, 'ToggleOptions', function(_, msg)
		local viewerKey = msg and moverToViewer[msg]
		if viewerKey then
			local db = GetDB()
			if db then db.selectedViewer = viewerKey end
			E.Libs.AceConfigRegistry:NotifyChange('ElvUI')
			ShowBlizzardCDMSettings()
			ShowPreview()
		end

		-- Also try to hook config close from here as a fallback
		if not configCloseHooked then
			C_Timer.After(0.1, TryHookConfigClose)
		end
	end)
end)
