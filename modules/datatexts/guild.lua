local E = unpack(ElvUI)
local DT = E:GetModule('DataTexts')

local format, sort, wipe, ipairs = format, sort, wipe, ipairs
local GetGuildInfo = GetGuildInfo
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumGuildMembers = GetNumGuildMembers
local IsInGuild = IsInGuild
local IsShiftKeyDown = IsShiftKeyDown
local GetQuestDifficultyColor = GetQuestDifficultyColor
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local C_GuildInfo_GuildRoster = C_GuildInfo.GuildRoster
local GetGuildRosterMOTD = C_GuildInfo.GetMOTD or GetGuildRosterMOTD
local C_PartyInfo_InviteUnit = C_PartyInfo.InviteUnit
local GUILD = GUILD

local guildTable = {}
local displayString = ''
local dataValid = false

local ROW_HEIGHT = 16
local ROW_PAD = 2
local TOOLTIP_PAD = 8
local MAX_ROWS = 30

local onlinestatus = {
	[0] = '',
	[1] = ' |cffFF9900AFK|r',
	[2] = ' |cffFF3333DND|r',
}

local activezone = { r = 0.3, g = 1.0, b = 0.3 }
local inactivezone = { r = 0.65, g = 0.65, b = 0.65 }

-- Tooltip frame and rows
local tooltip, headerText, motdText
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

local function InGroup(name)
	return (UnitInParty(name) or UnitInRaid(name)) and ' |cffaaaaaa*|r' or ''
end

-- Anchor a frame relative to the panel using ElvUI's anchor direction
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


local function SortByName(a, b)
	if a and b then return a.name < b.name end
end

local function SortByRank(a, b)
	if a and b then
		if a.rankIndex == b.rankIndex then return a.name < b.name end
		return a.rankIndex < b.rankIndex
	end
end

local function BuildGuildTable()
	wipe(guildTable)
	local totalMembers = GetNumGuildMembers()
	for i = 1, totalMembers do
		local name, rank, rankIndex, level, _, zone, note, officerNote, connected, memberstatus, className, _, _, isMobile, _, _, guid = GetGuildRosterInfo(i)
		if not name then break end
		if connected or isMobile then
			guildTable[#guildTable + 1] = {
				name = E:StripMyRealm(name),
				rank = rank,
				rankIndex = rankIndex,
				level = level,
				zone = zone or '',
				class = className,
				online = connected,
				isMobile = isMobile,
				status = onlinestatus[memberstatus] or '',
				guid = guid,
			}
		end
	end
end

local function CreateTooltip()
	if tooltip then return end

	tooltip = CreateFrame('Frame', 'TUIGuildTooltip', E.UIParent, 'BackdropTemplate')
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

	motdText = tooltip:CreateFontString(nil, 'OVERLAY')
	motdText:SetPoint('TOPLEFT', headerText, 'BOTTOMLEFT', 0, -4)
	motdText:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
	motdText:FontTemplate(nil, 11, 'NONE')
	motdText:SetJustifyH('LEFT')
	motdText:SetWordWrap(true)
	motdText:SetTextColor(0.75, 0.9, 1)
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
	row.name:SetWidth(140)
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
		if self.memberName then
			GameTooltip:SetOwner(_G.TooltipMover, 'ANCHOR_NONE')
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint('BOTTOMLEFT', _G.TooltipMover, 'TOPLEFT', 0, 2)
			local classc = self.memberClass and E:ClassColor(self.memberClass)
			if classc then
				GameTooltip:AddLine(self.memberName, classc.r, classc.g, classc.b)
			else
				GameTooltip:AddLine(self.memberName, 1, 1, 1)
			end
			if self.memberRank then GameTooltip:AddLine(self.memberRank, 0.5, 0.5, 0.5) end
			GameTooltip:AddLine(' ')
			GameTooltip:AddLine('Left-click: Whisper', 0.7, 0.7, 0.7)
			GameTooltip:AddLine('Right-click: Invite', 0.7, 0.7, 0.7)
			GameTooltip:Show()
		end
	end)
	row:SetScript('OnLeave', function()
		ScheduleHide()
		GameTooltip:Hide()
	end)
	row:SetScript('OnClick', function(self, button)
		if not self.memberName then return end
		if button == 'LeftButton' then
			ChatFrame_OpenChat('/w ' .. self.memberName .. ' ')
		elseif button == 'RightButton' then
			C_PartyInfo_InviteUnit(self.memberName)
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

	if not IsInGuild() then return end
	if not dataValid then
		BuildGuildTable()
		dataValid = true
	end

	local shiftDown = IsShiftKeyDown()
	if shiftDown then
		sort(guildTable, SortByRank)
	else
		sort(guildTable, SortByName)
	end

	local total, _, online = GetNumGuildMembers()
	if not online then online = 0 end
	if not total then total = 0 end

	local guildName = GetGuildInfo('player')
	if guildName then
		headerText:SetText(format('%s  |cff999999%s: %d/%d|r', guildName, GUILD, online, total))
	else
		headerText:SetText(format('%s: %d/%d', GUILD, online, total))
	end

	local motd = GetGuildRosterMOTD()
	local contentTop
	if motd and motd ~= '' and E:NotSecretValue(motd) then
		motdText:SetText(motd)
		motdText:Show()
		contentTop = motdText
	else
		motdText:SetText('')
		motdText:Hide()
		contentTop = headerText
	end

	local shown = 0

	for i, info in ipairs(guildTable) do
		if shown >= MAX_ROWS then break end
		shown = shown + 1

		local row = GetOrCreateRow(shown)
		local levelc = GetQuestDifficultyColor(info.level)
		local classc = E:ClassColor(info.class) or levelc

		row.level:SetText(info.level)
		row.level:SetTextColor(levelc.r, levelc.g, levelc.b)

		local nameStr = info.name .. InGroup(info.name) .. info.status
		row.name:SetText(nameStr)
		row.name:SetTextColor(classc.r, classc.g, classc.b)

		local zonec = (E.MapInfo.zoneText and E.MapInfo.zoneText == info.zone) and activezone or inactivezone
		row.zone:SetText(info.zone)
		row.zone:SetTextColor(zonec.r, zonec.g, zonec.b)

		row.memberName = info.name
		row.memberRank = info.rank
		row.memberClass = info.class

		if shown == 1 then
			row:SetPoint('TOPLEFT', contentTop, 'BOTTOMLEFT', 0, -6)
			row:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
		else
			row:SetPoint('TOPLEFT', rows[shown - 1], 'BOTTOMLEFT', 0, -ROW_PAD)
			row:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
		end
		row:Show()
	end

	-- Hide unused rows
	for i = shown + 1, #rows do
		rows[i]:Hide()
	end

	-- More members indicator
	local extra = #guildTable - shown
	if extra > 0 then
		shown = shown + 1
		local row = GetOrCreateRow(shown)
		row.level:SetText('')
		row.name:SetText(format('+%d more online...', extra))
		row.name:SetTextColor(0.75, 0.9, 1)
		row.zone:SetText('')
		row.memberName = nil
		row.memberRank = nil
		row.memberClass = nil
		row:SetPoint('TOPLEFT', rows[shown - 1], 'BOTTOMLEFT', 0, -ROW_PAD)
		row:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
		row:Show()
		for i = shown + 1, #rows do rows[i]:Hide() end
	end

	-- Size and position
	local tooltipWidth = TOOLTIP_PAD * 2 + 28 + 4 + 140 + 10 + 130
	local contentH = TOOLTIP_PAD + headerText:GetStringHeight()
	if motdText:IsShown() then
		motdText:SetWidth(tooltipWidth - TOOLTIP_PAD * 2)
		contentH = contentH + 4 + motdText:GetStringHeight()
	end
	contentH = contentH + 6 + (shown * (ROW_HEIGHT + ROW_PAD)) + TOOLTIP_PAD

	tooltip:SetSize(tooltipWidth, contentH)
	AnchorToPanel(tooltip, panel)
	tooltip:Show()
end

-- DT callbacks
local function OnEnter(panel)
	if not IsInGuild() then return end
	ShowTooltip(panel)
end

local function OnLeave()
	ScheduleHide()
end

local function OnEvent(panel, event, ...)
	if IsInGuild() then
		if event == 'GUILD_ROSTER_UPDATE' or event == 'PLAYER_ENTERING_WORLD' then
			dataValid = false
			BuildGuildTable()
			if tooltip and tooltip:IsShown() and ownerPanel then
				ShowTooltip(ownerPanel)
			end
		elseif event == 'PLAYER_GUILD_UPDATE' then
			C_GuildInfo_GuildRoster()
		end

		panel.text:SetFormattedText(displayString, GUILD .. ': ', #guildTable)
	else
		panel.text:SetText(displayString)
	end
end

local function OnClick(panel, btn)
	if btn == 'LeftButton' and not E:AlertCombat() then
		ToggleGuildFrame()
	end
end

local function ApplySettings(_, hex)
	displayString = '%s' .. hex .. '%d|r'
end

DT:RegisterDatatext('TUI Guild', _G.SOCIAL_LABEL, { 'GUILD_ROSTER_UPDATE', 'PLAYER_GUILD_UPDATE', 'PLAYER_ENTERING_WORLD' }, OnEvent, nil, OnClick, OnEnter, OnLeave, 'TUI Guild', nil, ApplySettings)
