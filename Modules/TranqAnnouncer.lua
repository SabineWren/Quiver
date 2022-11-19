local store = {}
local frame = nil

local handleEvent = function()
	local isHit =
		string.find(arg1, QUIVER_T.CombatLog.Tranq.Cast)
	local isMiss =
		string.find(arg1, QUIVER_T.CombatLog.Tranq.Miss)
		or string.find(arg1, QUIVER_T.CombatLog.Tranq.Resist)
		or string.find(arg1, QUIVER_T.CombatLog.Tranq.Fail)
	if isHit then
		Quiver_Lib_Print.Raid(store.MsgTranqHit)
	elseif isMiss then
		Quiver_Lib_Print.Raid(store.MsgTranqMiss)
	end
end

local EVENT = "CHAT_MSG_SPELL_SELF_DAMAGE"
local onEnable = function()
	if frame == nil then frame = CreateFrame("Frame", nil) end
	frame:SetScript("OnEvent", handleEvent)
	frame:RegisterEvent(EVENT)
end
local onDisable = function()
	frame:UnregisterEvent(EVENT)
end

Quiver_Module_TranqAnnouncer_CreateMenuOptions = function(parent, gap)
	local f = CreateFrame("Frame", nil, parent)

	local editHit = Quiver_Component_EditBox(f,
		{ TooltipReset="Reset Hit Message to Default" })
	editHit:SetText(store.MsgTranqHit)
	editHit:SetScript("OnTextChanged",
		function() store.MsgTranqHit = editHit:GetText() end)
	editHit.BtnReset:SetScript("OnClick",
		function() editHit:SetText(QUIVER_T.DefaultTranqHit) end)

	local editMiss = Quiver_Component_EditBox(f,
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
	OnInitFrames = function(savedFrameMeta) end,
	OnRestoreSavedVariables = function(savedVariables)
		store.MsgTranqHit = savedVariables.MsgTranqHit or QUIVER_T.DefaultTranqHit
		store.MsgTranqMiss = savedVariables.MsgTranqMiss or QUIVER_T.DefaultTranqMiss
	end,
	OnPersistSavedVariables = function() return store end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() return nil end,
	OnInterfaceUnlock = function() return nil end,
}
