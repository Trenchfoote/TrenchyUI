local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local ipairs = ipairs

local function ApplyBarClassColors()
	local r, g, b = TUI:GetClassColor()
	if not r then return end

	if WarpDeplete.bars then
		for _, bar in ipairs(WarpDeplete.bars) do
			if bar.frame and bar.frame.SetBackdropColor then
				bar.frame:SetBackdropColor(r, g, b, 1)
			end
		end
	end

	if WarpDeplete.forces and WarpDeplete.forces.frame and WarpDeplete.forces.frame.SetBackdropColor then
		WarpDeplete.forces.frame:SetBackdropColor(r, g, b, 1)
	end
end

function TUI:InitSkinWarpDeplete()
	if not WarpDeplete or not WarpDeplete.RenderLayout then return end
	if not self.db or not self.db.profile.addons or not self.db.profile.addons.skinWarpDeplete then return end

	hooksecurefunc(WarpDeplete, 'RenderLayout', ApplyBarClassColors)
end
