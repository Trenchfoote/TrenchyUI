local E = unpack(ElvUI)
local ElvUI_TrenchyUI = E:GetModule('ElvUI_TrenchyUI')

-- =====================================================================
-- OmniCd Custom Class Colors and Offset adjustment
-- =====================================================================

local function GetBorderRGB()
	local m = E and E.media and E.media.bordercolor
	if type(m) == 'table' then
		local r = m.r or m[1]
		local g = m.g or m[2]
		local b = m.b or m[3]
		if r and g and b then return r, g, b end
	end
	return 0, 0, 0
end

local function approx(a, b)
	return math.abs((a or 0) - (b or 0)) < 0.01
end

local function UseCCC()
	local cfg = E.db and E.db.ElvUI_TrenchyUI and E.db.ElvUI_TrenchyUI.omnicd
	return cfg and cfg.forceCCC
end

-- ---- coloring helpers ----
local function IconClass(icon)
	if not icon then return nil end
	if icon.class and type(icon.class) == "string" then return icon.class end
	if icon.guid and type(icon.guid) == "string" and GetPlayerInfoByGUID then
		local _, classFile = GetPlayerInfoByGUID(icon.guid)
		if classFile then return classFile end
	end
	if icon.unit and type(icon.unit) == "string" and UnitClass then
		local _, cf = UnitClass(icon.unit)
		if cf then return cf end
	end
	return nil
end

local function RecolorBar(sb, icon)
	if not (sb and icon) then return end
	if not UseCCC() then return end
	local classFile = IconClass(icon)
	if not classFile then return end
	local ccc = rawget(_G, 'CUSTOM_CLASS_COLORS')
	local rcc = rawget(_G, 'RAID_CLASS_COLORS')
	local cc = ccc and ccc[classFile]
	local rc = rcc and rcc[classFile]
	if not cc then return end
	local r, g, b = cc.r or 1, cc.g or 1, cc.b or 1
	local bar = (sb.CastingBar and sb.CastingBar.SetStatusBarColor) and sb.CastingBar or sb
	if bar then
		if bar.startCastColor and bar.startCastColor.SetRGB then bar.startCastColor:SetRGB(r, g, b) end
		if bar.startChannelColor and bar.startChannelColor.SetRGB then bar.startChannelColor:SetRGB(r, g, b) end
		if bar.startRechargeColor and bar.startRechargeColor.SetRGB then bar.startRechargeColor:SetRGB(r, g, b) end
		if bar.SetStatusBarColor then bar:SetStatusBarColor(r, g, b, 1) end
	end

	-- If Text/BG are using raid class colors, replace with custom
	if rc then
		if sb.Text and sb.Text.GetTextColor and sb.Text.SetTextColor then
			local tr, tg, tb = sb.Text:GetTextColor()
			if approx(tr, rc.r) and approx(tg, rc.g) and approx(tb, rc.b) then
				sb.Text:SetTextColor(r, g, b)
			end
		end
		if sb.BG and sb.BG.GetVertexColor and sb.BG.SetVertexColor then
			local br, bg, bb, ba = sb.BG:GetVertexColor()
			if approx(br, rc.r) and approx(bg, rc.g) and approx(bb, rc.b) then
				sb.BG:SetVertexColor(r, g, b, ba or 1)
			end
		end
	end
end

local function AttachBarHooks(sb, icon)
	if not sb then return end
	if not sb.__tuiHookedColors then
		if type(hooksecurefunc) == 'function' and type(sb.SetColors) == 'function' then
			hooksecurefunc(sb, 'SetColors', function(self)
				RecolorBar(self, icon)
			end)
		end
		sb.__tuiHookedColors = true
	end
	-- Always recolor on Apply to handle toggle flips without waiting for SetColors
	RecolorBar(sb, icon)
end

-- forward declare so we can keep layout after coloring section
local Reanchor
local EnsureLeftEdge

local function Apply(icon, sb)
	if icon and sb then AttachBarHooks(sb, icon) end
	-- layout next, after coloring
	Reanchor(icon, sb)
end

-- ---- layout/offset ----
Reanchor = function(icon, sb)
	if not (icon and sb) then return end
	if InCombatLockdown and InCombatLockdown() then return end
	local parent = sb.GetParent and sb:GetParent()
	local target = (parent and parent ~= icon) and parent or sb
	if not (target and target.ClearAllPoints and target.SetPoint) then return end
	local cfg = E.db and E.db.ElvUI_TrenchyUI and E.db.ElvUI_TrenchyUI.omnicd
	local dx = (cfg and cfg.gapX) or 0
	target:ClearAllPoints()
	target:SetPoint('TOPLEFT', icon, 'TOPRIGHT', dx, 0)
	target:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', dx, 0)
	EnsureLeftEdge(sb, dx)
end

-- Draw a thin left-edge border on the status bar to visually close the seam
EnsureLeftEdge = function(sb, dx)
	if not sb then return end
	local edge = sb.__tuiLeftEdge
	if not edge then
		edge = sb:CreateTexture(nil, 'OVERLAY', nil, 7)
		sb.__tuiLeftEdge = edge
	end
	if not dx or dx <= 0 then edge:Hide(); return end
	local r, g, b = GetBorderRGB()
	local thickness = (E and E.mult) or 1
	edge:ClearAllPoints()
	edge:SetColorTexture(r, g, b, 1)
	edge:SetPoint('TOPLEFT', sb, 'TOPLEFT', 0, 0)
	edge:SetPoint('BOTTOMLEFT', sb, 'BOTTOMLEFT', 0, 0)
	edge:SetWidth(thickness)
	edge:Show()
end

-- Pool sweeps (guard everything)
local function SweepStatusBars(P)
	if not P or not P.StatusBarPool then return end
	for sb in P.StatusBarPool:EnumerateActive() do
		local icon = sb and (sb.parent or (sb.GetParent and sb:GetParent()))
		if icon and not icon.class then
			local gp = icon.GetParent and icon:GetParent()
			if gp and gp.class then icon = gp end
		end
		if icon then Apply(icon, sb) end
	end
end

local function SweepExtraBars(P)
	if not P or not P.ExBarPool then return end
	for ex in P.ExBarPool:EnumerateActive() do
	local sb = ex and (ex.statusBar or ex.bar)
	local icon = ex and (ex.icon or ex.parent or (ex.GetParent and ex:GetParent()))
		if sb and icon then Apply(icon, sb) end
	end
end

-- Hooks
local hooked = false
local function EnsureHook()
	if hooked then return end
	local Omni = rawget(_G, 'OmniCD'); if not Omni then return end
	local OE = Omni[1]; if not OE then return end
	local P  = OE.Party; if not P then return end
	hooked = true

	if type(P.GetStatusBarFrame) == 'function' then
		hooksecurefunc(P, 'GetStatusBarFrame', function(_, icon)
			local sb = icon and icon.statusBar
			if sb then Apply(icon, sb) end
		end)
	end

	for _, fname in ipairs({ 'UpdateAllBars', 'UpdateExBars' }) do
		if type(P[fname]) == 'function' then
			hooksecurefunc(P, fname, function()
				SweepStatusBars(P)
				SweepExtraBars(P)
			end)
		end
	end

	SweepStatusBars(P)
	SweepExtraBars(P)
end

function ElvUI_TrenchyUI:OmniCD_ApplyExtras()
	EnsureHook()
	local Omni = rawget(_G, 'OmniCD'); if not Omni then return end
	local OE = Omni[1]; if not OE then return end
	local P  = OE.Party; if not P then return end
	SweepStatusBars(P)
	SweepExtraBars(P)
end

-- Public setters for Options.lua
function ElvUI_TrenchyUI:OmniCD_SetUseCCC(enabled)
	local cfg = E.db and E.db.ElvUI_TrenchyUI and E.db.ElvUI_TrenchyUI.omnicd
	if not cfg then return end
	cfg.forceCCC = not not enabled
	if self.OmniCD_ApplyExtras then self:OmniCD_ApplyExtras() end
	-- Nudge OmniCD to repaint now so SetColors runs and our post-hook recolors
	local Omni = rawget(_G, 'OmniCD')
	local OE = Omni and Omni[1]
	local P  = OE and OE.Party
	if P then
		if type(P.UpdateAllBars) == 'function' then pcall(P.UpdateAllBars, P) end
		if type(P.UpdateExBars) == 'function' then pcall(P.UpdateExBars, P) end
	end
end

function ElvUI_TrenchyUI:OmniCD_SetGap(dx)
	local cfg = E.db and E.db.ElvUI_TrenchyUI and E.db.ElvUI_TrenchyUI.omnicd
	if not cfg then return end
	local v = tonumber(dx)
	if v then cfg.gapX = v end
	if self.OmniCD_ApplyExtras then self:OmniCD_ApplyExtras() end
end

local f = CreateFrame('Frame')
f:RegisterEvent('ADDON_LOADED')
f:RegisterEvent('PLAYER_LOGIN')
f:SetScript('OnEvent', function(_, evt, arg1)
	if evt == 'PLAYER_LOGIN' or (evt == 'ADDON_LOADED' and (arg1 == 'OmniCD' or arg1 == 'ElvUI_TrenchyUI')) then
		if ElvUI_TrenchyUI and ElvUI_TrenchyUI.OmniCD_ApplyExtras then
			ElvUI_TrenchyUI:OmniCD_ApplyExtras()
		end
	end
end)

-- Re-apply when CUSTOM_CLASS_COLORS change or load later
do
	local function tryRegisterCCC(attempt)
		attempt = (attempt or 0) + 1
		local CCC = rawget(_G, 'CUSTOM_CLASS_COLORS')
		if CCC and CCC.RegisterCallback then
			CCC:RegisterCallback(function()
				if not UseCCC() then return end
				if ElvUI_TrenchyUI and ElvUI_TrenchyUI.OmniCD_ApplyExtras then
					ElvUI_TrenchyUI:OmniCD_ApplyExtras()
				end
			end, 'TrenchyUI_OmniCD')
		elseif C_Timer and C_Timer.After and attempt < 5 then
			C_Timer.After(1, function() tryRegisterCCC(attempt) end)
		end
	end
	tryRegisterCCC(0)
end


-- ===================================================================================================
-- WarpDeplete Custom Class Colors
-- ===================================================================================================

local function WD_GetClassRGB()
	local class = select(2, UnitClass("player"))
	local ccc = _G and rawget(_G, "CUSTOM_CLASS_COLORS")
	local rcc = _G and rawget(_G, "RAID_CLASS_COLORS")
	local t = (ccc and ccc[class]) or (rcc and rcc[class])
	if t then return t.r, t.g, t.b end
	return 1, 1, 1
end

function ElvUI_TrenchyUI:WarpDeplete_ApplyClassColors()
	-- respect your toggle
	local cfg = E.db and E.db.ElvUI_TrenchyUI and E.db.ElvUI_TrenchyUI.warpdeplete
	if not (cfg and cfg.forceClassColors) then return end

	local WD = _G and rawget(_G, "WarpDeplete"); if not WD then return end
	local r, g, b = WD_GetClassRGB()

	-- Color main timer/segment/status bars
	local bars = WD.bars
	if type(bars) == "table" then
		for _, barObj in pairs(bars) do
			local sb = barObj and barObj.bar
			if sb and sb.SetStatusBarColor then
				sb:SetStatusBarColor(r, g, b, 1)
			end
		end
	end

	-- Color the enemy forces main bar, but NOT the current pull overlay
	local forces = WD.forces
	if type(forces) == "table" then
		if forces.bar and forces.bar.SetStatusBarColor then
			forces.bar:SetStatusBarColor(r, g, b, 1)  -- main forces bar
		end
		-- leave forces.overlayBar untouched (this is the "current pull" display)
	end
end

-- Keep colors applied whenever WD builds/updates its UI
local hooked
local function EnsureWDHooks()
	if hooked then return end
	local WD = _G and rawget(_G, "WarpDeplete"); if not WD then return end
	hooked = true
	local function repaint()
		if ElvUI_TrenchyUI and ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors then
			ElvUI_TrenchyUI:WarpDeplete_ApplyClassColors()
		end
	end
	for _, fname in ipairs({ "RenderLayout", "RenderForces", "OnProfileChanged" }) do
		if type(WD[fname]) == "function" then hooksecurefunc(WD, fname, repaint) end
	end
	-- first paint
	repaint()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, evt, arg1)
	if evt == "PLAYER_LOGIN" then
		EnsureWDHooks()
		if ElvUI_TrenchyUI and ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors then
			ElvUI_TrenchyUI:WarpDeplete_ApplyClassColors()
		end
	elseif evt == "ADDON_LOADED" and arg1 == "WarpDeplete" then
		EnsureWDHooks()
	end
end)
