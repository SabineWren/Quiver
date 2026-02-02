---@class (exact) Version
---@field private __index? Version
---@field private breaking integer
---@field private feature integer
---@field private fix integer
---@field Text string
local Version = {}

---@param text string
---@return Version
---@nodiscard
function Version:ParseThrows(text)
	if text == nil then
		error("Nil version string")
	elseif string.len(text) == 0 then
		error("Empty version string")
	else
		local _, _, a, b, c = string.find(text, "(%d+)%.(%d+)%.(%d+)")
		local x, y, z = tonumber(a), tonumber(b), tonumber(c)
		if x == nil or y == nil or z == nil then
			error("Invalid version string: "..text)
		else
			---@type Version
			local r = {
				breaking = x,
				feature = y,
				fix = z,
				Text = text,
			}
			setmetatable(r, self)
			self.__index = self
			return r
		end
	end
end

---@param text string
---@return boolean
---@nodiscard
function Version:PredNewer(text)
	local a = self
	local b = Version:ParseThrows(text)
	return b.breaking > a.breaking
	or b.breaking == a.breaking and b.feature > a.feature
	or b.breaking == a.breaking and b.feature == a.feature and b.fix > a.fix
end

return Version
