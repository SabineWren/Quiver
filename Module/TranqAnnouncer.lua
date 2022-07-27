local store = {}
local restoreState = function(savedVariables)
	store.MsgTranqHit = savedVariables.MsgTranqHit or QUIVER_T.DefaultTranqHit
	store.MsgTranqMiss = savedVariables.MsgTranqMiss or QUIVER_T.DefaultTranqMiss
end
local persistState = function() return store end

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

local frame = nil
local onEnable = function()
	if frame == nil then frame = CreateFrame("Frame", nil) end
	frame:SetScript("OnEvent", handleEvent)
	frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
end
local onDisable = function()
	frame:UnregisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
end

Quiver_Module_TranqAnnouncer_CreateMenuOptions = function(f)
	local editHit = Quiver_UI_EditBox({
		Parent = f, YOffset = -115,
		TooltipReset="Reset Hit Message to Default",
		Text = store.MsgTranqHit,
	})
	editHit:SetScript("OnTextChanged", function()
		store.MsgTranqHit = editHit:GetText()
	end)
	editHit.BtnReset:SetScript("OnClick", function()
		editHit:SetText(QUIVER_T.DefaultTranqHit)
	end)

	local editMiss = Quiver_UI_EditBox({
		Parent = f, YOffset = -150,
		TooltipReset="Reset Miss Message to Default",
		Text = store.MsgTranqMiss,
	})
	editMiss:SetScript("OnTextChanged", function()
		store.MsgTranqMiss = editMiss:GetText()
	end)
	editMiss.BtnReset:SetScript("OnClick", function()
		editMiss:SetText(QUIVER_T.DefaultTranqMiss)
	end)
	return editHit, editMiss
end

Quiver_Module_TranqAnnouncer = {
	Name = "TranqAnnouncer",
	OnRestoreSavedVariables = restoreState,
	OnPersistSavedVariables = persistState,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() return nil end,
	OnInterfaceUnlock = function() return nil end,
}

--[[
TODO Yaht tranq announce works differently.
Worth looking into instead of parsing combat log,
which requries localization.

function YaHT:SPELLCAST_FAILED()
	self.casting = nil
	self:CancelScheduledEvent("YaHT_TRANQ")
end

function YaHT:SPELLCAST_STOP()
	self.casting = nil
	self.castblock = nil
	if incTranq and YaHT.db.profile.channel and YaHT.db.profile.channel ~= "" then
		local msg = string.gsub(YaHT.db.profile.tranqmsg, "%%t", currTarget)
		self:Announce(msg)
	end
end

function YaHT:CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF()
	if string.find(arg1, L["YaHT_MISS"]) then
		self:Announce(YaHT.db.profile.tranqfailmsg)
	end
end

]]
