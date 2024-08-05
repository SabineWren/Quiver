local Version = require "Lib/Version.lua"
local M001 = require "Migrations/M001.lua"
local M002 = require "Migrations/M002.lua"
local M003 = require "Migrations/M003.lua"

return function()
	-- toc version (after 1.0.0) persists to saved variables. A clean
	-- install has no saved variables, which distinguishes a 1.0.0 install.
	if Quiver_Store == nil then
		Quiver_Store = {}
	else
		local vOld = Quiver_Store.Version or "1.0.0"
		local getIsNewer = function(b)
			return Version.PredIsNewer(vOld, b)
		end

		if getIsNewer("2.0.0") then M001() end
		if getIsNewer("2.3.1") then M002() end
		if getIsNewer("2.5.0") then M003() end
	end
	Quiver_Store.Version = GetAddOnMetadata("Quiver", "Version")
end
