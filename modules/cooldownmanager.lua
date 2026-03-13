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
}

local containers = {}   -- [viewerKey] = container frame
local styledFrames = {} -- [itemFrame] = viewerKey — tracks which frames already have text/glow applied
local glowActive = {}   -- [itemFrame] = true — tracks which frames currently have our glow
local previewActive = false
local inCombat = false
local ScheduleRelayout -- forward declaration

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

local function ApplyCooldownText(cooldown, tdb)
	if not cooldown or not tdb then return end

	cooldown:SetHideCountdownNumbers(false)

	local text = cooldown.Text or cooldown:GetRegions()
	if text and text.SetTextColor then
		cooldown.Text = text
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
	-- Standalone FontString since Blizzard hides inactive cooldown text
	if show then
		if not itemFrame.tuiCDPreview then
			itemFrame.tuiCDPreview = itemFrame:CreateFontString(nil, 'OVERLAY')
		end
		local pfs = itemFrame.tuiCDPreview
		local tdb = vdb and vdb.cooldownText
		if tdb then
			StyleFontString(pfs, tdb)
		end
		pfs:SetText('12')
		pfs:Show()
	elseif itemFrame.tuiCDPreview then
		itemFrame.tuiCDPreview:Hide()
	end

	-- Count preview: use actual count FontString
	local countFS = itemFrame.Count
		or (itemFrame.ChargeCount and itemFrame.ChargeCount.Current)
		or (itemFrame.Applications and itemFrame.Applications.Applications)
	if countFS and countFS.SetText then
		if show then
			countFS:SetText('3')
			countFS:SetAlpha(1)
		else
			countFS:SetText('')
		end
	end
end

local function ShowPreview()
	if previewActive then return end
	previewActive = true

	for viewerKey in pairs(VIEWER_KEYS) do
		local vdb = GetViewerDB(viewerKey)
		local viewer = GetViewer(viewerKey)
		if viewer and vdb then
			for frame in viewer.itemFramePool:EnumerateActive() do
				if frame and frame.layoutIndex then
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
		if viewer then
			for frame in viewer.itemFramePool:EnumerateActive() do
				if frame and frame.layoutIndex then
					SetPreviewText(frame, false)
				end
			end
		end
	end
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

	function TUI:ShowGlowPanel(spellID)
		if not glowPanel then CreateGlowPanel() end
		currentSpellID = spellID

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
		if editAlert and not editAlert.tuiGlowHooked then
			editAlert:HookScript('OnShow', function() if glowPanel then glowPanel:Hide() end end)
			editAlert.tuiGlowHooked = true
		end

		UpdatePanelWidgets()
		glowPanel:Show()
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
	local iconW = vdb and vdb.iconWidth or 30
	local iconH = (vdb and vdb.keepSizeRatio and iconW) or (vdb and vdb.iconHeight or 30)

	local configStr = CDM_CONFIG_STRING .. ',' .. viewerKey

	local frame = CreateFrame('Frame', info.mover .. 'Holder', E.UIParent)
	frame:SetSize(iconW * 8, iconH * 2)
	frame:SetPoint('CENTER', E.UIParent, 'CENTER', 0, 0)
	frame:SetFrameStrata('MEDIUM')
	frame:SetFrameLevel(5)

	E:CreateMover(frame, info.mover .. 'Mover', 'TUI ' .. info.label, nil, nil, nil, 'ALL,TRENCHYUI', nil, configStr)
	moverToViewer[configStr] = viewerKey

	containers[viewerKey] = frame
	return frame
end

local iconCache = {}    -- [viewerKey] = reusable table for icon collection

local function LayoutContainer(viewerKey, isCapture)
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
		LayoutContainer(viewerKey, false)
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

-- Edit Mode HWI control via C_EditMode.SaveLayouts
local function HasEditModeApis()
	return C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts
		and Enum and Enum.EditModeSystem and Enum.EditModeSystem.CooldownViewer
		and Enum.EditModeCooldownViewerSystemIndices
		and Enum.EditModeCooldownViewerSetting
end

local function GetEditModeLayoutInfo()
	if not (C_EditMode and C_EditMode.GetLayouts) then return nil end
	local layoutInfo = C_EditMode.GetLayouts()
	if type(layoutInfo) ~= 'table' or type(layoutInfo.layouts) ~= 'table' then return nil end
	if type(layoutInfo.activeLayout) == 'number' and EditModePresetLayoutManager
		and EditModePresetLayoutManager.GetCopyOfPresetLayouts then
		local presets = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
		if type(presets) == 'table' then
			tAppendAll(presets, layoutInfo.layouts)
			layoutInfo.layouts = presets
		end
	end
	return layoutInfo
end

local function GetEditModeActiveLayout(layoutInfo)
	if type(layoutInfo) ~= 'table' then return nil end
	local layouts, idx = layoutInfo.layouts, layoutInfo.activeLayout
	if type(layouts) ~= 'table' or type(idx) ~= 'number' then return nil end
	local layout = layouts[idx]
	if type(layout) ~= 'table' or type(layout.systems) ~= 'table' then return nil end
	return layout
end

local function UpsertEditModeSetting(settings, settingEnum, value)
	if type(settings) ~= 'table' then return false end
	for _, info in ipairs(settings) do
		if info.setting == settingEnum then
			if info.value ~= value then
				info.value = value
				return true
			end
			return false
		end
	end
	settings[#settings + 1] = { setting = settingEnum, value = value }
	return true
end

function TUI:GetBuffIconEditModeHWI()
	if not HasEditModeApis() then return nil end
	local layoutInfo = GetEditModeLayoutInfo()
	local activeLayout = GetEditModeActiveLayout(layoutInfo)
	if not activeLayout then return nil end

	local cooldownSystem = Enum.EditModeSystem.CooldownViewer
	local buffIconIndex = Enum.EditModeCooldownViewerSystemIndices.BuffIcon
	local hwiSetting = Enum.EditModeCooldownViewerSetting.HideWhenInactive

	for _, systemInfo in ipairs(activeLayout.systems) do
		if systemInfo.system == cooldownSystem and systemInfo.systemIndex == buffIconIndex
			and type(systemInfo.settings) == 'table' then
			for _, info in ipairs(systemInfo.settings) do
				if info.setting == hwiSetting then
					return info.value == 1
				end
			end
		end
	end
	return false
end

function TUI:SetBuffIconEditModeHWI(enabled)
	if not HasEditModeApis() then return 'not_ready' end
	local layoutInfo = GetEditModeLayoutInfo()
	local activeLayout = GetEditModeActiveLayout(layoutInfo)
	if not activeLayout then return 'not_ready' end

	local changed = false
	local cooldownSystem = Enum.EditModeSystem.CooldownViewer
	local buffIconIndex = Enum.EditModeCooldownViewerSystemIndices.BuffIcon
	local hwiSetting = Enum.EditModeCooldownViewerSetting.HideWhenInactive
	local desiredValue = enabled and 1 or 0

	for _, systemInfo in ipairs(activeLayout.systems) do
		if systemInfo.system == cooldownSystem and systemInfo.systemIndex == buffIconIndex
			and type(systemInfo.settings) == 'table' then
			if UpsertEditModeSetting(systemInfo.settings, hwiSetting, desiredValue) then
				changed = true
			end
		end
	end

	if not changed then return 'noop' end
	C_EditMode.SaveLayouts(layoutInfo)
	return 'applied'
end

local function ShouldShowContainer(viewerKey)
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
	wipe(hookedAlerts)
	wipe(hookedSwipes)

	for viewerKey in pairs(VIEWER_KEYS) do
		LayoutContainer(viewerKey, true)
	end

	if previewActive then
		previewActive = false
		ShowPreview()
	end
end

function TUI:InitCooldownManager()
	local db = GetDB()
	if not db or not db.enabled then return end

	SetCVar('cooldownViewerEnabled', 1)

	-- Sync our DB to reflect Blizzard's current Edit Mode HWI state
	local buffDB = GetViewerDB('buffIcon')
	local blizzHWI = self:GetBuffIconEditModeHWI()
	if buffDB and blizzHWI ~= nil then
		buffDB.hideWhenInactive = blizzHWI
	end

	C_Timer.After(0, function()
		for viewerKey in pairs(VIEWER_KEYS) do
			CreateContainer(viewerKey)
			HookViewer(viewerKey)
			LayoutContainer(viewerKey, true)
		end

		-- Post-hook ElvUI Skins to re-apply our text styling after ElvUI overrides it
		local S = E:GetModule('Skins', true)
		if S then
			if S.CooldownManager_UpdateTextContainer then
				hooksecurefunc(S, 'CooldownManager_UpdateTextContainer', function(_, itemFrame)
					local viewerKey = styledFrames[itemFrame]
					if not viewerKey then return end
					local vdb = GetViewerDB(viewerKey)
					if vdb then
						ApplyCountText(itemFrame, vdb.countText)
					end
				end)
			end
			if S.CooldownManager_SkinIcon then
				hooksecurefunc(S, 'CooldownManager_SkinIcon', function(_, itemFrame)
					local viewerKey = styledFrames[itemFrame]
					if not viewerKey then return end
					local cdb = GetDB()
					local vdb = GetViewerDB(viewerKey)
					if vdb and cdb then
						ApplyTextOverrides(itemFrame, vdb, cdb)
					end
				end)
			end
		end

		-- Post-hook ElvUI cooldown text to re-apply our cooldown timer styling
		hooksecurefunc(E, 'CooldownUpdate', function(_, cooldown)
			if not cooldown then return end
			local itemFrame = cooldown:GetParent()
			local viewerKey = itemFrame and styledFrames[itemFrame]
			if not viewerKey then return end
			local vdb = GetViewerDB(viewerKey)
			if vdb then
				ApplyCooldownText(cooldown, vdb.cooldownText)
			end
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

		-- Right-click context menu for buff icon glow options
		local BUFF_CATEGORY = 2
		local tuiMenuTitle = '|cffff2f3dTrenchyUI|r CDM'
		Menu.ModifyMenu('MENU_COOLDOWN_SETTINGS_ITEM', function(owner, rootDescription)
			if not owner or not owner.GetCooldownInfo then return end
			local cdInfo = owner:GetCooldownInfo()
			if not cdInfo or cdInfo.category ~= BUFF_CATEGORY then return end

			rootDescription:CreateDivider()
			rootDescription:CreateTitle(tuiMenuTitle)
			rootDescription:CreateButton('Glow Options', function()
				local spellID = owner.GetBaseSpellID and owner:GetBaseSpellID()
				if spellID then TUI:ShowGlowPanel(spellID) end
			end)
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
