local Spell = require "Shiver/API/Spell.lua"

---@param texture string
---@return nil|ActionBarSlot
---@nodiscard
local FindByTexture = function(texture)
	if texture == nil then
		DEFAULT_CHAT_FRAME:AddMessage("Invalid nil argument to Action.FindByTexture")
		return nil
	end

	for i=0,120 do
		if HasAction(i) and GetActionTexture(i) == texture then
			return i
		end
	end
	return nil
end

---@param name string
---@return nil|ActionBarSlot
---@nodiscard
local FindBySpellName = function(name)
	local index = Spell.FindSpellIndex(name)
	if index ~= nil then
		local texture = GetSpellTexture(index, BOOKTYPE_SPELL)
		if texture ~= nil then
			return FindByTexture(texture)
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
	FindByTexture = FindByTexture,
	PredSomeActionBusy = PredSomeActionBusy,
}
