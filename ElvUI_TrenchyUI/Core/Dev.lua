local E = unpack(ElvUI)
local ElvUI_TrenchyUI = E:GetModule('ElvUI_TrenchyUI')

-- Inline, minimal WarpDeplete color override
local function WD_GetClassRGB()
	if InCombatLockdown() then return end
	local classFile = select(2, UnitClass('player'))
	local ccc = _G and rawget(_G, 'CUSTOM_CLASS_COLORS') or nil
	local rcc = _G and rawget(_G, 'RAID_CLASS_COLORS') or nil
	local tbl = (ccc and ccc[classFile]) or (rcc and rcc[classFile])
	if tbl then return tbl.r, tbl.g, tbl.b end
	return 1, 1, 1
end

function ElvUI_TrenchyUI:WarpDeplete_ApplyClassColors()
	local cfg = E.db and E.db.ElvUI_TrenchyUI and E.db.ElvUI_TrenchyUI.warpdeplete
	if not (cfg and cfg.forceClassColors) then return end
	local WD = _G and rawget(_G, 'WarpDeplete'); if not WD then return end
	local r, g2, b = WD_GetClassRGB()
	local bars = WD and WD.bars
	local forces = WD and WD.forces
	if type(bars) == 'table' then
		for i = 1, 3 do
			local bar = bars[i]
			if bar and bar.bar and bar.bar.SetStatusBarColor then
				bar.bar:SetStatusBarColor(r, g2, b, 1)
			end
		end
	end
	if type(forces) == 'table' then
		if forces.bar and forces.bar.SetStatusBarColor then forces.bar:SetStatusBarColor(r, g2, b, 1) end
		if forces.overlayBar and forces.overlayBar.SetStatusBarColor then forces.overlayBar:SetStatusBarColor(r, g2, b, 0.7) end
	end
end

-- Events to keep colors applied
local ev = false
local function ensureWDHooks()
	local WD = _G and rawget(_G, 'WarpDeplete'); if not WD then return end
	if not ev then
		ev = true
		if type(WD.RenderLayout) == 'function' then hooksecurefunc(WD, 'RenderLayout', function() ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors(true) end) end
		if type(WD.RenderForces) == 'function' then hooksecurefunc(WD, 'RenderForces', function() ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors(true) end) end
		if type(WD.OnProfileChanged) == 'function' then hooksecurefunc(WD, 'OnProfileChanged', function() ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors(true) end) end
		for _, fname in ipairs({ 'StartDemo', 'StopDemo', 'ToggleDemo' }) do
			local fn = WD[fname]
			if type(fn) == 'function' then hooksecurefunc(WD, fname, function() ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors(true) end) end
		end
	end
end

local init = CreateFrame('Frame')
init:RegisterEvent('PLAYER_LOGIN')
init:RegisterEvent('ADDON_LOADED')
init:SetScript('OnEvent', function(_, evt, arg1)
	if evt == 'PLAYER_LOGIN' then
		ensureWDHooks()
		ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors(false)
	elseif evt == 'ADDON_LOADED' and arg1 == 'WarpDeplete' then
		ensureWDHooks()
		ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors(false)
	end
end)

-- Re-apply when CUSTOM_CLASS_COLORS change (prefer these over RAID_CLASS_COLORS)
do
	local function tryRegisterCCC()
		if InCombatLockdown() then return end
		local CCC = _G and rawget(_G, 'CUSTOM_CLASS_COLORS')
		if CCC and CCC.RegisterCallback and not ElvUI_TrenchyUI.__WD_CCC_CB then
			ElvUI_TrenchyUI.__WD_CCC_CB = true
			CCC:RegisterCallback(function()
				if ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors then ElvUI_TrenchyUI.WarpDeplete_ApplyClassColors(true) end
			end, 'TrenchyUI_WD')
		end
	end
	tryRegisterCCC()
	if _G and _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(1, tryRegisterCCC) end
end

-- ================= OmniCD inline extras (class colors + padding) =================
local TUI_OmniCD_pending = {}
local TUI_OmniCD_backup

local function TUI_OmniCD_CopyCustomToRaid()
	if InCombatLockdown() then return end
	local ccc = _G and rawget(_G, 'CUSTOM_CLASS_COLORS')
	local rcc = _G and rawget(_G, 'RAID_CLASS_COLORS')
	if not (ccc and rcc) then return end
	if not TUI_OmniCD_backup then
		TUI_OmniCD_backup = {}
		for class, c in pairs(rcc) do TUI_OmniCD_backup[class] = { r = c.r, g = c.g, b = c.b } end
	end
	for class, c in pairs(ccc) do
		local dest = rcc[class]
		if dest then dest.r, dest.g, dest.b = c.r, c.g, c.b end
	end
end

local function TUI_OmniCD_RestoreRaid()
	if InCombatLockdown() then return end
	local rcc = _G and rawget(_G, 'RAID_CLASS_COLORS')
	if not (rcc and TUI_OmniCD_backup) then return end
	for class, c in pairs(TUI_OmniCD_backup) do
		if rcc[class] then rcc[class].r, rcc[class].g, rcc[class].b = c.r, c.g, c.b end
	end
end

local function TUI_OmniCD_Reanchor(icon, sb)
	if not sb or not icon or type(sb.ClearAllPoints) ~= 'function' or type(sb.SetPoint) ~= 'function' then return end
	local cfg = E.db and E.db.ElvUI_TrenchyUI and E.db.ElvUI_TrenchyUI.omnicd
	local dx = (cfg and cfg.gapX) or 0
	sb:ClearAllPoints()
	sb:SetPoint('TOPLEFT', icon, 'TOPRIGHT', dx, 0)
	sb:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', dx, 0)
	-- ensure left border exists and matches OmniCD border color
	if ElvUI_TrenchyUI.TUI_OmniCD_UpdateLeftBorder then ElvUI_TrenchyUI.TUI_OmniCD_UpdateLeftBorder(icon, sb) end
end

local function TUI_OmniCD_isFromPool(sb, P)
	if not P or not P.StatusBarPool or not sb then return false end
	for x in P.StatusBarPool:EnumerateActive() do if x == sb then return true end end
	return false
end

local function TUI_OmniCD_queueOrApply(icon, sb, P)
	if not icon or not sb then return end
	if not TUI_OmniCD_isFromPool(sb, P) then return end
	if InCombatLockdown and InCombatLockdown() then TUI_OmniCD_pending[sb] = icon; return end
	if C_Timer and C_Timer.After then C_Timer.After(0, function() if TUI_OmniCD_isFromPool(sb, P) then TUI_OmniCD_Reanchor(icon, sb) end end) else TUI_OmniCD_Reanchor(icon, sb) end
end

local TUI_OmniCD_hooked
local function TUI_OmniCD_EnsureHook()
	local Omni = _G and rawget(_G, 'OmniCD')
	local OE = Omni and Omni[1]
	local P = OE and OE.Party
	if not OE or not P or not P.StatusBarPool then
		if C_Timer and C_Timer.After then C_Timer.After(0.25, TUI_OmniCD_EnsureHook) end
		return
	end
	if not TUI_OmniCD_hooked then
		TUI_OmniCD_hooked = true
		if type(P.GetStatusBarFrame) == 'function' then
			hooksecurefunc(P, 'GetStatusBarFrame', function(_, icon)
				if icon and icon.statusBar then TUI_OmniCD_queueOrApply(icon, icon.statusBar, P) end
			end)
		elseif type(P.UpdateAllBars) == 'function' then
			hooksecurefunc(P, 'UpdateAllBars', function()
				if not (P and P.StatusBarPool) then return end
				for sb in P.StatusBarPool:EnumerateActive() do
					local icon = sb and (sb.parent or (type(sb.GetParent) == 'function' and sb:GetParent()))
					if icon then TUI_OmniCD_queueOrApply(icon, sb, P) end
				end
			end)
		end
	end
	for sb in P.StatusBarPool:EnumerateActive() do
		local icon = sb and (sb.parent or (type(sb.GetParent) == 'function' and sb:GetParent())) or nil
		if icon then TUI_OmniCD_queueOrApply(icon, sb, P) end
	end
end

local function TUI_OmniCD_UpdateAll(tries)
	tries = (tries or 0) + 1
	local Omni = _G and rawget(_G, 'OmniCD')
	local OE = Omni and Omni[1]
	local P = OE and OE.Party
	if OE and OE.isEnabled and P and P.enabled and P.UpdateAllBars then P:UpdateAllBars(); return end
	if tries < 50 and C_Timer and C_Timer.After then C_Timer.After(0.2, function() TUI_OmniCD_UpdateAll(tries) end) end
end

function ElvUI_TrenchyUI:OmniCD_ApplyExtras(now)
	if InCombatLockdown() then return end
	local cfg = E.db and E.db.ElvUI_TrenchyUI and E.db.ElvUI_TrenchyUI.omnicd
	local forceCCC = cfg and cfg.forceCCC
	if forceCCC == false then
		TUI_OmniCD_RestoreRaid()
	else
		TUI_OmniCD_CopyCustomToRaid()
	end
	TUI_OmniCD_EnsureHook()
	TUI_OmniCD_UpdateAll(0)
end

-- Create/refresh a 1px left-edge border on the status bar matching OmniCD's border color
do
	local function getBorderColor(frame)
		if not frame then return 0,0,0,1 end
		-- Try frame backdrop border color
		if type(frame.GetBackdropBorderColor) == 'function' then
			local r,g,b,a = frame:GetBackdropBorderColor()
			if r then return r,g,b,a or 1 end
		end
		-- Try common border textures/frames
		for _, key in ipairs({ 'Border', 'border', 'IconBorder' }) do
			local obj = rawget(frame, key)
			if obj then
				if type(obj.GetVertexColor) == 'function' then
					local r,g,b,a = obj:GetVertexColor(); if r then return r,g,b,a or 1 end
				elseif type(obj.GetBackdropBorderColor) == 'function' then
					local r,g,b,a = obj:GetBackdropBorderColor(); if r then return r,g,b,a or 1 end
				end
			end
		end
		return 0,0,0,1
	end

	function ElvUI_TrenchyUI.TUI_OmniCD_UpdateLeftBorder(icon, sb)
		if not sb then return end
		local tex = sb.__TrenchyLeftBorder
		if not tex and type(sb.CreateTexture) == 'function' then
			tex = sb:CreateTexture(nil, 'OVERLAY', nil, 7)
			sb.__TrenchyLeftBorder = tex
			tex:ClearAllPoints()
			tex:SetPoint('TOPLEFT', sb, 'TOPLEFT', 0, 0)
			tex:SetPoint('BOTTOMLEFT', sb, 'BOTTOMLEFT', 0, 0)
			tex:SetWidth(1)
		end
		if tex then
			local r,g,b,a = getBorderColor(sb)
			if (r == 0 and g == 0 and b == 0) then
				-- fall back to icon's border if bar doesn't expose one
				r,g,b,a = getBorderColor(icon)
			end
			tex:SetColorTexture(r or 0, g or 0, b or 0, a or 1)
			tex:Show()
		end
	end
end

-- Events for OmniCD extras
local ocEv = CreateFrame('Frame')
ocEv:RegisterEvent('ADDON_LOADED')
ocEv:RegisterEvent('PLAYER_LOGIN')
ocEv:RegisterEvent('PLAYER_REGEN_ENABLED')
ocEv:SetScript('OnEvent', function(_, evt, arg1)
	if evt == 'ADDON_LOADED' and arg1 == 'OmniCD' then
		ElvUI_TrenchyUI.OmniCD_ApplyExtras(false)
	elseif evt == 'PLAYER_LOGIN' then
		ElvUI_TrenchyUI.OmniCD_ApplyExtras(false)
	elseif evt == 'PLAYER_REGEN_ENABLED' then
		local Omni = _G and rawget(_G, 'OmniCD')
		local OE = Omni and Omni[1]
		local P = OE and OE.Party
		if OE and P and P.StatusBarPool then
			for sb, icon in pairs(TUI_OmniCD_pending) do
				local inPool = false
				for x in P.StatusBarPool:EnumerateActive() do if x == sb then inPool = true; break end end
				if inPool then TUI_OmniCD_Reanchor(icon, sb) end
				TUI_OmniCD_pending[sb] = nil
			end
		else
			for k in pairs(TUI_OmniCD_pending) do TUI_OmniCD_pending[k] = nil end
		end
	end
end)
