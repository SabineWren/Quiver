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
local timeStartShooting = GetTime()
local timeStartReloading = GetTime()

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
	local timePassed = GetTime() - timeStartShooting
	if isCasting then
		frame.BarAutoShot:SetWidth(1)-- Can't set to zero
	elseif timePassed <= AIMING_TIME then
		frame.BarAutoShot:SetWidth(maxBarWidth * timePassed / AIMING_TIME)
	else
		frame.BarAutoShot:SetWidth(maxBarWidth)
	end
end

---@param time number
local startReloading = function(time)
	if not isReloading then
		timeStartReloading = time
		log("starting reload")
	end
	isReloading = true
	reloadTime = UnitRangedDamage("player") - AIMING_TIME
end

local startShooting = function()
	if not isReloading then timeStartShooting = GetTime() end
	isShooting = true
	position.UpdateXY()
end

local tryHideBar = function()
	if Quiver_Store.IsLockedFrames then
		frame:SetAlpha(0)
	else
		-- Reset bar if it's locked open
		frame.BarAutoShot:SetWidth(1)
		timeStartShooting = GetTime()
		timeStartReloading = GetTime()
	end
end

local updateBarReload = function()
	frame:SetAlpha(1)
	local r, g, b = unpack(store.ColorReload)
	frame.BarAutoShot:SetBackdropColor(r, g, b, 0.8)
	local timePassed = GetTime() - timeStartReloading
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
		timeStartShooting = GetTime()
		tryHideBar()
	end
end

--[[ ************ Event Handlers ************
1. Instant Shot while either moving or in middle of reload
-> (hook) OnInstant
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
2. Instant Shot as Auto Shot fires
-> (hook) OnInstant
-> ITEM_LOCK_CHANGED
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
3. Casted Shot starts as Auto Shot fires
-> (hook) OnCast
-> ITEM_LOCK_CHANGED
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
4. Auto Shot -> Casted Shot -> Instant Shot -> Auto Shot
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
	-- Fires after SPELLCAST_STOP, but before ITEM_LOCK_CHANGED.
	-- Use to ignore whitelisted inventory events corresponding to consumables.
	"CHAT_MSG_SPELL_SELF_BUFF",
	-- Inventory event, such as using ammo or drinking a potion.
	-- This is how we detect auto shots.
	"ITEM_LOCK_CHANGED",
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
local handleEventStateCasting = function(event, arg1)
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
		isFiredInstant = false
		isCasting = false -- Exit this handler
		if not isReloading then timeStartShooting = GetTime() end
		log("Stopped Casting")
	elseif event == "ITEM_LOCK_CHANGED" then
		-- Two possibilities:
		-- 1 - Auto Shot fired as cast started. (Cast -> lock -> lock -> Cast Stop)
		-- 2 - Cast Fired. A stop or failed event will follow, or failed event when target dropped.
		-- For case 1, confirm plausible timing.
		-- The fastest possible cast (multi-shot) takes 0.5 seconds,
		-- so we can use any number between that and zero.
		-- For case 2, wait for the stop / fail event.
		local elapsed = GetTime() - timeStartCastLocal
		log(elapsed)
		if (elapsed < 0.4) then
			-- We must have started the cast exactly as an auto shot fired.
			-- This happens when server lag causes the bar the skip.
			startReloading(GetTime())
		end
	end
end

-- Two cases to handle.
-- Case 1: Auto -> Instant
-- Instant -> Lock -> Lock -> Stop
-- Csae 2: Instant -> Auto
-- Instant -> Lock -> Stop -> Lock
-- There's no way to know whether or not to start the reload at first lock, so we save
-- the reload time and apply it retroactively. This requires its own Mealy machine.
local stateAuto = { IsInitial=true, TimeLock=0 }
---@param event string
local handleEventStateShooting = function(event)
	-- Don't have to handle other spellcast events because they only trigger on successful
	-- casts without a selected target. However, dropping target cancels Auto Shot.
	if event == "SPELLCAST_STOP" then
		-- There's a measurable 0.5 second reset to Auto Shot when casting any instant spell (ex. Hunter's Mark)
		-- Can ignore this if our remaining time is longer than that reset.
		local aimTimeOffset = AIMING_TIME - 0.5
		if (GetTime() - timeStartShooting > aimTimeOffset) then
			timeStartShooting = GetTime() - aimTimeOffset
		end
	end

	if stateAuto.IsInitial then
	-- Handle first shot in sequence
		if event == "ITEM_LOCK_CHANGED" then
			if isFiredInstant then
				stateAuto.IsInitial = false
				stateAuto.TimeLock = GetTime()
				isFiredInstant = false
				log("State Advance")
			else
				log("Auto Fired")
				startReloading(GetTime())
			end
		end
		-- else ignore
	else
	-- Handle second shot in sequence
		if event == "ITEM_LOCK_CHANGED" then
			-- Fired another shot, meaning the first one must have been an auto.
			-- Retroactively start reload and reset state.
			stateAuto.IsInitial = true
			isFiredInstant = false
			startReloading(stateAuto.TimeLock)
			log("State Reset: Auto -> Instant")
		elseif event == "SPELLCAST_STOP" then
			-- Previous shot must have been an instant, so reset state.
			stateAuto.IsInitial = true
			isFiredInstant = false
			log("State Reset: Instant")
		end
		-- else ignore
	end
end

---@param event string
local handleEventStateIdle = function(event)
	if
		event == "SPELLCAST_STOP"
		or event == "SPELLCAST_FAILED"
		or event == "SPELLCAST_INTERRUPTED"
	then
		if isFiredInstant then log("Instant Shot") end
		isFiredInstant = false
	end
end

local onSpellcast = function(spellName)
	-- User can spam the ability while it's already casting
	if isCasting then return end
	isCasting = true
	local _latAdjusted
	castTime, _latAdjusted, timeStartCastLocal = Quiver_Lib_Spellbook_CalcCastTime(spellName)
	log("Start Cast")
end

local handleEvent = function()
	local e = event
	if (e ~= "CHAT_MSG_SPELL_SELF_BUFF") then
		local t1 = isCasting and "casting" or "false"
		local t2 = stateAuto.IsInitial and "initial" or "advanced"
		log(t1.." "..t2.." "..e)
	end
	-- ************ Event logic independant of state ************
	if e == "CHAT_MSG_SPELL_SELF_BUFF" then
		isConsumable = getIsConsumable(arg1)
	elseif e == "START_AUTOREPEAT_SPELL" then
		log("Start shooting")
		startShooting()
	elseif e == "STOP_AUTOREPEAT_SPELL" then
		log("Stop shooting")
		isShooting = false
	elseif isConsumable and e == "ITEM_LOCK_CHANGED" then
		isConsumable = false-- We drank a potion or something, so don't run any handlers
	-- ************ Mealy machine states ************
	elseif isCasting then
		handleEventStateCasting(e, arg1)
	elseif isShooting then
		handleEventStateShooting(e)
	else
		handleEventStateIdle(e)
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
	OnResetFrames = function()
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
