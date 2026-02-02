local Semigroup = {}

-- No support yet for generic classes
-- https://github.com/LuaLS/lua-language-server/issues/734
---@class Semigroup<A>
---@field Op fun(a: number, b: number): number

---@type Semigroup
Semigroup.Max = {
	Op = math.max,
}

---@type Semigroup
Semigroup.Min = {
	Op = math.min,
}

return Semigroup
