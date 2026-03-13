local E = unpack(ElvUI)
local EP = E.Libs.EP
local LSM = E.Libs.LSM
local addon, ns = ...

local pairs, select, type = pairs, select, type

local mediaPath = 'Interface\\AddOns\\ElvUI_TrenchyUI\\media\\'
LSM:Register('statusbar', 'TrenchyFocus', mediaPath .. 'statusbar\\TrenchyFocus')

local TUI = E:NewModule('TrenchyUI', 'AceHook-3.0', 'AceEvent-3.0')
ns.TUI = TUI

-- Register TrenchyUI as a mover filter category in ElvUI's Config Mode dropdown
E:ConfigMode_AddGroup('TRENCHYUI', E:TextGradient('TrenchyUI', 1.00,0.18,0.24, 0.80,0.10,0.20))

TUI.conflictDefs = {
	damageMeter = {
		addons     = { { name = 'Details', label = 'Details!' } },
		tuiFeature = 'Trenchy Damage Meter',
		category   = 'damage meter',
		tuiCheck   = function(db) return db.damageMeter.enabled end,
		tuiDisable = function(db) db.damageMeter.enabled = false end,
	},
	auraHighlight = {
		addons     = { { name = 'ElvUI_EltreumUI', label = 'Eltruism' } },
		tuiFeature = 'TUI Pixel Glow',
		category   = 'pixel glow',
		tuiCheck   = function(db) return db.pixelGlow.enabled end,
		tuiDisable = function(db) db.pixelGlow.enabled = false end,
		-- Eltruism: only conflict if their unitframe glow is enabled
		externalCheck = function()
			local eltDB = E.db and E.db.ElvUI_EltreumUI and E.db.ElvUI_EltreumUI.glow
			return eltDB and eltDB.enableUFs
		end,
		-- Don't disable all of Eltruism — just turn off their unitframe glow.
		tuiAccept = function()
			if E.db and E.db.ElvUI_EltreumUI and E.db.ElvUI_EltreumUI.glow then
				E.db.ElvUI_EltreumUI.glow.enableUFs = false
			end
		end,
	},
	moveableFrames = {
		addons     = { { name = 'BlizzMove', label = 'BlizzMove' } },
		tuiFeature = 'TUI Moveable Frames',
		category   = 'moveable frames addon',
		tuiCheck   = function(db) return db.qol.moveableFrames end,
		tuiDisable = function(db) db.qol.moveableFrames = false end,
	},
	cooldownManager = {
		addons     = {
			{ name = 'Ayije_CDM', label = 'Ayije CDM' },
			{ name = 'ArcUI', label = 'Arc UI' },
			{ name = 'BCDM', label = 'BCDM' },
			{ name = 'CDMCentered', label = 'CDM Centered' },
		},
		tuiFeature = 'TUI Cooldown Manager',
		category   = 'cooldown manager',
		tuiCheck   = function(db) return db.cooldownManager.enabled end,
		tuiDisable = function(db) db.cooldownManager.enabled = false end,
	},
}

do -- Compat popup system
	local tremove = tremove
	local C_AddOns_IsAddOnLoaded = C_AddOns.IsAddOnLoaded
	local C_AddOns_DisableAddOn = C_AddOns.DisableAddOn
	local compatPopupQueue = {}

	local function ShowNextCompatPopup()
		local entry = tremove(compatPopupQueue, 1)
		if not entry then return end
		local popup = E.PopupDialogs.TUI_COMPAT_CHOICE
		popup.button1 = entry.def.tuiFeature
		popup.button2 = entry.detectedLabel
		E:StaticPopup_Show('TUI_COMPAT_CHOICE', entry.popupText, nil, entry.key)
	end

	local function OnCompatChoice(self, choice)
		local key = self.data
		if not key then return end

		if TUI.db then TUI.db.profile.compat[key] = choice end

		local def = TUI.conflictDefs[key]
		if def then
			if choice == 'tui' then
				if def.tuiAccept then
					def.tuiAccept()
				else
					for _, entry in pairs(def.addons) do
						if C_AddOns_IsAddOnLoaded(entry.name) then
							C_AddOns_DisableAddOn(entry.name)
						end
					end
				end
			elseif choice == 'external' then
				def.tuiDisable(TUI.db.profile)
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

	-- Returns first loaded competing addon entry, or nil
	local function FindLoadedAddon(def)
		for _, entry in pairs(def.addons) do
			if C_AddOns_IsAddOnLoaded(entry.name) then return entry end
		end
	end

	-- Check if an external addon from a conflict def is currently loaded
	function TUI:HasExternalAddonLoaded(key)
		local def = self.conflictDefs[key]
		if not def then return false end
		return FindLoadedAddon(def) ~= nil
	end

	function TUI:ResolveCompat()
		self.activeConflicts = {}
		local db = self.db.profile.compat

		for key, def in pairs(self.conflictDefs) do
			local found = FindLoadedAddon(def)
			if not found then
				-- External addon is gone — clear stale compat choice
				if db[key] then db[key] = nil end
			else
				-- External addon is loaded — check for conflict
				local tuiActive = def.tuiCheck(TUI.db.profile)
				local externalActive = not def.externalCheck or def.externalCheck()

				if tuiActive and externalActive then
					self.activeConflicts[key] = def
					-- Re-prompt regardless of previous choice — state has changed
					db[key] = nil
					local label = found.label
					local text = 'Looks like you have |cffff2f3d' .. label
						.. '|r and |cffff2f3dTrenchyUI|r installed.\nPlease select which '
						.. def.category .. ' you\'d prefer to use.'
					compatPopupQueue[#compatPopupQueue + 1] = {
						key = key, def = def,
						detectedLabel = label, popupText = text,
					}
				end
			end
		end

		if #compatPopupQueue > 0 then C_Timer.After(1, ShowNextCompatPopup) end
	end
end

function TUI:GetClassColor(classFilename)
	classFilename = classFilename or select(2, UnitClass('player'))
	if not classFilename then return nil end
	local c = E:ClassColor(classFilename)
	if c then return c.r, c.g, c.b end
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
		E.data.RegisterCallback(self, 'OnNewProfile', 'UpdateProfileReference')

		if self.InitSkinWarpDeplete then self:InitSkinWarpDeplete() end
		if self.InitSkinBigWigs then self:InitSkinBigWigs() end
		if self.InitQoL then self:InitQoL() end
		if self.InitElvNP then self:InitElvNP() end
		if self.InitSkinAuctionator then self:InitSkinAuctionator() end
		if not self:IsCompatBlocked('cooldownManager') and self.InitCooldownManager then self:InitCooldownManager() end
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
