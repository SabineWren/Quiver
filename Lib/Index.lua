local Array = require "Lib/Array.lua"
local Color = require "Lib/Color.lua"
local M = require "Lib/Monoid.lua"
local Nil = require "Lib/Nil.lua"
local Sg = require "Lib/Semigroup.lua"

local Lib = {}
Lib.Array = Array
Lib.Color = Color
Lib.M = M
Lib.Nil = Nil
Lib.Sg = Sg

-- ************ Combinators ************
-- Reference library:
-- https://github.com/codereport/blackbird/blob/main/combinators.hpp

--- (>>), forward function composition, pipe without application
--- - See [Pipe](lua://Pipe)
---@generic A
---@generic B
---@generic C
---@generic D
-- Overloads type annotations don't work. See Pipe comments.
local flow = function(a1,a2,a3,a4,a5,a6,a7,a8,a9)
	return function(a)
		local out = a
		out = a1(out)
		out = a2(out)
		if a3 ~= nil then out = a3(out) end
		if a4 ~= nil then out = a4(out) end
		if a5 ~= nil then out = a5(out) end
		if a6 ~= nil then out = a6(out) end
		if a7 ~= nil then out = a7(out) end
		if a8 ~= nil then out = a8(out) end
		if a9 ~= nil then out = a9(out) end
		return out
	end
end

---@generic A
---@generic B
---@generic C
---@type fun(f: (fun(a: A): B), g: (fun(b: B): C)): fun(a: A): C
Lib.Flow = flow
---@generic A
---@generic B
---@generic C
---@generic D
---@type fun(f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): fun(a: A): D
Lib.Flow3 = flow

-- No support yet for generic overloads
-- https://github.com/LuaLS/lua-language-server/issues/723
--
-- I tried this using an external definition file instead of using @overload.
-- That partially works, as call sites select the correct overload.
-- However, generic type inference doesn't improve, and I don't think
-- a class can mix external type definitions with internal definitions.
---@generic A
---@generic B
---@generic C
--@type fun(a: A, f: (fun(a: A): B)): B
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C)): C
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): D
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D), i: (fun(d: D): E)): D
local pipe = function(a,a1,a2,a3,a4,a5,a6,a7,a8,a9)
	-- This looks ugly, but it's better than varargs:
	-- 1 - Varargs use different syntax between Lua 5.0/5.1
	-- 2 - Lua 5.0 varargs allocate an extra table
	-- pfUI also avoids varargs for the same reason
	-- https://github.com/shagu/pfUI/commit/e7dd8776f142a708e4677c1299ff89f1bcbe2baf
	local out = a1(a)
	if a2 ~= nil then out = a2(out) end
	if a3 ~= nil then out = a3(out) end
	if a4 ~= nil then out = a4(out) end
	if a5 ~= nil then out = a5(out) end
	if a6 ~= nil then out = a6(out) end
	if a7 ~= nil then out = a7(out) end
	if a8 ~= nil then out = a8(out) end
	if a9 ~= nil then out = a9(out) end
	return out
end

---@generic A
---@generic B
---@type fun(a: A, f: (fun(a: A): B)): B
Lib.Pipe = pipe
---@generic A
---@generic B
---@generic C
---@type fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C)): C
Lib.Pipe2 = pipe
---@generic A
---@generic B
---@generic C
---@generic D
---@type fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): D
Lib.Pipe3 = pipe

--- f(g(x), (y))
---@generic A
---@generic B
---@generic C
---@param f fun(x: B, y: B): C
---@param g fun(x: A): B
---@param x A
---@param y A
---@return C
---@nodiscard
Lib.Psi = function(f, g, x, y)
	return f(g(x), g(y))
end

-- ************ Operators / Ternary / Binary / Unary ************
---@param min number
---@param max number
---@return fun(x: number): number
---@nodiscard
Lib.Clamp = function(min, max)
	return function(x) return math.max(min, math.min(x, max)) end
end

return Lib
