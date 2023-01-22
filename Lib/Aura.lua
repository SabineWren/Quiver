local resetTooltip = (function()
	local tooltip = nil
	local createTooltip = function()
		-- https://wowwiki-archive.fandom.com/wiki/UIOBJECT_GameTooltip
		tt = CreateFrame("GameTooltip", "QuiverAuraScanningTooltip", nil, "GameTooltipTemplate")
		tt:SetScript("OnHide", function() tt:SetOwner(WorldFrame, "ANCHOR_NONE") end)
		tt:Hide()
		tt:SetFrameStrata("Tooltip")
		return tt
	end
	return function()
		if not tooltip then tooltip = createTooltip() end
		tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
		return tooltip
	end
end)()

-- 10% at full hp, to a max of 30% at 40% hp
-- That's a line with equation f(hp)= (130-hp) / 3, but capped at 30%
local getTrollBerserkBonus = function()
	local percent = UnitHealth("player") / UnitHealthMax("player")
	return math.min(0.3, (1.30 - percent) / 3.0)
end

--[[
UnitBuff indexes from 1.
GetPlayerBuffTexture indexes from 0.
They also don't have the same iteration order.
Haven't found a reason to use one over the other. ]]
Quiver_Lib_Aura_GetRangedAttackSpeedMultiplier = function()
	local speed = 1.0
	for i=1,QUIVER.Buff_Cap do
		local texture = UnitBuff("player", i)
		if texture == QUIVER.Icon.CurseOfTongues then
			speed = speed * 0.5
		-- Unsure if it's safe to remove the wrong one. Maybe that would break other servers.
		elseif texture == QUIVER.Icon.NaxxTrinket
			or texture == QUIVER.Icon.NaxxTrinketWrong
		then
			speed = speed * 1.2
		elseif texture == QUIVER.Icon.Quickshots then
			speed = speed * 1.3
		elseif texture == QUIVER.Icon.RapidFire then
			speed = speed * 1.4
		elseif texture == QUIVER.Icon.TrollBerserk then
			speed = speed * (1.0 + getTrollBerserkBonus())
		end
	end
	return speed
end

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

Quiver_Lib_Aura_GetIsBuffActive = function(buffname)
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
