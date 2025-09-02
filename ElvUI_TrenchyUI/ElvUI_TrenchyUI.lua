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

-- Installer steps definition
local InstallerData = {
    Title = "|cffff2f3dTrenchyUI|r Installer",
    Name = "TrenchyUI",
    tutorialImage = nil,
    Pages = {
        [1] = function()
            return "Welcome to |cffff2f3dTrenchyUI|r!\n\nThis wizard will help you set up your UI profile and recommended settings.\n\nClick 'Continue' to begin."
        end,
        [2] = function()
            return "Step 1: General Settings\n\nThis will apply recommended general settings for TrenchyUI.\n\nClick 'Continue' to apply."
        end,
        [3] = function()
            return "Step 2: Layout\n\nThis will set up your layout, action bars, and unitframes.\n\nClick 'Continue' to apply."
        end,
        [4] = function()
            return "Step 3: Finish\n\nSetup is complete!\n\nClick 'Finish' to reload your UI."
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
}

local currentPage = 1

local function ShowInstaller()
    if not E.GUIFrame then
        E.GUIFrame = CreateFrame("Frame", "TrenchyUIInstallerFrame", UIParent, "BackdropTemplate")
        E.GUIFrame:SetSize(420, 240)
        E.GUIFrame:SetPoint("CENTER")
        E.GUIFrame:SetFrameStrata("DIALOG")
        E.GUIFrame:SetMovable(true)
        E.GUIFrame:EnableMouse(true)
        E.GUIFrame:RegisterForDrag("LeftButton")
        E.GUIFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        E.GUIFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        E.GUIFrame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
        E.GUIFrame:Hide()

        E.GUIFrame.Title = E.GUIFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        E.GUIFrame.Title:SetPoint("TOP", 0, -16)
        E.GUIFrame.Title:SetText(InstallerData.Title)

        E.GUIFrame.Step = E.GUIFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        E.GUIFrame.Step:SetPoint("TOP", 0, -40)

        E.GUIFrame.Text = E.GUIFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        E.GUIFrame.Text:SetPoint("TOP", 0, -70)
        E.GUIFrame.Text:SetWidth(380)
        E.GUIFrame.Text:SetJustifyH("LEFT")
        E.GUIFrame.Text:SetJustifyV("TOP")

        E.GUIFrame.Prev = CreateFrame("Button", nil, E.GUIFrame, "UIPanelButtonTemplate")
        E.GUIFrame.Prev:SetSize(80, 22)
        E.GUIFrame.Prev:SetPoint("BOTTOMLEFT", 20, 20)
        E.GUIFrame.Prev:SetText("Previous")
        E.GUIFrame.Prev:SetScript("OnClick", function()
            if currentPage > 1 then
                currentPage = currentPage - 1
                TrenchyUI:UpdateInstaller()
            end
        end)

        E.GUIFrame.Next = CreateFrame("Button", nil, E.GUIFrame, "UIPanelButtonTemplate")
        E.GUIFrame.Next:SetSize(80, 22)
        E.GUIFrame.Next:SetPoint("BOTTOMRIGHT", -20, 20)
        E.GUIFrame.Next:SetText("Continue")
        E.GUIFrame.Next:SetScript("OnClick", function()
            if InstallerData.StepActions[currentPage] then
                InstallerData.StepActions[currentPage]()
            end
            if currentPage < InstallerData.PagesAmount then
                currentPage = currentPage + 1
                TrenchyUI:UpdateInstaller()
            else
                E.GUIFrame:Hide()
            end
        end)
    end
    currentPage = 1
    TrenchyUI:UpdateInstaller()
    E.GUIFrame:Show()
end

function TrenchyUI:UpdateInstaller()
    E.GUIFrame.Step:SetText("Step " .. currentPage .. ": " .. (InstallerData.StepTitles[currentPage] or ""))
    E.GUIFrame.Text:SetText(InstallerData.Pages[currentPage]())
    E.GUIFrame.Prev:SetEnabled(currentPage > 1)
    if currentPage == InstallerData.PagesAmount then
        E.GUIFrame.Next:SetText("Finish")
    else
        E.GUIFrame.Next:SetText("Continue")
    end
end

function TrenchyUI:InsertOptions()
    E.Options.args.TrenchyUI = {
        order = 100,
        type = "group",
        name = "|cffff2f3dTrenchyUI|r",
        args = {
            install = {
                order = 1,
                type = "execute",
                name = "Run Installer",
                desc = "Launch the TrenchyUI setup wizard.",
                func = ShowInstaller,
            },
        },
    }
end

function TrenchyUI:Initialize()
    EP:RegisterPlugin(addonName, TrenchyUI.InsertOptions)
end

E:RegisterModule(TrenchyUI:GetName())
