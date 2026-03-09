local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local CH  = E:GetModule('Chat')
local S   = E:GetModule('Skins')
local LSM = E.Libs.LSM

if not C_DamageMeter or not Enum.DamageMeterType then return end

local MAX_BARS      = 40
local PANEL_INSET   = 2
local HEADER_HEIGHT = 22

local COMBINED_DAMAGE  = "CombinedDamage"
local COMBINED_HEALING = "CombinedHealing"

local COMBINED_DATA_TYPE = {
    [COMBINED_DAMAGE]  = Enum.DamageMeterType.DamageDone,
    [COMBINED_HEALING] = Enum.DamageMeterType.HealingDone,
}

local MODE_ORDER = {
    Enum.DamageMeterType.DamageDone,
    Enum.DamageMeterType.Dps,
    COMBINED_DAMAGE,
    Enum.DamageMeterType.HealingDone,
    Enum.DamageMeterType.Hps,
    COMBINED_HEALING,
    Enum.DamageMeterType.Absorbs,
    Enum.DamageMeterType.Interrupts,
    Enum.DamageMeterType.Dispels,
    Enum.DamageMeterType.DamageTaken,
    Enum.DamageMeterType.AvoidableDamageTaken,
}
if Enum.DamageMeterType.Deaths           then MODE_ORDER[#MODE_ORDER + 1] = Enum.DamageMeterType.Deaths           end
if Enum.DamageMeterType.EnemyDamageTaken then MODE_ORDER[#MODE_ORDER + 1] = Enum.DamageMeterType.EnemyDamageTaken end

local function ResolveMeterType(modeEntry)
    return COMBINED_DATA_TYPE[modeEntry] or modeEntry
end

local MODE_LABELS = {
    [Enum.DamageMeterType.DamageDone]           = "Damage",
    [Enum.DamageMeterType.Dps]                  = "DPS",
    [COMBINED_DAMAGE]                           = "DPS/Damage",
    [Enum.DamageMeterType.HealingDone]          = "Healing",
    [Enum.DamageMeterType.Hps]                  = "HPS",
    [COMBINED_HEALING]                          = "HPS/Healing",
    [Enum.DamageMeterType.Absorbs]              = "Absorbs",
    [Enum.DamageMeterType.Interrupts]           = "Interrupts",
    [Enum.DamageMeterType.Dispels]              = "Dispels",
    [Enum.DamageMeterType.DamageTaken]          = "Damage Taken",
    [Enum.DamageMeterType.AvoidableDamageTaken] = "Avoidable Damage Taken",
}
if Enum.DamageMeterType.Deaths           then MODE_LABELS[Enum.DamageMeterType.Deaths]           = "Deaths"              end
if Enum.DamageMeterType.EnemyDamageTaken then MODE_LABELS[Enum.DamageMeterType.EnemyDamageTaken] = "Enemy Damage Taken"   end

local MODE_SHORT = {
    [Enum.DamageMeterType.DamageDone]           = "Damage",
    [Enum.DamageMeterType.Dps]                  = "DPS",
    [COMBINED_DAMAGE]                           = "DPS/Dmg",
    [Enum.DamageMeterType.HealingDone]          = "Healing",
    [Enum.DamageMeterType.Hps]                  = "HPS",
    [COMBINED_HEALING]                          = "HPS/Heal",
    [Enum.DamageMeterType.Absorbs]              = "Absorbs",
    [Enum.DamageMeterType.Interrupts]           = "Interrupts",
    [Enum.DamageMeterType.Dispels]              = "Dispels",
    [Enum.DamageMeterType.DamageTaken]          = "Dmg Taken",
    [Enum.DamageMeterType.AvoidableDamageTaken] = "Avoidable",
}
if Enum.DamageMeterType.Deaths           then MODE_SHORT[Enum.DamageMeterType.Deaths]           = "Deaths"    end
if Enum.DamageMeterType.EnemyDamageTaken then MODE_SHORT[Enum.DamageMeterType.EnemyDamageTaken] = "Enemy Dmg" end

local SESSION_LABELS = {
    [Enum.DamageMeterSessionType.Current] = "Current",
    [Enum.DamageMeterSessionType.Overall] = "Overall",
}

StaticPopupDialogs["TRENCHYUI_METER_RESET"] = {
    text         = "Reset all Trenchy Damage Meter data?",
    button1      = ACCEPT,
    button2      = CANCEL,
    OnAccept     = function()
        C_DamageMeter.ResetAllCombatSessions()
        TUI:RefreshMeter()
    end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local windows  = {}
local testMode = false

local classCache = {}
local spellCache = {}

local CLASS_ICON_COORDS = {
    WARRIOR     = {0,      0.25,  0,     0.25},
    MAGE        = {0.25,   0.5,   0,     0.25},
    ROGUE       = {0.5,    0.75,  0,     0.25},
    DRUID       = {0.75,   1,     0,     0.25},
    HUNTER      = {0,      0.25,  0.25,  0.5 },
    SHAMAN      = {0.25,   0.5,   0.25,  0.5 },
    PRIEST      = {0.5,    0.75,  0.25,  0.5 },
    WARLOCK     = {0.75,   1,     0.25,  0.5 },
    PALADIN     = {0,      0.25,  0.5,   0.75},
    DEATHKNIGHT = {0.25,   0.5,   0.5,   0.75},
    MONK        = {0.5,    0.75,  0.5,   0.75},
    DEMONHUNTER = {0.75,   1,     0.5,   0.75},
    EVOKER      = {0,      0.25,  0.75,  1   },
}

TUI._meterTestMode = false

local TEST_DATA = {
    { name = "Deathknight",   value = 980000, class = "DEATHKNIGHT",
      spells = {{49020, 340000}, {49143, 280000}, {49184, 195000}, {196770, 110000}, {6603, 55000}} },
    { name = "Demonhunter",   value = 920000, class = "DEMONHUNTER",
      spells = {{198013, 310000}, {188499, 260000}, {162794, 200000}, {258920, 100000}, {6603, 50000}} },
    { name = "Warrior",       value = 860000, class = "WARRIOR",
      spells = {{12294, 290000}, {163201, 240000}, {7384, 180000}, {262115, 100000}, {6603, 50000}} },
    { name = "Mage",          value = 800000, class = "MAGE",
      spells = {{11366, 280000}, {108853, 220000}, {133, 170000}, {12654, 90000}, {257541, 40000}} },
    { name = "Hunter",        value = 740000, class = "HUNTER",
      spells = {{19434, 260000}, {257044, 200000}, {185358, 150000}, {75, 90000}, {53351, 40000}} },
    { name = "Rogue",         value = 680000, class = "ROGUE",
      spells = {{196819, 240000}, {1752, 190000}, {315341, 140000}, {13877, 75000}, {6603, 35000}} },
    { name = "Warlock",       value = 620000, class = "WARLOCK",
      spells = {{116858, 220000}, {29722, 170000}, {348, 120000}, {5740, 70000}, {17962, 40000}} },
    { name = "Evoker",        value = 560000, class = "EVOKER",
      spells = {{357208, 200000}, {356995, 160000}, {361469, 110000}, {357211, 60000}, {362969, 30000}} },
    { name = "Shaman",        value = 500000, class = "SHAMAN",
      spells = {{188196, 180000}, {51505, 140000}, {188443, 100000}, {188389, 55000}, {8042, 25000}} },
    { name = "Paladin",       value = 440000, class = "PALADIN",
      spells = {{85256, 160000}, {184575, 120000}, {255937, 90000}, {26573, 45000}, {6603, 25000}} },
    { name = "Monk",          value = 380000, class = "MONK",
      spells = {{107428, 140000}, {100784, 105000}, {113656, 80000}, {100780, 35000}, {101546, 20000}} },
    { name = "Druid",         value = 320000, class = "DRUID",
      spells = {{78674, 120000}, {194153, 90000}, {190984, 60000}, {93402, 35000}, {8921, 15000}} },
    { name = "Priest",        value = 260000, class = "PRIEST",
      spells = {{8092, 100000}, {32379, 70000}, {34914, 45000}, {589, 30000}, {15407, 15000}} },
    { name = "Deathknight2",  value = 210000, class = "DEATHKNIGHT",
      spells = {{49020, 80000}, {49143, 60000}, {49184, 40000}, {6603, 30000}} },
    { name = "Mage2",         value = 170000, class = "MAGE",
      spells = {{11366, 65000}, {133, 50000}, {108853, 35000}, {12654, 20000}} },
    { name = "Hunter2",       value = 135000, class = "HUNTER",
      spells = {{19434, 55000}, {257044, 40000}, {185358, 25000}, {75, 15000}} },
    { name = "Warrior2",      value = 105000, class = "WARRIOR",
      spells = {{12294, 45000}, {163201, 30000}, {7384, 20000}, {6603, 10000}} },
    { name = "Rogue2",        value = 80000,  class = "ROGUE",
      spells = {{196819, 35000}, {1752, 25000}, {6603, 20000}} },
    { name = "Shaman2",       value = 58000,  class = "SHAMAN",
      spells = {{188196, 25000}, {51505, 18000}, {188389, 15000}} },
    { name = "Paladin2",      value = 40000,  class = "PALADIN",
      spells = {{85256, 18000}, {184575, 12000}, {6603, 10000}} },
}

local function IsSecret(val)
    return val ~= nil and issecretvalue and issecretvalue(val)
end


local floor = math.floor

local function RoundIfPlain(val)
    if val and not IsSecret(val) then
        return floor(val + 0.5)
    end
    return val
end

local function FormatValueText(fontString, val)
    if not val then
        fontString:SetText("0")
        return
    end
    fontString:SetText(AbbreviateNumbers(RoundIfPlain(val)))
end

local function FormatCombinedText(fontString, total, perSec)
    if not total and not perSec then
        fontString:SetText("0")
        return
    end
    local ok = pcall(function()
        local p = perSec and AbbreviateNumbers(RoundIfPlain(perSec)) or "0"
        local t = total and AbbreviateNumbers(RoundIfPlain(total)) or "0"
        fontString:SetText(p .. " (" .. t .. ")")
    end)
    if not ok then
        if total then
            fontString:SetText(AbbreviateNumbers(RoundIfPlain(total)))
        else
            fontString:SetText("0")
        end
    end
end

local function FontFlags(outline)
    return (outline and outline ~= "NONE") and outline or ""
end

local winDBCache = {}
local function GetWinDB(winIndex)
    local mainDB = TUI.db.profile.damageMeter
    if winIndex == 1 then return mainDB end
    local proxy = winDBCache[winIndex]
    if not proxy then
        proxy = setmetatable({}, { __index = function(_, k)
            local ew = TUI.db.profile.damageMeter.extraWindows[winIndex]
            if ew then
                local v = ew[k]
                if v ~= nil then return v end
            end
            return TUI.db.profile.damageMeter[k]
        end })
        winDBCache[winIndex] = proxy
    end
    return proxy
end

local function GetBarFGColor(db, classFilename)
    if db.barClassColor then
        local r, g, b = TUI:GetClassColor(classFilename)
        if r then return r, g, b end
    end
    local c = db.barColor
    return c.r, c.g, c.b
end

local function GetBarBGColor(db, classFilename)
    if db.barBGClassColor then
        local r, g, b = TUI:GetClassColor(classFilename)
        if r then return r, g, b, db.barBGColor.a end
    end
    local c = db.barBGColor
    return c.r, c.g, c.b, c.a
end

local function GetTextColor(db, classFilename)
    if db.textClassColor then
        local r, g, b = TUI:GetClassColor(classFilename)
        if r then return r, g, b end
    end
    local c = db.textColor
    return c.r, c.g, c.b
end

local function GetValueColor(db, classFilename)
    if db.valueClassColor then
        local r, g, b = TUI:GetClassColor(classFilename)
        if r then return r, g, b end
    end
    local c = db.valueColor
    return c.r, c.g, c.b
end

local function GetRankColor(db, classFilename)
    if db.rankClassColor then
        local r, g, b = TUI:GetClassColor(classFilename)
        if r then return r, g, b end
    end
    local c = db.rankColor
    return c.r, c.g, c.b
end

local function NewWindowState(index, savedModeIndex)
    return {
        index         = index,
        frame         = nil,
        header        = nil,
        window        = nil,
        bars          = {},
        modeIndex     = savedModeIndex or 1,
        sessionType   = Enum.DamageMeterSessionType.Current,
        sessionId     = nil,
        embedded      = false,
        scrollOffset  = 0,
        positionCache = {},
        drillSource   = nil,
    }
end

local function CreateBar(parent)
    local bar = {}

    bar.frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")

    bar.background = bar.frame:CreateTexture(nil, "BACKGROUND")
    bar.background:SetAllPoints()
    bar.background:SetTexture(E.media.normTex)
    bar.background:SetVertexColor(0.15, 0.15, 0.15, 0.35)

    bar.statusbar = CreateFrame("StatusBar", nil, bar.frame)
    bar.statusbar:SetAllPoints()
    bar.statusbar:SetStatusBarTexture(E.media.normTex)
    bar.statusbar:SetMinMaxValues(0, 1)
    bar.statusbar:SetValue(0)
    bar.statusbar.smoothing = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut or nil

    bar.classIcon = bar.statusbar:CreateTexture(nil, "OVERLAY")
    bar.classIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
    bar.classIcon:SetSize(16, 16)
    bar.classIcon:SetPoint("LEFT", 2, 0)
    bar.classIcon:Hide()

    bar.pctText = bar.statusbar:CreateFontString(nil, "OVERLAY")
    bar.pctText:SetPoint("RIGHT", -4, 0)
    bar.pctText:SetJustifyH("RIGHT")
    bar.pctText:SetWordWrap(false)
    bar.pctText:SetShadowOffset(1, -1)
    bar.pctText:Hide()

    bar.rightText = bar.statusbar:CreateFontString(nil, "OVERLAY")
    bar.rightText:SetPoint("RIGHT", -4, 0)
    bar.rightText:SetJustifyH("RIGHT")
    bar.rightText:SetWordWrap(false)
    bar.rightText:SetShadowOffset(1, -1)

    bar.leftText = bar.statusbar:CreateFontString(nil, "OVERLAY")
    bar.leftText:SetPoint("LEFT", 4, 0)
    bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
    bar.leftText:SetJustifyH("LEFT")
    bar.leftText:SetWordWrap(false)
    bar.leftText:SetShadowOffset(1, -1)

    bar.borderFrame = CreateFrame("Frame", nil, bar.frame, "BackdropTemplate")
    bar.borderFrame:SetAllPoints()
    bar.borderFrame:SetFrameLevel(bar.statusbar:GetFrameLevel() + 2)

    bar.textFrame = CreateFrame("Frame", nil, bar.frame)
    bar.textFrame:SetAllPoints()
    bar.textFrame:SetFrameLevel(bar.borderFrame:GetFrameLevel() + 1)

    bar.leftText:SetParent(bar.textFrame)
    bar.rightText:SetParent(bar.textFrame)
    bar.pctText:SetParent(bar.textFrame)

    bar.frame:EnableMouse(true)
    bar.frame:Hide()
    return bar
end

local function ApplyBarIconLayout(bar, db)
    local iconSize = max(8, (db.barHeight or 18) - 2)
    bar.classIcon:SetSize(iconSize, iconSize)
    bar.leftText:ClearAllPoints()
    if db.showClassIcon then
        bar.leftText:SetPoint("LEFT", bar.classIcon, "RIGHT", 2, 0)
    else
        bar.leftText:SetPoint("LEFT", 4, 0)
    end
    bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
end

local function ApplyBarBorder(bar, db)
    if db.barBorderEnabled then
        bar.borderFrame:SetTemplate()
        bar.borderFrame:SetBackdropColor(0, 0, 0, 0)
    else
        bar.borderFrame:SetBackdrop(nil)
    end
end

local function ComputeNumVisible(win)
    local db    = GetWinDB(win.index)
    local barHt = max(1, db.barHeight or 18)
    local availH

    if win.embedded then
        local panel    = _G.RightChatPanel
        local tabPanel = _G.RightChatTab
        if not panel or not tabPanel then return 1 end
        local tabH = tabPanel:GetHeight()
        availH = panel:GetHeight() - (tabH + PANEL_INSET * 2) - PANEL_INSET
    else
        if not win.window then return 1 end
        availH = win.window:GetHeight() - HEADER_HEIGHT
    end

    if not availH or availH < 1 then return 1 end
    local spacing = max(0, db.barSpacing or 1)
    return max(1, floor(availH / (barHt + spacing)))
end

local function ResizeToPanel(win)
    if not win or not win.frame or not win.embedded then return end

    local panel    = _G.RightChatPanel
    local tabPanel = _G.RightChatTab
    if not panel or not tabPanel then return end

    local tabH      = tabPanel:GetHeight()
    local topOffset = tabH + PANEL_INSET * 2

    win.frame:ClearAllPoints()
    win.frame:SetPoint("TOPLEFT",     panel, "TOPLEFT",     PANEL_INSET,  -topOffset)
    win.frame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -PANEL_INSET,  PANEL_INSET)

    local db    = GetWinDB(win.index)
    local barHt = max(1, db.barHeight or 18)
    for i = 1, MAX_BARS do
        if win.bars[i] then win.bars[i].frame:SetHeight(barHt) end
    end
end

local function ResizeStandalone(win)
    if not win or not win.window or not win.frame then return end

    local db = GetWinDB(win.index)
    local w, h = db.standaloneWidth, db.standaloneHeight
    win.window:SetSize(w, h)

    if win.window.mover then
        win.window.mover:SetSize(w, h)
    end

    local barHt = max(1, db.barHeight or 18)
    for i = 1, MAX_BARS do
        if win.bars[i] then win.bars[i].frame:SetHeight(barHt) end
    end
end

local RefreshWindow
local GetSession, GetSessionSource

local function EnterDrillDown(win, guid, name, classFilename)
    win.drillSource = { guid = guid, name = name, class = classFilename }
    win.scrollOffset = 0
    RefreshWindow(win)
end

local function ExitDrillDown(win)
    if not win.drillSource then return end
    win.drillSource = nil
    win.scrollOffset = 0
    RefreshWindow(win)
end

local function GetDrillSpellCount(win)
    local ds = win.drillSource
    if not ds then return 0 end

    if testMode then
        for _, td in ipairs(TEST_DATA) do
            if td.name == ds.name then return td.spells and #td.spells or 0 end
        end
        return 0
    end

    local meterType  = ResolveMeterType(MODE_ORDER[win.modeIndex])
    local sourceData = ds.guid and GetSessionSource(win, meterType, ds.guid)
    return (sourceData and sourceData.combatSpells) and #sourceData.combatSpells or 0
end

local function SetupBarInteraction(bar, win)
    bar.frame:SetScript("OnEnter", function(self)
        if win.drillSource then
            if self.drillSpellID then
                GameTooltip_SetDefaultAnchor(GameTooltip, self)
                GameTooltip:SetSpellByID(self.drillSpellID)
                GameTooltip:Show()
            end
            return
        end

        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        if self.sourceName then
            local cr, cg, cb = 1, 1, 1
            local guid = self.sourceGUID
            local cls = guid and classCache[guid]
            if not cls and self.testIndex then
                local td = TEST_DATA[self.testIndex]
                if td then cls = td.class end
            end
            if cls then
                local r, g, b = TUI:GetClassColor(cls)
                if r then cr, cg, cb = r, g, b end
            end
            GameTooltip:AddLine(self.sourceName, cr, cg, cb)
        end
        GameTooltip:AddLine("Click for spell breakdown", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    bar.frame:SetScript("OnLeave", GameTooltip_Hide)

    bar.frame:SetScript("OnMouseUp", function(self, button)
        if win.drillSource then
            if button == "RightButton" then
                ExitDrillDown(win)
            end
            return
        end

        if button == "LeftButton" then
            GameTooltip:Hide()
            if testMode and self.testIndex then
                local td = TEST_DATA[self.testIndex]
                if td then
                    EnterDrillDown(win, nil, td.name, td.class)
                end
                return
            end
            if self.sourceGUID and self.sourceName then
                local class = classCache[self.sourceGUID]
                EnterDrillDown(win, self.sourceGUID, self.sourceName, class)
            end
        end
    end)
end

local function SetupScrollWheel(win)
    win.frame:EnableMouseWheel(true)
    win.frame:SetScript("OnMouseWheel", function(_, delta)
        local total
        if win.drillSource then
            total = GetDrillSpellCount(win)
        elseif testMode then
            total = #TEST_DATA
        else
            local meterType = ResolveMeterType(MODE_ORDER[win.modeIndex])
            local session   = GetSession(win, meterType)
            total = (session and session.combatSources and #session.combatSources) or 0
        end
        local numVis = ComputeNumVisible(win)
        local maxOff = max(0, total - numVis)
        win.scrollOffset = max(0, min(maxOff, win.scrollOffset - delta))
        RefreshWindow(win)
    end)
end

local function ApplyHeaderStyle(win, db)
    local header = win.header
    if not header then return end

    local fontPath = LSM:Fetch("font", db.headerFont)
    local flags    = FontFlags(db.headerFontOutline)

    local hc = db.headerBGColor
    header.bg:SetVertexColor(hc.r, hc.g, hc.b, hc.a)

    local tc = db.headerFontColor
    header.modeText:FontTemplate(fontPath, db.headerFontSize + 1, flags)
    header.modeText:SetTextColor(tc.r, tc.g, tc.b)

    header.sessText:FontTemplate(fontPath, db.headerFontSize + 1, flags)
    header.sessText:SetTextColor(tc.r, tc.g, tc.b)

    header.timer:FontTemplate(fontPath, db.headerFontSize, flags)
    header.timer:SetTextColor(tc.r, tc.g, tc.b, 0.7)
    header.timer:ClearAllPoints()
    if db.showTimer then
        header.timer:SetPoint("RIGHT", header.reset, "LEFT", -4, 0)
        header.timer:Show()
    else
        header.timer:Hide()
    end
end

local function MakeModeEntry(win, mtype)
    local idx
    for i, mt in ipairs(MODE_ORDER) do
        if mt == mtype then idx = i; break end
    end
    if not idx then return nil end

    local label = MODE_LABELS[mtype] or "?"
    return {
        text         = (idx == win.modeIndex) and ("|cffffd100" .. label .. "|r") or label,
        notCheckable = true,
        func         = function()
            win.modeIndex  = idx
            win.drillSource = nil
            win.scrollOffset = 0
            local db = TUI.db.profile.damageMeter
            if win.index == 1 then
                db.modeIndex = idx
            else
                db.extraWindows[win.index] = db.extraWindows[win.index] or {}
                db.extraWindows[win.index].modeIndex = idx
            end
            RefreshWindow(win)
        end,
    }
end

local function BuildModeMenu(win)
    local dmg = {
        MakeModeEntry(win, Enum.DamageMeterType.DamageDone),
        MakeModeEntry(win, Enum.DamageMeterType.Dps),
        MakeModeEntry(win, COMBINED_DAMAGE),
        MakeModeEntry(win, Enum.DamageMeterType.DamageTaken),
        MakeModeEntry(win, Enum.DamageMeterType.AvoidableDamageTaken),
    }
    if Enum.DamageMeterType.EnemyDamageTaken then
        dmg[#dmg + 1] = MakeModeEntry(win, Enum.DamageMeterType.EnemyDamageTaken)
    end

    local heal = {
        MakeModeEntry(win, Enum.DamageMeterType.HealingDone),
        MakeModeEntry(win, Enum.DamageMeterType.Hps),
        MakeModeEntry(win, COMBINED_HEALING),
        MakeModeEntry(win, Enum.DamageMeterType.Absorbs),
    }

    local actions = {
        MakeModeEntry(win, Enum.DamageMeterType.Interrupts),
        MakeModeEntry(win, Enum.DamageMeterType.Dispels),
    }
    if Enum.DamageMeterType.Deaths then
        actions[#actions + 1] = MakeModeEntry(win, Enum.DamageMeterType.Deaths)
    end

    return {
        { text = "Damage",  notCheckable = true, hasArrow = true, menuList = dmg },
        { text = "Healing", notCheckable = true, hasArrow = true, menuList = heal },
        { text = "Actions", notCheckable = true, hasArrow = true, menuList = actions },
    }
end

local function BuildSessionMenu(win)
    local menu = {}

    -- Encounter sessions first (oldest at top, newest at bottom)
    if C_DamageMeter.GetAvailableCombatSessions then
        local ok, sessions = pcall(C_DamageMeter.GetAvailableCombatSessions)
        if ok and sessions and #sessions > 0 then
            for _, sess in ipairs(sessions) do
                local sid = sess.sessionId or sess.combatSessionId or sess.id or sess.sessionID
                local label = sess.name or "Encounter"
                local dur = sess.durationSeconds or sess.duration
                if dur and not IsSecret(dur) then
                    local timeOk, timeStr = pcall(function()
                        return format("[%d:%02d]", floor(dur / 60), floor(dur % 60))
                    end)
                    if timeOk then label = label .. " " .. timeStr end
                end
                menu[#menu + 1] = {
                    text = (win.sessionId == sid) and ("|cffffd100" .. label .. "|r") or label,
                    notCheckable = true,
                    func = function()
                        win.sessionId    = sid
                        win.sessionType  = nil
                        win.scrollOffset = 0
                        win.drillSource  = nil
                        RefreshWindow(win)
                    end,
                }
            end
            menu[#menu + 1] = { text = "", notCheckable = true, disabled = true }
        end
    end

    -- Current / Overall at the bottom
    menu[#menu + 1] = {
        text = (win.sessionId == nil and win.sessionType == Enum.DamageMeterSessionType.Current)
            and "|cffffd100Current Segment|r" or "Current Segment",
        notCheckable = true,
        func = function()
            win.sessionId    = nil
            win.sessionType  = Enum.DamageMeterSessionType.Current
            win.scrollOffset = 0
            win.drillSource  = nil
            RefreshWindow(win)
        end,
    }

    menu[#menu + 1] = {
        text = (win.sessionId == nil and win.sessionType == Enum.DamageMeterSessionType.Overall)
            and "|cffffd100Overall|r" or "Overall",
        notCheckable = true,
        func = function()
            win.sessionId    = nil
            win.sessionType  = Enum.DamageMeterSessionType.Overall
            win.scrollOffset = 0
            win.drillSource  = nil
            RefreshWindow(win)
        end,
    }

    return menu
end

local function ToggleSession(win)
    win.sessionId = nil
    if win.sessionType == Enum.DamageMeterSessionType.Current then
        win.sessionType = Enum.DamageMeterSessionType.Overall
    else
        win.sessionType = Enum.DamageMeterSessionType.Current
    end
    win.scrollOffset = 0
    win.drillSource  = nil
    RefreshWindow(win)
end

local function SetupHeaderContent(win, db)
    local header = win.header

    header.bg = header:CreateTexture(nil, "BACKGROUND")
    header.bg:SetAllPoints()
    header.bg:SetTexture(E.media.normTex)

    header.modeText = header:CreateFontString(nil, "OVERLAY")
    header.modeText:SetPoint("LEFT", 4, 0)
    header.modeText:SetShadowOffset(1, -1)

    header.sessText = header:CreateFontString(nil, "OVERLAY")
    header.sessText:SetPoint("LEFT", header.modeText, "RIGHT", 0, 0)
    header.sessText:SetShadowOffset(1, -1)

    header.reset = CreateFrame("Button", nil, header)
    header.reset:SetSize(16, 16)
    header.reset:SetPoint("RIGHT", -4, 0)
    S:HandleCloseButton(header.reset)
    header.reset:SetHitRectInsets(0, 0, 0, 0)
    header.reset:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" then
            StaticPopup_Show("TRENCHYUI_METER_RESET")
        end
    end)
    header.reset:HookScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:AddLine("Reset Meter", 1, 0.3, 0.3)
        GameTooltip:AddLine("Clears all session data.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    header.reset:HookScript("OnLeave", GameTooltip_Hide)

    header.timer = header:CreateFontString(nil, "OVERLAY")
    header.timer:SetShadowOffset(1, -1)

    ApplyHeaderStyle(win, db)

    -- Mode click area (left portion)
    header.modeArea = CreateFrame("Frame", nil, header)
    header.modeArea:SetPoint("TOPLEFT",     header.modeText, "TOPLEFT",     0, 0)
    header.modeArea:SetPoint("BOTTOMRIGHT", header.modeText, "BOTTOMRIGHT", 0, 0)
    header.modeArea:EnableMouse(true)
    header.modeArea:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            if win.drillSource then
                ExitDrillDown(win)
            else
                E:ComplicatedMenu(BuildModeMenu(win), E.EasyMenu, nil, nil, nil, "MENU")
                local mgr = Menu and Menu.GetManager and Menu.GetManager()
                local openMenu = mgr and mgr:GetOpenMenu()
                if openMenu then
                    openMenu:ClearAllPoints()
                    openMenu:SetPoint("BOTTOMLEFT", header, "TOPLEFT", -1, -3)
                end
            end
        elseif button == "RightButton" then
            ToggleSession(win)
        end
    end)
    header.modeArea:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        if win.drillSource then
            GameTooltip:AddLine("|cffffd100Left-click:|r return to overview", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("|cffffd100Left-click:|r choose display mode", 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine("|cffffd100Right-click:|r toggle Current / Overall", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    header.modeArea:SetScript("OnLeave", GameTooltip_Hide)

    -- Session click area (right portion)
    header.sessArea = CreateFrame("Frame", nil, header)
    header.sessArea:SetPoint("TOPLEFT",     header.sessText, "TOPLEFT",     0, 0)
    header.sessArea:SetPoint("BOTTOMRIGHT", header.sessText, "BOTTOMRIGHT", 0, 0)
    header.sessArea:EnableMouse(true)
    header.sessArea:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            E:ComplicatedMenu(BuildSessionMenu(win), E.EasyMenu, nil, nil, nil, "MENU")
            local mgr = Menu and Menu.GetManager and Menu.GetManager()
            local openMenu = mgr and mgr:GetOpenMenu()
            if openMenu then
                openMenu:ClearAllPoints()
                openMenu:SetPoint("BOTTOMLEFT", header, "TOPLEFT", -1, -3)
            end
        elseif button == "RightButton" then
            ToggleSession(win)
        end
    end)
    header.sessArea:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:AddLine("|cffffd100Left-click:|r choose encounter", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cffffd100Right-click:|r toggle Current / Overall", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    header.sessArea:SetScript("OnLeave", GameTooltip_Hide)
end

local function CreateEmbeddedWindow(win, db)
    local panel    = _G.RightChatPanel
    local tabPanel = _G.RightChatTab
    if not panel or not tabPanel then return end

    local fontPath = LSM:Fetch("font", db.barFont)
    local flags    = FontFlags(db.barFontOutline)

    win.header = CreateFrame("Frame", "TrenchyUIMeterHeader", tabPanel)
    win.header:SetAllPoints(tabPanel)
    win.header:SetFrameLevel(tabPanel:GetFrameLevel() + 1)
    win.header:EnableMouse(true)

    SetupHeaderContent(win, db)

    win.frame = CreateFrame("Frame", "TrenchyUIMeter", panel)
    win.frame:SetFrameStrata("MEDIUM")
    win.frame:SetClipsChildren(true)

    for i = 1, MAX_BARS do
        local bar = CreateBar(win.frame)
        bar.leftText:FontTemplate(fontPath, db.barFontSize, flags)
        bar.rightText:FontTemplate(fontPath, db.barFontSize, flags)
        bar.pctText:FontTemplate(fontPath, db.barFontSize, flags)
        ApplyBarIconLayout(bar, db)
        ApplyBarBorder(bar, db)

        local sp = max(0, db.barSpacing or 1)
        if i == 1 then
            bar.frame:SetPoint("TOPLEFT",  win.frame, "TOPLEFT",  0, -sp)
            bar.frame:SetPoint("TOPRIGHT", win.frame, "TOPRIGHT", 0, -sp)
        else
            bar.frame:SetPoint("TOPLEFT",  win.bars[i-1].frame, "BOTTOMLEFT",  0, -sp)
            bar.frame:SetPoint("TOPRIGHT", win.bars[i-1].frame, "BOTTOMRIGHT", 0, -sp)
        end
        win.bars[i] = bar
        SetupBarInteraction(bar, win)
    end

    win.embedded = true
    ResizeToPanel(win)
    SetupScrollWheel(win)
end

local function CreateStandaloneWindow(win, db, savedW, savedH)
    local i       = win.index
    local winName = i == 1 and "TrenchyUIMeter" or ("TrenchyUIMeter" .. i)
    local hdrName = i == 1 and "TrenchyUIMeterHeader" or ("TrenchyUIMeterHeader" .. i)

    local w = (savedW and savedW > 0) and savedW or db.standaloneWidth
    local h = (savedH and savedH > 0) and savedH or db.standaloneHeight

    local window = CreateFrame("Frame", winName, UIParent, "BackdropTemplate")
    window:SetSize(w, h)
    if i == 1 then
        window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    elseif i == 2 then
        window:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -2, 189)
    elseif i == 3 then
        window:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -416, 2)
    elseif i == 4 then
        window:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -416, 189)
    end
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:SetFrameStrata('BACKGROUND')
    window:SetFrameLevel(300)
    win.window = window

    if db.showBackdrop then
        window:SetTemplate('Transparent')
    end

    local headerBorder = CreateFrame("Frame", nil, window, "BackdropTemplate")
    headerBorder:SetPoint("TOPLEFT",  window, "TOPLEFT",  0, 0)
    headerBorder:SetPoint("TOPRIGHT", window, "TOPRIGHT", 0, 0)
    headerBorder:SetHeight(HEADER_HEIGHT)
    headerBorder:SetFrameLevel(window:GetFrameLevel() + 1)
    win.headerBorder = headerBorder
    if db.showHeaderBorder then
        headerBorder:SetTemplate()
    end

    win.header = CreateFrame("Frame", hdrName, window)
    win.header:SetPoint("TOPLEFT",  window, "TOPLEFT",  0, 0)
    win.header:SetPoint("TOPRIGHT", window, "TOPRIGHT", 0, 0)
    win.header:SetHeight(HEADER_HEIGHT)
    win.header:SetFrameLevel(headerBorder:GetFrameLevel() + 1)
    win.header:EnableMouse(true)

    SetupHeaderContent(win, db)

    win.frame = CreateFrame("Frame", nil, window)
    win.frame:SetPoint("TOPLEFT",     window, "TOPLEFT",     0, -HEADER_HEIGHT)
    win.frame:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", 0,  0)
    win.frame:SetFrameStrata("MEDIUM")
    win.frame:SetClipsChildren(true)

    local fontPath = LSM:Fetch("font", db.barFont)
    local flags    = FontFlags(db.barFontOutline)

    for j = 1, MAX_BARS do
        local bar = CreateBar(win.frame)
        bar.leftText:FontTemplate(fontPath, db.barFontSize, flags)
        bar.rightText:FontTemplate(fontPath, db.barFontSize, flags)
        bar.pctText:FontTemplate(fontPath, db.barFontSize, flags)
        ApplyBarIconLayout(bar, db)
        ApplyBarBorder(bar, db)

        local sp = max(0, db.barSpacing or 1)
        if j == 1 then
            bar.frame:SetPoint("TOPLEFT",  win.frame, "TOPLEFT",  0, -sp)
            bar.frame:SetPoint("TOPRIGHT", win.frame, "TOPRIGHT", 0, -sp)
        else
            bar.frame:SetPoint("TOPLEFT",  win.bars[j-1].frame, "BOTTOMLEFT",  0, -sp)
            bar.frame:SetPoint("TOPRIGHT", win.bars[j-1].frame, "BOTTOMRIGHT", 0, -sp)
        end
        win.bars[j] = bar
        SetupBarInteraction(bar, win)
    end

    local moverLabel = i == 1 and "TDM" or ("TDM " .. i)
    E:CreateMover(window, winName, moverLabel, nil, nil, nil, 'ALL,TRENCHYUI', nil, 'TrenchyUI,damageMeter')

    local holder = E:GetMoverHolder(winName)
    if holder and holder.mover then
        holder.mover:HookScript('OnMouseDown', function(_, button)
            if button == 'RightButton' and not IsControlKeyDown() and not IsShiftKeyDown() then
                TUI._selectedMeterWindow = i
            end
        end)
    end

    win.embedded = false
    ResizeStandalone(win)
    SetupScrollWheel(win)
end

local function CreateMeterFrame(win, isEmbedded)
    local db = GetWinDB(win.index)

    if isEmbedded then
        CreateEmbeddedWindow(win, db)
    else
        CreateStandaloneWindow(win, db, db.standaloneWidth, db.standaloneHeight)
    end
end

local function GetSessionLabel(win)
    if win.sessionId then
        if C_DamageMeter.GetAvailableCombatSessions then
            local ok, sessions = pcall(C_DamageMeter.GetAvailableCombatSessions)
            if ok and sessions then
                for i, sess in ipairs(sessions) do
                    local sid = sess.sessionId or sess.combatSessionId or sess.id or sess.sessionID
                    if sid == win.sessionId then
                        local label = sess.name or "Encounter"
                        if label == "Encounter" then
                            label = "Encounter " .. i
                        end
                        return label
                    end
                end
            end
        end
        return "Encounter"
    end
    return SESSION_LABELS[win.sessionType] or "?"
end

GetSession = function(win, meterType)
    if win.sessionId and C_DamageMeter.GetCombatSessionFromID then
        return C_DamageMeter.GetCombatSessionFromID(win.sessionId, meterType)
    end
    return C_DamageMeter.GetCombatSessionFromType(win.sessionType, meterType)
end

GetSessionSource = function(win, meterType, guid)
    if win.sessionId and C_DamageMeter.GetCombatSessionSourceFromID then
        return C_DamageMeter.GetCombatSessionSourceFromID(win.sessionId, meterType, guid)
    end
    return C_DamageMeter.GetCombatSessionSourceFromType(win.sessionType, meterType, guid)
end

RefreshWindow = function(win)
    if not win or not win.frame or not win.header then return end

    local db = GetWinDB(win.index)

    if win.drillSource then
        local ds = win.drillSource
        local modeEntry = MODE_ORDER[win.modeIndex]
        local modeLabel = MODE_SHORT[modeEntry] or MODE_LABELS[modeEntry] or "?"
        local sessLabel = GetSessionLabel(win)

        local cr, cg, cb = TUI:GetClassColor(ds.class)
        local nameHex = cr and format("%02x%02x%02x", cr * 255, cg * 255, cb * 255) or "ffffff"
        win.header.modeText:SetText(format("|cff%s%s|r \226\128\148 %s", nameHex, ds.name, modeLabel))
        win.header.sessText:SetText(" (" .. sessLabel .. ")")
        if win.sessionId then
            win.header.sessText:SetTextColor(1, 0.3, 0.3)
        else
            local tc = GetWinDB(win.index).headerFontColor
            win.header.sessText:SetTextColor(tc.r, tc.g, tc.b)
        end
        win.header.timer:Hide()

        local spells
        if testMode then
            for _, td in ipairs(TEST_DATA) do
                if td.name == ds.name then spells = td.spells; break end
            end
        else
            local meterType  = ResolveMeterType(modeEntry)
            local sourceData = ds.guid and GetSessionSource(win, meterType, ds.guid)
            spells = sourceData and sourceData.combatSpells
        end

        if not spells or #spells == 0 then
            for i = 1, MAX_BARS do
                if win.bars[i] then win.bars[i].frame:Hide() end
            end
            return
        end

        local numVisible = ComputeNumVisible(win)
        local total = #spells
        win.scrollOffset = max(0, min(win.scrollOffset, max(0, total - numVisible)))

        local topVal, totalAmt = 0, 0
        for si = 1, total do
            local s = spells[si]
            local amt = s.totalAmount or s[2] or 0
            if not IsSecret(amt) then
                if amt > topVal then topVal = amt end
                totalAmt = totalAmt + amt
            end
        end
        if topVal == 0 then topVal = 1 end
        if totalAmt == 0 then totalAmt = 1 end

        local fgR, fgG, fgB = GetBarFGColor(db, ds.class)
        local bgR, bgG, bgB, bgA = GetBarBGColor(db, ds.class)
        local tR, tG, tB = GetTextColor(db, ds.class)
        local vR, vG, vB = GetValueColor(db, ds.class)

        for i = 1, MAX_BARS do
            local bar = win.bars[i]
            if not bar then break end
            local spIdx = win.scrollOffset + i
            local s = spells[spIdx]

            if i > numVisible or not s then
                bar.frame:Hide()
                bar.frame.drillSpellID = nil
            else
                bar.frame:Show()
                local rawSpellID = s.spellID or (type(s[1]) == "number" and s[1]) or nil
                local spellID   = (rawSpellID and not issecretvalue(rawSpellID)) and rawSpellID or nil
                local spellName = (type(s[1]) == "string" and s[1]) or nil
                local amt       = s.totalAmount or s[2] or 0

                local iconID
                if spellID then
                    local cached = spellCache[spellID]
                    if cached then
                        spellName = cached.name or spellName
                        iconID = cached.icon
                    else
                        local ok, name = pcall(C_Spell.GetSpellName, spellID)
                        if ok and name then spellName = name end
                        local ok2, info = pcall(C_Spell.GetSpellInfo, spellID)
                        if ok2 and info then iconID = info.iconID end
                        spellCache[spellID] = { name = spellName, icon = iconID }
                    end
                end
                if not spellName then spellName = "?" end

                bar.frame.drillSpellID = spellID
                bar.frame.sourceGUID   = nil
                bar.frame.testIndex    = nil

                if iconID then
                    bar.classIcon:SetTexture(iconID)
                    bar.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    bar.classIcon:Show()
                else
                    bar.classIcon:Hide()
                end

                if not bar._isDrill then
                    bar._isDrill = true
                    bar.rightText:ClearAllPoints()
                    bar.rightText:SetPoint("RIGHT", -64, 0)
                    bar.pctText:Show()
                    bar.leftText:ClearAllPoints()
                    if iconID then
                        bar.leftText:SetPoint("LEFT", bar.classIcon, "RIGHT", 2, 0)
                    else
                        bar.leftText:SetPoint("LEFT", 4, 0)
                    end
                    bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
                elseif iconID then
                    if bar._drillHasIcon ~= spellID then
                        bar.leftText:ClearAllPoints()
                        bar.leftText:SetPoint("LEFT", bar.classIcon, "RIGHT", 2, 0)
                        bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
                    end
                else
                    if bar._drillHasIcon then
                        bar.leftText:ClearAllPoints()
                        bar.leftText:SetPoint("LEFT", 4, 0)
                        bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
                    end
                end
                bar._drillHasIcon = iconID and spellID or nil

                bar.statusbar:SetStatusBarColor(fgR, fgG, fgB)
                bar.statusbar:SetMinMaxValues(0, topVal)
                local ok3, _ = pcall(function() bar.statusbar:SetValue(amt) end)
                if not ok3 then bar.statusbar:SetValue(0) end
                bar.background:SetVertexColor(bgR, bgG, bgB, bgA)

                bar.leftText:SetText(spellName)
                bar.leftText:SetTextColor(tR, tG, tB)

                local ok5 = pcall(function()
                    bar.rightText:SetText(AbbreviateNumbers(RoundIfPlain(amt)))
                end)
                if not ok5 then bar.rightText:SetText("?") end
                bar.rightText:SetTextColor(vR, vG, vB)

                local ok4, pctStr = pcall(function()
                    return format("%.1f%%", (amt / totalAmt) * 100)
                end)
                bar.pctText:SetText(ok4 and pctStr or "")
                bar.pctText:SetTextColor(vR * 0.7, vG * 0.7, vB * 0.7)
            end
        end
        return
    end

    if testMode then
        win.header.modeText:SetText("|cffff6600[Test Mode]|r")
        win.header.sessText:SetText("")
        win.header.timer:Hide()
        local numVisible = ComputeNumVisible(win)
        local maxVal     = TEST_DATA[1].value
        local total      = #TEST_DATA
        win.scrollOffset = max(0, min(win.scrollOffset, max(0, total - numVisible)))
        for i = 1, MAX_BARS do
            local bar = win.bars[i]
            if not bar then break end
            local srcIdx = win.scrollOffset + i
            local td     = TEST_DATA[srcIdx]
            if i > numVisible or not td then
                bar.frame:Hide()
            else
                bar.frame:Show()
                local fgR, fgG, fgB = GetBarFGColor(db, td.class)
                bar.statusbar:SetStatusBarColor(fgR, fgG, fgB)
                bar.statusbar:SetMinMaxValues(0, maxVal)
                bar.statusbar:SetValue(td.value)
                local bgR, bgG, bgB, bgA = GetBarBGColor(db, td.class)
                bar.background:SetVertexColor(bgR, bgG, bgB, bgA)
                local tR, tG, tB = GetTextColor(db, td.class)
                if db.showRank then
                    local rr, rg, rb = GetRankColor(db, td.class)
                    bar.leftText:SetText(format("|cff%02x%02x%02x%d.|r %s",
                        rr * 255, rg * 255, rb * 255, srcIdx, td.name))
                else
                    bar.leftText:SetText(td.name)
                end
                bar.leftText:SetTextColor(tR, tG, tB)
                FormatValueText(bar.rightText, td.value)
                local vR, vG, vB = GetValueColor(db, td.class)
                bar.rightText:SetTextColor(vR, vG, vB)
                if bar._isDrill then
                    bar._isDrill = nil
                    bar._drillHasIcon = nil
                    bar.pctText:Hide()
                    bar.rightText:ClearAllPoints()
                    bar.rightText:SetPoint("RIGHT", -4, 0)
                    bar.classIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
                    ApplyBarIconLayout(bar, db)
                end
                if db.showClassIcon then
                    local coords = CLASS_ICON_COORDS[td.class]
                    if coords then
                        bar.classIcon:SetTexCoord(unpack(coords))
                        bar.classIcon:Show()
                    else
                        bar.classIcon:Hide()
                    end
                else
                    bar.classIcon:Hide()
                end
                bar.frame.sourceGUID   = nil
                bar.frame.sourceName   = td.name
                bar.frame.testIndex    = srcIdx
                bar.frame.drillSpellID = nil
            end
        end
        return
    end

    local modeEntry = MODE_ORDER[win.modeIndex]
    local meterType = ResolveMeterType(modeEntry)
    local modeLabel = MODE_SHORT[modeEntry] or MODE_LABELS[modeEntry] or "?"
    local sessLabel = GetSessionLabel(win)

    win.header.modeText:SetText(modeLabel)
    win.header.sessText:SetText(" \226\128\148 " .. sessLabel)
    if win.sessionId then
        win.header.sessText:SetTextColor(1, 0.3, 0.3)
    else
        local tc = GetWinDB(win.index).headerFontColor
        win.header.sessText:SetTextColor(tc.r, tc.g, tc.b)
    end

    if win.sessionType then
        local dur = C_DamageMeter.GetSessionDurationSeconds(win.sessionType)
        if dur then
            local ok = pcall(function()
                win.header.timer:SetText(format("%d:%02d", floor(dur / 60), floor(dur % 60)))
            end)
            if not ok then win.header.timer:SetText("--:--") end
        else
            win.header.timer:SetText("")
        end
    else
        win.header.timer:SetText("")
    end

    local session    = GetSession(win, meterType)
    local sources    = session and session.combatSources
    local usePerSec  = (modeEntry == Enum.DamageMeterType.Dps or modeEntry == Enum.DamageMeterType.Hps)
    local useCombined = (modeEntry == COMBINED_DAMAGE or modeEntry == COMBINED_HEALING)
    local numVisible = ComputeNumVisible(win)
    local total      = sources and #sources or 0
    win.scrollOffset = max(0, min(win.scrollOffset, max(0, total - numVisible)))

    for i = 1, MAX_BARS do
        local bar = win.bars[i]
        if not bar then break end

        if i > numVisible then
            bar.frame:Hide()
        else
            local srcIdx = win.scrollOffset + i
            local src    = sources and sources[srcIdx]
            if src then
                bar.frame:Show()

                local guid = (not IsSecret(src.sourceGUID)) and src.sourceGUID or nil
                bar.frame.sourceGUID   = guid
                bar.frame.testIndex    = nil
                bar.frame.drillSpellID = nil

                local classFilename
                if not IsSecret(src.classFilename) then
                    classFilename = src.classFilename
                    if guid and classFilename then classCache[guid] = classFilename end
                elseif guid then
                    classFilename = classCache[guid]
                end

                local fgR, fgG, fgB = GetBarFGColor(db, classFilename)
                bar.statusbar:SetStatusBarColor(fgR, fgG, fgB)
                bar.statusbar:SetMinMaxValues(0, session.maxAmount or 1)
                bar.statusbar:SetValue(src.totalAmount or 0)

                local bgR, bgG, bgB, bgA = GetBarBGColor(db, classFilename)
                bar.background:SetVertexColor(bgR, bgG, bgB, bgA)

                local rawName = src.name
                local nameIsSecret = IsSecret(rawName)
                local isLocal = (not IsSecret(src.isLocalPlayer)) and src.isLocalPlayer
                local plainName = nil

                if isLocal then
                    plainName = UnitName("player") or "?"
                    win.positionCache[srcIdx] = plainName
                elseif not nameIsSecret and rawName and rawName ~= "" then
                    plainName = rawName
                    win.positionCache[srcIdx] = plainName
                elseif not nameIsSecret then
                    plainName = win.positionCache[srcIdx] or "?"
                end
                bar.frame.sourceName = plainName or "?"

                local tR, tG, tB = GetTextColor(db, classFilename)
                if plainName then
                    if db.showRank then
                        local rr, rg, rb = GetRankColor(db, classFilename)
                        bar.leftText:SetText(format("|cff%02x%02x%02x%d.|r %s",
                            rr * 255, rg * 255, rb * 255, srcIdx, plainName))
                    else
                        bar.leftText:SetText(plainName)
                    end
                elseif nameIsSecret then
                    if db.showRank then
                        bar.leftText:SetFormattedText("%d. %s", srcIdx, rawName)
                    else
                        bar.leftText:SetText(rawName)
                    end
                else
                    bar.leftText:SetText("?")
                end
                bar.leftText:SetTextColor(tR, tG, tB)

                if useCombined then
                    FormatCombinedText(bar.rightText, src.totalAmount, src.amountPerSecond)
                else
                    local rawValue = usePerSec and src.amountPerSecond or src.totalAmount
                    FormatValueText(bar.rightText, rawValue)
                end
                local vR, vG, vB = GetValueColor(db, classFilename)
                bar.rightText:SetTextColor(vR, vG, vB)
                if bar._isDrill then
                    bar._isDrill = nil
                    bar._drillHasIcon = nil
                    bar.pctText:Hide()
                    bar.rightText:ClearAllPoints()
                    bar.rightText:SetPoint("RIGHT", -4, 0)
                    bar.classIcon:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
                    ApplyBarIconLayout(bar, db)
                end

                if db.showClassIcon then
                    local coords = classFilename and CLASS_ICON_COORDS[classFilename]
                    if coords then
                        bar.classIcon:SetTexCoord(unpack(coords))
                        bar.classIcon:Show()
                    else
                        bar.classIcon:Hide()
                    end
                else
                    bar.classIcon:Hide()
                end
            else
                bar.frame:Hide()
                bar.frame.sourceGUID = nil
                bar.frame.sourceName = nil
            end
        end
    end
end

function TUI:RefreshMeter()
    for _, win in pairs(windows) do
        RefreshWindow(win)
    end
end

function TUI:SetMeterTestMode(enabled)
    testMode           = enabled
    TUI._meterTestMode = enabled
    TUI:RefreshMeter()
end

local timerElapsed = 0
local function OnUpdate(_, dt)
    timerElapsed = timerElapsed + dt
    if timerElapsed < 0.5 then return end
    timerElapsed = 0

    for _, win in pairs(windows) do
        if not win.header or not win.header.timer then break end
        if win.sessionType then
            local dur = C_DamageMeter.GetSessionDurationSeconds(win.sessionType)
            if dur then
                local ok = pcall(function()
                    win.header.timer:SetText(format("%d:%02d", floor(dur / 60), floor(dur % 60)))
                end)
                if not ok then win.header.timer:SetText("--:--") end
            end
        end
    end
end

function TUI:ResizeMeterWindow(index)
    local win = windows[index]
    if not win or not win.window then return end
    local db = GetWinDB(index)
    local w, h = db.standaloneWidth, db.standaloneHeight
    win.window:SetSize(w, h)
    if win.window.mover then
        win.window.mover:SetSize(w, h)
    end
end

function TUI:CreateExtraWindow(index)
    if windows[index] then return end
    local db = TUI.db.profile.damageMeter
    local ewdb = db.extraWindows[index] or {}
    local win = NewWindowState(index, ewdb.modeIndex)
    windows[index] = win
    CreateMeterFrame(win, false)
    RefreshWindow(win)
end

function TUI:DestroyExtraWindow(index)
    local win = windows[index]
    if not win then return end
    local winName = "TrenchyUIMeter" .. index
    if win.window then
        E:DisableMover(winName)
        win.window:Hide()
    end
    windows[index] = nil
end

local function RespaceBarAnchors(win, db)
    local sp = max(0, db.barSpacing or 1)
    for i = 1, MAX_BARS do
        local bar = win.bars[i]
        if not bar then break end
        bar.frame:ClearAllPoints()
        if i == 1 then
            bar.frame:SetPoint("TOPLEFT",  win.frame, "TOPLEFT",  0, -sp)
            bar.frame:SetPoint("TOPRIGHT", win.frame, "TOPRIGHT", 0, -sp)
        else
            bar.frame:SetPoint("TOPLEFT",  win.bars[i-1].frame, "BOTTOMLEFT",  0, -sp)
            bar.frame:SetPoint("TOPRIGHT", win.bars[i-1].frame, "BOTTOMRIGHT", 0, -sp)
        end
    end
end

function TUI:UpdateMeterLayout()
    if not next(windows) then return end

    for _, win in pairs(windows) do
        local db       = GetWinDB(win.index)
        local fontPath = LSM:Fetch("font", db.barFont)
        local flags    = FontFlags(db.barFontOutline)

        ApplyHeaderStyle(win, db)
        RespaceBarAnchors(win, db)
        for i = 1, MAX_BARS do
            local bar = win.bars[i]
            if bar then
                bar.leftText:FontTemplate(fontPath, db.barFontSize, flags)
                bar.rightText:FontTemplate(fontPath, db.barFontSize, flags)
                bar.pctText:FontTemplate(fontPath, db.barFontSize, flags)
                ApplyBarIconLayout(bar, db)
                ApplyBarBorder(bar, db)
            end
        end

        if not win.embedded and win.window then
            if db.showBackdrop then
                win.window:SetTemplate('Transparent')
            else
                win.window:SetBackdrop(nil)
            end
            if win.headerBorder then
                if db.showHeaderBorder then
                    win.headerBorder:SetTemplate()
                else
                    win.headerBorder:SetBackdrop(nil)
                end
            end
        end

        if win.embedded then
            ResizeToPanel(win)
        else
            ResizeStandalone(win)
        end
    end

    self:RefreshMeter()
end

function TUI:InitDamageMeter()
    if not self.db or not self.db.profile.damageMeter.enabled then return end

    SetCVar('damageMeterEnabled', 0)

    C_Timer.After(0, function()
        local db = TUI.db.profile.damageMeter

        local win1 = NewWindowState(1, db.modeIndex)
        windows[1] = win1
        CreateMeterFrame(win1, db.embedded)

        local we = db.windowEnabled
        for i = 2, 4 do
            if we and we[i] then
                local ewdb = db.extraWindows[i] or {}
                local win  = NewWindowState(i, ewdb.modeIndex)
                windows[i] = win
                CreateMeterFrame(win, false)
            end
        end

        local evFrame = win1.frame
        if not evFrame then return end

        evFrame:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
        evFrame:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
        evFrame:RegisterEvent("DAMAGE_METER_RESET")
        evFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        evFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        evFrame:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_DISABLED" then
                for _, w in pairs(windows) do
                    ExitDrillDown(w)
                end
                return
            elseif event == "PLAYER_ENTERING_WORLD" then
                wipe(classCache)
                for _, w in pairs(windows) do
                    wipe(w.positionCache)
                    w.scrollOffset  = 0
                    w.drillSource   = nil
                    w.sessionId     = nil
                    w.sessionType   = Enum.DamageMeterSessionType.Current
                end
                if TUI.db.profile.damageMeter.autoResetOnComplete then
                    local _, instanceType = IsInInstance()
                    if instanceType == "party" or instanceType == "raid" or instanceType == "scenario" then
                        C_DamageMeter.ResetAllCombatSessions()
                    end
                end
            elseif event == "DAMAGE_METER_RESET" then
                for _, w in pairs(windows) do
                    w.scrollOffset  = 0
                    w.drillSource   = nil
                    w.sessionId     = nil
                    w.sessionType   = Enum.DamageMeterSessionType.Current
                end
                TUI:RefreshMeter()
            else
                TUI:RefreshMeter()
            end
        end)
        evFrame:SetScript("OnUpdate", OnUpdate)

        hooksecurefunc(CH, "PositionChats", function()
            if db.embedded then ResizeToPanel(win1) end
        end)

        TUI:RefreshMeter()
    end)
end

SLASH_TUITDM1 = '/tdm'
SlashCmdList['TUITDM'] = function()
    local open = E.Libs.AceConfigDialog and E.Libs.AceConfigDialog.OpenFrames and E.Libs.AceConfigDialog.OpenFrames['ElvUI']
    if not open then E:ToggleOptions('TrenchyUI') end
    C_Timer.After(0.1, function()
        E.Libs.AceConfigDialog:SelectGroup('ElvUI', 'TrenchyUI', 'damageMeter')
    end)
end
