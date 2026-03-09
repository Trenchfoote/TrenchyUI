local E = unpack(ElvUI)
local EP = E.Libs.EP
local LSM = E.Libs.LSM
local addon, ns = ...

local pairs, select, type = pairs, select, type
local tremove = tremove
local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded
local C_AddOns_DisableAddOn = C_AddOns.DisableAddOn

local mediaPath = 'Interface\\AddOns\\ElvUI_TrenchyUI\\media\\'
LSM:Register('statusbar', 'TrenchyFocus', mediaPath .. 'statusbar\\TrenchyFocus')

local TUI = E:NewModule('TrenchyUI', 'AceHook-3.0', 'AceEvent-3.0')
ns.TUI = TUI

-- Register TrenchyUI as a mover filter category in ElvUI's Config Mode dropdown
E:ConfigMode_AddGroup('TRENCHYUI', E:TextGradient('TrenchyUI', 1.00,0.18,0.24, 0.80,0.10,0.20))

TUI.conflictDefs = {
	damageMeter = {
		addonName  = 'Details',
		addonLabel = 'Details!',
		tuiFeature = 'Trenchy Damage Meter',
		popupText  = 'Looks like you have |cffff2f3dDetails!|r and |cffff2f3dTrenchyUI|r installed.\nPlease select which damage meter you\'d prefer to use.',
	},
	auraHighlight = {
		addonName  = 'ElvUI_EltreumUI',
		addonLabel = 'Eltruism',
		tuiFeature = 'TUI Pixel Glow',
		popupText  = 'Looks like you have |cffff2f3dEltruism|r and |cffff2f3dTrenchyUI|r installed.\nPlease select which pixel glow you\'d prefer to use.',
	},
	moveableFrames = {
		addonName  = 'BlizzMove',
		addonLabel = 'BlizzMove',
		tuiFeature = 'TUI Moveable Frames',
		popupText  = 'Looks like you have |cffff2f3dBlizzMove|r and |cffff2f3dTrenchyUI|r installed.\nPlease select which moveable frames addon you\'d prefer to use.',
	},
}

do -- Compat popup system
	local compatPopupQueue = {}

	local function ShowNextCompatPopup()
		local entry = tremove(compatPopupQueue, 1)
		if not entry then return end
		local popup = E.PopupDialogs.TUI_COMPAT_CHOICE
		popup.button1 = entry.def.tuiFeature
		popup.button2 = entry.def.addonLabel
		E:StaticPopup_Show('TUI_COMPAT_CHOICE', entry.def.popupText, nil, entry.key)
	end

	local function OnCompatChoice(self, choice)
		local key = self.data
		if not key then return end

		if TUI.db then TUI.db.profile.compat[key] = choice end

		local def = TUI.conflictDefs[key]
		if def and choice == 'tui' then
			C_AddOns_DisableAddOn(def.addonName)
		elseif def and choice == 'external' then
			if key == 'damageMeter' and TUI.db then
				TUI.db.profile.damageMeter.enabled = false
			elseif key == 'auraHighlight' and TUI.db then
				TUI.db.profile.pixelGlow.enabled = false
			elseif key == 'moveableFrames' and TUI.db then
				TUI.db.profile.qol.moveableFrames = false
			end
		end

		if #compatPopupQueue > 0 then ShowNextCompatPopup() else ReloadUI() end
	end

	E.PopupDialogs.TUI_COMPAT_CHOICE = {
		text = '%s',
		wideText = true,
		showAlert = true,
		button1 = 'TrenchyUI',
		button2 = 'Other',
		OnAccept = function(self) OnCompatChoice(self, 'tui') end,
		OnCancel = function(self) OnCompatChoice(self, 'external') end,
		whileDead = 1,
		hideOnEscape = false,
	}

	function TUI:ResolveCompat()
		self.activeConflicts = {}
		local db = self.db.profile.compat
		local needsReload = false

		for key, def in pairs(self.conflictDefs) do
			if C_AddOns_IsAddOnLoaded(def.addonName) then
				self.activeConflicts[key] = def
				if db[key] == nil then
					compatPopupQueue[#compatPopupQueue + 1] = { key = key, def = def }
				elseif db[key] == 'tui' then
					C_AddOns_DisableAddOn(def.addonName)
					needsReload = true
				end
			end
		end

		if needsReload then C_Timer.After(1, ReloadUI); return end
		if #compatPopupQueue > 0 then C_Timer.After(1, ShowNextCompatPopup) end
	end
end

function TUI:GetClassColor(classFilename)
	classFilename = classFilename or select(2, UnitClass('player'))
	if not classFilename then return nil end
	local c = E:ClassColor(classFilename)
	if c then return c.r, c.g, c.b end
	return nil
end

function TUI:IsCompatBlocked(key)
	if not self.activeConflicts[key] then return false end
	return self.db.profile.compat[key] ~= 'tui'
end

do -- Settings merge
	local function MergeDefaults(target, defaults)
		for k, v in pairs(defaults) do
			if type(v) == 'table' then
				if target[k] == nil then target[k] = {} end
				if type(target[k]) == 'table' then MergeDefaults(target[k], v) end
			elseif target[k] == nil then
				target[k] = v
			end
		end
	end

	function TUI:Initialize()
		if not E.db.TrenchyUI then E.db.TrenchyUI = {} end

		local sv = E.data and E.data.sv
		local oldNS = sv and sv.namespaces and sv.namespaces.TrenchyUI
		if oldNS then
			local profileKey = E.data.keys and E.data.keys.profile
			local oldProfile = profileKey and oldNS.profiles and oldNS.profiles[profileKey]
			if oldProfile and not E.db.TrenchyUI._migrated then
				MergeDefaults(E.db.TrenchyUI, oldProfile)
				E.db.TrenchyUI._migrated = true
			end
		end

		if E.db.TrenchyUI.blizzard and not E.db.TrenchyUI.qol then
			E.db.TrenchyUI.qol = E.db.TrenchyUI.blizzard
			E.db.TrenchyUI.blizzard = nil
		end

		if E.db.TrenchyUI.auraHighlight and not E.db.TrenchyUI.pixelGlow then
			E.db.TrenchyUI.pixelGlow = E.db.TrenchyUI.auraHighlight
			E.db.TrenchyUI.auraHighlight = nil
		end

		local addons = E.db.TrenchyUI.addons
		if addons and (addons.skinBigWigsLFG ~= nil or addons.bigWigsClassColorBars ~= nil) then
			if addons.skinBigWigs == nil then
				addons.skinBigWigs = addons.skinBigWigsLFG or addons.bigWigsClassColorBars or false
			end
			addons.skinBigWigsLFG = nil
			addons.bigWigsClassColorBars = nil
		end

		local defaults = self.defaults and self.defaults.profile or {}
		MergeDefaults(E.db.TrenchyUI, defaults)
		self.db = { profile = E.db.TrenchyUI }

		local installed = E.db.TrenchyUI._profileJustInstalled
		if installed then
			E.db.TrenchyUI._profileJustInstalled = nil
			if installed == 'all' then
				E:Print('|cffff2f3dTrenchyUI|r: All profiles applied.')
			elseif installed == 'elvui' then
				E:Print('|cffff2f3dTrenchyUI|r: ElvUI profile applied.')
			end
		end

		if E.db.TrenchyUI._pendingBigWigsProfile and BigWigsAPI and self.ApplyBigWigsProfile then
			E.db.TrenchyUI._pendingBigWigsProfile = nil
			C_Timer.After(2, function()
				self:ApplyBigWigsProfile(function(accepted)
					if accepted then E:Print('|cffff2f3dTrenchyUI|r: BigWigs profile applied.') end
				end)
			end)
		end

		self:ResolveCompat()

		E.data.RegisterCallback(self, 'OnProfileChanged', 'UpdateProfileReference')
		E.data.RegisterCallback(self, 'OnProfileCopied', 'UpdateProfileReference')
		E.data.RegisterCallback(self, 'OnProfileReset', 'UpdateProfileReference')

		if self.InitSkinWarpDeplete then self:InitSkinWarpDeplete() end
		if self.InitSkinBigWigs then self:InitSkinBigWigs() end
		if self.InitQoL then self:InitQoL() end
		if self.InitElvNP then self:InitElvNP() end
		if self.InitSkinAuctionator then self:InitSkinAuctionator() end
		if self.InitCooldownManager then self:InitCooldownManager() end
		if self.InitSoulFragments then self:InitSoulFragments() end
		if self.InitIronfurBar then self:InitIronfurBar() end
		if not self:IsCompatBlocked('auraHighlight') and self.InitPixelGlow then self:InitPixelGlow() end
		if not self:IsCompatBlocked('damageMeter') and self.InitDamageMeter then self:InitDamageMeter() end
		if self.InitSkinBugSack then self:InitSkinBugSack() end
		if self.InitSkinOPie then self:InitSkinOPie() end
	end

	function TUI:UpdateProfileReference()
		if not E.db.TrenchyUI then E.db.TrenchyUI = {} end
		local defaults = self.defaults and self.defaults.profile or {}
		MergeDefaults(E.db.TrenchyUI, defaults)
		self.db = { profile = E.db.TrenchyUI }

		if self.RefreshMeter then self:RefreshMeter() end
		if self.UpdateMeterLayout then self:UpdateMeterLayout() end
		if self.UpdateDifficultyFont then self:UpdateDifficultyFont() end
	end
end

EP:RegisterPlugin(addon, function()
	if TUI.BuildConfig then TUI:BuildConfig() end
end)

SLASH_TUI1 = '/tui'
SlashCmdList['TUI'] = function()
	E:ToggleOptions('TrenchyUI')
end

E:RegisterModule(TUI:GetName())
