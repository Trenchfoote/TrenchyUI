-- TrenchyUI/Profiles/OmniCD.lua
local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}

NS.RegisterExternalProfile("OmniCD", function()
  if not NS.IsAddonLoaded("OmniCD") then return false end
  -- Try to import the provided OmniCD export string using LibDeflate + AceSerializer
  local profileName = "TrenchyUI"
  local export = 'DAv3UTTXs4xOMIDN9)lpsooWaPYbLo402likTeTmrOifiPITYf9z)8T7SuwYXheKEHTgm)pFZWz2sz5DLfFOUREOQns(qF30yKyCQA6W4IQHe32QTLf3(57(4nREpRuzX7FE)q944tvhH2nFRUCfPlb)M19DZU6sT6Fy8pkxjNvxAJQx1T(X(FMOKmdsMQFE6aK9Dz7IpuwC3qn87XfTvDFPS4Ei4swtSp(u1W0XOn7NjGthQGJsUDOQzdOPKGUQ7BR3uUOSyxv3HQ2p1)D6CS8ABqQ9MGs59KsheLp8oTPS45YR9cJ2husVYiKsVokrZPX(QnBA62MbN1vTOmf)QRSOT6y)bOaqOMVb8anPIH6nnd1RNkV)S6()2Sz6XyhGkl6Q2vxwSCzeWFySEID70WHU1vt1fZMSkQ2keKdDntrOdvwB)6VW14y)W0IJLRcq(y9YdJt97w2wnoUSVThOZItz9FgD)0jGqXW5CbPollOlI1pQoFluwnJYoRqyLsNJuoJWWyzeLbFsB9sPMCssrrjQ52D2lPH(Xh7F6MUP6HHd7NQ3uSVUTncPVvyL5WAuHGXfccVrBDg1lH15TocTxPXB1cR6h3Cj(lLBNbN3zsi9nG3)PD)Jvji61TxV)8EegRZDJyQwV(XQHT1jorgBrya74)JFMTEQ5RViCMDt3ReSLfarBh6F6Z7FQAifRZhLIZgxLMbBWN6fBgx))D8cFS(to)OtnNxM(ER(HEEmGcIaaEb(1rw9fJb4JmmeeCbHHCN1p4pp(Wq)H9)ZFFv9d1DJaagzHNhTvYZN2csHwrkLlOE10MrlXh9chuyEABf9V3uZlMkTgLpk2b6lmvIQglACAlPfVmJxmghJtqL0BvExCIwgcATpI4kzqzsSKEHYZc9gFisHiPC2ifbXEz0aTqzvYKEElzt2IvBHelLvid6Kqf(Ml5e4lpZIubrMI0ob7dNN4ucXYMKIENKZeL1hy9aLwsjkKsukyi4sUCiLHKHt2Y8eqQG1JKw2cHZMZfH25uCDtSFnintYSAIHbRXWLN3caNHbRIlEfAqQKEER1WOfAngUQSqkJQUCErsJLs4N3fy)liJMtbHnyyivAiHIltGrC0dsPGda2RLlyHwi5MfMvyBncLsZgyjVLRP4iXSASbgjX1Iu4ZuKiqg2BqDMNgORyonTmvqO4QrkCghhRyRKZn4nwiroVIlApXMQX0UNJAWlSPAWNtdmHPc5C0ySCoAuzKryZ9FrWW9jVEE(trgxkT92GMDriUKpx6Y8iwe2MbnEYbnuv4eUW(LWz4G5ep2umMMdQneC5QJYbfl7J9tl6yzVIwm3ECgOFQsixIJvQuPsd3)PK5yXnyMHj5PjctEWhDDlNm28yj(6HyW07ejNQDgFkJ1sTnBi(mnPn2JK)gchGO5VRL65UMkdjoYNromWXPJbzwU1hO0wI8t443vD2nA(ca2w)o5fNdYRUxEvr0ImqHyHVlIu(4NClYJrI0wiSWM3hbyBX5RBs1FIxCNLHTlUa3XEi7jSfBwFJsMN5qv65vw8p2G1N1josakm3iyFJ1f8(qqzzENv977hBsx2U7YZExCiNF26V1pGBjF89xFx80XZRoS7Me0f1yDF7HDz6xDQB7lp4o(mKFVQBBDo2dn4jq8trNgA6(sD6ycK8Wq8UfyVPzSAyx61uRxN(zcVO90HS4tUMpeCD2MvkVIWcAO8Q81GizE)jYPv51WmzAVzKmHyPWhVB23v)x4VI6PjulZVzgZi4PXiTFlzFTzS5(M2CbvHxGxf7wZMer(OB5AFB8KCr8n(3DMk4EiRdi4NXvE7UUMLxrvTT)YTDTh)ulE3X4)7'

  local ok, applied = false, false
  local LibStub = _G.LibStub
  local LibDeflate = LibStub and LibStub("LibDeflate", true)
  local AceSerializer = LibStub and LibStub("AceSerializer-3.0", true)

  local function pickProfileTable(decoded)
    if type(decoded) ~= "table" then return nil end
    if decoded.Party or decoded.General then return decoded end
    if decoded.profile then return decoded.profile end
    if decoded.profiles and type(decoded.profiles) == "table" then
      for _, v in pairs(decoded.profiles) do
        if type(v) == "table" and (v.Party or v.General) then return v end
      end
    end
    for _, v in pairs(decoded) do
      if type(v) == "table" and (v.Party or v.General) then return v end
    end
    return nil
  end

  local decodedTbl
  if LibDeflate and AceSerializer and type(LibDeflate.DecodeForPrint) == "function" then
    local compressed = LibDeflate:DecodeForPrint(export)
    if compressed then
      local decompressed = LibDeflate:DecompressDeflate(compressed)
      if decompressed then
        local success, data = AceSerializer:Deserialize(decompressed)
        if success then decodedTbl = data end
      end
    end
  end

  local profileTbl = pickProfileTable(decodedTbl)
  if profileTbl then
    local DB = rawget(_G, "OmniCDDB")
    if type(DB) ~= "table" then
      -- Attempt to initialize the global DB table safely
      local okSet = pcall(function()
        _G["OmniCDDB"] = {}
      end)
      DB = okSet and rawget(_G, "OmniCDDB") or {}
    end
    DB.profiles = DB.profiles or {}
    DB.global = DB.global or {}
    DB.cooldowns = DB.cooldowns or {}
    DB.version = DB.version or 4
    DB.global.disableElvMsg = true

    DB.profiles[profileName] = profileTbl
    ok = true
  end

  -- Activate the profile for the current character via AceDB if available
  local OmniCDArr = rawget(_G, "OmniCD")
  local OCE = (type(OmniCDArr) == "table" and OmniCDArr[1]) or nil
  if ok and OCE and OCE.db and type(OCE.db.SetProfile) == "function" then
    pcall(function() OCE.db:SetProfile(profileName) end)
    applied = true
  end

  -- Integrate OmniCD_CustomColors reanchor hook if present
  local ccHook = rawget(_G, "ensureIconOffsetHook")
  if NS.IsAddonLoaded("OmniCD_CustomColors") and type(ccHook) == "function" then
    pcall(function() ccHook() end)
  end

  -- Refresh OmniCD bars to reflect changes
  if OCE and OCE.Party and type(OCE.Party.UpdateAllBars) == "function" then
    pcall(function() OCE.Party:UpdateAllBars() end)
  end

  return applied
end)
