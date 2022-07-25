_G = _G or getfenv()
_G.Quiver_Modules = {
	Quiver_Module_AutoShotCastbar,
	Quiver_Module_RangeIndicator,
	Quiver_Module_TranqAnnouncer,
}

local savedVariablesRestore = function()
	Quiver_Store_Restore()
	for _k, v in _G.Quiver_Modules do
		Quiver_Store.ModuleEnabled[v.Name] = Quiver_Store.ModuleEnabled[v.Name] ~= false
		Quiver_Store.ModuleStore[v.Name] = Quiver_Store.ModuleStore[v.Name] or {}
		Quiver_Store.FrameMeta[v.Name] = Quiver_Store.FrameMeta[v.Name] or {}
		v.OnRestoreSavedVariables(Quiver_Store.ModuleStore[v.Name])
	end
end
local savedVariablesPersist = function()
	for _k, v in _G.Quiver_Modules do
		Quiver_Store.ModuleStore[v.Name] = v.OnPersistSavedVariables()
		Quiver_Store.FrameMeta[v] = Quiver_Store.FrameMeta[v] or {}
	end
end

local init = function()
	_, cl = UnitClass("player")
	--if cl ~= "HUNTER" then return Quiver_Lib_Print.Danger("Quiver is for hunters") end

	local frameMainMenu = Quiver_MainMenu_Create()
	SLASH_QUIVER1 = "/qq"
	SLASH_QUIVER2 = "/quiver"
	SlashCmdList["QUIVER"] = function(_args, _box) frameMainMenu:Show() end

	local me = Quiver_Store.ModuleEnabled
	if me.AutoShotCastbar then Quiver_Module_AutoShotCastbar.OnEnable() end
	if me.RangeIndicator then Quiver_Module_RangeIndicator.OnEnable() end
	if me.TranqAnnouncer then Quiver_Module_TranqAnnouncer.OnEnable() end
end

-- Ignore ADDON_LOADED so spellbook, action bars, and chat window load first.
local frame = CreateFrame("Frame", nil)
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function()
	if event == "PLAYER_LOGIN" then
		if Quiver_Store == nil then DEFAULT_CHAT_FRAME:AddMessage("Type /Quiver or /qq to show the config dialog.") end
		savedVariablesRestore()
		init()
	elseif event == "PLAYER_LOGOUT" then
		savedVariablesPersist()
	elseif event == "ACTIONBAR_SLOT_CHANGED" then
		Quiver_Lib_ActionBar_ValidateCache(arg1)
	end
end)
