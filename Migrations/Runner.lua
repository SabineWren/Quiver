local parseVersion = function(text)
	local _, _, a, b, c = strfind(text, "(%d+)%.(%d+)%.(%d+)")
	return {
		Breaking = tonumber(a),
		Feature = tonumber(b),
		Fix = tonumber(c),
	}
end

local compareVersion = function(breaking, feature, fix, b)
	if
		breaking > b.Breaking
		or breaking == b.Breaking and feature > b.Feature
		or breaking == b.Breaking and feature == b.Feature and fix > b.Fix
	then
		return true
	else
		return false
	end
end

Quiver_Migrations_Runner = function()
	local vOldText = Quiver_Store.Version or "1.0.0"
	Quiver_Store.Version = GetAddOnMetadata("Quiver", "Version")

	local vOld = parseVersion(vOldText)
	local getIsNewer = function(a, b, c) return compareVersion(a, b, c, vOld) end

	if getIsNewer(2, 0, 0) then
		Quiver_Migrations_M001()
	end
end
