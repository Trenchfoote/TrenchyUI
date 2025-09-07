-- TrenchyUI/Profiles/WarpDeplete.lua
local E = unpack(ElvUI)
local ElvUI_TrenchyUI = E:GetModule('ElvUI_TrenchyUI')
local IsAddOnLoaded = _G.C_AddOns and _G.C_AddOns.IsAddOnLoaded

function ElvUI_TrenchyUI:WarpDeplete()
	if not IsAddOnLoaded("WarpDeplete") then return end

	local DB = _G.WarpDepleteDB
	DB.profiles = DB.profiles or {}
	DB.profileKeys = DB.profileKeys or {}
	local profileName = "TrenchyUI"

	-- If a profile named TrenchyUI already exists in SavedVariables, keep it; otherwise create it based on your SV defaults
	if not DB.profiles[profileName] then
		DB.profiles[profileName] = {
			-- Fonts/textures and sizing
			["bar1Font"] = "Expressway",
			["bar1FontSize"] = 14,
			["bar1Texture"] = "TrenchyBlank",
			["bar2Font"] = "Expressway",
			["bar2FontSize"] = 14,
			["bar2Texture"] = "TrenchyBlank",
			["bar3Font"] = "Expressway",
			["bar3FontSize"] = 14,
			["bar3Texture"] = "TrenchyBlank",
			["forcesFont"] = "Expressway",
			["timerFont"] = "Expressway",
			["objectivesFont"] = "Expressway",
			["deathsFont"] = "Expressway",
			["keyFont"] = "Expressway",
			["keyDetailsFont"] = "Expressway",
			["timerFontSize"] = 30,
			["barHeight"] = 25,
			["barPadding"] = 0.5,
			["barWidth"] = 300,

			-- Positioning/behaviour
			["frameAnchor"] = "TOPRIGHT",
			["frameX"] = 19.39580345153809,
			["frameY"] = -258.8146667480469,
			["verticalOffset"] = 0,
			["objectivesOffset"] = 2,
			["timingsDisplayStyle"] = "hidden",
			["deathLogStyle"] = "count",
			["unclampForcesPercent"] = true,

			-- Colors and style
			["completedObjectivesColor"] = "ff6dffa1",
			["completedForcesColor"] = "ff6dffa1",
			["objectivesColor"] = "ff858585",
			["deathsColor"] = "ffff4f68",
			["keyColor"] = "ffb1b1b1",
			["timerRunningColor"] = "ffff313f",
			["forcesColor"] = "ffc3c3c3",
			["bar1TextureColor"] = "ffff313f",
			["bar2TextureColor"] = "ffff303e",
			["bar3TextureColor"] = "ffff303e",
			["forcesTextureColor"] = "ffff303e",
			["forcesTexture"] = "TrenchyBlank",
			["forcesOverlayTexture"] = "TrenchyBlank",
			["forcesOverlayTextureColor"] = "ffa8a9a2",
			["forcesFormat"] = ":count:/:totalcount: - :percent:",

			-- Hint flag (used by our applier to favor class colors)
			["forceClassColors"] = true,
		}
	else-- Ensure fonts are Expressway even if the profile already existed
		do
			local prof = DB.profiles[profileName]
			if type(prof) == "table" then
				prof.bar1Font = "Expressway"
				prof.bar2Font = "Expressway"
				prof.bar3Font = "Expressway"
				prof.forcesFont = "Expressway"
				prof.timerFont = "Expressway"
				prof.objectivesFont = "Expressway"
				prof.deathsFont = "Expressway"
				prof.keyFont = "Expressway"
				prof.keyDetailsFont = "Expressway"
			end
		end
	end

	-- Set current character to use this profile
	DB.profileKeys[E.mynameRealm] = profileName

	ElvUI_TrenchyUI:WarpDeplete_ApplyClassColors()
	ElvUI_TrenchyUI:Print("WarpDeplete profile applied.")
end
