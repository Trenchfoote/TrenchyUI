local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UF = E:GetModule('UnitFrames')
local LCG = E.Libs.CustomGlow

local GLOW_KEY = 'TUI_PixelGlow'

local function GetPixelGlowDB()
	local db = TUI.db and TUI.db.profile and TUI.db.profile.pixelGlow
	if not db then return false, 8, 0.25, 2 end
	return db.enabled, db.lines, db.speed, db.thickness
end

local function AfterElvUIPostUpdate(element, frame, unit, aura, debuffType, texture, wasFiltered, style, color)
	if not LCG or not LCG.PixelGlow_Start then return end

	local _, lines, speed, thickness = GetPixelGlowDB()
	local glowTarget = frame.Health or frame

	if aura or debuffType then
		local r, g, b, a = element:GetVertexColor()

		element:SetVertexColor(0, 0, 0, 0)
		if frame.AuraHightlightGlow then frame.AuraHightlightGlow:Hide() end

		LCG.PixelGlow_Start(glowTarget, { r, g, b, a }, lines, speed, nil, thickness, 0, 0, false, GLOW_KEY)
	else
		element:SetVertexColor(0, 0, 0, 0)
		if frame.AuraHightlightGlow then frame.AuraHightlightGlow:Hide() end
		LCG.PixelGlow_Stop(glowTarget, GLOW_KEY)
	end
end

function TUI:InitPixelGlow()
	local enabled = GetPixelGlowDB()
	if not enabled then return end

	if E.db.unitframe.debuffHighlighting == 'NONE' then
		E.db.unitframe.debuffHighlighting = 'FILL'
	end

	hooksecurefunc(UF, 'Configure_AuraHighlight', function(_, frame)
		if not frame or not frame.AuraHighlight then return end

		frame.AuraHighlightBackdrop = false
		if frame.AuraHightlightGlow then frame.AuraHightlightGlow:Hide() end

		local elvuiPostUpdate = frame.AuraHighlight.PostUpdate
		frame.AuraHighlight.PostUpdate = function(element, fr, ...)
			if elvuiPostUpdate then elvuiPostUpdate(element, fr, ...) end
			AfterElvUIPostUpdate(element, fr, ...)
		end
	end)
end
