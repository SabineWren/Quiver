local store = {}
local frame = nil

local handleEvent = function()
	local isHit =
		string.find(arg1, QUIVER_T.CombatLog.TranqCast)
	local isMiss =
		string.find(arg1, QUIVER_T.CombatLog.TranqMiss)
		or string.find(arg1, QUIVER_T.CombatLog.TranqResist)
		or string.find(arg1, QUIVER_T.CombatLog.TranqFail)
	if isHit then
		Quiver_Lib_Print.Raid(store.MsgTranqHit)
	elseif isMiss then
		Quiver_Lib_Print.Raid(store.MsgTranqMiss)
	end
end

local onEnable = function()
	if frame == nil then frame = CreateFrame("Frame", nil) end
	frame:SetScript("OnEvent", handleEvent)
	frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
end
local onDisable = function()
	frame:UnregisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
end

Quiver_Module_TranqAnnouncer_CreateMenuOptions = function(parent, gap)
	local f = CreateFrame("Frame", nil, parent)

	local editHit = Quiver_Components_EditBox(f,
		{ TooltipReset="Reset Hit Message to Default" })
	editHit:SetText(store.MsgTranqHit)
	editHit:SetScript("OnTextChanged",
		function() store.MsgTranqHit = editHit:GetText() end)
	editHit.BtnReset:SetScript("OnClick",
		function() editHit:SetText(QUIVER_T.DefaultTranqHit) end)

	local editMiss = Quiver_Components_EditBox(f,
		{ TooltipReset="Reset Miss Message to Default" })
	editMiss:SetText(store.MsgTranqMiss)
	editMiss:SetScript("OnTextChanged",
		function() store.MsgTranqMiss = editMiss:GetText() end)
	editMiss.BtnReset:SetScript("OnClick",
		function() editMiss:SetText(QUIVER_T.DefaultTranqMiss) end)

	local height1 = editHit:GetHeight()
	editHit:SetPoint("Top", f, "Top", 0, 0)
	editMiss:SetPoint("Top", f, "Top", 0, -1 * (height1 + gap))

	f:SetWidth(parent:GetWidth())
	f:SetHeight(height1 + gap + editMiss:GetHeight())
	return f
end

Quiver_Module_TranqAnnouncer = {
	Id = "TranqAnnouncer",
	OnRestoreSavedVariables = function(savedVariables, savedFrameMeta)
		store.MsgTranqHit = savedVariables.MsgTranqHit or QUIVER_T.DefaultTranqHit
		store.MsgTranqMiss = savedVariables.MsgTranqMiss or QUIVER_T.DefaultTranqMiss
	end,
	OnPersistSavedVariables = function() return store end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() return nil end,
	OnInterfaceUnlock = function() return nil end,
}
