local parseVersion = function(text)
	local _, _, a, b, c = strfind(text, "(%d+)%.(%d+)%.(%d+)")
	return {
		Breaking = tonumber(a),
		Feature = tonumber(b),
		Fix = tonumber(c),
	}
end

Quiver_Migrations_Runner = function()
	local vOldText = Quiver_Store.Version or "0.0.0"
	local vOld = parseVersion(vOldText)
	Quiver_Store.Version = GetAddOnMetadata("Quiver", "Version")

	local getIsNewer = function(breaking, feature, fix)
		if breaking > vOld.Breaking then return true end
		if feature > vOld.Feature then return true end
		if fix > vOld.Fix then return true end
		return false
	end

	if getIsNewer(1, 0, 0) then
		Quiver_Migrations_M001()
	end
end
