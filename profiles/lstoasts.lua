local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local PROFILE_NAME = 'TrenchyUI'

function TUI:ApplyLSToastsProfile()
	local sv = LS_TOASTS_GLOBAL_CONFIG
	if not sv then
		LS_TOASTS_GLOBAL_CONFIG = {}
		sv = LS_TOASTS_GLOBAL_CONFIG
	end

	sv.profiles = sv.profiles or {}
	sv.profiles[PROFILE_NAME] = {
		font = {
			name = 'Expressway',
			size = 14,
		},
		skin = 'elv',
		anchors = {
			{
				point = {
					rP = 'TOP',
					p = 'TOP',
					x = 0,
					y = -268,
				},
				scale = 1.2,
				max_active_toasts = 6,
				growth_offset_y = 4,
				growth_offset_x = 4,
			},
		},
		types = {
			loot_currency = {
				enabled = true,
				vfx = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				tooltip = true,
				track_loss = false,
			},
			loot_special = {
				enabled = true,
				ilvl = true,
				legacy_equipment = true,
				tooltip = true,
				vfx = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				threshold = 1,
			},
			recipe = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				tooltip = true,
				vfx = true,
				left_click = false,
			},
			garrison_8_0 = {
				enabled = true,
				dnd = true,
				sfx = true,
				anchor = 1,
				tooltip = true,
				vfx = true,
			},
			loot_common = {
				enabled = true,
				ilvl = true,
				legacy_equipment = true,
				tooltip = true,
				vfx = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				threshold = 1,
				quest = false,
			},
			runecarving = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				tooltip = true,
				vfx = true,
			},
			collection = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				vfx = true,
				left_click = false,
			},
			world = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				vfx = true,
			},
			housing = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				vfx = true,
			},
			garrison_6_0 = {
				enabled = false,
				dnd = true,
				sfx = true,
				anchor = 1,
				tooltip = true,
				vfx = true,
			},
			activities = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				vfx = true,
			},
			instance = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				vfx = true,
			},
			achievement = {
				enabled = true,
				dnd = false,
				anchor = 1,
				tooltip = true,
				vfx = true,
				earned = false,
			},
			archaeology = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				tooltip = true,
				vfx = true,
			},
			garrison_9_0 = {
				enabled = true,
				dnd = true,
				sfx = true,
				anchor = 1,
				tooltip = true,
				vfx = true,
			},
			garrison_7_0 = {
				enabled = true,
				dnd = true,
				sfx = true,
				anchor = 1,
				tooltip = true,
				vfx = true,
			},
			loot_gold = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				track_loss = false,
				vfx = true,
				threshold = 1,
			},
			store = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				tooltip = true,
				vfx = true,
				left_click = false,
			},
			transmog = {
				enabled = true,
				dnd = false,
				sfx = true,
				anchor = 1,
				vfx = true,
				left_click = false,
			},
		},
	}

	sv.profileKeys = sv.profileKeys or {}
	sv.profileKeys[UnitName('player') .. ' - ' .. GetRealmName()] = PROFILE_NAME
end
