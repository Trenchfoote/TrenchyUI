local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = E:GetModule('Skins')

local hooksecurefunc = hooksecurefunc
local pairs, ipairs, next, unpack = pairs, ipairs, next, unpack

local function SkinInset(frame)
	if not frame then return end
	if frame.Bg then frame.Bg:Hide() end
	if frame.NineSlice then frame.NineSlice:StripTextures() end
	frame:SetTemplate('Transparent')
end

local function SkinResultsListing(frame)
	if not frame then return end
	if frame.ScrollArea and frame.ScrollArea.ScrollBar then
		S:HandleTrimScrollBar(frame.ScrollArea.ScrollBar)
	end
	if not frame.HeaderContainer then return end

	local function HandleHeaders()
		local max = frame.HeaderContainer:GetNumChildren()
		for i, h in next, { frame.HeaderContainer:GetChildren() } do
			if not h.IsSkinned then
				h:DisableDrawLayer('BACKGROUND')
				if not h.backdrop then h:CreateBackdrop('Transparent') end
				h.IsSkinned = true
			end
			if h.backdrop then h.backdrop:Point('BOTTOMRIGHT', i < max and -5 or 0, -2) end
		end
	end

	if frame.OnShow then hooksecurefunc(frame, 'OnShow', HandleHeaders) end
	HandleHeaders()
end

local function SkinItemButton(btn)
	if not btn or btn.TUI_Skinned then return end
	btn.TUI_Skinned = true
	if btn.EmptySlot then btn.EmptySlot:Hide() end
	if btn.IconBorder then btn.IconBorder:SetAlpha(0) end
	if btn.IconSelectedHighlight then btn.IconSelectedHighlight:SetAlpha(0) end

	if btn.SetItemInfo then
		hooksecurefunc(btn, 'SetItemInfo', function(self)
			if self.IconBorder then self.IconBorder:SetAlpha(0) end
			if self.IconSelectedHighlight then self.IconSelectedHighlight:SetAlpha(0) end
			if self.EmptySlot then self.EmptySlot:Hide() end
		end)
	end

	btn:SetPushedTexture(0)
	btn:SetHighlightTexture(0)
	if btn.Icon then
		S:HandleIcon(btn.Icon, true)
		btn.Icon:SetInside(btn)
	end
end

local function SkinMoneyInput(frame)
	if not frame or not frame.MoneyInput then return end
	local mi = frame.MoneyInput
	for _, key in ipairs({ 'GoldBox', 'SilverBox', 'CopperBox' }) do
		if mi[key] then S:HandleEditBox(mi[key]) end
	end
end

local function SkinMinMaxInput(frame)
	if not frame then return end
	if frame.MinBox then S:HandleEditBox(frame.MinBox) end
	if frame.MaxBox then S:HandleEditBox(frame.MaxBox) end
end

local function SkinIconAndName(frame)
	if not frame or frame.TUI_Skinned then return end
	frame.TUI_Skinned = true
	if frame.Icon then S:HandleIcon(frame.Icon, true) end
	if frame.QualityBorder then frame.QualityBorder:SetAlpha(0) end
end

local function SkinDropDownContainer(container)
	if not container then return end
	local dd = container.DropDown
	if dd and dd.DropDown then S:HandleDropDownBox(dd.DropDown)
	elseif dd then S:HandleDropDownBox(dd) end
end

local function SkinDialog(dialog)
	if not dialog or dialog.TUI_Skinned then return end
	dialog.TUI_Skinned = true
	if dialog.NineSlice then dialog.NineSlice:StripTextures() end
	dialog:StripTextures()
	dialog:SetTemplate('Transparent')
	for _, key in ipairs({ 'acceptButton', 'cancelButton', 'altButton' }) do
		if dialog[key] then S:HandleButton(dialog[key]) end
	end
	if dialog.editBox then S:HandleEditBox(dialog.editBox) end
end

local function SkinPanel(panel)
	if not panel or panel.TUI_Skinned then return end
	panel.TUI_Skinned = true
	panel:StripTextures()
	if panel.Border then panel.Border:StripTextures() end
	panel:SetTemplate('Transparent')
	if panel.Inset then SkinInset(panel.Inset) end
	if panel.ScrollBar then S:HandleTrimScrollBar(panel.ScrollBar) end
	if panel.CloseDialog then S:HandleCloseButton(panel.CloseDialog) end
	for _, child in pairs({ panel:GetChildren() }) do
		if child:IsObjectType('Button') and not child.IsSkinned then S:HandleButton(child) end
	end
end

local function SkinSearchOptions(dialog)
	if not dialog or dialog.TUI_Skinned then return end
	dialog.TUI_Skinned = true
	dialog:StripTextures()
	dialog:SetTemplate('Transparent')
	if dialog.Inset then SkinInset(dialog.Inset) end
	if dialog.CloseButton then S:HandleCloseButton(dialog.CloseButton) end

	local sc = dialog.SearchContainer
	if sc then
		if sc.SearchString then S:HandleEditBox(sc.SearchString) end
		if sc.IsExact then S:HandleCheckBox(sc.IsExact) end
	end

	if dialog.FilterKeySelector then
		for _, child in pairs({ dialog.FilterKeySelector:GetChildren() }) do
			if child.IsObjectType and child:IsObjectType('DropdownButton') then S:HandleDropDownBox(child) end
		end
	end

	for _, key in ipairs({ 'LevelRange', 'ItemLevelRange', 'PriceRange', 'CraftedLevelRange' }) do
		SkinMinMaxInput(dialog[key])
	end

	if dialog.PurchaseQuantity and dialog.PurchaseQuantity.InputBox then
		S:HandleEditBox(dialog.PurchaseQuantity.InputBox)
	end

	for _, key in ipairs({ 'QualityContainer', 'ExpansionContainer', 'TierContainer' }) do
		SkinDropDownContainer(dialog[key])
	end

	for _, key in ipairs({ 'Finished', 'Cancel', 'ResetAllButton' }) do
		if dialog[key] then S:HandleButton(dialog[key]) end
	end
end

local function SkinConfigWidgets(frame, depth)
	if not frame or (depth or 0) > 10 then return end
	for _, child in pairs({ frame:GetChildren() }) do
		if not child.TUI_Skinned then
			if child:IsObjectType('CheckButton') then
				child.TUI_Skinned = true
				S:HandleCheckBox(child)
			elseif child:IsObjectType('EditBox') then
				child.TUI_Skinned = true
				S:HandleEditBox(child)
			elseif child:IsObjectType('Button') and not child:GetName() then
				child.TUI_Skinned = true
				S:HandleButton(child)
			end
			if child.InputBox and not child.InputBox.TUI_Skinned then
				child.InputBox.TUI_Skinned = true
				S:HandleEditBox(child.InputBox)
			end
			if child.CheckBox and not child.CheckBox.TUI_Skinned then
				child.CheckBox.TUI_Skinned = true
				S:HandleCheckBox(child.CheckBox)
			end
			if child.RadioButton and not child.RadioButton.TUI_Skinned then
				child.RadioButton.TUI_Skinned = true
				S:HandleCheckBox(child.RadioButton)
			end
		end
		SkinConfigWidgets(child, (depth or 0) + 1)
	end
end

local function SkinAll()
	local tabContainer = _G.AuctionatorAHTabsContainer
	if tabContainer and tabContainer.Tabs then
		for _, tab in ipairs(tabContainer.Tabs) do
			if not tab.backdrop then S:HandleTab(tab) end
		end
	end

	local shop = _G.AuctionatorShoppingFrame
	if shop then
		shop:StripTextures()

		local s = shop.SearchOptions
		if s then
			if s.SearchString then S:HandleEditBox(s.SearchString) end
			for _, key in ipairs({ 'SearchButton', 'MoreButton', 'AddToListButton' }) do
				if s[key] then S:HandleButton(s[key]) end
			end
			if s.ResetSearchStringButton then S:HandleCloseButton(s.ResetSearchStringButton) end
		end

		for _, key in ipairs({ 'ListsContainer', 'RecentsContainer' }) do
			local c = shop[key]
			if c then
				if c.ScrollBar then S:HandleTrimScrollBar(c.ScrollBar) end
				if c.Inset then SkinInset(c.Inset) end
			end
		end

		if shop.ContainerTabs then
			for _, key in ipairs({ 'ListsTab', 'RecentsTab' }) do
				local tab = shop.ContainerTabs[key]
				if tab and not tab.backdrop then
					tab:StripTextures()
					tab:CreateBackdrop('Transparent')
					tab.backdrop:Point('TOPLEFT', 3, -8)
					tab.backdrop:Point('BOTTOMRIGHT', -3, 3)
				end
			end
		end

		SkinResultsListing(shop.ResultsListing)
		SkinInset(shop.ShoppingResultsInset)

		for _, key in ipairs({ 'NewListButton', 'ExportButton', 'ImportButton', 'ExportCSV' }) do
			if shop[key] then S:HandleButton(shop[key]) end
		end
	end

	local sell = _G.AuctionatorSellingFrame
	if sell then
		local sale = sell.SaleItemFrame
		if sale then
			SkinItemButton(sale.Icon)
			if sale.Quantity and sale.Quantity.InputBox then S:HandleEditBox(sale.Quantity.InputBox) end
			if sale.MaxButton then S:HandleButton(sale.MaxButton) end
			SkinMoneyInput(sale.Price)
			SkinMoneyInput(sale.BidPrice)

			if sale.Duration then
				for _, child in pairs({ sale.Duration:GetChildren() }) do
					if child:IsObjectType('CheckButton') then S:HandleCheckBox(child) end
				end
			end

			for _, key in ipairs({ 'PostButton', 'SkipButton', 'PrevButton' }) do
				if sale[key] then S:HandleButton(sale[key]) end
			end

			for _, child in pairs({ sale:GetChildren() }) do
				if child:IsObjectType('Button') and not child:GetName() and not child.IsSkinned then
					local w = child:GetWidth()
					if w and w <= 30 then
						S:HandleButton(child)
						child:Size(22)
					end
				end
			end
		end

		SkinInset(sell.BagInset)

		local bagView = sell.BagListing and sell.BagListing.View
		if bagView then
			if bagView.ScrollBar then S:HandleTrimScrollBar(bagView.ScrollBar) end
			local itemMixin = _G.AuctionatorGroupsViewItemMixin
			if itemMixin and not itemMixin.TUI_Hooked then
				itemMixin.TUI_Hooked = true
				hooksecurefunc(itemMixin, 'SetItemInfo', function(self) SkinItemButton(self) end)
			end
		end

		local groupMixin = _G.AuctionatorGroupsViewGroupMixin
		if groupMixin and not groupMixin.TUI_Hooked then
			groupMixin.TUI_Hooked = true
			hooksecurefunc(groupMixin, 'SetName', function(self)
				local btn = self.GroupTitle
				if btn and not btn.TUI_Skinned then
					btn.TUI_Skinned = true
					btn:StripTextures()
					btn:CreateBackdrop('Transparent')
				end
			end)
		end

		for _, key in ipairs({ 'CurrentPricesListing', 'HistoricalPriceListing', 'PostingHistoryListing' }) do
			SkinResultsListing(sell[key])
		end
		SkinInset(sell.HistoricalPriceInset)

		local pt = sell.PricesTabsContainer
		if pt then
			for _, key in ipairs({ 'CurrentPricesTab', 'PriceHistoryTab', 'YourHistoryTab' }) do
				if pt[key] then S:HandleTab(pt[key]) end
			end
		end
	end

	local cancel = _G.AuctionatorCancellingFrame
	if cancel then
		if cancel.SearchFilter then S:HandleEditBox(cancel.SearchFilter) end
		SkinResultsListing(cancel.ResultsListing)
		SkinInset(cancel.HistoricalPriceInset)

		local usc = cancel.UndercutScanContainer
		if usc then
			for _, key in ipairs({ 'CancelNextButton', 'StartScanButton' }) do
				if usc[key] then S:HandleButton(usc[key]) end
			end
		end
	end

	SkinConfigWidgets(_G.AuctionatorConfigFrame)

	local ikcMixin = _G.AuctionatorItemKeyCellTemplateMixin
	if ikcMixin and not ikcMixin.TUI_Hooked then
		ikcMixin.TUI_Hooked = true
		hooksecurefunc(ikcMixin, 'Populate', function(self)
			if self.IconBorder then self.IconBorder:SetAlpha(0) end
			if self.Icon and not self.Icon.TUI_TexCoord then
				self.Icon:SetTexCoord(unpack(E.TexCoords))
				self.Icon.TUI_TexCoord = true
			end
		end)
	end

	local D = Auctionator and Auctionator.Dialogs
	if D then
		for _, fn in ipairs({ 'ShowEditBox', 'ShowConfirm', 'ShowConfirmAlt', 'ShowMoney' }) do
			if D[fn] then
				hooksecurefunc(D, fn, function()
					for i = 1, 20 do
						local dlg = _G['AuctionatorDialog' .. i]
						if dlg then SkinDialog(dlg) else break end
					end
				end)
			end
		end
	end

	if shop then
		for _, key in ipairs({ 'exportDialog', 'importDialog', 'exportCSVDialog', 'itemHistoryDialog' }) do
			SkinPanel(shop[key])
		end
		SkinSearchOptions(shop.itemDialog)
	end
	SkinPanel(_G.AuctionatorExportListFrame)
	SkinPanel(_G.AuctionatorImportListFrame)
	SkinPanel(_G.AuctionatorItemHistoryFrame)
	SkinSearchOptions(_G.AuctionatorShoppingTabItemFrame)

	if _G.AuctionHouseFrame then
		hooksecurefunc(_G.AuctionHouseFrame, 'SetDisplayMode', function()
			for _, child in pairs({ _G.AuctionHouseFrame:GetChildren() }) do
				if child.NineSlice and child:GetFrameStrata() == 'DIALOG' and not child.IsSkinned then
					child.NineSlice:StripTextures()
					child:StripTextures()
					child:SetTemplate('Transparent')
					for _, c in pairs({ child:GetChildren() }) do
						if c:IsObjectType('Button') and not c.IsSkinned then S:HandleButton(c) end
					end
					if child.IconAndName then SkinIconAndName(child.IconAndName) end
					child.IsSkinned = true
				end
				if child.IconAndName and not child.TUI_Skinned then
					SkinIconAndName(child.IconAndName)
					if child.Inset then SkinInset(child.Inset) end
					for _, c in pairs({ child:GetChildren() }) do
						if c:IsObjectType('Button') and not c.IsSkinned then S:HandleButton(c) end
					end
					if child.ResultsListing then SkinResultsListing(child.ResultsListing) end
					child.TUI_Skinned = true
				end
			end
		end)
	end
end

function TUI:InitSkinAuctionator()
	if not self.db or not self.db.profile.addons or not self.db.profile.addons.skinAuctionator then return end
	if not C_AddOns.IsAddOnLoaded('Auctionator') then return end
	if not AuctionatorAHFrameMixin then return end

	local skinned = false
	hooksecurefunc(AuctionatorAHFrameMixin, 'OnShow', function()
		if skinned then return end
		if not _G.AuctionatorShoppingFrame then return end
		skinned = true
		SkinAll()
	end)
end
