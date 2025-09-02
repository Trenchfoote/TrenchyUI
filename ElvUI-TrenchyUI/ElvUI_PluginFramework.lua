--[[
	This is a framework showing how to create a plugin for ElvUI.
	It creates some default options and inserts a GUI table to the ElvUI Config.
	If you have questions then ask in the Tukui lua section: https://www.tukui.org/forum/viewforum.php?f=10
]]

local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local MyPlugin = E:NewModule('MyPluginName', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0'); --Create a plugin within ElvUI and adopt AceHook-3.0, AceEvent-3.0 and AceTimer-3.0. We can make use of these later.
local EP = LibStub("LibElvUIPlugin-1.0") --We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local addonName, addonTable = ... --See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2

--Default options
P["MyPlugin"] = {
	["SomeToggleOption"] = true,
	["SomeRangeOption"] = 5,
}

--Function we can call when a setting changes.
--In this case it just checks if "SomeToggleOption" is enabled. If it is it prints the value of "SomeRangeOption", otherwise it tells you that "SomeToggleOption" is disabled.
function MyPlugin:Update()
	local enabled = E.db.MyPlugin.SomeToggleOption
	local range = E.db.MyPlugin.SomeRangeOption

	if enabled then
		print(range)
	else
		print("SomeToggleOption is disabled")
	end
end

--This function inserts our GUI table into the ElvUI Config. You can read about AceConfig here: http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
function MyPlugin:InsertOptions()
	E.Options.args.MyPlugin = {
		order = 100,
		type = "group",
		name = "MyPlugin",
		args = {
			SomeToggleOption = {
				order = 1,
				type = "toggle",
				name = "MyToggle",
				get = function(info)
					return E.db.MyPlugin.SomeToggleOption
				end,
				set = function(info, value)
					E.db.MyPlugin.SomeToggleOption = value
					MyPlugin:Update() --We changed a setting, call our Update function
				end,
			},
			SomeRangeOption = {
				order = 1,
				type = "range",
				name = "MyRange",
				min = 0,
				max = 10,
				step = 1,
				get = function(info)
					return E.db.MyPlugin.SomeRangeOption
				end,
				set = function(info, value)
					E.db.MyPlugin.SomeRangeOption = value
					MyPlugin:Update() --We changed a setting, call our Update function
				end,
			},
		},
	}
end

function MyPlugin:Initialize()
	--Register plugin so options are properly inserted when config is loaded
	EP:RegisterPlugin(addonName, MyPlugin.InsertOptions)
end

E:RegisterModule(MyPlugin:GetName()) --Register the module with ElvUI. ElvUI will now call MyPlugin:Initialize() when ElvUI is ready to load our plugin.
