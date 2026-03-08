local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local LCG = LibStub('LibCustomGlow-1.0', true)

local hooksecurefunc = hooksecurefunc
local pairs = pairs
local ipairs = ipairs
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
local pushing = false   -- guard to prevent re-entry when we trigger RefreshLayout
local hookedViewers = {}

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
	if not LCG then return end
	LCG.PixelGlow_Stop(itemFrame, 'TUI_CDM')
	LCG.AutoCastGlow_Stop(itemFrame, 'TUI_CDM')
	LCG.ButtonGlow_Stop(itemFrame)
	LCG.ProcGlow_Stop(itemFrame, 'TUI_CDM')
end

local function ApplyGlow(itemFrame)
	local db = GetDB()
	if not db or not db.enabled or not db.glow or not db.glow.enabled then return end
	if not LCG then return end

	local glowType = db.glow.type or 'pixel'
	local color = db.glow.color
	local c = color and { color.r, color.g, color.b, color.a or 1 } or { 0.95, 0.95, 0.32, 1 }

	local cooldown = itemFrame.Cooldown
	if not cooldown then return end

	local start = cooldown:GetCooldownTimes()
	if not start or start == 0 then
		StopGlow(itemFrame)
		return
	end

	if glowType == 'pixel' then
		LCG.PixelGlow_Start(itemFrame, c, db.glow.lines or 8, db.glow.speed or 0.25, db.glow.length, db.glow.thickness or 2, 0, 0, nil, 'TUI_CDM')
	elseif glowType == 'autocast' then
		LCG.AutoCastGlow_Start(itemFrame, c, db.glow.particles or 4, db.glow.speed or 0.25, db.glow.scale or 1, 0, 0, 'TUI_CDM')
	elseif glowType == 'button' then
		LCG.ButtonGlow_Start(itemFrame, c, db.glow.speed or 0.25)
	elseif glowType == 'proc' then
		LCG.ProcGlow_Start(itemFrame, {
			color = c,
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
-- CONTAINER CREATION
-- ═══════════════════════════════════════════════════════════════════
local function CreateContainer(viewerKey)
	local info = VIEWER_KEYS[viewerKey]
	local vdb = GetViewerDB(viewerKey)
	local iconW = vdb and vdb.iconWidth or 30
	local iconH = vdb and vdb.iconHeight or 30

	local frame = CreateFrame('Frame', info.mover .. 'Holder', E.UIParent)
	frame:SetSize(iconW * 8, iconH * 2) -- initial size, resized on layout
	frame:SetPoint('CENTER', E.UIParent, 'CENTER', 0, 0)
	frame:SetFrameStrata('MEDIUM')
	frame:SetFrameLevel(5)

	E:CreateMover(frame, info.mover .. 'Mover', 'TUI ' .. info.label)

	containers[viewerKey] = frame
	return frame
end

-- ═══════════════════════════════════════════════════════════════════
-- GRID LAYOUT — positions captured icons inside our container
-- Always centers rows horizontally. Growth direction configurable.
-- ═══════════════════════════════════════════════════════════════════
local function LayoutContainer(viewerKey)
	local container = containers[viewerKey]
	if not container then return end

	local db = GetDB()
	if not db or not db.enabled then return end

	local vdb = GetViewerDB(viewerKey)
	if not vdb then return end

	local iconW = vdb.iconWidth or 30
	local iconH = vdb.iconHeight or 30
	local spacing = vdb.spacing or 2
	local perRow = vdb.iconsPerRow or 12
	local growUp = (vdb.growthDirection == 'UP')

	-- Collect captured frames that are shown and belong to this viewer
	local icons = {}
	for _, child in ipairs({ container:GetChildren() }) do
		if child and child:IsShown() and child.layoutIndex then
			icons[#icons + 1] = child
		end
	end

	-- Also check for frames that should be here but weren't captured yet
	local viewer = GetViewer(viewerKey)
	if viewer then
		for _, child in ipairs({ viewer:GetChildren() }) do
			if child and child:IsShown() and child.layoutIndex and child:GetParent() ~= container then
				-- Capture this frame
				child:SetParent(container)
				child:SetScale(1)
				icons[#icons + 1] = child
			end
		end
	end

	table.sort(icons, function(a, b) return (a.layoutIndex or 0) < (b.layoutIndex or 0) end)

	local count = #icons
	if count == 0 then
		-- Keep a minimum size so the ElvUI mover stays visible/draggable
		local minW = perRow * iconW + (perRow - 1) * spacing
		container:SetSize(minW, iconH)
		return
	end

	-- Apply sizing, zoom, glow
	for _, icon in ipairs(icons) do
		icon:SetSize(iconW, iconH)
		ApplyIconZoom(icon, vdb.iconZoom)
		if db.glow and db.glow.enabled then
			ApplyGlow(icon)
		end
	end

	-- Calculate grid dimensions
	local cols = math_min(count, perRow)
	local rows = math_ceil(count / perRow)

	-- Resize container to fit the grid
	local totalW = cols * iconW + (cols - 1) * spacing
	local totalH = rows * iconH + (rows - 1) * spacing
	container:SetSize(totalW, totalH)

	-- Position each icon — centered per row
	for i, icon in ipairs(icons) do
		local row = math_floor((i - 1) / perRow)
		local col = (i - 1) % perRow

		-- How many icons in this row?
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
-- Called as a post-hook on RefreshLayout. CDM has finished its
-- layout; we immediately steal the frames into our container.
-- ═══════════════════════════════════════════════════════════════════
local function CaptureAndLayout(viewer, viewerKey)
	if pushing then return end

	local db = GetDB()
	if not db or not db.enabled then return end

	local container = containers[viewerKey]
	if not container then return end

	-- Reparent all visible item frames from the viewer to our container
	for _, child in ipairs({ viewer:GetChildren() }) do
		if child and child.layoutIndex then
			if child:GetParent() ~= container then
				child:SetParent(container)
				child:SetScale(1)
			end
		end
	end

	-- Hide the original viewer (it's now empty)
	viewer:SetAlpha(0)

	-- Run our grid layout
	LayoutContainer(viewerKey)
end

-- ═══════════════════════════════════════════════════════════════════
-- HOOK SETUP
-- ═══════════════════════════════════════════════════════════════════
local function HookViewer(viewerKey)
	local viewer = GetViewer(viewerKey)
	if not viewer or hookedViewers[viewerKey] then return end
	hookedViewers[viewerKey] = true

	-- Hook only RefreshLayout — safe post-hook position in CDM's call chain.
	-- NOT OnAcquireItemFrame (runs mid-data-refresh with ConditionalSecrets).
	hooksecurefunc(viewer, 'RefreshLayout', function(self)
		CaptureAndLayout(self, viewerKey)
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- EVENT-DRIVEN RE-LAYOUT
-- Icons already reparented to our container won't trigger RefreshLayout
-- when they show/hide (buff gained/lost). A debounced event listener
-- catches these changes and re-runs our grid layout.
-- ═══════════════════════════════════════════════════════════════════
local layoutPending = false

local function ScheduleRelayout()
	if layoutPending then return end
	layoutPending = true
	C_Timer.After(0, function()
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

	for viewerKey in pairs(VIEWER_KEYS) do
		LayoutContainer(viewerKey)
	end
end

function TUI:InitCooldownManager()
	local db = GetDB()
	if not db or not db.enabled then return end

	-- Defer to avoid taint during ElvUI's InitializeModules callstack
	C_Timer.After(0, function()
		-- Create containers with ElvUI movers
		for viewerKey in pairs(VIEWER_KEYS) do
			CreateContainer(viewerKey)
		end

		-- Hook CDM viewers
		for viewerKey in pairs(VIEWER_KEYS) do
			HookViewer(viewerKey)
		end

		-- Initial capture
		for viewerKey in pairs(VIEWER_KEYS) do
			local viewer = GetViewer(viewerKey)
			if viewer then
				CaptureAndLayout(viewer, viewerKey)
			end
		end

		-- Event-driven re-layout for dynamic icon show/hide (buffs gained/lost)
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
	if not C_AddOns.IsAddOnLoaded('Blizzard_CooldownViewer') then
		C_AddOns.LoadAddOn('Blizzard_CooldownViewer')
	end

	local settings = _G.CooldownViewerSettings
	if settings then
		settings:SetShown(not settings:IsShown())
	end

	E:ToggleOptions('TrenchyUI')
	C_Timer.After(0.1, function()
		local configGroup = E.Options and E.Options.args and E.Options.args.TrenchyUI
		if configGroup and configGroup.args and configGroup.args.cooldownManager then
			E.Libs.AceConfigDialog:SelectGroup('ElvUI', 'TrenchyUI', 'cooldownManager')
		end
	end)
end
