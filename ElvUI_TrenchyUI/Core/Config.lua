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
