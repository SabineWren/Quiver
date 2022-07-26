local frame = nil
local bar = nil
local maxBarWidth = 0
local AIMING_TIME = 0.65
local reloadTime = 0

local castTime = 0
local isCasting = false
local timeStartCasting = 0

local isReloading = false
local isShooting = false
local timeStartShootOrReload = GetTime()
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
		CheckNoCooldownOrInstantShot = function()
			local cooldownStartTime, spellCD = Quiver_Lib_ActionBar_CheckGCD()
			if spellCD ~= 1.5 or gcdStartTime == cooldownStartTime then
				return true
			else
				-- We cast a spell that consumes ammo, but haven't yet handled "SPELLCAST_STOP"
				-- Case 1: it's instant cast
				-- Case 2: we started casting the instant we fired an auto shot
				-- In both cases, we can ignore it
				gcdStartTime = cooldownStartTime
				return isCasting
			end
		end
	}
end)()

-- ************ UI ************
local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("HIGH")

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

-- ************ Spell Event Handlers ************
local onSpellcast = function(spellName)
	if not Quiver_Store.ModuleEnabled.AutoShotCastbar then return end
	if isCasting then return end
	isCasting = true
	if isShooting and (not isReloading) then
		timeStartShootOrReload = GetTime()
	end
	timeStartCasting = GetTime()
	castTime = Quiver_Lib_ActionBar_GetCastTime(spellName)
end

local getIsBusy = function()
	for i=1,120 do
		if IsCurrentAction(i) then return true end
	end
	return false
end

local super = {
	CastSpell = CastSpell,
	CastSpellByName = CastSpellByName,
	UseAction = UseAction,
}
CastSpell = function(spellId, spellbookTabNum)
	super.CastSpell(spellId, spellbookTabNum)
	local spellName, _rank = GetSpellName(spellId, spellbookTabNum)
	if not getIsBusy() then return end
	local isShot = Quiver_Lib_ActionBar_GetIsSpellCastableShot(spellName)
	if isShot then onSpellcast(spellName) end
end
CastSpellByName = function(spellName, onSelf)
	super.CastSpellByName(spellName, onSelf)
	if not getIsBusy() then return end
	local isShot = Quiver_Lib_ActionBar_GetIsSpellCastableShot(spellName)
	if isShot then onSpellcast(spellName) end
end
UseAction = function(slot, checkCursor, onSelf)
	super.UseAction(slot, checkCursor, onSelf)
	if GetActionText(slot) or not IsCurrentAction(slot) then return end
	local spellName = Quiver_Lib_ActionBar_GetCastableShot(slot)
	if spellName ~= nil then onSpellcast(spellName) end
end

-- ************ Frame Update Handlers ************
local updateShooting = function()
	frame:SetAlpha(1)
	bar:SetBackdropColor(1 ,1 ,0, 0.8)
	local timePassed = GetTime() - timeStartShootOrReload

	if isCasting then
		bar:SetWidth(1)-- Can't set to zero
	elseif timePassed <= AIMING_TIME then
		bar:SetWidth(maxBarWidth * timePassed / AIMING_TIME)
	else
		bar:SetWidth(maxBarWidth)
	end
end

local hideBar = function()
	if Quiver_Store.IsLockedFrames then frame:SetAlpha(0) end
end

local updateReloading = function()
	frame:SetAlpha(1)
	bar:SetBackdropColor(1, 0, 0, 0.8)
	local timePassed = GetTime() - timeStartShootOrReload

	if timePassed <= reloadTime then
		bar:SetWidth(maxBarWidth - maxBarWidth * timePassed / reloadTime)
	else
		isReloading = false
		if isShooting then
			timeStartShootOrReload = GetTime()
			position.UpdateXY()
			updateShooting()-- Optional. I think this saves a frame
		else
			hideBar()
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
			hideBar()
			timeStartShootOrReload = GetTime()
		end
	end
end

-- ************ Event Handlers ************
local handleEvent = function()
	if event == "SPELLCAST_DELAYED" then
		castTime = castTime + arg1 / 1000
	elseif event == "START_AUTOREPEAT_SPELL" then
		isShooting = true
		position.UpdateXY()
		if not isReloading then timeStartShootOrReload = GetTime() end
	elseif event == "STOP_AUTOREPEAT_SPELL" then
		isShooting = false
		if not isReloading then hideBar() end
	-- If the spell consumes ammo, "ITEM_LOCK_CHANGED" will fire before "SPELLCAST_STOP"
	elseif event == "SPELLCAST_STOP" then
		isCasting = false
		gcd.HandleSpellcast()
		-- TODO-REMOVE DEFAULT_CHAT_FRAME:AddMessage("STOP CAST", 1, 0, 0)
	-- Auto Shot consumes ammo without triggering GCD
	-- This event fires when equiped items change, including changing ammo count.
	-- Swapping weapons will also trigger this and break the swing timer. Oh well.
	elseif event == "ITEM_LOCK_CHANGED" then
		local timeCasting = GetTime() - timeStartCasting
		-- Fired a non-instant spell
		if isCasting and timeCasting >= castTime then
			isCasting = false
			if not isReloading then timeStartShootOrReload = GetTime() end
		-- Fired Auto Shot
		elseif gcd.CheckNoCooldownOrInstantShot() then
			timeStartShootOrReload = GetTime()
			isReloading = true
			reloadTime = UnitRangedDamage("player") - AIMING_TIME
			position.UpdateXY()
		-- Else Fired Instant Shot
		end
	end
end

-- ************ Initialization ************
local events = {
	"ITEM_LOCK_CHANGED",
	"START_AUTOREPEAT_SPELL", "STOP_AUTOREPEAT_SPELL",
	"SPELLCAST_STOP",
	"SPELLCAST_DELAYED",
}
local onEnable = function()
	if frame == nil then frame, bar = createUI() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in events do frame:RegisterEvent(e) end
	frame:Show()
	if Quiver_Store.IsLockedFrames
	then frame:SetAlpha(0)
	else frame:SetAlpha(1)
	end
end
local onDisable = function()
	frame:Hide()
	for _k, e in events do frame:UnregisterEvent(e) end
end

local onInterfaceLock = function()
	if (not isShooting) and (not isReloading) then hideBar() end
end
local onInterfaceUnlock = function()
	frame:SetAlpha(1)
end

Quiver_Module_AutoShotCastbar = {
	Name = "AutoShotCastbar",
	OnRestoreSavedVariables = function(store) end,
	OnPersistSavedVariables = function() return {} end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = onInterfaceLock,
	OnInterfaceUnlock = onInterfaceUnlock,
}
