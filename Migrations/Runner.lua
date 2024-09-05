local M001 = require "Migrations/M001.lua"
local M002 = require "Migrations/M002.lua"
local M003 = require "Migrations/M003.lua"
local Version = require "Util/Version.lua"

return function()
	-- toc version (after 1.0.0) persists to saved variables. A clean
	-- install has no saved variables, which distinguishes a 1.0.0 install.
	if Quiver_Store == nil then
		Quiver_Store = {}
	else
		local vOld = Version:ParseThrows(Quiver_Store.Version or "1.0.0")
		if vOld:PredNewer("2.0.0") then M001() end
		if vOld:PredNewer("2.3.1") then M002() end
		if vOld:PredNewer("2.5.0") then M003() end
	end
	Quiver_Store.Version = GetAddOnMetadata("Quiver", "Version")
end
