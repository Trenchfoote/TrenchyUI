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
    if not only then print(BRAND..": No OnlyPlates export available.") return end
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
    print(BRAND..(ok and ": OnlyPlates layout reinstalled." or ": Failed to reinstall OnlyPlates layout."))
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

  local function ReinstallStyleFilters()
    if NS.ApplyOnlyPlatesStyleFilters then
      local ok = NS.ApplyOnlyPlatesStyleFilters()
      print(BRAND..(ok and ": Nameplate Style Filters applied." or ": Failed to apply Style Filters."))
    else
      print(BRAND..": Style Filter importer unavailable.")
    end
  end

  -- Version stamp for Nameplate Style Filters (shown on the button only)
  local STYLE_VERSION = "TWW S3 Version 1.0"

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
      name = "Reinstall OnlyPlates Layout",
      func = ReinstallOnlyPlates,
    },
    reinstallUnnamed = {
      order = 8, type = "execute", width = "full",
      name = "Reinstall Unnamed Layout (WIP)",
      disabled = true,
      func = ReinstallUnnamed,
    },
    spacer3 = { order = 9, type = "description", name = " " },
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
      order = 13, type = "execute", width = "full",
      name = "Apply OmniCD Profile",
      func = function() ApplyExternal('OmniCD') end,
    },
    applyWarpDeplete = {
      order = 14, type = "execute", width = "full",
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
    styleHeader = { order = 18, type = "header", name = "|cff"..BRAND_HEX.."Nameplate Style Filters|r" },
    reinstallStyle = {
      order = 19, type = "execute", width = "full",
      name = "Reinstall Style Filters (|cff40ff40"..STYLE_VERSION.."|r)",
      func = ReinstallStyleFilters,
    },
    spacer5 = { order = 20, type = "description", name = " " },

    -- Integrations (WarpDeplete & OmniCD)
    integrationsHeader = { order = 21, type = "header", name = "|cff"..BRAND_HEX.."Integrations|r" },
    wdGroup = {
      order = 22, type = "group", inline = true, name = "Warp Deplete: Extra Options",
      args = {
        wdEnabled = {
          order = 1, type = "toggle", width = 1.0,
          name = "Enable",
          desc = "Force bar colors to follow Custom Class colors.",
          get = function()
            local E = NS.E; if not E then return false end
            local db = E.global.TrenchyUI and E.global.TrenchyUI.integrations and E.global.TrenchyUI.integrations.wd
            return db and db.enabled or false
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local db = E.global.TrenchyUI.integrations.wd; db.enabled = not not v
            if NS.Integrations and NS.Integrations.WD then NS.Integrations.WD:ApplyWhenReady(0) end
          end,
        },
        wdTimers = {
          order = 2, type = "toggle", width = 1.2,
          name = "+1/+2/+3 Timers",
          get = function()
            local E = NS.E; if not E then return true end
            local db = E.global.TrenchyUI.integrations.wd; return db.applyTimers ~= false
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local db = E.global.TrenchyUI.integrations.wd; db.applyTimers = not not v
            if NS.Integrations and NS.Integrations.WD then NS.Integrations.WD:ApplyOverrides() end
          end,
        },
        wdForces = {
          order = 3, type = "toggle", width = 0.8,
          name = "Forces",
          get = function()
            local E = NS.E; if not E then return true end
            local db = E.global.TrenchyUI.integrations.wd; return db.applyForces ~= false
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local db = E.global.TrenchyUI.integrations.wd; db.applyForces = not not v
            if NS.Integrations and NS.Integrations.WD then NS.Integrations.WD:ApplyOverrides() end
          end,
        },
        wdTexture = {
          order = 4, type = "select", width = 0.7,
          name = "Bar texture",
          desc = "Force all bars to follow this texture",
          dialogControl = (NS.E and NS.E.Libs and NS.E.Libs.LSM) and "LSM30_Statusbar" or nil,
          values = (NS.E and NS.E.Libs and NS.E.Libs.LSM) and NS.E.Libs.LSM:HashTable("statusbar") or {},
          get = function()
            local E = NS.E; if not E then return nil end
            local db = E.global.TrenchyUI.integrations.wd; return db.textureName
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local db = E.global.TrenchyUI.integrations.wd; db.textureName = v
            if NS.Integrations and NS.Integrations.WD then NS.Integrations.WD:ApplyOverrides() end
          end,
        },
        wdFont = {
          order = 5, type = "select", width = 0.7,
          name = "Bar font",
          desc = "Force all fonts to follow this font",
          dialogControl = (NS.E and NS.E.Libs and NS.E.Libs.LSM) and "LSM30_Font" or nil,
          values = (NS.E and NS.E.Libs and NS.E.Libs.LSM) and NS.E.Libs.LSM:HashTable("font") or {},
          get = function()
            local E = NS.E; if not E then return nil end
            local db = E.global.TrenchyUI.integrations.wd; return db.fontName
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local db = E.global.TrenchyUI.integrations.wd; db.fontName = v
            if NS.Integrations and NS.Integrations.WD then NS.Integrations.WD:ApplyOverrides() end
          end,
        },
      }
    },
    occdGroup = {
      order = 23, type = "group", inline = true, name = "OmniCD: Extra Options",
      args = {
        occdCustomClass = {
          order = 0, type = "toggle", width = 1.5,
          name = "Use Custom Class Colors",
          get = function()
            local E = NS.E; if not E then return true end
            local db = E.global.TrenchyUI.integrations.occd; return db.customClassColorsEnabled ~= false
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local db = E.global.TrenchyUI.integrations.occd; db.customClassColorsEnabled = not not v
            if NS.Integrations and NS.Integrations.OCCD then NS.Integrations.OCCD:ApplyNow() end
          end,
        },
        occdEnable = {
          order = 1, type = "toggle", width = 1.0,
          name = "Enable",
          desc = "Increase the padding between extra bars and their icons",
          get = function()
            local E = NS.E; if not E then return true end
            local db = E.global.TrenchyUI.integrations.occd; return db.gapEnabled ~= false
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local db = E.global.TrenchyUI.integrations.occd; db.gapEnabled = not not v
            if NS.Integrations and NS.Integrations.OCCD then NS.Integrations.OCCD:ApplyNow() end
          end,
        },
        occdGap = {
          order = 2, type = "range", width = 0.9,
          name = "Padding X",
          min = 0, max = 40, step = 1,
          get = function()
            local E = NS.E; if not E then return 0 end
            local db = E.global.TrenchyUI.integrations.occd; return db.gapX or 0
          end,
          set = function(_, v)
            local E = NS.E; if not E then return end
            local db = E.global.TrenchyUI.integrations.occd; db.gapX = math.floor(tonumber(v) or 0)
            if NS.Integrations and NS.Integrations.OCCD then NS.Integrations.OCCD:ApplyNow() end
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
  E.Options.args.trenchyui = {
    order = 95, type = "group", name = BRAND, args = sharedArgs
  }
end
