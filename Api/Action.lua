local Spell = require "Api/Spell.lua"

local _MAX_NUM_ACTION_SLOTS = 120

---@param name string
---@return nil|ActionBarSlot
---@nodiscard
local FindBySpellName = function(name)
	local index = Spell.FindSpellIndex(name)
	local texture = index ~= nil and GetSpellTexture(index, BOOKTYPE_SPELL) or nil
	if texture ~= nil then
		for i=0,_MAX_NUM_ACTION_SLOTS do
			if HasAction(i) then
				local isSpell = ActionHasRange(i) or GetActionText(i) == nil
				local isSameTexture = GetActionTexture(i) == texture
				if isSpell and isSameTexture then
					return i
				end
			end
		end
	end
	return nil
end

--- Matches return type of IsCurrentAction
---@return nil|1 isBusy
---@nodiscard
local PredSomeActionBusy = function()
	for i=1,_MAX_NUM_ACTION_SLOTS do
		if IsCurrentAction(i) then
			return 1
		end
	end
	return nil
end

return {
	FindBySpellName = FindBySpellName,
	PredSomeActionBusy = PredSomeActionBusy,
}
