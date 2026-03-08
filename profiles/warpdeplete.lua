local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local PROFILE_NAME = 'TrenchyUI'

function TUI:ApplyWarpDepleteProfile()
	if not WarpDepleteDB then
		WarpDepleteDB = {}
	end

	WarpDepleteDB.profiles = WarpDepleteDB.profiles or {}
	WarpDepleteDB.profiles[PROFILE_NAME] = {
		['bar1FontSize'] = 20,
		['bar1Texture'] = 'ElvUI Blank',
		['bar1TextureColor'] = 'ff2d2d2d',
		['bar2FontSize'] = 20,
		['bar2Texture'] = 'ElvUI Blank',
		['bar2TextureColor'] = 'ff2d2d2d',
		['bar3FontSize'] = 20,
		['bar3Texture'] = 'ElvUI Blank',
		['bar3TextureColor'] = 'ff2d2d2d',
		['barHeight'] = 25,
		['completedForcesColor'] = 'ffff27cc',
		['completedObjectivesColor'] = 'ff00ff24',
		['forcesColor'] = 'ffffffff',
		['forcesFontSize'] = 20,
		['forcesOverlayTexture'] = 'ElvUI Blank',
		['forcesTexture'] = 'ElvUI Blank',
		['forcesTextureColor'] = 'ff2d2d2d',
		['frameAnchor'] = 'TOPRIGHT',
		['frameX'] = 17,
		['frameY'] = -320,
		['frameScale'] = 0.8300000000000001,
		['objectivesFontSize'] = 20,
		['showTooltipCount'] = false,
	}

	WarpDepleteDB.profileKeys = WarpDepleteDB.profileKeys or {}
	WarpDepleteDB.profileKeys[UnitName('player') .. ' - ' .. GetRealmName()] = PROFILE_NAME

	if WarpDeplete and WarpDeplete.db and WarpDeplete.db.SetProfile then
		WarpDeplete.db:SetProfile(PROFILE_NAME)
	end
end
