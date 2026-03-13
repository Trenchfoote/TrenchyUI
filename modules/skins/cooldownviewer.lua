local E = unpack(ElvUI)
local S = E:GetModule('Skins')

local ipairs = ipairs

local function SkinEditAlert()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.cooldownManager) then return end

	local frame = _G.CooldownViewerSettingsEditAlert
	if not frame then return end

	if frame.BG then frame.BG:Hide() end
	frame:SetTemplate('Transparent')

	if frame.CloseButton then S:HandleCloseButton(frame.CloseButton) end
	if frame.Icon then S:HandleIcon(frame.Icon, true) end

	for _, key in ipairs({ 'TypeDropdown', 'EventDropdown', 'PayloadDropdown' }) do
		local dd = frame[key]
		if dd then S:HandleDropDownBox(dd, dd:GetWidth()) end
	end

	if frame.AddAlertButton then S:HandleButton(frame.AddAlertButton) end
end

S:AddCallbackForAddon('Blizzard_CooldownViewer', 'TUI_CDVEditAlert', SkinEditAlert)
