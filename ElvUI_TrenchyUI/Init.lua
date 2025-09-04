-- TrenchyUI/Init.lua
local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}

-- Basic addon metadata helpers
local function GetMeta(field)
  local CA = _G and rawget(_G, 'C_AddOns')
  if CA and type(CA.GetAddOnMetadata) == 'function' then
    local v = CA.GetAddOnMetadata(AddonName, field)
    if v ~= nil then return v end
  end
  local GAM = _G and rawget(_G, 'GetAddOnMetadata')
  if type(GAM) == 'function' then
    return GAM(AddonName, field)
  end
end

NS.AddonName = AddonName
NS.Title = GetMeta('Title') or AddonName
NS.Version = GetMeta('Version') or '1.0.0'
NS.Author = GetMeta('Author') or 'Unknown'

-- Centralized branding (used elsewhere if not already set)
NS.BRAND_HEX = NS.BRAND_HEX or 'ff2f3d'
NS.BRAND = NS.BRAND or ('|cff' .. NS.BRAND_HEX .. 'TrenchyUI|r')

-- Optional: shared LibSharedMedia handle
NS.LSM = _G.LibStub and _G.LibStub('LibSharedMedia-3.0', true) or nil
