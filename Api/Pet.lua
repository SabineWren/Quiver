local L = require "Lib/Index.lua"
local _NUM_PET_ACTION_SLOTS = 10

---@param actionName string
---@return nil
local CastActionByName = function(actionName)
	local parseIndex = function(i)
		local name, _, _, _, _, _, _ = GetPetActionInfo(i)
		return name == actionName and i or nil
	end
	L.Pipe(
		L.Nil.FirstBy(_NUM_PET_ACTION_SLOTS, parseIndex),
		L.Nil.Iter(CastPetAction)
	)
end

return {
	CastActionByName = CastActionByName,
}
