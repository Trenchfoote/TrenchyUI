-- TrenchyUI/Core/Install.lua
local E = unpack(ElvUI)
local ElvUI_TrenchyUI = E:GetModule('ElvUI_TrenchyUI')

function ElvUI_TrenchyUI:GeneralSetup()
	E:SetupChat()
	E:SetupCVars()
end

ElvUI_TrenchyUI.InstallerData = {
	Title = ElvUI_TrenchyUI.Title,
	Name = ElvUI_TrenchyUI.Title,
	tutorialImage = "Interface\\AddOns\\ElvUI_TrenchyUI\\Media\\TrenchyUI_Splash.tga",
	tutorialImageSize = {256,256},
	Pages = {
		[1] = function()
			_G.PluginInstallTutorialImage:Show()
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetText("Continue")
			PluginInstallFrame.Option1:SetScript("OnClick", function() E:GetModule("PluginInstaller"):NextPage() end)
			PluginInstallFrame.Option2:Hide()
			PluginInstallFrame.Option3:Hide()
			PluginInstallFrame.Option4:Hide()
		end,
		[2] = function()
			_G.PluginInstallTutorialImage:Hide()
			PluginInstallFrame.SubTitle:SetText("Choose a layout")
			PluginInstallFrame.Desc1:SetText("Select a layout to apply on the final step.")
			PluginInstallFrame.Desc2:SetText("|cffff2f3dTrenchyUI|r is ready. |cffff4444Unnamed|r is currently inactive.")

			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetScript("OnClick", function()
				ElvUI_TrenchyUI:GeneralSetup()
				if (E.Mists or E.Retail or E.ClassicSOD) and E.data:IsDualSpecEnabled() then
					E.data:SetDualSpecProfile('TUI OnlyPlates ('..E.mynameRealm..')', E.Libs.DualSpec.currentSpec)
				else
					E.data:SetProfile('TUI OnlyPlates ('..E.mynameRealm..')')
				end
				ElvUI_TrenchyUI:ApplyProfileDB("onlyplates")
			end)
			PluginInstallFrame.Option1:SetText("OnlyPlates")
			PluginInstallFrame.Option1:Enable()

			PluginInstallFrame.Option2:Show()
			PluginInstallFrame.Option2:SetScript("OnClick", function()
                ElvUI_TrenchyUI:GeneralSetup()
                if (E.Mists or E.Retail or E.ClassicSOD) and E.data:IsDualSpecEnabled() then
                    E.data:SetDualSpecProfile('TUI Unnamed ('..E.mynameRealm..')', E.Libs.DualSpec.currentSpec)
                else
                    E.data:SetProfile('TUI Unnamed ('..E.mynameRealm..')')
                end
                ElvUI_TrenchyUI:ApplyProfileDB("unnamed")
            end)
			PluginInstallFrame.Option2:SetText("Unnamed (WIP)")
			PluginInstallFrame.Option2:Enable()

			PluginInstallFrame.Option3:Hide()
			PluginInstallFrame.Option4:Hide()
		end,
		[3] = function()
			_G.PluginInstallTutorialImage:Hide()
			PluginInstallFrame.SubTitle:SetText("Addons (1/2)")
			PluginInstallFrame.Desc1:SetText("Click to apply that addon's profile now.")
			PluginInstallFrame.Desc2:SetText("First set of addons.")
			PluginInstallFrame.Desc3:SetText("")
			PluginInstallFrame.Desc4:SetText("")

			PluginInstallFrame.Option1:Enable()
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetText("BigWigs\nOnlyPlates")
			PluginInstallFrame.Option1:SetScript("OnClick", function()
				ElvUI_TrenchyUI:BigWigs("OnlyPlates")
				ElvUI_TrenchyUI:Print("BigWigs applied")
			end)

			PluginInstallFrame.Option2:Enable()
			PluginInstallFrame.Option2:Show()
			PluginInstallFrame.Option2:SetText("BigWigs\nUnnamed")
			PluginInstallFrame.Option2:SetScript("OnClick", function()
				ElvUI_TrenchyUI:BigWigs("Unnamed")
				ElvUI_TrenchyUI:Print("BigWigs applied")
			end)

			PluginInstallFrame.Option3:Enable()
			PluginInstallFrame.Option3:Show()
			PluginInstallFrame.Option3:SetText("OmniCD\nOnlyPlates")
			PluginInstallFrame.Option3:SetScript("OnClick", function()
				ElvUI_TrenchyUI:OmniCD("OnlyPlates")
				ElvUI_TrenchyUI:Print("OmniCD applied")
			end)

			PluginInstallFrame.Option4:Enable()
			PluginInstallFrame.Option4:Show()
			PluginInstallFrame.Option4:SetText("OmniCD\nUnnamed")
			PluginInstallFrame.Option4:SetScript("OnClick", function()
				ElvUI_TrenchyUI:OmniCD("Unnamed")
				ElvUI_TrenchyUI:Print("OmniCD applied")
			end)
		end,
		[4] = function()
			_G.PluginInstallTutorialImage:Hide()
			PluginInstallFrame.SubTitle:SetText("Addons (2/2)")
			PluginInstallFrame.Desc1:SetText("Click to apply that addon's profile now.")
			PluginInstallFrame.Desc2:SetText("")
			PluginInstallFrame.Desc3:SetText("")
			PluginInstallFrame.Desc4:SetText("")

			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetText("WarpDeplete")
			PluginInstallFrame.Option1:SetScript("OnClick", function()
				ElvUI_TrenchyUI:WarpDeplete()
				ElvUI_TrenchyUI:Print("WarpDeplete applied")
			end)

			PluginInstallFrame.Option2:Show()
			PluginInstallFrame.Option2:SetText("AddOnSkins")
			PluginInstallFrame.Option2:SetScript("OnClick", function()
				ElvUI_TrenchyUI:AddOnSkins()
				ElvUI_TrenchyUI:Print("AddOnSkins applied")
			end)

			PluginInstallFrame.Option3:Show()
			PluginInstallFrame.Option3:SetText("ProjectAzilroka")
			PluginInstallFrame.Option3:SetScript("OnClick", function()
				ElvUI_TrenchyUI:ProjectAzilroka()
				ElvUI_TrenchyUI:Print("ProjectAzilroka applied")
			end)

			PluginInstallFrame.Option4:Enable()
			PluginInstallFrame.Option4:Show()
			PluginInstallFrame.Option4:SetText("Details")
			PluginInstallFrame.Option4:SetScript("OnClick", function()
				ElvUI_TrenchyUI:Details()
				ElvUI_TrenchyUI:Print("Details applied")
			end)
		end,
		[5] = function()
			_G.PluginInstallTutorialImage:Hide()
			PluginInstallFrame.Desc1:SetText("Optional: Apply TrenchyUI ElvUI Style Filters now.")
			PluginInstallFrame.Desc2:SetText("Seasonal: "..E.db.ElvUI_TrenchyUI.StyleFilters.Seasonal.Version.."\nCommon: "..E.db.ElvUI_TrenchyUI.StyleFilters.Common.Version)
			PluginInstallFrame.Desc3:SetText("")
			PluginInstallFrame.Desc4:SetText("")

			PluginInstallFrame.Option1:Enable()
			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetText("Seasonal")
			PluginInstallFrame.Option1:SetScript("OnClick", function()
				ElvUI_TrenchyUI:ApplyTrenchyStyleFiltersDB("Seasonal")
				ElvUI_TrenchyUI:Print("Seasonal filters applied ("..E.db.ElvUI_TrenchyUI.StyleFilters.Seasonal.Version..")")
			end)

			PluginInstallFrame.Option2:Enable()
			PluginInstallFrame.Option2:Show()
			PluginInstallFrame.Option2:SetText("Common")
			PluginInstallFrame.Option2:SetScript("OnClick", function()
				ElvUI_TrenchyUI:ApplyTrenchyStyleFiltersDB("Common")
				ElvUI_TrenchyUI:Print("Common filters applied ("..E.db.ElvUI_TrenchyUI.StyleFilters.Common.Version..")")
			end)

			PluginInstallFrame.Option3:Hide()
			PluginInstallFrame.Option4:Hide()
		end,
		[6] = function()
			_G.PluginInstallTutorialImage:Hide()
			PluginInstallFrame.SubTitle:SetText("")
			PluginInstallFrame.Desc1:SetText("Click |cffff2f3dFinish|r to apply selections and finalize "..ElvUI_TrenchyUI.Title..".")
			PluginInstallFrame.Desc2:SetText("Reopen anytime with |cffffff00/trenchyui install|r.")
			PluginInstallFrame.Desc3:SetText("")
			PluginInstallFrame.Desc4:SetText("")

			PluginInstallFrame.Option1:Show()
			PluginInstallFrame.Option1:SetText("|cffff2f3dFinish|r")
			PluginInstallFrame.Option1:SetScript("OnClick", function()
				E.db.ElvUI_TrenchyUI.install_version = ElvUI_TrenchyUI.Version
				E.private.install_complete = E.version
				_G.ReloadUI()
			end)
		end,
	},
	StepTitles = {
		[1] = "Welcome",
		[2] = "Layout",
		[3] = "Addons (1/2)",
		[4] = "Addons (2/2)",
		[5] = "Style Filters",
		[6] = "Finish",
	},
	StepTitlesColor = {1, 1, 1},
	StepTitlesColorSelected = {1, 0.18, 0.24},
	StepTitleWidth = 200,
	StepTitleButtonWidth = 180,
	StepTitleTextJustification = "RIGHT",
}
