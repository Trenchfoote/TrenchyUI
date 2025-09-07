local E = unpack(ElvUI)
local ElvUI_TrenchyUI = E:GetModule('ElvUI_TrenchyUI')
local UNKNOWN = _G.UNKNOWN or 'Unknown'

-- Trenchy's custom tags

-- trenchy:health - health percent including absorbs (no % sign) with status
E:AddTag("trenchy:health", "UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED UNIT_CONNECTION UNIT_FLAGS PLAYER_FLAGS_CHANGED", function(unit)
    if not UnitIsConnected(unit) then
        return "Offline"
    end

    local class = select(2, UnitClass(unit))
    local color, colorStr = class and E:ClassColor(class)
    local classHex = colorStr or (color and (E.RGBToHex and E:RGBToHex(color.r, color.g, color.b)) or nil)

    if UnitIsDead(unit) then
        return classHex and (classHex .. "Dead|r") or "Dead"
    end
    if UnitIsGhost(unit) then
        return classHex and (classHex .. "Ghost|r") or "Ghost"
    end
    if UnitIsAFK(unit) then
        return "|cffffffff[|r|cffff0000AFK|r|cffffffff]|r"
    end
    if UnitIsDND(unit) then
        return "|cffffffff[|r|cffff0000DND|r|cffffffff]|r"
    end

    local cur, max = UnitHealth(unit) or 0, UnitHealthMax(unit) or 0
    if max == 0 then return '' end
    local absorb = (UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit)) or 0
    local total = cur + (absorb or 0)
    if total < 0 then total = 0 end
    return tostring(math.floor((total / max) * 100 + 0.5))
end)
E:AddTagInfo("trenchy:health", ElvUI_TrenchyUI.Title, "Health percent including absorbs (no % sign) with status")

-- trenchy:name - last name only, truncated to 16 characters
E:AddTag("trenchy:name", "UNIT_NAME_UPDATE", function(unit)
    local name = UnitName(unit) or UNKNOWN
    local last = string.match(name, "%S+$") or name
    return E:ShortenString(last, 16)
end)
E:AddTagInfo("trenchy:name", ElvUI_TrenchyUI.Title, "Last name only, truncated to 16 characters")

-- trenchy:class:name - last name only, truncated to 16 characters, colored by class
E:AddTag("trenchy:class:name", "UNIT_NAME_UPDATE", function(unit)
    local name = UnitName(unit) or UNKNOWN
    local last = string.match(name, "%S+$") or name
    local short = E:ShortenString(last, 16)

    local class = select(2, UnitClass(unit))
    local color, colorStr = class and E:ClassColor(class)
    local hex = colorStr or (color and (E.RGBToHex and E:RGBToHex(color.r, color.g, color.b)) or nil)
    return hex and (hex .. short .. "|r") or short
end)
E:AddTagInfo("trenchy:class:name", ElvUI_TrenchyUI.Title, "Last name only, truncated to 16 characters, colored by class")

-- trenchy:mana - healer-only mana percent, color by thresholds, no % sign
E:AddTag("trenchy:mana", "UNIT_MAXPOWER UNIT_POWER_FREQUENT UNIT_DISPLAYPOWER PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE", function(unit)
	if UnitGroupRolesAssigned(unit) ~= 'HEALER' then return '' end
	local P_MANA = (_G.Enum and _G.Enum.PowerType and _G.Enum.PowerType.Mana) or 0
	local cur, max = UnitPower(unit, P_MANA) or 0, UnitPowerMax(unit, P_MANA) or 0
	if max == 0 then return '' end
	local pct = math.floor((cur / max) * 100 + 0.5)
	local hex
	if pct >= 51 then
		hex = '|cff7db5ff'
	elseif pct >= 26 then
		hex = '|cfffff78a'
	else
		hex = '|cffff2935'
	end
	return string.format('%s%d|r', hex, pct)
end)
E:AddTagInfo("trenchy:mana", ElvUI_TrenchyUI.Title, "Healer mana percent with threshold colors (no % sign)")

-- trenchy:role - leader and/or role letters (L/T/H) with custom colors
E:AddTag("trenchy:role", "GROUP_ROSTER_UPDATE RAID_ROSTER_UPDATE PARTY_LEADER_CHANGED PLAYER_ROLES_ASSIGNED UNIT_NAME_UPDATE PLAYER_ENTERING_WORLD", function(unit)
    if not unit then return '' end
    -- only show for units in your current group/raid
    if not IsInGroup() and not IsInRaid() then return '' end

    local out = {}

    if UnitIsGroupLeader(unit) then
        out[#out+1] = "|cffffc948L|r"
    end

    local role = UnitGroupRolesAssigned(unit)
    if role == "TANK" then
        out[#out+1] = "|cff684932T|r"
    elseif role == "HEALER" then
        out[#out+1] = "|cff2a6824H|r"
    end

    return table.concat(out)
end)
E:AddTagInfo("trenchy:role", ElvUI_TrenchyUI.Title, "Leader (L, gold) and/or role: T (brown) / H (green). Empty for DPS/none.")
