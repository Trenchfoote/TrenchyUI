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

--This function will handle initialization of the addon
function ElvUI_TrenchyUI:Initialize()
	if not E.db.ElvUI_TrenchyUI.install_version then
		E:GetModule("PluginInstaller"):Queue(ElvUI_TrenchyUI.InstallerData)
	end

	--Insert our options table when ElvUI config is loaded
	local EP = LibStub("LibElvUIPlugin-1.0")
	EP:RegisterPlugin(addon, ElvUI_TrenchyUI.Configtable)
	ElvUI_TrenchyUI:LoadCommands() --add the chat commands
end

--Register module with callback so it gets initialized when ready
local function CallbackInitialize()
	ElvUI_TrenchyUI:Initialize()
end
E:RegisterModule(addon,CallbackInitialize)
