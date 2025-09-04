-- TrenchyUI/Core/Core.lua
local AddonName, NS = ...
local E, L, V, P, G
local _G = _G

-- ===== Branding =====
local BRAND_HEX = "ff2f3d"
local BRAND     = "|cff"..BRAND_HEX.."TrenchyUI|r"

-- Safe trim (older clients compat)
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- ===== Slash Command =====
if type(SLASH_TRENCHYUI1) ~= "string" then SLASH_TRENCHYUI1 = "/trenchyui" end
SlashCmdList = SlashCmdList or {}
local function TrenchyUI_SlashHandler(msg)
	msg = trim((msg or ""):lower())
	if msg == "install" then
		if NS.ShowInstaller then
			NS.ShowInstaller(true)
		else
			print(BRAND..": Installer not ready. Is ElvUI loaded?")
		end
	else
		print(BRAND..": use |cffffff00/trenchyui install|r")
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

	-- Lib registry (commonly used for the Plugins list)
	if EP and EP.plugins and EP.plugins[AddonName] then
		EP.plugins[AddonName].name = BRAND
	end

	-- Some builds mirror into E.plugins
	if NS.E.plugins and NS.E.plugins[AddonName] then
		NS.E.plugins[AddonName].name = BRAND
	end
end

-- ===== Options Injection (ElvUI -> Plugins + Top-Level) =====
local function BuildOptions()
	local function OpenInstaller()
		if NS.ShowInstaller then NS.ShowInstaller(true)
		else print(BRAND..": Installer not ready. Is ElvUI loaded?") end
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
		info    = {
			order = 6, type = "description",
			name  = "Layouts: |cff00ff88DPS/Tank|r (ready)  •  |cffff4444Healer|r (WIP)"
		},
	}

	return {
		order = 50,
		type  = "group",
		name  = BRAND,  -- colored in the tree
		args  = groupArgs,
	}, groupArgs
end

local function InsertOptions()
	if not (E and E.Options and E.Options.args) then return end

	local pluginGroup, sharedArgs = BuildOptions()

	-- Under Plugins category (if present)
	if E.Options.args.plugins and E.Options.args.plugins.args then
		E.Options.args.plugins.args.trenchyui = pluginGroup
	end

	-- Also add a top-level entry (like AddOnSkins / PA / Tinker Toolbox)
	E.Options.args.trenchyui = {
		order = 95, type = "group", name = BRAND, args = sharedArgs
	}

	-- Ensure Estatus list shows our colored name
	ColorStatusPluginName()
end

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
		EP:RegisterPlugin(AddonName, InsertOptions)
		-- In case the lib populates after a tiny delay, recolor shortly after
		C_Timer.After(0.1, ColorStatusPluginName)
	else
		-- Fallback if the lib isn't ready: wait for ElvUI_Options to load
		local waiter = CreateFrame("Frame")
		waiter:RegisterEvent("ADDON_LOADED")
		waiter:SetScript("OnEvent", function(_, _, name)
			if name == "ElvUI_Options" then
				InsertOptions()
				ColorStatusPluginName()
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
