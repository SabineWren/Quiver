local Api = require "Api/Index.lua"
local Const = require "Constants.lua"
local FrameLock = require "Events/FrameLock.lua"
local Spellcast = require "Events/Spellcast.lua"
local BorderStyle = require "Modules/BorderStyle.provider.lua"
local Haste = require "Util/Haste.lua"
local Print = require "Util/Print.lua"

-- Auto Shot
local _AIMING_TIME = 0.5-- HSK, rais, and YaHT use 0.65. However, 0.5 seems better.
local MODULE_ID = "AutoShotTimer"
local store = nil---@type StoreAutoShotTimer
local frame = nil
local maxBarWidth = 0
-- Aimed Shot, Multi-Shot, Steady Shot
local castTime = 0
local isCasting = false
local isFiredInstant = false
local timeStartCastLocal = 0

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

local isReloading = false
local timeReload = (function()
	local reloadTime = 0
	local time = GetTime()
	local getElapsed = function() return GetTime() - time end
	return {
		GetPercentCompleted = function()
			local elapsed = getElapsed()
			if elapsed <= reloadTime then
				return elapsed / reloadTime
			else
				return 1.0
			end
		end,
		GetRemaining = function() return reloadTime - getElapsed() end,
		Reset = function() time = GetTime() end,
		---@param t number
		StartAt = function(t)
			time = t
			local speed, _, _, _, _, _ = UnitRangedDamage("player")
			isReloading = true
			reloadTime = speed - _AIMING_TIME
			Print.Debug("starting reload")
		end,
	}
end)()

local isShooting = false
local timeShoot = (function()
	local time = GetTime()
	local getElapsed = function() return GetTime() - time end
	return {
		GetPercentCompleted = function()
			local elapsed = getElapsed()
			if elapsed <= _AIMING_TIME then
				return elapsed / _AIMING_TIME
			else
				return 1.0
			end
		end,
		GetRemaining = function() return _AIMING_TIME - getElapsed() end,
		Reset = function() time = GetTime() end,
	}
end)()
-- May be called after reload while already shooting
local startShooting = function()
	if not isReloading then timeShoot.Reset() end
	isShooting = true
	position.UpdateXY()
end

local getIsConsumable = function(combatLogMsg)
	if combatLogMsg == nil then return false end
	for _i, v in ipairs(Quiver.L.CombatLog.Consumes) do
		local startPos, _ = string.find(combatLogMsg, v)
		if startPos then return true end
	end
	return false
end
local isConsumable = false

-- ************ UI ************
local styleBarAutoShot = function(f)
	local sizeInset = BorderStyle.GetInsetSize()

	if BorderStyle.GetStyle() == "Tooltip" then
		f:SetBackdrop({
			bgFile = "Interface/BUTTONS/WHITE8X8",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 10,
			insets = { left=sizeInset, right=sizeInset, top=sizeInset, bottom=sizeInset },
		})
		f:SetBackdropBorderColor(BorderStyle.GetColor())
	else
		f:SetBackdrop({
			bgFile = "Interface/BUTTONS/WHITE8X8",
			edgeFile = "Interface/BUTTONS/WHITE8X8",
			edgeSize = sizeInset,
		})
		f:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
	end
	f:SetBackdropColor(0, 0, 0, 0.8)

	-- Coerce to boolean because there's nothing sensible to do if we have an invalid value.
	if store.BarDirection == "LeftToRight" then
		f.BarAutoShot:ClearAllPoints()
		f.BarAutoShot:SetPoint("Left", f, "Left", sizeInset, 0)
	else
		f.BarAutoShot:ClearAllPoints()
		f.BarAutoShot:SetPoint("Center", f, "Center", 0, 0)
	end

	maxBarWidth = f:GetWidth() - 2 * sizeInset
	f.BarAutoShot:SetWidth(1)-- Must be > 0 or UI doesn't resize.
	f.BarAutoShot:SetHeight(f:GetHeight() - 2 * sizeInset)
end

local setFramePosition = function(f, s)
	FrameLock.SideEffectRestoreSize(s, {
		w=240, h=14, dx=240 * -0.5, dy=-136,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("HIGH")

	f.BarAutoShot = CreateFrame("Frame", nil, f)
	f.BarAutoShot:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		tile = false,
	})

	setFramePosition(f, store)
	styleBarAutoShot(f)

	FrameLock.SideEffectMakeMoveable(f, store)
	FrameLock.SideEffectMakeResizeable(f, store, {
		GripMargin=4,
		OnResizeDrag=function() styleBarAutoShot(f) end,
		OnResizeEnd=function() styleBarAutoShot(f) end,
		IsCenterX=true,
	})
	return f
end

-- ************ Frame Update Handlers ************
local updateBarShooting = function()
	frame:SetAlpha(1)
	local r, g, b = unpack(store.ColorShoot)
	frame.BarAutoShot:SetBackdropColor(r, g, b, 0.8)
	if isCasting then
		frame.BarAutoShot:SetWidth(1)
	else
		frame.BarAutoShot:SetWidth(maxBarWidth * timeShoot.GetPercentCompleted())
	end
end

local tryHideBar = function()
	if Quiver_Store.IsLockedFrames then
		frame:SetAlpha(0)
	else
		-- Reset bar if it's locked open
		frame.BarAutoShot:SetWidth(1)
		timeShoot.Reset()
		timeReload.Reset()
	end
end

local updateBarReload = function()
	frame:SetAlpha(1)
	local r, g, b = unpack(store.ColorReload)
	frame.BarAutoShot:SetBackdropColor(r, g, b, 0.8)
	local percentCompleted = timeReload.GetPercentCompleted()
	if percentCompleted < 1.0 then
		frame.BarAutoShot:SetWidth(maxBarWidth - maxBarWidth * percentCompleted)
	else
		Print.Debug("End reload")
		isReloading = false
		if isShooting then
			startShooting()
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
		-- We probably moved while shooting
		timeShoot.Reset()
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
--- @type Event[]
local _EVENTS = {
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
		if not isReloading then timeShoot.Reset() end
		Print.Debug("Stopped Casting")
	elseif event == "ITEM_LOCK_CHANGED" then
		-- Failed event means Stop, but we also dropped target before the cast finished.
		-- Two possibilities:
		-- 1 - Cast Start -> Lock -> Lock -> Cast Stop or Cast Failed
		--   - Cause: Auto Shot fired as cast started.
		--   - Action: Trigger reload and continue casting.
		-- 2 - Cast Start -> Lock         -> Cast Stop or Cast Failed
		--   - Cause: Cast completed.
		--   - Action: End casting.
		-- Case 1 happens immediately, while case 2 can't happen faster than the fastest cast.
		-- The cast start is latency-adjusted, so we pick a number between 0 and 0.5 (Multi-Shot cast time).
		-- Too high a threshold and multi-shot occasionally triggers reload when latency changes.
		-- Too low and we get stuck in a shooting state. This is much worse than an extra reload.
		-- 0.4 frequently trigger reloads over 100ms latency.
		local elapsed = GetTime() - timeStartCastLocal
		Print.Debug(elapsed)
		if (elapsed < 0.25) then
			-- We must have started the cast exactly as an auto shot fired.
			-- This happens when server lag causes the bar the skip.
			timeReload.StartAt(GetTime())
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
		-- There's a measurable 0.5 second reset to Auto Shot when casting any instant spell (ex. Hunter's Mark).
		-- Since auto shot also seems to use 0.5 second shoot time, we can reset it to 0.
		timeShoot.Reset()
	end

	if stateAuto.IsInitial then
	-- Handle first shot in sequence
		if event == "ITEM_LOCK_CHANGED" then
			if isFiredInstant then
				stateAuto.IsInitial = false
				stateAuto.TimeLock = GetTime()
				isFiredInstant = false
				Print.Debug("State Advance")
			elseif timeReload.GetRemaining() > 0 then
				-- Sometimes SPELLCAST_STOP triggers before ITEM_LOCK_CHANGED
				-- No-op from multi-shot during reload.
				Print.Debug("Edge case -- out-of-order events. Probably multi-shot: "..timeReload.GetRemaining())
			else
				Print.Debug("Auto Fired")
				timeReload.StartAt(GetTime())
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
			timeReload.StartAt(stateAuto.TimeLock)
			Print.Debug("State Reset: Auto -> Instant")
		elseif event == "SPELLCAST_STOP" then
			-- Previous shot must have been an instant, so reset state.
			stateAuto.IsInitial = true
			isFiredInstant = false
			Print.Debug("State Reset: Instant")
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
		if isFiredInstant then Print.Debug("Instant Shot") end
		isFiredInstant = false
	end
end

---@param nameEnglish string
---@param nameLocalized string
local onSpellcast = function(nameEnglish, nameLocalized)
	-- User can spam the ability while it's already casting
	if not isCasting then
		isCasting = true
		local _latAdjusted
		castTime, _latAdjusted, timeStartCastLocal = Haste.CalcCastTime(nameEnglish)
		Print.Debug("Start Cast")
	end
end

local handleEvent = function()
	local e = event
	-- ************ Event logic independant of state ************
	if e == "CHAT_MSG_SPELL_SELF_BUFF" then
		isConsumable = getIsConsumable(arg1)
	elseif e == "START_AUTOREPEAT_SPELL" then
		Print.Debug("Start shooting")
		startShooting()
	elseif e == "STOP_AUTOREPEAT_SPELL" then
		Print.Debug("Stop shooting")
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
---@return boolean
---@nodiscard
local PredMidShot = function()
	return isShooting and not isReloading
end

local GetSecondsRemainingReload = function()
	if isReloading then
		return true, timeReload.GetRemaining()
	else
		return false, 0
	end
end

local GetSecondsRemainingShoot = function()
	local t = timeShoot.GetRemaining()
	local isFiring = isShooting and not isReloading
	if isFiring then
		return true, t
	else
		return false, 0
	end
end

-- ************ Initialization ************
local onEnable = function()
	if frame == nil then
		frame = createUI()
	end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _i, v in ipairs(_EVENTS) do frame:RegisterEvent(v) end
	if Quiver_Store.IsLockedFrames then frame:SetAlpha(0) else frame:SetAlpha(1) end
	BorderStyle.Subscribe(MODULE_ID, function(_style)
		if frame ~= nil then styleBarAutoShot(frame) end
	end)
	Spellcast.CastableShot.Subscribe(MODULE_ID, onSpellcast)
	Spellcast.Instant.Subscribe(MODULE_ID, function(spellName)
		isFiredInstant = Api.Spell.PredInstantShot(spellName)
	end)
	frame:Show()
end

local onDisable = function()
	Spellcast.Instant.Dispose(MODULE_ID)
	Spellcast.CastableShot.Dispose(MODULE_ID)
	BorderStyle.Dispose(MODULE_ID)
	if frame ~= nil then
		frame:Hide()
		for _i, v in ipairs(_EVENTS) do frame:UnregisterEvent(v) end
	end
end

---@type QqModule
return {
	Id = MODULE_ID,
	GetName = function() return Quiver.T["Auto Shot Timer"] end,
	GetTooltipText = function() return nil end,
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
		if frame then
			setFramePosition(frame, store)
			styleBarAutoShot(frame)
		end
	end,
	---@param savedVariables StoreAutoShotTimer
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.BarDirection = savedVariables.BarDirection or "LeftToRight"
		store.ColorShoot = savedVariables.ColorShoot or Const.ColorDefault.AutoShotShoot
		store.ColorReload = savedVariables.ColorReload or Const.ColorDefault.AutoShotReload
	end,
	OnSavedVariablesPersist = function() return store end,
	UpdateDirection = function()
		if frame then styleBarAutoShot(frame) end
	end,
	-- API exports
	GetSecondsRemainingReload = GetSecondsRemainingReload,
	GetSecondsRemainingShoot = GetSecondsRemainingShoot,
	PredMidShot = PredMidShot,
}
