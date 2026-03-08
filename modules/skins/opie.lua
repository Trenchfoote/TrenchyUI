local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = E:GetModule('Skins')

local pairs, ipairs, unpack = pairs, ipairs, unpack
local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame

local function IsTab(frame)
	for _, region in pairs({ frame:GetRegions() }) do
		if region:IsObjectType('Texture') then
			local atlas = region.GetAtlas and region:GetAtlas()
			if atlas and atlas:find('Options_Tab') then return true end
		end
	end
end

local function SkinDescendants(frame, depth)
	if not frame or depth > 20 then return end

	for _, child in pairs({ frame:GetChildren() }) do
		if child.IsObjectType and not child.TUI_Skinned and not child.TUI_TabSkinned then
			if child:IsObjectType('CheckButton') then
				-- Icon-style buttons (have .tex, .background or .edge)
				if child.tex and type(child.tex) == 'table' and child.tex.IsObjectType
					and child.tex:IsObjectType('Texture') and (child.background or child.edge)
				then
					child.TUI_Skinned = true
					if child.background then child.background:SetAlpha(0) end
					if child.edge then child.edge:SetAlpha(0) end
					if child.tex then
						child.tex:SetTexCoord(unpack(E.TexCoords))
						hooksecurefunc(child.tex, 'SetTexture', function(self)
							self:SetTexCoord(unpack(E.TexCoords))
						end)
					end
					child:SetNormalTexture(0)
					child:SetPushedTexture(0)
					child:SetHighlightTexture(0)
					child:CreateBackdrop()
					if child.backdrop then child.backdrop:SetOutside(child.tex or child) end

				-- Toggle buttons (tall CheckButtons with normal+checked textures)
				elseif child:GetHeight() >= 26 and child:GetCheckedTexture() and child:GetNormalTexture() then
					child.TUI_Skinned = true
					child:StripTextures()
					child:CreateBackdrop('Transparent')
					if child.backdrop then
						child.backdrop:Point('TOPLEFT', 2, -2)
						child.backdrop:Point('BOTTOMRIGHT', -2, 2)
					end
					local function UpdateToggle(self)
						if not self.backdrop then return end
						if self:GetChecked() then
							self.backdrop:SetBackdropBorderColor(1, 0.8, 0, 1)
						else
							local r, g, b = unpack(E.media.bordercolor)
							self.backdrop:SetBackdropBorderColor(r, g, b, 1)
						end
					end
					hooksecurefunc(child, 'SetChecked', UpdateToggle)
					UpdateToggle(child)

				-- Standard checkboxes
				elseif child.Text then
					child.TUI_Skinned = true
					S:HandleCheckBox(child)
				end

			elseif child:IsObjectType('Button') then
				if child:GetObjectType() == 'DropDown' then
					-- Dropdown menus
					child.TUI_Skinned = true
					for _, region in pairs({ child:GetRegions() }) do
						if region:IsObjectType('Texture') then region:SetAlpha(0) end
					end
					for _, method in ipairs({ 'GetNormalTexture', 'GetPushedTexture', 'GetDisabledTexture', 'GetHighlightTexture' }) do
						local tex = child[method] and child[method](child)
						if tex then tex:SetAlpha(0) end
					end
					child:CreateBackdrop('Transparent')
					if child.backdrop then
						child.backdrop:Point('TOPLEFT', 18, -2)
						child.backdrop:Point('BOTTOMRIGHT', -18, 4)
					end
					local arrow = child:CreateTexture(nil, 'OVERLAY')
					arrow:SetTexture(E.Media.Textures.ArrowUp)
					arrow:SetRotation(3.14159)
					arrow:SetSize(12, 12)
					arrow:SetPoint('RIGHT', child.backdrop, 'RIGHT', -4, 0)
					arrow:SetVertexColor(1, 0.8, 0)
					local fs = child:GetFontString()
					if fs then
						fs:ClearAllPoints()
						fs:SetPoint('LEFT', child.backdrop, 'LEFT', 6, 0)
						fs:SetPoint('RIGHT', arrow, 'LEFT', -4, 0)
						fs:SetJustifyH('LEFT')
					end

				elseif IsTab(child) then
					-- Settings tabs
					child.TUI_TabSkinned = true
					for _, region in pairs({ child:GetRegions() }) do
						if region:IsObjectType('Texture') then
							region:SetAlpha(0)
							hooksecurefunc(region, 'SetAtlas', function(self) self:SetAlpha(0) end)
							hooksecurefunc(region, 'SetColorTexture', function(self) self:SetAlpha(0) end)
						end
					end
					child:CreateBackdrop('Transparent')
					if child.backdrop then
						child.backdrop:Point('TOPLEFT', 2, -14)
						child.backdrop:Point('BOTTOMRIGHT', -2, 2)
					end

				elseif child.GetNormalFontObject and child:GetNormalFontObject() then
					local w = child:GetWidth()
					if w and w > 30 then
						child.TUI_Skinned = true
						child:StripTextures()
						S:HandleButton(child)
					elseif w and w <= 30 and child:GetNormalTexture() then
						child.TUI_Skinned = true
						child:SetNormalTexture(0)
						child:SetPushedTexture(0)
						child:SetHighlightTexture(0)
						if child.SetDisabledTexture then child:SetDisabledTexture(0) end
						child:CreateBackdrop('Transparent')
						local arrow = child:CreateTexture(nil, 'OVERLAY')
						arrow:SetTexture(E.Media.Textures.ArrowUp)
						arrow:SetRotation(-1.5708)
						arrow:SetSize(10, 10)
						arrow:SetPoint('CENTER')
						arrow:SetVertexColor(1, 0.8, 0)
					end

				elseif child:GetNormalTexture() then
					local w = child:GetWidth()
					if w and w <= 30 then
						child.TUI_Skinned = true
						child:StripTextures()
						child:SetNormalTexture(0)
						child:SetPushedTexture(0)
						child:SetHighlightTexture(0)
						if child.SetDisabledTexture then child:SetDisabledTexture(0) end
						child:CreateBackdrop('Transparent')
						local arrow = child:CreateTexture(nil, 'OVERLAY')
						arrow:SetTexture(E.Media.Textures.ArrowUp)
						arrow:SetRotation(3.14159)
						arrow:SetSize(10, 10)
						arrow:SetPoint('CENTER')
						arrow:SetVertexColor(1, 0.8, 0)
					end
				end

			elseif child:IsObjectType('Slider') then
				child.TUI_Skinned = true
				S:HandleSliderFrame(child)

			elseif child:IsObjectType('EditBox') then
				child.TUI_Skinned = true
				S:HandleEditBox(child)
			end

			if child.GetRegions then
				for _, region in pairs({ child:GetRegions() }) do
					if region:IsObjectType('Texture') and not region.TUI_Stripped then
						local atlas = region.GetAtlas and region:GetAtlas()
						if atlas == 'Options_InnerFrame' then
							region.TUI_Stripped = true
							region:SetAlpha(0)
						end
					end
				end
			end
		end

		SkinDescendants(child, depth + 1)
	end
end

local function SkinHost()
	local tsf = _G.TenSettingsFrame
	if not tsf then return end

	if tsf.NineSlice then tsf.NineSlice:StripTextures() end
	if tsf.Bg then tsf.Bg:Hide() end
	tsf:StripTextures()
	tsf:SetTemplate('Transparent')

	if tsf.ClosePanelButton then
		S:HandleCloseButton(tsf.ClosePanelButton)
		tsf.ClosePanelButton.TUI_Skinned = true
	end

	for _, key in ipairs({ 'Save', 'Cancel', 'Reset', 'Revert' }) do
		local btn = tsf[key]
		if btn and not btn.TUI_Skinned then
			btn.TUI_Skinned = true
			S:HandleButton(btn)
		end
	end
end

function TUI:InitSkinOPie()
	if not C_AddOns.IsAddOnLoaded('OPie') then return end
	if not self.db or not self.db.profile.addons or not self.db.profile.addons.skinOPie then return end
	if not _G.TenSettingsFrame then return end

	local hostSkinned = false
	local scanner = CreateFrame('Frame')
	scanner:Hide()
	local elapsed = 0
	scanner:SetScript('OnUpdate', function(_, dt)
		elapsed = elapsed + dt
		if elapsed < 1 then return end
		elapsed = 0
		local tsf = _G.TenSettingsFrame
		if not tsf or not tsf:IsShown() then scanner:Hide(); return end
		SkinDescendants(tsf, 0)
	end)

	hooksecurefunc(_G.TenSettingsFrame, 'Show', function()
		if not hostSkinned then hostSkinned = true; SkinHost() end
		SkinDescendants(_G.TenSettingsFrame, 0)
		elapsed = 0
		scanner:Show()
	end)

	_G.TenSettingsFrame:HookScript('OnHide', function() scanner:Hide() end)
end
