local frame = nil
local maxBarWidth = 0
local borderSize = 1
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
		CheckShotWasAuto = function()
			local cooldownStartTime, spellCD = Quiver_Lib_ActionBar_CheckGCD()
			-- Case 1 -- Not on GCD
			if spellCD ~= 1.5 then return true
			-- Case 2 -- Still on GCD from previous cast
			elseif gcdStartTime == cooldownStartTime then return true
			-- Case 3 -- We triggered GCD at the same time we fired an auto shot
			elseif isShooting and (not isReloading) then return true
			-- Case 4 -- Cast an instant shot like Arcane Shot
			else
				gcdStartTime = cooldownStartTime
				return false
			end
		end
	}
end)()
local ammo = (function()
	local lastCount = 0
	return {
		Update = function()
			local ammoSlot = GetInventorySlotInfo("AmmoSlot")
			local ammoCount = GetInventoryItemCount("player", ammoSlot)
			local shots = lastCount - ammoCount
			lastCount = ammoCount
			return shots
		end
	}
	end
)()

-- ************ UI ************
local updateAllSizes = function()
	local meta = Quiver_Store.FrameMeta.AutoShotCastbar
	frame:SetWidth(meta.W)
	frame:SetHeight(meta.H)
	frame:SetPoint("Center", 0, meta.Y)

	maxBarWidth = meta.W - 2 * borderSize
	frame.Bar:SetWidth(1)
	frame.Bar:SetHeight(meta.H - 2 * borderSize)
end
local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("HIGH")
	f.Bar = CreateFrame("Frame", nil, f)

	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
		edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = borderSize,
	})
	f:SetBackdropColor(0, 0, 0, 0.8)
	f:SetBackdropBorderColor(1, 1, 1, 0.8)

	f.Bar:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
	})
	f.Bar:SetPoint("Center", f, "Center", 0, 0)
	return f
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
	frame.Bar:SetBackdropColor(1 ,1 ,0, 0.8)
	local timePassed = GetTime() - timeStartShootOrReload

	if isCasting then
		frame.Bar:SetWidth(1)-- Can't set to zero
	elseif timePassed <= AIMING_TIME then
		frame.Bar:SetWidth(maxBarWidth * timePassed / AIMING_TIME)
	else
		frame.Bar:SetWidth(maxBarWidth)
	end
end

local hideBar = function()
	if Quiver_Store.IsLockedFrames
	then frame:SetAlpha(0)
	else frame.Bar:SetWidth(1)
	end
end

local updateReloading = function()
	frame:SetAlpha(1)
	frame.Bar:SetBackdropColor(1, 0, 0, 0.8)
	local timePassed = GetTime() - timeStartShootOrReload

	if timePassed <= reloadTime then
		frame.Bar:SetWidth(maxBarWidth - maxBarWidth * timePassed / reloadTime)
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
	-- Auto Shot consumes ammo without triggering GCD
	-- This event fires when equiped items change, including changing ammo count.
	-- Swapping weapons, clicking on bag items, receiving loot, etc. will trigger this.
	elseif event == "ITEM_LOCK_CHANGED" then
		local newTime = GetTime()
		local shotsFired = ammo.Update()
		-- Ammo check covers edge case of stop-attack right as shot fires
		-- isCasting check covers edge case where you start a cast right as shot fires
		-- isShooting check covers all other shots
		-- If all 3 checks fail, it must be an inventory event
		local hasProbablyShot = shotsFired ~= 0 or isCasting or isShooting
		-- Fired a non-instant spell
		if isCasting and (newTime - timeStartCasting) >= castTime then
			isCasting = false
			if not isReloading then timeStartShootOrReload = newTime end
		-- Fired Auto Shot
		elseif hasProbablyShot and gcd.CheckShotWasAuto() then
			timeStartShootOrReload = newTime
			isReloading = true
			reloadTime = UnitRangedDamage("player") - AIMING_TIME
			position.UpdateXY()
		-- Else Fired Instant Shot
		-- Or was an inventory event such as looting or moving an item
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
	if frame == nil then frame = createUI(); updateAllSizes() end
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

Quiver_Module_AutoShotCastbar_MoveY = function()
	local meta = Quiver_Store.FrameMeta.AutoShotCastbar
	frame:SetPoint("Center", 0, meta.Y)
end

Quiver_Module_AutoShotCastbar_Resize = updateAllSizes

Quiver_Module_AutoShotCastbar = {
	Name = "AutoShotCastbar",
	OnRestoreSavedVariables = function(store)
		local meta = Quiver_Store.FrameMeta.AutoShotCastbar
		meta.W = meta.W or 190
		meta.H = meta.H or 14
		meta.Y = meta.Y or -180
	end,
	OnPersistSavedVariables = function() return {} end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = onInterfaceLock,
	OnInterfaceUnlock = onInterfaceUnlock,
}
