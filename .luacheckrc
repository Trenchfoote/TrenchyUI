std = "lua51"
max_line_length = false
codes = true
globals = {
	"ElvUI_TrenchyUI",
	"ElvUI",
	"ElvDB",
	"LibStub",
	"PluginInstallFrame",
}
ignore = {
    "142/_.*", --Setting an undefined field of a global variable.
    "143/_.*", --Accessing an undefined field of a global variable.
}
self=false
