-- TrenchyUI/Core/Integrations.lua
local AddonName, NS = ...
local _G = _G

local function GetE()
  local engine = _G and rawget(_G, 'ElvUI')
  if engine and engine[1] then return engine[1] end
  return NS and NS.E
end

-- Ensure namespace tables
NS.Integrations = NS.Integrations or {}
local I = NS.Integrations

-- Persistent settings (stored in E.global)
local function DB()
  local E = GetE()
  if not E then return nil end
  E.global.TrenchyUI = E.global.TrenchyUI or {}
  E.global.TrenchyUI.integrations = E.global.TrenchyUI.integrations or {}
  local db = E.global.TrenchyUI.integrations
  db.wd = db.wd or { enabled = true, applyTimers = true, applyForces = true, textureName = nil, fontName = nil }
  db.occd = db.occd or { gapEnabled = true, gapX = 0, customClassColorsEnabled = true }
  return db
end

-- LibSharedMedia helper
local function LSM()
  local E = GetE()
  return E and E.Libs and E.Libs.LSM
end

-- ========================= WarpDeplete: Class Colors =========================
I.WD = I.WD or {}
local WD = I.WD

function WD:GetClassColorRGB()
  local classFile = select(2, UnitClass('player'))
  local ccc = _G and rawget(_G, 'CUSTOM_CLASS_COLORS') or nil
  local rcc = _G and rawget(_G, 'RAID_CLASS_COLORS') or nil
  local tbl = (ccc and ccc[classFile]) or (rcc and rcc[classFile])
  if tbl then return tbl.r, tbl.g, tbl.b end
  return 1, 1, 1
end

function WD:ApplyOverrides()
  local cfgDB = DB(); if not cfgDB then return end
  local cfg = cfgDB.wd
  if not (cfg and cfg.enabled) then return end
  local WDAddOn = _G and rawget(_G, 'WarpDeplete')
  if not WDAddOn then return end
  local r, g, b = self:GetClassColorRGB()
  local bars = WDAddOn and WDAddOn.bars or nil
  local forces = WDAddOn and WDAddOn.forces or nil

  local lsm = LSM()
  local texPath = (lsm and cfg.textureName) and lsm:Fetch('statusbar', cfg.textureName) or nil
  local fontPath = (lsm and cfg.fontName) and lsm:Fetch('font', cfg.fontName) or nil

  -- Timers
  if bars and cfg.applyTimers then
    for i = 1, 3 do
      local bar = bars[i]
      if bar and bar.bar then
        if texPath then bar.bar:SetStatusBarTexture(texPath) end
        bar.bar:SetStatusBarColor(r, g, b, 1)
      end
      if fontPath and bar and bar.text then
        local _, size, flags = bar.text:GetFont()
        bar.text:SetFont(fontPath, size or 12, flags)
      end
    end
  end

  -- Forces
  if forces and cfg.applyForces then
    if forces.bar then
      if texPath then forces.bar:SetStatusBarTexture(texPath) end
      forces.bar:SetStatusBarColor(r, g, b, 1)
    end
    if forces.overlayBar then
      if texPath then forces.overlayBar:SetStatusBarTexture(texPath) end
      forces.overlayBar:SetStatusBarColor(r, g, b, 0.7)
    end
    if fontPath and forces.text then
      local _, size, flags = forces.text:GetFont()
      forces.text:SetFont(fontPath, size or 12, flags)
    end
  end
end

function WD:ApplyWhenReady(tries)
  tries = (tries or 0) + 1
  local WDAddOn = _G and rawget(_G, 'WarpDeplete')
  if WDAddOn and (WDAddOn.bars or WDAddOn.forces) then
    self:ApplyOverrides(); return
  end
  if tries < 50 and C_Timer and C_Timer.After then
    C_Timer.After(0.2, function() WD:ApplyWhenReady(tries) end)
  end
end

local wdHooked = false
function WD:Hook()
  if wdHooked then return end
  local WDAddOn = _G and rawget(_G, 'WarpDeplete')
  if not WDAddOn then return end
  wdHooked = true
  hooksecurefunc(WDAddOn, 'RenderLayout', function()
    if C_Timer and C_Timer.After then C_Timer.After(0, function() WD:ApplyOverrides() end) else WD:ApplyOverrides() end
  end)
  hooksecurefunc(WDAddOn, 'RenderForces', function()
    if C_Timer and C_Timer.After then C_Timer.After(0, function() WD:ApplyOverrides() end) else WD:ApplyOverrides() end
  end)
  hooksecurefunc(WDAddOn, 'OnProfileChanged', function()
    if C_Timer and C_Timer.After then C_Timer.After(0, function() WD:ApplyOverrides() end) else WD:ApplyOverrides() end
  end)
  -- Ensure first-time apply even if bars spawn a bit later
  self:ApplyWhenReady(0)
end

-- ========================= OmniCD: Custom Colors/Gap =========================
I.OCCD = I.OCCD or {}
local OCCD = I.OCCD
local pendingReanchors = {}
local hookedIconGap

function OCCD:CopyCustomToRaid()
  local ccc = _G and rawget(_G, 'CUSTOM_CLASS_COLORS')
  local rcc = _G and rawget(_G, 'RAID_CLASS_COLORS')
  if not (ccc and rcc) then return end
  for class, c in pairs(ccc) do
    local dest = rcc[class]
    if dest then dest.r, dest.g, dest.b = c.r, c.g, c.b end
  end
end

function OCCD:RefreshOmniCD(tries)
  tries = (tries or 0) + 1
  local Omni = _G and rawget(_G, 'OmniCD')
  local E = Omni and Omni[1]
  local P = E and E.Party
  if E and E.isEnabled and P and P.enabled and P.ExBarPool and P.UpdateAllBars then
    P:UpdateAllBars(); return
  end
  if tries < 50 and C_Timer and C_Timer.After then
    C_Timer.After(0.2, function() OCCD:RefreshOmniCD(tries) end)
  end
end

function OCCD:EnsureSBLeftBorder(sb, show)
  local Omni = _G and rawget(_G, 'OmniCD')
  local E = Omni and Omni[1]
  if not sb or not E then return end
  local exdb = E.db and sb.key and E.db.extraBars and E.db.extraBars[sb.key]
  if exdb and exdb.hideBorder then show = false end
  local edgeSize = (E.PixelMult and E.PixelMult > 0 and E.PixelMult) or 1
  local color = E.db and E.db.icons and E.db.icons.borderColor
  local r, g, b = 1, 1, 1
  if color then r, g, b = color.r or 1, color.g or 1, color.b or 1 end
  if not sb.borderLeft then
    local t = sb:CreateTexture(nil, 'BORDER')
    t:SetTexelSnappingBias(0.0)
    t:SetSnapToPixelGrid(false)
    sb.borderLeft = t
  end
  sb.borderLeft:ClearAllPoints()
  sb.borderLeft:SetPoint('TOPLEFT', sb, 'TOPLEFT')
  sb.borderLeft:SetPoint('BOTTOMRIGHT', sb, 'BOTTOMLEFT', edgeSize, 0)
  sb.borderLeft:SetColorTexture(r, g, b)
  if show then sb.borderLeft:Show() else sb.borderLeft:Hide() end
end

function OCCD:ReanchorStatusBar(icon, sb)
  local cfgDB = DB(); if not cfgDB then return end
  local cfg = cfgDB.occd
  if not icon or not sb or type(sb.ClearAllPoints) ~= 'function' or type(sb.SetPoint) ~= 'function' then return end
  if cfg.gapEnabled and cfg.gapX and cfg.gapX ~= 0 then
    sb:ClearAllPoints()
    sb:SetPoint('TOPLEFT', icon, 'TOPRIGHT', cfg.gapX, 0)
    sb:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', cfg.gapX, 0)
    self:EnsureSBLeftBorder(sb, true)
  else
    sb:ClearAllPoints()
    sb:SetPoint('TOPLEFT', icon, 'TOPRIGHT', 0, 0)
    sb:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', 0, 0)
    self:EnsureSBLeftBorder(sb, false)
  end
end

local function isFromPool(sb, P)
  if not P or not P.StatusBarPool or not sb then return false end
  for x in P.StatusBarPool:EnumerateActive() do if x == sb then return true end end
  return false
end

local function queueOrApply(icon, sb, P)
  if not sb or not icon then return end
  if not isFromPool(sb, P) then return end
  if InCombatLockdown and InCombatLockdown() then
    pendingReanchors[sb] = icon; return
  end
  if C_Timer and C_Timer.After then
    C_Timer.After(0, function() if isFromPool(sb, P) then OCCD:ReanchorStatusBar(icon, sb) end end)
  else
    OCCD:ReanchorStatusBar(icon, sb)
  end
end

function OCCD:EnsureIconOffsetHook()
  local Omni = _G and rawget(_G, 'OmniCD')
  local E = Omni and Omni[1]
  local P = E and E.Party
  if not E or not P or not P.StatusBarPool then return end
  if not hookedIconGap then
    hookedIconGap = true
    hooksecurefunc(P, 'GetStatusBarFrame', function(_, icon)
      if icon and icon.statusBar then queueOrApply(icon, icon.statusBar, P) end
    end)
  end
  -- Reanchor all current
  for sb in P.StatusBarPool:EnumerateActive() do
    local icon = sb.parent or (type(sb.GetParent) == 'function' and sb:GetParent()) or nil
    if icon then queueOrApply(icon, sb, P) end
  end
end

function OCCD:ApplyNow()
  local cfgDB = DB(); if cfgDB and cfgDB.occd and cfgDB.occd.customClassColorsEnabled ~= false then
    self:CopyCustomToRaid()
  end
  self:EnsureIconOffsetHook()
  self:RefreshOmniCD(0)
end

-- ========================= Init & Events =========================
function NS.SetupIntegrations()
  local cfgDB = DB(); if not cfgDB then return end

  local f = CreateFrame('Frame')
  f:RegisterEvent('ADDON_LOADED')
  f:RegisterEvent('PLAYER_LOGIN')
  f:RegisterEvent('PLAYER_REGEN_ENABLED')
  f:SetScript('OnEvent', function(_, event, arg1)
    if event == 'ADDON_LOADED' then
      if arg1 == 'WarpDeplete' then
        WD:Hook(); WD:ApplyWhenReady(0)
      elseif arg1 == 'OmniCD' then
        OCCD:ApplyNow()
      end
    elseif event == 'PLAYER_LOGIN' then
      WD:Hook(); WD:ApplyWhenReady(0)
      OCCD:ApplyNow()
    elseif event == 'PLAYER_REGEN_ENABLED' then
  local Omni = _G and rawget(_G, 'OmniCD')
  local E = Omni and Omni[1]
  local P = E and E.Party
      if E and P and P.StatusBarPool then
        for sb, icon in pairs(pendingReanchors) do
          local inPool = false
          for x in P.StatusBarPool:EnumerateActive() do if x == sb then inPool = true; break end end
          if inPool then OCCD:ReanchorStatusBar(icon, sb) end
          pendingReanchors[sb] = nil
        end
      else
        for k in pairs(pendingReanchors) do pendingReanchors[k] = nil end
      end
    end
  end)
end
