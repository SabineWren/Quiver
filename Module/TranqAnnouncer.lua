local handleEvent = function()
	local isHit =
		string.find(arg1, QUIVER_T.CombatLog.TranqCast)
	local isMiss =
		string.find(arg1, QUIVER_T.CombatLog.TranqMiss)
		or string.find(arg1, QUIVER_T.CombatLog.TranqResist)
		or string.find(arg1, QUIVER_T.CombatLog.TranqFail)
	if isHit then
		Quiver_Lib_Print.Raid(Quiver_Store.MsgTranqHit)
	elseif isMiss then
		Quiver_Lib_Print.Raid(Quiver_Store.MsgTranqMiss)
	end
end

local frame = nil
Quiver_Module_TranqAnnouncer_Enable = function()
	if frame == nil then frame = CreateFrame("Frame", nil) end
	frame:SetScript("OnEvent", handleEvent)
	frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
end

Quiver_Module_TranqAnnouncer_Disable = function()
	frame:UnregisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
end
