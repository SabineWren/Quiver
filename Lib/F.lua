local Every = function(xs, f)
	for _k, v in xs do
		if not f(v) then return false end
	end
	return true
end

local Find = function(xs, f)
	for _k, v in xs do
		if f(v) then return v end
	end
	return nil
end

local Length = function(xs)
	local l = 0
	for _k, _v in xs do l = l + 1 end
	return l
end

local Map = function(xs, f)
	local ys = {}
	local i = 0
	for _k, v in xs do
		table.insert(ys, f(v, i))
		i = i + 1
	end
	return ys
end

-- Assumes positive numbers
local Max = function(xs)
	local max = 0
	for _k, w in xs do
		if w > max then max = w end
	end
	return max
end

local Some = function(xs, f)
	for _k, v in xs do
		if f(v) then return true end
	end
	return false
end

local Sum = function(xs)
	local total = 0
	for _k, v in xs do
		total = total + v
	end
	return total
end

Quiver_Lib_F = {
	Every=Every,
	Find=Find,
	Length=Length,
	Map=Map,
	Max=Max,
	Some=Some,
	Sum=Sum,
}
