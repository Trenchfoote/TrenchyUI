-- TrenchyUI/Profiles/Common.lua
local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}

-- Branding used for optional prints
NS._BRAND_HEX = NS._BRAND_HEX or "ff2f3d"
NS._BRAND = NS._BRAND or ("|cff"..NS._BRAND_HEX.."TrenchyUI|r")

-- Table of external profile appliers
NS.ExternalProfileAppliers = NS.ExternalProfileAppliers or {}

-- Safe addon-loaded check
function NS.IsAddonLoaded(name)
  local CA = _G and rawget(_G, "C_AddOns")
  local ok = (CA and CA.IsAddOnLoaded and CA.IsAddOnLoaded(name))
  if ok == nil and _G then
    local isLoaded = rawget(_G, "IsAddOnLoaded")
    if type(isLoaded) == "function" then ok = isLoaded(name) end
  end
  return ok == true or ok == 1
end

-- Register an applier to a central list
function NS.RegisterExternalProfile(name, applyFn)
  if type(applyFn) ~= "function" then return end
  table.insert(NS.ExternalProfileAppliers, { name = name, apply = applyFn })
end

-- Run all registered external profile appliers (protected)
function NS.ApplyAllExternalProfiles()
  if not NS.ExternalProfileAppliers then return 0 end
  local count = 0
  for _, item in ipairs(NS.ExternalProfileAppliers) do
    local ok, applied = pcall(item.apply)
    if ok and applied then count = count + 1 end
  end
  return count
end
