local Array = require "Lib/Array.lua"
local Color = require "Lib/Color.lua"
local Nil = require "Lib/Nil.lua"

local Lib = {}
Lib.Array = Array
Lib.Color = Color
Lib.Nil = Nil

-- ************ Combinators ************
-- Reference library:
-- https://github.com/codereport/blackbird/blob/main/combinators.hpp

--- (>>), forward function composition, pipe without application
---@generic A
---@generic B
---@generic C
---@generic D
--@type fun(f: (fun(a: A): B), g: (fun(b: B): C)): fun(a: A): C
---@type fun(f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): fun(a: A): D
Lib.Flow = function(...)
	local functions = arg
	return function(a)
		local out = a
		for _, fn in ipairs(functions) do
			out = fn(out)
		end
		return out
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
---@nodiscard
Lib.Psi = function(f, g, x, y)
	return f(g(x), g(y))
end

-- ************ Operators ************
-- ************ Binary / Unary ************
---@type fun(a: number, b: number): number
---@nodiscard
Lib.Add = function(a, b) return a + b end

---@type fun(a: number, b: number): number
---@nodiscard
Lib.Max = function(a, b) return math.max(a, b) end

return Lib
