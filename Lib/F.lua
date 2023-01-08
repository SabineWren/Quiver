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

local Some = function(xs, f)
	for _k, v in xs do
		if f(v) then return true end
	end
	return false
end

Quiver_Lib_F = {
	Every=Every,
	Find=Find,
	Some=Some,
}
