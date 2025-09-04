-- TrenchyUI/Profiles/AddOnSkins.lua
local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}

NS.RegisterExternalProfile("AddOnSkins", function()
  if not NS.IsAddonLoaded("AddOnSkins") then return false end
  local ASgw = _G and rawget(_G, "AddOnSkins")
  if type(ASgw) ~= "table" then return false end
  local AS = unpack(ASgw)
  if type(AS) ~= "table" or not AS.data or not AS.db then return false end

  local name = "TrenchyUI"
  if AS.data and AS.data.SetProfile then AS.data:SetProfile(name) end

  -- Apply settings based on provided SavedVariables (Default profile)
  AS.db.Font = "Expressway"
  AS.db.FontSize = 14
  AS.db.Shadows = false
  AS.db.CropIcons = false
  AS.db.BackgroundTexture = "TrenchyBlank"
  AS.db.ElvUIStyle = false
  AS.db.StatusBarTexture = "TrenchyBlank"
  AS.db.ZygorGuidesViewer = false
  AS.db.FontFlag = "SHADOWOUTLINE"

  return true
end)
