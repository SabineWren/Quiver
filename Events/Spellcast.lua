local ActionBar = require "Lib/ActionBar.lua"
local Print = require "Lib/Print.lua"
local Spellbook = require "Lib/Spellbook.lua"
local Spell = require "Shiver/API/Spell.lua"

local log = function(text)
	if Quiver_Store.DebugLevel == "Verbose" then
		DEFAULT_CHAT_FRAME:AddMessage(text)
	end
end

--- Matches return type of IsCurrentAction
---@return nil|1 isBusy
local predSomeActionBusy = function()
	for i=1,120 do
		if IsCurrentAction(i) then
			return 1
		end
	end
	return nil
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

---@param name string
---@param isCurrentAction nil|1
local handleCastByName = function(name, isCurrentAction)
	for shotName, _ in Spellbook.HUNTER_CASTABLE_SHOTS do
		local knowsShot = Spellbook.GetIsSpellLearned(shotName)
		-- Bad code... findSlot has side effect of printing when a spell isn't on bars
		if knowsShot and findSlot(shotName) == 0 and name == shotName then
			println.Warning(name .. " not on action bars, so can't track cast.")
		end
	end

	log(name .. " Is current action... " .. (isCurrentAction and "yes" or "no"))

	-- We pre-hook the cast, so confirm we actually cast it before triggering callbacks.
	-- If it's castable, then check we're casting it, else check that we triggered GCD.
	if Spellbook.GetIsSpellCastableShot(name) then
		if isCurrentAction then publishShotCastable(name) end
	elseif checkGCD() then
		publishInstant(name)
	end
end

---@param spellIndex number
---@param bookType BookType
---@return nil
CastSpell = function(spellIndex, bookType)
	super.CastSpell(spellIndex, bookType)
	local name, _rank = GetSpellName(spellIndex, bookType)
	if name ~= nil then
		log("Cast as spell... " .. name)
		handleCastByName(name, predSomeActionBusy())
	end
end

-- Some spells trigger this one time when spamming, others multiple
---@param name string
---@param isSelf? boolean
---@return nil
CastSpellByName = function(name, isSelf)
	super.CastSpellByName(name, isSelf)
	log("Cast by name... " .. name)
	handleCastByName(name, predSomeActionBusy())
end

-- Triggers multiple times when spamming the cast
---@param slot ActionBarSlot
---@param checkCursor? nil|0|1
---@param onSelf? nil|0|1
---@return nil
UseAction = function(slot, checkCursor, onSelf)
	super.UseAction(slot, checkCursor, onSelf)
	local texturePath = GetActionTexture(slot)
	if texturePath ~= nil then
		-- If we don't find a name, it means action is a macro with a custom texture.
		-- The macro will call CastSpellByName, which triggers a different hook.
		--
		-- If the macro uses the same texture, then both these hooks are called!
		-- We *could* check macro text etc. to disambiguate, but it's okay
		-- to duplicate the spell event since it won't change CD or start time.
		local name, index = Spell.FindSpellByTexture(texturePath)
		if name ~= nil and index ~= nil then
			log("Cast as Action... " .. name)
			handleCastByName(name, IsCurrentAction(slot))
		else
			log("Skip Action... ")
		end
	end
end

return {
	CastableShot = CastableShot,
	Instant = Instant,
}
