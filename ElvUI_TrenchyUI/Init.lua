-- TrenchyUI/Init.lua
local E = unpack(ElvUI)
local _G = _G
local addon = ...
local ElvUI_TrenchyUI = E:NewModule("ElvUI_TrenchyUI", 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0', 'AceConsole-3.0')
local GetAddOnMetadata = _G.C_AddOns and _G.C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata

--Constants
ElvUI_TrenchyUI.Title = '|cffff2f3dTrenchyUI|r'
ElvUI_TrenchyUI.Version = GetAddOnMetadata(addon, 'Version')
ElvUI_TrenchyUI.Author = GetAddOnMetadata(addon, 'Author')
ElvUI_TrenchyUI.Notes = GetAddOnMetadata(addon, 'Notes')
ElvUI_TrenchyUI.BRAND_HEX = "ff2f3d"
ElvUI_TrenchyUI.Config = {}

--installer data
local EP = LibStub("LibElvUIPlugin-1.0")

-- ElvUI_TrenchyUI print
function ElvUI_TrenchyUI:Print(msg)
	print(ElvUI_TrenchyUI.Title..': '..msg)
end

-- ingame options
function ElvUI_TrenchyUI:Configtable()
	E.Options.name = E.Options.name .. " + " .. ElvUI_TrenchyUI.Title .. _G.format(" |cff40ff40%s|r", ElvUI_TrenchyUI.Version)

	ElvUI_TrenchyUI.Options = E.Libs.ACH:Group(ElvUI_TrenchyUI.Title, nil, 6)
	ElvUI_TrenchyUI.Options.args.description1 = E.Libs.ACH:Header(ElvUI_TrenchyUI.Title, 1)
	ElvUI_TrenchyUI.Options.args.description2 = E.Libs.ACH:Description(ElvUI_TrenchyUI.Notes, 2, "medium")
	ElvUI_TrenchyUI.Options.args.spacer1 = E.Libs.ACH:Description(" ", 3)
	ElvUI_TrenchyUI.Options.args.installer = E.Libs.ACH:Execute(ElvUI_TrenchyUI.Title.." – Open Installer", nil, 4, function()
		E:GetModule("PluginInstaller"):Queue(ElvUI_TrenchyUI.InstallerData)
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.layoutsHeader = E.Libs.ACH:Header("|cff"..ElvUI_TrenchyUI.BRAND_HEX.."Layouts|r", 5)
	ElvUI_TrenchyUI.Options.args.reinstallOnly = E.Libs.ACH:Execute("Reinstall OnlyPlates Layout", nil, 6, function()
		ElvUI_TrenchyUI:ApplyOnlyPlatesDB("general")
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.reinstallUnnamed = E.Libs.ACH:Execute("Reinstall Unnamed Layout (WIP)", nil, 8, function()
		ElvUI_TrenchyUI:ApplyOnlyPlatesDB("Unnamed")
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.styleHeader = E.Libs.ACH:Header("|cff"..ElvUI_TrenchyUI.BRAND_HEX.."ElvUI Nameplate Style Filters|r", 9)
	ElvUI_TrenchyUI.Options.args.applySeasonalStyle = E.Libs.ACH:Execute("Apply Seasonal Style Filters (|cff40ff40"..E.db.ElvUI_TrenchyUI.StyleFiltersSeasonal.Version.."|r)", nil, 10, function()
		ElvUI_TrenchyUI:OnlyPlatesStyleFilterStrings("nameplatefilters")
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.applyCommonStyle = E.Libs.ACH:Execute("Apply Common Style Filters (|cff40ff40"..E.db.ElvUI_TrenchyUI.StyleFiltersCommon.Version.."|r)", nil, 11, function()
		ElvUI_TrenchyUI:OnlyPlatesStyleFilterStrings("nameplatefilters_alt")
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.addonsHeader = E.Libs.ACH:Header("|cff"..ElvUI_TrenchyUI.BRAND_HEX.."Other Addons|r", 12)
	ElvUI_TrenchyUI.Options.args.applyBigWigs = E.Libs.ACH:Execute("Apply BigWigs Profile", nil, 13, function()
		ElvUI_TrenchyUI:BigWigs()
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.applyDetails = E.Libs.ACH:Execute("Apply Details Profile", nil, 14, function()
		ElvUI_TrenchyUI:Details()
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.applyOmniCD = E.Libs.ACH:Execute("Apply OmniCD Profile", nil, 15, function()
		ElvUI_TrenchyUI:OmniCD()
	end, nil, nil, "full")

	ElvUI_TrenchyUI.Options.args.applyAddOnSkins = E.Libs.ACH:Execute("Apply AddOnSkins Profile", nil, 15, function()
		ElvUI_TrenchyUI:AddOnSkins()
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.applyProjectAzilroka = E.Libs.ACH:Execute("Apply ProjectAzilroka Profile", nil, 15, function()
		ElvUI_TrenchyUI:ProjectAzilroka()
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.spacer2 = E.Libs.ACH:Description(" ", 16)
	ElvUI_TrenchyUI.Options.args.spacer3 = E.Libs.ACH:Description(" ", 17)
	ElvUI_TrenchyUI.Options.args.integrationsHeader = E.Libs.ACH:Header(" ", 18)

	ElvUI_TrenchyUI.Options.args.wdGroup = E.Libs.ACH:Group(" ", nil, 19)
	ElvUI_TrenchyUI.Options.args.wdGroup.inline = true
	ElvUI_TrenchyUI.Options.args.wdGroup.args.wdHeader = E.Libs.ACH:Header("|cff"..ElvUI_TrenchyUI.BRAND_HEX.."WarpDeplete|r", 1)
	ElvUI_TrenchyUI.Options.args.wdGroup.args.wdApplyProfile = E.Libs.ACH:Execute("Apply WarpDeplete Profile", nil, 2, function()
		ElvUI_TrenchyUI:WarpDeplete()
	end, nil, nil, "double")
	ElvUI_TrenchyUI.Options.args.wdGroup.args.wdForceClass = E.Libs.ACH:Toggle("Force Class Colors", "Override WarpDeplete bar colors with your class color (uses CUSTOM_CLASS_COLORS first).", 3, nil, nil, nil, function() return E.db.ElvUI_TrenchyUI.warpdeplete.forceClassColors end, function(_, value) E.db.ElvUI_TrenchyUI.warpdeplete.forceClassColors = value ElvUI_TrenchyUI:WarpDeplete_ApplyClassColors(true) end)

	ElvUI_TrenchyUI.Options.args.ocGroup = E.Libs.ACH:Group(" ", nil, 20)
	ElvUI_TrenchyUI.Options.args.ocGroup.inline = true
	ElvUI_TrenchyUI.Options.args.ocGroup.args.ocHeader = E.Libs.ACH:Header("|cff"..ElvUI_TrenchyUI.BRAND_HEX.."OmniCD|r", 1)
	ElvUI_TrenchyUI.Options.args.ocGroup.args.ocApplyProfile = E.Libs.ACH:Execute("Apply OmniCD Profile", nil, 2, function()
		ElvUI_TrenchyUI:OmniCD()
	end, nil, nil, "double")
	ElvUI_TrenchyUI.Options.args.ocGroup.args.ocUseCCC = E.Libs.ACH:Toggle("Use Custom Class Colors", "Copy CUSTOM_CLASS_COLORS to RAID_CLASS_COLORS for OmniCD extra bars.", 3, nil, nil, nil, function() return E.db.ElvUI_TrenchyUI.omnicd.forceCCC end, function(_, value) E.db.ElvUI_TrenchyUI.omnicd.forceCCC = value ElvUI_TrenchyUI.OmniCD_ApplyExtras(true) end)
	ElvUI_TrenchyUI.Options.args.ocGroup.args.ocGap = E.Libs.ACH:Range("Padding X", nil, 4, { min = 0, max = 40, step = 1 }, nil, function() return E.db.ElvUI_TrenchyUI.omnicd.gapX end, function(_, value) E.db.ElvUI_TrenchyUI.omnicd.gapX = value ElvUI_TrenchyUI.OmniCD_ApplyExtras(true) end)

	--[[
	E.Libs.ACH:Header(name, order, get, set, hidden)
	E.Libs.ACH:Group(name, desc, order, childGroups, get, set, disabled, hidden, func)
	E.Libs.ACH:Description(name, order, fontSize, image, imageCoords, imageWidth, imageHeight, width, hidden)

	E.Libs.ACH:Toggle(name, desc, order, tristate, confirm, width, get, set, disabled, hidden)
	E.Libs.ACH:Execute(name, desc, order, func, image, confirm, width, get, set, disabled, hidden)
	E.Libs.ACH:Select(name, desc, order, values, confirm, width, get, set, disabled, hidden)
	E.Libs.ACH:Input(name, desc, order, multiline, width, get, set, disabled, hidden, validate)
	E.Libs.ACH:Color(name, desc, order, alpha, width, get, set, disabled, hidden)
	E.Libs.ACH:Range(name, desc, order, values, width, get, set, disabled, hidden)

	E.Libs.ACH:SharedMediaFont(name, desc, order, width, get, set, disabled, hidden)
	E.Libs.ACH:SharedMediaSound(name, desc, order, width, get, set, disabled, hidden)
	E.Libs.ACH:SharedMediaStatusbar(name, desc, order, width, get, set, disabled, hidden)
	E.Libs.ACH:SharedMediaBackground(name, desc, order, width, get, set, disabled, hidden)
	E.Libs.ACH:SharedMediaBorder(name, desc, order, width, get, set, disabled, hidden)
	]]--

	E.Options.args.ElvUI_TrenchyUI = ElvUI_TrenchyUI.Options
end

--This function will handle initialization of the addon
function ElvUI_TrenchyUI:Initialize()

	--Initiate installation process if ElvUI install is complete and our plugin install has not yet been run
	if E.private.install_complete and E.db.ElvUI_TrenchyUI.install_version == nil then
		E:GetModule("PluginInstaller"):Queue(ElvUI_TrenchyUI.InstallerData)
	end

	--Insert our options table when ElvUI config is loaded
	EP:RegisterPlugin(addon, ElvUI_TrenchyUI.Configtable)
end

--Register module with callback so it gets initialized when ready
local function CallbackInitialize()
	ElvUI_TrenchyUI:Initialize()
end
E:RegisterModule(addon,CallbackInitialize)
