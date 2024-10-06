local Action = require "Shiver/API/Action.lua"
local Spell = require "Shiver/API/Spell.lua"
local DB_SPELL = require "Shiver/Data/Spell.lua"
local Print = require "Util/Print.lua"

local log = function(text)
	if Quiver_Store.DebugLevel == "Verbose" then
		DEFAULT_CHAT_FRAME:AddMessage(text)
	end
end

-- Hooks get called even if spell didn't fire, but successful cast triggers GCD.
local lastGcdStart = 0
local checkGCD = function()
	local isTriggeredGcd, newStart = Spell.CheckNewGCD(lastGcdStart)
	lastGcdStart = newStart
	return isTriggeredGcd
end

-- Castable shot event has 2 triggers:
-- 1. User starts casting Aimed Shot, Multi-Shot, or Trueshot
-- 2. User is already casting, but presses the spell again
-- It's up to the subscriber to differentiate.
---@type (fun(x: string, y: string): nil)[]
local callbacksCastableShot = {}

---@param nameEnglish string
---@param nameLocalized string
local publishShotCastable = function(nameEnglish, nameLocalized)
	for _i, v in pairs(callbacksCastableShot) do
		v(nameEnglish, nameLocalized)
	end
end

local CastableShot = {
	---@param moduleId string
	---@param callback fun(x: string, y: string): nil
	Subscribe = function(moduleId, callback)
		callbacksCastableShot[moduleId] = callback
	end,
	---@param moduleId string
	Dispose = function(moduleId)
		callbacksCastableShot[moduleId] = nil
	end,
}

---@type (fun(x: string, y: string): nil)[]
local callbacksInstant = {}

---@param nameEnglish string
---@param nameLocalized string
local publishInstant = function(nameEnglish, nameLocalized)
	for _i, v in pairs(callbacksInstant) do v(nameEnglish, nameLocalized) end
end
local Instant = {
	---@param moduleId string
	---@param callback fun(x: string, y: string): nil
	Subscribe = function(moduleId, callback)
		callbacksInstant[moduleId] = callback
	end,
	---@param moduleId string
	Dispose = function(moduleId)
		callbacksInstant[moduleId] = nil
	end,
}

local super = {
	CastSpell = CastSpell,
	CastSpellByName = CastSpellByName,
	UseAction = UseAction,
}

local println = Print.PrefixedF("spellcast")

---@param nameLocalized string
---@param isCurrentAction nil|1
local handleCastByName = function(nameLocalized, isCurrentAction)
	local nameEnglish = Quiver.L.SpellReverse[nameLocalized]
	if nameEnglish == nil then
		log("Localized spellname not found: "..nameLocalized)
		-- TODO implement zhCN
		nameEnglish = nameLocalized
	else
		local meta = DB_SPELL[nameEnglish]
		local isCastable = not Spell.PredInstant(meta)

		-- We pre-hook the cast, so confirm we actually cast it before triggering callbacks.
		-- If it's castable, then check we're casting it, else check that we triggered GCD.
		if isCastable then
			if isCurrentAction then
				publishShotCastable(nameEnglish, nameLocalized)
			elseif Action.FindBySpellName(nameLocalized) == nil then
				println.Warning(nameLocalized .. " not on action bars, so can't track cast.")
			end
		elseif checkGCD() then
			publishInstant(nameEnglish, nameLocalized)
		end
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
		handleCastByName(name, Action.PredSomeActionBusy())
	end
end

-- Some spells trigger this one time when spamming, others multiple
---@param name string
---@param isSelf? boolean
---@return nil
CastSpellByName = function(name, isSelf)
	super.CastSpellByName(name, isSelf)
	log("Cast by name... " .. name)
	handleCastByName(name, Action.PredSomeActionBusy())
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
