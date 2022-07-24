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

-- ************ State ************
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

local gcd = (function()
	local gcdStartTime = 0
	return {
		HandleSpellcast = function()
			local cooldownStartTime, spellCD = Quiver_Lib_ActionBar_CheckGCD()
			if spellCD == 1.5 then gcdStartTime = cooldownStartTime end
		end,
		CheckOffOrPreviousSpell = function()
			local cooldownStartTime, spellCD = Quiver_Lib_ActionBar_CheckGCD()
			if spellCD ~= 1.5 or gcdStartTime == cooldownStartTime then
				return true
			else
				-- We cast a spell that consumes ammo, but haven't yet handled the spellcast
				gcdStartTime = cooldownStartTime
				return false
			end
		end
	}
end)()

-- ************ Event Handlers ************
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

local handleEvent = function()
	if event == "START_AUTOREPEAT_SPELL" then
		isShooting = true
		position.UpdateXY()
		if not isReloading then timeStart = GetTime() end
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		isShooting = false
		if not isReloading then frame:SetAlpha(0) end
	elseif event == "SPELLCAST_STOP" then
		-- If the spell consumes ammo, this will first fire "ITEM_LOCK_CHANGED"
		gcd.HandleSpellcast()
	elseif event == "ITEM_LOCK_CHANGED" and isShooting then
		-- Auto Shot consumes ammo without triggering GCD
		-- This event fires when equiped items change, including changing ammo count.
		-- Swapping weapons will also trigger this and break the swing timer. Oh well.
		if gcd.CheckOffOrPreviousSpell() then
			isReloading = true
			timeStart = GetTime()
			position.UpdateXY()
			reloadTime = UnitRangedDamage("player") - AIMING_TIME
		end
	end
end

-- ************ Initialization ************
local events = { "ITEM_LOCK_CHANGED", "START_AUTOREPEAT_SPELL", "STOP_AUTOREPEAT_SPELL", "SPELLCAST_STOP" }
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
