local getIsBusy = function()
	for i=1,120 do
		if IsCurrentAction(i) then return true end
	end
	return false
end

-- Hooks get called even if spell didn't fire, but successful cast triggers GCD.
local lastGcdStart = 0
local checkGCD = function()
	local isTriggeredGcd, newStart = Quiver_Lib_Spellbook_CheckNewGCD(lastGcdStart)
	lastGcdStart = newStart
	return isTriggeredGcd
end

-- Castable shot event has 2 triggers:
-- 1. User starts casting Aimed Shot, Multi-Shot, or Trueshot
-- 2. User is already casting, but presses the spell again
-- It's up to the subscriber to differentiate.
local callbacksCastableShot = {}
local publishShotCastable = function(spellname)
	for _i, v in callbacksCastableShot do v(spellname) end
end
Quiver_Event_CastableShot_Subscribe = function(moduleId, callback)
	callbacksCastableShot[moduleId] = callback
end
Quiver_Event_CastableShot_Unsubscribe = function(moduleId)
	callbacksCastableShot[moduleId] = nil
end

local callbacksInstantShot = {}
local publishShotInstant = function(spellname)
	for _i, v in callbacksInstantShot do v(spellname) end
end
Quiver_Event_InstantShot_Subscribe = function(moduleId, callback)
	callbacksInstantShot[moduleId] = callback
end
Quiver_Event_InstantShot_Unsubscribe = function(moduleId)
	callbacksInstantShot[moduleId] = nil
end

local super = {
	CastSpell = CastSpell,
	CastSpellByName = CastSpellByName,
	UseAction = UseAction,
}
local handleCastByName = function(spellName)
	if Quiver_Lib_Spellbook_GetIsSpellCastableShot(spellName) then
		if getIsBusy() then publishShotCastable(spellName) end
	elseif Quiver_Lib_Spellbook_GetIsSpellInstantShot(spellName) then
		if checkGCD() then publishShotInstant(spellName) end
	end
end
CastSpell = function(spellIndex, spellbookTabNum)
	super.CastSpell(spellIndex, spellbookTabNum)
	local spellName, _rank = GetSpellName(spellIndex, spellbookTabNum)
	handleCastByName(spellName)
end
CastSpellByName = function(spellName, onSelf)
	super.CastSpellByName(spellName, onSelf)
	handleCastByName(spellName)
end
UseAction = function(slot, checkCursor, onSelf)
	super.UseAction(slot, checkCursor, onSelf)
	if not IsCurrentAction(slot) then return end
	-- Raw abilities return a nil action name. Macros, items, etc. don't.
	if GetActionText(slot) or not IsCurrentAction(slot) or GetActionText(slot) ~= nil then return end
	local actionTexture = GetActionTexture(slot)
	local spellName = Quiver_Lib_Spellbook_GetSpellNameFromTexture(actionTexture)
	handleCastByName(spellName)
end
