local parseVersion = function(text)
	local _, _, a, b, c = strfind(text, "(%d+)%.(%d+)%.(%d+)")
	return {
		Breaking = tonumber(a),
		Feature = tonumber(b),
		Fix = tonumber(c),
	}
end

local getIsNewerFactory = function(vOldText)
	local v = parseVersion(vOldText)
	return function(breaking, feature, fix)
		return breaking > v.Breaking
		or breaking == v.Breaking and feature > v.Feature
		or breaking == v.Breaking and feature == v.Feature and fix > v.Fix
	end
end

local runMigrations = function(vOldText)
	local getIsNewer = getIsNewerFactory(vOldText)

	if getIsNewer(2, 0, 0) then
		Quiver_Migrations_M001()
	end
end

Quiver_Migrations_UpdateVersion = function()
	-- toc version (after 1.0.0) persists to saved variables. A clean
	-- install has no saved variables, which distinguishes a 1.0.0 install.
	if Quiver_Store == nil
	then Quiver_Store = {}
	else runMigrations(Quiver_Store.Version or "1.0.0")
	end
	Quiver_Store.Version = GetAddOnMetadata("Quiver", "Version")
end
