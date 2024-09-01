local Spell = require "Shiver/API/Spell.lua"

---@param name string
---@return nil|ActionBarSlot
---@nodiscard
local FindBySpellName = function(name)
	local index = Spell.FindSpellIndex(name)
	if index ~= nil then
		local texture = GetSpellTexture(index, BOOKTYPE_SPELL)
		for i=0,120 do
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
	for i=1,120 do
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
