local store
local frame = nil

local aura = (function()
	local knowsAura, isActive, lastUpdate, timeLeft =
		false, false, 1800, 0
	local updateState = function()
		knowsAura = Quiver_Lib_Spellbook_GetIsSpellLearned("Trueshot Aura")
		lastUpdate, timeLeft = 0, 0
		for i=1,24 do
			-- Indexes from 1
			local texture = UnitBuff("Player", i)
			if texture == QUIVER.Icon.Trueshot then
				-- Indexes from 0
				timeLeft = GetPlayerBuffTimeLeft(i - 1)
			end
		end
	end
	return {
		Print = function()
			if isActive
			then
				DEFAULT_CHAT_FRAME:AddMessage("Active " .. timeLeft)
			else
				DEFAULT_CHAT_FRAME:AddMessage("Not Active")
			end
		end,
		Update = function()
			updateState()
		end,
	}
end)()

local handleEvent = function()
	if event == "SPELLS_CHANGED" and arg1 ~= "LeftButton" then
		aura.Update()
	elseif event == "PLAYER_AURAS_CHANGED" then
		aura.Update()
		aura.Print()
	end
end

local EVENTS = {
	"PLAYER_AURAS_CHANGED",
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
