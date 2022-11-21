Quiver_Migrations_Runner = function()
	local meta = GetAddOnMetadata("Quiver", "Version")
	local _, _, a, b, c = strfind(tostring(meta), "(%d+)%.(%d+)%.(%d+)")
	local versionNew = {
		Breaking = tonumber(a),
		Feature = tonumber(b),
		Fix = tonumber(c),
	}

	Quiver_Store = Quiver_Store or {}
	if Quiver_Store.Version == nil then
		Quiver_Migrations_M001()
	end

	Quiver_Store.Version = versionNew
end
