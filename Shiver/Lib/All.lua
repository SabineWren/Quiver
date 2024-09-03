-- Reference library:
-- https://github.com/codereport/blackbird/blob/main/combinators.hpp
local Array = require "Shiver/Lib/Array.lua"
local Op = require "Shiver/Lib/Operator.lua"

-- ************ Combinators ************
--- (>>), forward function composition
---@generic A
---@generic B
---@generic C
---@param f fun(a: A): B
---@param g fun(y: B): C
---@return fun(x: A): C
local Forward = function(f, g)
	return function(a)
		return g(f(a))
	end
end

-- No support yet for generic overloads
-- https://github.com/LuaLS/lua-language-server/issues/723
---@generic A
---@generic B
---@generic C
--@generic D
--@generic E
---@type fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C)): C
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): D
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D), i: (fun(d: D): E)): D
local Pipe = function(a, ...)
	local out = a
	for _, fn in ipairs(arg) do
		out = fn(out)
	end
	return out
end

-- No support yet for generic overloads
-- https://github.com/LuaLS/lua-language-server/issues/723
---@generic A
---@generic B
---@generic C
---@generic D
---@type fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): D
local Pipe3 = Pipe

-- No support yet for generic overloads
-- https://github.com/LuaLS/lua-language-server/issues/723
---@generic A
---@generic B
---@generic C
---@generic D
---@generic E
---@type fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D), i: (fun(d: D): E)): D
local Pipe4 = Pipe

return {
	Array = Array,
	-- Combinators
	Fw = Forward,
	Pipe = Pipe,
	Pipe3 = Pipe3,
	Pipe4 = Pipe4,
	-- Binary / Unary
	Add = Op.Add,
	-- Comparison
	Lt = Op.Lt,
	Le = Op.Le,
	Eq = Op.Eq,
	Ne = Op.Ne,
	Ge = Op.Ge,
	Gt = Op.Gt,
}
