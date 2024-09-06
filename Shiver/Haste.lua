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
	local baseTime = meta and meta.Time or 0
	local offset = meta and meta.Offset or 0

	local _,_, msLatency = GetNetStats()
	local startLocal = GetTime()
	local startLatAdjusted = startLocal + msLatency / 1000

	if meta.Haste == "range" then
		local speedCurrent, _, _ , _, _, _ = UnitRangedDamage("player")
		local speedBaseNil = calcRangedWeaponSpeedBase()
		local speedBase = speedBaseNil and speedBaseNil or speedCurrent
		local speedMultiplier = speedCurrent / speedBase
		-- https://www.mmo-champion.com/content/2188-Patch-4-0-6-Feb-22-Hotfixes-Blue-Posts-Artworks-Comic
		local casttime = (offset + baseTime * speedMultiplier) / 1000
		return casttime, startLatAdjusted, startLocal
	end

	-- LuaLS doesn't support exhaustive checks? TODO investigate
	local timeFallback = (meta.Time + meta.Offset) / 1000
	return timeFallback, startLatAdjusted, startLocal
end

return {
	CalcCastTime = CalcCastTime,
}
