-- TrenchyUI/Core/Core.lua
local AddonName, NS = ...
local E, L, V, P, G
local _G = _G

local BRAND_HEX = "ff2f3d"
local BRAND     = "|cff"..BRAND_HEX.."TrenchyUI|r"
local EnsureOptionsBranding -- forward declaration

-- TOC metadata helper (shared)
local function GetTOCVersion()
	local CA = _G and rawget(_G, "C_AddOns")
	local v
	if CA and CA.GetAddOnMetadata then
		v = CA.GetAddOnMetadata(AddonName, "Version")
	else
		local get = _G and rawget(_G, "GetAddOnMetadata")
		if type(get) == "function" then v = get(AddonName, "Version") end
	end
	return v or ""
end

-- Safe trim (older clients compat)
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- ===== Slash Command =====
if type(SLASH_TRENCHYUI1) ~= "string" then SLASH_TRENCHYUI1 = "/trenchyui" end
SlashCmdList = SlashCmdList or {}
local function OpenTrenchyOptions()
	-- Resolve ElvUI engine
	local engine = NS.E and { NS.E } or (_G and rawget(_G, "ElvUI"))
	if engine and engine[1] then E = engine[1] end

	-- Ensure ElvUI_Options is loaded then open options UI
	local CA = _G and rawget(_G, 'C_AddOns')
	if CA and CA.LoadAddOn then pcall(CA.LoadAddOn, 'ElvUI_Options') end
	if E and E.ToggleOptions then E:ToggleOptions() elseif E and E.ToggleOptionsUI then E:ToggleOptionsUI() end
		EnsureOptionsBranding()

	-- After the options UI is loaded, select our group safely
	local attempts, maxAttempts = 0, 20 -- ~1s total with 0.05s steps
	local function trySelect()
		attempts = attempts + 1
		local ACD = E and E.Libs and (E.Libs.AceConfigDialog or E.Libs.ACD)
		if E and E.Options and E.Options.args and ACD and ACD.SelectGroup then
			-- Select our top-level group; we no longer add an entry under Plugins
			if E.Options.args.trenchyui then ACD:SelectGroup("ElvUI", "trenchyui") end
			return
		end
		if attempts < maxAttempts and _G and C_Timer and C_Timer.After then
			C_Timer.After(0.05, trySelect)
		end
	end
	if _G and C_Timer and C_Timer.After then C_Timer.After(0.05, trySelect) else trySelect() end
end
local function TrenchyUI_SlashHandler(msg)
	msg = trim((msg or ""):lower())
	if msg == "install" then
		if NS.ShowInstaller then
			NS.ShowInstaller(true)
		else
			print(BRAND..": Installer not ready. Is ElvUI loaded?")
		end
	elseif msg == "config" or msg == "options" or msg == "ui" or msg == "" then
		OpenTrenchyOptions()
	else
		print(BRAND..": use |cffffff00/trenchyui|r or |cffffff00/trenchyui install|r")
	end
end
if not SlashCmdList.TRENCHYUI then
	SlashCmdList.TRENCHYUI = TrenchyUI_SlashHandler
else
	SlashCmdList.TRENCHYUI = TrenchyUI_SlashHandler
end

-- ===== Color our entry in Estatus -> Plugins =====
local function ColorStatusPluginName()
	if not (NS and NS.E) then return end
	local EP = _G.LibStub and _G.LibStub("LibElvUIPlugin-1.0", true)


-- Add a brand/version label to the ElvUI options top bar
EnsureOptionsBranding = function()
	local f = _G and rawget(_G, 'ElvUIOptionsUI')
	if not f then return end
	local E = NS.E
	if not E then return end

	-- If we've already branded the title via E.Options.name, skip overlay label
	if E.Options and type(E.Options.name) == "string" and string.find(E.Options.name, "TrenchyUI", 1, true) then
		if f.TrenchyBrand then f.TrenchyBrand:Hide() end
		return
	end

		if not f.TrenchyBrand then
			local fs = f:CreateFontString(nil, "OVERLAY")
			-- Keep default UI font; apply only size/outline if available
			if fs.FontTemplate then fs:FontTemplate(nil, 12, "OUTLINE") end
			fs:SetJustifyH("RIGHT")
			fs:SetPoint("TOPRIGHT", f, "TOPRIGHT", -48, -6)
			f.TrenchyBrand = fs
		end

	local version = GetTOCVersion()
	local text = BRAND.." |cff40ff40v"..version.."|r"
	f.TrenchyBrand:SetText(text)
		f.TrenchyBrand:Show()
	end

	-- Lib registry (commonly used for the Plugins list)
	if EP and EP.plugins and EP.plugins[AddonName] then
		EP.plugins[AddonName].name = BRAND
		local v = GetTOCVersion()
		if v ~= "" then EP.plugins[AddonName].version = v end
	end

	-- Some builds mirror into E.plugins
	if NS.E.plugins and NS.E.plugins[AddonName] then
		NS.E.plugins[AddonName].name = BRAND
		local v = GetTOCVersion()
		if v ~= "" then NS.E.plugins[AddonName].version = v end
	end
end

-- ===== Options (moved to Config.lua) =====
-- BuildOptions is now defined in Core/Config.lua
-- We keep only handlers that need to run here.
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
			-- Re-enable importing OnlyPlates nameplate Style Filters as requested
			nameplatefilters = only.nameplatefilters or "",
		}
		local ok = NS.ImportProfileStrings(overrides)
		if ok and NS.OnlyPlates_PostImport then NS.OnlyPlates_PostImport() end
		if NS.ApplyUIScaleAfterImport and NS.UIScale then NS.ApplyUIScaleAfterImport(NS.UIScale) end
		print(BRAND..(ok and ": OnlyPlates layout reinstalled." or ": Failed to reinstall OnlyPlates layout."))
	end

	local function ReinstallUnnamed()
		-- Placeholder for future Unnamed layout
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

	local groupArgs = {
		header  = { order = 1, type = "header", name = BRAND },
		desc    = {
			order = 2, type = "description",
			name  = "A lightweight installer and layout preset for ElvUI.\n\n" ..
							"Click the button below to (re)open the setup wizard."
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
	}

	-- InsertOptions is now provided by Core/Config.lua as NS.InsertOptions()

-- ===== ElvUI Hook & Initialization =====
local function OnElvUIReady()
	local engine = _G and rawget(_G, "ElvUI")
	if not (engine and engine[1]) then return end
	E, L, V, P, G = unpack(engine)
	NS.E = E

	-- Prepare installer wiring (defined in Install.lua)
	if NS.SetupInstaller then NS.SetupInstaller() end

	-- Register via LibElvUIPlugin so timing is correct for options
	local EP = _G.LibStub and _G.LibStub("LibElvUIPlugin-1.0", true)
	if EP then
			EP:RegisterPlugin(AddonName, function()
				if NS.InsertOptions then NS.InsertOptions() end
				ColorStatusPluginName()
				EnsureOptionsBranding()
			end)
		-- In case the lib populates after a tiny delay, recolor shortly after
		C_Timer.After(0.1, ColorStatusPluginName)
	else
		-- Fallback if the lib isn't ready: wait for ElvUI_Options to load
		local waiter = CreateFrame("Frame")
		waiter:RegisterEvent("ADDON_LOADED")
		waiter:SetScript("OnEvent", function(_, _, name)
			if name == "ElvUI_Options" then
				if NS.InsertOptions then NS.InsertOptions() end
				ColorStatusPluginName()
				EnsureOptionsBranding()
				waiter:UnregisterAllEvents()
			end
		end)
	end

	-- First-run prompt (only if ElvUI exists)
	E.global.TrenchyUI = E.global.TrenchyUI or {}
	if not E.global.TrenchyUI.installed then
		C_Timer.After(1, function()
			if NS.ShowInstaller then NS.ShowInstaller(true) end
		end)
	end
end

-- Wait for the game to be ready (ElvUI engine available)
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", OnElvUIReady)
