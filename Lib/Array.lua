local M = require "Lib/Monoid.lua"

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

--- - ϴ(1) memory allocation
--- - ϴ(N) runtime complexity
---@generic A
---@generic B
---@param xs A[]
---@param f fun(a: A): B
---@param folder fun(b1: B, b2: B): B
---@param initial B
---@return B
---@nodiscard
Array.MapFoldL = function(xs, f, folder, initial)
	local zRef = initial
	for _i, v in ipairs(xs) do
		zRef = folder(f(v), zRef)
	end
	return zRef
end

--- Constrained to [Monoid](lua://Monoid)\<number\>
--- - ϴ(1) memory allocation
--- - ϴ(N) runtime complexity
---@generic A
---@param xs A[]
---@param f fun(a: A): number
---@param monoid Monoid
---@return number
---@nodiscard
Array.MapReduce = function(xs, f, monoid)
	return Array.MapFoldL(xs, f, monoid.Op, monoid.Id)
end

--- Constrained to [Semigroup](lua://Semigroup)\<number\>
--- - ϴ(1) memory allocation
--- - ϴ(N) runtime complexity
---@generic A
---@param xs A[]
---@param f fun(a: A): number
---@param semigroup Semigroup
---@param identity number
---@return number
---@nodiscard
Array.MapSeduce = function(xs, f, semigroup, identity)
	return Array.MapFoldL(xs, f, semigroup.Op, identity)
end

-- TODO Intercalate
--- <br>@link https://typeclasses.com/featured/intercalate
--- <br>@link https://en.wiktionary.org/wiki/intercalate
--@generic A
--@param calate A[]
--@param xss A[][]
--@return A[]
--@nodiscard

--- Map f >> Intersperse x >> Reduce (+)
--- <br>@link https://typeclasses.com/featured/intercalate
--- <br>@link https://en.wiktionary.org/wiki/intercalate
--- - ϴ(1) memory allocation
--- - ϴ(N) runtime complexity
---@generic A
---@param xs A[]
---@param f fun(a: A): number
---@param gap number
---@return number
---@nodiscard
Array.MapIntersperseSum = function(xs, f, gap)
	local numJoins = math.max(0, Array.Length(xs) - 1)
	return gap * numJoins + Array.MapReduce(xs, f, M.Add)
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

--- - ϴ(1) memory allocation
--- - ϴ(N) runtime complexity
---@generic A
---@generic B
---@param xs A[]
---@param folder fun(b1: B, b2: B): B
---@param identity B
---@return B
---@nodiscard
Array.FoldL = function(xs, folder, identity)
	local zRef = identity
	for _i, v in ipairs(xs) do
		zRef = folder(v, zRef)
	end
	return zRef
end

--- Constrained to [Monoid](lua://Monoid)\<number\>
--- - ϴ(1) memory allocation
--- - ϴ(N) runtime complexity
---@param xs number[]
---@param monoid Monoid
---@return number
---@nodiscard
Array.Reduce = function(xs, monoid)
	return Array.FoldL(xs, monoid.Op, monoid.Id)
end

--- Constrained to [Semigroup](lua://Semigroup)\<number\>
--- - ϴ(1) memory allocation
--- - ϴ(N) runtime complexity
---@param xs number[]
---@param semigroup Semigroup
---@param identity number
---@return number
---@nodiscard
Array.Seduce = function(xs, semigroup, identity)
	return Array.FoldL(xs, semigroup.Op, identity)
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
