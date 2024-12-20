---@class Array
local Array = {}

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return boolean
Array.Every = function(xs, f)
	for _k, v in ipairs(xs) do
		if not f(v) then return false end
	end
	return true
end

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return nil|A
Array.Find = function(xs, f)
	for _k, v in ipairs(xs) do
		if f(v) then
			return v
		end
	end
	return nil
end

---ϴ(N)
---@generic A
---@param xs A[]
---@return integer
Array.Length = function(xs)
	local l = 0
	for _k, _v in ipairs(xs) do l = l + 1 end
	return l
end

---@generic A
---@generic B
---@param xs A[]
---@param f fun(x: A): B
---@return B[]
Array.Map = function(xs, f)
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
Array.Mapi = function(xs, f)
	local ys = {}
	local i = 0
	for _k, v in ipairs(xs) do
		table.insert(ys, f(v, i))
		i = i + 1
	end
	return ys
end

--- ϴ(1) memory allocation<br>
--- ϴ(N) runtime complexity
---@generic A
---@generic B
---@param xs A[]
---@param f fun(a: A): B
---@param reducer fun(b1: B, b2: B): B
---@param identity B
---@return B
Array.MapReduce = function(xs, f, reducer, identity)
	local zRef = identity
	for _k, x in ipairs(xs) do
		zRef = reducer(f(x), zRef)
	end
	return zRef
end

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return boolean
Array.Some = function(xs, f)
	for _k, v in ipairs(xs) do
		if f(v) then return true end
	end
	return false
end

---@param xs number[]
---@return number
Array.Sum = function(xs)
	local total = 0
	for _k, v in ipairs(xs) do
		total = total + v
	end
	return total
end

--- ϴ(1) memory allocation<br>
--- ϴ(N) runtime complexity
---@generic A
---@generic B
---@param xs A[]
---@param reducer fun(b1: B, b2: B): B
---@param identity B
---@return B
Array.Reduce = function(xs, reducer, identity)
	local zRef = identity
	for _k, x in ipairs(xs) do
		zRef = reducer(x, zRef)
	end
	return zRef
end

---@generic A
---@generic B
---@param as A[]
---@param bs B[]
---@return [A,B][]
Array.Zip2 = function(as, bs)
	local zipped = {}
	local l1, l2 = Array.Length(as), Array.Length(bs)
	if l1 ~= l2 then
		DEFAULT_CHAT_FRAME:AddMessage("Warning -- Called Zip2 on arrays of unequal length.", 1.0, 0.5, 0)
		DEFAULT_CHAT_FRAME:AddMessage(l1 .. " <> " .. l2, 1.0, 0, 0)
	end
	local length = math.min(l1, l2)
	for i=1, length do
		zipped[i] = { as[i], bs[i] }
	end
	return zipped
end

return Array
