-- TrenchyUI/Core/Profile.lua
-- Purpose: Centralize ElvUI Distributor imports (profile/private/global/nameplate filters)
-- This helps future-proof the installer if ElvUI changes import sequencing.

local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}

local E
local BRAND_HEX = "ff2f3d"
local BRAND     = "|cff"..BRAND_HEX.."TrenchyUI|r"

-- Desired UI scale for TrenchyUI
NS.UIScale = NS.UIScale or 0.53

-- Import strings can be populated later (e.g., generated exports). Keep empty by default.
NS.ProfileStrings = NS.ProfileStrings or {
	profile           = "",
	private           = "",
	global            = "",
	nameplatefilters  = "",
}

-- Contract:
-- inputs: optional table with overrides { profile, private, global, nameplatefilters }
-- returns: true if any import succeeded, false if Distributor missing or all empty
function NS.ImportProfileStrings(overrides)
	local engine = _G and rawget(_G, "ElvUI")
	if not (engine and engine[1]) then return false end
	E = engine[1]

	local D = E and E:GetModule('Distributor')
	if not D or not D.ImportProfile then
		print(BRAND..": ElvUI Distributor module not found; skipping profile import.")
		return false
	end

	local S = NS.ProfileStrings
	if overrides then
		if overrides.profile ~= nil          then S.profile = overrides.profile end
		if overrides.private ~= nil          then S.private = overrides.private end
		if overrides.global ~= nil           then S.global = overrides.global end
		if overrides.nameplatefilters ~= nil then S.nameplatefilters = overrides.nameplatefilters end
	end

	local any = false
	-- Import order typically: private -> nameplate filters -> profile -> global
	if S.private and S.private ~= ""          then D:ImportProfile(S.private); any = true end
	if S.nameplatefilters and S.nameplatefilters ~= "" then D:ImportProfile(S.nameplatefilters); any = true end
	if S.profile and S.profile ~= ""          then D:ImportProfile(S.profile); any = true end
	if S.global and S.global ~= ""            then D:ImportProfile(S.global); any = true end

	return any
end

-- Optional utility: set UI scale after import if provided
function NS.ApplyUIScaleAfterImport(scale)
	local engine = _G and rawget(_G, "ElvUI")
	if not (engine and engine[1]) or not scale then return end
	E = engine[1]
	E.global = E.global or {}
	E.global.general = E.global.general or {}
	E.global.general.UIScale = scale
end
