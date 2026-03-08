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

-- Viewer types we manage (buffBar excluded — different frame structure)
local VIEWER_KEYS = {
	essential = { global = 'EssentialCooldownViewer', label = 'Essential CDs',  mover = 'TUI_CDM_Essential' },
	utility   = { global = 'UtilityCooldownViewer',  label = 'Utility CDs',    mover = 'TUI_CDM_Utility' },
	buffIcon  = { global = 'BuffIconCooldownViewer', label = 'Buff Icon CDs',  mover = 'TUI_CDM_BuffIcon' },
}

local containers = {}   -- [viewerKey] = container frame
local hookedViewers = {}
local styledFrames = {} -- [itemFrame] = viewerKey — tracks which frames already have text/glow applied
local glowActive = {}   -- [itemFrame] = true — tracks which frames currently have our glow
local iconCache = {}    -- [viewerKey] = reusable table for icon collection
local glowColor = {}    -- reusable color table for glow
local previewActive = false

local sortFunc = function(a, b) return (a.layoutIndex or 0) < (b.layoutIndex or 0) end

-- ═══════════════════════════════════════════════════════════════════
-- DB HELPERS
-- ═══════════════════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════════════════
-- GLOW
-- ═══════════════════════════════════════════════════════════════════
local function StopGlow(itemFrame)
	if not LCG or not glowActive[itemFrame] then return end
	glowActive[itemFrame] = nil

	LCG.PixelGlow_Stop(itemFrame, 'TUI_CDM')
	LCG.AutoCastGlow_Stop(itemFrame, 'TUI_CDM')
	LCG.ButtonGlow_Stop(itemFrame)
	LCG.ProcGlow_Stop(itemFrame, 'TUI_CDM')

	-- Restore Blizzard's SpellActivationAlert if we previously hid it
	if itemFrame.tuiAlertHidden then
		itemFrame.tuiAlertHidden = nil
		local alert = itemFrame.SpellActivationAlert
		if alert then alert:SetAlpha(1) end
	end
end

local hookedAlerts = {} -- [itemFrame] = true — tracks which alerts we've hooked

local function ApplyGlow(itemFrame, db)
	if not LCG then return end

	-- Glow on proc — mirror Blizzard's SpellActivationAlert
	local alert = itemFrame.SpellActivationAlert
	if not alert or not alert:IsShown() then
		StopGlow(itemFrame)
		return
	end

	-- Hide Blizzard's proc glow so only ours shows
	alert:SetAlpha(0)
	itemFrame.tuiAlertHidden = true

	-- Hook Show so we keep suppressing Blizzard's alert while glow is enabled
	if not hookedAlerts[itemFrame] then
		hookedAlerts[itemFrame] = true
		hooksecurefunc(alert, 'Show', function(self)
			local cdb = GetDB()
			if cdb and cdb.enabled and cdb.glow and cdb.glow.enabled then
				self:SetAlpha(0)
				itemFrame.tuiAlertHidden = true
			end
		end)
	end

	glowActive[itemFrame] = true

	local glowType = db.glow.type or 'pixel'
	local color = db.glow.color
	glowColor[1] = color and color.r or 0.95
	glowColor[2] = color and color.g or 0.95
	glowColor[3] = color and color.b or 0.32
	glowColor[4] = color and color.a or 1

	if glowType == 'pixel' then
		LCG.PixelGlow_Start(itemFrame, glowColor, db.glow.lines or 8, db.glow.speed or 0.25, db.glow.length, db.glow.thickness or 2, 0, 0, nil, 'TUI_CDM')
	elseif glowType == 'autocast' then
		LCG.AutoCastGlow_Start(itemFrame, glowColor, db.glow.particles or 4, db.glow.speed or 0.25, db.glow.scale or 1, 0, 0, 'TUI_CDM')
	elseif glowType == 'button' then
		LCG.ButtonGlow_Start(itemFrame, glowColor, db.glow.speed or 0.25)
	elseif glowType == 'proc' then
		LCG.ProcGlow_Start(itemFrame, {
			color = glowColor,
			startAnim = db.glow.startAnim ~= false,
			key = 'TUI_CDM',
		})
	end
end

local function ApplyIconZoom(itemFrame, zoom)
	if not zoom or zoom <= 0 then return end
	local icon = itemFrame.Icon
	if icon and icon.SetTexCoord then
		icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- TEXT STYLING — overrides ElvUI's cdmanager cooldown text settings
-- ═══════════════════════════════════════════════════════════════════
local function GetTextColor(tdb)
	if tdb.classColor then
		local cc = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[E.myclass] or RAID_CLASS_COLORS[E.myclass]
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

local hookedSwipes = {} -- [cooldown] = true — tracks which cooldowns have SetDrawSwipe hooked

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

-- ═══════════════════════════════════════════════════════════════════
-- PREVIEW — show fake text on icons when config is open
-- ═══════════════════════════════════════════════════════════════════
local function SetPreviewText(itemFrame, show, vdb)
	-- Cooldown preview: use a standalone FontString since Blizzard hides
	-- the cooldown text region when no cooldown is active
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
		local container = containers[viewerKey]
		if container and vdb then
			for _, child in ipairs({ container:GetChildren() }) do
				if child and child.layoutIndex then
					SetPreviewText(child, true, vdb)
				end
			end
		end
	end
end

local function HidePreview()
	if not previewActive then return end
	previewActive = false

	for viewerKey in pairs(VIEWER_KEYS) do
		local container = containers[viewerKey]
		if container then
			for _, child in ipairs({ container:GetChildren() }) do
				if child and child.layoutIndex then
					SetPreviewText(child, false)
				end
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- BLIZZARD CDM SETTINGS HELPER
-- ═══════════════════════════════════════════════════════════════════
local function ShowBlizzardCDMSettings()
	if not C_AddOns.IsAddOnLoaded('Blizzard_CooldownViewer') then
		C_AddOns.LoadAddOn('Blizzard_CooldownViewer')
	end
	local settings = _G.CooldownViewerSettings
	if settings and not settings:IsShown() then
		settings:Show()
	end
end

local function HideBlizzardCDMSettings()
	local settings = _G.CooldownViewerSettings
	if settings and settings:IsShown() then
		settings:Hide()
	end
end

local function OpenCDMConfig()
	E:ToggleOptions('TrenchyUI')
	C_Timer.After(0.1, function()
		local configGroup = E.Options and E.Options.args and E.Options.args.TrenchyUI
		if configGroup and configGroup.args and configGroup.args.cooldownManager then
			E.Libs.AceConfigDialog:SelectGroup('ElvUI', 'TrenchyUI', 'cooldownManager')
		end
		-- Defer CDM settings + preview until after layout settles
		C_Timer.After(0.2, function()
			ShowBlizzardCDMSettings()
			ShowPreview()
		end)
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- CONTAINER CREATION
-- ═══════════════════════════════════════════════════════════════════
local CDM_CONFIG_STRING = '/TrenchyUI,cooldownManager'

local function CreateContainer(viewerKey)
	local info = VIEWER_KEYS[viewerKey]
	local vdb = GetViewerDB(viewerKey)
	local iconW = vdb and vdb.iconWidth or 30
	local iconH = vdb and vdb.iconHeight or 30

	local frame = CreateFrame('Frame', info.mover .. 'Holder', E.UIParent)
	frame:SetSize(iconW * 8, iconH * 2)
	frame:SetPoint('CENTER', E.UIParent, 'CENTER', 0, 0)
	frame:SetFrameStrata('MEDIUM')
	frame:SetFrameLevel(5)

	-- 9th param = configString for right-click on mover
	E:CreateMover(frame, info.mover .. 'Mover', 'TUI ' .. info.label, nil, nil, nil, nil, nil, CDM_CONFIG_STRING)

	containers[viewerKey] = frame
	iconCache[viewerKey] = {}
	return frame
end

-- ═══════════════════════════════════════════════════════════════════
-- GRID LAYOUT — positions captured icons inside our container
-- Styling (text/glow/zoom) only applied on capture, not every relayout.
-- ═══════════════════════════════════════════════════════════════════
local function LayoutContainer(viewerKey, isCapture)
	local container = containers[viewerKey]
	if not container then return end

	local db = GetDB()
	if not db or not db.enabled then return end

	local vdb = GetViewerDB(viewerKey)
	if not vdb then return end

	local iconW = vdb.iconWidth or 30
	local iconH = vdb.iconHeight or 30
	local perRow = vdb.iconsPerRow or 12

	-- Scale spacing so slider value = visual pixels (E.UIParent has custom scale)
	local rawSpacing = vdb.spacing or 2
	local parentScale = container:GetEffectiveScale()
	local spacing = (parentScale and parentScale > 0) and (rawSpacing / parentScale) or rawSpacing
	local growUp = (vdb.growthDirection == 'UP')

	local icons = iconCache[viewerKey]
	if not icons then icons = {}; iconCache[viewerKey] = icons end
	wipe(icons)

	for _, child in ipairs({ container:GetChildren() }) do
		if child and child:IsShown() and child.layoutIndex then
			icons[#icons + 1] = child
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
	local useGlow = db.glow and db.glow.enabled

	local iconZoom = vdb.iconZoom

	for _, icon in ipairs(icons) do
		icon:SetSize(iconW, iconH)

		-- Zoom runs every relayout — Blizzard resets texcoords on texture change
		ApplyIconZoom(icon, iconZoom)

		if applyStyle or not styledFrames[icon] then
			ApplyTextOverrides(icon, vdb, db)
			styledFrames[icon] = viewerKey
		end

		-- Glow must run every relayout since proc state changes dynamically
		if useGlow then
			ApplyGlow(icon, db)
		else
			StopGlow(icon)
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

-- ═══════════════════════════════════════════════════════════════════
-- FRAME CAPTURE — reparent CDM item frames into our containers
-- ═══════════════════════════════════════════════════════════════════
local function CaptureAndLayout(viewer, viewerKey)
	local db = GetDB()
	if not db or not db.enabled then return end

	local container = containers[viewerKey]
	if not container then return end

	-- Hide container during recapture to prevent visual flash
	local needsCapture = false
	for _, child in ipairs({ viewer:GetChildren() }) do
		if child and child.layoutIndex then
			if child:GetParent() ~= container then
				if not needsCapture then
					needsCapture = true
					container:SetAlpha(0)
				end
				child:SetParent(container)
				child:SetScale(1)
			end
		end
	end

	viewer:SetAlpha(0)
	LayoutContainer(viewerKey, true)

	if needsCapture then
		container:SetAlpha(1)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- HOOK SETUP
-- ═══════════════════════════════════════════════════════════════════
local function HookViewer(viewerKey)
	local viewer = GetViewer(viewerKey)
	if not viewer or hookedViewers[viewerKey] then return end
	hookedViewers[viewerKey] = true

	hooksecurefunc(viewer, 'RefreshLayout', function(self)
		CaptureAndLayout(self, viewerKey)
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- EVENT-DRIVEN RE-LAYOUT (position only, no restyling)
-- ═══════════════════════════════════════════════════════════════════
local layoutPending = false

local function ScheduleRelayout(_, event, unit)
	if event == 'UNIT_AURA' and unit ~= 'player' then return end
	if layoutPending then return end
	layoutPending = true
	C_Timer.After(0.1, function()
		layoutPending = false
		local db = GetDB()
		if not db or not db.enabled then return end
		for viewerKey in pairs(VIEWER_KEYS) do
			LayoutContainer(viewerKey)
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════════
function TUI:RefreshCDM()
	local db = GetDB()
	if not db or not db.enabled then return end

	wipe(styledFrames)
	wipe(glowActive)

	for viewerKey in pairs(VIEWER_KEYS) do
		LayoutContainer(viewerKey, true)
	end

	-- Update preview if active
	if previewActive then
		previewActive = false
		ShowPreview()
	end
end

function TUI:InitCooldownManager()
	local db = GetDB()
	if not db or not db.enabled then return end

	C_Timer.After(0, function()
		for viewerKey in pairs(VIEWER_KEYS) do
			CreateContainer(viewerKey)
		end

		for viewerKey in pairs(VIEWER_KEYS) do
			HookViewer(viewerKey)
		end

		for viewerKey in pairs(VIEWER_KEYS) do
			local viewer = GetViewer(viewerKey)
			if viewer then
				CaptureAndLayout(viewer, viewerKey)
			end
		end

		local eventFrame = CreateFrame('Frame')
		eventFrame:RegisterEvent('UNIT_AURA')
		eventFrame:RegisterEvent('SPELL_UPDATE_COOLDOWN')
		eventFrame:RegisterEvent('SPELLS_CHANGED')
		eventFrame:SetScript('OnEvent', ScheduleRelayout)
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- /cdm SLASH COMMAND
-- ═══════════════════════════════════════════════════════════════════
SLASH_TUICDM1 = '/cdm'
SlashCmdList['TUICDM'] = function()
	OpenCDMConfig()
end

-- ═══════════════════════════════════════════════════════════════════
-- CONFIG HOOKS — mover right-click + ESC close (single ToggleOptions hook)
-- ═══════════════════════════════════════════════════════════════════
local configCloseHooked = false

local function HookConfigClose()
	if configCloseHooked then return end

	local ACD = E.Libs.AceConfigDialog
	if not ACD or not ACD.OpenFrames then return end

	local configFrame = ACD.OpenFrames.ElvUI
	if not configFrame or not configFrame.frame then return end

	configCloseHooked = true
	configFrame.frame:HookScript('OnHide', function()
		HideBlizzardCDMSettings()
		HidePreview()
	end)
end

C_Timer.After(0, function()
	hooksecurefunc(E, 'ToggleOptions', function(_, msg)
		-- Open Blizzard CDM settings + preview when right-clicking a CDM mover
		if msg == CDM_CONFIG_STRING then
			C_Timer.After(0.3, function()
				ShowBlizzardCDMSettings()
				ShowPreview()
			end)
		end

		-- Hook config frame close (ESC) — frame may not exist on first call
		if not configCloseHooked then
			C_Timer.After(0.1, HookConfigClose)
		end
	end)
end)
