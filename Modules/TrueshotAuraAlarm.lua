local store
local frame = nil
local UPDATE_DELAY = 5

local aura = (function()
	local knowsAura, isActive, lastUpdate, timeLeft = false, false, 1800, 0
	local updateState = function()
		knowsAura = Quiver_Lib_Spellbook_GetIsSpellLearned("Trueshot Aura")
		lastUpdate, timeLeft, isActive = 0, 0, false
		-- This seems to check debuffs as well (tested with deserter)
		-- Turtle supports 24 buffs and 24 debuffs, so up to 48 slots
		for i=0,47 do
			local texture = GetPlayerBuffTexture(i)
			if texture == QUIVER.Icon.Trueshot then
				isActive = true
				timeLeft = GetPlayerBuffTimeLeft(i)
				return
			end
		end
	end
	return {
		Print = function()
			if isActive and timeLeft < 5 * 60
			then
				DEFAULT_CHAT_FRAME:AddMessage("Low time " .. timeLeft)
			elseif not isActive then
				DEFAULT_CHAT_FRAME:AddMessage("Not Active")
			end
		end,
		Update = updateState,
		ShouldUpdate = function(elapsed)
			lastUpdate = lastUpdate + elapsed
			return knowsAura and lastUpdate > UPDATE_DELAY
		end
	}
end)()

local handleUpdate = function()
	if aura.ShouldUpdate(arg1) then
		aura.Update()
		aura.Print()
	end
end

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
	"SPELLS_CHANGED",-- Open or click thru spellbook, learn/unlearn spell
}
local onEnable = function()
	if frame == nil then frame = CreateFrame("Frame", nil) end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	frame:Show()
	if Quiver_Store.IsLockedFrames then frame:SetAlpha(0) else frame:SetAlpha(1) end
end
local onDisable = function()
	frame:Hide()
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
