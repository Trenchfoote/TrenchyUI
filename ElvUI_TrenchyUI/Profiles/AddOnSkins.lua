-- TrenchyUI/Profiles/AddOnSkins.lua
local E = unpack(ElvUI)
local ElvUI_TrenchyUI = E:GetModule('ElvUI_TrenchyUI')
local IsAddOnLoaded = _G.C_AddOns and _G.C_AddOns.IsAddOnLoaded

function ElvUI_TrenchyUI:AddOnSkins()
	if not IsAddOnLoaded("AddOnSkins") then return end

	local AS = unpack(_G.AddOnSkins)

	AS.db.Font = "Expressway"
	AS.db.FontSize = 14
	AS.db.Shadows = false
	AS.db.CropIcons = false
	AS.db.BackgroundTexture = "TrenchyBlank"
	AS.db.ElvUIStyle = false
	AS.db.StatusBarTexture = "TrenchyBlank"
	AS.db.ZygorGuidesViewer = false
	AS.db.FontFlag = "SHADOWOUTLINE"
end
