-- TrenchyUI/Install.lua
local AddonName, NS = ...
local _G = _G or getfenv and getfenv(0) or {}
local E

local BRAND_HEX = "ff2f3d"
local BRAND     = "|cff"..BRAND_HEX.."TrenchyUI|r"

-- ---------- helpers ----------
local function SnapshotProfile() if not E then return end return E:CopyTable({}, E.db) end
local function RestoreSnapshot(snap) if not (E and snap) then return end E:CopyTable(E.db, snap) end
local function Commit() if E then E:StaggeredUpdateAll() end end

-- ---------- layouts ----------
local function ApplyBase()
  E.db.general = E.db.general or {}
  E.db.actionbar = E.db.actionbar or {}
  E.db.unitframe = E.db.unitframe or { units = {} }
  E.db.unitframe.units = E.db.unitframe.units or {}

  E.db.general.minimap = E.db.general.minimap or {}
  E.db.general.minimap.size = 200

  E.db.actionbar.bar1 = E.db.actionbar.bar1 or { enabled = true, buttons = 12, buttonsPerRow = 12 }
  E.db.actionbar.bar2 = E.db.actionbar.bar2 or { enabled = true, buttons = 12, buttonsPerRow = 12 }

  local U = E.db.unitframe.units
  U.player = U.player or {}
  U.player.width, U.player.height = 260, 48
  U.player.power = U.player.power or {}
  U.player.power.enable = true
end

local function ApplyDPSTank()
  ApplyBase()
  local U = E.db.unitframe.units
  U.target = U.target or {}
  U.target.width, U.target.height = 260, 48
  U.focus = U.focus or {}
  U.focus.width, U.focus.height = 220, 40
  U.boss = U.boss or {}
  U.boss.width, U.boss.height = 200, 40
  U.player.castbar = U.player.castbar or {}
  U.player.castbar.width, U.player.castbar.height = 260, 20

  E.db.nameplates = E.db.nameplates or {}
  E.db.nameplates.plateSize = { enemyWidth = 135, enemyHeight = 18, friendlyWidth = 135, friendlyHeight = 18 }
end

local function HealerWIPNotice()
  print(BRAND.." Healer layout is currently |cffff4444WIP|r and not applied.")
end

-- ---------- page builders ----------
local function Page_Welcome()
  local f = _G and rawget(_G, "PluginInstallFrame")
  f.SubTitle:SetText("Welcome")
  f.Desc1:SetText("Thanks for trying "..BRAND.."!")
  f.Desc2:SetText("We’ll snapshot your current ElvUI profile so you can revert anytime.")
  f.Desc3:SetText("Use |cffffff00/trenchyui install|r to reopen this wizard.")
  f.Desc4:SetText("Click Continue to proceed.")

  f.Option1:Show(); f.Option1:SetText("Continue")
  f.Option2:Hide(); f.Option3:Hide(); f.Option4:Hide()
  f.Option1:SetScript("OnClick", function() E:GetModule("PluginInstaller"):NextPage() end)

  f.tutorialImage:SetTexture(nil); f.tutorialImage2:SetTexture(nil)
end

local function Page_Choose()
  local f = _G and rawget(_G, "PluginInstallFrame")
  f.SubTitle:SetText("Choose a layout")
  f.Desc1:SetText("|cff00ff88DPS/Tank|r is ready to apply.")
  f.Desc2:SetText("|cffff4444Healer|r is WIP and won’t apply changes yet.")
  f.Desc3:SetText("You can also revert to your snapshot if you change your mind.")
  f.Desc4:SetText("")

  f.Option1:Show(); f.Option1:SetText(BRAND.." – Apply DPS/Tank")
  f.Option1:SetScript("OnClick", function()
    NS._snapshot = NS._snapshot or SnapshotProfile()
    -- Try Distributor-driven import first for future proofing.
    local imported = false
    if NS.ImportProfileStrings then
      imported = NS.ImportProfileStrings()
      -- Optional UIScale hook (no-op unless you set a value elsewhere)
      if NS.ApplyUIScaleAfterImport then NS.ApplyUIScaleAfterImport(NS.UIScale) end
    end
    if not imported then
      ApplyDPSTank()
      Commit()
    end
  end)

  f.Option2:Show(); f.Option2:SetText(BRAND.." – Healer (WIP)")
  f.Option2:SetScript("OnClick", HealerWIPNotice)

  f.Option3:Show(); f.Option3:SetText("Revert snapshot")
  f.Option3:SetScript("OnClick", function()
    if NS._snapshot then
      RestoreSnapshot(NS._snapshot); Commit()
      print(BRAND..": Snapshot restored.")
    else
      print(BRAND..": No snapshot yet (apply a layout first).")
    end
  end)

  f.Option4:Hide()
  f.tutorialImage:SetTexture(nil); f.tutorialImage2:SetTexture(nil)
end

local function Page_Finish()
  local f = _G and rawget(_G, "PluginInstallFrame")
  f.SubTitle:SetText("Finish")
  f.Desc1:SetText("Click |cffffff00Apply & Reload|r to finalize "..BRAND..".")
  f.Desc2:SetText("Reopen anytime with |cffffff00/trenchyui install|r.")
    f.Desc3:SetText("Now including aurafilters.")
    f.Desc4:SetText("Make sure to check your settings.")

  f.Option1:Show(); f.Option1:SetText(BRAND.." – Apply & Reload UI")
  f.Option1:SetScript("OnClick", function()
    E.global.TrenchyUI = E.global.TrenchyUI or {}
    E.global.TrenchyUI.installed = true
    ReloadUI()
  end)
  f.Option2:Hide(); f.Option3:Hide(); f.Option4:Hide()
  f.tutorialImage:SetTexture(nil); f.tutorialImage2:SetTexture(nil)
end

-- ---------- installer wiring ----------
function NS.SetupInstaller()
  local engine = _G and rawget(_G, "ElvUI")
  if not (engine and engine[1]) then return end
  E = engine[1]
  local PI = E:GetModule("PluginInstaller")
  if not PI then
    print(BRAND..": ElvUI PluginInstaller not found.")
    return
  end

  local data = {
    Title = BRAND,         -- colored title in installer
    Name  = "TrenchyUI",   -- plain internal name
    tutorialImage = nil,
    StepTitles = { "Welcome", "Layout", "Finish" },
    Pages = { Page_Welcome, Page_Choose, Page_Finish },
  }

  NS.ShowInstaller = function()
    if PI.Queue then PI:Queue(data)
    elseif PI.InstallPackage then PI:InstallPackage(data)
    elseif PI.Show then PI:Show(data)
    else print(BRAND..": Installer UI not available.") end
  end
end
