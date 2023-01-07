local parseVersion = function(text)
	local _, _, a, b, c = string.find(text, "(%d+)%.(%d+)%.(%d+)")
	return {
		Breaking = tonumber(a),
		Feature = tonumber(b),
		Fix = tonumber(c),
	}
end

Quiver_Lib_Version_GetIsNewer = function(ta, tb)
	local a = parseVersion(ta)
	local b = parseVersion(tb)
	return b.Breaking > a.Breaking
	or b.Breaking == a.Breaking and b.Feature > a.Feature
	or b.Breaking == a.Breaking and b.Feature == a.Feature and b.Fix > a.Fix
end
