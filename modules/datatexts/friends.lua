local E = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local format, sort, wipe, ipairs, next = format, sort, wipe, ipairs, next
local BNConnected = BNConnected
local BNGetNumFriends = BNGetNumFriends
local GetQuestDifficultyColor = GetQuestDifficultyColor
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local ToggleFriendsFrame = ToggleFriendsFrame

local GetFriendAccountInfo = C_BattleNet.GetFriendAccountInfo
local GetFriendGameAccountInfo = C_BattleNet.GetFriendGameAccountInfo
local GetFriendNumGameAccounts = C_BattleNet.GetFriendNumGameAccounts
local BNet_GetValidatedCharacterName = BNet_GetValidatedCharacterName
local C_FriendList_GetNumFriends = C_FriendList.GetNumFriends
local C_FriendList_GetNumOnlineFriends = C_FriendList.GetNumOnlineFriends
local C_FriendList_GetFriendInfoByIndex = C_FriendList.GetFriendInfoByIndex
local C_PartyInfo_InviteUnit = C_PartyInfo.InviteUnit
local ChatFrame_SendBNetTell = (ChatFrameUtil and ChatFrameUtil.SendBNetTell) or ChatFrame_SendBNetTell
local BNInviteFriend = BNInviteFriend

local FRIENDS = _G.FRIENDS
local WOW_PROJECT_ID = WOW_PROJECT_ID
local wowString = _G.BNET_CLIENT_WOW
local battleNetString = _G.BATTLENET_OPTIONS_LABEL

local friendTable, bnTable = {}, {}
local clientGroups, clientOrder = {}, {}
local displayString = ''
local dataValid = false

local clientTags = {
	WoW  = { index = 1,  tag = 'WoW' },
	WTCG = { index = 2,  tag = 'HS' },
	Hero = { index = 3,  tag = 'HotS' },
	Pro  = { index = 4,  tag = 'OW' },
	OSI  = { index = 5,  tag = 'D2' },
	D3   = { index = 6,  tag = 'D3' },
	Fen  = { index = 7,  tag = 'D4' },
	ANBS = { index = 8,  tag = 'DI' },
	S1   = { index = 9,  tag = 'SC' },
	S2   = { index = 10, tag = 'SC2' },
	W3   = { index = 11, tag = 'WC3' },
	RTRO = { index = 12, tag = 'AC' },
	WLBY = { index = 13, tag = 'CB4' },
	VIPR = { index = 14, tag = 'BO4' },
	ODIN = { index = 15, tag = 'WZ' },
	AUKS = { index = 16, tag = 'WZ2' },
	LAZR = { index = 17, tag = 'MW2' },
	ZEUS = { index = 18, tag = 'CW' },
	FORE = { index = 19, tag = 'VG' },
	GRY  = { index = 20, tag = 'AR' },
	App  = { index = 21, tag = 'App' },
	BSAp = { index = 22, tag = 'Mobile' },
}

local ROW_HEIGHT = 16
local ROW_PAD = 2
local TOOLTIP_PAD = 8
local MAX_ROWS = 30

local statusText = {
	AFK = ' |cffFF9900AFK|r',
	DND = ' |cffFF3333DND|r',
}

local activezone = { r = 0.3, g = 1.0, b = 0.3 }
local inactivezone = { r = 0.65, g = 0.65, b = 0.65 }

-- Tooltip frame and rows
local tooltip, headerText
local rows = {}
local hideTimer
local ownerPanel

local function CancelHide()
	if hideTimer then hideTimer:Cancel(); hideTimer = nil end
end

local function ScheduleHide()
	CancelHide()
	hideTimer = C_Timer.NewTimer(0.15, function()
		hideTimer = nil
		if tooltip then tooltip:Hide() end
	end)
end

local function InGroup(name, realmName)
	if realmName and realmName ~= '' and realmName ~= E.myrealm then
		name = name .. '-' .. realmName
	end
	return (UnitInParty(name) or UnitInRaid(name)) and ' |cffaaaaaa*|r' or ''
end

local function GetPanelAnchor(panel)
	local parent = panel:GetParent()
	return parent and parent.anchor or 'ANCHOR_TOP', parent and parent.xOff or 0, parent and parent.yOff or 0
end

local function AnchorToPanel(tt, panel)
	local anchor, xOff, yOff = GetPanelAnchor(panel)
	tt:ClearAllPoints()
	if anchor == 'ANCHOR_TOP' or anchor == 'ANCHOR_TOPLEFT' or anchor == 'ANCHOR_TOPRIGHT' then
		tt:SetPoint('BOTTOM', panel, 'TOP', xOff, 4 + yOff)
	elseif anchor == 'ANCHOR_BOTTOM' or anchor == 'ANCHOR_BOTTOMLEFT' or anchor == 'ANCHOR_BOTTOMRIGHT' then
		tt:SetPoint('TOP', panel, 'BOTTOM', xOff, -4 + yOff)
	elseif anchor == 'ANCHOR_LEFT' then
		tt:SetPoint('RIGHT', panel, 'LEFT', -4 + xOff, yOff)
	elseif anchor == 'ANCHOR_RIGHT' then
		tt:SetPoint('LEFT', panel, 'RIGHT', 4 + xOff, yOff)
	else
		tt:SetPoint('BOTTOM', panel, 'TOP', xOff, 4 + yOff)
	end
end

local function AnchorHoverTooltip(hoverTT, customTT)
	hoverTT:ClearAllPoints()
	hoverTT:SetPoint('TOPLEFT', customTT, 'TOPRIGHT', 2, 0)
end

local function BuildFriendTable(total)
	wipe(friendTable)
	for i = 1, total do
		local info = C_FriendList_GetFriendInfoByIndex(i)
		if info and info.connected then
			local className = E:UnlocalizedClassName(info.className) or ''
			local status = (info.afk and statusText.AFK) or (info.dnd and statusText.DND) or ''
			friendTable[#friendTable + 1] = {
				name = info.name,
				level = info.level,
				class = className,
				zone = info.area or '',
				status = status,
			}
		end
	end
	sort(friendTable, function(a, b) return a.name < b.name end)
end

local function ClientSortFunc(a, b)
	local A, B = clientTags[a], clientTags[b]
	if A and B then return A.index < B.index end
	return a < b
end

local function BNSortFunc(a, b)
	if a.client and b.client and a.client == b.client and a.client == wowString then
		if a.name and b.name then return a.name < b.name end
	end
	return (a.accountName or '') < (b.accountName or '')
end

local function BuildBNTable(total)
	wipe(bnTable)
	for _, v in next, clientGroups do wipe(v) end
	wipe(clientOrder)

	for i = 1, total do
		local accountInfo = GetFriendAccountInfo(i)
		local gameInfo = accountInfo and accountInfo.gameAccountInfo
		if gameInfo and gameInfo.isOnline then
			local client = gameInfo.clientProgram
			local status = (accountInfo.isAFK and statusText.AFK) or (accountInfo.isDND and statusText.DND) or ''
			local charName = BNet_GetValidatedCharacterName(gameInfo.characterName, accountInfo.battleTag, client) or ''
			local className = E:UnlocalizedClassName(gameInfo.className) or ''

			-- Check additional game accounts for a better WoW character
			local numAccounts = GetFriendNumGameAccounts(i)
			if numAccounts and numAccounts > 1 then
				for y = 1, numAccounts do
					local other = GetFriendGameAccountInfo(i, y)
					if other and other.clientProgram == wowString and other.wowProjectID == WOW_PROJECT_ID then
						client = wowString
						charName = BNet_GetValidatedCharacterName(other.characterName, accountInfo.battleTag, wowString) or ''
						className = E:UnlocalizedClassName(other.className) or ''
						gameInfo = other
						break
					end
				end
			end

			local entry = {
				accountName = accountInfo.accountName,
				battleTag = accountInfo.battleTag,
				name = charName,
				level = gameInfo.characterLevel or 0,
				class = className,
				zone = gameInfo.areaName or '',
				realmName = gameInfo.realmName or '',
				client = client,
				status = status,
				gameID = gameInfo.gameAccountID,
				isWoW = client == wowString,
				wowProjectID = gameInfo.wowProjectID,
			}

			bnTable[#bnTable + 1] = entry

			if not clientGroups[client] then
				clientGroups[client] = {}
				clientOrder[#clientOrder + 1] = client
			end
			clientGroups[client][#clientGroups[client] + 1] = entry
		end
	end

	sort(clientOrder, ClientSortFunc)
	for _, group in next, clientGroups do
		sort(group, BNSortFunc)
	end
end

local function CreateTooltip()
	if tooltip then return end

	tooltip = CreateFrame('Frame', 'TUIFriendsTooltip', E.UIParent, 'BackdropTemplate')
	tooltip:SetFrameStrata('TOOLTIP')
	tooltip:SetClampedToScreen(true)
	tooltip:Hide()
	tooltip:SetTemplate('Transparent')

	tooltip:SetScript('OnEnter', CancelHide)
	tooltip:SetScript('OnLeave', ScheduleHide)

	headerText = tooltip:CreateFontString(nil, 'OVERLAY')
	headerText:SetPoint('TOPLEFT', tooltip, 'TOPLEFT', TOOLTIP_PAD, -TOOLTIP_PAD)
	headerText:SetPoint('TOPRIGHT', tooltip, 'TOPRIGHT', -TOOLTIP_PAD, -TOOLTIP_PAD)
	headerText:FontTemplate(nil, 13, 'OUTLINE')
	headerText:SetJustifyH('LEFT')
end

local function GetOrCreateRow(index)
	if rows[index] then return rows[index] end

	CreateTooltip()

	local row = CreateFrame('Button', nil, tooltip)
	row:SetHeight(ROW_HEIGHT)

	row.level = row:CreateFontString(nil, 'OVERLAY')
	row.level:SetPoint('LEFT', row, 'LEFT', 0, 0)
	row.level:SetWidth(28)
	row.level:FontTemplate(nil, 11, 'OUTLINE')
	row.level:SetJustifyH('RIGHT')

	row.name = row:CreateFontString(nil, 'OVERLAY')
	row.name:SetPoint('LEFT', row.level, 'RIGHT', 4, 0)
	row.name:SetWidth(160)
	row.name:FontTemplate(nil, 11, 'OUTLINE')
	row.name:SetJustifyH('LEFT')

	row.zone = row:CreateFontString(nil, 'OVERLAY')
	row.zone:SetPoint('RIGHT', row, 'RIGHT', 0, 0)
	row.zone:SetWidth(130)
	row.zone:FontTemplate(nil, 11, 'OUTLINE')
	row.zone:SetJustifyH('RIGHT')

	row.highlight = row:CreateTexture(nil, 'HIGHLIGHT')
	row.highlight:SetAllPoints()
	row.highlight:SetColorTexture(1, 1, 1, 0.1)

	row:SetScript('OnEnter', function(self)
		CancelHide()
		if (self.friendName or self.friendBNetName) and ownerPanel then
			DT.tooltip:SetOwner(tooltip, 'ANCHOR_NONE')
			AnchorHoverTooltip(DT.tooltip, tooltip)
			local classc = self.friendClass and E:ClassColor(self.friendClass)
			if self.friendBNetName then
				DT.tooltip:AddLine(self.friendBNetName, 1, 1, 1)
				if self.friendName and self.friendName ~= '' then
					if classc then
						DT.tooltip:AddLine(self.friendName, classc.r, classc.g, classc.b)
					else
						DT.tooltip:AddLine(self.friendName, 0.7, 0.7, 0.7)
					end
				end
			elseif self.friendName then
				if classc then
					DT.tooltip:AddLine(self.friendName, classc.r, classc.g, classc.b)
				else
					DT.tooltip:AddLine(self.friendName, 1, 1, 1)
				end
			end
			DT.tooltip:AddLine(' ')
			DT.tooltip:AddLine('Left-click: Whisper', 0.7, 0.7, 0.7)
			if self.canInvite then
				DT.tooltip:AddLine('Right-click: Invite', 0.7, 0.7, 0.7)
			end
			DT.tooltip:Show()
		end
	end)
	row:SetScript('OnLeave', function()
		ScheduleHide()
		DT.tooltip:Hide()
	end)
	row:SetScript('OnClick', function(self, button)
		if button == 'LeftButton' then
			if self.friendBNetName then
				ChatFrame_SendBNetTell(self.friendBNetName)
			elseif self.friendName then
				ChatFrame_OpenChat('/w ' .. self.friendName .. ' ')
			end
		elseif button == 'RightButton' and self.canInvite then
			if self.friendGameID then
				BNInviteFriend(self.friendGameID)
			elseif self.friendName then
				C_PartyInfo_InviteUnit(self.friendName)
			end
		end
	end)
	row:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

	rows[index] = row
	return row
end

local function ShowTooltip(panel)
	CreateTooltip()
	CancelHide()
	ownerPanel = panel

	local numberOfFriends = C_FriendList_GetNumFriends()
	local onlineFriends = C_FriendList_GetNumOnlineFriends() or 0
	local totalBNet, numBNetOnline = BNGetNumFriends()
	numBNetOnline = numBNetOnline or 0
	local totalOnline = onlineFriends + numBNetOnline

	if totalOnline == 0 then return end

	if not dataValid then
		if numberOfFriends > 0 then BuildFriendTable(numberOfFriends) end
		if totalBNet > 0 and BNConnected() then BuildBNTable(totalBNet) end
		dataValid = true
	end

	headerText:SetText(format('%s  |cff999999Online: %d|r', FRIENDS, totalOnline))

	local shown = 0

	-- Section: Character friends
	local hasCharHeader = false
	for _, info in ipairs(friendTable) do
		if shown >= MAX_ROWS then break end

		if not hasCharHeader and next(friendTable) then
			shown = shown + 1
			local row = GetOrCreateRow(shown)
			row.level:SetText('')
			row.name:SetText('Character Friends')
			row.name:SetTextColor(0.4, 0.78, 1)
			row.zone:SetText('')
			row.friendName = nil
			row.friendBNetName = nil
			row.friendClass = nil
			row.canInvite = false
			row.friendGameID = nil
			if shown == 1 then
				row:SetPoint('TOPLEFT', headerText, 'BOTTOMLEFT', 0, -6)
				row:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
			else
				row:SetPoint('TOPLEFT', rows[shown - 1], 'BOTTOMLEFT', 0, -ROW_PAD)
				row:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
			end
			row:Show()
			hasCharHeader = true
		end

		shown = shown + 1
		local row = GetOrCreateRow(shown)
		local levelc = GetQuestDifficultyColor(info.level)
		local classc = E:ClassColor(info.class) or levelc

		row.level:SetText(info.level)
		row.level:SetTextColor(levelc.r, levelc.g, levelc.b)

		row.name:SetText(info.name .. InGroup(info.name) .. info.status)
		row.name:SetTextColor(classc.r, classc.g, classc.b)

		local zonec = (E.MapInfo.zoneText and E.MapInfo.zoneText == info.zone) and activezone or inactivezone
		row.zone:SetText(info.zone)
		row.zone:SetTextColor(zonec.r, zonec.g, zonec.b)

		row.friendName = info.name
		row.friendBNetName = nil
		row.friendClass = info.class
		row.canInvite = InGroup(info.name) == ''
		row.friendGameID = nil

		row:SetPoint('TOPLEFT', rows[shown - 1], 'BOTTOMLEFT', 0, -ROW_PAD)
		row:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
		row:Show()
	end

	-- Section: BNet friends grouped by client
	for _, client in ipairs(clientOrder) do
		local group = clientGroups[client]
		if group and #group > 0 and shown < MAX_ROWS then
			-- Section header
			shown = shown + 1
			local hdr = GetOrCreateRow(shown)
			hdr.level:SetText('')
			local tagInfo = clientTags[client]
			local tag = tagInfo and tagInfo.tag or client
			hdr.name:SetText(format('%s (%s)', battleNetString, tag))
			hdr.name:SetTextColor(0.4, 0.78, 1)
			hdr.zone:SetText('')
			hdr.friendName = nil
			hdr.friendBNetName = nil
			hdr.friendClass = nil
			hdr.canInvite = false
			hdr.friendGameID = nil
			if shown == 1 then
				hdr:SetPoint('TOPLEFT', headerText, 'BOTTOMLEFT', 0, -6)
				hdr:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
			else
				hdr:SetPoint('TOPLEFT', rows[shown - 1], 'BOTTOMLEFT', 0, -ROW_PAD)
				hdr:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
			end
			hdr:Show()

			for _, info in ipairs(group) do
				if shown >= MAX_ROWS then break end

				shown = shown + 1
				local row = GetOrCreateRow(shown)

				if info.isWoW and info.level and info.level > 0 then
					local levelc = GetQuestDifficultyColor(info.level)
					local classc = E:ClassColor(info.class) or levelc
					row.level:SetText(info.level)
					row.level:SetTextColor(levelc.r, levelc.g, levelc.b)

					local nameStr = info.name
					if info.name ~= '' then
						nameStr = nameStr .. InGroup(info.name, info.realmName) .. info.status
					end
					row.name:SetText(nameStr)
					row.name:SetTextColor(classc.r, classc.g, classc.b)

					row.zone:SetText(info.accountName or '')
					row.zone:SetTextColor(0.93, 0.93, 0.93)
				else
					row.level:SetText('')
					local nameStr = info.name ~= '' and (info.name .. info.status) or ''
					row.name:SetText(nameStr)
					row.name:SetTextColor(0.9, 0.9, 0.9)
					row.zone:SetText(info.accountName or '')
					row.zone:SetTextColor(0.93, 0.93, 0.93)
				end

				row.friendName = info.name ~= '' and info.name or nil
				row.friendBNetName = info.accountName
				row.friendClass = info.class ~= '' and info.class or nil
				row.canInvite = info.isWoW and info.wowProjectID == WOW_PROJECT_ID and InGroup(info.name or '', info.realmName) == ''
				row.friendGameID = info.gameID

				row:SetPoint('TOPLEFT', rows[shown - 1], 'BOTTOMLEFT', 0, -ROW_PAD)
				row:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
				row:Show()
			end
		end
	end

	-- Hide unused rows
	for i = shown + 1, #rows do
		rows[i]:Hide()
	end

	-- Size and position
	local tooltipWidth = TOOLTIP_PAD * 2 + 28 + 4 + 160 + 10 + 130
	local contentH = TOOLTIP_PAD + headerText:GetStringHeight() + 6 + (shown * (ROW_HEIGHT + ROW_PAD)) + TOOLTIP_PAD

	tooltip:SetSize(tooltipWidth, contentH)
	AnchorToPanel(tooltip, panel)
	tooltip:Show()
end

-- DT callbacks
local function OnEnter(panel)
	ShowTooltip(panel)
end

local function OnLeave()
	ScheduleHide()
end

local function OnEvent(panel, event, arg1)
	local onlineFriends = C_FriendList_GetNumOnlineFriends() or 0
	local _, numBNetOnline = BNGetNumFriends()
	numBNetOnline = numBNetOnline or 0

	if event == 'CHAT_MSG_SYSTEM' then
		if E:IsSecretValue(arg1) then return end
	end

	dataValid = false

	panel.text:SetFormattedText(displayString, FRIENDS .. ': ', onlineFriends + numBNetOnline)
end

local function OnClick(_, btn)
	if btn == 'LeftButton' and not E:AlertCombat() then
		ToggleFriendsFrame(not E.Retail and 1 or nil)
	end
end

local function ApplySettings(_, hex)
	displayString = '%s' .. hex .. '%d|r'
end

DT:RegisterDatatext('TUI Friends', _G.SOCIAL_LABEL, { 'BN_FRIEND_ACCOUNT_ONLINE', 'BN_FRIEND_ACCOUNT_OFFLINE', 'BN_FRIEND_INFO_CHANGED', 'FRIENDLIST_UPDATE', 'CHAT_MSG_SYSTEM' }, OnEvent, nil, OnClick, OnEnter, OnLeave, 'TUI Friends', nil, ApplySettings)
