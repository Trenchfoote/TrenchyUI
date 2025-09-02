--[[
    TrenchyUI: ElvUI Profile Installer Wizard
    Author: Trenchfoote
    This plugin provides a multi-step installer for TrenchyUI profiles and settings.
]]


local E, L, V, P, G = unpack(ElvUI)
local TrenchyUI = E:NewModule('TrenchyUI', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0')
local EP = LibStub("LibElvUIPlugin-1.0")
local addonName = ...

local INSTALL_VERSION = "1.0"


local function InstallerTable()
    return {
        Title = "|cffff2f3dTrenchyUI|r",
        Name = "TrenchyUI",
        Version = INSTALL_VERSION,
    -- Splash image disabled (no custom tutorial image)
        Pages = {
            [1] = function()
                return "Welcome to |cffff2f3dTrenchyUI|r!\n\nThis wizard will help you set up your UI profile and recommended settings.\n\nClick 'Next' to begin."
            end,
            [2] = function()
                return "Step 1: General Settings\n\nThis will apply recommended general settings for TrenchyUI.\n\nClick 'Apply' to set these options."
            end,
            [3] = function()
                return "Step 2: Layout\n\nThis will set up your layout, action bars, and unitframes.\n\nClick 'Apply' to set these options."
            end,
            [4] = function()
                return "Setup is complete!\n\nClick 'Finish' to reload your UI."
            end,
        },
        StepTitles = {
            [1] = "Welcome",
            [2] = "General",
            [3] = "Layout",
            [4] = "Finish",
        },
        StepActions = {
            [2] = function()
                -- Apply general settings here (example)
                E.db.general.loginmessage = false
                E.db.general.valuecolor = { r = 1, g = 0.18, b = 0.24 }
            end,
            [3] = function()
                -- Apply layout settings here (example)
                E.db.actionbar.bar1.buttons = 12
                E.db.unitframe.fontSize = 14
            end,
            [4] = function()
                E:StaticPopup_Show("PRIVATE_RL")
            end,
        },
        PagesAmount = 4,
        StepTitlesColor = {1, 0.18, 0.24},
    }
end

local function RunInstaller()
    local data = InstallerTable()
    local PI = E and E.GetModule and E:GetModule('PluginInstaller', true)

    if PI and type(PI.Queue) == 'function' then
        -- Queue our installer package and try to show the plugin installer
        PI:Queue(data)
        if type(PI.Show) == 'function' then
            PI:Show()
        elseif type(PI.Toggle) == 'function' then
            PI:Toggle()
        elseif type(PI.Start) == 'function' then
            PI:Start()
        end
    else
        -- Fallback to ElvUI core installer API
        E:Install(data)
    end

    -- Branding: adjust title/version after the frame exists
    if E.InstallFrame then
        E.InstallFrame.Title:SetText("|cffff2f3dTrenchyUI|r")
        if E.InstallFrame.Version then
            E.InstallFrame.Version:SetText("v"..INSTALL_VERSION)
        end
    end
end

-- Slash commands removed per request; config can be opened via /ec.

function TrenchyUI:InsertOptions()
    if not (E and E.Options and E.Options.args) then return end
    local groupDef = {
        order = 100,
        type = "group",
        name = "|cffff2f3dTrenchyUI|r",
        args = {
            install = {
                order = 1,
                type = "execute",
                name = "Run Installer",
                desc = "Launch the TrenchyUI setup wizard.",
                func = RunInstaller,
            },
        },
    }
    if E.Options.args.plugins and E.Options.args.plugins.args then
        E.Options.args.plugins.args.TrenchyUI = groupDef
    else
        E.Options.args.TrenchyUI = groupDef
    end
end

function TrenchyUI:Initialize()
    EP:RegisterPlugin(addonName, TrenchyUI.InsertOptions)
    -- If options UI is already initialized, insert our options now as well
    if E and E.Options and E.Options.args then
        TrenchyUI:InsertOptions()
    end
end

E:RegisterModule(TrenchyUI:GetName())
