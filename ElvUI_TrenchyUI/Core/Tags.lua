local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}

-- ElvUI presence guard
local ElvUI = _G and rawget(_G, 'ElvUI')
if not ElvUI then return end
local E = unpack(ElvUI)
local ElvUF = _G and rawget(_G, 'ElvUF')
if not (ElvUF and ElvUF.Tags) then return end

local Tags = ElvUF.Tags
local UNKNOWN = _G and rawget(_G, 'UNKNOWN') or 'Unknown'

-- Tag registration helper
local function AddTag(name, events, fn, desc, classicOnly)
  E:AddTag(name, events, fn, classicOnly)
  local CATEGORY = '|cffff2f3dTrenchy|r Tags'
  E:AddTagInfo(name, CATEGORY, desc or name, nil, classicOnly)
end

-- Utility: get last word of a name
local function lastNamePart(str)
  if not str then return nil end
  if not string.find(str, '%s') then return str end
  return string.match(str, '([%S]+)$')
end

-- trenchy:health - whole percent including absorbs, no % sign
AddTag('trenchy:health', 'UNIT_HEALTH UNIT_MAXHEALTH UNIT_ABSORB_AMOUNT_CHANGED', function(unit)
  local cur, max = UnitHealth(unit) or 0, UnitHealthMax(unit) or 0
  if max == 0 then return '' end
  local absorb = (UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit)) or 0
  local total = cur + (absorb or 0)
  if total < 0 then total = 0 end
  if total > max then total = max end
  return tostring(math.floor((total / max) * 100 + 0.5))
end, "Health percent including absorbs (no % sign)")

-- trenchy:name - last name only, truncated to 16 chars, no color
AddTag('trenchy:name', 'UNIT_NAME_UPDATE INSTANCE_ENCOUNTER_ENGAGE_UNIT', function(unit)
  local name = UnitName(unit) or UNKNOWN
  local last = lastNamePart(name) or name
  return E:ShortenString(last, 16)
end, "Last name only, truncated to 16 characters")

-- trenchy:mana - healer-only mana percent, color by thresholds, no % sign
AddTag('trenchy:mana', 'UNIT_MAXPOWER UNIT_POWER_FREQUENT UNIT_DISPLAYPOWER PLAYER_ROLES_ASSIGNED GROUP_ROSTER_UPDATE', function(unit)
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
end, "Healer mana percent with threshold colors (no % sign)")
