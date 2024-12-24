local Tooltip = require "Api/Tooltip.lua"
local Const = require "Constants.lua"

-- This doesn't work for duplicate textures (ex. cheetah + zg mount).
-- For those you have to scan by name using the GameTooltip.
local GetIsActiveAndTimeLeftByTexture = function(targetTexture)
	-- This seems to check debuffs as well (tested with deserter)
	local maxIndex = Const.Aura_Cap - 1
	for i=0, maxIndex do
		local texture = GetPlayerBuffTexture(i)
		if texture == targetTexture then
			local timeLeft = GetPlayerBuffTimeLeft(i)
			return true, timeLeft
		end
	end
	return false, 0
end

---@param buffname string
---@nodiscard
local PredBuffActive = function(buffname)
	return Tooltip.Scan(function(tooltip)
		for i=0, Const.Buff_Cap do
			local buffIndex, _untilCancelled = GetPlayerBuff(i, "HELPFUL|PASSIVE")
			if buffIndex >= 0 then
				tooltip:ClearLines()
				tooltip:SetPlayerBuff(buffIndex)
				if Tooltip.GetText("TextLeft", 1) == buffname then
					return true
				end
			end
		end
		return false
	end)
end


-- This works great. Don't delete because switching from
-- texture to tooltip scanning would increase reliability.
-- UPDATE: Quiver now has as tooltip scanning library.
-- Also, this time-parsing code isn't client-localized.
-- This is still the right approach though.
--[[
local PredIsBuffActiveTimeLeftByName = function(buffname)
	local tooltip = resetTooltip()
	for i=0, Const.Buff_Cap do
		local buffIndex, _untilCancelled = GetPlayerBuff(i, "HELPFUL|PASSIVE")
		if buffIndex >= 0 then
			tooltip:ClearLines()
			tooltip:SetPlayerBuff(buffIndex)
			local fs1 = _G["QuiverAuraScanningTooltipTextLeft1"]
			local fs3 = _G["QuiverAuraScanningTooltipTextLeft3"]

			local auraTimeLeft = fs3 and fs3:GetText() or ""
			local _, _, strHours = string.find(auraTimeLeft, "(.*) hours remaining")
			local _, _, strMinutes = string.find(auraTimeLeft, "(.*) minutes remaining")
			local _, _, strSeconds = string.find(auraTimeLeft, "(.*) seconds remaining")
			local hours = tonumber(strHours) or 0
			local minutes = tonumber(strMinutes) or 0
			local seconds = tonumber(strSeconds) or 0
			local secondsLeft = seconds + 60 * (minutes + 60 * hours)

			if fs1 and fs1:GetText() == buffname then
				return true, secondsLeft
			end
		end
	end
	return false, 0
end
]]

return {
	GetIsActiveAndTimeLeftByTexture = GetIsActiveAndTimeLeftByTexture,
	PredBuffActive = PredBuffActive,
}
