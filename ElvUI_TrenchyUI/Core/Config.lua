-- TrenchyUI/Core/Config.lua
local AddonName, NS = ...
local _G = _G

-- Branding (local to this module)
local BRAND_HEX = "ff2f3d"
local BRAND     = "|cff"..BRAND_HEX.."TrenchyUI|r"

-- Read addon metadata from TOC safely
local function GetTOCMetadata(field)
  local CA = _G and rawget(_G, 'C_AddOns')
  local v
  if CA and CA.GetAddOnMetadata then
    v = CA.GetAddOnMetadata(AddonName, field)
  else
    local get = _G and rawget(_G, 'GetAddOnMetadata')
    if type(get) == 'function' then v = get(AddonName, field) end
  end
  return v
end

-- Build the TrenchyUI options group
local function BuildOptions()
  local E = NS.E

  local function OpenInstaller()
    if NS.ShowInstaller then NS.ShowInstaller(true)
    else print(BRAND..": Installer not ready. Is ElvUI loaded?") end
  end

  -- Helpers used by option buttons
  local function ReinstallOnlyPlates()
    if not NS.ImportProfileStrings then print(BRAND..": Importer not available.") return end
    local only = NS.OnlyPlatesStrings
  if not only then print(BRAND..": No TrenchyUI export available.") return end
    local overrides = {
      profile = only.profile or "",
      private = only.private or "",
      global = only.global or "",
      aurafilters = only.aurafilters or "",
      nameplatefilters = "", -- keep Style Filters separate
    }
    local ok = NS.ImportProfileStrings(overrides)
    if ok and NS.OnlyPlates_PostImport then NS.OnlyPlates_PostImport() end
    if NS.ApplyUIScaleAfterImport and NS.UIScale then NS.ApplyUIScaleAfterImport(NS.UIScale) end
  print(BRAND..(ok and ": TrenchyUI layout reinstalled." or ": Failed to reinstall TrenchyUI layout."))
  end

  local function ReinstallUnnamed()
    print(BRAND..": Unnamed layout is currently WIP.")
  end

  local function ApplyExternal(name)
    if not NS.ExternalProfileAppliers then print(BRAND..": No external appliers registered.") return end
    for _, item in ipairs(NS.ExternalProfileAppliers) do
      if item.name == name then
        local ok, res = pcall(item.apply)
        print(BRAND..((ok and res ~= false) and (": Applied "..name.." profile.") or (": Failed applying "..name.." profile.")))
        return
      end
    end
    print(BRAND..": Profile applier for '"..name.."' not found.")
  end

  -- Version stamp for TrenchyUI Nameplate Style Filters
  local STYLE_VERSION = NS.StyleFiltersVersion or "TrenchyUI"

  local function ApplyOnlyPlatesStyleFilters()
    local ver = STYLE_VERSION or ""
    local ok = NS.ApplyOnlyPlatesStyleFilters and NS.ApplyOnlyPlatesStyleFilters() or false
  print(BRAND..(ok and (": TrenchyUI Style Filters applied ("..ver..")") or (": Failed to apply TrenchyUI Style Filters ("..ver..")")))
  end


  local groupArgs = {
    header  = { order = 1, type = "header", name = BRAND },
    desc    = {
      order = 2, type = "description",
      name  = function()
        local notes = GetTOCMetadata('Notes') or ""
        return notes .. "\n\n"
      end,
    },
    spacer1 = { order = 3, type = "description", name = " " },
    open    = {
      order = 4, type = "execute", width = "full",
      name  = BRAND.." – Open Installer",
      func  = OpenInstaller,
    },
    spacer2 = { order = 5, type = "description", name = " " },
    layoutsHeader = { order = 6, type = "header", name = "|cff"..BRAND_HEX.."Layouts|r" },
    reinstallOnly = {
      order = 7, type = "execute", width = "full",
      name = "Reinstall TrenchyUI Layout",
      func = ReinstallOnlyPlates,
    },
    reinstallUnnamed = {
      order = 8, type = "execute", width = "full",
      name = "Reinstall Unnamed Layout (WIP)",
      disabled = true,
      func = ReinstallUnnamed,
    },
    spacer3 = { order = 9, type = "description", name = " " },
    -- Move Style Filters above Other Addons
    styleHeader = { order = 9.1, type = "header", name = "|cff"..BRAND_HEX.."ElvUI Nameplate Style Filters|r" },
    applyOnlyPlatesStyle = {
      order = 9.2, type = "execute", width = "full",
      name = "Apply TrenchyUI Filters (|cff40ff40"..STYLE_VERSION.."|r)",
      func = ApplyOnlyPlatesStyleFilters,
    },
  -- compare/purge buttons removed per request
    addonsHeader = { order = 10, type = "header", name = "|cff"..BRAND_HEX.."Other Addons|r" },
  applyBigWigs = {
      order = 11, type = "execute", width = "full",
      name = "Apply BigWigs Profile",
      func = function() ApplyExternal('BigWigs') end,
    },
    applyDetails = {
      order = 12, type = "execute", width = "full",
      name = "Apply Details Profile",
      func = function() ApplyExternal('Details') end,
    },
    applyOmniCD = {
  order = 13, type = "execute", width = "full", hidden = true,
  name = "Apply OmniCD Profile",
  func = function() ApplyExternal('OmniCD') end,
    },
    applyWarpDeplete = {
  -- moved into Warp Deplete section below
  order = 14, type = "execute", hidden = true,
  name = "Apply WarpDeplete Profile",
  func = function() ApplyExternal('WarpDeplete') end,
    },
    applyAddOnSkins = {
      order = 15, type = "execute", width = "full",
      name = "Apply AddOnSkins Profile",
      func = function() ApplyExternal('AddOnSkins') end,
    },
    applyProjectAzilroka = {
      order = 16, type = "execute", width = "full",
      name = "Apply ProjectAzilroka Profile",
      func = function() ApplyExternal('ProjectAzilroka') end,
    },
  spacer4 = { order = 17, type = "description", name = " " },
  spacer5 = { order = 20, type = "description", name = " " },

    -- WarpDeplete: group profile button + class color toggle
    integrationsHeader = { order = 21, type = "header", name = "|cff"..BRAND_HEX.."Warp Deplete|r" },
    wdGroup = {
      order = 22, type = "group", inline = true, name = "",
      args = {
        wdApplyProfile = {
          order = 1, type = "execute", width = 1.4,
          name = "Apply WarpDeplete Profile",
          func = function() ApplyExternal('WarpDeplete') end,
        },
        wdSpacer = {
          order = 2, type = "description", name = " ",
          width = 0.3, -- approx. 50px gap; adjust 0.2-0.4 if needed
        },
        wdForceClass = {
          order = 3, type = "toggle", width = 1.2,
          name = "Force Class Colors",
          desc = "Override WarpDeplete bar colors with your class color (uses CUSTOM_CLASS_COLORS first).",
          get = function()
            local E = NS.E; if not E then return false end
            E.global.TrenchyUI = E.global.TrenchyUI or {}
            E.global.TrenchyUI.warpdeplete = E.global.TrenchyUI.warpdeplete or {}
            return E.global.TrenchyUI.warpdeplete.forceClassColors == true
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local g = E.global; g.TrenchyUI = g.TrenchyUI or {}; g.TrenchyUI.warpdeplete = g.TrenchyUI.warpdeplete or {}
            g.TrenchyUI.warpdeplete.forceClassColors = not not v
            if NS.WarpDeplete_ApplyClassColors then NS.WarpDeplete_ApplyClassColors(true) end
          end,
        },
      },
    },

    -- OmniCD: group with profile button + class colors toggle + padding slider
    ocHeader = { order = 23, type = "header", name = "|cff"..BRAND_HEX.."OmniCD|r" },
    ocGroup = {
      order = 24, type = "group", inline = true, name = "",
      args = {
        ocApplyProfile = {
          order = 1, type = "execute", width = 1.4,
          name = "Apply OmniCD Profile",
          func = function() ApplyExternal('OmniCD') end,
        },
        ocSpacer = { order = 2, type = "description", name = " ", width = 0.3 },
        ocUseCCC = {
          order = 3, type = "toggle", width = 1.5,
          name = "Use Custom Class Colors",
          desc = "Copy CUSTOM_CLASS_COLORS to RAID_CLASS_COLORS for OmniCD extra bars.",
          get = function()
            local E = NS.E; if not E then return true end
            E.global.TrenchyUI = E.global.TrenchyUI or {}
            E.global.TrenchyUI.omnicd = E.global.TrenchyUI.omnicd or {}
            local v = E.global.TrenchyUI.omnicd.forceCCC
            if v == nil then return true end
            return v
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local g = E.global; g.TrenchyUI = g.TrenchyUI or {}; g.TrenchyUI.omnicd = g.TrenchyUI.omnicd or {}
            g.TrenchyUI.omnicd.forceCCC = not not v
            if NS.OmniCD_ApplyExtras then NS.OmniCD_ApplyExtras(true) end
          end,
        },
        ocGap = {
          order = 4, type = "range", width = 1.2,
          name = "Padding X",
          min = 0, max = 40, step = 1,
          get = function()
            local E = NS.E; if not E then return 0 end
            local db = E.global.TrenchyUI and E.global.TrenchyUI.omnicd or nil
            return (db and db.gapX) or 0
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local g = E.global; g.TrenchyUI = g.TrenchyUI or {}; g.TrenchyUI.omnicd = g.TrenchyUI.omnicd or {}
            g.TrenchyUI.omnicd.gapX = math.floor(tonumber(v) or 0)
            if NS.OmniCD_ApplyExtras then NS.OmniCD_ApplyExtras(true) end
          end,
        },
      }
    },
  }

  return {
    order = 50,
    type  = "group",
    name  = BRAND,
    args  = groupArgs,
  }, groupArgs
end

-- Public: insert the options into ElvUI
function NS.InsertOptions()
  local engine = _G and rawget(_G, "ElvUI")
  if engine and engine[1] then NS.E = engine[1] end
  local E = NS.E
  if not (E and E.Options and E.Options.args) then return end

  -- Match Luckyone's approach: brand the ElvUI options window title itself
  do
    local current = E.Options.name or "ElvUI"
    if not string.find(current, "TrenchyUI", 1, true) then
      local version = GetTOCMetadata('Version') or ""
      local stamp = version ~= "" and (" |cff40ff40v"..version.."|r") or ""
      E.Options.name = string.format("%s + %s%s", current, BRAND, stamp)
    end
  end

  local pluginGroup, sharedArgs = BuildOptions()

  -- Under Plugins category (if present)
  if E.Options.args.plugins and E.Options.args.plugins.args then
    E.Options.args.plugins.args.trenchyui = pluginGroup
  end

  -- Also add a top-level entry
  local function deepCopy(tbl)
    local out = {}
    for k, v in pairs(tbl) do
      out[k] = (type(v) == 'table') and deepCopy(v) or v
    end
    return out
  end
  local topArgs = deepCopy(sharedArgs)
  E.Options.args.trenchyui = {
    order = 95, type = "group", name = BRAND, args = topArgs
  }
end

-- Inline, minimal WarpDeplete color override
local function WD_GetClassRGB()
  local classFile = select(2, UnitClass('player'))
  local ccc = _G and rawget(_G, 'CUSTOM_CLASS_COLORS') or nil
  local rcc = _G and rawget(_G, 'RAID_CLASS_COLORS') or nil
  local tbl = (ccc and ccc[classFile]) or (rcc and rcc[classFile])
  if tbl then return tbl.r, tbl.g, tbl.b end
  return 1, 1, 1
end

local function WD_Colorize()
  local E = NS.E; if not E then return end
  local g = E.global; if not g then return end
  local cfg = g.TrenchyUI and g.TrenchyUI.warpdeplete
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

-- Public: apply now or when ready
function NS.WarpDeplete_ApplyClassColors(now)
  local function doApply()
    if C_Timer and C_Timer.After then C_Timer.After(0, WD_Colorize) else WD_Colorize() end
  end
  if now then doApply(); return end
  local tries = 0
  local function wait()
    tries = tries + 1
    local WD = _G and rawget(_G, 'WarpDeplete')
    if WD and (WD.bars or WD.forces) then doApply(); return end
    if tries < 50 and C_Timer and C_Timer.After then C_Timer.After(0.2, wait) end
  end
  wait()
end

-- Events to keep colors applied
local ev
local function ensureWDHooks()
  local WD = _G and rawget(_G, 'WarpDeplete'); if not WD then return end
  if ev and ev.hooked then return end
  ev = ev or CreateFrame('Frame')
  if not ev.hooked then
    ev.hooked = true
    if type(WD.RenderLayout) == 'function' then hooksecurefunc(WD, 'RenderLayout', function() NS.WarpDeplete_ApplyClassColors(true) end) end
    if type(WD.RenderForces) == 'function' then hooksecurefunc(WD, 'RenderForces', function() NS.WarpDeplete_ApplyClassColors(true) end) end
    if type(WD.OnProfileChanged) == 'function' then hooksecurefunc(WD, 'OnProfileChanged', function() NS.WarpDeplete_ApplyClassColors(true) end) end
    for _, fname in ipairs({ 'StartDemo', 'StopDemo', 'ToggleDemo' }) do
      local fn = WD[fname]
      if type(fn) == 'function' then hooksecurefunc(WD, fname, function() NS.WarpDeplete_ApplyClassColors(true) end) end
    end
  end
end

local init = CreateFrame('Frame')
init:RegisterEvent('PLAYER_LOGIN')
init:RegisterEvent('ADDON_LOADED')
init:SetScript('OnEvent', function(_, evt, arg1)
  if evt == 'PLAYER_LOGIN' then
    ensureWDHooks()
    NS.WarpDeplete_ApplyClassColors(false)
  elseif evt == 'ADDON_LOADED' and arg1 == 'WarpDeplete' then
    ensureWDHooks()
    NS.WarpDeplete_ApplyClassColors(false)
  end
end)

-- Re-apply when CUSTOM_CLASS_COLORS change (prefer these over RAID_CLASS_COLORS)
do
  local function tryRegisterCCC()
    local CCC = _G and rawget(_G, 'CUSTOM_CLASS_COLORS')
    if CCC and CCC.RegisterCallback and not NS.__WD_CCC_CB then
      NS.__WD_CCC_CB = true
      CCC:RegisterCallback(function()
        if NS.WarpDeplete_ApplyClassColors then NS.WarpDeplete_ApplyClassColors(true) end
      end, 'TrenchyUI_WD')
    end
  end
  tryRegisterCCC()
  if _G and _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(1, tryRegisterCCC) end
end

-- ================= OmniCD inline extras (class colors + padding) =================
local OCCD_pending = {}
local OCCD_backup

local function OCCD_CopyCustomToRaid()
  local ccc = _G and rawget(_G, 'CUSTOM_CLASS_COLORS')
  local rcc = _G and rawget(_G, 'RAID_CLASS_COLORS')
  if not (ccc and rcc) then return end
  if not OCCD_backup then
    OCCD_backup = {}
    for class, c in pairs(rcc) do OCCD_backup[class] = { r = c.r, g = c.g, b = c.b } end
  end
  for class, c in pairs(ccc) do
    local dest = rcc[class]
    if dest then dest.r, dest.g, dest.b = c.r, c.g, c.b end
  end
end

local function OCCD_RestoreRaid()
  local rcc = _G and rawget(_G, 'RAID_CLASS_COLORS')
  if not (rcc and OCCD_backup) then return end
  for class, c in pairs(OCCD_backup) do
    if rcc[class] then rcc[class].r, rcc[class].g, rcc[class].b = c.r, c.g, c.b end
  end
end

local function OCCD_Reanchor(icon, sb)
  if not sb or not icon or type(sb.ClearAllPoints) ~= 'function' or type(sb.SetPoint) ~= 'function' then return end
  local E = NS.E; if not E then return end
  local cfg = E.global and E.global.TrenchyUI and E.global.TrenchyUI.omnicd or {}
  local dx = cfg.gapX or 0
  sb:ClearAllPoints()
  sb:SetPoint('TOPLEFT', icon, 'TOPRIGHT', dx, 0)
  sb:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', dx, 0)
  -- ensure left border exists and matches OmniCD border color
  if NS.OCCD_UpdateLeftBorder then NS.OCCD_UpdateLeftBorder(icon, sb) end
end

local function OCCD_isFromPool(sb, P)
  if not P or not P.StatusBarPool or not sb then return false end
  for x in P.StatusBarPool:EnumerateActive() do if x == sb then return true end end
  return false
end

local function OCCD_queueOrApply(icon, sb, P)
  if not icon or not sb then return end
  if not OCCD_isFromPool(sb, P) then return end
  if InCombatLockdown and InCombatLockdown() then OCCD_pending[sb] = icon; return end
  if C_Timer and C_Timer.After then C_Timer.After(0, function() if OCCD_isFromPool(sb, P) then OCCD_Reanchor(icon, sb) end end) else OCCD_Reanchor(icon, sb) end
end

local OCCD_hooked
local function OCCD_EnsureHook()
  local Omni = _G and rawget(_G, 'OmniCD')
  local OE = Omni and Omni[1]
  local P = OE and OE.Party
  if not OE or not P or not P.StatusBarPool then
    if C_Timer and C_Timer.After then C_Timer.After(0.25, OCCD_EnsureHook) end
    return
  end
  if not OCCD_hooked then
    OCCD_hooked = true
    if type(P.GetStatusBarFrame) == 'function' then
      hooksecurefunc(P, 'GetStatusBarFrame', function(_, icon)
        if icon and icon.statusBar then OCCD_queueOrApply(icon, icon.statusBar, P) end
      end)
    elseif type(P.UpdateAllBars) == 'function' then
      hooksecurefunc(P, 'UpdateAllBars', function()
        if not (P and P.StatusBarPool) then return end
        for sb in P.StatusBarPool:EnumerateActive() do
          local icon = sb and (sb.parent or (type(sb.GetParent) == 'function' and sb:GetParent()))
          if icon then OCCD_queueOrApply(icon, sb, P) end
        end
      end)
    end
  end
  for sb in P.StatusBarPool:EnumerateActive() do
    local icon = sb and (sb.parent or (type(sb.GetParent) == 'function' and sb:GetParent())) or nil
    if icon then OCCD_queueOrApply(icon, sb, P) end
  end
end

local function OCCD_UpdateAll(tries)
  tries = (tries or 0) + 1
  local Omni = _G and rawget(_G, 'OmniCD')
  local OE = Omni and Omni[1]
  local P = OE and OE.Party
  if OE and OE.isEnabled and P and P.enabled and P.UpdateAllBars then P:UpdateAllBars(); return end
  if tries < 50 and C_Timer and C_Timer.After then C_Timer.After(0.2, function() OCCD_UpdateAll(tries) end) end
end

function NS.OmniCD_ApplyExtras(now)
  local E = NS.E; if not E then return end
  local cfg = E.global and E.global.TrenchyUI and E.global.TrenchyUI.omnicd or {}
  if cfg.forceCCC ~= false then OCCD_CopyCustomToRaid() else OCCD_RestoreRaid() end
  OCCD_EnsureHook()
  OCCD_UpdateAll(0)
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

  function NS.OCCD_UpdateLeftBorder(icon, sb)
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
    NS.OmniCD_ApplyExtras(false)
  elseif evt == 'PLAYER_LOGIN' then
    NS.OmniCD_ApplyExtras(false)
  elseif evt == 'PLAYER_REGEN_ENABLED' then
    local Omni = _G and rawget(_G, 'OmniCD')
    local OE = Omni and Omni[1]
    local P = OE and OE.Party
    if OE and P and P.StatusBarPool then
      for sb, icon in pairs(OCCD_pending) do
        local inPool = false
        for x in P.StatusBarPool:EnumerateActive() do if x == sb then inPool = true; break end end
        if inPool then OCCD_Reanchor(icon, sb) end
        OCCD_pending[sb] = nil
      end
    else
      for k in pairs(OCCD_pending) do OCCD_pending[k] = nil end
    end
  end
end)

-- Re-apply on custom class color changes
do
  local function tryRegisterCCC_OC()
    local CCC = _G and rawget(_G, 'CUSTOM_CLASS_COLORS')
    if CCC and CCC.RegisterCallback and not NS.__OC_CCC_CB then
      NS.__OC_CCC_CB = true
      CCC:RegisterCallback(function()
        NS.OmniCD_ApplyExtras(true)
      end, 'TrenchyUI_OC')
    end
  end
  tryRegisterCCC_OC()
  if _G and _G.C_Timer and _G.C_Timer.After then _G.C_Timer.After(1, tryRegisterCCC_OC) end
end
