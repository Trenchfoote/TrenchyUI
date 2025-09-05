-- TrenchyUI/Core/Install.lua
local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}
local E

local BRAND_HEX = "ff2f3d"
local BRAND     = "|cff"..BRAND_HEX.."TrenchyUI|r"
local OK_COLOR  = "|cff00ff88"
local BAD_COLOR = "|cffff4444"
local SPLASH    = "Interface\\AddOns\\ElvUI_TrenchyUI\\Media\\TrenchyUI_Splash.tga"

-- ---------- helpers ----------
local function SnapshotProfile() if not E then return end return E:CopyTable({}, E.db) end
local function RestoreSnapshot(snap) if not (E and snap) then return end E:CopyTable(E.db, snap) end
local function Commit() if E then E:StaggeredUpdateAll() end end

-- In-installer toast helper
local function ShowToast(msg, good)
	local f = _G and rawget(_G, "PluginInstallFrame")
	if not f then return end
	if not f.TrenchyToast then
		local holder = CreateFrame("Frame", nil, f)
		holder:SetSize(320, 24)
		holder:SetPoint("TOP", f, "TOP", 0, -36)
		local fs = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		fs:SetPoint("CENTER")
		fs:SetText("")
		holder.fs = fs
		holder:Hide()
		f.TrenchyToast = holder
	end
	local color = good and OK_COLOR or BAD_COLOR
	local holder = f.TrenchyToast
	holder.fs:SetText(color..(msg or "").."|r")
	holder:SetAlpha(1)
	holder:Show()
	if _G and _G.UIFrameFadeOut then
		C_Timer.After(1.0, function() if holder and holder:IsShown() then UIFrameFadeOut(holder, 0.3, 1, 0) end end)
		C_Timer.After(1.35, function() if holder then holder:Hide(); holder:SetAlpha(1) end end)
	else
		C_Timer.After(1.2, function() if holder then holder:Hide() end end)
	end
end

-- ---------- layouts ----------
local function ApplyBase()
	E.db.general = E.db.general or {}
	E.db.actionbar = E.db.actionbar or {}
	E.db.unitframe = E.db.unitframe or { units = {} }
	E.db.unitframe.units = E.db.unitframe.units or {}

	E.db.general.minimap = E.db.general.minimap or {}
	E.db.general.minimap.size = 200

	E.db.actionbar.bar1 = E.db.actionbar.bar1 or { enabled = true, buttons = 12, buttonsPerRow = 12 }
	E.db.actionbar.bar2 = E.db.actionbar.bar2 or { enabled = true, buttons = 12, buttonsPerRow = 12 }

	local U = E.db.unitframe.units
	U.player = U.player or {}
	U.player.width, U.player.height = 260, 48
	U.player.power = U.player.power or {}
	U.player.power.enable = true
end

local function ApplyDPSTank()
	ApplyBase()
	local U = E.db.unitframe.units
	U.target = U.target or {}
	U.target.width, U.target.height = 260, 48
	U.focus = U.focus or {}
	U.focus.width, U.focus.height = 220, 40
	U.boss = U.boss or {}
	U.boss.width, U.boss.height = 200, 40
	U.player.castbar = U.player.castbar or {}
	U.player.castbar.width, U.player.castbar.height = 260, 20

	E.db.nameplates = E.db.nameplates or {}
	E.db.nameplates.plateSize = { enemyWidth = 135, enemyHeight = 18, friendlyWidth = 135, friendlyHeight = 18 }
end

local function HealerWIPNotice()
	print(BRAND.." Healer layout is currently |cffff4444WIP|r and not applied.")
end

-- ---------- choices state ----------
NS._choices = NS._choices or {
	layout = nil,                -- 'dps' | 'healer' | nil
	styleFiltersApplied = false, -- whether user applied nameplate style filters earlier
}

-- Apply a specific external addon profile immediately and report
local function ApplyExternalNow(name)
	if not NS.ExternalProfileAppliers then return end
	for _, item in ipairs(NS.ExternalProfileAppliers) do
		if item.name == name then
			local ok, res = pcall(item.apply)
			if ok and res ~= false then
				print(BRAND..": Applied "..name.." profile.")
			else
				print(BRAND..": Failed applying "..name.." profile.")
			end
			return
		end
	end
	print(BRAND..": Profile applier for '"..name.."' not found.")
end

-- ---------- page builders ----------
local function Page_Welcome()
	local f = _G and rawget(_G, "PluginInstallFrame")
	f.SubTitle:SetText("")
	-- Remove all descriptive text on the welcome page
	f.Desc1:SetText("")
	f.Desc2:SetText("")
	f.Desc3:SetText("")
	f.Desc4:SetText("")

	-- Make the main title much larger
	if f.Title and f.Title.SetFont then
		local font = (E and E.media and E.media.normFont) or nil
		-- large, readable size with outline
		f.Title:SetFont(font, 40, "OUTLINE")
	elseif f.Title and f.Title.FontTemplate then
		f.Title:FontTemplate(E.media and E.media.normFont, 40, "OUTLINE")
	end

	f.Option1:Show(); f.Option1:SetText("Continue")
	f.Option2:Hide(); f.Option3:Hide(); f.Option4:Hide()
	f.Option1:SetScript("OnClick", function() E:GetModule("PluginInstaller"):NextPage() end)

	-- Brand image
		if f.tutorialImage then
			f.tutorialImage:SetTexture(SPLASH)
			f.tutorialImage:ClearAllPoints()
			if f.Option1 then
				f.tutorialImage:SetPoint("BOTTOM", f.Option1, "TOP", 0, 14)
			else
				f.tutorialImage:SetPoint("BOTTOM", f, "BOTTOM", 0, 120)
			end
			-- Use a square size to prevent vertical squish
			f.tutorialImage:SetSize(192, 192)
			f.tutorialImage:SetVertexColor(1,1,1,1)
		end
	if f.tutorialImage2 then f.tutorialImage2:SetTexture(nil) end
end

local function Page_Choose()
	local f = _G and rawget(_G, "PluginInstallFrame")
	f.SubTitle:SetText("Choose a layout")
	f.Desc1:SetText("Select a layout to apply on the final step.")
	f.Desc2:SetText("|cff00ff88OnlyPlates|r is ready. |cffff4444Unnamed|r is currently inactive.")
	f.Desc3:SetText("")
	f.Desc4:SetText("")

	f.Option1:Show(); f.Option1:SetText("OnlyPlates")
	f.Option1:SetScript("OnClick", function()
		NS._choices.layout = 'dps'
		print(BRAND..": Layout set to DPS/Tank. It will apply on Finish.")
	end)

		f.Option2:Show(); f.Option2:SetText("Unnamed (WIP)")
		f.Option2:SetScript("OnClick", nil)
		if f.Option2.Disable then f.Option2:Disable() elseif f.Option2.SetEnabled then f.Option2:SetEnabled(false) end

	f.Option3:Hide()
	f.Option4:Hide()
	f.tutorialImage:SetTexture(nil); f.tutorialImage2:SetTexture(nil)
end

local function Page_Addons1()
	local f = _G and rawget(_G, "PluginInstallFrame")
	f.SubTitle:SetText("Addons (1/2)")
	f.Desc1:SetText("Click to apply that addon's profile now.")
	f.Desc2:SetText("First set of addons.")
	f.Desc3:SetText("")
	f.Desc4:SetText("")

	f.Option1:Show(); f.Option1:SetText("BigWigs")
	f.Option1:SetScript("OnClick", function()
		ApplyExternalNow('BigWigs')
		ShowToast("BigWigs applied", true)
	end)

	f.Option2:Show(); f.Option2:SetText("Details")
	f.Option2:SetScript("OnClick", function()
		ApplyExternalNow('Details')
		ShowToast("Details applied", true)
	end)

	f.Option3:Show(); f.Option3:SetText("OmniCD")
	f.Option3:SetScript("OnClick", function()
		ApplyExternalNow('OmniCD')
		ShowToast("OmniCD applied", true)
	end)

	-- Ensure buttons are enabled in case a previous page disabled them
	if f.Option1.Enable then f.Option1:Enable() elseif f.Option1.SetEnabled then f.Option1:SetEnabled(true) end
	if f.Option2.Enable then f.Option2:Enable() elseif f.Option2.SetEnabled then f.Option2:SetEnabled(true) end
	if f.Option3.Enable then f.Option3:Enable() elseif f.Option3.SetEnabled then f.Option3:SetEnabled(true) end

	f.Option4:Hide()
	f.tutorialImage:SetTexture(nil); f.tutorialImage2:SetTexture(nil)
end

local function Page_Addons2()
	local f = _G and rawget(_G, "PluginInstallFrame")
	f.SubTitle:SetText("Addons (2/2)")
	f.Desc1:SetText("Click to apply that addon's profile now.")
	f.Desc2:SetText("")
	f.Desc3:SetText("")
	f.Desc4:SetText("")

	f.Option1:Show(); f.Option1:SetText("WarpDeplete")
	f.Option1:SetScript("OnClick", function()
		ApplyExternalNow('WarpDeplete')
		ShowToast("WarpDeplete applied", true)
	end)

	f.Option2:Show(); f.Option2:SetText("AddOnSkins")
	f.Option2:SetScript("OnClick", function()
		ApplyExternalNow('AddOnSkins')
		ShowToast("AddOnSkins applied", true)
	end)

	f.Option3:Show(); f.Option3:SetText("ProjectAzilroka")
	f.Option3:SetScript("OnClick", function()
		ApplyExternalNow('ProjectAzilroka')
		ShowToast("ProjectAzilroka applied", true)
	end)

	-- Ensure buttons are enabled
	if f.Option1.Enable then f.Option1:Enable() elseif f.Option1.SetEnabled then f.Option1:SetEnabled(true) end
	if f.Option2.Enable then f.Option2:Enable() elseif f.Option2.SetEnabled then f.Option2:SetEnabled(true) end
	if f.Option3.Enable then f.Option3:Enable() elseif f.Option3.SetEnabled then f.Option3:SetEnabled(true) end

	f.Option4:Hide()
	f.tutorialImage:SetTexture(nil); f.tutorialImage2:SetTexture(nil)
end

local function Page_Nameplates()
	local f = _G and rawget(_G, "PluginInstallFrame")
	f.SubTitle:SetText("Nameplates")
	f.Desc1:SetText("Optional: import Style Filters now.")
	f.Desc2:SetText("")
	f.Desc3:SetText("")
	f.Desc4:SetText("")

	f.Option1:Show(); f.Option1:SetText("Style Filters")
	f.Option1:SetScript("OnClick", function()
		local only = NS.OnlyPlatesStrings
		if only and only.nameplatefilters and only.nameplatefilters ~= "" then
			if NS.ApplyOnlyPlatesStyleFilters then
				local ok = NS.ApplyOnlyPlatesStyleFilters()
				if ok ~= false then
					NS._choices.styleFiltersApplied = true
					ShowToast("Style Filters applied", true)
				else
					ShowToast("Failed to apply Style Filters", false)
				end
			else
				ShowToast("Importer unavailable", false)
			end
		else
			ShowToast("No Style Filters export found", false)
		end
	end)

	-- Ensure button enabled
	if f.Option1.Enable then f.Option1:Enable() elseif f.Option1.SetEnabled then f.Option1:SetEnabled(true) end

	f.Option2:Hide(); f.Option3:Hide(); f.Option4:Hide()
	f.tutorialImage:SetTexture(nil); f.tutorialImage2:SetTexture(nil)
end

local function Page_Finish()
	local f = _G and rawget(_G, "PluginInstallFrame")
	f.SubTitle:SetText("")
	f.Desc1:SetText("Click |cff"..BRAND_HEX.."Finish|r to apply selections and finalize "..BRAND..".")
	f.Desc2:SetText("Reopen anytime with |cffffff00/trenchyui install|r.")
	f.Desc3:SetText("")
	f.Desc4:SetText("")

	f.Option1:Show(); f.Option1:SetText("|cff"..BRAND_HEX.."Finish|r")
	f.Option1:SetScript("OnClick", function()
		-- Snapshot once before we change anything
		NS._snapshot = NS._snapshot or SnapshotProfile()

		-- Layout selection
		local layout = NS._choices.layout
		if layout == 'dps' then
			local imported = false
			if NS.ImportProfileStrings then
				-- Prefer OnlyPlates export strings if present
				local only = NS.OnlyPlatesStrings
				if only and (only.profile ~= "" or only.private ~= "" or only.global ~= "" or only.nameplatefilters ~= "") then
					-- If style filters already applied on the Nameplates page, skip re-importing them here
					local overrides = {
						profile = only.profile,
						private = only.private,
						global = only.global,
						nameplatefilters = NS._choices.styleFiltersApplied and "" or only.nameplatefilters,
					}
					imported = NS.ImportProfileStrings(overrides)
				else
					imported = NS.ImportProfileStrings()
				end
				if imported and NS.OnlyPlates_PostImport then NS.OnlyPlates_PostImport() end
				if NS.ApplyUIScaleAfterImport then NS.ApplyUIScaleAfterImport(NS.UIScale) end
			end
			if not imported then
				ApplyDPSTank()
			end
		elseif layout == 'healer' then
			HealerWIPNotice()
		end

	-- External addon profiles are applied immediately on button press

		-- Commit and finalize
		Commit()
		E.global.TrenchyUI = E.global.TrenchyUI or {}
		E.global.TrenchyUI.installed = true
		ReloadUI()
	end)

	-- Optional: quick revert if there is a snapshot (no reload)
	f.Option2:Hide(); f.Option3:Hide(); f.Option4:Hide()
			if f.tutorialImage then
				f.tutorialImage:SetTexture(SPLASH)
				f.tutorialImage:ClearAllPoints()
				if f.Option1 then
					f.tutorialImage:SetPoint("BOTTOM", f.Option1, "TOP", 0, 14)
				else
					f.tutorialImage:SetPoint("BOTTOM", f, "BOTTOM", 0, 120)
				end
				f.tutorialImage:SetSize(192, 192)
				f.tutorialImage:SetVertexColor(1,1,1,1)
			end
		if f.tutorialImage2 then f.tutorialImage2:SetTexture(nil) end
end

-- ---------- installer wiring ----------
function NS.SetupInstaller()
	local engine = _G and rawget(_G, "ElvUI")
	if not (engine and engine[1]) then return end
	E = engine[1]
	local PI = E:GetModule("PluginInstaller")
	if not PI then
		print(BRAND..": ElvUI PluginInstaller not found.")
		return
	end

	local data = {
		Title = BRAND,         -- colored title in installer
		Name  = "TrenchyUI",   -- plain internal name
		tutorialImage = SPLASH,
	StepTitles = { "Welcome", "Layout", "Addons 1", "Addons 2", "Nameplates", "Finish" },
	Pages = { Page_Welcome, Page_Choose, Page_Addons1, Page_Addons2, Page_Nameplates, Page_Finish },
	}

	NS.ShowInstaller = function()
		if PI.Queue then PI:Queue(data)
		elseif PI.InstallPackage then PI:InstallPackage(data)
		elseif PI.Show then PI:Show(data)
		else print(BRAND..": Installer UI not available.") end
	end
end
