local init = function()
	_, cl = UnitClass("player")
	if cl ~= "HUNTER" then
		Quiver_Lib_Print.Danger("Quiver is for hunters")
		return
	end

	local frameMainMenu = Quiver_UI_MainMenu_Create()
	SLASH_QUIVER1 = "/qq"
	SLASH_QUIVER2 = "/quiver"
	SlashCmdList["QUIVER"] = function(_args, _box) frameMainMenu:Show() end

	if Quiver_Store.ModuleEnabled.AutoShotCastbar
	then Quiver_Module_AutoShotCastbar_Enable()
	end

	if Quiver_Store.ModuleEnabled.RangeIndicator
	then Quiver_Module_RangeIndicator_Enable()
	end

	if Quiver_Store.ModuleEnabled.TranqAnnouncer
	then Quiver_Module_TranqAnnouncer_Enable()
	end
end

local frame = CreateFrame("Frame", nil)
-- Need spellbook, action bars, and chat window to load first, so ignoring ADDON_LOADED
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:SetScript("OnEvent", function()
	if event == "PLAYER_LOGIN" then
		if Quiver_Store == nil then DEFAULT_CHAT_FRAME:AddMessage("Type /Quiver to show the config dialog.") end
		Quiver_Store_Restore()
		init()
	elseif event == "PLAYER_LOGOUT" then
		Quiver_Store_Persist()
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		Quiver_Lib_ActionBar_ValidateCache(arg1)
	end
end)
