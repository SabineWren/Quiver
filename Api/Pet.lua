local _NUM_PET_ACTION_SLOTS = 10

---@param actionName string
---@return nil|1|2|3|4|5|6|7|8|9|10
---@nodiscard
local findActionIndex = function(actionName)
	for i=1, _NUM_PET_ACTION_SLOTS do
		local name, subtext, tex, isToken, isActive, isAutoCastAllowed, isAutoCastEnabled = GetPetActionInfo(i)
		if (name == actionName) then
			return i
		end
	end
	return nil
end

---@param actionName string
---@return nil
local CastActionByName = function(actionName)
	local index = findActionIndex(actionName)
	if index ~= nil then CastPetAction(index) end
end

return {
	CastActionByName = CastActionByName,
}
