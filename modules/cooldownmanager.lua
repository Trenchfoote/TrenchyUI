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

local function ApplyGlow(itemFrame, glowDB)
	if not LCG then return end

	local alert = itemFrame.SpellActivationAlert
	if not alert or not alert:IsShown() then
		StopGlow(itemFrame)
		return
	end

	alert:SetAlpha(0)
	itemFrame.tuiAlertHidden = true

	-- Hook Show so we keep suppressing Blizzard's alert while glow is enabled
	if not hookedAlerts[itemFrame] then
		hookedAlerts[itemFrame] = true
		hooksecurefunc(alert, 'Show', function(self)
			local vKey = styledFrames[itemFrame]
			local vdb = vKey and GetViewerDB(vKey)
			if vdb and vdb.glow and vdb.glow.enabled then
				self:SetAlpha(0)
				itemFrame.tuiAlertHidden = true
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

	if glowType == 'pixel' then
		LCG.PixelGlow_Start(itemFrame, glowColor, glowDB.lines or 8, glowDB.speed or 0.25, glowDB.length, glowDB.thickness or 2, 0, 0, nil, 'TUI_CDM')
	elseif glowType == 'autocast' then
		LCG.AutoCastGlow_Start(itemFrame, glowColor, glowDB.particles or 4, glowDB.speed or 0.25, glowDB.scale or 1, 0, 0, 'TUI_CDM')
	elseif glowType == 'button' then
		LCG.ButtonGlow_Start(itemFrame, glowColor, glowDB.speed or 0.25)
	elseif glowType == 'proc' then
		LCG.ProcGlow_Start(itemFrame, {
			color = glowColor,
			startAnim = glowDB.startAnim ~= false,
			key = 'TUI_CDM',
		})
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

		if useGlow then
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

-- Blizzard HWI setting via Edit Mode API
local CDM_SETTING_HWI = 8 -- Enum.EditModeCooldownViewerSetting.HideWhenInactive

function TUI:SetBlizzardHWI(viewerKey, enabled)
	local viewer = GetViewer(viewerKey)
	if not viewer then return end
	local mgr = EditModeManagerFrame
	if not mgr or not mgr.OnSystemSettingChange then return end
	pcall(mgr.OnSystemSettingChange, mgr, viewer, CDM_SETTING_HWI, enabled and 1 or 0)
end

-- Visibility
local function ShouldShowContainer(viewerKey)
	local vdb = GetViewerDB(viewerKey)
	if not vdb then return true end

	local vis = vdb.visibleSetting or 'ALWAYS'
	if vis == 'HIDDEN' then return false end
	if vis == 'INCOMBAT' and not inCombat then return false end
	return true
end

function TUI:UpdateCDMVisibility()
	local db = GetDB()
	if not db or not db.enabled then return end

	for viewerKey in pairs(VIEWER_KEYS) do
		local show = ShouldShowContainer(viewerKey)
		local container = containers[viewerKey]
		if container then
			container:SetShown(show)
		end
		local viewer = GetViewer(viewerKey)
		if viewer then
			viewer:SetShown(show)
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

	C_Timer.After(0, function()
		for viewerKey in pairs(VIEWER_KEYS) do
			CreateContainer(viewerKey)
			HookViewer(viewerKey)
			LayoutContainer(viewerKey, true)
		end

		-- Sync Blizzard HWI to match our DB setting for buffIcon
		local bdb = GetViewerDB('buffIcon')
		if bdb then
			TUI:SetBlizzardHWI('buffIcon', bdb.hideWhenInactive)
		end

		local eventFrame = CreateFrame('Frame')
		eventFrame:RegisterEvent('UNIT_AURA')
		eventFrame:RegisterEvent('SPELL_UPDATE_COOLDOWN')
		eventFrame:RegisterEvent('SPELLS_CHANGED')
		eventFrame:RegisterEvent('PLAYER_REGEN_DISABLED')
		eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
		eventFrame:RegisterEvent('CVAR_UPDATE')
		eventFrame:SetScript('OnEvent', OnCDMEvent)

		TUI:UpdateCDMVisibility()
	end)
end

-- Slash command
SLASH_TUICDM1 = '/cdm'
SlashCmdList['TUICDM'] = function()
	local db = GetDB()
	if not db or not db.enabled then return end
	if cdmDisabledByCVar then
		E:Print('|cffff2f3dTrenchyUI|r: Cooldown Manager requires Blizzard\'s Cooldown Viewer. Re-enable it in Options > Gameplay Enhancements > Enable Cooldown Manager.')
		return
	end
	OpenCDMConfig()
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
