-- TrenchyUI/Profiles/ProjectAzilroka.lua
local E = unpack(ElvUI)
local ElvUI_TrenchyUI = E:GetModule('ElvUI_TrenchyUI')
local IsAddOnLoaded = _G.C_AddOns and _G.C_AddOns.IsAddOnLoaded

function ElvUI_TrenchyUI:ProjectAzilroka()
	if not IsAddOnLoaded("ProjectAzilroka") then return end

	local ProjectAzilrokaDB = _G.ProjectAzilrokaDB
	if not ProjectAzilrokaDB then return end

	ProjectAzilrokaDB["profiles"]["TrenchyUI"] = {}

	-- General/Modules per SavedVariables (Default profile)
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedShadows = ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedShadows or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedShadows.Enable = false

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].AuraReminder = ProjectAzilrokaDB["profiles"]["TrenchyUI"].AuraReminder or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].AuraReminder.Enable = false

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].TorghastBuffs = ProjectAzilrokaDB["profiles"]["TrenchyUI"].TorghastBuffs or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].TorghastBuffs.Enable = false
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].TorghastBuffs.horizontalSpacing = 1
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].TorghastBuffs.verticalSpacing = 1
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].TorghastBuffs.size = 26

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedFriendsList = ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedFriendsList or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedFriendsList.ShowStatusHighlight = false
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedFriendsList.NameFontFlag = "SHADOWOUTLINE"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedFriendsList.NameFontSize = 17
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedFriendsList.StatusIconPack = "Square"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedFriendsList.InfoFontFlag = "SHADOWOUTLINE"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedFriendsList.ShowLevel = false
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].EnhancedFriendsList.Texture = "TrenchyBlank"

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].DragonOverlay = ProjectAzilrokaDB["profiles"]["TrenchyUI"].DragonOverlay or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].DragonOverlay.Enable = false

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].OzCooldowns = ProjectAzilrokaDB["profiles"]["TrenchyUI"].OzCooldowns or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].OzCooldowns.StatusBarTexture = "TrenchyBlank"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].OzCooldowns.Enable = false
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].OzCooldowns.Tooltips = false
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].OzCooldowns.Size = 24
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].OzCooldowns.StatusBarGradient = true
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].OzCooldowns.Announce = false

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].QuestSounds = ProjectAzilrokaDB["profiles"]["TrenchyUI"].QuestSounds or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].QuestSounds.ObjectiveCompleteID = "None"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].QuestSounds.ObjectiveProgressID = "None"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].QuestSounds.ObjectiveComplete = "None"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].QuestSounds.QuestCompleteID = "None"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].QuestSounds.ObjectiveProgress = "None"

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SunsongRanchFarmer = ProjectAzilrokaDB["profiles"]["TrenchyUI"].SunsongRanchFarmer or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SunsongRanchFarmer.Enable = false

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].stAddonManager = ProjectAzilrokaDB["profiles"]["TrenchyUI"].stAddonManager or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].stAddonManager.FontSize = 18
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].stAddonManager.CheckTexture = "TrenchyBlank"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].stAddonManager.ButtonHeight = 15
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].stAddonManager.FontFlag = "SHADOWOUTLINE"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].stAddonManager.ButtonWidth = 15
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].stAddonManager.ClassColor = true
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].stAddonManager.Font = "Expressway"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].stAddonManager.FrameWidth = 430

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].iFilger = ProjectAzilrokaDB["profiles"]["TrenchyUI"].iFilger or {}
	local iF = ProjectAzilrokaDB["profiles"]["TrenchyUI"].iFilger
	-- Turn off groups and set fonts per SV
	for _, group in pairs({"Enhancements","FocusDebuffs","RaidDebuffs","TargetDebuffs","FocusBuffs","Procs","Cooldowns","Buffs","ItemCooldowns"}) do
		iF[group] = iF[group] or {}
	end
	iF.Enhancements.Enable = false
	iF.FocusDebuffs.Enable = false
	iF.RaidDebuffs.Enable = false
	iF.TargetDebuffs.Enable = false
	iF.FocusBuffs.Enable = false
	iF.Procs.FilterByList = "Blacklist"
	iF.Procs.Blacklist = { [185394] = true }
	iF.Buffs.StatusBarTexture = "TrenchyBlank"
	iF.Buffs.FilterByList = "Whitelist"
	iF.Buffs.StatusBarWidth = 256
	iF.Buffs.StatusBar = true
	iF.Buffs.Whitelist = { [188290] = true, [376907] = true, [194879] = true }
	iF.Buffs.Size = 24
	iF.Buffs.StatusBarHeight = 6
	iF.Buffs.FollowCooldownText = true
	-- Shared font fields observed in SV
	local fontName = "Expressway"
	for _, group in pairs({"Enhancements","FocusDebuffs","RaidDebuffs","TargetDebuffs","FocusBuffs","Procs","Cooldowns","Buffs","ItemCooldowns"}) do
		iF[group].StackCountFont = fontName
		iF[group].StatusBarFont = fontName
	end
	-- ItemCooldowns whitelist
	iF.ItemCooldowns.FilterByList = "Whitelist"
	iF.ItemCooldowns.Whitelist = { [193743] = true }
	-- Cooldowns SpellCDs (subset from SV for safety)
	iF.Cooldowns.SpellCDs = iF.Cooldowns.SpellCDs or {}
	for spellID, enabled in pairs({
		[43265]=false,[42650]=false,[49028]=false,[207289]=false,[206940]=false,[47568]=false,[194844]=false,[274738]=false,[46584]=false,[390279]=false,[195292]=false,[108199]=false,[275699]=false,[46585]=false,[55233]=false,[206931]=false,[63560]=false,[50977]=false,[56222]=false,[383269]=false,[196770]=false,[115989]=false,[219809]=false,[50842]=false,[194679]=false,[51271]=false,[221699]=false,[152280]=false,[274156]=false,[49206]=false,[125439]=false,[279302]=false
	}) do iF.Cooldowns.SpellCDs[spellID] = enabled end

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons = ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons.Enable = true
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons.ReverseDirection = true
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons.MoveMail = false
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons.MoveQueue = false
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons.IconSize = 27
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons.Shadows = false
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons.ButtonsPerRow = 6
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons.Visibility = "show"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].SquareMinimapButtons.MoveTracker = false

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].BrokerLDB = ProjectAzilrokaDB["profiles"]["TrenchyUI"].BrokerLDB or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].BrokerLDB.FontFlag = "OUTLINE"
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].BrokerLDB.Font = fontName

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].Cooldown = ProjectAzilrokaDB["profiles"]["TrenchyUI"].Cooldown or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].Cooldown.checkSeconds = true
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].Cooldown.Enable = false

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].MasterExperience = ProjectAzilrokaDB["profiles"]["TrenchyUI"].MasterExperience or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].MasterExperience.Font = fontName
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].MasterExperience.ColorByClass = true

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].FasterLoot = ProjectAzilrokaDB["profiles"]["TrenchyUI"].FasterLoot or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].FasterLoot.Enable = false

	ProjectAzilrokaDB["profiles"]["TrenchyUI"].ReputationReward = ProjectAzilrokaDB["profiles"]["TrenchyUI"].ReputationReward or {}
	ProjectAzilrokaDB["profiles"]["TrenchyUI"].ReputationReward.Enable = false

	--set the profile
	ProjectAzilrokaDB["profileKeys"][E.mynameRealm] = "TrenchyUI"
	ElvUI_TrenchyUI:Print("|cFF16C3F2Project|r|cFFFFFFFFAzilroka|r profile applied.")
end
