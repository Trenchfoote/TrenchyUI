-- TrenchyUI/Core/Core.lua
local E = unpack(ElvUI)
local ElvUI_TrenchyUI = E:GetModule('ElvUI_TrenchyUI')

-- ElvUI_TrenchyUI print
function ElvUI_TrenchyUI:Print(msg)
	print(ElvUI_TrenchyUI.Title..': '..msg)
end

function ElvUI_TrenchyUI:LoadCommands()
	self:RegisterChatCommand('trenchyui', 'RunCommands')
end

function ElvUI_TrenchyUI:RunCommands(msg)
	if msg == 'installer' or msg == 'install' or msg == 'setup' then
		E:GetModule('PluginInstaller'):Queue(ElvUI_TrenchyUI.InstallerData)
	elseif msg == "config" or msg == "options" or msg == "ui" or msg == "" then
		if not InCombatLockdown() then
			E:ToggleOptions("ElvUI_TrenchyUI")
		end
	else
		ElvUI_TrenchyUI:Print("use |cffffff00/trenchyui|r or |cffffff00/trenchyui install|r")
	end
end
