local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local EDIT_MODE_STRING = [[2 50 0 0 0 7 7 UIParent 0.0 42.0 -1 ##$$%/&&'%)$+$,$ 0 1 1 7 7 UIParent 0.0 45.0 -1 ##$$%/&('%(#,$ 0 2 0 1 1 UIParent 0.0 -1162.0 -1 ##$$%/&&'%(#,$ 0 3 0 0 0 UIParent 611.9 -1122.0 -1 ##$%%/&&'%(#,$ 0 4 0 0 0 UIParent 1298.5 -1122.0 -1 ##$%%/&&'%(#,$ 0 5 0 6 0 ChatFrame1 -48.0 64.0 -1 #$$$%/&&'%(#,$ 0 6 1 1 4 UIParent 0.0 -50.0 -1 ##$$%/&('%(#,$ 0 7 1 1 4 UIParent 0.0 -100.0 -1 ##$$%/&('%(#,$ 0 10 0 1 1 UIParent 0.0 -1102.0 -1 ##$$&%'% 0 11 0 7 7 UIParent 0.0 78.0 -1 ##$$&&'%,# 0 12 0 4 4 UIParent -227.0 -500.0 -1 ##$$&('% 1 -1 0 0 0 UIParent 1152.0 -1242.4 -1 #%$#%# 2 -1 1 2 2 UIParent 0.0 0.0 -1 ##$#%( 3 0 0 0 0 UIParent 881.0 -897.0 -1 $#3# 3 1 0 0 0 UIParent 1449.0 -897.0 -1 %#3# 3 2 0 0 2 TargetFrame -31.5 -3.5 -1 %#&#3# 3 3 0 0 0 UIParent 710.8 -540.4 -1 '#(#)#-k.)/#1#3.5%627-7$ 3 4 0 0 0 UIParent 2.0 -602.0 -1 ,$-5.-/#0#1#2(5%6-7-7$ 3 5 0 2 2 UIParent -4.3 -535.0 -1 &$*#3# 3 6 1 5 5 UIParent 0.0 0.0 -1 -#.#/#4&5#6(7-7$ 3 7 1 4 4 UIParent 0.0 0.0 -1 3# 4 -1 0 7 7 UIParent 3.0 1362.0 -1 # 5 -1 0 7 7 UIParent -267.0 602.0 -1 # 6 0 1 2 2 UIParent -255.0 -10.0 -1 ##$#%#&.(()( 6 1 1 2 2 UIParent -270.0 -155.0 -1 ##$#%#'+(()(-$ 6 2 0 4 4 UIParent -138.0 -55.5 -1 ##$#%$&((()(+#,-,$ 7 -1 0 1 1 UIParent -779.7 -2.0 -1 # 8 -1 0 7 7 UIParent -832.7 34.0 -1 #'$#%%&# 9 -1 1 7 7 UIParent 0.0 45.0 -1 # 10 -1 1 0 0 UIParent 16.0 -116.0 -1 # 11 -1 0 5 5 UIParent -60.5 -260.0 -1 # 12 -1 0 1 1 UIParent 1142.0 -302.0 -1 #3$#%# 13 -1 0 5 5 UIParent -19.0 -245.8 -1 ##$#%)&- 14 -1 0 8 6 DamageMeter -4.0 0.0 -1 ##$#%( 15 0 0 7 7 UIParent 0.0 1182.0 -1 # 15 1 1 7 7 StatusTrackingBarManager 0.0 17.0 -1 # 16 -1 0 8 6 MinimapCluster -4.0 0.0 -1 #( 17 -1 1 1 1 UIParent 0.0 -100.0 -1 ## 18 -1 0 2 2 UIParent -292.3 -0.0 -1 #- 19 -1 1 7 7 UIParent 0.0 0.0 -1 ## 20 0 0 4 4 UIParent 0.0 100.0 -1 ##$7%$&(')(-($)#+$,$-# 20 1 0 4 4 UIParent 0.0 -0.0 -1 ##$)%$&)')(-($)#+$,$-# 20 2 0 4 4 UIParent 0.0 200.0 -1 ##$$%$&(')(-($)#+#,$-# 20 3 0 0 0 UIParent 1163.2 -1132.0 -1 #$$$%#&('+(-($)#*$+$,$-#.^ 21 -1 1 7 7 UIParent -410.0 380.0 -1 ##$# 22 0 0 0 0 UIParent 1419.5 -665.5 -1 #$$$%$&('((#)U*$+#,$-$.$/U0% 22 1 0 1 1 UIParent 0.0 -442.0 -1 &('()U*#+$ 22 2 0 4 4 UIParent 0.0 296.0 -1 &('()U*#+$ 22 3 0 4 4 UIParent 0.0 220.0 -1 &('()U*#+$ 23 -1 0 8 8 UIParent -396.0 1.0 -1 ##$#%$&S&$'_(#)U+#,$--.*/-/$]]

function TUI:ShowEditModeString()
	if EDIT_MODE_STRING == '' then
		E:Print('|cffff2f3dTrenchyUI|r: No Edit Mode layout string configured yet.')
		return
	end

	E:StaticPopup_Show('TUI_EDITMODE_STRING')
end

E.PopupDialogs.TUI_EDITMODE_STRING = {
	text = 'Copy the string below, then open\n|cff1784d1Edit Mode > Import > Paste|r.',
	button1 = 'Close',
	hasEditBox = 1,
	editBoxWidth = 350,
	OnShow = function(self)
		self.editBox:SetText(EDIT_MODE_STRING)
		self.editBox:HighlightText()
		self.editBox:SetFocus()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	whileDead = 1,
	hideOnEscape = true,
}
