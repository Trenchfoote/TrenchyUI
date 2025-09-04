-- TrenchyUI/Profiles/ProjectAzilroka.lua
local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}

NS.RegisterExternalProfile("ProjectAzilroka", function()
  if not NS.IsAddonLoaded("ProjectAzilroka") then return false end
  local PAgw = _G and rawget(_G, "ProjectAzilroka")
  if type(PAgw) ~= "table" then return false end
  local PA = unpack(PAgw)
  if type(PA) ~= "table" or not PA.data or not PA.db then return false end

  local name = "TrenchyUI"
  if PA.data and PA.data.SetProfile then PA.data:SetProfile(name) end

  -- General/Modules per SavedVariables (Default profile)
  PA.db.EnhancedShadows = PA.db.EnhancedShadows or {}
  PA.db.EnhancedShadows.Enable = false
  
  PA.db.AuraReminder = PA.db.AuraReminder or {}
  PA.db.AuraReminder.Enable = false

  PA.db.TorghastBuffs = PA.db.TorghastBuffs or {}
  PA.db.TorghastBuffs.Enable = false
  PA.db.TorghastBuffs.horizontalSpacing = 1
  PA.db.TorghastBuffs.verticalSpacing = 1
  PA.db.TorghastBuffs.size = 26

  PA.db.EnhancedFriendsList = PA.db.EnhancedFriendsList or {}
  PA.db.EnhancedFriendsList.ShowStatusHighlight = false
  PA.db.EnhancedFriendsList.NameFontFlag = "SHADOWOUTLINE"
  PA.db.EnhancedFriendsList.NameFontSize = 17
  PA.db.EnhancedFriendsList.StatusIconPack = "Square"
  PA.db.EnhancedFriendsList.InfoFontFlag = "SHADOWOUTLINE"
  PA.db.EnhancedFriendsList.ShowLevel = false
  PA.db.EnhancedFriendsList.Texture = "TrenchyBlank"

  PA.db.DragonOverlay = PA.db.DragonOverlay or {}
  PA.db.DragonOverlay.Enable = false

  PA.db.OzCooldowns = PA.db.OzCooldowns or {}
  PA.db.OzCooldowns.StatusBarTexture = "Eltreum7pixelB"
  PA.db.OzCooldowns.Enable = false
  PA.db.OzCooldowns.Tooltips = false
  PA.db.OzCooldowns.Size = 24
  PA.db.OzCooldowns.StatusBarGradient = true
  PA.db.OzCooldowns.Announce = false

  PA.db.QuestSounds = PA.db.QuestSounds or {}
  PA.db.QuestSounds.ObjectiveCompleteID = "None"
  PA.db.QuestSounds.ObjectiveProgressID = "None"
  PA.db.QuestSounds.ObjectiveComplete = "None"
  PA.db.QuestSounds.QuestCompleteID = "None"
  PA.db.QuestSounds.ObjectiveProgress = "None"

  PA.db.SunsongRanchFarmer = PA.db.SunsongRanchFarmer or {}
  PA.db.SunsongRanchFarmer.Enable = false

  PA.db.stAddonManager = PA.db.stAddonManager or {}
  PA.db.stAddonManager.FontSize = 18
  PA.db.stAddonManager.CheckTexture = "TrenchyBlank"
  PA.db.stAddonManager.ButtonHeight = 15
  PA.db.stAddonManager.FontFlag = "SHADOWOUTLINE"
  PA.db.stAddonManager.ButtonWidth = 15
  PA.db.stAddonManager.ClassColor = true
  PA.db.stAddonManager.Font = "Expressway"
  PA.db.stAddonManager.FrameWidth = 430

  PA.db.iFilger = PA.db.iFilger or {}
  local iF = PA.db.iFilger
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
  iF.Buffs.StatusBarTexture = "Eltreum-Class-PriestV2"
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

  PA.db.SquareMinimapButtons = PA.db.SquareMinimapButtons or {}
  PA.db.SquareMinimapButtons.Enable = false
  PA.db.SquareMinimapButtons.ReverseDirection = true
  PA.db.SquareMinimapButtons.MoveMail = false
  PA.db.SquareMinimapButtons.MoveQueue = false
  PA.db.SquareMinimapButtons.IconSize = 27
  PA.db.SquareMinimapButtons.Shadows = false
  PA.db.SquareMinimapButtons.ButtonsPerRow = 6
  PA.db.SquareMinimapButtons.Visibility = "show"
  PA.db.SquareMinimapButtons.MoveTracker = false

  PA.db.BrokerLDB = PA.db.BrokerLDB or {}
  PA.db.BrokerLDB.FontFlag = "OUTLINE"
  PA.db.BrokerLDB.Font = fontName

  PA.db.Cooldown = PA.db.Cooldown or {}
  PA.db.Cooldown.checkSeconds = true
  PA.db.Cooldown.Enable = false

  PA.db.MasterExperience = PA.db.MasterExperience or {}
  PA.db.MasterExperience.Font = fontName
  PA.db.MasterExperience.ColorByClass = true

  PA.db.FasterLoot = PA.db.FasterLoot or {}
  PA.db.FasterLoot.Enable = false

  PA.db.ReputationReward = PA.db.ReputationReward or {}
  PA.db.ReputationReward.Enable = false

  return true
end)
