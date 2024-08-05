local ActionBar = require "Lib/ActionBar.lua"
local Print = require "Lib/Print.lua"
local Spellbook = require "Lib/Spellbook.lua"

local getIsBusy = function()
	for i=1,120 do
		if IsCurrentAction(i) then return true end
	end
	return false
end

-- Hooks get called even if spell didn't fire, but successful cast triggers GCD.
local lastGcdStart = 0
local checkGCD = function()
	local isTriggeredGcd, newStart = Spellbook.CheckNewGCD(lastGcdStart)
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
local CastableShot = {
	Subscribe = function(moduleId, callback)
		callbacksCastableShot[moduleId] = callback
	end,
	Dispose = function(moduleId)
		callbacksCastableShot[moduleId] = nil
	end,
}

local callbacksInstant = {}
local publishInstant = function(spellname)
	for _i, v in callbacksInstant do v(spellname) end
end
local Instant = {
	Subscribe = function(moduleId, callback)
		callbacksInstant[moduleId] = callback
	end,
	Dispose = function(moduleId)
		callbacksInstant[moduleId] = nil
	end,
}

local super = {
	CastSpell = CastSpell,
	CastSpellByName = CastSpellByName,
	UseAction = UseAction,
}
local findSlot = ActionBar.FindSlot("spellcast")
local println = Print.PrefixedF("spellcast")
local handleCastByName = function(spellName)
	for shotName, _ in Spellbook.HUNTER_CASTABLE_SHOTS do
		local knowsShot = Spellbook.GetIsSpellLearned(shotName)
		-- Bad code... findSlot has side effect of printing when a spell isn't on bars
		if knowsShot and findSlot(shotName) == 0 and spellName == shotName then
			println.Warning(spellName .. " not on action bars, so can't track cast.")
		end
	end

	-- We pre-hook the cast, so confirm we actually cast it before triggering callbacks.
	-- If it's castable, then check we're casting it, else check that we triggered GCD.
	if Spellbook.GetIsSpellCastableShot(spellName) then
		if getIsBusy() then publishShotCastable(spellName) end
	elseif checkGCD() then
		publishInstant(spellName)
	end
end
CastSpell = function(spellIndex, spellbookTabNum)
	super.CastSpell(spellIndex, spellbookTabNum)
	local spellName, _rank = GetSpellName(spellIndex, spellbookTabNum)
	handleCastByName(spellName)
end
-- Some spells trigger this one time when spamming, others multiple
CastSpellByName = function(spellName, onSelf)
	super.CastSpellByName(spellName, onSelf)
	handleCastByName(spellName)
end
-- Trigger multiple times when spamming the cast
UseAction = function(slot, checkCursor, onSelf)
	super.UseAction(slot, checkCursor, onSelf)
	if not IsCurrentAction(slot) then return end
	-- Raw abilities return a nil action name. Macros, items, etc. don't.
	if GetActionText(slot) or not IsCurrentAction(slot) or GetActionText(slot) ~= nil then return end
	local actionTexture = GetActionTexture(slot)
	local spellName = Spellbook.GetSpellNameFromTexture(actionTexture)
	handleCastByName(spellName)
end

return {
	CastableShot = CastableShot,
	Instant = Instant,
}
