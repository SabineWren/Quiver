local MODULE_ID = "TranqAnnouncer"
local store = nil
local frame = nil
--local TODO_SPELL_NAME = QUIVER_T.Spellbook.Tranquilizing_Shot
local TODO_SPELL_NAME = QUIVER_T.Spellbook.Arcane_Shot

local ADDON_MESSAGE_CAST = "Tranq_Shot_Cast"

local handleEvent = function()
	-- For compatibility with other tranq addons, ignore the addon name (arg1).
	if event == "CHAT_MSG_ADDON" then
		local _, _, nameCaster = string.find(arg2, ADDON_MESSAGE_CAST..":(.*)")
		if nameCaster ~= nil then
			DEFAULT_CHAT_FRAME:AddMessage(nameCaster.." Fired Tranq Shot", 0.2, 1, 0.1)
		end
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		local isHit =
			string.find(arg1, QUIVER_T.CombatLog.Tranq.Cast)
		local isMiss =
			string.find(arg1, QUIVER_T.CombatLog.Tranq.Miss)
			or string.find(arg1, QUIVER_T.CombatLog.Tranq.Resist)
			or string.find(arg1, QUIVER_T.CombatLog.Tranq.Fail)
		if isHit then
			DEFAULT_CHAT_FRAME:AddMessage(arg1)
			Quiver_Lib_Print.Raid(store.MsgTranqHit)
		elseif isMiss then
			Quiver_Lib_Print.Raid(store.MsgTranqMiss)
		end
	end
end

local EVENTS = {
	"CHAT_MSG_ADDON",
	"CHAT_MSG_SPELL_SELF_DAMAGE",
}
local onEnable = function()
	if frame == nil then frame = CreateFrame("Frame", nil) end
	frame:SetScript("OnEvent", handleEvent)
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	Quiver_Event_Spellcast_Instant.Subscribe(MODULE_ID, function(spellName)
		if spellName == TODO_SPELL_NAME then
			DEFAULT_CHAT_FRAME:AddMessage("Fired Tranq Shot")
			local playerName = UnitName("player")
			SendAddonMessage("Quiver", ADDON_MESSAGE_CAST..":"..playerName, "Raid")
		end
	end)
	if Quiver_Store.IsLockedFrames then frame:Hide() else frame:Show() end
end
local onDisable = function()
	frame:Hide()
	Quiver_Event_Spellcast_Instant.Dispose(MODULE_ID)
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
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
		store.MsgTranqMiss = savedVariables.MsgTranqMiss or QUIVER_T.Tranq.DefaultMiss

		-- TODO move to migration and rename hit -> cast
		-- We notify on tranq cast instead of hit. To prevent a breaking
		-- release version, attempt changing contradictory text.
		if store.MsgTranqHit then
			local startPos, _ = string.find(string.lower(store.MsgTranqHit), "hit")
			if startPos then
				store.MsgTranqHit = QUIVER_T.Tranq.DefaultCast
				DEFAULT_CHAT_FRAME:AddMessage("Changed tranq message to new default")
			end
		else
			store.MsgTranqHit = QUIVER_T.Tranq.DefaultCast
		end
	end,
	OnSavedVariablesPersist = function() return store end,
}
