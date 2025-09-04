-- TrenchyUI/Profiles/WarpDeplete.lua
local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}

NS.RegisterExternalProfile("WarpDeplete", function()
  if not NS.IsAddonLoaded("WarpDeplete") then return false end
  local DB = rawget(_G, "WarpDepleteDB")
  if type(DB) ~= "table" then return false end
  DB.profiles = DB.profiles or {}
  DB.profileKeys = DB.profileKeys or {}

  local profileName = "TrenchyUI"

  -- If a profile named TrenchyUI already exists in SavedVariables, keep it; otherwise create it based on your SV defaults
  if type(DB.profiles[profileName]) ~= "table" then
    DB.profiles[profileName] = {
      -- Fonts/textures and sizing
      bar1Font = "Expressway",
      bar1FontSize = 14,
      bar1Texture = "TrenchyBlank",
      bar2Font = "Expressway",
      bar2FontSize = 14,
      bar2Texture = "TrenchyBlank",
      bar3Font = "Expressway",
      bar3FontSize = 14,
      bar3Texture = "TrenchyBlank",
      forcesFont = "Expressway",
      timerFont = "Expressway",
      objectivesFont = "Expressway",
      deathsFont = "Expressway",
      keyFont = "Expressway",
      keyDetailsFont = "Expressway",
      timerFontSize = 30,
      barHeight = 25,
      barPadding = 0.5,
      barWidth = 300,

      -- Positioning/behaviour
      frameAnchor = "TOPRIGHT",
      frameX = 19.39580345153809,
      frameY = -258.8146667480469,
      verticalOffset = 0,
      objectivesOffset = 2,
      timingsDisplayStyle = "hidden",
      deathLogStyle = "count",
      unclampForcesPercent = true,

      -- Colors and style
      completedObjectivesColor = "ff6dffa1",
      completedForcesColor = "ff6dffa1",
      objectivesColor = "ff858585",
      deathsColor = "ffff4f68",
      keyColor = "ffb1b1b1",
      timerRunningColor = "ffff313f",
      forcesColor = "ffc3c3c3",
      bar1TextureColor = "ffff313f",
      bar2TextureColor = "ffff303e",
      bar3TextureColor = "ffff303e",
      forcesTextureColor = "ffff303e",
      forcesTexture = "TrenchyBlank",
      forcesOverlayTexture = "TrenchyBlank",
      forcesOverlayTextureColor = "ffa8a9a2",
      forcesFormat = ":count:/:totalcount: - :percent:",

      -- Hint flag (used by our applier to favor class colors)
      forceClassColors = true,
    }
  end

  -- Ensure fonts are Expressway even if the profile already existed
  do
    local prof = DB.profiles[profileName]
    if type(prof) == "table" then
      prof.bar1Font = "Expressway"
      prof.bar2Font = "Expressway"
      prof.bar3Font = "Expressway"
      prof.forcesFont = "Expressway"
      prof.timerFont = "Expressway"
      prof.objectivesFont = "Expressway"
      prof.deathsFont = "Expressway"
      prof.keyFont = "Expressway"
      prof.keyDetailsFont = "Expressway"
    end
  end

  -- Set current character to use this profile
  local pname, prealm = UnitFullName and UnitFullName("player") or UnitName("player"), GetRealmName and GetRealmName() or ""
  local key = tostring(pname or "Player") .. " - " .. tostring(prealm or "Realm")
  DB.profileKeys[key] = profileName

  -- Incorporate class color styling (from WarpDeplete_ClassColors functionality)
  local LSM = _G.LibStub and _G.LibStub("LibSharedMedia-3.0", true)
  local function getClassRGB()
    local classToken = select(2, UnitClass("player"))
    local ccc = _G and rawget(_G, "CUSTOM_CLASS_COLORS")
    local rcc = _G and rawget(_G, "RAID_CLASS_COLORS")
    local c = (ccc and ccc[classToken]) or (rcc and rcc[classToken])
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
  end

  local function applyClassColors()
    local WD = rawget(_G, "WarpDeplete")
    if not WD then return end
    local r, g, b = getClassRGB()
    local bars = WD.bars
    local forces = WD.forces

    -- Optional: use LSM to fetch textures/fonts matching the profile
    local prof = DB.profiles[profileName]
    local sbTexName = prof and prof.bar1Texture or nil
    local forcesTexName = prof and prof.forcesTexture or nil
    local fontName = prof and prof.bar1Font or nil
    local sbTexPath = (LSM and sbTexName) and LSM:Fetch("statusbar", sbTexName) or nil
    local forcesTexPath = (LSM and forcesTexName) and LSM:Fetch("statusbar", forcesTexName) or nil
    local fontPath = (LSM and fontName) and LSM:Fetch("font", fontName) or nil

    if type(bars) == "table" then
      for i = 1, 3 do
        local bar = bars[i]
        if bar and bar.bar then
          if sbTexPath then bar.bar:SetStatusBarTexture(sbTexPath) end
          bar.bar:SetStatusBarColor(r, g, b, 1)
        end
        if fontPath and bar and bar.text and bar.text.SetFont then
          local _, size, flags = bar.text:GetFont()
          bar.text:SetFont(fontPath, size or 12, flags)
        end
      end
    end

    if type(forces) == "table" then
      if forces.bar then
        if forcesTexPath then forces.bar:SetStatusBarTexture(forcesTexPath) end
        forces.bar:SetStatusBarColor(r, g, b, 1)
      end
      if forces.overlayBar then
        if forcesTexPath then forces.overlayBar:SetStatusBarTexture(forcesTexPath) end
        forces.overlayBar:SetStatusBarColor(r, g, b, 0.7)
      end
      if fontPath and forces.text and forces.text.SetFont then
        local _, size, flags = forces.text:GetFont()
        forces.text:SetFont(fontPath, size or 12, flags)
      end
    end
  end

  -- If the standalone addon is present, don't duplicate its work
  local hasExternal = NS.IsAddonLoaded and NS.IsAddonLoaded("WarpDeplete_ClassColors")
  if not hasExternal then
    -- Hook WarpDeplete rendering to re-apply overrides
    NS.__WDClassColorHooked = NS.__WDClassColorHooked or false
    if not NS.__WDClassColorHooked then
      NS.__WDClassColorHooked = true
      local WD = rawget(_G, "WarpDeplete")
      if WD then
        if hooksecurefunc then
          if type(WD.RenderLayout) == "function" then hooksecurefunc(WD, "RenderLayout", function() if C_Timer and C_Timer.After then C_Timer.After(0, applyClassColors) else applyClassColors() end end) end
          if type(WD.RenderForces) == "function" then hooksecurefunc(WD, "RenderForces", function() if C_Timer and C_Timer.After then C_Timer.After(0, applyClassColors) else applyClassColors() end end) end
          if type(WD.OnProfileChanged) == "function" then hooksecurefunc(WD, "OnProfileChanged", function() if C_Timer and C_Timer.After then C_Timer.After(0, applyClassColors) else applyClassColors() end end) end
        end
      end
    end

    -- Apply once now (slightly delayed to let WD layout)
    if C_Timer and C_Timer.After then C_Timer.After(0.5, applyClassColors) else applyClassColors() end
  end

  return true
end)
