-- This file would be API extension code, except that it only supports
-- hunter casts. I have no idea how to compute haste for non-hunter spells.
local Api = require "Api/Index.lua"
local L = require "Lib/Index.lua"

-- GetInventoryItemLink("Player", slot#) returns a link, ex. [name]
-- <br>Weapon name always appears at line TextLeft1
-- <br>ex. "Speed 3.2", but avoid matching on localized portions of text.
-- <br>If nil, something went wrong. Maybe there's no ranged weapon equipped.
---@return nil|integer
local scanRangedWeaponSpeed = function()
	return Api.Tooltip.Scan(function(tooltip)
		tooltip:ClearLines()
		local _, _, _ = tooltip:SetInventoryItem("player", Api.Enum.INVENTORY_SLOT.Ranged)
		return L.Nil.FirstBy(
			tooltip:NumLines(),
			L.Flow3(
				function(i) return Api.Tooltip.GetText("TextRight", i) end,
				L.Nil.Bind(function(text)
					local _, _, speed = string.find(text, "(%d+%.%d+)")
					return speed
				end),
				L.Nil.Bind(tonumber)
			)
		)
	end)
end

---@param nameEnglish string
---@return number casttime
---@return number startLatAdjusted
---@return number startLocal
---@nodiscard
local CalcCastTime = function(nameEnglish)
	local meta = Api.Spell.Db[nameEnglish]
	local _,_, msLatency = GetNetStats()
	local startLocal = GetTime()
	local startLatAdjusted = startLocal + msLatency / 1000

	-- No spell metadata means it's not a spell we care about. Assume instant.
	if meta == nil then
		return 0, startLatAdjusted, startLocal
	elseif meta.Haste == "range" then
		local speedCurrent, _, _ , _, _, _ = UnitRangedDamage("player")
		local speedWeapon = L.Nil.GetOr(scanRangedWeaponSpeed(), speedCurrent)
		local speedMultiplier = speedCurrent / speedWeapon
		-- https://www.mmo-champion.com/content/2188-Patch-4-0-6-Feb-22-Hotfixes-Blue-Posts-Artworks-Comic
		local casttime = (meta.Offset + meta.Time * speedMultiplier) / 1000
		return casttime, startLatAdjusted, startLocal
	elseif meta.Haste == "none" then
		return 0, startLatAdjusted, startLocal
	else
		-- LuaLS type narrows on objects, but not literals
		-- https://github.com/LuaLS/lua-language-server/pull/2864
		-- https://github.com/LuaLS/lua-language-server/issues/704
		-- Even when narrowing, it doesn't support exhaustive checks (no issue).
		-- The best we can do is provide some debug output for QA.
		DEFAULT_CHAT_FRAME:AddMessage("Failed exhaustive check", 1, 1, 0)
		DEFAULT_CHAT_FRAME:AddMessage(meta.Haste, 1, 1, 0)
		return 0, startLatAdjusted, startLocal
	end
end

return {
	CalcCastTime = CalcCastTime,
}
