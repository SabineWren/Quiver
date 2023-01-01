local MODULE_ID = "TranqAnnouncer"
local store = nil
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

Quiver_Module_TranqAnnouncer = {
	Id = MODULE_ID,
	Name = QUIVER_T.ModuleName[MODULE_ID],
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() return nil end,
	OnInterfaceUnlock = function() return nil end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.MsgTranqHit = savedVariables.MsgTranqHit or QUIVER_T.Tranq.DefaultHit
		store.MsgTranqMiss = savedVariables.MsgTranqMiss or QUIVER_T.Tranq.DefaultMiss
	end,
	OnSavedVariablesPersist = function() return store end,
}
