return {
	-- ************ Binary / Unary ************
	---@type fun(a: number, b: number): number
	Add = function(a, b) return a + b end,

	-- ************ Comparison ************
	---@generic A
	---@type fun(a: A, b: A): boolean
	Lt = function(a, b) return a < b end,
	---@generic A
	---@type fun(a: A, b: A): boolean
	Le = function(a, b) return a <= b end,
	---@generic A
	---@type fun(a: A, b: A): boolean
	Eq = function(a, b) return a == b end,
	---@generic A
	---@type fun(a: A, b: A): boolean
	Ne = function(a, b) return a ~= b end,
	---@generic A
	---@type fun(a: A, b: A): boolean
	Ge = function(a, b) return a >= b end,
	---@generic A
	---@type fun(a: A, b: A): boolean
	Gt = function(a, b) return a > b end,
}
