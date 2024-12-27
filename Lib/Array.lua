---@class Array
local Array = {}

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return boolean
---@nodiscard
Array.Every = function(xs, f)
	for _i, v in ipairs(xs) do
		if not f(v) then return false end
	end
	return true
end

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return nil|A
---@nodiscard
Array.Find = function(xs, f)
	for _i, v in ipairs(xs) do
		if f(v) then
			return v
		end
	end
	return nil
end

---Since arrays are actually tables, Lua doesn't guarantee consistent indexing.
---@generic A
---@param xs A[]
---@return nil|A
---@nodiscard
Array.Head = function(xs)
	for _i, v in ipairs(xs) do
		return v
	end
	return nil
end

--- Alias to avoid Lua 5.1 deprecation warning; we need this syntax for 5.1 compatibility.
Array.Length = table.getn

---@generic A
---@generic B
---@param xs A[]
---@param f fun(x: A): B
---@return B[]
---@nodiscard
Array.Map = function(xs, f)
	local ys = {}
	for _i, v in ipairs(xs) do
		table.insert(ys, f(v))
	end
	return ys
end

---@generic A
---@generic B
---@param xs A[]
---@param f fun(x: A, i: integer): B
---@return B[]
---@nodiscard
Array.Mapi = function(xs, f)
	local ys = {}
	local i = 0
	for _i, v in ipairs(xs) do
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
---@nodiscard
Array.MapReduce = function(xs, f, reducer, identity)
	local zRef = identity
	for _i, v in ipairs(xs) do
		zRef = reducer(f(v), zRef)
	end
	return zRef
end

--- Map f >> Intercalate x >> Reduce (+)
--- <br>@link https://typeclasses.com/featured/intercalate
--- <br>@link https://en.wiktionary.org/wiki/intercalate
--- - ϴ(1) memory allocation
--- - ϴ(N) runtime complexity
---@generic A
---@param xs A[]
---@param f fun(a: A): number
---@param calate number
---@return number
---@nodiscard
Array.MapIntercalateSum = function(xs, f, calate)
	local id = 0
	if Array.Head(xs) == nil then
		return id
	else
		local add = function(a, b) return a + b end
		return Array.MapReduce(xs, f, add, id) + calate * (Array.Length(xs) - 1)
	end
end

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return boolean
---@nodiscard
Array.Some = function(xs, f)
	for _i, v in ipairs(xs) do
		if f(v) then return true end
	end
	return false
end

---@param xs number[]
---@return number
---@nodiscard
Array.Sum = function(xs)
	local total = 0
	for _i, v in ipairs(xs) do
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
---@nodiscard
Array.Reduce = function(xs, reducer, identity)
	local zRef = identity
	for _i, v in ipairs(xs) do
		zRef = reducer(v, zRef)
	end
	return zRef
end

---@generic A
---@generic B
---@param as A[]
---@param bs B[]
---@return [A,B][]
---@nodiscard
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
