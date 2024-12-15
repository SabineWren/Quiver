-- Reference library:
-- https://github.com/codereport/blackbird/blob/main/combinators.hpp
local Array = require "Shiver/Lib/Array.lua"

---@class Lib
local Lib = {}

Lib.Array = Array

-- ************ Combinators ************
--- (>>), forward function composition, pipe without application
---@generic A
---@generic B
---@generic C
---@param f fun(a: A): B
---@param g fun(y: B): C
---@return fun(x: A): C
Lib.Flow = function(f, g)
	return function(a)
		return g(f(a))
	end
end

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
---@type fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C)): C
--@type fun(a: A, f: (fun(a: A): B)): B
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C)): C
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): D
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D), i: (fun(d: D): E)): D
Lib.Pipe = function(a, ...)
	local out = a
	for _, fn in ipairs(arg) do
		out = fn(out)
	end
	return out
end

--- f(g(x), (y))
---@generic A
---@generic B
---@generic C
---@type fun(f: (fun(x: B, y: B): C), g: (fun(x: A): B), x: A, y: A): C
Lib.Psi = function(f, g, x, y)
	return f(g(x), g(y))
end

-- ************ Operators ************
-- ************ Binary / Unary ************
---@type fun(a: number, b: number): number
Lib.Add = function(a, b) return a + b end

---@type fun(a: number, b: number): number
Lib.Max = function(a, b) return math.max(a, b) end

-- ************ Comparison ************
---@generic A
---@type fun(a: A, b: A): boolean
Lib.Lt = function(a, b) return a < b end
---@generic A
---@type fun(a: A, b: A): boolean
Lib.Le = function(a, b) return a <= b end
---@generic A
---@type fun(a: A, b: A): boolean
Lib.Eq = function(a, b) return a == b end
---@generic A
---@type fun(a: A, b: A): boolean
Lib.Ne = function(a, b) return a ~= b end
---@generic A
---@type fun(a: A, b: A): boolean
Lib.Ge = function(a, b) return a >= b end
---@generic A
---@type fun(a: A, b: A): boolean
Lib.Gt = function(a, b) return a > b end

-- ************ Logic ************
---@type fun(a: boolean, b: boolean): boolean
Lib.And = function(a, b) return a and b end

---@type fun(a: boolean, b: boolean): boolean
Lib.Or = function(a, b) return a or b end-- ************ Comparison ************
---@generic A
---@type fun(a: A, b: A): boolean

return Lib
