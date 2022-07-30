--[[
Won't merge into pfUI
https://github.com/shagu/pfUI/pull/1073
pfUI module based on its vanillaplus template
https://github.com/shagu/pfUI-vanillaplus

pfUI.lua will change environment which gives access to its local variables:
setfenv(pfUI.module[m], pfUI:GetEnvironment())
pfUI.module[m]()
]]

local pfUITurtleHunter = function()
	pfUI_locale["enUS"]["customcast"]["TRUESHOT"] = QUIVER_T.Spellbook.Trueshot
	local trueshotName = L["customcast"]["TRUESHOT"]
	-- Copy-pasted from pf's Multi-Shot implementation in libs/libcast.lua
	libcast.customcast[strlower(trueshotName)] = function(begin, duration)
		-- Somehow player isn't defined, but all the other locals from pfUI work
		local player = UnitName("player")
		if begin then
			local castTime, start = Quiver_Lib_Spellbook_GetCastTime(QUIVER_T.Spellbook.Trueshot)
			local duration = duration or (castTime * 1000)

			-- add cast action to the database
			libcast.db[player].cast = trueshotName
			libcast.db[player].rank = lastrank
			libcast.db[player].start = start
			libcast.db[player].casttime = duration
			libcast.db[player].icon = "Interface\\Icons\\Ability_Hunter_SteadyShot"
			libcast.db[player].channel = nil
		else
			-- remove cast action to the database
			libcast.db[player].cast = nil
			libcast.db[player].rank = nil
			libcast.db[player].start = nil
			libcast.db[player].casttime = nil
			libcast.db[player].icon = nil
			libcast.db[player].channel = nil
		end
	end
end

if pfUI ~= nil and pfUI.RegisterModule ~= nil then
	pfUI:RegisterModule("turtlehunter", pfUITurtleHunter)
end
