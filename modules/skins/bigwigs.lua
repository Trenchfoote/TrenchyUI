local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local LSM = E.Libs.LSM or LibStub('LibSharedMedia-3.0')

local CreateFrame = CreateFrame
local ipairs = ipairs

local DEFAULTS_BARS = {
	texture      = 'BantoBar',
	fontName     = 'Fonts\\FRIZQT__.TTF',
	fontSize     = 10,
	outline      = 'NONE',
	normalHeight = 18,
}

local DEFAULTS_COLORS = {
	barColor      = { 0.25, 0.33, 0.68, 1 },
	barBackground = { 0.5, 0.5, 0.5, 0.3 },
	barText       = { 1, 1, 1, 1 },
	barTextShadow = { 0, 0, 0, 1 },
}

do -- BigWigs settings helpers
	local C_AddOns_LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
	local pluginsReady = false

	local function EnsurePluginsLoaded()
		if pluginsReady then return end
		if BigWigs and BigWigs.GetPlugin then
			local cp = BigWigs:GetPlugin('Colors', true)
			if cp and cp.GetColor then
				pluginsReady = true
				return
			end
		end
		C_AddOns_LoadAddOn('BigWigs_Core')
		C_AddOns_LoadAddOn('BigWigs_Plugins')
		if BigWigs and BigWigs.GetPlugin then
			pluginsReady = BigWigs:GetPlugin('Colors', true) ~= nil
		end
	end

	function TUI:GetBarSettings()
		local settings = {}
		EnsurePluginsLoaded()

		local barsDB
		if BigWigs and BigWigs.GetPlugin then
			local barsPlugin = BigWigs:GetPlugin('Bars', true)
			if barsPlugin and barsPlugin.db then barsDB = barsPlugin.db.profile end
		end

		barsDB = barsDB or {}
		settings.texture  = barsDB.texture      or DEFAULTS_BARS.texture
		settings.fontName = barsDB.fontName     or DEFAULTS_BARS.fontName
		settings.fontSize = barsDB.fontSize     or DEFAULTS_BARS.fontSize
		settings.outline  = barsDB.outline      or DEFAULTS_BARS.outline
		settings.height   = barsDB.normalHeight or DEFAULTS_BARS.normalHeight

		if BigWigs and BigWigs.GetPlugin then
			local colorsPlugin = BigWigs:GetPlugin('Colors', true)
			if colorsPlugin and colorsPlugin.GetColor then
				local r, g, b, a = colorsPlugin:GetColor('barColor')
				settings.barColor = { r, g, b, a }
				r, g, b, a = colorsPlugin:GetColor('barBackground')
				settings.barBg = { r, g, b, a }
				r, g, b, a = colorsPlugin:GetColor('barText')
				settings.barText = { r, g, b, a }
				r, g, b, a = colorsPlugin:GetColor('barTextShadow')
				settings.barTextShadow = { r, g, b, a }
				return settings
			end
		end

		settings.barColor      = DEFAULTS_COLORS.barColor
		settings.barBg         = DEFAULTS_COLORS.barBackground
		settings.barText       = DEFAULTS_COLORS.barText
		settings.barTextShadow = DEFAULTS_COLORS.barTextShadow
		return settings
	end
end

do -- LFG Timer Skin
	local timerBarRef

	local function ApplyLFGSkin()
		if not timerBarRef then return end

		local s = TUI:GetBarSettings()
		local popupWidth = LFGDungeonReadyPopup and LFGDungeonReadyPopup:GetWidth()
		if not popupWidth or popupWidth < 50 then popupWidth = 303 end

		timerBarRef:SetSize(popupWidth, s.height)
		timerBarRef:ClearAllPoints()
		timerBarRef:SetPoint('TOP', LFGDungeonReadyPopup, 'BOTTOM', 0, -3)

		local texturePath = LSM:Fetch('statusbar', s.texture) or LSM:Fetch('statusbar', DEFAULTS_BARS.texture)
		timerBarRef:SetStatusBarTexture(texturePath)
		timerBarRef:SetStatusBarColor(s.barColor[1], s.barColor[2], s.barColor[3], s.barColor[4] or 1)

		local regions = { timerBarRef:GetRegions() }
		local cr, cg, cb = TUI:GetClassColor()
		for _, region in ipairs(regions) do
			if region:IsObjectType('Texture') and region:GetDrawLayer() == 'BACKGROUND' then
				region:SetTexture(texturePath)
				if cr then
					region:SetVertexColor(cr, cg, cb, 1)
				else
					region:SetVertexColor(s.barBg[1], s.barBg[2], s.barBg[3], s.barBg[4] or 1)
				end
			elseif region:IsObjectType('Texture') and region:GetDrawLayer() == 'OVERLAY' then
				region:Hide()
			end
		end

		if timerBarRef.text then
			local fontPath = LSM:Fetch('font', s.fontName) or s.fontName
			local flags = (s.outline and s.outline ~= 'NONE') and s.outline or ''
			timerBarRef.text:SetFont(fontPath, s.fontSize, flags) -- raw SetFont: BigWigs applies its own shadow
			timerBarRef.text:SetTextColor(s.barText[1], s.barText[2], s.barText[3], s.barText[4] or 1)
			if s.barTextShadow then
				timerBarRef.text:SetShadowColor(s.barTextShadow[1], s.barTextShadow[2], s.barTextShadow[3], s.barTextShadow[4] or 1)
			end
		end

		if not timerBarRef.borderFrame then
			local bf = CreateFrame('Frame', nil, timerBarRef, BackdropTemplateMixin and 'BackdropTemplate')
			bf:SetPoint('TOPLEFT', timerBarRef, 'TOPLEFT', 0, 1)
			bf:SetPoint('BOTTOMRIGHT', timerBarRef, 'BOTTOMRIGHT', 0, -1)
			bf:SetFrameLevel(timerBarRef:GetFrameLevel() + 1)
			bf:SetBackdrop({ edgeFile = E.media.blankTex, edgeSize = 1 })
			bf:SetBackdropBorderColor(0, 0, 0, 1)
			timerBarRef.borderFrame = bf
		end
		timerBarRef.borderFrame:Show()
	end

	function TUI:InitLFGTimerSkin()
		BigWigsLoader.RegisterMessage({}, 'BigWigs_FrameCreated', function(_, frame, name)
			if name == 'QueueTimer' then
				timerBarRef = frame
				ApplyLFGSkin()
			end
		end)

		local eventFrame = CreateFrame('Frame')
		eventFrame:RegisterEvent('LFG_PROPOSAL_SHOW')
		eventFrame:SetScript('OnEvent', function()
			C_Timer.After(0.05, ApplyLFGSkin)
		end)
	end
end

do -- Class-Coloured Bar Backgrounds
	local function ApplyClassColorBackground(bar)
		if not bar or not bar.candyBarBackground then return end
		local r, g, b = TUI:GetClassColor()
		if not r then return end
		bar.candyBarBackground:SetVertexColor(r, g, b, 1)
	end

	function TUI:InitBigWigsClassColorBars()
		BigWigsLoader.RegisterMessage({}, 'BigWigs_BarCreated', function(_, _, bar)
			ApplyClassColorBackground(bar)
		end)
		BigWigsLoader.RegisterMessage({}, 'BigWigs_BarEmphasized', function(_, _, bar)
			ApplyClassColorBackground(bar)
		end)
	end
end

function TUI:InitSkinBigWigs()
	if not BigWigsLoader then return end
	local db = self.db and self.db.profile and self.db.profile.addons
	if not db or not db.skinBigWigs then return end

	self:InitLFGTimerSkin()
	self:InitBigWigsClassColorBars()
end
