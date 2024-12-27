local Nil = {}

---@generic A
---@generic B
---@param f fun(i: A): nil|B
---@return fun(a: nil|A): nil|B
---@nodiscard
Nil.Bind = function(f)
	---@generic A
	---@generic B
	---@param x nil|A
	---@return nil|B
	---@nodiscard
	return function(x)
		if x == nil then return x else return f(x) end
	end
end

--- Parses a sequence, short circuiting when a value succeeds
---@generic A
---@param n integer Range [1, n]
---@param f fun(i: integer): nil|A Parser
---@return nil|A
---@nodiscard
Nil.FirstBy = function(n, f)
	for i=1, n do
		local x = f(i)
		if x ~= nil then
			return x
		end
	end
	return nil
end

---@generic A
---@param x nil|A
---@param fallback A
---@return A
---@nodiscard
Nil.GetOr = function(x, fallback)
	if x == nil then return fallback else return x end
end

---@generic A
---@param f fun(i: A): nil
---@return fun(a: nil|A): nil
---@nodiscard
Nil.Iter = function(f)
	return function(x)
		if x ~= nil then f(x) end
	end
end

---@generic A
---@generic B
---@param f fun(i: A): B
---@return fun(a: nil|A): nil|B
---@nodiscard
Nil.Map = function(f)
	---@generic A
	---@generic B
	---@param x nil|A
	---@return nil|B
	---@nodiscard
	return function(x)
		if x == nil then return x else return f(x) end
	end
end

return Nil
