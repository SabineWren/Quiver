local MODULE_ID = "AutoShotTimer"
local store = nil
local frame = nil
local BORDER = 1
-- Aimed Shot, Multi-Shot, Trueshot
local castTime = 0
local isCasting = false
local isFiredInstant = false
local timeStartCastLocal = 0
-- Auto Shot
local AIMING_TIME = 0.65
local isReloading = false
local isShooting = false
local maxBarWidth = 0
local reloadTime = 0
local timeStartShootOrReload = GetTime()

local log = function(text)
	if Quiver_Store.DebugLevel == "Verbose" then
		DEFAULT_CHAT_FRAME:AddMessage(text)
	end
end

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
	-- Coerce to boolean because there's nothing sensible to do if we have an invalid value.
	if store.BarDirection == "LeftToRight" then
		f.BarAutoShot:ClearAllPoints()
		f.BarAutoShot:SetPoint("Left", f, "Left", BORDER, 0)
	else
		f.BarAutoShot:ClearAllPoints()
		f.BarAutoShot:SetPoint("Center", f, "Center", 0, 0)
	end

	maxBarWidth = f:GetWidth() - 2 * BORDER
	f.BarAutoShot:SetWidth(1)
	f.BarAutoShot:SetHeight(f:GetHeight() - 2 * BORDER)
end

local setFramePosition = function(f, s)
	Quiver_Event_FrameLock_SideEffectRestoreSize(s, {
		w=240, h=14, dx=240 * -0.5, dy=-136,
	})

	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)

	setBarAutoShot(f)
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
	if not isReloading then
		timeStartShootOrReload = GetTime()
		log("starting reload")
	end
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
		log("End reload")
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
4. Auto Shot -> Casted Shot -> Instant Shot -> Auto Shot
   Tricky case to handle. TODO: CURRENTLY BUGGED.
-> ITEM_LOCK_CHANGED (auto)
-> (hook) casting
-> (hook) instant (spamming before cast finishes)
-> ITEM_LOCK_CHANGED (casted)
-> SPELLCAST_STOP (casted)
-> (hook) instant (still spamming the instant)
-> ITEM_LOCK_CHANGED (instant)
-> SPELLCAST_STOP (instant)
-> ITEM_LOCK_CHANGED (auto)
]]
local EVENTS = {
	"CHAT_MSG_SPELL_SELF_BUFF",-- To ignore whitelisted inventory events corresponding to consumables
	"ITEM_LOCK_CHANGED",-- Inventory event, such as using ammo or drinking a potion. This is how we detect auto shots.
	"SPELLCAST_DELAYED",-- Pushback
	-- Failed / INTERRUPTED / STOP all happen after ITEM_LOCK_CHANGED
	"SPELLCAST_FAILED",-- Too close, Spell on CD, already in progress, or success after dropping target
	"SPELLCAST_INTERRUPTED",-- Knockback etc.
	"SPELLCAST_STOP",-- Finished cast
	"START_AUTOREPEAT_SPELL",-- Start shooting (first event fired in chain)
	"STOP_AUTOREPEAT_SPELL",-- Stop shooting (last event fired in chain)
}

---@param event string
---@param arg1 any
local handleEventWhileCasting = function(event, arg1)
	if event == "SPELLCAST_DELAYED" then
		castTime = castTime + arg1 / 1000
	elseif
		event == "SPELLCAST_STOP"
		or event == "SPELLCAST_FAILED"
		or event == "SPELLCAST_INTERRUPTED"
	then
		-- The instant hook may have set its state variable. That means the user pressed an instant shot
		-- before the castbar completed. We can't actually fire an instant shot while casting,
		-- so it's a false positive and we need to override it to avoid breaking our state machine.
		isCasting = false -- Exit this handler
		isFiredInstant = false
		if not isReloading then timeStartShootOrReload = GetTime() end
		log("Stopped Casting")
	elseif event == "ITEM_LOCK_CHANGED" then
		-- Two possibilities:
		-- 1 - Auto Shot fired as cast started. (Cast -> lock -> lock -> Cast Stop)
		-- 2 - Cast Fired. A stop or failed event will follow, or failed event when target dropped.
		-- For case 1, confirm plausible timing.
		-- The fastest possible cast (multi-shot) takes 0.5 seconds,
		-- so we can use any number between that and zero.
		-- For case 2, wait for the stop / fail event
		local elapsed = GetTime() - timeStartCastLocal
		log(elapsed)
		if (elapsed < 0.4) then
			-- We must have started the cast exactly as an auto shot fired.
			-- TODO Printing this because theoretically it should happen,
			-- but I haven't managed to trigger it O.O.
			local text = "Quiver -- Auto Fired (edge case): " .. string.format(" %.3f before %.3f", elapsed, castTime)
			DEFAULT_CHAT_FRAME:AddMessage(text)
			startReloading()
		end
	end
end

---comment
---@param event string
---@param arg1 any
local handleEventNoCast = function(event, arg1)
	if
		event == "SPELLCAST_STOP"
		or event == "SPELLCAST_FAILED"
		or event == "SPELLCAST_INTERRUPTED"
	then
		if isFiredInstant then log("Instant Shot") end
		isFiredInstant = false
	elseif
		event == "ITEM_LOCK_CHANGED"
		and isShooting
		and (not isFiredInstant)
	then
		log("Auto Fired")
	-- Works even if we cancelled Auto Shot as we fired because "STOP_AUTOREPEAT_SPELL" is lower priority.
		startReloading()
	end
end

local onSpellcast = function(spellName)
	-- User can spam the ability while it's already casting
	if isCasting then return end
	isCasting = true
	-- We can reload while casting, but Auto Shot needs resetting
	-- TODO this doesn't make sense. Why would starting a cast reset shooting time?
	-- The shot can't restart until the cast ends.
	if isShooting and (not isReloading) then
		timeStartShootOrReload = GetTime()
	end
	local _latAdjusted
	castTime, _latAdjusted, timeStartCastLocal = Quiver_Lib_Spellbook_CalcCastTime(spellName)
	log("Start Cast")
end

local handleEvent = function()
	local e = event
	-- Fires after SPELLCAST_STOP, but before ITEM_LOCK_CHANGED
	if e == "CHAT_MSG_SPELL_SELF_BUFF" then
		isConsumable = getIsConsumable(arg1)
	elseif e == "START_AUTOREPEAT_SPELL" then
		log("Start shooting")
		startShooting()
	elseif e == "STOP_AUTOREPEAT_SPELL" then
		log("Stop shooting")
		isShooting = false
	elseif isConsumable and e == "ITEM_LOCK_CHANGED" then
		-- We drank a potion or something, so don't run any handlers
		isConsumable = false
	elseif isCasting then
		handleEventWhileCasting(e, arg1)
	else
		handleEventNoCast(e, arg1)
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
	Quiver_Event_Spellcast_Instant.Dispose(MODULE_ID)
	Quiver_Event_Spellcast_CastableShot.Dispose(MODULE_ID)
	if frame ~= nil then
		frame:Hide()
		for _k, e in EVENTS do frame:UnregisterEvent(e) end
	end
end

Quiver_Module_AutoShotTimer = {
	Id = MODULE_ID,
	Name = QUIVER_T.ModuleName[MODULE_ID],
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function()
		if (not isShooting) and (not isReloading) then tryHideBar() end
	end,
	OnInterfaceUnlock = function()
		if frame ~= nil then frame:SetAlpha(1) end
	end,
	OnResetFrames = function(trigger)
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.BarDirection = store.BarDirection or "LeftToRight"
		store.ColorShoot = store.ColorShoot or QUIVER.ColorDefault.AutoShotShoot
		store.ColorReload = store.ColorReload or QUIVER.ColorDefault.AutoShotReload
	end,
	OnSavedVariablesPersist = function() return store end,
	UpdateDirection = function()
		if frame then setBarAutoShot(frame) end
	end
}
