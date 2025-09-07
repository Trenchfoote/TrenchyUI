local E = unpack(ElvUI)
local ElvUI_TrenchyUI = E:GetModule('ElvUI_TrenchyUI')

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
		ElvUI_TrenchyUI:ApplyProfileDB("onlyplates")
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.reinstallUnnamed = E.Libs.ACH:Execute("Reinstall Unnamed Layout (WIP)", nil, 8, function()
		ElvUI_TrenchyUI:ApplyProfileDB("Unnamed")
	end, nil, nil, "full")
	ElvUI_TrenchyUI.Options.args.styleHeader = E.Libs.ACH:Header("|cff"..ElvUI_TrenchyUI.BRAND_HEX.."ElvUI Nameplate Style Filters|r", 9)
	ElvUI_TrenchyUI.Options.args.applySeasonalStyle = E.Libs.ACH:Execute("Seasonal (|cff40ff40"..E.db.ElvUI_TrenchyUI.StyleFilters.Seasonal.Version.."|r)", "Reinstall dungeon specific style filters.", 10, function()
		ElvUI_TrenchyUI:ApplyTrenchyStyleFiltersDB("Seasonal")
	end, nil, nil, "double")
	ElvUI_TrenchyUI.Options.args.applyCommonStyle = E.Libs.ACH:Execute("Common (|cff40ff40"..E.db.ElvUI_TrenchyUI.StyleFilters.Common.Version.."|r)", "Reinstall non-season style filters (quest, focus, hide)", 11, function()
		ElvUI_TrenchyUI:ApplyTrenchyStyleFiltersDB("Common")
	end, nil, nil, "double")
	ElvUI_TrenchyUI.Options.args.addonsHeader = E.Libs.ACH:Header("|cff"..ElvUI_TrenchyUI.BRAND_HEX.."Other Addons|r", 12)
	ElvUI_TrenchyUI.Options.args.applyBigWigsOnlyPlates = E.Libs.ACH:Execute("BW OnlyPlates", "Reapply the BigWigs OnlyPlates profile.", 13, function()
		ElvUI_TrenchyUI:BigWigs("OnlyPlates")
	end, nil, nil, "single")
	ElvUI_TrenchyUI.Options.args.applyBigWigsUnnamed = E.Libs.ACH:Execute("BW Unnamed", "Reapply the BigWigs Unnamed profile.", 13, function()
		ElvUI_TrenchyUI:BigWigs("Unnamed")
	end, nil, nil, "single")
	ElvUI_TrenchyUI.Options.args.applyDetails = E.Libs.ACH:Execute("Details!", "Reapply the Details! profile. (Note, don't click this if TrenchyUI is already in Details, may cause shifting.)", 14, function()
		ElvUI_TrenchyUI:Details()
	end, nil, nil, "single")
	ElvUI_TrenchyUI.Options.args.applyProjectAzilroka = E.Libs.ACH:Execute("|cFF16C3F2Project|r|cFFFFFFFFAzilroka|r", "Reapply the ProjectAzilroka profile.", 15, function()
		ElvUI_TrenchyUI:ProjectAzilroka()
	end, nil, nil, "single")
	ElvUI_TrenchyUI.Options.args.integrationsHeader = E.Libs.ACH:Description(" ", 18)
	ElvUI_TrenchyUI.Options.args.wdGroup = E.Libs.ACH:Group(" ", nil, 19)
	ElvUI_TrenchyUI.Options.args.wdGroup.inline = true
	ElvUI_TrenchyUI.Options.args.wdGroup.args.wdHeader = E.Libs.ACH:Header("|cff"..ElvUI_TrenchyUI.BRAND_HEX.."WarpDeplete|r", 1)
	ElvUI_TrenchyUI.Options.args.wdGroup.args.wdApplyProfile = E.Libs.ACH:Execute("WarpDeplete", "Reapply the WarpDeplete profile.", 2, function()
		ElvUI_TrenchyUI:WarpDeplete()
	end, nil, nil, "single")
	ElvUI_TrenchyUI.Options.args.wdGroup.args.wdForceClass = E.Libs.ACH:Toggle("Class Colors", "Override WarpDeplete bar colors with your class color.", 3, nil, nil, nil, function() return E.db.ElvUI_TrenchyUI.warpdeplete.forceClassColors end, function(_, value) E.db.ElvUI_TrenchyUI.warpdeplete.forceClassColors = value if value == true then ElvUI_TrenchyUI:WarpDeplete_ApplyClassColors() end end)
	ElvUI_TrenchyUI.Options.args.ocGroup = E.Libs.ACH:Group(" ", nil, 20)
	ElvUI_TrenchyUI.Options.args.ocGroup.inline = true
	ElvUI_TrenchyUI.Options.args.ocGroup.args.ocHeader = E.Libs.ACH:Header("|cff"..ElvUI_TrenchyUI.BRAND_HEX.."OmniCD|r", 1)
	ElvUI_TrenchyUI.Options.args.ocGroup.args.applyOmniCDOnlyPlates = E.Libs.ACH:Execute("OnlyPlates", "Click to reapply the OnlyPlates OmniCd profile.", 2, function()
		ElvUI_TrenchyUI:OmniCD("OnlyPlates")
	end, nil, nil, "single")
	ElvUI_TrenchyUI.Options.args.ocGroup.args.applyOmniCDUnnamed = E.Libs.ACH:Execute("Unnamed", "Click to reapply the Unnamed OmniCd profile.", 3, function()
		ElvUI_TrenchyUI:OmniCD("Unnamed")
	end, nil, nil, "single")
	ElvUI_TrenchyUI.Options.args.ocGroup.args.ocUseCCC = E.Libs.ACH:Toggle("Class Colors", "Forces OmniCD to use Custom Class Colors, if they're present.", 4, nil, nil, nil,
		function() return E.db.ElvUI_TrenchyUI.omnicd.forceCCC end,
		function(_, value) ElvUI_TrenchyUI:OmniCD_SetUseCCC(value) end)
	ElvUI_TrenchyUI.Options.args.ocGroup.args.ocGap = E.Libs.ACH:Range("Padding X", nil, 5, { min = 0, max = 40, step = 1 }, nil,
		function() return E.db.ElvUI_TrenchyUI.omnicd.gapX end,
		function(_, value) ElvUI_TrenchyUI:OmniCD_SetGap(value) end)

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
