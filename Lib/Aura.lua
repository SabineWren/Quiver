-- This doesn't work for duplicate textures (ex. cheetah + zg mount).
-- For those you have to scan by name using the GameTooltip.
Quiver_Lib_Aura_GetIsActiveTimeLeftByTexture = function(targetTexture)
	-- This seems to check debuffs as well (tested with deserter)
	local maxIndex = QUIVER.Aura_Cap - 1
	for i=0,maxIndex do
		local texture = GetPlayerBuffTexture(i)
		if texture == targetTexture then
			local timeLeft = GetPlayerBuffTimeLeft(i)
			return true, timeLeft
		end
	end
	return false, 0
end

Quiver_Lib_Aura_GetIsBuffActive = (function()
	local resetTooltip = Quiver_Lib_Tooltip_Factory("QuiverAuraScanningTooltip")
	return function(buffname)
		local tooltip = resetTooltip()
		for i=0,QUIVER.Buff_Cap do
			local buffIndex, isCancellable = GetPlayerBuff(i, "HELPFUL|PASSIVE")
			if buffIndex >= 0 then
				tooltip:ClearLines()
				tooltip:SetPlayerBuff(buffIndex)
				local fs1 = _G["QuiverAuraScanningTooltipTextLeft1"]
				if fs1 and fs1:GetText() == buffname then
					return true
				end
			end
		end
		return false
	end
end)()

-- This works great. Don't delete because I'm sure it will be useful in the future.
--[[
Quiver_Lib_Aura_GetIsBuffActiveTimeLeftByName = function(buffname)
	local tooltip = resetTooltip()
	for i=0,QUIVER.Buff_Cap do
		local buffIndex, isCancellable = GetPlayerBuff(i, "HELPFUL|PASSIVE")
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
