local init = function()
	_, cl = UnitClass("player")
	if cl ~= "HUNTER" then return Quiver_Lib_Print.Danger("Quiver is for hunters") end

	local frameMainMenu = Quiver_MainMenu_Create()
	SLASH_QUIVER1 = "/qq"
	SLASH_QUIVER2 = "/quiver"
	SlashCmdList["QUIVER"] = function(_args, _box) frameMainMenu:Show() end

	local me = Quiver_Store.ModuleEnabled
	if me.AutoShotCastbar then Quiver_Module_AutoShotCastbar_Enable() end
	if me.RangeIndicator then Quiver_Module_RangeIndicator_Enable() end
	if me.TranqAnnouncer then Quiver_Module_TranqAnnouncer_Enable() end
end

-- Ignore ADDON_LOADED so spellbook, action bars, and chat window load first.
local frame = CreateFrame("Frame", nil)
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function()
	if event == "PLAYER_LOGIN" then
		if Quiver_Store == nil then DEFAULT_CHAT_FRAME:AddMessage("Type /Quiver or /qq to show the config dialog.") end
		Quiver_Store_Restore()
		init()
	elseif event == "PLAYER_LOGOUT" then
		Quiver_Store_Persist()
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		Quiver_Lib_ActionBar_ValidateCache(arg1)
	end
end)
