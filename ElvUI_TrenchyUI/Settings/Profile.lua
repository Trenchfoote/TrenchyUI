local E, _, _, P = unpack(ElvUI)

-- Trenchy UI Profile DB
P.ElvUI_TrenchyUI = {
	StyleFilters = {
		Installed = {
			type = "",
			Season = 0,
			Version = 0,
		},
		Seasonal = {
			Expansion = "TWW",
			Season = 3,
			Version = 20250905,
		},
		Common = {
			Expansion = "TWW",
			Season = 3,
			Version = 20250906,
		},
	},
	install_version = nil,
	warpdeplete = {
		forceClassColors = true,
	},
	omnicd = {
		forceCCC = true,
		gapX = 2,
	},
}
