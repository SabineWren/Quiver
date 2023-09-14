local MODULE_ID = "AutoShotTimer"
local store = nil
local frame = nil
local BORDER = 1
-- Aimed Shot, Multi-Shot, Trueshot
local castTime = 0
local isCasting = false
local isFiredInstant = false
local timeStartCast = 0
-- Auto Shot
local AIMING_TIME = 0.65
local isReloading = false
local isShooting = false
local maxBarWidth = 0
local reloadTime = 0
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

local getIsConsumable = function(combatLogMsg)
	if combatLogMsg == nil then return false end
	for _k, v in QUIVER_T.CombatLog.Consumes do
		local startPos, _ = string.find(combatLogMsg, v)
		if startPos then return true end
	end
	return false
end
local isConsumable = false

-- ************ UI ************
local setBarAutoShot = function(f)
	maxBarWidth = f:GetWidth() - 2 * BORDER
	f.BarAutoShot:SetWidth(1)
	f.BarAutoShot:SetHeight(f:GetHeight() - 2 * BORDER)
end
local setBarSizes = function(f, s)
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	setBarAutoShot(f)
end

local setFramePosition = function(f, s)
	Quiver_Event_FrameLock_SideEffectRestoreSize(s, {
		w=240, h=14, dx=240 * -0.5, dy=-136,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
	setBarSizes(f, s)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("High")
	f.BarAutoShot = CreateFrame("Frame", nil, f)

	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
		edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = BORDER,
	})
	f.BarAutoShot:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
	})
	f:SetBackdropColor(0, 0, 0, 0.8)
	f:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)

	f.BarAutoShot:SetPoint("Center", f, "Center", 0, 0)

	setFramePosition(f, store)
	local resizeBarAutoShot = function() setBarAutoShot(f) end
	Quiver_Event_FrameLock_SideEffectMakeMoveable(f, store)
	Quiver_Event_FrameLock_SideEffectMakeResizeable(f, store, {
		GripMargin=0,
		OnResizeDrag=resizeBarAutoShot,
		OnResizeEnd=resizeBarAutoShot,
		IsCenterX=true,
	})
	return f
end

-- ************ Frame Update Handlers ************
local updateBarShooting = function()
	frame:SetAlpha(1)
	local r, g, b = unpack(store.ColorShoot)
	frame.BarAutoShot:SetBackdropColor(r, g, b, 0.8)
	local timePassed = GetTime() - timeStartShootOrReload

	if isCasting then
		frame.BarAutoShot:SetWidth(1)-- Can't set to zero
	elseif timePassed <= AIMING_TIME then
		frame.BarAutoShot:SetWidth(maxBarWidth * timePassed / AIMING_TIME)
	else
		frame.BarAutoShot:SetWidth(maxBarWidth)
	end
end

local startReloading = function()
	if not isReloading then timeStartShootOrReload = GetTime() end
	isReloading = true
	reloadTime = UnitRangedDamage("player") - AIMING_TIME
end
local startShooting = function()
	if not isReloading then timeStartShootOrReload = GetTime() end
	isShooting = true
	position.UpdateXY()
end

local tryHideBar = function()
	if Quiver_Store.IsLockedFrames then
		frame:SetAlpha(0)
	else
		-- Reset bar if it's locked open
		frame.BarAutoShot:SetWidth(1)
		timeStartShootOrReload = GetTime()
	end
end

local updateBarReload = function()
	frame:SetAlpha(1)
	local r, g, b = unpack(store.ColorReload)
	frame.BarAutoShot:SetBackdropColor(r, g, b, 0.8)
	local timePassed = GetTime() - timeStartShootOrReload
	if timePassed <= reloadTime then
		frame.BarAutoShot:SetWidth(maxBarWidth - maxBarWidth * timePassed / reloadTime)
	else
		isReloading = false
		if isShooting then
			startShooting()
			updateBarShooting()-- Optional. I think this saves a frame
		else
			tryHideBar()
		end
	end
end

local handleUpdate = function()
	if isReloading then
		updateBarReload()
	elseif isShooting and position.CheckStandingStill() then
		updateBarShooting()
	else
		-- We may have moved while shooting, so reset time
		timeStartShootOrReload = GetTime()
		tryHideBar()
	end
end

--[[ ************ Event Handlers ************
Some actions trigger multiple events in sequence:
1. Instant Shot while either moving or in middle of reload
-> (hook) OnInstant
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
2. Instant Shot as Auto Shot fires (assuming state is already shooting)
-> (hook) OnInstant
-> ITEM_LOCK_CHANGED
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
3. Casted Shot starts as Auto Shot fires (assuming state is already shooting)
-> (hook) OnCast
-> ITEM_LOCK_CHANGED
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
]]
local EVENTS = {
	"CHAT_MSG_SPELL_SELF_BUFF",-- To ignore whitelisted inventory events corresponding to consumables
	"ITEM_LOCK_CHANGED",-- Inventory event, such as using ammo
	"SPELLCAST_DELAYED",-- Pushback
	"SPELLCAST_FAILED",-- Too close, Spell on CD, already in progress, or success after dropping target
	"SPELLCAST_INTERRUPTED",-- Knockback etc.
	"SPELLCAST_STOP",-- Finished cast
	"START_AUTOREPEAT_SPELL",-- Start shooting
	"STOP_AUTOREPEAT_SPELL",-- Stop shooting
}
local onSpellcast = function(spellName)
	-- User can spam the ability while it's already casting
	if isCasting then return end
	isCasting = true
	-- We can reload while casting, but Auto Shot needs resetting
	if isShooting and (not isReloading) then
		timeStartShootOrReload = GetTime()
	end
	castTime, timeStartCast = Quiver_Lib_Spellbook_GetCastTime(spellName)
end

local handleEvent = function()
	local e = event
	-- Fires after SPELLCAST_STOP, but before ITEM_LOCK_CHANGED
	if e == "CHAT_MSG_SPELL_SELF_BUFF" then
		isConsumable = getIsConsumable(arg1)
	elseif e == "SPELLCAST_DELAYED"
		then castTime = castTime + arg1 / 1000
	-- This works because shooting consumes ammo, which triggers an inventory event
	elseif e == "ITEM_LOCK_CHANGED" then
		if isConsumable then
		-- Case 1 - We used a consumable, not ammunition.
			isConsumable = false
		elseif isFiredInstant then
		-- Case 2
		-- We fired an instant but haven't yet called "SPELLCAST_STOP"
		-- If we fired an Auto Shot at the same time, then "ITEM_LOCK_CHANGED" will
		-- trigger twice before "SPELLCAST_STOP", so we mark the first one as done.
			isFiredInstant = false
		elseif isCasting then
			local elapsed = GetTime() - timeStartCast
			if isShooting and elapsed < castTime then
		-- Case 3 - We started casting immediately after firing an Auto Shot. We're casting and reloading.
				startReloading()
			else
		-- Case 4 - We finished a cast. If we're done reloading, we can shoot again
				if not isReloading then timeStartShootOrReload = GetTime() end
				isCasting = false
			end
		elseif isShooting then
		-- Case 5 - Fired Auto Shot
		-- Works even if we cancelled Auto Shot as we fired because "STOP_AUTOREPEAT_SPELL" is lower priority.
			startReloading()
		-- else No-op
		-- Case 6 - This was an inventory event we can safely ignore.
		end
	elseif e == "SPELLCAST_STOP" or e == "SPELLCAST_FAILED" or e == "SPELLCAST_INTERRUPTED" then
		isCasting = false
	elseif e == "START_AUTOREPEAT_SPELL" then
		startShooting()
	elseif e == "STOP_AUTOREPEAT_SPELL" then
		isShooting = false
	end
end

-- ************ Enable macros that avoid clipping shots ************
local castNoClip = function(spellName)
	return function(_args, _box)
		local isMidShot = isShooting and not isReloading
		if not isMidShot and not isCasting then
			CastSpellByName(spellName)
		end
	end
end

-- ************ Initialization ************
local onEnable = function()
	if frame == nil then
		frame = createUI()
		SLASH_QQAIMEDSHOT1 = "/qqaimedshot"
		SLASH_QQMULTISHOT1 = "/qqmultishot"
		SLASH_QQTRUESHOT1 = "/qqtrueshot"
		SlashCmdList["QQAIMEDSHOT"] = castNoClip("Aimed Shot")
		SlashCmdList["QQMULTISHOT"] = castNoClip("Multi-Shot")
		SlashCmdList["QQTRUESHOT"] = castNoClip("Trueshot")
	end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	if Quiver_Store.IsLockedFrames then frame:SetAlpha(0) else frame:SetAlpha(1) end
	Quiver_Event_Spellcast_CastableShot.Subscribe(MODULE_ID, onSpellcast)
	Quiver_Event_Spellcast_Instant.Subscribe(MODULE_ID, function(spellName)
		isFiredInstant = Quiver_Lib_Spellbook_GetIsSpellInstantShot(spellName)
	end)
	frame:Show()
end
local onDisable = function()
	frame:Hide()
	Quiver_Event_Spellcast_Instant.Dispose(MODULE_ID)
	Quiver_Event_Spellcast_CastableShot.Dispose(MODULE_ID)
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

Quiver_Module_AutoShotTimer = {
	Id = MODULE_ID,
	Name = QUIVER_T.ModuleName[MODULE_ID],
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function()
		if (not isShooting) and (not isReloading) then tryHideBar() end
	end,
	OnInterfaceUnlock = function() frame:SetAlpha(1) end,
	OnResetFrames = function(trigger)
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.ColorShoot = store.ColorShoot or QUIVER.ColorDefault.AutoShotShoot
		store.ColorReload = store.ColorReload or QUIVER.ColorDefault.AutoShotReload
	end,
	OnSavedVariablesPersist = function() return store end,
}
