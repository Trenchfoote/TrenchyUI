local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = E:GetModule('Skins')

local pairs, ipairs = pairs, ipairs
local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded

local skinned = false

local function SkinBugSack()
	local frame = _G.BugSackFrame
	if not frame or skinned then return end
	skinned = true

	frame:StripTextures()
	frame:SetTemplate('Transparent')

	local close
	for _, child in pairs({ frame:GetChildren() }) do
		if child:IsObjectType('Button') and child.GetNormalTexture then
			local tex = child:GetNormalTexture()
			if tex then
				local atlas = tex:GetAtlas()
				if atlas and atlas:find('RedButton') then close = child; break end
			end
		end
	end
	if not close then
		for _, child in pairs({ frame:GetChildren() }) do
			if child:IsObjectType('Button') and child:GetNumRegions() > 0 then
				if child:GetPoint(1) == 'TOPRIGHT' then close = child; break end
			end
		end
	end
	if close then S:HandleCloseButton(close) end

	if _G.BugSackNextButton then S:HandleButton(_G.BugSackNextButton) end
	if _G.BugSackPrevButton then S:HandleButton(_G.BugSackPrevButton) end
	if _G.BugSackSendButton then S:HandleButton(_G.BugSackSendButton) end

	local scroll = _G.BugSackScroll
	if scroll then S:HandleScrollBar(_G.BugSackScrollScrollBar or scroll.ScrollBar) end

	if _G.BugSackScrollText then _G.BugSackScrollText:SetTextColor(1, 1, 1) end

	for _, child in pairs({ frame:GetChildren() }) do
		if child:IsObjectType('EditBox') then S:HandleEditBox(child) end
	end

	for _, name in ipairs({ 'BugSackTabAll', 'BugSackTabSession', 'BugSackTabLast' }) do
		local tab = _G[name]
		if tab then S:HandleTab(tab) end
	end
end

function TUI:InitSkinBugSack()
	if not C_AddOns_IsAddOnLoaded('BugSack') then return end
	if not self.db or not self.db.profile.addons or not self.db.profile.addons.skinBugSack then return end
	local bs = _G.BugSack
	if not bs then return end

	hooksecurefunc(bs, 'OpenSack', SkinBugSack)
end
