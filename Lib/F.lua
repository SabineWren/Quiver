---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return boolean
local Every = function(xs, f)
	for _k, v in ipairs(xs) do
		if not f(v) then return false end
	end
	return true
end

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return nil | A
local Find = function(xs, f)
	for _k, v in ipairs(xs) do
		if f(v) then
			return v
		end
	end
	return nil
end

---@generic A
---@param xs A[]
---@return integer
local Length = function(xs)
	local l = 0
	for _k, _v in ipairs(xs) do l = l + 1 end
	return l
end

---@generic A
---@generic B
---@param xs A[]
---@param f fun(x: A): B
---@return B[]
local Map = function(xs, f)
	local ys = {}
	for _k, v in ipairs(xs) do
		table.insert(ys, f(v))
	end
	return ys
end

---@generic A
---@generic B
---@param xs A[]
---@param f fun(x: A, i: integer): B
---@return B[]
local Mapi = function(xs, f)
	local ys = {}
	local i = 0
	for _k, v in ipairs(xs) do
		table.insert(ys, f(v, i))
		i = i + 1
	end
	return ys
end

---@param identity number
---@return fun(xs: number[]): number
local Max = function(identity)
	return function(xs)
		local max = identity
		for _k, w in ipairs(xs) do
			if w > max then max = w end
		end
		return max
	end
end

local Max0 = Max(0)

---@param xs number[]
---@return number
local Min = function(xs)
	local min = math.huge
	for _k, w in ipairs(xs) do
		if w < min then min = w end
	end
	return min
end

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return boolean
local Some = function(xs, f)
	for _k, v in ipairs(xs) do
		if f(v) then return true end
	end
	return false
end

---@param xs number[]
---@return number
local Sum = function(xs)
	local total = 0
	for _k, v in ipairs(xs) do
		total = total + v
	end
	return total
end

---@generic A
---@generic B
---@param as A[]
---@param bs B[]
---@return [A,B][]
local Zip2 = function(as, bs)
	local zipped = {}
	local length = Min({ Length(as), Length(bs) })
	for i=1, length do
		zipped[i] = { as[i], bs[i] }
	end
	return zipped
end

Quiver_Lib_F = {
	Every=Every,
	Find=Find,
	Length=Length,
	Map=Map,
	Mapi=Mapi,
	Max=Max,
	Max0=Max0,
	Min=Min,
	Some=Some,
	Sum=Sum,
	Zip2
}
