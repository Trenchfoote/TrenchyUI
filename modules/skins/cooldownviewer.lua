local E = unpack(ElvUI)
local S = E:GetModule('Skins')

local ipairs, next = ipairs, next

local function SkinSettingsBarItem(item)
	if item.TUI_BarSkinned then return end
	item.TUI_BarSkinned = true

	for _, child in next, { item:GetChildren() } do
		if child:IsObjectType('StatusBar') then
			local tex = child:GetStatusBarTexture()
			if tex then
				tex:SetTexture(E.media.normTex)
				if tex.ClearTextureSlice then tex:ClearTextureSlice() end
				if tex.SetTextureSliceMode then tex:SetTextureSliceMode(0) end
			end

			for _, region in next, { child:GetRegions() } do
				if region:IsObjectType('Texture') then
					local atlas = region:GetAtlas()
					if atlas == 'UI-HUD-CoolDownManager-Bar-BG' and not region.backdrop then
						region:StripTextures()
						region:CreateBackdrop('Transparent', nil, true)
						region.backdrop:SetOutside()
					elseif atlas == 'UI-HUD-CoolDownManager-Bar' then
						region:Point('TOPLEFT', 1, 0)
						region:Point('BOTTOMLEFT', -1, 0)
					end
				end
			end
			break
		end
	end
end

local hookedBarPools = {}

local function SkinSettingsBarItems()
	local viewer = _G.CooldownViewerSettings
	if not viewer or not viewer.CooldownScroll then return end

	local content = viewer.CooldownScroll.Content
	if not content then return end

	for _, category in next, { content:GetChildren() } do
		local pool = category.itemPool
		if pool and not hookedBarPools[pool] then
			for frame in pool:EnumerateActive() do
				SkinSettingsBarItem(frame)
			end

			local hasBarItems = false
			for frame in pool:EnumerateActive() do
				for _, child in next, { frame:GetChildren() } do
					if child:IsObjectType('StatusBar') then hasBarItems = true; break end
				end
				break
			end

			if hasBarItems then
				hookedBarPools[pool] = true
				hooksecurefunc(pool, 'Acquire', function(p)
					for frame in p:EnumerateActive() do
						SkinSettingsBarItem(frame)
					end
				end)
			end
		end
	end
end

local function SkinCooldownViewer()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.cooldownManager) then return end

	-- Edit Alert dialog
	local editAlert = _G.CooldownViewerSettingsEditAlert
	if editAlert then
		if editAlert.BG then editAlert.BG:Hide() end
		editAlert:SetTemplate('Transparent')

		if editAlert.CloseButton then S:HandleCloseButton(editAlert.CloseButton) end
		if editAlert.Icon then S:HandleIcon(editAlert.Icon, true) end

		for _, key in ipairs({ 'TypeDropdown', 'EventDropdown', 'PayloadDropdown' }) do
			local dd = editAlert[key]
			if dd then S:HandleDropDownBox(dd, dd:GetWidth()) end
		end

		if editAlert.AddAlertButton then S:HandleButton(editAlert.AddAlertButton) end
	end

	-- Settings panel bar items
	local viewer = _G.CooldownViewerSettings
	if viewer then
		SkinSettingsBarItems()
		hooksecurefunc(viewer, 'RefreshLayout', SkinSettingsBarItems)
	end
end

S:AddCallbackForAddon('Blizzard_CooldownViewer', 'TUI_SkinCooldownViewer', SkinCooldownViewer)
