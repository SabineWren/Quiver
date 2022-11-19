--[[
Won't merge into pfUI
https://github.com/shagu/pfUI/pull/1073
pfUI module based on its vanillaplus template
https://github.com/shagu/pfUI-vanillaplus

pfUI.lua will change environment which gives access to its local variables:
setfenv(pfUI.module[m], pfUI:GetEnvironment())
pfUI.module[m]()
]]

Quiver_Module_pfUITurtleTrueshot = function()
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

-- This doesn't belong in Quiver, since it's non-Hunter stuff for autoshift.lua
-- However, it's useful, and there isn't a generic Turtle pfUI plugin.
Quiver_Module_pfUITurtleMountsAutoDismount = function()
	if pfUI.autoshift and pfUI.autoshift.buffs then
		local custom_mounts = { "ability_hunter_pet_bear", "ability_hunter_pet_tallstrider", "ability_creature_cursed_01", "inv_misc_key_06", "inv_misc_key_12", "inv_valentinescard01", "inv_valentinesboxofchocolates02", "spell_nature_sentinal", "inv_misc_questionmark", "inv_misc_head_dragon_bronze", "inv_pet_speedy", "ability_hunter_pet_dragonhawk", "ability_hunter_pet_hippogryph", "ability_hunter_pet_stag1", "spell_magic_polymorphchicken" }
		for _i, mount in custom_mounts do
			table.insert(pfUI.autoshift.buffs, mount)
		end
	end
end
