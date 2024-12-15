---@alias Rgb [number, number, number]

---@class (exact) Color
---@field private __index? Color
---@field private cache Rgb
---@field private default Rgb
local Color = {}

---@param store Rgb
---@return Color
function Color:Lift(store)
	local default = { store[1], store[2], store[3] }
	---@type Color
	local o = { cache=store, default=default }
	setmetatable(o, self)
	self.__index = self
	return o
end

---@param store Rgb
---@param default Rgb
---@return Color
function Color:LiftReset(store, default)
	---@type Color
	local o = { cache=store, default=default }
	setmetatable(o, self)
	self.__index = self
	return o
end

function Color:Reset()
	self.cache[1] = self.default[1]
	self.cache[2] = self.default[2]
	self.cache[3] = self.default[3]
end

---@return number, number, number
---@nodiscard
function Color:Rgb()
	local c = self.cache
	return c[1], c[2], c[3]
end

---@return [number, number, number]
---@nodiscard
function Color:RgbArray()
	local c = self.cache
	return { c[1], c[2], c[3] }
end

function Color:R() return self.cache[1] end
function Color:G() return self.cache[2] end
function Color:B() return self.cache[3] end

---@param r number 0 to 1
---@param g number 0 to 1
---@param b number 0 to 1
function Color:SetRgb(r, g, b)
	self.cache[1] = r
	self.cache[2] = g
	self.cache[3] = b
end

return Color
