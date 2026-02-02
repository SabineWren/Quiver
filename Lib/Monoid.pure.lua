local Monoid = {}

-- No support yet for generic classes
-- https://github.com/LuaLS/lua-language-server/issues/734
---@class Monoid<A>: Semigroup<A>
---@field Id number

---@type Monoid
Monoid.Add = {
	Id = 0,
	Op = function(a, b) return a + b end,
}

return Monoid
