local DB_SPELL = require "Shiver/Data/Spell.lua"
local ScanningTooltip = require "Shiver/ScanningTooltip.lua"

local calcRangedWeaponSpeedBase = function()
	return ScanningTooltip.Scan(function(tooltip)
		tooltip:ClearLines()
		local _, _, _ = tooltip:SetInventoryItem("player", 18)-- ranged weapon slot

		for i=1, tooltip:NumLines() do
			local text = ScanningTooltip.GetText("TextRight", i)
			if text ~= nil then
				--- TODO LOCALIZE
				local _, _, speed = string.find(text, "Speed (%d+%.%d+)")
				if speed ~= nil then
					local parsed = tonumber(speed)
					if parsed ~= nil then
						tooltip:Hide()
						return parsed
					end
				end
			end
		end

		-- Something went wrong. Maybe there's no ranged weapn equipped.
		return nil
	end)
end

---@param name string
---@return number casttime
---@return number startLatAdjusted
---@return number startLocal
---@nodiscard
local CalcCastTime = function(name)
	local meta = DB_SPELL[name]
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
