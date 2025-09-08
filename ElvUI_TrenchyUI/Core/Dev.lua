local E = unpack(ElvUI)
local ElvUI_TrenchyUI = E:GetModule('ElvUI_TrenchyUI')
local UnitClass = UnitClass
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local InCombatLockdown = InCombatLockdown
local hooksecurefunc = hooksecurefunc

-- OmniCD


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
	return math.abs((a or 0) - (b or 0)) < 0.001
end

local function UseCCC()
	local cfg = E.db and E.db.ElvUI_TrenchyUI and E.db.ElvUI_TrenchyUI.omnicd
	return cfg and cfg.forceCCC
end

local function sameRGB(r1, g1, b1, r2, g2, b2)
	return approx(r1, r2) and approx(g1, g2) and approx(b1, b2)
end

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
	if not (E and E.ClassColor) then return end
	local c = E:ClassColor(classFile)
	if not c then return end
	local r, g, b = c.r, c.g, c.b

	local classColors = RAID_CLASS_COLORS
	local rc = classColors and classColors[classFile]
	if not rc then return end
	local rr, rg, rb = rc.r, rc.g, rc.b
	if sameRGB(r, g, b, rr, rg, rb) then return end

	local bar = (sb.CastingBar and sb.CastingBar.SetStatusBarColor) and sb.CastingBar or sb
	if bar then
		local obj
		obj = bar.startCastColor
		if obj and obj.GetRGB and obj.SetRGB then
			local cr, cg, cb = obj:GetRGB()
			if sameRGB(cr, cg, cb, rr, rg, rb) then obj:SetRGB(r, g, b) end
		end
		obj = bar.startChannelColor
		if obj and obj.GetRGB and obj.SetRGB then
			local cr, cg, cb = obj:GetRGB()
			if sameRGB(cr, cg, cb, rr, rg, rb) then obj:SetRGB(r, g, b) end
		end
		obj = bar.startRechargeColor
		if obj and obj.GetRGB and obj.SetRGB then
			local cr, cg, cb = obj:GetRGB()
			if sameRGB(cr, cg, cb, rr, rg, rb) then obj:SetRGB(r, g, b) end
		end
		if bar.GetStatusBarColor and bar.SetStatusBarColor then
			local cr, cg, cb = bar:GetStatusBarColor()
			if sameRGB(cr, cg, cb, rr, rg, rb) then bar:SetStatusBarColor(r, g, b, 1) end
		end
	end

	local text = sb.Text
	if text and text.GetTextColor and text.SetTextColor then
		local tr, tg, tb = text:GetTextColor()
		if sameRGB(tr, tg, tb, rr, rg, rb) then text:SetTextColor(r, g, b) end
	end
	local bg = sb.BG
	if bg and bg.GetVertexColor and bg.SetVertexColor then
		local br, bg2, bb, ba = bg:GetVertexColor()
		if sameRGB(br, bg2, bb, rr, rg, rb) then bg:SetVertexColor(r, g, b, ba or 1) end
	end
end

local function AttachBarHooks(sb, icon)
	if not sb then return end
	if not sb.__tuiHookedColors then
		if hooksecurefunc and sb.SetColors then
			hooksecurefunc(sb, 'SetColors', function(self)
				local owner = self.parent or (self.GetParent and self:GetParent())
				RecolorBar(self, owner)
			end)
		end
		sb.__tuiHookedColors = true
	end
	local owner = sb.parent or (sb.GetParent and sb:GetParent())
	RecolorBar(sb, owner)
end

local Reanchor
local EnsureLeftEdge

local function Apply(icon, sb)
	if icon and sb then AttachBarHooks(sb, icon) end
	Reanchor(icon, sb)
end

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

local hooked = false
local function EnsureHook()
	if hooked then return end
	local Omni = OmniCD; if not Omni then return end
	local OE = Omni[1]; if not OE then return end
	local P  = OE.Party; if not P then return end
	hooked = true

	if P.GetStatusBarFrame then
		hooksecurefunc(P, 'GetStatusBarFrame', function(_, icon)
			local sb = icon and icon.statusBar
			if sb then Apply(icon, sb) end
		end)
	end

	for _, fname in ipairs({ 'UpdateAllBars', 'UpdateExBars' }) do
		if P[fname] then
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
	local Omni = OmniCD; if not Omni then return end
	local OE = Omni[1]; if not OE then return end
	local P  = OE.Party; if not P then return end
	SweepStatusBars(P)
	SweepExtraBars(P)
end

function ElvUI_TrenchyUI:OmniCD_SetUseCCC(enabled)
	local cfg = E.db and E.db.ElvUI_TrenchyUI and E.db.ElvUI_TrenchyUI.omnicd
	if not cfg then return end
	cfg.forceCCC = not not enabled
	if self.OmniCD_ApplyExtras then self:OmniCD_ApplyExtras() end
	local Omni = OmniCD
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
-- WD

local function WD_Cfg()
    E.db.ElvUI_TrenchyUI = E.db.ElvUI_TrenchyUI or {}
    E.db.ElvUI_TrenchyUI.warpdeplete = E.db.ElvUI_TrenchyUI.warpdeplete or {}
    return E.db.ElvUI_TrenchyUI.warpdeplete
end

function ElvUI_TrenchyUI:WarpDeplete_ApplyClassColors()
    local cfg = WD_Cfg()
    if not cfg.forceClassColors then return end

	local WD = WarpDeplete; if not WD then return end
	local _, class = UnitClass("player")
	local c = (E and E.ClassColor and class) and E:ClassColor(class) or nil
	local r, g, b = c and c.r or 1, c and c.g or 1, c and c.b or 1

	for _, barObj in pairs(WD.bars or {}) do
		local sb = barObj and barObj.bar
		if sb and sb.SetStatusBarColor then sb:SetStatusBarColor(r, g, b, 1) end
	end

	local forces = WD.forces
	if forces and forces.bar and forces.bar.SetStatusBarColor then
		forces.bar:SetStatusBarColor(r, g, b, 1)
	end

end

function ElvUI_TrenchyUI:WarpDeplete_ClearOverride()
	local WD = WarpDeplete; if not WD then return end
	if WD.RenderLayout  then pcall(WD.RenderLayout, WD) end
	if WD.RenderForces  then pcall(WD.RenderForces, WD) end
	if WD.OnProfileChanged then pcall(WD.OnProfileChanged, WD) end

end

function ElvUI_TrenchyUI:WarpDeplete_SetUseClassColors(enabled)
    local cfg = WD_Cfg()
    cfg.forceClassColors = not not enabled
    if cfg.forceClassColors then
        self:WarpDeplete_ApplyClassColors()
    else
        self:WarpDeplete_ClearOverride()
    end

end

local WD_hooked
local function EnsureWDHooks()
    if WD_hooked then return end
	local WD = WarpDeplete; if not WD then return end
    WD_hooked = true
    local function repaint()
        if ElvUI_TrenchyUI and ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors then
            ElvUI_TrenchyUI:WarpDeplete_ApplyClassColors()
        end
    end
    for _, fname in ipairs({ "RenderLayout", "RenderForces", "OnProfileChanged" }) do
        if type(WD[fname]) == "function" then hooksecurefunc(WD, fname, repaint) end
    end
	repaint()
end

-- Now that all helpers are defined, register the unified event frame
local tuiEvt = CreateFrame('Frame')
tuiEvt:RegisterEvent('ADDON_LOADED')
tuiEvt:RegisterEvent('PLAYER_LOGIN')
tuiEvt:SetScript('OnEvent', function(_, evt, arg1)
	if evt == 'PLAYER_LOGIN' then
		if ElvUI_TrenchyUI and ElvUI_TrenchyUI.OmniCD_ApplyExtras then
			ElvUI_TrenchyUI:OmniCD_ApplyExtras()
		end
		local cfg = WD_Cfg()
		if cfg.forceClassColors == nil then cfg.forceClassColors = false end
		EnsureWDHooks()
		if ElvUI_TrenchyUI and ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors then
			ElvUI_TrenchyUI:WarpDeplete_ApplyClassColors()
		end
	elseif evt == 'ADDON_LOADED' then
		if arg1 == 'OmniCD' or arg1 == 'ElvUI_TrenchyUI' then
			if ElvUI_TrenchyUI and ElvUI_TrenchyUI.OmniCD_ApplyExtras then
				ElvUI_TrenchyUI:OmniCD_ApplyExtras()
			end
		elseif arg1 == 'WarpDeplete' then
			EnsureWDHooks()
		end
	end
end)
