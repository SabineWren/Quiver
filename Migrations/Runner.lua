Quiver_Migrations_Run = function()
	-- toc version (after 1.0.0) persists to saved variables. A clean
	-- install has no saved variables, which distinguishes a 1.0.0 install.
	if Quiver_Store == nil then
		Quiver_Store = {}
	else
		local vOld = Quiver_Store.Version or "1.0.0"
		local getIsNewer = function(b)
			return Quiver_Lib_Version_GetIsNewer(vOld, b)
		end

		if getIsNewer("2.0.0") then Quiver_Migrations_M001() end
		if getIsNewer("2.3.1") then Quiver_Migrations_M002() end
		if getIsNewer("2.5.0") then Quiver_Migrations_M003() end
	end
	Quiver_Store.Version = GetAddOnMetadata("Quiver", "Version")
end
