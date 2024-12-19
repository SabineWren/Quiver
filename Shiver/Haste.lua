local DB_SPELL = require "Shiver/Data/Spell.lua"
local ScanningTooltip = require "Shiver/ScanningTooltip.lua"
local Enum = require "Shiver/Enum.lua"

-- GetInventoryItemLink("Player", slot#) returns a link, ex. [name]
-- Weapon name always appears at line TextLeft1
-- TODo Might be cachable. Experiment which events would clear cache.
local calcRangedWeaponSpeedBase = function()
	return ScanningTooltip.Scan(function(tooltip)
		tooltip:ClearLines()
		local _RANGED = Enum.INVENTORY_SLOT.Ranged
		local _, _, _ = tooltip:SetInventoryItem("player", _RANGED)

		for i=1, tooltip:NumLines() do
			local text = ScanningTooltip.GetText("TextRight", i)
			if text ~= nil then
				-- ex. "Speed 3.2"
				-- Not matching on the text part since that requires localization
				local _, _, speed = string.find(text, "(%d+%.%d+)")
				if speed ~= nil then
					local parsed = tonumber(speed)
					if parsed ~= nil then
						tooltip:Hide()
						return parsed
					end
				end
			end
		end

		-- Something went wrong. Maybe there's no ranged weapon equipped.
		return nil
	end)
end

---@param nameEnglish string
---@return number casttime
---@return number startLatAdjusted
---@return number startLocal
---@nodiscard
local CalcCastTime = function(nameEnglish)
	local meta = DB_SPELL[nameEnglish]
	local _,_, msLatency = GetNetStats()
	local startLocal = GetTime()
	local startLatAdjusted = startLocal + msLatency / 1000

	-- No spell metadata means it's not a spell we care about. Assume instant.
	if meta == nil then
		return 0, startLatAdjusted, startLocal
	elseif meta.Haste == "range" then
		local speedCurrent, _, _ , _, _, _ = UnitRangedDamage("player")
		local speedBaseNil = calcRangedWeaponSpeedBase()
		local speedBase = speedBaseNil and speedBaseNil or speedCurrent
		local speedMultiplier = speedCurrent / speedBase
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
