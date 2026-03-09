local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH
local P = E.DF and E.DF.profile

TUI.defaults = {
    profile = {
        installedProfileVersion = nil,
        compat = {},
        qol = {
            hideTalkingHead = false,
            autoFillDelete  = false,
            moveableFrames  = false,
            fastLoot        = false,
            difficultyText  = false,
            difficultyFont    = 'Expressway',
            difficultyFontSize = 14,
            difficultyFontOutline = 'OUTLINE',
            difficultyColors = {
                normal      = { r = 0.60, g = 0.60, b = 0.60 },
                heroic      = { r = 0.00, g = 0.44, b = 0.87 },
                mythic      = { r = 0.78, g = 0.00, b = 1.00 },
                keystoneMod = { r = 1.00, g = 0.50, b = 0.00 },
                timewalking = { r = 0.00, g = 0.80, b = 0.60 },
                lfr         = { r = 0.00, g = 0.80, b = 0.00 },
                follower    = { r = 0.80, g = 0.80, b = 0.80 },
                delve       = { r = 0.80, g = 0.60, b = 0.20 },
                other       = { r = 1.00, g = 1.00, b = 1.00 },
            },
        },
        addons = {
            skinWarpDeplete = false,
            skinBigWigs     = false,
            skinAuctionator = false,
            skinOPie        = false,
            skinBugSack     = false,
        },
        nameplates = {
            classificationOverThreat = false,
            classificationInstanceOnly = false,
            interruptCastbarColors      = false,
            castbarInterruptReady       = { r = 0.2, g = 0.8, b = 0.2 },
            castbarInterruptOnCD        = { r = 0.9, g = 0.4, b = 0.1 },
            castbarMarkerColor          = { r = 1.0, g = 1.0, b = 1.0 },
            disableFriendlyHighlight = false,
            focusGlow = {
                enabled = false,
                color   = { r = 0.5, g = 0.3, b = 0.9, a = 0.3 },
                texture = 'TrenchyFocus',
            },
        },
        pixelGlow = {
            enabled   = false,
            lines     = 8,
            speed     = 0.25,
            thickness = 2,
            length    = nil,
        },
        cooldownManager = {
            enabled = false,
            hideSwipe = false,
            selectedViewer = 'essential',
            viewers = {
                essential = {
                    iconWidth = 30, iconHeight = 30, iconZoom = 0, spacing = 2, iconsPerRow = 12, growthDirection = 'DOWN',
                    cooldownText = { font = 'Expressway', fontSize = 16, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'CENTER', xOffset = 0, yOffset = 0 },
                    countText    = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'BOTTOMRIGHT', xOffset = 0, yOffset = 0 },
                },
                utility = {
                    iconWidth = 30, iconHeight = 30, iconZoom = 0, spacing = 2, iconsPerRow = 12, growthDirection = 'DOWN',
                    cooldownText = { font = 'Expressway', fontSize = 16, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'CENTER', xOffset = 0, yOffset = 0 },
                    countText    = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'BOTTOMRIGHT', xOffset = 0, yOffset = 0 },
                },
                buffIcon = {
                    iconWidth = 30, iconHeight = 30, iconZoom = 0, spacing = 2, iconsPerRow = 12, growthDirection = 'DOWN',
                    cooldownText = { font = 'Expressway', fontSize = 16, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'CENTER', xOffset = 0, yOffset = 0 },
                    countText    = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'BOTTOMRIGHT', xOffset = 0, yOffset = 0 },
                },
                buffBar = {
                    iconWidth = 30, iconHeight = 30, iconZoom = 0, spacing = 2, iconsPerRow = 12, growthDirection = 'DOWN',
                    cooldownText = { font = 'Expressway', fontSize = 16, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'CENTER', xOffset = 0, yOffset = 0 },
                    countText    = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'BOTTOMRIGHT', xOffset = 0, yOffset = 0 },
                },
            },
            glow = {
                enabled   = false,
                type      = 'pixel',
                color     = { r = 0.95, g = 0.95, b = 0.32, a = 1 },
                lines     = 8,
                speed     = 0.25,
                thickness = 2,
                length    = nil,
                particles = 4,
                scale     = 1,
                startAnim = true,
            },
        },
        damageMeter = {
            enabled       = false,
            barHeight     = 18,
            barSpacing    = 1,
            showClassIcon = false,
            showTimer     = false,
            modeIndex     = 1,
            autoResetOnComplete = false,
            embedded         = true,
            standaloneWidth  = 220,
            standaloneHeight = 180,
            windowEnabled    = { true, false, false, false },
            extraWindows     = {},
            showBackdrop     = true,
            showHeaderBorder = true,
            headerFont        = 'Expressway',
            headerFontSize    = 11,
            headerFontOutline = 'OUTLINE',
            headerBGColor   = { r = 0.06, g = 0.06, b = 0.06, a = 0.85 },
            headerFontColor = { r = 1.00, g = 1.00, b = 1.00 },
            barClassColor = true,
            barColor      = { r = 0.60, g = 0.60, b = 0.60 },
            barBGClassColor = true,
            barBGColor    = { r = 0.20, g = 0.20, b = 0.20, a = 0.35 },
            barFont        = 'Expressway',
            barFontSize    = 11,
            barFontOutline = 'OUTLINE',
            barBorderEnabled   = false,
            textClassColor = false,
            textColor      = { r = 1.00, g = 1.00, b = 1.00 },
            valueClassColor = false,
            valueColor      = { r = 1.00, g = 1.00, b = 1.00 },
            showRank       = true,
            rankClassColor = false,
            rankColor      = { r = 0.60, g = 0.60, b = 0.60 },
        },
        minimapButtonBar = {
            enabled        = false,
            orientation    = 'HORIZONTAL',
            growthDirection = 'RIGHTDOWN',
            buttonSize     = 28,
            buttonSpacing  = 2,
            buttonsPerRow  = 12,
            buttonBackdrop      = true,
            buttonBackdropColor = { r = 0.00, g = 0.00, b = 0.00, a = 0.50 },
            buttonBorder        = true,
            buttonBorderColor   = { r = 0.00, g = 0.00, b = 0.00, a = 1.00 },
            buttonBorderSize    = 1,
            backdrop       = true,
            backdropColor  = { r = 0.06, g = 0.06, b = 0.06, a = 0.85 },
            border         = true,
            borderColor    = { r = 0.00, g = 0.00, b = 0.00, a = 1.00 },
            borderSize     = 1,
            mouseover      = false,
            mouseoverAlpha = 1.0,
            hideInCombat   = false,
        },
    },
}

if P then
    P.TrenchyUI = E:CopyTable({}, TUI.defaults.profile)
end

function TUI:BuildConfig()
    local tuiVersion = C_AddOns.GetAddOnMetadata("ElvUI_TrenchyUI", "Version") or "?"
    local tuiName = E:TextGradient('TrenchyUI', 1.00,0.18,0.24, 0.80,0.10,0.20)
    E.Options.name = format("%s + |TInterface\\AddOns\\ElvUI_TrenchyUI\\media\\TrenchyUI_Tiny:16:16|t %s |cff99ff33%s|r", E.Options.name, tuiName, tuiVersion)

    E.Options.args.TrenchyUI = ACH:Group(tuiName, nil, 6, "tab")
    local root = E.Options.args.TrenchyUI.args

    root.qol = ACH:Group("QoL", nil, 1)

    root.qol.args.general = ACH:Group("General", nil, 1)
    root.qol.args.general.inline = true
    local qolGen = root.qol.args.general.args

    qolGen.hideTalkingHead = ACH:Toggle(
        "Hide Talking Head",
        "Permanently suppress the Talking Head popup.",
        1, nil, nil, nil,
        function() return TUI.db.profile.qol.hideTalkingHead end,
        function(_, value)
            TUI.db.profile.qol.hideTalkingHead = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    qolGen.autoFillDelete = ACH:Toggle(
        "Auto-fill Delete",
        "Automatically type DELETE in the item destruction confirmation popup.",
        2, nil, nil, nil,
        function() return TUI.db.profile.qol.autoFillDelete end,
        function(_, value)
            TUI.db.profile.qol.autoFillDelete = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    qolGen.moveableFrames = ACH:Toggle(
        "Moveable Frames",
        "Click and drag most Blizzard and addon frames to reposition them freely. "
        .. "Also removes the shift-drag requirement from ElvUI bags.",
        3, nil, nil, nil,
        function() return TUI.db.profile.qol.moveableFrames end,
        function(_, value)
            TUI.db.profile.qol.moveableFrames = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    qolGen.fastLoot = ACH:Toggle(
        "Fast Loot",
        "Instantly loot all items when opening a loot window, skipping the default pickup delay.",
        4, nil, nil, nil,
        function() return TUI.db.profile.qol.fastLoot end,
        function(_, value)
            TUI.db.profile.qol.fastLoot = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    root.qol.args.difficulty = ACH:Group("Difficulty Text", nil, 2)
    root.qol.args.difficulty.inline = true
    local qolDiff = root.qol.args.difficulty.args

    qolDiff.difficultyText = ACH:Toggle(
        function() return TUI.db.profile.qol.difficultyText and "|cff00ff00Enable|r" or "Enable" end,
        "Replace the minimap difficulty flag icon with readable text (N, H, M, M+, TW, etc.).",
        1, nil, nil, nil,
        function() return TUI.db.profile.qol.difficultyText end,
        function(_, value)
            TUI.db.profile.qol.difficultyText = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    local diffDisabled = function() return not TUI.db.profile.qol.difficultyText end

    qolDiff.diffFont = ACH:SharedMediaFont(
        "Font", "Font used for difficulty text.", 2, nil,
        function() return TUI.db.profile.qol.difficultyFont end,
        function(_, value)
            TUI.db.profile.qol.difficultyFont = value
            TUI:UpdateDifficultyFont()
        end,
        diffDisabled
    )

    qolDiff.diffFontSize = ACH:Range(
        "Font Size", "Size of the difficulty text.", 3,
        { min = 6, max = 32, step = 1 }, nil,
        function() return TUI.db.profile.qol.difficultyFontSize end,
        function(_, value)
            TUI.db.profile.qol.difficultyFontSize = value
            TUI:UpdateDifficultyFont()
        end,
        diffDisabled
    )

    qolDiff.diffFontOutline = ACH:FontFlags(
        "Font Outline", "Outline style for difficulty text.", 4, nil,
        function() return TUI.db.profile.qol.difficultyFontOutline end,
        function(_, value)
            TUI.db.profile.qol.difficultyFontOutline = value
            TUI:UpdateDifficultyFont()
        end,
        diffDisabled
    )

    qolDiff.colorHeader = ACH:Header("Difficulty Colors", 5)

    local function getDiffColor(key)
        local colors = TUI.db.profile.qol.difficultyColors
        if not colors then return nil end
        return colors[key]
    end
    local function ensureDiffColor(key)
        local qol = TUI.db.profile.qol
        if not qol.difficultyColors then qol.difficultyColors = {} end
        if not qol.difficultyColors[key] then qol.difficultyColors[key] = { r = 1, g = 1, b = 1 } end
        return qol.difficultyColors[key]
    end

    qolDiff.diffNormal = ACH:Color(
        "Normal", "Color for Normal difficulty.", 6, nil, nil,
        function() local c = getDiffColor("normal") or ensureDiffColor("normal"); return c.r, c.g, c.b end,
        function(_, r, g, b) local c = ensureDiffColor("normal"); c.r, c.g, c.b = r, g, b end,
        diffDisabled
    )

    qolDiff.diffHeroic = ACH:Color(
        "Heroic", "Color for Heroic difficulty.", 7, nil, nil,
        function() local c = getDiffColor("heroic") or ensureDiffColor("heroic"); return c.r, c.g, c.b end,
        function(_, r, g, b) local c = ensureDiffColor("heroic"); c.r, c.g, c.b = r, g, b end,
        diffDisabled
    )

    qolDiff.diffMythic = ACH:Color(
        "Mythic", "Color for Mythic (non-keystone) difficulty.", 8, nil, nil,
        function() local c = getDiffColor("mythic") or ensureDiffColor("mythic"); return c.r, c.g, c.b end,
        function(_, r, g, b) local c = ensureDiffColor("mythic"); c.r, c.g, c.b = r, g, b end,
        diffDisabled
    )

    qolDiff.diffKeystone = ACH:Color(
        "Mythic+", "Color for Mythic Keystone (M+) text and level number.", 9, nil, nil,
        function() local c = getDiffColor("keystoneMod") or ensureDiffColor("keystoneMod"); return c.r, c.g, c.b end,
        function(_, r, g, b) local c = ensureDiffColor("keystoneMod"); c.r, c.g, c.b = r, g, b end,
        diffDisabled
    )

    qolDiff.diffTimewalking = ACH:Color(
        "Timewalking", "Color for Timewalking difficulty.", 10, nil, nil,
        function() local c = getDiffColor("timewalking") or ensureDiffColor("timewalking"); return c.r, c.g, c.b end,
        function(_, r, g, b) local c = ensureDiffColor("timewalking"); c.r, c.g, c.b = r, g, b end,
        diffDisabled
    )

    qolDiff.diffLFR = ACH:Color(
        "LFR", "Color for Looking For Raid difficulty.", 11, nil, nil,
        function() local c = getDiffColor("lfr") or ensureDiffColor("lfr"); return c.r, c.g, c.b end,
        function(_, r, g, b) local c = ensureDiffColor("lfr"); c.r, c.g, c.b = r, g, b end,
        diffDisabled
    )

    qolDiff.diffFollower = ACH:Color(
        "Follower", "Color for Follower Dungeon difficulty.", 12, nil, nil,
        function() local c = getDiffColor("follower") or ensureDiffColor("follower"); return c.r, c.g, c.b end,
        function(_, r, g, b) local c = ensureDiffColor("follower"); c.r, c.g, c.b = r, g, b end,
        diffDisabled
    )

    qolDiff.diffDelve = ACH:Color(
        "Delve", "Color for Delve difficulty.", 13, nil, nil,
        function() local c = getDiffColor("delve") or ensureDiffColor("delve"); return c.r, c.g, c.b end,
        function(_, r, g, b) local c = ensureDiffColor("delve"); c.r, c.g, c.b = r, g, b end,
        diffDisabled
    )

    root.qol.args.minimapButtonBar = ACH:Group("Minimap Buttons", nil, 3)
    root.qol.args.minimapButtonBar.inline = true
    local mbb = root.qol.args.minimapButtonBar.args

    local mbbUpdate = function() if TUI.UpdateMinimapButtonBar then TUI:UpdateMinimapButtonBar() end end
    local mbbDB = function() return TUI.db.profile.minimapButtonBar end
    local mbbDisabled = function() return not mbbDB().enabled end

    mbb.enabled = ACH:Toggle(
        function() return mbbDB().enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Collect minimap addon buttons into a bar.", 1, nil, nil, nil,
        function() return mbbDB().enabled end,
        function(_, value) mbbDB().enabled = value; E:StaticPopup_Show('CONFIG_RL') end)

    mbb.layoutHeader = ACH:Header("Layout", 2)

    mbb.orientation = ACH:Select(
        "Orientation", "Primary direction the bar extends.", 3,
        { HORIZONTAL = 'Horizontal', VERTICAL = 'Vertical' }, nil, nil,
        function() return mbbDB().orientation or 'HORIZONTAL' end,
        function(_, v)
            mbbDB().orientation = v
            -- Reset growth direction to a sensible default
            mbbDB().growthDirection = (v == 'HORIZONTAL') and 'RIGHTDOWN' or 'DOWNRIGHT'
            mbbUpdate()
        end,
        mbbDisabled
    )

    mbb.growthDirection = ACH:Select(
        "Growth Direction", "How buttons fill and wrap.", 4,
        function()
            if (mbbDB().orientation or 'HORIZONTAL') == 'HORIZONTAL' then
                return { RIGHTDOWN = 'Right, then Down', RIGHTUP = 'Right, then Up', LEFTDOWN = 'Left, then Down', LEFTUP = 'Left, then Up' }
            else
                return { DOWNRIGHT = 'Down, then Right', DOWNLEFT = 'Down, then Left', UPRIGHT = 'Up, then Right', UPLEFT = 'Up, then Left' }
            end
        end,
        nil, nil,
        function() return mbbDB().growthDirection or 'RIGHTDOWN' end,
        function(_, v) mbbDB().growthDirection = v; mbbUpdate() end,
        mbbDisabled
    )

    mbb.buttonSize = ACH:Range("Button Size", "Size of each button.", 5, { min = 16, max = 48, step = 1 },
        nil, function() return mbbDB().buttonSize end,
        function(_, v) mbbDB().buttonSize = v; mbbUpdate() end, mbbDisabled)

    mbb.buttonSpacing = ACH:Range("Button Spacing", "Space between buttons.", 6, { min = 0, max = 10, step = 1 },
        nil, function() return mbbDB().buttonSpacing end,
        function(_, v) mbbDB().buttonSpacing = v; mbbUpdate() end, mbbDisabled)

    mbb.buttonsPerRow = ACH:Range("Buttons Per Row", "Number of buttons before wrapping to the next row/column.", 7, { min = 1, max = 24, step = 1 },
        nil, function() return mbbDB().buttonsPerRow end,
        function(_, v) mbbDB().buttonsPerRow = v; mbbUpdate() end, mbbDisabled)

    mbb.btnHeader = ACH:Header("Button Appearance", 10)

    mbb.buttonBackdrop = ACH:Toggle("Button Background", "Show a background behind each button icon.", 11, nil, nil, nil,
        function() return mbbDB().buttonBackdrop end,
        function(_, v) mbbDB().buttonBackdrop = v; mbbUpdate() end, mbbDisabled)

    mbb.buttonBackdropColor = ACH:Color("Button BG Color", nil, 12, true, nil,
        function() local c = mbbDB().buttonBackdropColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().buttonBackdropColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().buttonBackdrop end)

    mbb.buttonBorder = ACH:Toggle("Button Border", "Show a border around each button.", 13, nil, nil, nil,
        function() return mbbDB().buttonBorder end,
        function(_, v) mbbDB().buttonBorder = v; mbbUpdate() end, mbbDisabled)

    mbb.buttonBorderColor = ACH:Color("Button Border Color", nil, 14, true, nil,
        function() local c = mbbDB().buttonBorderColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().buttonBorderColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().buttonBorder end)

    mbb.buttonBorderSize = ACH:Range("Button Border Thickness", nil, 15, { min = 1, max = 4, step = 1 },
        nil, function() return mbbDB().buttonBorderSize end,
        function(_, v) mbbDB().buttonBorderSize = v; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().buttonBorder end)

    mbb.barHeader = ACH:Header("Bar Appearance", 20)

    mbb.backdrop = ACH:Toggle("Bar Background", "Show a backdrop behind the button bar.", 21, nil, nil, nil,
        function() return mbbDB().backdrop end,
        function(_, v) mbbDB().backdrop = v; mbbUpdate() end, mbbDisabled)

    mbb.backdropColor = ACH:Color("Bar BG Color", nil, 22, true, nil,
        function() local c = mbbDB().backdropColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().backdropColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().backdrop end)

    mbb.border = ACH:Toggle("Bar Border", "Show a border around the button bar.", 23, nil, nil, nil,
        function() return mbbDB().border end,
        function(_, v) mbbDB().border = v; mbbUpdate() end, mbbDisabled)

    mbb.borderColor = ACH:Color("Bar Border Color", nil, 24, true, nil,
        function() local c = mbbDB().borderColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().borderColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().border end)

    mbb.borderSize = ACH:Range("Bar Border Thickness", nil, 25, { min = 1, max = 4, step = 1 },
        nil, function() return mbbDB().borderSize end,
        function(_, v) mbbDB().borderSize = v; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().border end)

    mbb.visHeader = ACH:Header("Visibility", 30)

    mbb.mouseover = ACH:Toggle("Mouseover", "Only show the bar when mousing over it.", 31, nil, nil, nil,
        function() return mbbDB().mouseover end,
        function(_, v) mbbDB().mouseover = v; mbbUpdate() end, mbbDisabled)

    mbb.mouseoverAlpha = ACH:Range("Mouseover Alpha", "Bar opacity when visible on mouseover.", 32, { min = 0, max = 1, step = 0.05, isPercent = true },
        nil, function() return mbbDB().mouseoverAlpha end,
        function(_, v) mbbDB().mouseoverAlpha = v; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().mouseover end)

    mbb.hideInCombat = ACH:Toggle("Hide in Combat", "Automatically hide the button bar during combat.", 33, nil, nil, nil,
        function() return mbbDB().hideInCombat end,
        function(_, v) mbbDB().hideInCombat = v; mbbUpdate() end, mbbDisabled)

    if C_DamageMeter and Enum.DamageMeterType then
        root.damageMeter = ACH:Group("TDM", nil, 2)

        local DM_DEFAULTS = {
            standaloneWidth  = 220,
            standaloneHeight = 180,
            showBackdrop     = true,
            showHeaderBorder = true,
            headerFont       = 'Expressway',
            headerFontSize   = 11,
            headerFontOutline = 'OUTLINE',
            headerBGColor    = { r = 0.06, g = 0.06, b = 0.06, a = 0.85 },
            headerFontColor  = { r = 1.00, g = 1.00, b = 1.00 },
            barHeight        = 18,
            barSpacing       = 1,
            showClassIcon    = false,
            barBorderEnabled = false,
            barClassColor    = true,
            barColor         = { r = 0.60, g = 0.60, b = 0.60 },
            barBGClassColor  = true,
            barBGColor       = { r = 0.20, g = 0.20, b = 0.20, a = 0.35 },
            barFont          = 'Expressway',
            barFontSize      = 11,
            barFontOutline   = 'OUTLINE',
            textClassColor   = false,
            textColor        = { r = 1.00, g = 1.00, b = 1.00 },
            valueClassColor  = false,
            valueColor       = { r = 1.00, g = 1.00, b = 1.00 },
            showRank         = true,
            rankClassColor   = false,
            rankColor        = { r = 0.60, g = 0.60, b = 0.60 },
            showTimer        = false,
        }
        TUI.DM_DEFAULTS = DM_DEFAULTS

        local dmDisabled = function() return not TUI.db.profile.damageMeter.enabled end

        TUI._selectedMeterWindow = TUI._selectedMeterWindow or 1

        local function isWindowEnabled(i)
            local we = TUI.db.profile.damageMeter.windowEnabled
            return we and we[i]
        end

        local function selWinDisabled()
            return dmDisabled() or not isWindowEnabled(TUI._selectedMeterWindow)
        end

        local function getWinDB()
            local db = TUI.db.profile.damageMeter
            if TUI._selectedMeterWindow == 1 then return db end
            db.extraWindows[TUI._selectedMeterWindow] = db.extraWindows[TUI._selectedMeterWindow] or {}
            return db.extraWindows[TUI._selectedMeterWindow]
        end

        local function winGet(key)
            local wdb = getWinDB()
            if TUI._selectedMeterWindow == 1 then return wdb[key] end
            local val = wdb[key]
            if val ~= nil then return val end
            return TUI.db.profile.damageMeter[key]
        end

        local function winSet(key, value) getWinDB()[key] = value end

        local function winGetColor(key)
            local c = winGet(key)
            return c.r, c.g, c.b, c.a
        end

        local function winSetColor(key, r, g, b, a)
            local wdb = getWinDB()
            if not wdb[key] then wdb[key] = {} end
            local c = wdb[key]
            c.r, c.g, c.b, c.a = r, g, b, a
        end

        local function winUpdate() TUI:UpdateMeterLayout() end
        local function winRefresh() TUI:RefreshMeter() end

        local WHITE, GREY = '|cFFFFFFFF', '|cFF888888'

        root.damageMeter.args.general = ACH:Group("General", nil, 1)
        root.damageMeter.args.general.inline = true
        local dmGen = root.damageMeter.args.general.args

        dmGen.desc = ACH:Description(
            "TDM is a lightweight meter using the built-in API. "
            .. "Options below to enable additional windows and embed window 1 into the right chat panel. "
            .. "Additional windows can be moved via the movers button at the top of the config.\n\n"
            .. "Left-click the header to choose display mode. "
            .. "Right-click to toggle Current/Overall session. "
            .. "Scroll wheel over the bars to page through all entries.",
            1, "medium"
        )

        dmGen.enabled = ACH:Toggle(
            function() return TUI.db.profile.damageMeter.enabled and "|cff00ff00Enable|r" or "Enable" end,
            "Show TDM.",
            2, nil, nil, nil,
            function() return TUI.db.profile.damageMeter.enabled end,
            function(_, value)
                TUI.db.profile.damageMeter.enabled = value
                E:StaticPopup_Show('CONFIG_RL')
            end
        )

        dmGen.showTimer = ACH:Toggle(
            "Show Timer", "Display the session duration timer in the header.",
            3, nil, nil, nil,
            function() return TUI.db.profile.damageMeter.showTimer end,
            function(_, value) TUI.db.profile.damageMeter.showTimer = value; winUpdate() end,
            dmDisabled
        )

        dmGen.autoResetOnComplete = ACH:Toggle(
            "Auto-Reset on Entry",
            "Automatically reset all meter data when entering a dungeon, raid, or scenario.",
            4, nil, nil, nil,
            function() return TUI.db.profile.damageMeter.autoResetOnComplete end,
            function(_, value) TUI.db.profile.damageMeter.autoResetOnComplete = value end,
            dmDisabled
        )

        dmGen.testMode = ACH:Execute(
            "TDM Test", "Toggle placeholder bars to preview the meter appearance.",
            5,
            function() TUI:SetMeterTestMode(not TUI._meterTestMode) end,
            nil, nil, nil, nil, nil,
            dmDisabled
        )

        root.damageMeter.args.windows = ACH:Group("Windows", nil, 2)
        root.damageMeter.args.windows.inline = true
        local dmWinSel = root.damageMeter.args.windows.args

        dmWinSel.windowSelect = ACH:Select(
            "Window", "Select which window to configure below.", 1,
            function()
                local t = {}
                for i = 1, 4 do
                    local color = isWindowEnabled(i) and WHITE or GREY
                    t[i] = color .. "Window " .. i .. '|r'
                end
                return t
            end,
            nil, nil,
            function() return TUI._selectedMeterWindow end,
            function(_, value) TUI._selectedMeterWindow = value end,
            dmDisabled
        )

        dmWinSel.windowEnabled = ACH:Toggle(
            function() return isWindowEnabled(TUI._selectedMeterWindow) and "|cff00ff00Enable|r" or "Enable" end,
            "Enable or disable this window. Window 1 is always enabled.",
            2, nil, nil, nil,
            function() return isWindowEnabled(TUI._selectedMeterWindow) end,
            function(_, value)
                local db = TUI.db.profile.damageMeter
                db.windowEnabled[TUI._selectedMeterWindow] = value
                if value and TUI._selectedMeterWindow > 1 then
                    db.extraWindows[TUI._selectedMeterWindow] = db.extraWindows[TUI._selectedMeterWindow] or {}
                    local ew = db.extraWindows[TUI._selectedMeterWindow]
                    for key in pairs(DM_DEFAULTS) do
                        local val = db[key]
                        if type(val) == "table" then
                            ew[key] = {}
                            for k, v in pairs(val) do ew[key][k] = v end
                        else
                            ew[key] = val
                        end
                    end
                end
                if value then
                    TUI:CreateExtraWindow(TUI._selectedMeterWindow)
                else
                    TUI:DestroyExtraWindow(TUI._selectedMeterWindow)
                end
            end,
            function() return dmDisabled() or TUI._selectedMeterWindow == 1 end
        )

        dmWinSel.embedded = ACH:Toggle(
            "Embed in Chat Panel",
            "Nest the meter inside the ElvUI Right Chat Panel instead of a standalone window.",
            3, nil, nil, nil,
            function() return TUI.db.profile.damageMeter.embedded end,
            function(_, value)
                TUI.db.profile.damageMeter.embedded = value
                E:StaticPopup_Show('CONFIG_RL')
            end,
            function() return dmDisabled() or TUI._selectedMeterWindow ~= 1 end,
            function() return TUI._selectedMeterWindow ~= 1 end
        )

        dmWinSel.applyToAll = ACH:Execute(
            "Apply Settings to All",
            "Copy Window 1's visual settings to all enabled extra windows.",
            4,
            function()
                local db = TUI.db.profile.damageMeter
                local liveW, liveH
                if db.embedded then
                    local panel = _G.RightChatPanel
                    if panel then
                        liveW = math.floor(panel:GetWidth())
                        liveH = math.floor(panel:GetHeight())
                    end
                end
                for i = 2, 4 do
                    if db.windowEnabled[i] then
                        db.extraWindows[i] = db.extraWindows[i] or {}
                        local ew = db.extraWindows[i]
                        for key in pairs(DM_DEFAULTS) do
                            local val = db[key]
                            if key == 'standaloneWidth' and liveW then
                                val = liveW
                            elseif key == 'standaloneHeight' and liveH then
                                val = liveH
                            end
                            if type(val) == "table" then
                                ew[key] = {}
                                for k, v in pairs(val) do ew[key][k] = v end
                            else
                                ew[key] = val
                            end
                        end
                    end
                end
                winUpdate()
            end,
            nil, nil, nil, nil, nil,
            function() return dmDisabled() or TUI._selectedMeterWindow ~= 1 end,
            function() return TUI._selectedMeterWindow ~= 1 end
        )

        root.damageMeter.args.window = ACH:Group("Window", nil, 3, nil, nil, nil, selWinDisabled)
        root.damageMeter.args.window.inline = true
        local dmWin = root.damageMeter.args.window.args

        local function sizeDisabled()
            return selWinDisabled() or (TUI._selectedMeterWindow == 1 and TUI.db.profile.damageMeter.embedded)
        end

        dmWin.standaloneWidth = ACH:Range(
            "Width", "Width of this window in pixels.", 1,
            { min = 100, max = 600, step = 1 }, nil,
            function()
                if TUI._selectedMeterWindow == 1 and TUI.db.profile.damageMeter.embedded then
                    local panel = _G.RightChatPanel
                    return panel and math.floor(panel:GetWidth()) or winGet('standaloneWidth')
                end
                return winGet('standaloneWidth')
            end,
            function(_, value)
                winSet('standaloneWidth', value)
                TUI:ResizeMeterWindow(TUI._selectedMeterWindow)
            end,
            sizeDisabled
        )

        dmWin.standaloneHeight = ACH:Range(
            "Height", "Height of this window in pixels.", 2,
            { min = 60, max = 600, step = 1 }, nil,
            function()
                if TUI._selectedMeterWindow == 1 and TUI.db.profile.damageMeter.embedded then
                    local panel = _G.RightChatPanel
                    return panel and math.floor(panel:GetHeight()) or winGet('standaloneHeight')
                end
                return winGet('standaloneHeight')
            end,
            function(_, value)
                winSet('standaloneHeight', value)
                TUI:ResizeMeterWindow(TUI._selectedMeterWindow)
            end,
            sizeDisabled
        )

        dmWin.showBackdrop = ACH:Toggle(
            "Window Backdrop", "Show a transparent backdrop matching the ElvUI chat panel style.",
            3, nil, nil, nil,
            function() return winGet('showBackdrop') end,
            function(_, value) winSet('showBackdrop', value); winUpdate() end,
            selWinDisabled
        )

        root.damageMeter.args.header = ACH:Group("Header", nil, 4, nil, nil, nil, selWinDisabled)
        root.damageMeter.args.header.inline = true
        local dmHdr = root.damageMeter.args.header.args

        dmHdr.headerFont = ACH:SharedMediaFont(
            "Font", "Font used for the header title and timer.", 1, nil,
            function() return winGet('headerFont') end,
            function(_, value) winSet('headerFont', value); winUpdate() end,
            selWinDisabled
        )

        dmHdr.headerFontSize = ACH:Range(
            "Font Size", "Size of the header text.", 2,
            { min = 8, max = 24, step = 1 }, nil,
            function() return winGet('headerFontSize') end,
            function(_, value) winSet('headerFontSize', value); winUpdate() end,
            selWinDisabled
        )

        dmHdr.headerFontOutline = ACH:FontFlags(
            "Font Outline", "Outline style for the header text.", 3, nil,
            function() return winGet('headerFontOutline') end,
            function(_, value) winSet('headerFontOutline', value); winUpdate() end,
            selWinDisabled
        )

        dmHdr.headerFontColor = ACH:Color(
            "Font Color", "Color for the mode label and timer text.",
            4, nil, nil,
            function() return winGetColor('headerFontColor') end,
            function(_, r, g, b) winSetColor('headerFontColor', r, g, b); winUpdate() end,
            selWinDisabled
        )

        dmHdr.showHeaderBorder = ACH:Toggle(
            "Header Border", "Show a border around the header section.",
            5, nil, nil, nil,
            function() return winGet('showHeaderBorder') end,
            function(_, value) winSet('showHeaderBorder', value); winUpdate() end,
            selWinDisabled
        )

        dmHdr.headerBGColor = ACH:Color(
            "Background", "Background color and transparency of the header.",
            6, true, nil,
            function() return winGetColor('headerBGColor') end,
            function(_, r, g, b, a) winSetColor('headerBGColor', r, g, b, a); winUpdate() end,
            selWinDisabled
        )

        root.damageMeter.args.bars = ACH:Group("Bars", nil, 5, nil, nil, nil, selWinDisabled)
        root.damageMeter.args.bars.inline = true
        local dmBars = root.damageMeter.args.bars.args

        dmBars.barHeight = ACH:Range(
            "Height", "Fixed height of each bar in pixels.", 1,
            { min = 12, max = 40, step = 1 }, nil,
            function() return winGet('barHeight') end,
            function(_, value) winSet('barHeight', value); winUpdate() end,
            selWinDisabled
        )

        dmBars.barSpacing = ACH:Range(
            "Spacing", "Vertical gap between bars in pixels.", 2,
            { min = 0, max = 10, step = 1 }, nil,
            function() return winGet('barSpacing') end,
            function(_, value) winSet('barSpacing', value); winUpdate() end,
            selWinDisabled
        )

        dmBars.barBorderEnabled = ACH:Toggle(
            "Borders", "Draw ElvUI-styled borders around each bar.",
            3, nil, nil, nil,
            function() return winGet('barBorderEnabled') end,
            function(_, value) winSet('barBorderEnabled', value); winUpdate() end,
            selWinDisabled
        )

        dmBars.showClassIcon = ACH:Toggle(
            "Class Icons", "Show a class icon to the left of each player name.",
            4, nil, nil, nil,
            function() return winGet('showClassIcon') end,
            function(_, value) winSet('showClassIcon', value); winUpdate() end,
            selWinDisabled
        )

        dmBars.fgHeader = ACH:Header("Foreground", 10)

        dmBars.barClassColor = ACH:Toggle(
            "Class Color", "Use ElvUI class colors for bar foregrounds.",
            11, nil, nil, nil,
            function() return winGet('barClassColor') end,
            function(_, value) winSet('barClassColor', value); winRefresh() end,
            selWinDisabled
        )

        dmBars.barColor = ACH:Color(
            "Color", "Fixed bar foreground color (used when Class Color is off).",
            12, nil, nil,
            function() return winGetColor('barColor') end,
            function(_, r, g, b) winSetColor('barColor', r, g, b); winRefresh() end,
            function() return selWinDisabled() or winGet('barClassColor') end
        )

        dmBars.bgHeader = ACH:Header("Background", 20)

        dmBars.barBGClassColor = ACH:Toggle(
            "Class Color", "Use ElvUI class colors for bar backgrounds.",
            21, nil, nil, nil,
            function() return winGet('barBGClassColor') end,
            function(_, value) winSet('barBGClassColor', value); winRefresh() end,
            selWinDisabled
        )

        dmBars.barBGColor = ACH:Color(
            "Color", "Bar background color and alpha.",
            22, true, nil,
            function() return winGetColor('barBGColor') end,
            function(_, r, g, b, a) winSetColor('barBGColor', r, g, b, a); winRefresh() end,
            function() return selWinDisabled() or winGet('barBGClassColor') end
        )

        root.damageMeter.args.text = ACH:Group("Text", nil, 6, nil, nil, nil, selWinDisabled)
        root.damageMeter.args.text.inline = true
        local dmText = root.damageMeter.args.text.args

        dmText.barFont = ACH:SharedMediaFont(
            "Font", "Font used for bar name and value text.", 1, nil,
            function() return winGet('barFont') end,
            function(_, value) winSet('barFont', value); winUpdate() end,
            selWinDisabled
        )

        dmText.barFontSize = ACH:Range(
            "Font Size", "Size of bar text.", 2,
            { min = 8, max = 24, step = 1 }, nil,
            function() return winGet('barFontSize') end,
            function(_, value) winSet('barFontSize', value); winUpdate() end,
            selWinDisabled
        )

        dmText.barFontOutline = ACH:FontFlags(
            "Font Outline", "Outline style for bar text.", 3, nil,
            function() return winGet('barFontOutline') end,
            function(_, value) winSet('barFontOutline', value); winUpdate() end,
            selWinDisabled
        )

        dmText.nameHeader = ACH:Header("Name", 10)

        dmText.textClassColor = ACH:Toggle(
            "Class Color", "Use ElvUI class colors for player name text.",
            11, nil, nil, nil,
            function() return winGet('textClassColor') end,
            function(_, value) winSet('textClassColor', value); winRefresh() end,
            selWinDisabled
        )

        dmText.textColor = ACH:Color(
            "Color", "Fixed name text color (used when Class Color is off).",
            12, nil, nil,
            function() return winGetColor('textColor') end,
            function(_, r, g, b) winSetColor('textColor', r, g, b); winRefresh() end,
            function() return selWinDisabled() or winGet('textClassColor') end
        )

        dmText.valueHeader = ACH:Header("Value", 20)

        dmText.valueClassColor = ACH:Toggle(
            "Class Color", "Use ElvUI class colors for value text.",
            21, nil, nil, nil,
            function() return winGet('valueClassColor') end,
            function(_, value) winSet('valueClassColor', value); winRefresh() end,
            selWinDisabled
        )

        dmText.valueColor = ACH:Color(
            "Color", "Fixed value text color (used when Class Color is off).",
            22, nil, nil,
            function() return winGetColor('valueColor') end,
            function(_, r, g, b) winSetColor('valueColor', r, g, b); winRefresh() end,
            function() return selWinDisabled() or winGet('valueClassColor') end
        )

        dmText.rankHeader = ACH:Header("Rank", 30)

        local rankDisabled = function() return selWinDisabled() or not winGet('showRank') end

        dmText.showRank = ACH:Toggle(
            "Show Rank", "Show the rank number before each player name.",
            31, nil, nil, nil,
            function() return winGet('showRank') end,
            function(_, value) winSet('showRank', value); winRefresh() end,
            selWinDisabled
        )

        dmText.rankClassColor = ACH:Toggle(
            "Class Color", "Use ElvUI class colors for the rank number.",
            32, nil, nil, nil,
            function() return winGet('rankClassColor') end,
            function(_, value) winSet('rankClassColor', value); winRefresh() end,
            rankDisabled
        )

        dmText.rankColor = ACH:Color(
            "Color", "Fixed rank number color (used when Class Color is off).",
            33, nil, nil,
            function() return winGetColor('rankColor') end,
            function(_, r, g, b) winSetColor('rankColor', r, g, b); winRefresh() end,
            function() return rankDisabled() or winGet('rankClassColor') end
        )
    end

    do -- Cooldown Manager config
        root.cooldownManager = ACH:Group("CDM", nil, 2.5, 'tab')

        local cdmDB = function() return TUI.db.profile.cooldownManager end
        local cdmDisabled = function() return not cdmDB().enabled end
        local cdmRefresh = function()
            if TUI.RefreshCDM then TUI:RefreshCDM() end
        end
        local selVDB = function() return cdmDB().viewers[cdmDB().selectedViewer] end

        local VIEWER_CHOICES = { essential = 'Essential', utility = 'Utility', buffIcon = 'Buff Icon', buffBar = 'Ext. Defensives' }
        local POSITIONS = { CENTER = 'Center', TOP = 'Top', BOTTOM = 'Bottom', LEFT = 'Left', RIGHT = 'Right',
            TOPLEFT = 'Top Left', TOPRIGHT = 'Top Right', BOTTOMLEFT = 'Bottom Left', BOTTOMRIGHT = 'Bottom Right' }

        -- General tab
        root.cooldownManager.args.general = ACH:Group("General", nil, 1)
        local cdmGen = root.cooldownManager.args.general.args

        cdmGen.desc = ACH:Description(
            "Reparents Blizzard's CDM icons into TUI containers with ElvUI movers. "
            .. "Overrides ElvUI's CDM text styling with per-viewer font settings.",
            1, "medium"
        )

        cdmGen.enabled = ACH:Toggle(
            function() return cdmDB().enabled and "|cff00ff00Enable|r" or "Enable" end,
            "Enable TrenchyUI Cooldown Manager customizations.",
            2, nil, nil, nil,
            function() return cdmDB().enabled end,
            function(_, value)
                cdmDB().enabled = value
                E:StaticPopup_Show('CONFIG_RL')
            end
        )

        cdmGen.hideSwipe = ACH:Toggle(
            "Hide GCD Swipe", "Hide the cooldown swipe overlay on CDM icons.",
            3, nil, nil, nil,
            function() return cdmDB().hideSwipe end,
            function(_, value) cdmDB().hideSwipe = value; cdmRefresh() end,
            cdmDisabled
        )

        -- Viewer tab — dropdown + settings for selected viewer
        root.cooldownManager.args.viewer = ACH:Group("Viewer", nil, 2, nil, nil, nil, cdmDisabled)
        local cdmViewer = root.cooldownManager.args.viewer.args

        cdmViewer.selectedViewer = ACH:Select(
            "Viewer", "Select which CDM viewer to configure.", 1,
            VIEWER_CHOICES, nil, nil,
            function() return cdmDB().selectedViewer end,
            function(_, value) cdmDB().selectedViewer = value end
        )

        cdmViewer.spacer1 = ACH:Spacer(2)

        -- Layout group
        cdmViewer.layout = ACH:Group("Layout", nil, 3)
        cdmViewer.layout.inline = true
        local cdmLayout = cdmViewer.layout.args

        cdmLayout.iconWidth = ACH:Range(
            "Icon Width", nil, 1,
            { min = 16, max = 80, step = 1 }, nil,
            function() return selVDB().iconWidth end,
            function(_, value) selVDB().iconWidth = value; cdmRefresh() end
        )

        cdmLayout.iconHeight = ACH:Range(
            "Icon Height", nil, 2,
            { min = 16, max = 80, step = 1 }, nil,
            function() return selVDB().iconHeight end,
            function(_, value) selVDB().iconHeight = value; cdmRefresh() end
        )

        cdmLayout.iconZoom = ACH:Range(
            "Icon Zoom", "Crop the icon texture inward.", 3,
            { min = 0, max = 0.60, step = 0.01, isPercent = true }, nil,
            function() return selVDB().iconZoom end,
            function(_, value) selVDB().iconZoom = value; cdmRefresh() end
        )

        cdmLayout.spacing = ACH:Range(
            "Spacing", "Gap between icons in pixels.", 4,
            { min = 0, max = 20, step = 1 }, nil,
            function() return selVDB().spacing end,
            function(_, value) selVDB().spacing = value; cdmRefresh() end
        )

        cdmLayout.iconsPerRow = ACH:Range(
            "Icons Per Row", nil, 5,
            { min = 1, max = 20, step = 1 }, nil,
            function() return selVDB().iconsPerRow end,
            function(_, value) selVDB().iconsPerRow = value; cdmRefresh() end
        )

        cdmLayout.growthDirection = ACH:Select(
            "Vertical Growth", nil, 6,
            { DOWN = 'Down', UP = 'Up' },
            nil, nil,
            function() return selVDB().growthDirection end,
            function(_, value) selVDB().growthDirection = value; cdmRefresh() end
        )

        -- Cooldown Text group
        cdmViewer.cooldownText = ACH:Group("Cooldown Text", nil, 4)
        cdmViewer.cooldownText.inline = true
        local cdmCD = cdmViewer.cooldownText.args

        cdmCD.font = ACH:SharedMediaFont("Font", nil, 1, nil,
            function() return selVDB().cooldownText.font end,
            function(_, value) selVDB().cooldownText.font = value; cdmRefresh() end
        )

        cdmCD.fontSize = ACH:Range(
            "Font Size", nil, 2,
            { min = 6, max = 36, step = 1 }, nil,
            function() return selVDB().cooldownText.fontSize end,
            function(_, value) selVDB().cooldownText.fontSize = value; cdmRefresh() end
        )

        cdmCD.fontOutline = ACH:FontFlags(
            "Font Outline", nil, 3, nil,
            function() return selVDB().cooldownText.fontOutline end,
            function(_, value) selVDB().cooldownText.fontOutline = value; cdmRefresh() end
        )

        cdmCD.classColor = ACH:Toggle(
            "Class Color", "Use custom class color.", 4, nil, nil, nil,
            function() return selVDB().cooldownText.classColor end,
            function(_, value) selVDB().cooldownText.classColor = value; cdmRefresh() end
        )

        cdmCD.color = ACH:Color(
            "Color", nil, 5, nil, nil,
            function()
                local c = selVDB().cooldownText.color
                return c.r, c.g, c.b
            end,
            function(_, r, g, b)
                local c = selVDB().cooldownText.color
                c.r, c.g, c.b = r, g, b
                cdmRefresh()
            end,
            function() return selVDB().cooldownText.classColor end
        )

        cdmCD.position = ACH:Select(
            "Position", nil, 6, POSITIONS, nil, nil,
            function() return selVDB().cooldownText.position end,
            function(_, value) selVDB().cooldownText.position = value; cdmRefresh() end
        )

        cdmCD.xOffset = ACH:Range(
            "X-Offset", nil, 7,
            { min = -45, max = 45, step = 1 }, nil,
            function() return selVDB().cooldownText.xOffset end,
            function(_, value) selVDB().cooldownText.xOffset = value; cdmRefresh() end
        )

        cdmCD.yOffset = ACH:Range(
            "Y-Offset", nil, 8,
            { min = -45, max = 45, step = 1 }, nil,
            function() return selVDB().cooldownText.yOffset end,
            function(_, value) selVDB().cooldownText.yOffset = value; cdmRefresh() end
        )

        -- Count Text group
        cdmViewer.countText = ACH:Group("Count Text", nil, 5)
        cdmViewer.countText.inline = true
        local cdmCT = cdmViewer.countText.args

        cdmCT.font = ACH:SharedMediaFont("Font", nil, 1, nil,
            function() return selVDB().countText.font end,
            function(_, value) selVDB().countText.font = value; cdmRefresh() end
        )

        cdmCT.fontSize = ACH:Range(
            "Font Size", nil, 2,
            { min = 6, max = 36, step = 1 }, nil,
            function() return selVDB().countText.fontSize end,
            function(_, value) selVDB().countText.fontSize = value; cdmRefresh() end
        )

        cdmCT.fontOutline = ACH:FontFlags(
            "Font Outline", nil, 3, nil,
            function() return selVDB().countText.fontOutline end,
            function(_, value) selVDB().countText.fontOutline = value; cdmRefresh() end
        )

        cdmCT.classColor = ACH:Toggle(
            "Class Color", "Use custom class color.", 4, nil, nil, nil,
            function() return selVDB().countText.classColor end,
            function(_, value) selVDB().countText.classColor = value; cdmRefresh() end
        )

        cdmCT.color = ACH:Color(
            "Color", nil, 5, nil, nil,
            function()
                local c = selVDB().countText.color
                return c.r, c.g, c.b
            end,
            function(_, r, g, b)
                local c = selVDB().countText.color
                c.r, c.g, c.b = r, g, b
                cdmRefresh()
            end,
            function() return selVDB().countText.classColor end
        )

        cdmCT.position = ACH:Select(
            "Position", nil, 6, POSITIONS, nil, nil,
            function() return selVDB().countText.position end,
            function(_, value) selVDB().countText.position = value; cdmRefresh() end
        )

        cdmCT.xOffset = ACH:Range(
            "X-Offset", nil, 7,
            { min = -45, max = 45, step = 1 }, nil,
            function() return selVDB().countText.xOffset end,
            function(_, value) selVDB().countText.xOffset = value; cdmRefresh() end
        )

        cdmCT.yOffset = ACH:Range(
            "Y-Offset", nil, 8,
            { min = -45, max = 45, step = 1 }, nil,
            function() return selVDB().countText.yOffset end,
            function(_, value) selVDB().countText.yOffset = value; cdmRefresh() end
        )

        -- Glow tab
        root.cooldownManager.args.glow = ACH:Group("Glow", nil, 3, nil, nil, nil, cdmDisabled)
        local cdmGlow = root.cooldownManager.args.glow.args

        local glowDisabled = function() return not cdmDB().glow.enabled end

        cdmGlow.enabled = ACH:Toggle(
            function() return cdmDB().glow.enabled and "|cff00ff00Enable|r" or "Enable" end,
            "Apply a glow effect to cooldown icons.",
            1, nil, nil, nil,
            function() return cdmDB().glow.enabled end,
            function(_, value) cdmDB().glow.enabled = value; cdmRefresh() end
        )

        cdmGlow.type = ACH:Select(
            "Type", "Glow animation style.", 2,
            { pixel = 'Pixel', autocast = 'Autocast', button = 'Button', proc = 'Proc' },
            nil, nil,
            function() return cdmDB().glow.type end,
            function(_, value) cdmDB().glow.type = value; cdmRefresh() end,
            glowDisabled
        )

        cdmGlow.color = ACH:Color(
            "Color", "Glow color.", 3, true, nil,
            function()
                local c = cdmDB().glow.color
                return c.r, c.g, c.b, c.a
            end,
            function(_, r, g, b, a)
                local c = cdmDB().glow.color
                c.r, c.g, c.b, c.a = r, g, b, a
                cdmRefresh()
            end,
            glowDisabled
        )

        cdmGlow.lines = ACH:Range(
            "Lines", "Number of glow lines (Pixel only).", 4,
            { min = 1, max = 20, step = 1 }, nil,
            function() return cdmDB().glow.lines end,
            function(_, value) cdmDB().glow.lines = value; cdmRefresh() end,
            function() return glowDisabled() or cdmDB().glow.type ~= 'pixel' end
        )

        cdmGlow.speed = ACH:Range(
            "Speed", "Animation speed.", 5,
            { min = 0.05, max = 2, step = 0.05 }, nil,
            function() return cdmDB().glow.speed end,
            function(_, value) cdmDB().glow.speed = value; cdmRefresh() end,
            glowDisabled
        )

        cdmGlow.thickness = ACH:Range(
            "Thickness", "Line thickness (Pixel only).", 6,
            { min = 1, max = 8, step = 1 }, nil,
            function() return cdmDB().glow.thickness end,
            function(_, value) cdmDB().glow.thickness = value; cdmRefresh() end,
            function() return glowDisabled() or cdmDB().glow.type ~= 'pixel' end
        )

        cdmGlow.particles = ACH:Range(
            "Particles", "Number of particles (Autocast only).", 7,
            { min = 1, max = 16, step = 1 }, nil,
            function() return cdmDB().glow.particles end,
            function(_, value) cdmDB().glow.particles = value; cdmRefresh() end,
            function() return glowDisabled() or cdmDB().glow.type ~= 'autocast' end
        )

        cdmGlow.scale = ACH:Range(
            "Scale", "Glow scale (Autocast only).", 8,
            { min = 0.5, max = 3, step = 0.1 }, nil,
            function() return cdmDB().glow.scale end,
            function(_, value) cdmDB().glow.scale = value; cdmRefresh() end,
            function() return glowDisabled() or cdmDB().glow.type ~= 'autocast' end
        )
    end

    root.unitframes = ACH:Group("UnitFrames", nil, 3)

    root.unitframes.args.pixelGlow = ACH:Group("Pixel Glow", nil, 1)
    root.unitframes.args.pixelGlow.inline = true
    local uf = root.unitframes.args.pixelGlow.args

    uf.auraDesc = ACH:Description(
        "Replaces ElvUI's built-in Aura Highlight (GLOW/FILL) with a Pixel Glow "
        .. "on unit frames when a dispellable debuff is detected. "
        .. "Uses ElvUI's existing debuff highlight colors.",
        1, "medium"
    )

    uf.auraEnabled = ACH:Toggle(
        function() return TUI.db.profile.pixelGlow.enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Replace ElvUI's Aura Highlight with a Pixel Glow effect.",
        2, nil, nil, nil,
        function() return TUI.db.profile.pixelGlow.enabled end,
        function(_, value)
            TUI.db.profile.pixelGlow.enabled = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    local auraDisabled = function() return not TUI.db.profile.pixelGlow.enabled end

    uf.auraLines = ACH:Range(
        "Lines", "Number of animated glow lines around the frame.", 3,
        { min = 1, max = 20, step = 1 }, nil,
        function() return TUI.db.profile.pixelGlow.lines end,
        function(_, value) TUI.db.profile.pixelGlow.lines = value end,
        auraDisabled
    )

    uf.auraSpeed = ACH:Range(
        "Speed", "Animation speed (cycles per second). Higher = faster.", 4,
        { min = 0.05, max = 1, step = 0.05, isPercent = false }, nil,
        function() return TUI.db.profile.pixelGlow.speed end,
        function(_, value) TUI.db.profile.pixelGlow.speed = value end,
        auraDisabled
    )

    uf.auraThickness = ACH:Range(
        "Thickness", "Pixel thickness of the glow lines.", 5,
        { min = 1, max = 5, step = 1 }, nil,
        function() return TUI.db.profile.pixelGlow.thickness end,
        function(_, value) TUI.db.profile.pixelGlow.thickness = value end,
        auraDisabled
    )

    root.nameplates = ACH:Group("Nameplates", nil, 4)

    root.nameplates.args.threat = ACH:Group("Threat", nil, 1)
    root.nameplates.args.threat.inline = true
    local npThreat = root.nameplates.args.threat.args

    npThreat.classificationOverThreat = ACH:Toggle(
        "Classification Over Threat",
        "When threat status is 'good' (tank securely tanking, DPS/healer no aggro), skip the flat threat color "
        .. "and show normal health colors (Classification, Class, Selection) instead. "
        .. "Bad/transitional threat still shows the standard warning color.",
        1, nil, nil, nil,
        function() return TUI.db.profile.nameplates.classificationOverThreat end,
        function(_, value)
            TUI.db.profile.nameplates.classificationOverThreat = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    npThreat.classificationOverThreat.customWidth = 250

    npThreat.classificationInstanceOnly = ACH:Toggle(
        "Instance Only",
        "Disable classification colors outside of instances. "
        .. "In the open world, nameplates fall back to selection and threat colors. "
        .. "Inside dungeons, raids, and scenarios, classification colors are used normally.",
        2, nil, nil, nil,
        function() return TUI.db.profile.nameplates.classificationInstanceOnly end,
        function(_, value)
            TUI.db.profile.nameplates.classificationInstanceOnly = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    root.nameplates.args.interrupt = ACH:Group("Interrupt Ready", nil, 2)
    root.nameplates.args.interrupt.inline = true
    local npInt = root.nameplates.args.interrupt.args

    npInt.interruptCredit = ACH:Description(
        "Special thanks to |CFF6559F1B|r|CFF7A4DEFl|r|CFF8845ECi|r|CFFA037E9n|r|CFFB32DE6k|r|CFFBC26E5i|r|CFFCB1EE3i|r for allowing the porting and updating of this module!",
        1, "medium"
    )

    npInt.interruptCastbarColors = ACH:Toggle(
        function() return TUI.db.profile.nameplates.interruptCastbarColors and "|cff00ff00Enable|r" or "Enable" end,
        "Color interruptible castbars based on your interrupt cooldown status:\n"
        .. "  \226\128\162 Ready \226\128\148 interrupt is off cooldown\n"
        .. "  \226\128\162 On CD \226\128\148 interrupt is on cooldown\n\n"
        .. "A marker line is drawn on the castbar showing when your interrupt becomes available.",
        2, nil, nil, nil,
        function() return TUI.db.profile.nameplates.interruptCastbarColors end,
        function(_, value)
            TUI.db.profile.nameplates.interruptCastbarColors = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    local intDisabled = function() return not TUI.db.profile.nameplates.interruptCastbarColors end

    npInt.castbarInterruptReady = ACH:Color(
        "Interrupt Ready", "Castbar color when your interrupt is off cooldown.",
        3, nil, nil,
        function()
            local c = TUI.db.profile.nameplates.castbarInterruptReady
            return c.r, c.g, c.b
        end,
        function(_, r, g, b)
            local c = TUI.db.profile.nameplates.castbarInterruptReady
            c.r, c.g, c.b = r, g, b
        end,
        intDisabled
    )

    npInt.castbarInterruptOnCD = ACH:Color(
        "On Cooldown", "Castbar color when your interrupt is on CD and won't be ready in time.",
        4, nil, nil,
        function()
            local c = TUI.db.profile.nameplates.castbarInterruptOnCD
            return c.r, c.g, c.b
        end,
        function(_, r, g, b)
            local c = TUI.db.profile.nameplates.castbarInterruptOnCD
            c.r, c.g, c.b = r, g, b
        end,
        intDisabled
    )

    npInt.castbarMarkerColor = ACH:Color(
        "Ready Marker",
        "Color of the vertical marker line showing when your interrupt becomes available during a cast.",
        5, nil, nil,
        function()
            local c = TUI.db.profile.nameplates.castbarMarkerColor
            return c.r, c.g, c.b
        end,
        function(_, r, g, b)
            local c = TUI.db.profile.nameplates.castbarMarkerColor
            c.r, c.g, c.b = r, g, b
        end,
        intDisabled
    )

    root.nameplates.args.highlight = ACH:Group("Hover Highlight", nil, 4)
    root.nameplates.args.highlight.inline = true
    local npHL = root.nameplates.args.highlight.args

    npHL.disableFriendlyHighlight = ACH:Toggle(
        "Disable Friendly Highlight",
        "Remove the mouseover highlight effect from friendly nameplates.",
        1, nil, nil, nil,
        function() return TUI.db.profile.nameplates.disableFriendlyHighlight end,
        function(_, value)
            TUI.db.profile.nameplates.disableFriendlyHighlight = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    npHL.disableFriendlyHighlight.customWidth = 250

    root.nameplates.args.focus = ACH:Group("Focus Indicator", nil, 5)
    root.nameplates.args.focus.inline = true
    local npFocus = root.nameplates.args.focus.args

    local focusDisabled = function() return not TUI.db.profile.nameplates.focusGlow.enabled end

    npFocus.focusGlowEnabled = ACH:Toggle(
        function() return TUI.db.profile.nameplates.focusGlow.enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Overlay a colored statusbar texture on the nameplate of your focus target.",
        1, nil, nil, nil,
        function() return TUI.db.profile.nameplates.focusGlow.enabled end,
        function(_, value)
            TUI.db.profile.nameplates.focusGlow.enabled = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    npFocus.focusGlowTexture = ACH:SharedMediaStatusbar(
        "Texture", "Statusbar texture for the focus overlay.", 2, nil,
        function() return TUI.db.profile.nameplates.focusGlow.texture end,
        function(_, value) TUI.db.profile.nameplates.focusGlow.texture = value end,
        focusDisabled
    )

    npFocus.focusGlowColor = ACH:Color(
        "Color", "Color and opacity of the focus overlay.", 3, true, nil,
        function()
            local c = TUI.db.profile.nameplates.focusGlow.color
            return c.r, c.g, c.b, c.a
        end,
        function(_, r, g, b, a)
            local c = TUI.db.profile.nameplates.focusGlow.color
            c.r, c.g, c.b, c.a = r, g, b, a
        end,
        focusDisabled
    )

    root.skins = ACH:Group("Skins", nil, 5)
    local skins = root.skins.args

    skins.addons = ACH:Group("AddOns", nil, 1)
    skins.addons.inline = true

    local skinDefs = {
        { key = "skinAuctionator", addon = "Auctionator", label = "Auctionator", order = 1 },
        { key = "skinBigWigs",     addon = "BigWigs",     label = "BigWigs",      order = 2 },
        { key = "skinBugSack",     addon = "BugSack",     label = "BugSack",      order = 3 },
        { key = "skinOPie",        addon = "OPie",        label = "OPie",         order = 4 },
        { key = "skinWarpDeplete", addon = "WarpDeplete",  label = "WarpDeplete",  order = 5 },
    }

    for _, def in ipairs(skinDefs) do
        skins.addons.args[def.key] = ACH:Toggle(def.label, nil, def.order, nil, nil, nil,
            function() return TUI.db.profile.addons[def.key] end,
            function(_, value)
                TUI.db.profile.addons[def.key] = value
                E:StaticPopup_Show('CONFIG_RL')
            end,
            function() return not E:IsAddOnEnabled(def.addon) end
        )
    end

    root.profiles = ACH:Group("Profiles", nil, 6)
    local prof = root.profiles.args

    prof.installAll = ACH:Group("Install All", nil, 1)
    prof.installAll.inline = true
    local allArgs = prof.installAll.args

    allArgs.desc = ACH:Description("Apply ElvUI, BigWigs, WarpDeplete, and LS: Toasts profiles in one click.", 1, "medium")
    allArgs.install = ACH:Execute("Install All Profiles", nil, 2, function()
        E:StaticPopup_Show('TUI_INSTALL_ALL')
    end)

    prof.individual = ACH:Group("Individual Profiles", nil, 2)
    prof.individual.inline = true
    local indArgs = prof.individual.args

    indArgs.installElvUI = ACH:Execute("ElvUI", "Creates a new profile — your current profile is not modified.", 1, function()
        E:StaticPopup_Show('TUI_INSTALL_ELVUI')
    end)

    local function addonDisabled(name)
        return function() return not E:IsAddOnEnabled(name) end
    end

    indArgs.installBigWigs = ACH:Execute("BigWigs", "Imports the TrenchyUI layout into BigWigs.", 2, function()
        TUI:ApplyBigWigsProfile(function(accepted)
            if accepted then
                E:Print(tuiName .. ": BigWigs profile applied.")
                E:StaticPopup_Show('CONFIG_RL')
            end
        end)
    end, nil, nil, nil, nil, nil, addonDisabled('BigWigs'))

    indArgs.installWarpDeplete = ACH:Execute("WarpDeplete", "Imports the TrenchyUI M+ timer layout.", 3, function()
        TUI:ApplyWarpDepleteProfile()
        E:Print(tuiName .. ": WarpDeplete profile applied.")
        E:StaticPopup_Show('CONFIG_RL')
    end, nil, nil, nil, nil, nil, addonDisabled('WarpDeplete'))

    indArgs.installLSToasts = ACH:Execute("LS: Toasts", "Imports the TrenchyUI toast layout.", 4, function()
        TUI:ApplyLSToastsProfile()
        E:Print(tuiName .. ": LS: Toasts profile applied.")
        E:StaticPopup_Show('CONFIG_RL')
    end, nil, nil, nil, nil, nil, addonDisabled('ls_Toasts'))

    indArgs.editMode = ACH:Execute("Edit Mode", "Shows the TrenchyUI Edit Mode layout string for you to import manually.", 5, function()
        TUI:ShowEditModeString()
    end, nil, nil, nil, nil, nil, function() return true end)

    root.info = ACH:Group("Information", nil, 7)
    local info = root.info.args

    info.about = ACH:Group("About", nil, 1)
    info.about.inline = true
    info.about.args.desc = ACH:Description(tuiName .. " is a minimalistic quality of life plugin for ElvUI.", 1, "medium")

    info.links = ACH:Group("Links", nil, 2)
    info.links.inline = true
    info.links.args.discord = ACH:Input("Discord", nil, 1, nil, 255, function() return 'https://discord.gg/24wXBTPD' end)
    info.links.args.discord.focusSelect = true

    info.credits = ACH:Group("Credits", nil, 3)
    info.credits.inline = true
    info.credits.args.desc = ACH:Description(
        E:TextGradient('Requiem', 0.13,0.37,0.13, 0.30,0.57,0.25) .. " — For entertaining me while making this...and he tested some stuff.\n\n"
        .. E:TextGradient('Menios', 0.64,0.19,0.79, 0.46,0.33,0.80) .. " — For the 10+ years of trolling and entertainment, and helping me kill 4+ Guilds during Legion.\n\n"
        .. E:TextGradient('Jiberish', 1.00,0.08,0.56, 1.00,0.41,0.71) .. " — For the encouragement to actually do this, and for the baller UI's.\n\n"
        .. "|cFFb8bb26Thurin|r — For bouncing all the ideas off of and balancing Jib's uncontrollable \"push the buttons\".\n\n"
        .. "|cffff2f3dThe ElvUI team|r ("
        .. E:TextGradient('Simpy but my name needs to be longer', 0.28,0.79,0.96, 0.50,0.77,0.38, 1.00,0.95,0.38, 0.96,0.53,0.37, 0.80,0.51,0.72, 0.34,0.80,0.96)
        .. ", |cFFAAD372Tsxy|r, |cfff48cbaRepooc|r) — For having a space to learn a ton about stuff I never knew about.\n\n"
        .. E:TextGradient('Eltreum', 0.50,0.70,1, 0.67,0.95,1) .. " — For the inspiration on some of these ideas and for the fantastic plugin, " .. E:TextGradient('Eltruism', 0.50,0.70,1, 0.67,0.95,1) .. ".\n\n"
        .. "|CFF6559F1B|r|CFF7A4DEFl|r|CFF8845ECi|r|CFFA037E9n|r|CFFB32DE6k|r|CFFBC26E5i|r|CFFCB1EE3i|r — For allowing me to use his module for the interrupt ready, and for always being receptive to new ideas with |CFF6559F1m|r|CFF7A4DEFM|r|CFF8845ECe|r|CFFA037E9d|r|CFFA435E8i|r|CFFB32DE6a|r|CFFBC26E5T|r|CFFCB1EE3a|r|CFFDD14E0g|r|CFFE609DFs|r.\n\n"
        .. "And, the " .. E:TextGradient('Igloo community', 0.89,0.99,1.00, 0.84,1.00,1.00, 0.45,0.66,0.67, 0.42,0.72,0.95, 0.15,0.49,0.64, 0.04,0.37,0.57) .. ", for the constant feedback on this simplistic UI...you guys are awesome!",
        1, "medium"
    )

    E.PopupDialogs.TUI_INSTALL_ALL = {
        text = "This will install the " .. tuiName .. " profile for ElvUI and all supported addons.\n\nYour current ElvUI profile will not be modified \226\128\148 a new one will be created.\n\nProceed?",
        button1 = "Install",
        button2 = "Cancel",
        OnAccept = function()
            TUI:ApplyElvUIProfile()
            if C_AddOns.IsAddOnLoaded('WarpDeplete') and TUI.ApplyWarpDepleteProfile then TUI:ApplyWarpDepleteProfile() end
            if C_AddOns.IsAddOnLoaded('ls_Toasts') and TUI.ApplyLSToastsProfile then TUI:ApplyLSToastsProfile() end

            if BigWigsAPI and TUI.ApplyBigWigsProfile then
                E.db.TrenchyUI._pendingBigWigsProfile = true
            end

            E.db.TrenchyUI._profileJustInstalled = 'all'
            ReloadUI()
        end,
        whileDead = 1,
        hideOnEscape = true,
    }

    E.PopupDialogs.TUI_INSTALL_ELVUI = {
        text = "This will install the |cff1784d1ElvUI|r profile only.\n\nA new profile called " .. tuiName .. " will be created \226\128\148 your current profile is not modified.\n\nProceed?",
        button1 = "Install",
        button2 = "Cancel",
        OnAccept = function()
            TUI:ApplyElvUIProfile()
            E.db.TrenchyUI._profileJustInstalled = 'elvui'
            ReloadUI()
        end,
        whileDead = 1,
        hideOnEscape = true,
    }
end
