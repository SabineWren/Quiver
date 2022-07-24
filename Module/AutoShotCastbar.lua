local frame = nil
local bar = nil
local maxBarWidth = 0

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)

	f:SetFrameStrata("HIGH")
	f:SetAlpha(1)

	local borderSize = 1
	local width = 190
	local height = 14
	local posY = -165-- todo -180

	f:SetWidth(width)
	f:SetHeight(height)
	f:SetPoint("Center", 0, posY)
	maxBarWidth = width - 2 * borderSize

	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
		edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = borderSize,
	})
	f:SetBackdropColor(0, 0, 0, 0.8)
	f:SetBackdropBorderColor(1, 1, 1, 0.8)

	local b = CreateFrame("Frame", nil, f)
	b:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
	})
	b:SetWidth(0)
	b:SetHeight(height - 2 * borderSize)
	b:SetPoint("Center", f, "Center", 0, 0)

	return f, b
end

local AIMING_TIME = 0.65
local isReloading = false
local isShooting = false
local reloadTime = 0
local timeStart = GetTime()

local position = (function()
	local x, y = 0, 0
	local updateXY = function() x, y = GetPlayerMapPosition("player") end
	return {
		UpdateXY = updateXY,
		CheckStandingStill = function()
			local lastX, lastY = x, y
			updateXY()
			return x == lastX and y == lastY
		end,
	}
end)()

local updateShooting = function()
	frame:SetAlpha(1)
	bar:SetBackdropColor(1 ,1 ,0, 0.8)
	local timePassed = GetTime() - timeStart

	local width = timePassed <= AIMING_TIME
		and maxBarWidth * timePassed / AIMING_TIME
		or maxBarWidth
	bar:SetWidth(width)
end

local updateReloading = function()
	frame:SetAlpha(1)
	bar:SetBackdropColor(1, 0, 0, 0.8)
	local timePassed = GetTime() - timeStart

	if timePassed <= reloadTime then
		bar:SetWidth(maxBarWidth - maxBarWidth * timePassed / reloadTime)
	else
		isReloading = false
		if isShooting then
			timeStart = GetTime()
			position.UpdateXY()
			updateShooting()-- Optional. I think this saves a frame
		else
			frame:SetAlpha(0)
		end
	end
end

local handleUpdate = function()
	if isReloading then
		updateReloading()
	elseif isShooting then
		if position.CheckStandingStill() then
			updateShooting()
		else
			frame:SetAlpha(0)
			timeStart = GetTime()
		end
	end
end

--[[
Some addons use "SPELLCAST_STOP", but I think that's a retail thing for Auto Shot.
https://forum.nostalrius.org/viewtopic.php?t=12765

Private servers trigger "ITEM_LOCK_CHANGED" when equiped items change,
which works because shooting expends ammunition.
]]
local lastCooldownStartTime = 0
local handleEvent = function()
	if event == "START_AUTOREPEAT_SPELL" then
		isShooting = true
		if not isReloading then timeStart = GetTime() end
		position.UpdateXY()
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		isShooting = false
		if not isReloading then frame:SetAlpha(0) end
	elseif event == "ITEM_LOCK_CHANGED" and isShooting then
		local cooldownStartTime, cooldownRemaining = Quiver_Lib_ActionBar_CheckGCD()
		if cooldownRemaining ~= 1.5 or cooldownStartTime == lastCooldownStartTime then
			isReloading = true
			timeStart = GetTime()
			position.UpdateXY()
			reloadTime = UnitRangedDamage("player") - AIMING_TIME
		else
			lastCooldownStartTime = cooldownStartTime
		end
	end
end

local events = { "START_AUTOREPEAT_SPELL", "STOP_AUTOREPEAT_SPELL", "ITEM_LOCK_CHANGED" }
Quiver_Module_AutoShotCastbar_Enable = function()
	if frame == nil then frame, bar = createUI() end
	frame:Show()
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in events do frame:RegisterEvent(e) end
end

Quiver_Module_AutoShotCastbar_Disable = function()
	frame:Hide()
	for _k, e in events do frame:UnregisterEvent(e) end
end
