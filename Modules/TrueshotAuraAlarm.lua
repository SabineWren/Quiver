local store
local frame = nil

local handleEvent = function()
	if event == "SPELLS_CHANGED" and arg1 ~= "LeftButton" then
		if Quiver_Lib_Spellbook_GetIsSpellLearned("Trueshot Aura")
		then
			DEFAULT_CHAT_FRAME:AddMessage("yes!", 0.5, 0.8, 1)
		else
			DEFAULT_CHAT_FRAME:AddMessage("no!", 0.5, 0.8, 1)
		end
	end
end

local EVENTS = {
	"SPELLS_CHANGED",
}
local onEnable = function()
	if frame == nil then frame = CreateFrame("Frame", nil) end
	frame:SetScript("OnEvent", handleEvent)
	for _k, e in EVENTS do frame:RegisterEvent(e) end
end
local onDisable = function()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

Quiver_Module_TrueshotAuraAlarm = {
	Id = "TrueshotAuraAlarm",
	OnInitFrames = function(options) end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() return nil end,
	OnInterfaceUnlock = function() return nil end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
	end,
	OnSavedVariablesPersist = function() return store end,
}
