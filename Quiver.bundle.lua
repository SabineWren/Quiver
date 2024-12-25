local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(nil)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local LoadLocale = require("Locale/Lang.lua")
local MainMenu = require("Config/MainMenu.lua")
local Migrations = require("Migrations/Runner.lua")
local AspectTracker = require("Modules/Aspect_Tracker/AspectTracker.lua")
local AutoShotTimer = require("Modules/Auto_Shot_Timer/AutoShotTimer.lua")
local Castbar = require("Modules/Castbar.lua")
local RangeIndicator = require("Modules/RangeIndicator.lua")
local TranqAnnouncer = require("Modules/TranqAnnouncer.lua")
local TrueshotAuraAlarm = require("Modules/TrueshotAuraAlarm.lua")
local UpdateNotifierInit = require("Modules/UpdateNotifier.lua")
local RegisterGlobalFunctions = require("GlobalFunctions.lua")

_G = _G or getfenv()
Quiver = Quiver or {}
_G.Quiver_Modules = {
	AspectTracker,
	AutoShotTimer,
	Castbar,
	RangeIndicator,
	TranqAnnouncer,
	TrueshotAuraAlarm,
}

local savedVariablesRestore = function()
	-- If first time running Quiver, then savedVars are nil, so make defaults
	Quiver_Store.IsLockedFrames = Quiver_Store.IsLockedFrames == true
	Quiver_Store.ModuleEnabled = Quiver_Store.ModuleEnabled or {}
	Quiver_Store.ModuleStore = Quiver_Store.ModuleStore or {}
	Quiver_Store.DebugLevel = Quiver_Store.DebugLevel or "None"
	Quiver_Store.Border_Style = Quiver_Store.Border_Style or "Simple"
	for _k, v in _G.Quiver_Modules do
		Quiver_Store.ModuleEnabled[v.Id] = Quiver_Store.ModuleEnabled[v.Id] ~= false
		Quiver_Store.ModuleStore[v.Id] = Quiver_Store.ModuleStore[v.Id] or {}
		-- Loading saved variables into each module gives them a chance to set their own defaults.
		v.OnSavedVariablesRestore(Quiver_Store.ModuleStore[v.Id])
	end
end
local savedVariablesPersist = function()
	for _k, v in _G.Quiver_Modules do
		Quiver_Store.ModuleStore[v.Id] = v.OnSavedVariablesPersist()
	end
end

local initSlashCommandsAndModules = function()
	SLASH_QUIVER1 = "/qq"
	SLASH_QUIVER2 = "/quiver"
	local _, cl = UnitClass("player")
	if cl == "HUNTER" then
		local frameConfigMenu = MainMenu.Create("QuiverConfigDialog")
		Api.Aero.RegisterFrame(frameConfigMenu)

		SlashCmdList["QUIVER"] = function(_args, _box) frameConfigMenu:Show() end
		for _k, v in _G.Quiver_Modules do
			if Quiver_Store.ModuleEnabled[v.Id] then v.OnEnable() end
		end
	else
		SlashCmdList["QUIVER"] = function() DEFAULT_CHAT_FRAME:AddMessage(Quiver.T["Quiver is for hunters."], 1, 0.5, 0) end
	end
end

--[[
-- https://wowpedia.fandom.com/wiki/AddOn_loading_process
-- Addon load alphabetically (affected by color characters)
1 - ADDON_LOADED Fires each time any addon can load variables (arg1 = addon name) (can't yet print to pfUI chat frame)
2 - VARIABLES_LOADED Fires once after variables are available to all addons
3 - PLAYER_LOGIN Fires once, but can't yet read talent tree
]]
local frame = CreateFrame("Frame", nil)
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function()
	if event == "VARIABLES_LOADED" then
		LoadLocale()-- Must run before everything else
		Migrations()-- Modifies saved variables
		savedVariablesRestore()-- Passes saved data to modules for init
		initSlashCommandsAndModules()
		RegisterGlobalFunctions()
	elseif event == "PLAYER_LOGIN" then
		UpdateNotifierInit()
	elseif event == "PLAYER_LOGOUT" then
		savedVariablesPersist()
	end
end)

end)
__bundle_register("GlobalFunctions.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local AutoShotTimer = require("Modules/Auto_Shot_Timer/AutoShotTimer.lua")

---@param spellName string
---@return nil
local CastNoClip = function(spellName)
	if not AutoShotTimer.PredMidShot() then
		CastSpellByName(spellName)
	end
end

---@param actionName string
---@return nil
local CastPetActionByName = function(actionName)
	-- local hasSpells = HasPetUI()
	-- local hasUI = HasPetUI()
	if GetPetActionsUsable() then
		Api.Pet.CastActionByName(actionName)
	end
end

---@param spellNameLocalized string
local predOffCd = function(spellNameLocalized)
	local index = Api.Spell.FindSpellIndex(spellNameLocalized)
	if index ~= nil then
		local timeStartCd, _ = GetSpellCooldown(index, BOOKTYPE_SPELL)
		return timeStartCd == 0
	else
		return false
	end
end

-- Casts feign death (if needed) and sets pet passive (if needed).
-- Usage:
-- /cast Frost Trap
-- /script Quiver.FdPrepareTrap()
local FdPrepareTrap = function()
	-- Requires level 16, which makes it the lowest level trap
	local trap = Quiver.L.Spell["Immolation Trap"]
	local fd = Quiver.L.Spell["Feign Death"]
	if UnitAffectingCombat("player") and predOffCd(trap) and predOffCd(fd) then
		if UnitExists("pettarget") and UnitAffectingCombat("pet") then
			PetPassiveMode()
			PetFollow()
		end
		CastSpellByName(fd)
	end
end

return function()
	Quiver.CastNoClip = CastNoClip
	Quiver.CastPetAction = CastPetActionByName
	Quiver.FdPrepareTrap = FdPrepareTrap
	Quiver.GetSecondsRemainingReload = AutoShotTimer.GetSecondsRemainingReload
	Quiver.GetSecondsRemainingShoot = AutoShotTimer.GetSecondsRemainingShoot
	Quiver.PredMidShot = AutoShotTimer.PredMidShot
end

end)
__bundle_register("Modules/Auto_Shot_Timer/AutoShotTimer.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local Const = require("Constants.lua")
local FrameLock = require("Events/FrameLock.lua")
local Spellcast = require("Events/Spellcast.lua")
local BorderStyle = require("Modules/BorderStyle.provider.lua")
local Haste = require("Util/Haste.lua")
local Print = require("Util/Print.lua")

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
	for _k, v in Quiver.L.CombatLog.Consumes do
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
	for _k, e in _EVENTS do frame:RegisterEvent(e) end
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
		for _k, e in _EVENTS do frame:UnregisterEvent(e) end
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

end)
__bundle_register("Util/Print.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local danger = function(text) DEFAULT_CHAT_FRAME:AddMessage(text, 1, 0, 0) end
local neutral = function(text) DEFAULT_CHAT_FRAME:AddMessage(text) end
local success = function(text) DEFAULT_CHAT_FRAME:AddMessage(text, 0, 1, 0) end
local warning = function(text) DEFAULT_CHAT_FRAME:AddMessage(text, 1, 0.6, 0) end

--- @param text string
--- @return nil
local logVerbose = function(text)
	if Quiver_Store.DebugLevel == "Verbose" then
		DEFAULT_CHAT_FRAME:AddMessage(text)
	end
end

local PrintLine = {
	Danger = function(text) danger("Quiver -- " .. text) end,
	Neutral = function(text) neutral("Quiver -- " .. text) end,
	Success = function(text) success("Quiver -- " .. text) end,
	Warning = function(text) warning("Quiver -- " .. text) end,
	-- BigWigs suppresses raid messages unless you guarantee
	-- they don't match its spam filter. Adding a space works.
	-- https://github.com/CosminPOP/BigWigs/issues/2
	Raid = function(text) SendChatMessage(text.." ", "RAID") end,
	Say = function(text) SendChatMessage(text, "SAY") end,
}

local PrintPrefixedF = function(callerName)
	local noNil = function(text) return text or "nil" end
	local prefix = "Quiver ["..callerName.."] -- "
	return {
		Danger = function(text) danger(prefix..noNil(text)) end,
		Neutral = function(text) neutral(prefix..noNil(text)) end,
		Success = function(text) success(prefix..noNil(text)) end,
		Warning = function(text) warning(prefix..noNil(text)) end,
	}
end

return {
	Debug = logVerbose,
	Error = logVerbose,
	Line = PrintLine,
	PrefixedF = PrintPrefixedF,
}

end)
__bundle_register("Util/Haste.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
-- This file would be API extension code, except that it only supports
-- hunter casts. I have no idea how to compute haste for non-hunter spells.
local Api = require("Api/Index.lua")
local L = require("Lib/Index.lua")

-- GetInventoryItemLink("Player", slot#) returns a link, ex. [name]
-- <br>Weapon name always appears at line TextLeft1
-- <br>ex. "Speed 3.2", but avoid matching on localized portions of text.
-- <br>If nil, something went wrong. Maybe there's no ranged weapon equipped.
---@return nil|integer
local scanRangedWeaponSpeed = function()
	return Api.Tooltip.Scan(function(tooltip)
		tooltip:ClearLines()
		local _, _, _ = tooltip:SetInventoryItem("player", Api.Enum.INVENTORY_SLOT.Ranged)
		return L.Array.GenerateFirst(
			tooltip:NumLines(),
			L.Flow(
				function(i) return Api.Tooltip.GetText("TextRight", i) end,
				L.Nil.Bind(function(text)
					local _, _, speed = string.find(text, "(%d+%.%d+)")
					return speed
				end),
				L.Nil.Bind(tonumber)
			)
		)
	end)
end

---@param nameEnglish string
---@return number casttime
---@return number startLatAdjusted
---@return number startLocal
---@nodiscard
local CalcCastTime = function(nameEnglish)
	local meta = Api.Spell.Db[nameEnglish]
	local _,_, msLatency = GetNetStats()
	local startLocal = GetTime()
	local startLatAdjusted = startLocal + msLatency / 1000

	-- No spell metadata means it's not a spell we care about. Assume instant.
	if meta == nil then
		return 0, startLatAdjusted, startLocal
	elseif meta.Haste == "range" then
		local speedCurrent, _, _ , _, _, _ = UnitRangedDamage("player")
		local speedWeapon = L.Nil.GetOr(scanRangedWeaponSpeed(), speedCurrent)
		local speedMultiplier = speedCurrent / speedWeapon
		-- https://www.mmo-champion.com/content/2188-Patch-4-0-6-Feb-22-Hotfixes-Blue-Posts-Artworks-Comic
		local casttime = (meta.Offset + meta.Time * speedMultiplier) / 1000
		return casttime, startLatAdjusted, startLocal
	elseif meta.Haste == "none" then
		return 0, startLatAdjusted, startLocal
	else
		-- LuaLS type narrows on objects, but not literals
		-- https://github.com/LuaLS/lua-language-server/pull/2864
		-- https://github.com/LuaLS/lua-language-server/issues/704
		-- Even when narrowing, it doesn't support exhaustive checks (no issue).
		-- The best we can do is provide some debug output for QA.
		DEFAULT_CHAT_FRAME:AddMessage("Failed exhaustive check", 1, 1, 0)
		DEFAULT_CHAT_FRAME:AddMessage(meta.Haste, 1, 1, 0)
		return 0, startLatAdjusted, startLocal
	end
end

return {
	CalcCastTime = CalcCastTime,
}

end)
__bundle_register("Lib/Index.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Array = require("Lib/Array.lua")
local Color = require("Lib/Color.lua")
local Nil = require("Lib/Nil.lua")

local Lib = {}
Lib.Array = Array
Lib.Color = Color
Lib.Nil = Nil

-- ************ Combinators ************
-- Reference library:
-- https://github.com/codereport/blackbird/blob/main/combinators.hpp

--- (>>), forward function composition, pipe without application
---@generic A
---@generic B
---@generic C
---@generic D
--@type fun(f: (fun(a: A): B), g: (fun(b: B): C)): fun(a: A): C
---@type fun(f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): fun(a: A): D
Lib.Flow = function(...)
	local functions = arg
	return function(a)
		local out = a
		for _, fn in ipairs(functions) do
			out = fn(out)
		end
		return out
	end
end

-- No support yet for generic overloads
-- https://github.com/LuaLS/lua-language-server/issues/723
--
-- I tried this using an external definition file instead of using @overload.
-- That partially works, as call sites select the correct overload.
-- However, generic type inference doesn't improve, and I don't think
-- a class can mix external type definitions with internal definitions.
---@generic A
---@generic B
---@generic C
---@type fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C)): C
--@type fun(a: A, f: (fun(a: A): B)): B
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C)): C
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): D
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D), i: (fun(d: D): E)): D
Lib.Pipe = function(a, ...)
	local out = a
	for _, fn in ipairs(arg) do
		out = fn(out)
	end
	return out
end

--- f(g(x), (y))
---@generic A
---@generic B
---@generic C
---@type fun(f: (fun(x: B, y: B): C), g: (fun(x: A): B), x: A, y: A): C
---@nodiscard
Lib.Psi = function(f, g, x, y)
	return f(g(x), g(y))
end

-- ************ Operators ************
-- ************ Binary / Unary ************
---@type fun(a: number, b: number): number
---@nodiscard
Lib.Add = function(a, b) return a + b end

---@type fun(a: number, b: number): number
---@nodiscard
Lib.Max = function(a, b) return math.max(a, b) end

return Lib

end)
__bundle_register("Lib/Nil.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Nil = {}

---@generic A
---@generic B
---@param f fun(i: A): nil|B
---@return fun(a: nil|A): nil|B
---@nodiscard
Nil.Bind = function(f)
	---@generic A
	---@generic B
	---@param x nil|A
	---@return nil|B
	---@nodiscard
	return function(x)
		if x == nil then return x else return f(x) end
	end
end

---@generic A
---@param x nil|A
---@param fallback A
---@return A
---@nodiscard
Nil.GetOr = function(x, fallback)
	if x == nil then return fallback else return x end
end

---@generic A
---@generic B
---@param f fun(i: A): B
---@return fun(a: nil|A): nil|B
---@nodiscard
Nil.Map = function(f)
	---@generic A
	---@generic B
	---@param x nil|A
	---@return nil|B
	---@nodiscard
	return function(x)
		if x == nil then return x else return f(x) end
	end
end

return Nil

end)
__bundle_register("Lib/Color.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
---@alias Rgb [number, number, number]

---@class (exact) Color
---@field private __index? Color
---@field private cache Rgb
---@field private default Rgb
local Color = {}

---@param store Rgb
---@return Color
function Color:Lift(store)
	local default = { store[1], store[2], store[3] }
	---@type Color
	local o = { cache=store, default=default }
	setmetatable(o, self)
	self.__index = self
	return o
end

---@param store Rgb
---@param default Rgb
---@return Color
function Color:LiftReset(store, default)
	---@type Color
	local o = { cache=store, default=default }
	setmetatable(o, self)
	self.__index = self
	return o
end

function Color:Reset()
	self.cache[1] = self.default[1]
	self.cache[2] = self.default[2]
	self.cache[3] = self.default[3]
end

---@return number, number, number
---@nodiscard
function Color:Rgb()
	local c = self.cache
	return c[1], c[2], c[3]
end

---@return [number, number, number]
---@nodiscard
function Color:RgbArray()
	local c = self.cache
	return { c[1], c[2], c[3] }
end

function Color:R() return self.cache[1] end
function Color:G() return self.cache[2] end
function Color:B() return self.cache[3] end

---@param r number 0 to 1
---@param g number 0 to 1
---@param b number 0 to 1
function Color:SetRgb(r, g, b)
	self.cache[1] = r
	self.cache[2] = g
	self.cache[3] = b
end

return Color

end)
__bundle_register("Lib/Array.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class Array
local Array = {}

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return boolean
---@nodiscard
Array.Every = function(xs, f)
	for _k, v in ipairs(xs) do
		if not f(v) then return false end
	end
	return true
end

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return nil|A
---@nodiscard
Array.Find = function(xs, f)
	for _k, v in ipairs(xs) do
		if f(v) then
			return v
		end
	end
	return nil
end

--- Array.Iota n 1 |> Array.Collect f |> Array.Head
--- - Does not allocate an intermediate array.
---@generic A
---@param n integer
---@param f fun(i: integer): nil|A
---@return nil|A
---@nodiscard
Array.GenerateFirst = function(n, f)
	for i=1, n do
		local x = f(i)
		if x ~= nil then
			return x
		end
	end
	return nil
end

---Since arrays are actually tables, Lua doesn't guarantee consistent indexing.
---@generic A
---@param xs A[]
---@return nil|A
---@nodiscard
Array.Head = function(xs)
	for _k, v in ipairs(xs) do
		return v
	end
	return nil
end

---ϴ(N)
---@generic A
---@param xs A[]
---@return integer
---@nodiscard
Array.Length = function(xs)
	local l = 0
	for _k, _v in ipairs(xs) do l = l + 1 end
	return l
end

---@generic A
---@generic B
---@param xs A[]
---@param f fun(x: A): B
---@return B[]
---@nodiscard
Array.Map = function(xs, f)
	local ys = {}
	for _k, v in ipairs(xs) do
		table.insert(ys, f(v))
	end
	return ys
end

---@generic A
---@generic B
---@param xs A[]
---@param f fun(x: A, i: integer): B
---@return B[]
---@nodiscard
Array.Mapi = function(xs, f)
	local ys = {}
	local i = 0
	for _k, v in ipairs(xs) do
		table.insert(ys, f(v, i))
		i = i + 1
	end
	return ys
end

--- ϴ(1) memory allocation<br>
--- ϴ(N) runtime complexity
---@generic A
---@generic B
---@param xs A[]
---@param f fun(a: A): B
---@param reducer fun(b1: B, b2: B): B
---@param identity B
---@return B
---@nodiscard
Array.MapReduce = function(xs, f, reducer, identity)
	local zRef = identity
	for _k, x in ipairs(xs) do
		zRef = reducer(f(x), zRef)
	end
	return zRef
end

--- Map f >> Intercalate x >> Reduce (+)
--- <br>@link https://typeclasses.com/featured/intercalate
--- <br>@link https://en.wiktionary.org/wiki/intercalate
--- - ϴ(1) memory allocation
--- - ϴ(N) runtime complexity
---@generic A
---@param xs A[]
---@param f fun(a: A): number
---@param calate number
---@return number
---@nodiscard
Array.MapIntercalateSum = function(xs, f, calate)
	local id = 0
	if Array.Head(xs) == nil then
		return id
	else
		local add = function(a, b) return a + b end
		return Array.MapReduce(xs, f, add, id) + calate * (Array.Length(xs) - 1)
	end
end

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return boolean
---@nodiscard
Array.Some = function(xs, f)
	for _k, v in ipairs(xs) do
		if f(v) then return true end
	end
	return false
end

---@param xs number[]
---@return number
---@nodiscard
Array.Sum = function(xs)
	local total = 0
	for _k, v in ipairs(xs) do
		total = total + v
	end
	return total
end

--- ϴ(1) memory allocation<br>
--- ϴ(N) runtime complexity
---@generic A
---@generic B
---@param xs A[]
---@param reducer fun(b1: B, b2: B): B
---@param identity B
---@return B
---@nodiscard
Array.Reduce = function(xs, reducer, identity)
	local zRef = identity
	for _k, x in ipairs(xs) do
		zRef = reducer(x, zRef)
	end
	return zRef
end

---@generic A
---@generic B
---@param as A[]
---@param bs B[]
---@return [A,B][]
---@nodiscard
Array.Zip2 = function(as, bs)
	local zipped = {}
	local l1, l2 = Array.Length(as), Array.Length(bs)
	if l1 ~= l2 then
		DEFAULT_CHAT_FRAME:AddMessage("Warning -- Called Zip2 on arrays of unequal length.", 1.0, 0.5, 0)
		DEFAULT_CHAT_FRAME:AddMessage(l1 .. " <> " .. l2, 1.0, 0, 0)
	end
	local length = math.min(l1, l2)
	for i=1, length do
		zipped[i] = { as[i], bs[i] }
	end
	return zipped
end

return Array

end)
__bundle_register("Api/Index.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Action = require("Api/Action.lua")
local Aero = require("Api/Aero.lua")
local Aura = require("Api/Aura.lua")
local Enum = require("Api/Enum.lua")
local Pet = require("Api/Pet.lua")
local Spell = require("Api/Spell.lua")
local Tooltip = require("Api/Tooltip.lua")

-- Elm and FSharp use underscore syntax for sugaring property getters.
return {
	Action = Action,
	Aero = Aero,
	Aura = Aura,
	Enum = Enum,
	Pet = Pet,
	Spell = Spell,
	Tooltip = Tooltip,
	-- ************ Region ************
	--- @type fun(r: Region): number
	_Height = function(r) return r:GetHeight() end,

	--- @type fun(r: Region): number
	_Width = function(r) return r:GetWidth() end,

	-- ************ Button ************
	--- @type fun(r: Button): FontString
	_FontString = function(r) return r:GetFontString() end,
}

end)
__bundle_register("Api/Tooltip.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local L = require("Lib/Index.lua")

-- TODO figure out how to let caller specify preferred side, then
-- flip if there isn't enough room for tooltip. This is hard because
-- we don't know how big the tooltip is until after rendering it.
---@param anchor Frame
---@param x? number
---@param y? number
---@return nil
local Position = function(anchor, x, y)
	local screenW = GetScreenWidth()
	local center = screenW / 2.0

	local closestAnchorSide = L.Psi(
		function(a, b) return a < b and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_BOTTOMLEFT" end,
		function(a) return math.abs(center - a) end,
		L.Nil.GetOr(anchor:GetLeft(), 0),
		L.Nil.GetOr(anchor:GetRight(), screenW)
	)

	local xx = L.Nil.GetOr(x, 0)
	local yy = L.Nil.GetOr(y, 0) + anchor:GetHeight()
	GameTooltip:SetOwner(anchor, closestAnchorSide, xx, yy)
end

--- Creates a scanning tooltip for later use
---@param name string Name of global tooltip frame
---@return GameTooltip
---@nodiscard
local createTooltip = function(name)
	local tt = CreateFrame("GameTooltip", name, nil, "GameTooltipTemplate")
	tt:SetScript("OnHide", function() tt:SetOwner(WorldFrame, "ANCHOR_NONE") end)
	tt:Hide()
	tt:SetFrameStrata("TOOLTIP")
	return tt
end

-- ************ Scanning ************
local _TOOLTIP_NAME = "QuiverScanningTooltip"
local tooltip = createTooltip(_TOOLTIP_NAME)

---@param fsName "TextLeft" | "TextRight"
---@param lineNumber integer
---@return nil|string
local GetText = function(fsName, lineNumber)
	---@type nil|FontString
	local fs = _G[_TOOLTIP_NAME .. fsName .. lineNumber]
	return fs and fs:GetText()
end

--- Handles setup and teardown when scanning.
---@generic Output
---@param f fun(t: GameTooltip): Output
---@return Output
---@nodiscard
local Scan = function(f)
	tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	local output = f(tooltip)
	tooltip:Hide()
	return output
end

return {
	GetText = GetText,
	Position = Position,
	Scan = Scan,
}

end)
__bundle_register("Api/Spell.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class SpellMetaAll
---@field Class CharacterClass
---@field Icon string

---@class SpellMetaCastedShot: SpellMetaAll
---@field Haste "range"
---@field IsAmmo true
---@field Time integer
---@field Offset integer

---@class SpellMetaInstantShot: SpellMetaAll
---@field Haste "none"
---@field IsAmmo true

-- Data is fully denormalized since we don't have a database.
-- This will probably cause maintenance problems.
local DB_SPELL = {
	-- Casted Shots
	["Aimed Shot"]={ Class="HUNTER", Time=3000, Offset=500, Haste="range", Icon="INV_Spear_07", IsAmmo=true },---@type SpellMetaCastedShot
	["Multi-Shot"]={ Class="HUNTER", Time=0, Offset=500, Haste="range", Icon="Ability_UpgradeMoonGlaive", IsAmmo=true },---@type SpellMetaCastedShot
	["Steady Shot"]={ Class="HUNTER", Time=1000, Offset=500, Haste="range", Icon="Ability_Hunter_SteadyShot", IsAmmo=true },---@type SpellMetaCastedShot

	-- Instant Shots
	["Arcane Shot"]={ Class="HUNTER", Haste="none", Icon="Ability_ImpalingBolt", IsAmmo=true },---@type SpellMetaInstantShot
	["Concussive Shot"]={ Class="HUNTER", Haste="none", Icon="Spell_Frost_Stun", IsAmmo=true },---@type SpellMetaInstantShot
	["Scatter Shot"]={ Class="HUNTER", Haste="none", Icon="Ability_GolemStormBolt", IsAmmo=true },---@type SpellMetaInstantShot
	["Scorpid Sting"]={ Class="HUNTER", Haste="none", Icon="Ability_Hunter_CriticalShot", IsAmmo=true },---@type SpellMetaInstantShot
	["Serpent Sting"]={ Class="HUNTER", Haste="none", Icon="Ability_Hunter_Quickshot", IsAmmo=true },---@type SpellMetaInstantShot
	["Viper Sting"]={ Class="HUNTER", Haste="none", Icon="Ability_Hunter_AimedShot", IsAmmo=true },---@type SpellMetaInstantShot
	["Wyvern Sting"]={ Class="HUNTER", Haste="none", Icon="INV_Spear_02", IsAmmo=true },---@type SpellMetaInstantShot
}

---@param spellName string
---@return nil|integer spellIndex
local FindSpellIndex = function(spellName)
	local numTabs = GetNumSpellTabs()
	local _, _, tabOffset, numEntries = GetSpellTabInfo(numTabs)
	local numSpells = tabOffset + numEntries
	for spellIndex=1, numSpells do
		local name, _rank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
		if name == spellName then
			return spellIndex
		end
	end
	return nil
end

--- This assumes the texture uniquely identifies a spell, which may not be true.
---@param texturePath string
---@return nil|string spellName
---@return nil|integer spellIndex
---@nodiscard
local FindSpellByTexture = function(texturePath)
	local i = 0
	while true do
		i = i + 1
		local t = GetSpellTexture(i, BOOKTYPE_SPELL)
		local name, _rank = GetSpellName(i, BOOKTYPE_SPELL)
		if not t or not name then
			break-- Base Case
		elseif t == texturePath then
			return name, i
		end
	end
	return nil, nil
end

--- Returns true if spell is instant cast. If nil, assume instant.
---@param name string
---@return boolean
---@nodiscard
local PredInstantCast = function(name)
	local meta = DB_SPELL[name]
	if meta == nil then
		return true
	else
		return meta.Haste == "none"
	end
end

---@param name string
---@return boolean
---@nodiscard
local PredInstantShot = function(name)
	local meta = DB_SPELL[name]
	return meta ~= nil and meta.IsAmmo and PredInstantCast(name)
end

---@param spellName string
---@return boolean
---@nodiscard
local PredSpellLearned = function(spellName)
	local i = 0
	while true do
		i = i + 1
		local name, _rank = GetSpellName(i, BOOKTYPE_SPELL)
		if not name then return false
		elseif name == spellName then return true
		end
	end
end

local CheckNewCd = function(cooldown, lastCdStart, spellName)
	local spellIndex = FindSpellIndex(spellName)
	if spellIndex ~= nil then
		local timeStartCD, durationCD = GetSpellCooldown(spellIndex, BOOKTYPE_SPELL)
		-- Sometimes spells return a CD of 0 when cast fails.
		-- If it's non-zero, we have a valid timeStart to check.
		if durationCD == cooldown and timeStartCD ~= lastCdStart then
			return true, timeStartCD
		end
	end
	return false, lastCdStart
end

local CheckNewGCD = function(lastCdStart)
	return CheckNewCd(1.5, lastCdStart, Quiver.L.Spell["Serpent Sting"])
end

return {
	CheckNewCd = CheckNewCd,
	CheckNewGCD = CheckNewGCD,
	Db = DB_SPELL,
	FindSpellByTexture = FindSpellByTexture,
	FindSpellIndex = FindSpellIndex,
	PredInstantCast = PredInstantCast,
	PredInstantShot = PredInstantShot,
	PredSpellLearned = PredSpellLearned,
}

end)
__bundle_register("Api/Pet.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local _NUM_PET_ACTION_SLOTS = 10

---@param actionName string
---@return nil|1|2|3|4|5|6|7|8|9|10
---@nodiscard
local findActionIndex = function(actionName)
	for i=1, _NUM_PET_ACTION_SLOTS, 1 do
		local name, subtext, tex, isToken, isActive, isAutoCastAllowed, isAutoCastEnabled = GetPetActionInfo(i)
		if (name == actionName) then
			return i
		end
	end
	return nil
end

---@param actionName string
---@return nil
local CastActionByName = function(actionName)
	local index = findActionIndex(actionName)
	if index ~= nil then CastPetAction(index) end
end

return {
	CastActionByName = CastActionByName,
}

end)
__bundle_register("Api/Enum.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
--- see API InventorySlot(lua://InventorySlot)
local INVENTORY_SLOT = {
	Ammo = 0,
	Head = 1,
	Neck = 2,
	Shoulder = 3,
	Shirt = 4,
	Chest = 5,
	Belt = 6,
	Legs = 7,
	Feet = 8,
	Wrist = 9,
	Gloves = 10,
	Finger1 = 11,
	Finger2 = 12,
	Trinket1 = 13,
	Trinket2 = 14,
	Back = 15,
	MainHand = 16,
	OffHand = 17,
	Ranged = 18,
	Tabard = 19,
	Bag1 = 20,-- rightmost
	Bag2 = 21,-- second from right
	Bag3 = 22,-- third from right
	Bag4 = 23,-- fourth from right
	BankBag1 = 68,-- leftmost
	BankBag2 = 69,
	BankBag3 = 70,
	BankBag4 = 71,
	BankBag5 = 72,
	BankBag6 = 73,
	BankBag7 = 74,
}

return {
	INVENTORY_SLOT = INVENTORY_SLOT,
}

end)
__bundle_register("Api/Aura.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Tooltip = require("Api/Tooltip.lua")
local Const = require("Constants.lua")

-- This doesn't work for duplicate textures (ex. cheetah + zg mount).
-- For those you have to scan by name using the GameTooltip.
local GetIsActiveAndTimeLeftByTexture = function(targetTexture)
	-- This seems to check debuffs as well (tested with deserter)
	local maxIndex = Const.Aura_Cap - 1
	for i=0, maxIndex do
		local texture = GetPlayerBuffTexture(i)
		if texture == targetTexture then
			local timeLeft = GetPlayerBuffTimeLeft(i)
			return true, timeLeft
		end
	end
	return false, 0
end

---@param buffname string
---@nodiscard
local PredBuffActive = function(buffname)
	return Tooltip.Scan(function(tooltip)
		for i=0, Const.Buff_Cap do
			local buffIndex, _untilCancelled = GetPlayerBuff(i, "HELPFUL|PASSIVE")
			if buffIndex >= 0 then
				tooltip:ClearLines()
				tooltip:SetPlayerBuff(buffIndex)
				if Tooltip.GetText("TextLeft", 1) == buffname then
					return true
				end
			end
		end
		return false
	end)
end


-- This works great. Don't delete because switching from
-- texture to tooltip scanning would increase reliability.
-- UPDATE: Quiver now has as tooltip scanning library.
-- Also, this time-parsing code isn't client-localized.
-- This is still the right approach though.
--[[
local PredIsBuffActiveTimeLeftByName = function(buffname)
	local tooltip = resetTooltip()
	for i=0, Const.Buff_Cap do
		local buffIndex, _untilCancelled = GetPlayerBuff(i, "HELPFUL|PASSIVE")
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

return {
	GetIsActiveAndTimeLeftByTexture = GetIsActiveAndTimeLeftByTexture,
	PredBuffActive = PredBuffActive,
}

end)
__bundle_register("Constants.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
	-- I don't know if hidden auras show via GameTooltip.
	Buff_Cap = 32,-- I think UI shows up to 24.
	Debuff_Cap = 24,-- UI shows 16. Turtle allows 8 more hidden.
	Aura_Cap = 32 + 24,
	ColorDefault = {
		AutoShotReload = { 1, 0, 0 },
		AutoShotShoot = { 1, 1, 0 },
		Castbar = { 0.42, 0.41, 0.53 },
		Range = {
			Melee = { 0, 1, 0, 0.7 },
			DeadZone = { 1, 0.5, 0, 0.7 },
			ScareBeast = { 0, 1, 0.2, 0.7 },
			ScatterShot = { 0, 1, 0.8, 0.7 },
			Short = { 0, 0.8, 0.8, 0.7 },
			Long = { 0, 0.8, 0.8, 0.7 },
			Mark = { 1, 0.2, 0, 0.7 },
			TooFar = { 1, 0, 0, 0.7 },
		},
	},
	Size = {
		Border = 12,
		Button = 22,
		Gap = 8,
		Icon = 18,
	},
	Icon = {
		-- Custom
		ArrowsSwap = "Interface\\AddOns\\Quiver\\Assets\\Fa6\\arrow-right-arrow-left",
		CaretDown = "Interface\\AddOns\\Quiver\\Assets\\Fa6\\caret-down-fill",
		GripHandle = "Interface\\AddOns\\Quiver\\Assets\\grip-lines",
		LockClosed = "Interface\\AddOns\\Quiver\\Assets\\Fa6\\lock",
		LockOpen = "Interface\\AddOns\\Quiver\\Assets\\Fa6\\lock-open",
		Reset = "Interface\\AddOns\\Quiver\\Assets\\Fa6\\arrow-rotate-right",
		ToggleOff = "Interface\\AddOns\\Quiver\\Assets\\Fa6\\toggle-off",
		ToggleOn = "Interface\\AddOns\\Quiver\\Assets\\Fa6\\toggle-on",
		XMark = "Interface\\AddOns\\Quiver\\Assets\\Fa6\\xmark",
		-- Client
		Aspect_Beast = "Interface\\Icons\\Ability_Mount_PinkTiger",
		Aspect_Cheetah = "Interface\\Icons\\Ability_Mount_JungleTiger",
		Aspect_Hawk = "Interface\\Icons\\Spell_Nature_RavenForm",
		Aspect_Monkey = "Interface\\Icons\\Ability_Hunter_AspectOfTheMonkey",
		Aspect_Pack = "Interface\\Icons\\Ability_Mount_WhiteTiger",
		Aspect_Wild = "Interface\\Icons\\Spell_Nature_ProtectionformNature",-- 'form' is not a typo.
		Aspect_Wolf = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
		Quickshots = "Interface\\Icons\\Ability_Warrior_InnerRage",
		RapidFire = "Interface\\Icons\\Ability_Hunter_RunningShot",
		TrollBerserk = "Interface\\Icons\\Racial_Troll_Berserk",
		TrueshotAura = "Interface\\Icons\\Ability_TrueShot",
	},
}

end)
__bundle_register("Api/Aero.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
-- Support Aero animations if installed.
-- https://github.com/gashole/Aero

---@param f Frame
local RegisterFrame = function(f)
	Aero = IsAddOnLoaded("Aero") and Aero or nil
	if Aero ~= nil then
		if f.GetName then
			Aero:RegisterFrames(f:GetName())
		else
			DEFAULT_CHAT_FRAME:AddMessage("Must pass frame by reference", 1, 0.5, 0)
		end
	end
end

---@param f Frame
---@return boolean
---@nodiscard
local predAnimating = function(f)
	Aero = IsAddOnLoaded("Aero") and Aero or nil
	local ff = f---@type { aero: { animating: boolean } }
	return Aero ~= nil and ff.aero and ff.aero.animating
end

--- Aero calls Show/Hide internally, leading to duplicate calls.
---@param frame Frame
---@param event "OnHide"|"OnShow"
---@param f function
local SetScript = function(frame, event, f)
	frame:SetScript(event, function()
		if not predAnimating(frame) then f() end
	end)
end

return {
	RegisterFrame = RegisterFrame,
	SetScript = SetScript,
}

end)
__bundle_register("Api/Action.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Spell = require("Api/Spell.lua")

local _MAX_NUM_ACTION_SLOTS = 120

---@param name string
---@return nil|ActionBarSlot
---@nodiscard
local FindBySpellName = function(name)
	local index = Spell.FindSpellIndex(name)
	local texture = index ~= nil and GetSpellTexture(index, BOOKTYPE_SPELL) or nil
	if texture ~= nil then
		for i=0,_MAX_NUM_ACTION_SLOTS do
			if HasAction(i) then
				local isSpell = ActionHasRange(i) or GetActionText(i) == nil
				local isSameTexture = GetActionTexture(i) == texture
				if isSpell and isSameTexture then
					return i
				end
			end
		end
	end
	return nil
end

--- Matches return type of IsCurrentAction
---@return nil|1 isBusy
---@nodiscard
local PredSomeActionBusy = function()
	for i=1,_MAX_NUM_ACTION_SLOTS do
		if IsCurrentAction(i) then
			return 1
		end
	end
	return nil
end

return {
	FindBySpellName = FindBySpellName,
	PredSomeActionBusy = PredSomeActionBusy,
}

end)
__bundle_register("Modules/BorderStyle.provider.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
---@alias BorderStyle "Simple" | "Tooltip"

---@type (fun(x: BorderStyle): nil)[]
local callbacks = {}

---@param moduleId string
---@param callback fun(x: BorderStyle): nil
---@return nil
local Subscribe = function(moduleId, callback)
	callbacks[moduleId] = callback
end

---@param moduleId string
local Dispose = function(moduleId)
	callbacks[moduleId] = nil
end

return {
	Dispose = Dispose,
	Subscribe = Subscribe,

	---@param style BorderStyle
	---@return nil
	ChangeAndPublish = function(style)
		Quiver_Store.Border_Style = style
		for _i, v in pairs(callbacks) do
			v(style)
		end
	end,

	GetColor = function() return 0.6, 0.7, 0.7, 1.0 end,

	---@return integer
	---@nodiscard
	GetInsetSize = function()
		return Quiver_Store.Border_Style == "Tooltip" and 3 or 1
	end,

	-- TODO Ideally, subscribing would return a provider instance that can access state.
	-- However, that's going to require considerable re-architecting to support with type safety.
	---@return BorderStyle
	---@nodiscard
	GetStyle = function() return Quiver_Store.Border_Style end,
}

end)
__bundle_register("Events/Spellcast.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local Print = require("Util/Print.lua")

-- Hooks get called even if spell didn't fire, but successful cast triggers GCD.
local lastGcdStart = 0
local checkGCD = function()
	local isTriggeredGcd, newStart = Api.Spell.CheckNewGCD(lastGcdStart)
	lastGcdStart = newStart
	return isTriggeredGcd
end

-- Castable shot event has 2 triggers:
-- 1. User starts casting Aimed Shot, Multi-Shot, or Steady Shot
-- 2. User is already casting, but presses the spell again
-- It's up to the subscriber to differentiate.
---@type (fun(x: string, y: string): nil)[]
local callbacksCastableShot = {}

---@param nameEnglish string
---@param nameLocalized string
local publishShotCastable = function(nameEnglish, nameLocalized)
	for _i, v in pairs(callbacksCastableShot) do
		v(nameEnglish, nameLocalized)
	end
end

local CastableShot = {
	---@param moduleId string
	---@param callback fun(x: string, y: string): nil
	Subscribe = function(moduleId, callback)
		callbacksCastableShot[moduleId] = callback
	end,
	---@param moduleId string
	Dispose = function(moduleId)
		callbacksCastableShot[moduleId] = nil
	end,
}

---@type (fun(x: string, y: string): nil)[]
local callbacksInstant = {}

---@param nameEnglish string
---@param nameLocalized string
local publishInstant = function(nameEnglish, nameLocalized)
	for _i, v in pairs(callbacksInstant) do v(nameEnglish, nameLocalized) end
end
local Instant = {
	---@param moduleId string
	---@param callback fun(x: string, y: string): nil
	Subscribe = function(moduleId, callback)
		callbacksInstant[moduleId] = callback
	end,
	---@param moduleId string
	Dispose = function(moduleId)
		callbacksInstant[moduleId] = nil
	end,
}

local super = {
	CastSpell = CastSpell,
	CastSpellByName = CastSpellByName,
	UseAction = UseAction,
}

local println = Print.PrefixedF("spellcast")

---@param nameLocalized string
---@param isCurrentAction nil|1
local handleCastByName = function(nameLocalized, isCurrentAction)
	local nameEnglish = Quiver.L.SpellReverse[nameLocalized]
	if nameEnglish == nil then
		Print.Error("Localized spellname not found: "..nameLocalized)
		nameEnglish = nameLocalized
	-- We pre-hook the cast, so confirm we actually cast it before triggering callbacks.
	-- If it's castable, then check we're casting it, else check that we triggered GCD.
	elseif not Api.Spell.PredInstantCast(nameEnglish) then
		if isCurrentAction then
			publishShotCastable(nameEnglish, nameLocalized)
		elseif Api.Action.FindBySpellName(nameLocalized) == nil then
			println.Warning(nameLocalized .. " not on action bars, so can't track cast.")
		end
	elseif checkGCD() then
		publishInstant(nameEnglish, nameLocalized)
	end
end

---@param spellIndex number
---@param bookType BookType
---@return nil
CastSpell = function(spellIndex, bookType)
	super.CastSpell(spellIndex, bookType)
	local name, _rank = GetSpellName(spellIndex, bookType)
	if name ~= nil then
		Print.Debug("Cast as spell... " .. name)
		handleCastByName(name, Api.Action.PredSomeActionBusy())
	end
end

-- Some spells trigger this one time when spamming, others multiple
---@param name string
---@param isSelf? boolean
---@return nil
CastSpellByName = function(name, isSelf)
	super.CastSpellByName(name, isSelf)
	Print.Debug("Cast by name... " .. name)
	handleCastByName(name, Api.Action.PredSomeActionBusy())
end

-- Triggers multiple times when spamming the cast
---@param slot ActionBarSlot
---@param checkCursor? nil|0|1
---@param onSelf? nil|0|1
---@return nil
UseAction = function(slot, checkCursor, onSelf)
	super.UseAction(slot, checkCursor, onSelf)
	local texturePath = GetActionTexture(slot)
	if texturePath ~= nil then
		-- If we don't find a name, it means action is a macro with a custom texture.
		-- The macro will call CastSpellByName, which triggers a different hook.
		--
		-- If the macro uses the same texture, then both these hooks are called!
		-- We *could* check macro text etc. to disambiguate, but it's okay
		-- to duplicate the spell event since it won't change CD or start time.
		local name, index = Api.Spell.FindSpellByTexture(texturePath)
		if name ~= nil and index ~= nil then
			Print.Debug("Cast as Action... " .. name)
			handleCastByName(name, IsCurrentAction(slot))
		else
			Print.Debug("Skip Action... ")
		end
	end
end

return {
	CastableShot = CastableShot,
	Instant = Instant,
}

end)
__bundle_register("Events/FrameLock.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Button = require("Component/Button.lua")
local Const = require("Constants.lua")

--[[
WoW persists positions for frames that have global names.
However, we use custom meta (size+position) logic because
otherwise each login clears all frame data for disabled addons.
TopLeft origin because GetPoint() uses TopLeft


Must use entire store as parameter for functions, because we reset by setting FrameMeta to null.
If we only pass FrameMeta, then several event listeners will mutate the wrong object.
]]

local GRIP_HEIGHT = 12
local framesMoveable = {}
local framesResizeable = {}
local openWarning

-- Screensize scales after initializing, but when it does, the UI scale value also changes.
-- Therefore, the result of size * scale never changes, but the result of either size or scale does.
-- Disabling useUIScale doesn't affect the scale value, so we have to conditionally scale saved frame positions.
local getRealScreenWidth = function()
	local scale = GetCVar("useUiScale") == 1 and UIParent:GetEffectiveScale() or 1
	return GetScreenWidth() * scale
end
local getRealScreenheight = function()
	local scale = GetCVar("useUiScale") == 1 and UIParent:GetEffectiveScale() or 1
	return GetScreenHeight() * scale
end

local defaultOf = function(val, fallback)
	if val == nil then return fallback else return val end
end
local SideEffectRestoreSize = function(store, args)
	local sw = getRealScreenWidth()
	local sh = getRealScreenheight()

	local m = store.FrameMeta or {}
	local w, h, dx, dy = args.w, args.h, args.dx, args.dy
	m.W = defaultOf(m.W, w)
	m.H = defaultOf(m.H, h)
	m.X = defaultOf(m.X, sw / 2 + dx)
	m.Y = defaultOf(m.Y, -1 * sh / 2 + dy)
	store.FrameMeta = m
end

-- Tons of users don't read the readme file AT ALL. Not even the first line!
-- We have to guide and strongly encourage them to lock the frames.
local Init = function()
	openWarning = CreateFrame("Frame", nil, UIParent)
	openWarning:SetFrameStrata("MEDIUM")
	openWarning.Text = openWarning:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	openWarning.Text:SetAllPoints(openWarning)
	openWarning.Text:SetJustifyH("Center")
	openWarning.Text:SetJustifyV("Center")
	openWarning.Text:SetText(Quiver.T["Quiver Unlocked. Show config dialog with /qq or /quiver.\nClick the lock icon when done."])
	openWarning.Text:SetTextColor(1, 1, 1)
	openWarning:SetAllPoints(UIParent)
	if Quiver_Store.IsLockedFrames
	then openWarning:Hide()
	else openWarning:Show()
	end
end

local addFrameMoveable = function(frame)
	if not Quiver_Store.IsLockedFrames then
		frame:EnableMouse(true)
		frame:SetMovable(true)
	end
	table.insert(framesMoveable, frame)
end
local addFrameResizable = function(frame, handle)
	frame.QuiverGripHandle = handle
	if Quiver_Store.IsLockedFrames
	then frame.QuiverGripHandle.Container:Hide()
	else frame:SetResizable(true)
	end
	table.insert(framesResizeable, frame)
end

local lockFrames = function()
	openWarning:Hide()
	for _k, f in framesMoveable do
		f:EnableMouse(false)
		f:SetMovable(false)
	end
	for _k, f in framesResizeable do
		f.QuiverGripHandle.Container:Hide()
		f:SetResizable(false)
	end
	for _k, v in _G.Quiver_Modules do
		if Quiver_Store.ModuleEnabled[v.Id] then v.OnInterfaceLock() end
	end
end
local unlockFrames = function()
	openWarning:Show()
	for _k, f in framesMoveable do
		f:EnableMouse(true)
		f:SetMovable(true)
	end
	for _k, f in framesResizeable do
		f.QuiverGripHandle.Container:Show()
		f:SetResizable(true)
	end
	for _k, v in _G.Quiver_Modules do
		if Quiver_Store.ModuleEnabled[v.Id] then v.OnInterfaceUnlock() end
	end
end

local SetIsLocked = function(isChecked)
	Quiver_Store.IsLockedFrames = isChecked
	if isChecked then lockFrames() else unlockFrames() end
end

local absClamp = function(vOpt, vMax)
	local fallback = vMax / 2
	if vOpt == nil then return fallback end

	local v = math.abs(vOpt)
	if v > 0 and v < vMax
	then return v
	else return fallback
	end
end


---@param a number
---@return integer
local round = function(a)
	return math.floor(a + 0.5)
end
---@param a number
---@return integer
local round4 = function(a)
	return math.floor(a / 4 + 0.5) * 4
end

local SideEffectMakeMoveable = function(f, store)
	f:SetWidth(store.FrameMeta.W)
	f:SetHeight(store.FrameMeta.H)
	f:SetMinResize(30, GRIP_HEIGHT)
	local sw = getRealScreenWidth()
	local sh = getRealScreenheight()
	f:SetMaxResize(sw/2, sh/2)

	local xMax = sw - store.FrameMeta.W
	local yMax = sh - store.FrameMeta.H
	local x = absClamp(store.FrameMeta.X, xMax)
	local y = -1 * absClamp(store.FrameMeta.Y, yMax)
	f:SetPoint("TopLeft", nil, "TopLeft", x, y)
	f:SetScript("OnMouseDown", function()
		if not Quiver_Store.IsLockedFrames then f:StartMoving() end
	end)
	f:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		local _, _, _, x, y = f:GetPoint()
		store.FrameMeta.X = round4(x)
		store.FrameMeta.Y = round4(y)
		f:SetPoint("TopLeft", nil, "TopLeft", store.FrameMeta.X, store.FrameMeta.Y)
	end)

	addFrameMoveable(f)
end

local SideEffectMakeResizeable = function(frame, store, args)
	local margin, isCenterX, onResizeEnd, onResizeDrag =
		args.GripMargin, args.IsCenterX, args.OnResizeEnd, args.OnResizeDrag

	if isCenterX then
		frame:SetScript("OnSizeChanged", function()
			local wOld = store.FrameMeta.W
			local delta = round(frame:GetWidth() - wOld)
			store.FrameMeta.W = wOld + 2 * delta
			store.FrameMeta.X = store.FrameMeta.X - delta
			frame:SetWidth(store.FrameMeta.W)
			frame:SetPoint("TopLeft", store.FrameMeta.X, store.FrameMeta.Y)
			if onResizeDrag ~= nil then onResizeDrag() end
		end)
	elseif onResizeDrag ~= nil then
		frame:SetScript("OnSizeChanged", onResizeDrag)
	end

	local handle = Button:Create(frame, Const.Icon.GripHandle, nil, 0.5)
	addFrameResizable(frame, handle)
	handle.Container:SetFrameLevel(100)-- Should be top element
	handle.Container:SetPoint("BottomRight", frame, "BottomRight", -margin, margin)

	handle.HookMouseDown = function()
		if frame:IsResizable() then frame:StartSizing("BottomRight") end
	end
	handle.HookMouseUp = function()
		frame:StopMovingOrSizing()
		store.FrameMeta.W = math.floor(frame:GetWidth() + 0.5)
		store.FrameMeta.H = math.floor(frame:GetHeight() + 0.5)
		frame:SetWidth(store.FrameMeta.W)
		frame:SetHeight(store.FrameMeta.H)
		if onResizeEnd ~= nil then onResizeEnd() end
	end
end

return {
	Init = Init,
	SetIsLocked = SetIsLocked,
	SideEffectMakeMoveable = SideEffectMakeMoveable,
	SideEffectMakeResizeable = SideEffectMakeResizeable,
	SideEffectRestoreSize = SideEffectRestoreSize,
}

end)
__bundle_register("Component/Button.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local Util = require("Component/_Util.lua")
local L = require("Lib/Index.lua")

local _GAP = 6
local _SIZE = 16

-- see [IconButton](lua://QqIconButton)
-- see [Switch](lua://QqSwitch)
---@class (exact) QqButton : IMouseInteract
---@field private __index? QqButton
---@field Container Frame
---@field HookClick nil|(fun(): nil)
---@field HookMouseDown nil|(fun(): nil)
---@field HookMouseUp nil|(fun(): nil)
---@field Icon Frame
---@field Label? FontString
---@field TooltipText? string
---@field Texture Texture
---@field private isEnabled boolean
---@field private isHover boolean
---@field private isMouseDown boolean
local QqButton = {}

function QqButton:resetTexture()
	local r, g, b = Util.SelectColor(self)
	self.Texture:SetVertexColor(r, g, b)
	if self.Label ~= nil then
		self.Label:SetTextColor(r, g, b)
	end
end

function QqButton:OnHoverStart()
	self.isHover = true
	self:resetTexture()
	Util.ToggleTooltip(self, self.Container, self.TooltipText)
end

function QqButton:OnHoverEnd()
	self.isHover = false
	self:resetTexture()
	Util.ToggleTooltip(self, self.Container, self.TooltipText)
end

function QqButton:OnMouseDown()
	self.isMouseDown = true
	if self.HookMouseDown ~= nil then self.HookMouseDown() end
	self:resetTexture()
end

function QqButton:OnMouseUp()
	self.isMouseDown = false
	if self.HookMouseUp ~= nil then self.HookMouseUp() end
	if MouseIsOver(self.Container) == 1 and self.HookClick ~= nil then
		self.HookClick()
	end
	self:resetTexture()
end

---@param isEnabled boolean
function QqButton:ToggleEnabled(isEnabled)
	self.isEnabled = isEnabled
	self:resetTexture()
end

---@param isHover boolean
function QqButton:ToggleHover(isHover)
	self.isHover = isHover
	self:resetTexture()
end


---@param parent Frame
---@param texPath string
---@param labelText? string
---@param scale? number
---@return QqButton
function QqButton:Create(parent, texPath, labelText, scale)
	local container = CreateFrame("Frame", nil, parent, nil)
	local icon = CreateFrame("Frame", nil, container, nil)

	---@type QqButton
	local r = {
		Container = container,
		Icon = icon,
		Texture = icon:CreateTexture(nil, "OVERLAY"),
		isEnabled = true,
		isHover = false,
		isMouseDown = false,
	}
	setmetatable(r, self)
	self.__index = self

	container:SetScript("OnEnter", function() r:OnHoverStart() end)
	container:SetScript("OnLeave", function() r:OnHoverEnd() end)
	container:SetScript("OnMouseDown", function() r:OnMouseDown() end)
	container:SetScript("OnMouseUp", function() r:OnMouseUp() end)
	container:EnableMouse(true)

	r.Texture:SetAllPoints(r.Icon)
	local scaleOr = scale and scale or 1.0
	r.Icon:SetWidth(_SIZE * scaleOr)
	r.Icon:SetHeight(_SIZE * scaleOr)
	r.Texture:SetTexture(texPath)

	r.Icon:SetPoint("Left", container, "Left", 0, 0)
	local h, w = 0, 0
	if labelText then
		r.Label = container:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		r.Label:SetText(labelText)
		r.Label:SetPoint("Right", container, "Right", 0, 0)
		h = L.Psi(L.Max, Api._Height, r.Icon, r.Label)
		w = L.Psi(L.Add, Api._Width, r.Icon, r.Label) + _GAP
	else
		h = r.Icon:GetHeight()
		w = r.Icon:GetWidth()
	end
	container:SetHeight(h)
	container:SetWidth(w)

	r:resetTexture()
	return r
end

return QqButton

end)
__bundle_register("Component/_Util.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local L = require("Lib/Index.lua")

---@class IMouseInteract
---@field isEnabled boolean
---@field isHover boolean
---@field isMouseDown boolean

local _COLOR_NORMAL = L.Color:Lift({ 1.0, 0.82, 0.0 })
local _COLOR_HOVER = L.Color:Lift({ 1.0, 0.6, 0.0 })
local _COLOR_MOUSEDOWN = L.Color:Lift({ 1.0, 0.3, 0.0 })
local _COLOR_DISABLE = L.Color:Lift({ 0.3, 0.3, 0.3 })

---@param self IMouseInteract
---@return number, number, number
local SelectColor = function(self)
	if not self.isEnabled then
		return _COLOR_DISABLE:Rgb()
	elseif self.isMouseDown then
		return _COLOR_MOUSEDOWN:Rgb()
	elseif self.isHover then
		return _COLOR_HOVER:Rgb()
	else
		return _COLOR_NORMAL:Rgb()
	end
end

---@param self IMouseInteract
---@param frame Frame
---@param text nil|string
local ToggleTooltip = function(self, frame, text)
	if text ~= nil then
		if self.isHover then
			Api.Tooltip.Position(frame)
			GameTooltip:AddLine(text, nil, nil, nil, 1)
			GameTooltip:Show()
		else
			GameTooltip:Hide()
			GameTooltip:ClearLines()
		end
	end
end

return {
	SelectColor = SelectColor,
	ToggleTooltip = ToggleTooltip,
}

end)
__bundle_register("Modules/UpdateNotifier.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Version = require("Util/Version.lua")

-- This file based on pfUI's updatenotify.lua
-- Copyright (c) 2016-2021 Eric Mauser (Shagu)
-- Copyright (c) 2022 SabineWren
local hasNotified = false
local CURRENT = Version:ParseThrows(GetAddOnMetadata("Quiver", "Version"))

local broadcast = (function()
	local channelsLogin = { "Battleground", "Raid", "guild" }
	local channelsPlayerGroup = { "Battleground", "Raid" }
	local send = function(channels)
		for _k, chan in channels do
			SendAddonMessage("Quiver", "VERSION:"..CURRENT.Text, chan)
		end
	end
	return {
		Group = function() send(channelsPlayerGroup) end,
		Login = function() send(channelsLogin) end,
	}
end)()

local checkGroupGrew = (function()
	local lastSize = 0
	return function()
		local sizeRaid = GetNumRaidMembers()
		local sizeParty = GetNumPartyMembers()
		local sizeGroup = sizeRaid > 0 and sizeRaid
			or sizeParty > 0 and sizeParty
			or 0
		local isLarger = sizeGroup > lastSize
		lastSize = sizeGroup
		return isLarger
	end
end)()

--- @type Event[]
local _EVENTS = {
	"CHAT_MSG_ADDON",
	"PARTY_MEMBERS_CHANGED",
	"PLAYER_ENTERING_WORLD",
}
local handleEvent = function()
	if event == "CHAT_MSG_ADDON" and arg1 == "Quiver" then
		local _, _, versionText = string.find(arg2, "VERSION:(.*)")
		if versionText ~= nil
			and CURRENT:PredNewer(versionText)
			and not hasNotified
		then
			local URL = "https://github.com/SabineWren/Quiver"
			local m1 = Quiver.T["New version %s available at %s"]
			local m2 = Quiver.T["It's always safe to upgrade Quiver. You won't lose any of your configuration."]
			local text = string.format(m1, versionText, URL)
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Quiver|r - "..text)
			DEFAULT_CHAT_FRAME:AddMessage("|cffdddddd"..m2)
			hasNotified = true
		end
	elseif event == "PARTY_MEMBERS_CHANGED" then
		if checkGroupGrew() then broadcast.Group() end
	elseif event == "PLAYER_ENTERING_WORLD" then
		broadcast.Login()
	end
end

-- ************ Initialization ************
return function()
	local frame = CreateFrame("Frame", nil)
	frame:SetScript("OnEvent", handleEvent)
	-- We don't need to unsubscribe, as we never disable the update notifier
	for _k, e in _EVENTS do frame:RegisterEvent(e) end
end

end)
__bundle_register("Util/Version.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class (exact) Version
---@field private __index? Version
---@field private breaking integer
---@field private feature integer
---@field private fix integer
---@field Text string
local Version = {}

---@param text string
---@return Version
---@nodiscard
function Version:ParseThrows(text)
	if text == nil then
		error("Nil version string")
	elseif string.len(text) == 0 then
		error("Empty version string")
	else
		local _, _, a, b, c = string.find(text, "(%d+)%.(%d+)%.(%d+)")
		local x, y, z = tonumber(a), tonumber(b), tonumber(c)
		if x == nil or y == nil or z == nil then
			error("Invalid version string: "..text)
		else
			---@type Version
			local r = {
				breaking = x,
				feature = y,
				fix = z,
				Text = text,
			}
			setmetatable(r, self)
			self.__index = self
			return r
		end
	end
end

---@param text string
---@return boolean
---@nodiscard
function Version:PredNewer(text)
	local a = self
	local b = Version:ParseThrows(text)
	return b.breaking > a.breaking
	or b.breaking == a.breaking and b.feature > a.feature
	or b.breaking == a.breaking and b.feature == a.feature and b.fix > a.fix
end

return Version

end)
__bundle_register("Modules/TrueshotAuraAlarm.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local Const = require("Constants.lua")
local FrameLock = require("Events/FrameLock.lua")
local Spellcast = require("Events/Spellcast.lua")

local MODULE_ID = "TrueshotAuraAlarm"
local store = nil
local frame = nil

local UPDATE_DELAY_SLOW = 5
local UPDATE_DELAY_FAST = 0.1
local updateDelay = UPDATE_DELAY_SLOW

local INSET = 4
local DEFAULT_ICON_SIZE = 40
local MINUTES_LEFT_WARNING = 5

-- ************ State ************
local aura = (function()
	local knowsAura, isActive, lastUpdate, timeLeft = false, false, 1800, 0
	return {
		ShouldUpdate = function(elapsed)
			lastUpdate = lastUpdate + elapsed
			return knowsAura and lastUpdate > updateDelay
		end,
		UpdateUI = function()
			knowsAura = Api.Spell.PredSpellLearned(Quiver.L.Spell["Trueshot Aura"])
				or not Quiver_Store.IsLockedFrames
			isActive, timeLeft = Api.Aura.GetIsActiveAndTimeLeftByTexture(Const.Icon.TrueshotAura)
			lastUpdate = 0

			if not Quiver_Store.IsLockedFrames or knowsAura and not isActive then
				frame.Icon:SetAlpha(0.75)
				frame:SetBackdropBorderColor(1, 0, 0, 0.8)
			elseif knowsAura and isActive and timeLeft > 0 and timeLeft < MINUTES_LEFT_WARNING * 60 then
				frame.Icon:SetAlpha(0.4)
				frame:SetBackdropBorderColor(0, 0, 0, 0.1)
			else
				updateDelay = UPDATE_DELAY_SLOW
				frame.Icon:SetAlpha(0.0)
				frame:SetBackdropBorderColor(0, 0, 0, 0)
			end
		end,
	}
end)()

-- ************ UI ************
local setFramePosition = function(f, s)
	FrameLock.SideEffectRestoreSize(s, {
		w=DEFAULT_ICON_SIZE, h=DEFAULT_ICON_SIZE, dx=150, dy=40,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("LOW")
	f:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left=INSET, right=INSET, top=INSET, bottom=INSET },
	})
	setFramePosition(f, store)

	f.Icon = CreateFrame("Frame", nil, f)
	f.Icon:SetBackdrop({ bgFile = Const.Icon.TrueshotAura, tile = false })
	f.Icon:SetPoint("Left", f, "Left", INSET, 0)
	f.Icon:SetPoint("Right", f, "Right", -INSET, 0)
	f.Icon:SetPoint("Top", f, "Top", 0, -INSET)
	f.Icon:SetPoint("Bottom", f, "Bottom", 0, INSET)

	FrameLock.SideEffectMakeMoveable(f, store)
	FrameLock.SideEffectMakeResizeable(f, store, { GripMargin=0 })
	return f
end

-- ************ Event Handlers ************
--- @type Event[]
local _EVENTS = {
	"PLAYER_AURAS_CHANGED",
	"SPELLS_CHANGED",-- Open or click thru spellbook, learn/unlearn spell
}
local handleEvent = function()
	if event == "SPELLS_CHANGED" and arg1 ~= "LeftButton"
		or event == "PLAYER_AURAS_CHANGED"
	then
		aura.UpdateUI()
	end
end

-- ************ Initialization ************
local onEnable = function()
	if frame == nil then frame = createUI() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", function()
		if aura.ShouldUpdate(arg1) then aura.UpdateUI() end
	end)
	for _k, e in _EVENTS do frame:RegisterEvent(e) end
	frame:Show()
	aura.UpdateUI()
	Spellcast.Instant.Subscribe(MODULE_ID, function(spellName)
		if spellName == Quiver.L.Spell["Trueshot Aura"] then
			-- Buffs don't update right away, but we want fast user feedback
			updateDelay = UPDATE_DELAY_FAST
		end
	end)
end
local onDisable = function()
	Spellcast.Instant.Dispose(MODULE_ID)
	frame:Hide()
	for _k, e in _EVENTS do frame:UnregisterEvent(e) end
end

---@type QqModule
return {
	Id = MODULE_ID,
	GetName = function() return Quiver.T["Trueshot Aura Alarm"] end,
	GetTooltipText = function() return nil end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() aura.UpdateUI() end,
	OnInterfaceUnlock = function() aura.UpdateUI() end,
	OnResetFrames = function()
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
	end,
	OnSavedVariablesPersist = function() return store end,
}

end)
__bundle_register("Modules/TranqAnnouncer.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local FrameLock = require("Events/FrameLock.lua")
local BorderStyle = require("Modules/BorderStyle.provider.lua")
local L = require("Lib/Index.lua")
local Print = require("Util/Print.lua")

local MODULE_ID = "TranqAnnouncer"
local store = nil
local frame = nil
local TRANQ_CD_SEC = 20
local INSET = 4
local BORDER_BAR = 1
local HEIGHT_BAR = 17
local WIDTH_FRAME_DEFAULT = 120

local message = (function()
	local ADDON_MESSAGE_CAST = "Quiver_Tranq_Shot"
	local MATCH = ADDON_MESSAGE_CAST..":(.*):(.*)"
	return {
		Broadcast = function()
			local playerName = UnitName("player")
			local _,_, msLatency = GetNetStats()
			local serialized = ADDON_MESSAGE_CAST..":"..playerName..":"..msLatency
			SendAddonMessage("Quiver", serialized, "Raid")
		end,
		Deserialize = function(msg)
			local _, _, nameCaster, latencyOrZero = string.find(msg, MATCH)
			local msLatencyCaster = latencyOrZero and latencyOrZero or 0
			-- Game client updates latency every 30 seconds, so it's unlikely
			-- to break deterministic ordering, but could happen in rare cases.
			-- Might consider a logical clock or something in the future.
			local _,_, msLatency = GetNetStats()
			local timeCastSec = GetTime() - (msLatency + msLatencyCaster) / 1000
			return nameCaster, timeCastSec
		end,
	}
end)()

local getColorForeground = (function()
	-- It would be expensive to compute non-rgb gradients in Lua during the update loop,
	-- so we design stop points using an online gradient generator and convert them to RGB.
	-- lch(52% 100 40) to lch(52% 100 141)
	-- https://non-boring-gradients.netlify.app/
	local NUM_COLORS = 17
	local COLOR_FG = {
		{ 0.95, 0.05, 0.05 },
		{ 0.91, 0.19, 0.0 },
		{ 0.79, 0.35, 0.08 },
		{ 0.75, 0.38, 0.02 },
		{ 0.72, 0.40, 0.0 },
		{ 0.68, 0.43, 0.0 },
		{ 0.64, 0.45, 0.0 },
		{ 0.60, 0.46, 0.0 },
		{ 0.56, 0.48, 0.0 },
		{ 0.52, 0.49, 0.0 },
		{ 0.48, 0.51, 0.0 },
		{ 0.44, 0.52, 0.04 },
		{ 0.40, 0.53, 0.10 },
		{ 0.29, 0.55, 0.0 },
		{ 0.23, 0.55, 0.0 },
		{ 0.15, 0.56, 0.11 },
		{ 0.00, 0.56, 0.18 },
	}
	return function(progress)
		-- Fixes floating point bugs
		local p = progress <= 0.0 and 0.001
			or progress >= 1.0 and 0.999
			or progress
		local i = math.ceil(p * NUM_COLORS)
		return unpack(COLOR_FG[i])
	end
end)()

local createProgressBar = function()
	local MARGIN_TEXT = 4
	local bar = CreateFrame("Frame")
	bar:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/BUTTONS/WHITE8X8",
		edgeSize = 1,
		tile = false,
	})
	bar:SetBackdropBorderColor(0, 0, 0, 0.6)

	local centerVertically = function(ele)
		ele:SetPoint("Top", bar, "Top", 0, -BORDER_BAR)
		ele:SetPoint("Bottom", bar, "Bottom", 0, BORDER_BAR)
	end

	bar.ProgressFrame = CreateFrame("Frame", nil, bar)
	centerVertically(bar.ProgressFrame)
	bar.ProgressFrame:SetPoint("Left", bar, "Left", BORDER_BAR, 0)
	bar.ProgressFrame:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
	})

	bar.FsPlayerName = bar.ProgressFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	centerVertically(bar.FsPlayerName)
	bar.FsPlayerName:SetPoint("Left", bar, "Left", MARGIN_TEXT, 0)
	bar.FsPlayerName:SetJustifyH("Left")
	bar.FsPlayerName:SetJustifyV("Center")
	bar.FsPlayerName:SetTextColor(1, 1, 1)

	bar.FsCdTimer = bar.ProgressFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	centerVertically(bar.FsCdTimer)
	bar.FsCdTimer:SetPoint("Right", bar, "Right", -MARGIN_TEXT, 0)
	bar.FsCdTimer:SetJustifyH("Right")
	bar.FsPlayerName:SetJustifyV("Center")
	bar.FsCdTimer:SetTextColor(1, 1, 1)

	return bar
end

local poolProgressBar = (function()
	local fs = {}
	return {
		Acquire = function(parent)
			local bar = table.remove(fs) or createProgressBar()
			bar:SetParent(parent)
			-- Clearing parent on release has side effects: hides frame and change stratas
			bar:SetFrameStrata("LOW")
			bar.ProgressFrame:SetFrameStrata("Medium")
			bar:Show()
			return bar
		end,
		Release = function(bar)
			bar:SetParent(nil)
			bar:ClearAllPoints()
			table.insert(fs, bar)
		end,
	}
end)()

local getIdealFrameHeight = function()
	local height = 0
	for _i, bar in frame.Bars do
		height = height + bar:GetHeight()
	end
	-- Make space for at least 1 bar when UI unlocked
	if height == 0 then height = HEIGHT_BAR end
	return height + 2 * INSET
end

local adjustBarYOffsets = function()
	local height = 0
	for _i, bar in frame.Bars do
		bar:SetPoint("Left", frame, "Left", INSET, 0)
		bar:SetPoint("Right", frame, "Right", -INSET, 0)
		bar:SetPoint("Top", frame, "Top", 0, -height - INSET)
		height = height + bar:GetHeight()
	end
end

local setFramePosition = function(f, s)
	local height = getIdealFrameHeight()
	FrameLock.SideEffectRestoreSize(s, {
		w=WIDTH_FRAME_DEFAULT, h=height, dx=110, dy=150,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
end

local createUI = function()
	frame = CreateFrame("Frame", nil, UIParent)
	frame.Bars = {}

	frame:SetFrameStrata("LOW")
	frame:SetBackdrop({
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left=INSET, right=INSET, top=INSET, bottom=INSET },
	})
	frame:SetBackdropBorderColor(BorderStyle.GetColor())

	setFramePosition(frame, store)
	FrameLock.SideEffectMakeMoveable(frame, store)
	FrameLock.SideEffectMakeResizeable(frame, store, { GripMargin=4 })
	return frame
end

-- ************ Frame Update Handlers ************
local getCanHide = function()
	local now = GetTime()
	local getIsFinished = function(v)
		local secElapsed = now - v.TimeCastSec
		return secElapsed >= TRANQ_CD_SEC
	end
	return not UnitAffectingCombat('player')
		and L.Array.Every(frame.Bars, getIsFinished)
		and Quiver_Store.IsLockedFrames
end

local hideFrameDeleteBars = function()
	frame:Hide()
	for _k, bar in frame.Bars do
		poolProgressBar.Release(bar)
	end
	frame.Bars = {}
end

local handleUpdate = function()
	if getCanHide() then hideFrameDeleteBars() end
	-- Animate Progress Bars
	local now = GetTime()
	for _k, bar in frame.Bars do
		local secElapsed = now - bar.TimeCastSec
		local secProgress = secElapsed > TRANQ_CD_SEC and TRANQ_CD_SEC or secElapsed
		local percentProgress = secProgress / TRANQ_CD_SEC
		local width = (bar:GetWidth() - 2 * BORDER_BAR) * percentProgress
		bar.ProgressFrame:SetWidth(width > 1 and width or 1)
		bar.FsCdTimer:SetText(string.format("%.1f / %.0f", secProgress, TRANQ_CD_SEC))

		local r, g, b = getColorForeground(percentProgress)
		-- RGB scaling doesn't change brightness equally for all colors,
		-- so we may need to make a separate gradient for bg
		local s = 0.7
		bar:SetBackdropColor(r*s, g*s, b*s, 0.8)
		bar.ProgressFrame:SetBackdropColor(r, g, b, 0.9)
	end
end

-- ************ Event Handlers ************
local handleMsg = function(_source, msg)
	-- For compatibility with other tranq addons, ignore the message source.
	local nameCaster, timeCastSec = message.Deserialize(msg)
	if nameCaster ~= nil then
		local barVisible = L.Array.Find(frame.Bars, function(bar)
			return bar.FsPlayerName:GetText() == nameCaster
		end)

		if barVisible then
			barVisible.TimeCastSec = timeCastSec
		else
			local barNew = poolProgressBar.Acquire(frame)
			barNew.TimeCastSec = timeCastSec
			barNew:SetHeight(HEIGHT_BAR)
			barNew.FsPlayerName:SetText(nameCaster)
			table.insert(frame.Bars, barNew)
		end

		table.sort(frame.Bars, function(a,b) return a.TimeCastSec < b.TimeCastSec end)
		adjustBarYOffsets()
		frame:SetHeight(getIdealFrameHeight())
		frame:Show()
	end
end

--- @type Event[]
local _EVENTS = {
	"CHAT_MSG_ADDON",-- Also works with macros
	"CHAT_MSG_SPELL_SELF_DAMAGE",-- Detect misses
	"SPELL_UPDATE_COOLDOWN",
}
local lastCastStart = 0
local getHasFiredTranq = function()
	local isCast, cdStart = Api.Spell.CheckNewCd(
		TRANQ_CD_SEC, lastCastStart, Quiver.L.Spell["Tranquilizing Shot"])
	lastCastStart = cdStart
	return isCast
end
local handleEvent = function()
	if event == "CHAT_MSG_ADDON" then
		handleMsg(arg1, arg2)
	elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
		if string.find(arg1, Quiver.L.CombatLog.Tranq.Miss)
			or string.find(arg1, Quiver.L.CombatLog.Tranq.Resist)
			or string.find(arg1, Quiver.L.CombatLog.Tranq.Fail)
		then
			Print.Line.Say(store.MsgTranqMiss)
			Print.Line.Raid(store.MsgTranqMiss)
		end
	elseif event == "SPELL_UPDATE_COOLDOWN" then
		if getHasFiredTranq() then
			message.Broadcast()
			if store.TranqChannel == "/Say" then
				Print.Line.Say(store.MsgTranqCast)
			elseif store.TranqChannel == "/Raid" then
				Print.Line.Raid(store.MsgTranqCast)
			-- else don't announce
			end
		end
	end
end

local onEnable = function()
	if frame == nil then frame = createUI() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in _EVENTS do frame:RegisterEvent(e) end
	if getCanHide() then hideFrameDeleteBars() else frame:Show() end
end
local onDisable = function()
	frame:Hide()
	for _k, e in _EVENTS do frame:UnregisterEvent(e) end
end

---@type QqModule
return {
	Id = MODULE_ID,
	GetName = function() return Quiver.T["Tranq Shot Announcer"] end,
	GetTooltipText = function() return Quiver.T["Announces in chat when your tranquilizing shot hits or misses a target."] end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function()
		if getCanHide() then hideFrameDeleteBars() end
	end,
	OnInterfaceUnlock = function() frame:Show() end,
	OnResetFrames = function()
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.MsgTranqMiss = savedVariables.MsgTranqMiss or Quiver.T["*** MISSED Tranq Shot ***"]
		store.MsgTranqCast = store.MsgTranqCast or Quiver.T["Casting Tranq Shot"]
		-- TODO DRY violation -- dropdown must match the module store init
		store.TranqChannel = store.TranqChannel or "/Say"
	end,
	OnSavedVariablesPersist = function() return store end,
}

end)
__bundle_register("Modules/RangeIndicator.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local Const = require("Constants.lua")
local FrameLock = require("Events/FrameLock.lua")

local MODULE_ID = "RangeIndicator"
local store = nil
local frame = nil
local fontString = nil

local setFramePosition = function(f, s)
	FrameLock.SideEffectRestoreSize(s, {
		w=190, h=35, dx=190 * -0.5, dy=-183,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	setFramePosition(f, store)
	FrameLock.SideEffectMakeMoveable(f, store)
	FrameLock.SideEffectMakeResizeable(f, store, { GripMargin=4 })

	f:SetFrameStrata("LOW")
	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 16,
		insets = { left=4, right=4, top=4, bottom=4 },
	})
	f:SetBackdropColor(0, 0, 0, 0.6)
	f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

	local fs = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetAllPoints(f)
	fs:SetJustifyH("Center")
	fs:SetJustifyV("Middle")
	fs:SetText("Range Indicator")
	fs:SetTextColor(1, 1, 1)

	return f, fs
end

---@param name string
---@return boolean
---@nodiscard
local predSpellInRange = function(name)
	local slot = Api.Action.FindBySpellName(name)
	if slot == nil then
		return false
	else
		return IsActionInRange(slot) == 1
	end
end

local checkDistance = {
	-- https://wowwiki-archive.fandom.com/wiki/API_CheckInteractDistance
	Inspect=function() return CheckInteractDistance("target", 1) end,-- 11.11 yards
	Trade=function() return CheckInteractDistance("target", 2) end,-- 11.11 yards
	Duel=function() return CheckInteractDistance("target", 3) end,-- 9.9 yards (or 10?)
	Follow=function() return CheckInteractDistance("target", 4) end,-- 28 yards
	-- Using Action Bars
	Melee=function() return predSpellInRange(Quiver.L.Spell["Wing Clip"]) end,-- 5 yards
	Mark=function() return predSpellInRange(Quiver.L.Spell["Hunter's Mark"]) end,-- 100 yards
	Ranged=function() return predSpellInRange(Quiver.L.Spell["Auto Shot"]) end,-- 35-41 yards (talents)
	Scare=function() return predSpellInRange(Quiver.L.Spell["Scare Beast"]) end,-- 10 yards
	Scatter=function() return predSpellInRange(Quiver.L.Spell["Scatter Shot"]) end,-- 15-21 yards (talents)
}

local render = function(color, text)
	fontString:SetText(text)
	local r, g, b, a = unpack(color)
	frame:SetBackdropColor(r, g, b, a)
	frame:SetBackdropBorderColor(r, g, b, a)
	-- if not Quiver_Store.IsLockedFrames then
	-- 	TODO do we care about grip handle color here?
	-- 	frame.QuiverGripHandle:GetNormalTexture():SetVertexColor(r, g, b)
	-- 	frame.QuiverGripHandle:GetHighlightTexture():SetVertexColor(r+0.3, g-0.1, b+0.3)
	-- end
end

-- ************ Event Handlers ************
local handleUpdate = function()
	if checkDistance.Melee() then
		render(store.ColorMelee, Quiver.T["Melee Range"])
	elseif checkDistance.Ranged() then
		if UnitCreatureType("target") == "Beast" and checkDistance.Scare() then
			render(store.ColorScareBeast, Quiver.T["Scare Beast"])
		elseif checkDistance.Scatter() then
			render(store.ColorScatterShot, Quiver.T["Scatter Shot"])
		elseif checkDistance.Follow() then
			render(store.ColorShort, Quiver.T["Short Range"])
		else
			render(store.ColorLong, Quiver.T["Long Range"])
		end
	elseif checkDistance.Follow() then
		render(store.ColorDeadZone, Quiver.T["Dead Zone"])
	elseif checkDistance.Mark() then
		render(store.ColorMark, Quiver.T["Hunter's Mark"])
	else
		render(store.ColorTooFar, Quiver.T["Out of Range"])
	end
end

local handleEvent = function()
	if UnitExists("target")
		and (not UnitIsDead("target"))
		and UnitCanAttack("player", "target")
	then
		frame:Show()
	elseif Quiver_Store.IsLockedFrames
		then frame:Hide()
	end
end

-- ************ Initialization ************
--- @type Event[]
local _EVENTS = {
	"PLAYER_TARGET_CHANGED",
	"UNIT_FACTION",
}
local onEnable = function()
	if frame == nil then frame, fontString = createUI() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in _EVENTS do frame:RegisterEvent(e) end
	if Quiver_Store.IsLockedFrames then handleEvent() else frame:Show() end
end

local onDisable = function()
	frame:Hide()
	for _k, e in _EVENTS do frame:UnregisterEvent(e) end
end

---@type QqModule
return {
	Id = MODULE_ID,
	GetName = function() return Quiver.T["Range Indicator"] end,
	GetTooltipText = function() return Quiver.T["Shows when abilities are in range. Requires spellbook abilities placed somewhere on your action bars."] end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() handleEvent() end,
	OnInterfaceUnlock = function() frame:Show() end,
	OnResetFrames = function()
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.ColorMelee = store.ColorMelee or Const.ColorDefault.Range.Melee
		store.ColorDeadZone = store.ColorDeadZone or Const.ColorDefault.Range.DeadZone
		store.ColorScareBeast = store.ColorScareBeast or Const.ColorDefault.Range.ScareBeast
		store.ColorScatterShot = store.ColorScatterShot or Const.ColorDefault.Range.ScatterShot
		store.ColorShort = store.ColorShort or Const.ColorDefault.Range.Short
		store.ColorLong = store.ColorLong or Const.ColorDefault.Range.Long
		store.ColorMark = store.ColorMark or Const.ColorDefault.Range.Mark
		store.ColorTooFar = store.ColorTooFar or Const.ColorDefault.Range.TooFar
	end,
	OnSavedVariablesPersist = function() return store end,
}

end)
__bundle_register("Modules/Castbar.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Const = require("Constants.lua")
local FrameLock = require("Events/FrameLock.lua")
local Spellcast = require("Events/Spellcast.lua")
local BorderStyle = require("Modules/BorderStyle.provider.lua")
local Haste = require("Util/Haste.lua")

local MODULE_ID = "Castbar"
local store = nil
local frame = nil

local maxBarWidth = 0
local castTime = 0
local isCasting = false
local timeStartCasting = 0

-- ************ UI ************
local styleCastbar = function(f)
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

	maxBarWidth = f:GetWidth() - 2 * sizeInset
	f.Castbar:SetPoint("Left", f, "Left", sizeInset, 0)
	f.Castbar:SetWidth(1)
	f.Castbar:SetHeight(f:GetHeight() - 2 * sizeInset)

	f.SpellName:SetWidth(maxBarWidth)
	f.SpellTime:SetWidth(maxBarWidth)

	local path, _size, flags = f.SpellName:GetFont()
	local textMargin = 5
	local calcFontSize = f:GetHeight() - sizeInset - textMargin
	local fontSize = calcFontSize > 18 and 18
		or calcFontSize < 10 and 10
		or calcFontSize

	f.SpellName:SetPoint("Left", f, "Left", textMargin, 0)
	f.SpellTime:SetPoint("Right", f, "Right", -textMargin, 0)

	f.SpellName:SetFont(path, fontSize, flags)
	f.SpellTime:SetFont(path, fontSize, flags)
end

local setFramePosition = function(f, s)
	FrameLock.SideEffectRestoreSize(s, {
		w=240, h=20, dx=240 * -0.5, dy=-116,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y, 0, 0)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("HIGH")

	f.Castbar = CreateFrame("Frame", nil, f)
	f.Castbar:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
	})

	f.SpellName = f.Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.SpellName:SetJustifyH("Left")
	f.SpellName:SetTextColor(1, 1, 1)

	f.SpellTime = f.Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.SpellTime:SetJustifyH("Right")
	f.SpellTime:SetTextColor(1, 1, 1)

	setFramePosition(f, store)
	styleCastbar(f)

	FrameLock.SideEffectMakeMoveable(f, store)
	FrameLock.SideEffectMakeResizeable(f, store, {
		GripMargin=4,
		OnResizeDrag=function() styleCastbar(f) end,
		OnResizeEnd=function() styleCastbar(f) end,
		IsCenterX=true,
	})
	return f
end

-- ************ Custom Event Handlers ************
local displayTime = function(current)
	if current < 0 then current = 0 end
	frame.SpellTime:SetText(string.format("%.1f / %.2f", current, castTime))
end

---@param nameEnglish string
---@param nameLocalized string
local onSpellcast = function(nameEnglish, nameLocalized)
	if not isCasting then
		isCasting = true
		local _timeStartLocal
		castTime, timeStartCasting, _timeStartLocal = Haste.CalcCastTime(nameEnglish)
		frame.SpellName:SetText(nameLocalized)
		frame.Castbar:SetWidth(1)
		displayTime(0)

		local r, g, b = unpack(store.ColorCastbar)
		frame.Castbar:SetBackdropColor(r, g, b, 1)
		frame:Show()
	end
end

-- ************ Frame Update Handlers ************
local handleUpdate = function()
	local timePassed = GetTime() - timeStartCasting
	if not isCasting then
		frame.Castbar:SetWidth(1)
	elseif timePassed <= castTime then
		displayTime(timePassed)
		frame.Castbar:SetWidth(maxBarWidth * timePassed / castTime)
	else
		displayTime(castTime)
		frame.Castbar:SetWidth(maxBarWidth)
	end
end

-- ************ Event Handlers ************
local handleEvent = function()
	if event == "SPELLCAST_DELAYED" then
		castTime = castTime + arg1 / 1000
	else
		isCasting = false
		if Quiver_Store.IsLockedFrames then frame:Hide() end
	end
end

-- ************ Initialization ************
--- @type Event[]
local _EVENTS = {
	"SPELLCAST_DELAYED",
	"SPELLCAST_FAILED",
	"SPELLCAST_INTERRUPTED",
	"SPELLCAST_STOP",
}
local onEnable = function()
	if frame == nil then frame = createUI() end
	if Quiver_Store.IsLockedFrames then frame:Hide() else frame:Show() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in _EVENTS do frame:RegisterEvent(e) end
	BorderStyle.Subscribe(MODULE_ID, function(_style)
		if frame ~= nil then styleCastbar(frame) end
	end)
	Spellcast.CastableShot.Subscribe(MODULE_ID, onSpellcast)
end
local onDisable = function()
	Spellcast.CastableShot.Dispose(MODULE_ID)
	BorderStyle.Dispose(MODULE_ID)
	if frame ~= nil then
		frame:Hide()
		for _k, e in _EVENTS do frame:UnregisterEvent(e) end
	end
end

---@type QqModule
return {
	Id = MODULE_ID,
	GetName = function() return Quiver.T["Castbar"] end,
	GetTooltipText = function() return Quiver.T["Shows Aimed Shot, Multi-Shot, and Steady Shot."] end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() if not isCasting then frame:Hide() end end,
	OnInterfaceUnlock = function() frame:Show() end,
	OnResetFrames = function()
		store.FrameMeta = nil
		if frame then
			setFramePosition(frame, store)
			styleCastbar(frame)
		end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.ColorCastbar = store.ColorCastbar or Const.ColorDefault.Castbar
	end,
	OnSavedVariablesPersist = function() return store end,
}

end)
__bundle_register("Modules/Aspect_Tracker/AspectTracker.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local Const = require("Constants.lua")
local FrameLock = require("Events/FrameLock.lua")

local MODULE_ID = "AspectTracker"
local store = nil---@type StoreAspectTracker
local frame = nil

local DEFAULT_ICON_SIZE = 40
local INSET = 5
local TRANSPARENCY = 0.5

local chooseIconTexture = function()
	if Api.Aura.PredBuffActive(Quiver.L.Spell["Aspect of the Beast"]) then
		return Const.Icon.Aspect_Beast
	elseif Api.Aura.PredBuffActive(Quiver.L.Spell["Aspect of the Cheetah"]) then
		return Const.Icon.Aspect_Cheetah
	elseif Api.Aura.PredBuffActive(Quiver.L.Spell["Aspect of the Monkey"]) then
		return Const.Icon.Aspect_Monkey
	elseif Api.Aura.PredBuffActive(Quiver.L.Spell["Aspect of the Wild"]) then
		return Const.Icon.Aspect_Wild
	elseif Api.Aura.PredBuffActive(Quiver.L.Spell["Aspect of the Wolf"]) then
		return Const.Icon.Aspect_Wolf
	elseif Api.Spell.PredSpellLearned(Quiver.L.Spell["Aspect of the Hawk"])
		and not Api.Aura.PredBuffActive(Quiver.L.Spell["Aspect of the Hawk"])
		or not Quiver_Store.IsLockedFrames
	then
		return Const.Icon.Aspect_Hawk
	else
		return nil
	end
end

-- ************ UI ************
local updateUI = function()
	local activeTexture = chooseIconTexture()
	if activeTexture then
		frame.Icon:SetBackdrop({ bgFile = activeTexture, tile = false })
		frame.Icon:SetAlpha(TRANSPARENCY)
	else
		frame.Icon:SetAlpha(0.0)
	end

	-- Exclude Pack from main texture, since party members can apply it.
	-- I don't have a simple way of detecting who cast it, because
	-- the cancellable bit is 1 even if a party member cast it.
	if Api.Aura.PredBuffActive(Quiver.L.Spell["Aspect of the Pack"]) then
		frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 20,
			insets = { left=INSET, right=INSET, top=INSET, bottom=INSET },
			tile = false,
		})
		frame:SetBackdropBorderColor(0.7, 0.8, 0.9, 1.0)
	else
		frame:SetBackdrop({ bgFile = "Interface/BUTTONS/WHITE8X8", tile = false })
	end
	frame:SetBackdropColor(0, 0, 0, 0)
end

local setFramePosition = function(f, s)
	FrameLock.SideEffectRestoreSize(s, {
		w=DEFAULT_ICON_SIZE, h=DEFAULT_ICON_SIZE, dx=110, dy=40,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("LOW")
	setFramePosition(f, store)

	f.Icon = CreateFrame("Frame", nil, f)
	f.Icon:SetPoint("Left", f, "Left", INSET, 0)
	f.Icon:SetPoint("Right", f, "Right", -INSET, 0)
	f.Icon:SetPoint("Top", f, "Top", 0, -INSET)
	f.Icon:SetPoint("Bottom", f, "Bottom", 0, INSET)

	FrameLock.SideEffectMakeMoveable(f, store)
	FrameLock.SideEffectMakeResizeable(f, store, { GripMargin=0 })
	return f
end

-- ************ Event Handlers ************
--- @type Event[]
local _EVENTS = {
	"PLAYER_AURAS_CHANGED",
	"SPELLS_CHANGED",-- Open or click thru spellbook, learn/unlearn spell
}
local handleEvent = function()
	if event == "SPELLS_CHANGED" and arg1 ~= "LeftButton"
		or event == "PLAYER_AURAS_CHANGED"
	then
		updateUI()
	end
end

-- ************ Initialization ************
local onEnable = function()
	if frame == nil then frame = createUI() end
	updateUI()
	frame:SetScript("OnEvent", handleEvent)
	for _k, e in _EVENTS do frame:RegisterEvent(e) end
	frame:Show()
end
local onDisable = function()
	frame:Hide()
	for _k, e in _EVENTS do frame:UnregisterEvent(e) end
end

---@type QqModule
return {
	Id = MODULE_ID,
	GetName = function() return Quiver.T["Aspect Tracker"] end,
	GetTooltipText = function() return nil end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() updateUI() end,
	OnInterfaceUnlock = function() updateUI() end,
	OnResetFrames = function()
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	---@param savedVariables StoreAspectTracker
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
	end,
	OnSavedVariablesPersist = function() return store end,
}

end)
__bundle_register("Migrations/Runner.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local M001 = require("Migrations/M001.lua")
local M002 = require("Migrations/M002.lua")
local M003 = require("Migrations/M003.lua")
local Version = require("Util/Version.lua")

return function()
	-- toc version (after 1.0.0) persists to saved variables. A clean
	-- install has no saved variables, which distinguishes a 1.0.0 install.
	if Quiver_Store == nil then
		Quiver_Store = {}
	else
		local vOld = Version:ParseThrows(Quiver_Store.Version or "1.0.0")
		if vOld:PredNewer("2.0.0") then M001() end
		if vOld:PredNewer("2.3.1") then M002() end
		if vOld:PredNewer("2.5.0") then M003() end
	end
	Quiver_Store.Version = GetAddOnMetadata("Quiver", "Version")
end

end)
__bundle_register("Migrations/M003.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local TranqAnnouncer = require("Modules/TranqAnnouncer.lua")

return function()
	local mstore = Quiver_Store.ModuleStore or {}
	local s = mstore[TranqAnnouncer.Id] or {}

	if s.MsgTranqHit then
		-- We notify on tranq cast instead of hit. To prevent a breaking
		-- release version, attempt changing contradictory text.
		local startPos, _ = string.find(string.lower(s.MsgTranqHit), "hit")
		if startPos then
			s.MsgTranqHit = Quiver.T["Casting Tranq Shot"]
		end

		-- Change name to account for new behaviour
		s.MsgTranqCast = s.MsgTranqHit
		s.MsgTranqHit = nil
	end
end

end)
__bundle_register("Migrations/M002.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local AutoShotTimer = require("Modules/Auto_Shot_Timer/AutoShotTimer.lua")

return function()
	local mstore = Quiver_Store.ModuleStore or {}
	local s = mstore[AutoShotTimer.Id] or {}

	-- Change colour to color
	if s.ColourShoot then s.ColorShoot = s.ColourShoot end
	if s.ColorReload then s.ColorReload = s.ColourReload end
	s.ColourShoot = nil
	s.ColourReload = nil
end

end)
__bundle_register("Migrations/M001.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local AutoShotTimer = require("Modules/Auto_Shot_Timer/AutoShotTimer.lua")

return function()
	local mstore = Quiver_Store.ModuleStore
	if mstore == nil or Quiver_Store.FrameMeta == nil then return end

	-- Rename Auto Shot timer module
	Quiver_Store.ModuleEnabled[AutoShotTimer.Id] = Quiver_Store.ModuleEnabled["AutoShotCastbar"]
	Quiver_Store.ModuleEnabled["AutoShotCastbar"] = nil

	mstore[AutoShotTimer.Id] = mstore["AutoShotCastbar"]
	mstore["AutoShotCastbar"] = nil

	Quiver_Store.FrameMeta[AutoShotTimer.Id] = Quiver_Store.FrameMeta["AutoShotCastbar"]
	Quiver_Store.FrameMeta["AutoShotCastbar"] = nil

	-- Move all module-specific frame data into module stores
	for _k, v in _G.Quiver_Modules do
		if mstore[v.Id] and Quiver_Store.FrameMeta[v.Id] then
			mstore[v.Id].FrameMeta = Quiver_Store.FrameMeta[v.Id]
		end
	end
	Quiver_Store.FrameMeta = nil
end

end)
__bundle_register("Config/MainMenu.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local Button = require("Component/Button.lua")
local Dialog = require("Component/Dialog.lua")
local IconButton = require("Component/IconButton.lua")
local Select = require("Component/Select.lua")
local Switch = require("Component/Switch.lua")
local TitleBox = require("Component/TitleBox.lua")
local Color = require("Config/Color.lua")
local InputText = require("Config/InputText.lua")
local Const = require("Constants.lua")
local FrameLock = require("Events/FrameLock.lua")
local L = require("Lib/Index.lua")
local AutoShotTimer = require("Modules/Auto_Shot_Timer/AutoShotTimer.lua")
local BorderStyle = require("Modules/BorderStyle.provider.lua")
local TranqAnnouncer = require("Modules/TranqAnnouncer.lua")

local createModuleControls = function(parent, m)
	local f = CreateFrame("Frame", nil, parent)

	local btnReset = Button:Create(f, Const.Icon.Reset)
	btnReset.TooltipText = Quiver.T["Reset Frame Size and Position"]
	btnReset.HookClick = function() m.OnResetFrames() end
	if not Quiver_Store.ModuleEnabled[m.Id] then
		btnReset:ToggleEnabled(false)
	end

	local switch = Switch:Create(f, {
		IsChecked = Quiver_Store.ModuleEnabled[m.Id],
		LabelText = m.GetName(),
		TooltipText = m.GetTooltipText(),
		OnChange = function (isChecked)
			Quiver_Store.ModuleEnabled[m.Id] = isChecked
			;(isChecked and m.OnEnable or m.OnDisable)()
			btnReset:ToggleEnabled(isChecked)
		end,
	})

	local x = 0
	local gap = 8
	btnReset.Container:SetPoint("Left", f, "Left", x, 0)
	x = x + btnReset.Container:GetWidth() + gap
	switch.Container:SetPoint("Left", f, "Left", x, 0)
	x = x + switch.Container:GetWidth()

	f:SetHeight(switch.Container:GetHeight())
	f:SetWidth(x)
	return f
end

local createAllModuleControls = function(parent, gap)
	local f = CreateFrame("Frame", nil, parent)
	local frames = L.Array.Mapi(_G.Quiver_Modules, function(m, i)
		local frame = createModuleControls(f, m)
		local yOffset = i * (frame:GetHeight() + gap)
		frame:SetPoint("Left", f, "Left", 0, 0)
		frame:SetPoint("Top", f, "Top", 0, -yOffset)
		return frame
	end)

	local maxWidths = L.Array.MapReduce(frames, Api._Width, math.max, 0)
	local totalHeight = L.Array.MapIntercalateSum(frames, Api._Height, gap)
	f:SetHeight(totalHeight)
	f:SetWidth(maxWidths)

	return f
end

local makeSelectAutoShotTimerDirection = function(parent)
	-- Factored out text until we can re-render options upon locale change.
	-- Otherwise, the change handler with compare wrong locale.
	local both = Quiver.T["Both Directions"]
	local selected = Quiver_Store.ModuleStore[AutoShotTimer.Id].BarDirection
	local options = { Quiver.T["Left to Right"], both }
	return Select:Create(parent,
		Quiver.T["Auto Shot Timer"],
		options,
		Quiver.T[selected],
		function(text)
			-- Reverse map from localized text to saved value
			local direction = text == both and "BothDirections" or "LeftToRight"
			Quiver_Store.ModuleStore[AutoShotTimer.Id].BarDirection = direction
			AutoShotTimer.UpdateDirection()
		end
	)
end

local makeSelectBorderStyle = function(parent)
	local tooltip = Quiver.T["Tooltip"]
	local selected = Quiver_Store.Border_Style
	local options = { Quiver.T["Simple"], tooltip }
	return Select:Create(parent,
		Quiver.T["Border Style"],
		options,
		Quiver.T[selected],
		function(text)
			-- Reverse map from localized text to saved value
			local style = text == tooltip and "Tooltip" or "Simple"
			BorderStyle.ChangeAndPublish(style)
		end
	)
end

local makeSelectChannelHit = function(parent)
	local defaultTranqText = (function()
		local store = Quiver_Store.ModuleStore[TranqAnnouncer.Id]
		-- TODO DRY violation -- dropdown must match the module store init
		return store and store.TranqChannel or "/Say"
	end)()
	return Select:Create(parent,
		Quiver.T["Tranq Speech"],
		{ Quiver.T["None"], "/Say", "/Raid" },
		defaultTranqText,
		function(text)
			local val = (function()
				if text == Quiver.T["None"] then
					return "None"
				else
					return text or "/Say"
				end
			end)()
			Quiver_Store.ModuleStore[TranqAnnouncer.Id].TranqChannel = val
		end
	)
end

local makeSelectDebugLevel = function(parent)
	return Select:Create(parent,
		Quiver.T["Debug Level"],
		{ Quiver.T["None"], Quiver.T["Verbose"] },
		Quiver_Store.DebugLevel == "Verbose" and Quiver.T["Verbose"] or Quiver.T["None"],
		function(text)
			local level = text == Quiver.T["Verbose"] and "Verbose" or "None"
			Quiver_Store.DebugLevel = level
		end
	)
end

---@param frameName string
---@return Frame
---@nodiscard
local Create = function(frameName)
	-- WoW uses border-box content sizing
	local _PADDING_CLOSE = Const.Size.Border + 6
	local _PADDING_FAR = Const.Size.Border + Const.Size.Gap
	local dialog = Dialog.Create(_PADDING_CLOSE, frameName)
	Api.Aero.SetScript(dialog, "OnShow", function()
		PlaySoundFile("Interface\\AddOns\\Quiver\\Assets\\removing_wood_arrow_from_bow_4.wav")
	end)
	Api.Aero.SetScript(dialog, "OnHide", function()
		PlaySoundFile("Interface\\AddOns\\Quiver\\Assets\\sheathing_a_few_arrows_loosely_into_a_quiver_3.wav")
	end)
	-- This allows escape key to close, and preserves frame position.
	table.insert(UISpecialFrames, frameName)

	local titleText = "Quiver " .. GetAddOnMetadata("Quiver", "Version")
	local titleBox = TitleBox.Create(dialog, titleText)
	titleBox:SetPoint("Center", dialog, "Top", 0, -10)

	local btnCloseTop = Button:Create(dialog, Const.Icon.XMark)
	btnCloseTop.TooltipText = Quiver.T["Close Window"]
	btnCloseTop.HookClick = function() dialog:Hide() end
	btnCloseTop.Container:SetPoint("TopRight", dialog, "TopRight", -_PADDING_CLOSE, -_PADDING_CLOSE)

	local btnToggleLock = IconButton:Create(dialog, {
		IsChecked = Quiver_Store.IsLockedFrames,
		OnChange = function(isLocked) FrameLock.SetIsLocked(isLocked) end,
		TexPathOff = Const.Icon.LockOpen,
		TexPathOn = Const.Icon.LockClosed,
		TooltipText = Quiver.T["Lock/Unlock Frames"],
	})
	FrameLock.Init()

	local lockOffsetX = _PADDING_CLOSE + Const.Size.Icon + Const.Size.Gap/2
	btnToggleLock.Icon:SetPoint("TopRight", dialog, "TopRight", -lockOffsetX, -_PADDING_CLOSE)

	local btnResetFrames = Button:Create(dialog, Const.Icon.Reset)
	btnResetFrames.TooltipText = Quiver.T["Reset All Frame Sizes and Positions"]
	btnResetFrames.HookClick = function()
		for _k, v in _G.Quiver_Modules do v.OnResetFrames() end
	end
	local resetOffsetX = lockOffsetX + btnResetFrames.Container:GetWidth() + Const.Size.Gap/2
	btnResetFrames.Container:SetPoint("TopRight", dialog, "TopRight", -resetOffsetX, -_PADDING_CLOSE)

	local controls = createAllModuleControls(dialog, Const.Size.Gap)
	local colorPickers = Color.Create(dialog, Const.Size.Gap)

	local yOffset = -_PADDING_CLOSE - Const.Size.Icon - Const.Size.Gap
	controls:SetPoint("Top", dialog, "Top", 0, yOffset)
	controls:SetPoint("Left", dialog, "Left", _PADDING_FAR, 0)
	colorPickers:SetPoint("Top", dialog, "Top", 0, yOffset)
	colorPickers:SetPoint("Right", dialog, "Right", -_PADDING_FAR, 0)
	dialog:SetWidth(_PADDING_FAR + controls:GetWidth() + _PADDING_FAR + colorPickers:GetWidth() + _PADDING_FAR)

	local ddContainer = CreateFrame("Frame", nil, dialog)
	local selectChannelHit = makeSelectChannelHit(ddContainer)
	local selectAutoShotTimerDirection = makeSelectAutoShotTimerDirection(ddContainer)
	local selectBorderStyle = makeSelectBorderStyle(ddContainer)
	local selectDebugLevel = makeSelectDebugLevel(ddContainer)

	selectChannelHit.Container:SetPoint("Right", ddContainer, "Right")
	selectAutoShotTimerDirection.Container:SetPoint("Right", ddContainer, "Right")
	selectBorderStyle.Container:SetPoint("Right", ddContainer, "Right")
	selectDebugLevel.Container:SetPoint("Right", ddContainer, "Right")

	local dropdownY = 0
	selectChannelHit.Container:SetPoint("Top", ddContainer, "Top", 0, dropdownY)
	dropdownY = dropdownY - Const.Size.Gap - selectChannelHit.Container:GetHeight()

	selectAutoShotTimerDirection.Container:SetPoint("Top", ddContainer, "Top", 0, dropdownY)
	dropdownY = dropdownY - Const.Size.Gap - selectAutoShotTimerDirection.Container:GetHeight()

	selectBorderStyle.Container:SetPoint("Top", ddContainer, "Top", 0, dropdownY)
	dropdownY = dropdownY - Const.Size.Gap - selectBorderStyle.Container:GetHeight()

	selectDebugLevel.Container:SetPoint("Top", ddContainer, "Top", 0, dropdownY)
	dropdownY = dropdownY - selectDebugLevel.Container:GetHeight()

	ddContainer:SetPoint("Top", dialog, "Top", 0, yOffset - controls:GetHeight() - _PADDING_FAR)
	ddContainer:SetPoint("Right", dialog, "Right", -(_PADDING_FAR + colorPickers:GetWidth() + _PADDING_FAR), 0)
	ddContainer:SetHeight(-dropdownY)

	local dropdowns = { selectChannelHit, selectAutoShotTimerDirection, selectBorderStyle, selectDebugLevel }
	local maxWidth = L.Array.MapReduce(dropdowns, function(x) return x.Container:GetWidth() end, math.max, 0)
	ddContainer:SetHeight(-dropdownY)
	ddContainer:SetWidth(maxWidth)

	local hLeft = controls:GetHeight() + _PADDING_FAR + ddContainer:GetHeight()
	local hRight = colorPickers:GetHeight()
	local hMax = hRight > hLeft and hRight or hLeft
	yOffset = yOffset - hMax - Const.Size.Gap

	local tranqOptions = InputText.Create(dialog, Const.Size.Gap)
	tranqOptions:SetPoint("TopLeft", dialog, "TopLeft", 0, yOffset)
	yOffset = yOffset - tranqOptions:GetHeight()
	yOffset = yOffset - Const.Size.Gap

	dialog:SetHeight(-1 * yOffset + _PADDING_CLOSE + Const.Size.Button)
	return dialog
end

return {
	Create = Create,
}

end)
__bundle_register("Config/InputText.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local EditBox = require("Component/EditBox.lua")
local TranqAnnouncer = require("Modules/TranqAnnouncer.lua")

-- TODO this is tightly coupled to tranq announcer,
-- which doesn't make sense for a separate component.
local Create = function(parent, gap)
	local store = Quiver_Store.ModuleStore[TranqAnnouncer.Id]
	local f = CreateFrame("Frame", nil, parent)

	local editCast = EditBox:Create(f, Quiver.T["Reset Tranq Message to Default"])
	editCast.Box:SetText(store.MsgTranqCast)
	editCast.Box:SetScript("OnTextChanged", function()
		store.MsgTranqCast = editCast.Box:GetText()
	end)
	editCast.Reset.HookClick = function()
		editCast.Box:SetText(Quiver.T["Casting Tranq Shot"])
	end

	local editMiss = EditBox:Create(f, Quiver.T["Reset Miss Message to Default"])
	editMiss.Box:SetText(store.MsgTranqMiss)
	editMiss.Box:SetScript("OnTextChanged", function()
		store.MsgTranqMiss = editMiss.Box:GetText()
	end)
	editMiss.Reset.HookClick = function()
		editMiss.Box:SetText(Quiver.T["*** MISSED Tranq Shot ***"])
	end

	local height1 = editCast.Box:GetHeight()
	editCast.Box:SetPoint("Top", f, "Top", 0, 0)
	editMiss.Box:SetPoint("Top", f, "Top", 0, -1 * (height1 + gap))

	f:SetWidth(parent:GetWidth())
	f:SetHeight(height1 + gap + editMiss.Box:GetHeight())
	return f
end

return {
	Create = Create,
}

end)
__bundle_register("Component/EditBox.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Button = require("Component/Button.lua")
local Const = require("Constants.lua")

local _GAP = Const.Size.Gap
local _GAP_RESET = 4

---@class (exact) QqEditBox
---@field private __index? QqEditBox
---@field Box EditBox
---@field Reset QqButton
local QqEditBox = {}

---@param parent Frame
---@param tooltipText string
---@return QqEditBox
function QqEditBox:Create(parent, tooltipText)
	local box = CreateFrame("EditBox", nil, parent)
	box:SetWidth(300)
	box:SetHeight(25)

	---@type QqEditBox
	local r = {
		Box = box,
		Reset = Button:Create(box, Const.Icon.Reset),
	}
	setmetatable(r, self)
	self.__index = self
	r.Reset.TooltipText = tooltipText

	local fMarginLeft = Const.Size.Border + _GAP
	local fMarginRight = Const.Size.Border + _GAP + Const.Size.Icon + _GAP_RESET

	local xr = r.Reset.Container:GetWidth() + _GAP_RESET
	r.Reset.Container:SetPoint("Right", box, "Right", xr, 0)

	box:SetPoint("Left", parent, "Left", fMarginLeft, 0)
	box:SetPoint("Right", parent, "Right", -fMarginRight, 0)
	box:SetTextColor(.5, 1, .8, 1)
	box:SetJustifyH("Left")
	box:SetMaxLetters(50)

	box:SetFontObject(GameFontNormalSmall)

	box:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 10,
		insets = { left=3, right=3, top=3, bottom=3 },
	})
	box:SetBackdropColor(0, 0, 0, 1)
	box:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	box:SetTextInsets(6,6,0,0)

	box:SetAutoFocus(false)
	box:SetScript("OnEscapePressed", function() box:ClearFocus() end)
	box:SetScript("OnEnterPressed", function() box:ClearFocus() end)
	return r
end

return QqEditBox

end)
__bundle_register("Config/Color.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Button = require("Component/Button.lua")
local ColorSwatch = require("Component/ColorSwatch.lua")
local Const = require("Constants.lua")
local L = require("Lib/Index.lua")
local AutoShotTimer = require("Modules/Auto_Shot_Timer/AutoShotTimer.lua")
local Castbar = require("Modules/Castbar.lua")
local RangeIndicator = require("Modules/RangeIndicator.lua")

---@param c1 Color
---@param c2 Color
local createBtnColorSwap = function(parent, f1, f2, c1, c2)
	local f = Button:Create(parent, Const.Icon.ArrowsSwap, Quiver.T["Shoot / Reload"])
	f.TooltipText = Quiver.T["Swap Shoot and Reload Colors"]
	f.HookClick = function()
		-- Swap colors
		local r, g, b = c1:Rgb()
		c1:SetRgb(c2:Rgb())
		c2:SetRgb(r, g, b)

		-- Update preview button
		f1.Button:SetBackdropColor(c1:Rgb())
		f2.Button:SetBackdropColor(c2:Rgb())
	end

	return f
end

---@param f Frame
---@param label string
---@param store Rgb
---@param default Rgb
local swatch = function(f, label, store, default)
	local color = L.Color:LiftReset(store, default)
	return ColorSwatch:Create(f, label, color)
end

local Create = function(parent, gap)
	local storeAutoShotTimer = Quiver_Store.ModuleStore[AutoShotTimer.Id]
	local storeCastbar = Quiver_Store.ModuleStore[Castbar.Id]
	local storeRange = Quiver_Store.ModuleStore[RangeIndicator.Id]
	local f = CreateFrame("Frame", nil, parent)

	local colorShoot = L.Color:LiftReset(storeAutoShotTimer.ColorShoot, Const.ColorDefault.AutoShotShoot)
	local colorReload = L.Color:LiftReset(storeAutoShotTimer.ColorReload, Const.ColorDefault.AutoShotReload)
	local optionShoot = ColorSwatch:Create(f, Quiver.T["Shooting"], colorShoot)
	local optionReload = ColorSwatch:Create(f, Quiver.T["Reloading"], colorReload)

	local elements = {
		swatch(f, Quiver.T["Casting"], storeCastbar.ColorCastbar, Const.ColorDefault.Castbar),
		createBtnColorSwap(f, optionShoot, optionReload, colorShoot, colorReload),
		optionShoot,
		optionReload,
		swatch(f, Quiver.T["Melee Range"], storeRange.ColorMelee, Const.ColorDefault.Range.Melee),
		swatch(f, Quiver.T["Dead Zone"], storeRange.ColorDeadZone, Const.ColorDefault.Range.DeadZone),
		swatch(f, Quiver.T["Scare Beast"], storeRange.ColorScareBeast, Const.ColorDefault.Range.ScareBeast),
		swatch(f, Quiver.T["Scatter Shot"], storeRange.ColorScatterShot, Const.ColorDefault.Range.ScatterShot),
		swatch(f, Quiver.T["Short Range"], storeRange.ColorShort, Const.ColorDefault.Range.Short),
		swatch(f, Quiver.T["Long Range"], storeRange.ColorLong, Const.ColorDefault.Range.Long),
		swatch(f, Quiver.T["Hunter's Mark"], storeRange.ColorMark, Const.ColorDefault.Range.Mark),
		swatch(f, Quiver.T["Out of Range"], storeRange.ColorTooFar, Const.ColorDefault.Range.TooFar),
	}
	-- Right align buttons using minimum amount of space
	local getLabelWidth = function(x) return x.Label and x.Label:GetWidth() or 0 end
	local labelMaxWidth = L.Array.MapReduce(elements, getLabelWidth, L.Max, 0)

	local y = 0
	for _,ele in elements do
		if ele.WidthMinusLabel ~= nil then
			ele.Container:SetWidth(ele.WidthMinusLabel + labelMaxWidth)
		end
		ele.Container:SetPoint("Left", f, "Left", 0, 0)
		ele.Container:SetPoint("Top", f, "Top", 0, -y)
		y = y + ele.Container:GetHeight() + gap
	end

	f:SetWidth(L.Array.MapReduce(elements, function(x) return x.Container:GetWidth() end, math.max, 0))
	f:SetHeight(y)
	return f
end

return {
	Create = Create,
}

end)
__bundle_register("Component/ColorSwatch.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Button = require("Component/Button.lua")
local Const = require("Constants.lua")

---@param color Color
---@param button Frame
local openColorPicker = function(color, button)
	-- colors at time of opening picker
	local ri, gi, bi = color:Rgb()

	-- Must replace existing callback before changing anything else,
	-- or edits can fire previous callback, contaminating other values.
	ColorPickerFrame.func = function()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		color:SetRgb(r, g, b)
		button:SetBackdropColor(r, g, b, 1)
	end

	ColorPickerFrame.cancelFunc = function()
		color:SetRgb(ri, gi, bi)
		button:SetBackdropColor(ri, gi, bi, 1)
		-- Reset native picker
		ColorPickerFrame:SetFrameStrata("MEDIUM")
	end

	ColorPickerFrame.hasOpacity = false
	ColorPickerFrame:SetColorRGB(ri, gi, bi)
	ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	ColorPickerFrame:Show()
end

---@param parent Frame
---@param color Color
---@return Frame
local createButton = function(parent, color)
	local f = CreateFrame("Button", nil, parent)
	f:SetWidth(40)
	f:SetHeight(20)
	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left=2, right=2, top=2, bottom=2 },
	})
	f:SetBackdropColor(color:Rgb())
	f:SetScript("OnClick", function() openColorPicker(color, f) end)
	return f
end

---@class (exact) QqColorSwatch
---@field private __index? QqColorSwatch
---@field Button Frame
---@field Container Frame
---@field Label FontString
---@field WidthMinusLabel number
local QqColorSwatch = {}

---@param parent Frame
---@param labelText string
---@param color Color
---@return QqColorSwatch
function QqColorSwatch:Create(parent, labelText, color)
	local container = CreateFrame("Frame", nil, parent)

	---@type QqColorSwatch
	local r = {
		Button = createButton(container, color),
		Container = container,
		Label = container:CreateFontString(nil, "BACKGROUND", "GameFontNormal"),
		WidthMinusLabel = 0,
	}
	setmetatable(r, self)
	self.__index = self

	r.Label:SetPoint("Left", container, "Left", 0, 0)
	r.Label:SetText(labelText)

	local reset = Button:Create(container, Const.Icon.Reset)
	reset.TooltipText = Quiver.T["Reset Color"]
	reset.HookClick = function()
		color:Reset()
		r.Button:SetBackdropColor(color:Rgb())
	end
	reset.Container:SetPoint("Right", container, "Right", 0, 0)

	local x = 4 + reset.Container:GetWidth()
	r.Button:SetPoint("Right", container, "Right", -x, 0)

	r.Container:SetHeight(r.Button:GetHeight())
	r.WidthMinusLabel = 6 + x + r.Button:GetWidth()

	return r
end

return QqColorSwatch

end)
__bundle_register("Component/TitleBox.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
---@param parent Frame
---@param text string
---@return Frame
local Create = function(parent, text)
	local f = CreateFrame("Frame", nil, parent)
	local fs = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetAllPoints(f)
	fs:SetJustifyH("Center")
	fs:SetJustifyV("Middle")
	fs:SetText(text)

	f:SetWidth(fs:GetStringWidth() + 30)
	f:SetHeight(35)
	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		tile = true,
		tileSize = 24,
		edgeSize = 24,
		insets = { left=8, right=8, top=8, bottom=8 },
	})
	-- TODO figure out how to clip parent frame instead of 100% opacity.
	f:SetBackdropColor(0, 0, 0, 1)
	f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	return f
end

return {
	Create = Create,
}

end)
__bundle_register("Component/Switch.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local Util = require("Component/_Util.lua")
local Const = require("Constants.lua")
local L = require("Lib/Index.lua")

local _GAP = 6
local _SIZE = 18

-- Three frame types exist for implementing a Switch: CheckButton, Button, Frame
-- For custom functionality with minimal code, Frame is the easiest starting point.

-- - CheckButton
-- The built-in texture slots don't allow different highlight/pushed effects for checked/unchecked.
-- Also inherits all problems from Button.

-- - Button
-- 1. Requires a pushed texture, otherwise icon disappears when user drags mouse.
--    That's twice the code of putting a single texture on a frame.
-- 2. Requires re-creating textures every time the button state changes, or
--    the next click causes a nil reference.
-- 3. If we use the built-in hover slot, the hover MUST stack with normal texture.
--    i.e. can't darken on hover.
-- 4. The built-in pushed effect doesn't take effect until MouseUp.

-- - Frame
-- 1. Mouse disabled by default.
-- 2. Click event not implemented.
-- 3. Disabled not implemented.

-- see [Button](lua://QqButton)
-- see [IconButton](lua://QqIconButton)
---@class (exact) QqSwitch : IMouseInteract
---@field private __index? QqSwitch
---@field Container Frame
---@field Icon Frame
---@field Label FontString
---@field Texture Texture
---@field isChecked boolean
---@field isEnabled boolean
---@field isHover boolean
---@field isMouseDown boolean
local QqSwitch = {}

---@class (exact) paramsSwitch
---@field IsChecked boolean
---@field LabelText string
---@field OnChange fun(b: boolean): nil
---@field TooltipText? string

---@param self QqSwitch
local resetTexture = function(self)
	local path = self.isChecked and Const.Icon.ToggleOn or Const.Icon.ToggleOff
	self.Texture:SetTexture(path)

	local r, g, b = Util.SelectColor(self)
	local a = self.isChecked and 1.0 or 0.7
	self.Texture:SetVertexColor(r, g, b, a)
	self.Label:SetTextColor(r, g, b, a)
end

---@param parent Frame
---@param bag paramsSwitch
---@return QqSwitch
---@nodiscard
function QqSwitch:Create(parent, bag)
	local container = CreateFrame("Frame", nil, parent, nil)
	local icon = CreateFrame("Frame", nil, container, nil)

	---@type QqSwitch
	local r = {
		Container = container,
		Icon = icon,
		Label = container:CreateFontString(nil, "BACKGROUND", "GameFontNormal"),
		Texture = icon:CreateTexture(nil, "OVERLAY"),
		isChecked = bag.IsChecked,
		isEnabled = true,
		isHover = false,
		isMouseDown = false,
	}
	setmetatable(r, self)
	self.__index = self

	local onEnter = function()
		r.isHover = true
		resetTexture(r)
		Util.ToggleTooltip(r, r.Container, bag.TooltipText)
	end
	local onLeave = function()
		r.isHover = false
		resetTexture(r)
		Util.ToggleTooltip(r, r.Container, bag.TooltipText)
	end

	local onMouseDown = function()
		r.isMouseDown = true
		resetTexture(r)
	end
	local onMouseUp = function()
		r.isMouseDown = false
		if MouseIsOver(r.Container) == 1 then
			r.isChecked = not r.isChecked
			bag.OnChange(r.isChecked)
		end
		resetTexture(r)
	end

	container:SetScript("OnEnter", onEnter)
	container:SetScript("OnLeave", onLeave)
	container:SetScript("OnMouseDown", onMouseDown)
	container:SetScript("OnMouseUp", onMouseUp)
	container:EnableMouse(true)

	r.Texture:SetAllPoints(r.Icon)
	r.Icon:SetWidth(_SIZE * 1.2)
	r.Icon:SetHeight(_SIZE)
	r.Label:SetText(bag.LabelText)

	r.Icon:SetPoint("Left", container, "Left", 0, 0)
	r.Label:SetPoint("Right", container, "Right", 0, 0)
	local h = L.Psi(L.Max, Api._Height, r.Icon, r.Label)
	local w = L.Psi(L.Add, Api._Width, r.Icon, r.Label) + _GAP
	container:SetHeight(h)
	container:SetWidth(w)

	resetTexture(r)
	return r
end

return QqSwitch

end)
__bundle_register("Component/Select.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Api = require("Api/Index.lua")
local Util = require("Component/_Util.lua")
local Const = require("Constants.lua")
local L = require("Lib/Index.lua")

local _BORDER, _INSET, _SPACING = 1, 4, 4
local _OPTION_PAD_H, _OPTION_PAD_V = 8, 4
local _MENU_PAD_TOP = 6

---@type QqSelect[]
local allSelects = {}

---@class Icon
---@field Frame Frame
---@field Texture Texture

---@param container Frame
---@return Icon
---@nodiscard
local createIcon = function(container)
	local f = CreateFrame("Frame", nil, container)
	f:SetPoint("Right", container, "Right", -_INSET, 0)
	f:SetWidth(16)
	f:SetHeight(16)

	local t = f:CreateTexture(nil, "OVERLAY")
	t:SetAllPoints(f)
	t:SetTexture(Const.Icon.CaretDown)
	return { Frame=f, Texture=t }
end

---@class (exact) QqSelect : IMouseInteract
---@field private __index? QqSelect
---@field Container Frame
---@field private icon Icon
---@field private label FontString
---@field private isEnabled boolean
---@field private isHover boolean
---@field private isMouseDown boolean
---@field Menu Frame
---@field Selected FontString
local QqSelect = {}

function QqSelect:resetTexture()
	local r, g, b = Util.SelectColor(self)

	local borderAlpha = self.isHover and 0.6 or 0.0
	self.Container:SetBackdropBorderColor(r, g, b, borderAlpha)

	self.label:SetTextColor(r, g, b)
	self.Selected:SetTextColor(r, g, b)

	self.icon.Texture:SetVertexColor(r, g, b)

	-- Vertically flip caret
	if self.Menu:IsVisible() then
		self.icon.Texture:SetTexCoord(0, 1, 1, 0)
	else
		self.icon.Texture:SetTexCoord(0, 1, 0, 1)
	end
end

function QqSelect:OnHoverStart()
	self.isHover = true
	self:resetTexture()
end

function QqSelect:OnHoverEnd()
	self.isHover = false
	self:resetTexture()
end

function QqSelect:OnMouseDown()
	self.isMouseDown = true
	self:resetTexture()
end

function QqSelect:OnMouseUp()
	self.isMouseDown = false
	if self:predMouseOver() then
		local isVisible = self.Menu:IsVisible()
		for _k, m in allSelects do
			m.Menu:Hide()
			m:resetTexture()
		end
		if not isVisible then self.Menu:Show() end
	end
	self:resetTexture()
end

---@private
---@return boolean
---@nodiscard
function QqSelect:predMouseOver()
	local xs = { self.Container, self.icon.Frame }
	return L.Array.Some(xs, MouseIsOver)
end

---@param parent Frame
---@param labelText string
---@param optionsText string[]
---@param selectedText nil|string
---@param onSet fun(text: string): nil
---@return QqSelect
function QqSelect:Create(parent, labelText, optionsText, selectedText, onSet)
	local select = CreateFrame("Frame", nil, parent)

	---@type QqSelect
	local r = {
		Container = select,
		icon = createIcon(select),
		label = select:CreateFontString(nil, "BACKGROUND", "GameFontNormal"),
		isEnabled = true,
		isHover = false,
		isMouseDown = false,
		Menu = CreateFrame("Frame", nil, parent),
		Selected = select:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	}
	setmetatable(r, self)
	self.__index = self
	table.insert(allSelects, r)

	r.Container:SetBackdrop({
		edgeFile="Interface/BUTTONS/WHITE8X8",
		edgeSize=_BORDER,
	})

	r.Menu:SetFrameStrata("TOOLTIP")
	r.Menu:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile="Interface/BUTTONS/WHITE8X8",
		edgeSize=1,
	})
	r.Menu:SetBackdropColor(0, 0, 0, 1)
	r.Menu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

	r.label:SetPoint("Left", select, "Left", _INSET, 0)
	r.label:SetPoint("Top", select, "Top", 0, -_INSET)
	r.label:SetText(labelText)

	r.Selected:SetPoint("Bottom", select, "Bottom", 0, _INSET)
	r.Selected:SetPoint("Left", select, "Left", _INSET, 0)
	r.Selected:SetPoint("Right", select, "Right", -_INSET - r.icon.Frame:GetWidth(), 0)
	r.Selected:SetText(selectedText or optionsText[1])

	local options = L.Array.Mapi(optionsText, function(t, i)
		local option = CreateFrame("Button", nil, r.Menu)
		local optionFs = option:CreateFontString(nil, "OVERLAY", "GameFontNormal")

		option:SetFontString(optionFs)
		optionFs:SetPoint("TopLeft", option, "TopLeft", _OPTION_PAD_H, -_OPTION_PAD_V)
		optionFs:SetText(t)

		option:SetHeight(optionFs:GetHeight() + 2 * _OPTION_PAD_V)
		option:SetPoint("Left", r.Menu, "Left", _BORDER, 0)
		option:SetPoint("Right", r.Menu, "Right", -_BORDER, 0)
		option:SetPoint("Top", r.Menu, "Top", 0, -i * option:GetHeight() - _BORDER - _MENU_PAD_TOP)

		local texHighlight = option:CreateTexture(nil, "OVERLAY")
		-- It would probably look better to set a fancy texture and adjust vertex color.
		texHighlight:SetTexture(0.22, 0.1, 0)
		texHighlight:SetAllPoints(option)
		option:SetHighlightTexture(texHighlight)

		return option
	end)

	for _k, oLoop in options do
		local option = oLoop---@type Button
		option:SetScript("OnClick", function()
			local text = option:GetFontString():GetText() or ""
			onSet(text)
			r.Selected:SetText(text)
			r.Menu:Hide()
		end)
	end

	local sumOptionHeights = L.Array.MapReduce(options, Api._Height, L.Add, 0)
	local maxOptionWidth = L.Array.MapReduce(options, L.Flow(Api._FontString, Api._Width), math.max, 0)

	select:SetScript("OnEnter", function() r:OnHoverStart() end)
	select:SetScript("OnLeave", function() r:OnHoverEnd() end)
	select:SetScript("OnMouseDown", function() r:OnMouseDown() end)
	select:SetScript("OnMouseUp", function() r:OnMouseUp() end)
	select:EnableMouse(true)

	select:SetHeight(
		r.Selected:GetHeight()
		+ _SPACING
		+ r.label:GetHeight()
		+ 2 * _INSET
	)
	select:SetWidth(
		math.max(r.label:GetWidth(), maxOptionWidth)
		+ r.icon.Frame:GetWidth()
		+ _SPACING
		+ _INSET * 2
	)

	r.Menu:SetHeight(sumOptionHeights + _MENU_PAD_TOP + 2 * _BORDER)
	r.Menu:SetWidth(maxOptionWidth + 2 * (_OPTION_PAD_H + _BORDER))
	r.Menu:SetPoint("Right", select, "Right", 0, 0)
	r.Menu:SetPoint("Top", select, "Top", 0, -select:GetHeight())
	r.Menu:Hide()

	r:resetTexture()
	return r
end

return QqSelect

end)
__bundle_register("Component/IconButton.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Util = require("Component/_Util.lua")

local _SIZE = 16

-- see [Button](lua://QqButton)
-- see [Switch](lua://QqSwitch)
---@class (exact) QqIconButtonButton : IMouseInteract
---@field private __index? QqIconButtonButton
---@field Icon Frame
---@field IsChecked boolean
---@field TexPathOff string
---@field TexPathOn string
---@field Texture Texture
---@field isEnabled boolean
---@field isHover boolean
---@field isMouseDown boolean
local QqIconButton = {}

---@class (exact) paramsIconButton
---@field IsChecked boolean
---@field OnChange fun(b: boolean): nil
---@field TexPathOff string
---@field TexPathOn string
---@field TooltipText? string

---@param self QqIconButtonButton
local resetTexture = function(self)
	local path = self.IsChecked and self.TexPathOn or self.TexPathOff
	self.Texture:SetTexture(path)

	local r, g, b = Util.SelectColor(self)
	self.Texture:SetVertexColor(r, g, b)
end

---@param parent Frame
---@param bag paramsIconButton
---@return QqIconButtonButton
---@nodiscard
function QqIconButton:Create(parent, bag)
	local icon = CreateFrame("Frame", nil, parent, nil)

	---@type QqIconButtonButton
	local r = {
		Icon = icon,
		IsChecked = bag.IsChecked,
		TexPathOff = bag.TexPathOff,
		TexPathOn = bag.TexPathOn,
		Texture = icon:CreateTexture(nil, "OVERLAY"),
		isEnabled = true,
		isHover = false,
		isMouseDown = false,
	}
	setmetatable(r, self)
	self.__index = self

	r.Texture:SetAllPoints(r.Icon)

	local onEnter = function()
		r.isHover = true
		resetTexture(r)
		Util.ToggleTooltip(r, r.Icon, bag.TooltipText)
	end
	local onLeave = function()
		r.isHover = false
		resetTexture(r)
		Util.ToggleTooltip(r, r.Icon, bag.TooltipText)
	end

	local onMouseDown = function()
		r.isMouseDown = true
		resetTexture(r)
	end
	local onMouseUp = function()
		r.isMouseDown = false
		if MouseIsOver(r.Icon) == 1 then
			r.IsChecked = not r.IsChecked
			bag.OnChange(r.IsChecked)
		end
		resetTexture(r)
	end

	r.Icon:SetScript("OnEnter", onEnter)
	r.Icon:SetScript("OnLeave", onLeave)
	r.Icon:SetScript("OnMouseDown", onMouseDown)
	r.Icon:SetScript("OnMouseUp", onMouseUp)

	r.Icon:EnableMouse(true)
	r.Icon:SetWidth(_SIZE)
	r.Icon:SetHeight(_SIZE)

	resetTexture(r)
	return r
end

return QqIconButton

end)
__bundle_register("Component/Dialog.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Const = require("Constants.lua")

---@param padding number
---@param frameName nil|string
---@return Frame
---@nodiscard
local Create = function(padding, frameName)
	local f = CreateFrame("Frame", frameName, UIParent)
	f:Hide()
	f:SetFrameStrata("DIALOG")
	f:SetPoint("Center", nil, "Center", 0, 0)
	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left=8, right=8, top=8, bottom=8 },
	})
	f:SetBackdropColor(0, 0, 0, 0.6)
	f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetScript("OnMouseDown", function() f:StartMoving() end)
	f:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

	local btnCloseBottom = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	btnCloseBottom:SetWidth(70)
	btnCloseBottom:SetHeight(Const.Size.Button)
	btnCloseBottom:SetPoint("BottomRight", f, "BottomRight", -padding, padding)
	btnCloseBottom:SetText(Quiver.T["Close"])
	btnCloseBottom:SetScript("OnClick", function() f:Hide() end)

	return f
end

return {
	Create = Create,
}

end)
__bundle_register("Locale/Lang.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local enUS_C = require("Locale/enUS/Client.enUS.lua")
local enUS_T = require("Locale/enUS/Translations.enUS.lua")
local zhCN_C = require("Locale/zhCN/Client.zhCN.lua")
local zhCN_T = require("Locale/zhCN/Translations.zhCN.lua")

return function()
	local translation = {
		["enUS"] = enUS_T,
		["zhCN"] = zhCN_T,
	}
	local client = {
		["enUS"] = enUS_C,
		["zhCN"] = zhCN_C,
	}
	local currentLang = GetLocale()
	Quiver.T = translation[currentLang] or translation["enUS"]
	Quiver.L = client[currentLang] or client["enUS"]
end

end)
__bundle_register("Locale/zhCN/Translations.zhCN.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
	["Announces in chat when your tranquilizing shot hits or misses a target."] = "在“/团队”聊天中通告你的宁神射击是否命中目标。",
	["Aspect Tracker"] = "守护追踪器",
	["Auto Shot Timer"] = "自动射击计时器",
	["Border Style"] = "边框样式",
	["Both Directions"] = "双向",
	["Castbar"] = "施法条",
	["Casting"] = "正在施法",
	["Casting Tranq Shot"] = "施放宁神射击",
	["Close"] = "关闭",
	["Close Window"] = "关闭窗口",
	["Dead Zone"] = "死区",
	["Debug Level"] = "调试级别",
	["Hunter's Mark"] = "猎人印记",
	["It's always safe to upgrade Quiver. You won't lose any of your configuration."] = "升级Quiver是安全的，你不会丢失任何配置。",
	["Left to Right"] = "从左到右",
	["Lock/Unlock Frames"] = "锁定/解锁框架",
	["Long Range"] = "远距离",
	["Melee Range"] = "近战范围",
	["*** MISSED Tranq Shot ***"] = "*** 宁神射击未命中 ***",
	["New version %s available at %s"] = "新版本%s可在%s下载",
	["None"] = "无",
	["Out of Range"] = "超出范围",
	["Quiver is for hunters."] = "Quiver仅适用于猎人。",
	["Quiver Unlocked. Show config dialog with /qq or /quiver.\nClick the lock icon when done."] = "Quiver已解锁。使用/qq或/quiver显示配置对话框。\n完成后点击锁定图标。",
	["Range Indicator"] = "距离指示器",
	["Reloading"] = "正在装填",
	["Reset All Frame Sizes and Positions"] = "重置所有框架大小和位置",
	["Reset Color"] = "重置颜色",
	["Reset Frame Size and Position"] = "重置框架大小和位置",
	["Reset Miss Message to Default"] = "重置未命中消息为默认",
	["Reset Tranq Message to Default"] = "重置宁神射击消息为默认",
	["Scare Beast"] = "恐吓野兽",
	["Scatter Shot"] = "驱散射击",
	["Shoot / Reload"] = "射击/装填",
	["Shooting"] = "正在射击",
	["Short Range"] = "近距离",
	["Shows Aimed Shot, Multi-Shot, and Steady Shot."] = "显示瞄准射击、多重射击和稳固射击的施法条。",
	["Shows when abilities are in range. Requires spellbook abilities placed somewhere on your action bars."] = "显示技能是否在范围内。需要将技能书中的技能放在动作条上。",
	["Simple"] = "简单的",
	["Swap Shoot and Reload Colors"] = "交换射击和装填颜色",
	["Tooltip"] = "工具提示",
	["Tranq Shot Announcer"] = "宁神射击通告器",
	["Tranq Speech"] = "宁神通知",
	["Trueshot Aura Alarm"] = "强击光环警报",
	["Verbose"] = "详细信息",
}

end)
__bundle_register("Locale/zhCN/Client.zhCN.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Spell = require("Locale/zhCN/Spell.zhCN.lua")
local SpellReverse = require("Locale/zhCN/Spell.reverse.zhCN.lua")
-- local Zone = require "Locale/zhCN/Zone.zhCN.lua"

return {
	CombatLog = {
		Consumes = {
			ManaPotion = "你从恢复法力中获得(.*)点法力值。",
			HealthPotion = "你的治疗药水为你恢复了(.*)点生命值。",
			Healthstone = "你的(.*)治疗石为你恢复了(.*)点生命值。",
			Tea = "你的糖水茶为你恢复了(.*)点生命值。",
		},
		Tranq = {
			Fail = "你未能驱散",
			Miss = "你的宁神射击未命中",
			Resist = "你的宁神射击被抵抗了",
		},
	},
	Spell = Spell,
	-- TODO it turns out spellnames aren't unique in Chinese.
	-- This approach isn't going to work in the general case.
	SpellReverse = SpellReverse,
}

end)
__bundle_register("Locale/zhCN/Spell.reverse.zhCN.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
	["孤狼守护"] = "Aspect of the Wolf",
	["驱除疾病"] = "Abolish Disease",
	["驱毒术"] = "Abolish Poison",
	["驱毒术效果"] = "Abolish Poison Effect",
	["Acid Breath"] = "Acid Breath",
	["Acid of Hakkar"] = "Acid of Hakkar",
	["Acid Spit"] = "Acid Spit",
	["Acid Splash"] = "Acid Splash",
	["速射炮台"] = "Activate MG Turret",
	["冲动"] = "Adrenaline Rush",
	["清算"] = "Reckoning",
	["侵略"] = "Aggression",
	["瞄准射击"] = "Aimed Shot",
	["炼金术"] = "Alchemy",
	["伏击"] = "Ambush",
	["诅咒增幅"] = "Amplify Curse",
	["Amplify Damage"] = "Amplify Damage",
	["Amplify Flames"] = "Amplify Flames",
	["魔法增效"] = "Amplify Magic",
	["先祖坚韧"] = "Ancestral Fortitude",
	["先祖治疗"] = "Ancestral Healing",
	["先祖知识"] = "Ancestral Knowledge",
	["先祖之魂"] = "Ancestral Spirit",
	["Anesthetic Poison"] = "Anesthetic Poison",
	["愤怒掌控"] = "Anger Management",
	["Anguish"] = "Anguish",
	["预知"] = "Anticipation",
	["Aqua Jet"] = "Aqua Jet",
	["水栖形态"] = "Aquatic Form",
	["Arcane Blast"] = "Arcane Blast",
	["Arcane Bolt"] = "Arcane Bolt",
	["奥术光辉"] = "Arcane Brilliance",
	["奥术专注"] = "Arcane Concentration",
	["魔爆术"] = "Arcane Explosion",
	["奥术集中"] = "Arcane Focus",
	["奥术增效"] = "Arcane Instability",
	["奥术智慧"] = "Arcane Intellect",
	["奥术冥想"] = "Arcane Meditation",
	["奥术心智"] = "Arcane Mind",
	["奥术飞弹"] = "Arcane Missiles",
	["Arcane Potency"] = "Arcane Potency",
	["奥术强化"] = "Arcane Power",
	["奥术抗性"] = "Arcane Resistance",
	["奥术射击"] = "Arcane Shot",
	["奥术精妙"] = "Arcane Subtlety",
	["Arcane Weakness"] = "Arcane Weakness",
	["Arcing Smash"] = "Arcing Smash",
	["极寒延伸"] = "Arctic Reach",
	["护甲锻造师"] = "Armorsmith",
	["Arugal's Curse"] = "Arugal's Curse",
	["Arugal's Gift"] = "Arugal's Gift",
	["Ascendance"] = "Ascendance",
	["Aspect of Arlokk"] = "Aspect of Arlokk",
	["Aspect of Jeklik"] = "Aspect of Jeklik",
	["Aspect of Mar'li"] = "Aspect of Mar'li",
	["野兽守护"] = "Aspect of the Beast",
	["猎豹守护"] = "Aspect of the Cheetah",
	["雄鹰守护"] = "Aspect of the Hawk",
	["灵猴守护"] = "Aspect of the Monkey",
	["豹群守护"] = "Aspect of the Pack",
	["Aspect of the Viper"] = "Aspect of the Viper",
	["野性守护"] = "Aspect of the Wild",
	["Aspect of Venoxis"] = "Aspect of Venoxis",
	["星界传送"] = "Astral Recall",
	["攻击"] = "Attacking",
	["Aura of Command"] = "Aura of Command",
	["Aural Shock"] = "Aural Shock",
	["自动射击"] = "Auto Shot",
	["Avenger's Shield"] = "Avenger's Shield",
	["Avenging Wrath"] = "Avenging Wrath",
	["Avoidance"] = "Avoidance",
	["Axe Flurry"] = "Axe Flurry",
	["斧专精"] = "Axe Specialization",
	["Axe Toss"] = "Axe Toss",
	["Backhand"] = "Backhand",
	["Backlash"] = "Backlash",
	["背刺"] = "Backstab",
	["灾祸"] = "Bane",
	["Baneful Poison"] = "Baneful Poison",
	["放逐术"] = "Banish",
	["Banshee Curse"] = "Banshee Curse",
	["Banshee Shriek"] = "Banshee Shriek",
	["Barbed Sting"] = "Barbed Sting",
	["树皮术"] = "Barkskin",
	["树皮术效果"] = "Barkskin Effect",
	["弹幕"] = "Barrage",
	["重击"] = "Bash",
	["基础营火"] = "Basic Campfire",
	["战斗怒吼"] = "Battle Shout",
	["战斗姿态"] = "Battle Stance",
	["战斗姿态（被动）"] = "Battle Stance Passive",
	["熊形态"] = "Bear Form",
	["野兽知识"] = "Beast Lore",
	["野兽杀手"] = "Beast Slaying",
	["训练野兽"] = "Beast Training",
	["The Beast Within"] = "The Beast Within",
	["Befuddlement"] = "Befuddlement",
	["祈福"] = "Benediction",
	["Berserker Charge"] = "Berserker Charge",
	["狂暴之怒"] = "Berserker Rage",
	["狂暴姿态"] = "Berserker Stance",
	["狂暴姿态（被动）"] = "Berserker Stance Passive",
	["狂暴"] = "Berserking",
	["野兽戒律"] = "Bestial Discipline",
	["野兽迅捷"] = "Bestial Swiftness",
	["狂野怒火"] = "Bestial Wrath",
	["Biletoad Infection"] = "Biletoad Infection",
	["Binding Heal"] = "Binding Heal",
	["撕咬"] = "Bite",
	["黑箭"] = "Black Arrow",
	["昏阙"] = "Blackout",
	["锻造"] = "Blacksmithing",
	["剑刃乱舞"] = "Blade Flurry",
	["冲击波"] = "Blast Wave",
	["Blaze"] = "Blaze",
	["Blazing Speed"] = "Blazing Speed",
	["神恩回复"] = "Blessed Recovery",
	["Blessing of Blackfathom"] = "Blessing of Blackfathom",
	["自由祝福"] = "Blessing of Freedom",
	["王者祝福"] = "Blessing of Kings",
	["光明祝福"] = "Blessing of Light",
	["力量祝福"] = "Blessing of Might",
	["保护祝福"] = "Blessing of Protection",
	["牺牲祝福"] = "Blessing of Sacrifice",
	["拯救祝福"] = "Blessing of Salvation",
	["庇护祝福"] = "Blessing of Sanctuary",
	["Blessing of Shahram"] = "Blessing of Shahram",
	["智慧祝福"] = "Blessing of Wisdom",
	["致盲"] = "Blind",
	["致盲粉"] = "Blinding Powder",
	["闪现术"] = "Blink",
	["暴风雪"] = "Blizzard",
	["格挡"] = "Block",
	["血之狂热"] = "Blood Craze",
	["血之狂暴"] = "Blood Frenzy",
	["Blood Funnel"] = "Blood Funnel",
	["血性狂暴"] = "Bloodrage",
	["Blood Leech"] = "Blood Leech",
	["血之契印"] = "Blood Pact",
	["Blood Siphon"] = "Blood Siphon",
	["Blood Tap"] = "Blood Tap",
	["Bloodlust"] = "Bloodlust",
	["残忍"] = "Cruelty",
	["Bomb"] = "Bomb",
	["震耳嗓音"] = "Booming Voice",
	["Boulder"] = "Boulder",
	["弓专精"] = "Bow Specialization",
	["弓"] = "Bows",
	["Brain Wash"] = "Brain Wash",
	["明亮篝火"] = "Bright Campfire",
	["野蛮冲撞"] = "Brutal Impact",
	["Burning Adrenaline"] = "Burning Adrenaline",
	["燃烧之魂"] = "Burning Soul",
	["Burning Wish"] = "Burning Wish",
	["Butcher Drain"] = "Butcher Drain",
	["烈焰召唤"] = "Call of Flame",
	["Call of the Grave"] = "Call of the Grave",
	["雷霆召唤"] = "Call of Thunder",
	["召唤宠物"] = "Call Pet",
	["伪装"] = "Camouflage",
	["食尸"] = "Cannibalize",
	["猎豹形态"] = "Cat Form",
	["灾变"] = "Cataclysm",
	["Cause Insanity"] = "Cause Insanity",
	["Chain Bolt"] = "Chain Bolt",
	["Chain Burn"] = "Chain Burn",
	["治疗链"] = "Chain Heal",
	["闪电链"] = "Chain Lightning",
	["Chained Bolt"] = "Chained Bolt",
	["Chains of Ice"] = "Chains of Ice",
	["挑战咆哮"] = "Challenging Roar",
	["挑战怒吼"] = "Challenging Shout",
	["冲锋"] = "Charge",
	["冲锋额外怒气效果"] = "Charge Rage Bonus Effect",
	["冲锋击昏"] = "Charge Stun",
	["偷袭"] = "Cheap Shot",
	["冰冻"] = "Chilled",
	["Chilling Touch"] = "Chilling Touch",
	["Chromatic Infusion"] = "Chromatic Infusion",
	["Circle of Healing"] = "Circle of Healing",
	["爪击"] = "Claw",
	["清洁术"] = "Cleanse",
	["Cleanse Nova"] = "Cleanse Nova",
	["节能施法"] = "Clearcasting",
	["顺劈斩"] = "Cleave",
	["灵巧陷阱"] = "Clever Traps",
	["Cloak of Shadows"] = "Cloak of Shadows",
	["关闭"] = "Closing",
	["布甲"] = "Cloth",
	["粗制磨刀石"] = "Coarse Sharpening Stone",
	["毒蛇反射"] = "Cobra Reflexes",
	["冷血"] = "Cold Blood",
	["急速冷却"] = "Cold Snap",
	["作战持久"] = "Combat Endurance",
	["燃烧"] = "Conflagrate",
	["命令"] = "Command",
	["Commanding Shout"] = "Commanding Shout",
	["专注光环"] = "Concentration Aura",
	["震荡"] = "Concussion",
	["震荡猛击"] = "Concussion Blow",
	["震荡射击"] = "Concussive Shot",
	["冰锥术"] = "Cone of Cold",
	["造食术"] = "Conjure Food",
	["制造魔法玛瑙"] = "Conjure Mana Agate",
	["制造魔法黄水晶"] = "Conjure Mana Citrine",
	["制造魔法翡翠"] = "Conjure Mana Jade",
	["制造魔法红宝石"] = "Conjure Mana Ruby",
	["造水术"] = "Conjure Water",
	["Consecrated Sharpening Stone"] = "Consecrated Sharpening Stone",
	["奉献"] = "Consecration",
	["Consume Magic"] = "Consume Magic",
	["吞噬暗影"] = "Consume Shadows",
	["Consuming Shadows"] = "Consuming Shadows",
	["传导"] = "Convection",
	["定罪"] = "Conviction",
	["烹饪"] = "Cooking",
	["Corrosive Acid Breath"] = "Corrosive Acid Breath",
	["Corrosive Ooze"] = "Corrosive Ooze",
	["Corrosive Poison"] = "Corrosive Poison",
	["Corrupted Blood"] = "Corrupted Blood",
	["腐蚀"] = "Corruption",
	["反击"] = "Counterattack",
	["法术反制"] = "Counterspell",
	["法术反制 - 沉默"] = "Counterspell - Silenced",
	["畏缩"] = "Cower",
	["制造火焰石"] = "Create Firestone",
	["制造强效火焰石"] = "Create Firestone (Greater)",
	["制造次级火焰石"] = "Create Firestone (Lesser)",
	["制造极效火焰石"] = "Create Firestone (Major)",
	["制造治疗石"] = "Create Healthstone",
	["制造强效治疗石"] = "Create Healthstone (Greater)",
	["制造次级治疗石"] = "Create Healthstone (Lesser)",
	["制造极效治疗石"] = "Create Healthstone (Major)",
	["制造初级治疗石"] = "Create Healthstone (Minor)",
	["制造灵魂石"] = "Create Soulstone",
	["制造强效灵魂石"] = "Create Soulstone (Greater)",
	["制造次级灵魂石"] = "Create Soulstone (Lesser)",
	["制造极效灵魂石"] = "Create Soulstone (Major)",
	["制造初级灵魂石"] = "Create Soulstone (Minor)",
	["制造法术石"] = "Create Spellstone",
	["制造强效法术石"] = "Create Spellstone (Greater)",
	["制造极效法术石"] = "Create Spellstone (Major)",
	["Create Spellstone (Master)"] = "Create Spellstone (Master)",
	["Creeper Venom"] = "Creeper Venom",
	["Cripple"] = "Cripple",
	["致残毒药"] = "Crippling Poison",
	["致残毒药 II"] = "Crippling Poison II",
	["火焰重击"] = "Critical Mass",
	["弩"] = "Crossbows",
	["Crowd Pummel"] = "Crowd Pummel",
	["Crusader Aura"] = "Crusader Aura",
	["Crusader Strike"] = "Crusader Strike",
	["Crusader's Wrath"] = "Crusader's Wrath",
	["Crystal Charge"] = "Crystal Charge",
	["Crystal Force"] = "Crystal Force",
	["Crystal Restore"] = "Crystal Restore",
	["Crystal Spire"] = "Crystal Spire",
	["Crystal Ward"] = "Crystal Ward",
	["Crystal Yield"] = "Crystal Yield",
	["Crystalline Slumber"] = "Crystalline Slumber",
	["栽培"] = "Cultivation",
	["祛病术"] = "Cure Disease",
	["消毒术"] = "Cure Poison",
	["痛苦诅咒"] = "Curse of Agony",
	["Curse of Blood"] = "Curse of Blood",
	["厄运诅咒"] = "Curse of Doom",
	["厄运诅咒效果"] = "Curse of Doom Effect",
	["疲劳诅咒"] = "Curse of Exhaustion",
	["痴呆诅咒"] = "Curse of Idiocy",
	["鲁莽诅咒"] = "Curse of Recklessness",
	["暗影诅咒"] = "Curse of Shadow",
	["Curse of the Deadwood"] = "Curse of the Deadwood",
	["Curse of the Elemental Lord"] = "Curse of the Elemental Lord",
	["元素诅咒"] = "Curse of the Elements",
	["语言诅咒"] = "Curse of Tongues",
	["Curse of Tuten'kash"] = "Curse of Tuten'kash",
	["虚弱诅咒"] = "Curse of Weakness",
	["Cursed Blood"] = "Cursed Blood",
	["Cyclone"] = "Cyclone",
	["匕首专精"] = "Dagger Specialization",
	["匕首"] = "Daggers",
	["魔法抑制"] = "Dampen Magic",
	["Dark Iron Bomb"] = "Dark Iron Bomb",
	["Dark Offering"] = "Dark Offering",
	["黑暗契约"] = "Dark Pact",
	["黑暗"] = "Darkness",
	["急奔"] = "Dash",
	["Dazed"] = "Dazed",
	["致命毒药"] = "Deadly Poison",
	["致命毒药 II"] = "Deadly Poison II",
	["致命毒药 III"] = "Deadly Poison III",
	["致命毒药 IV"] = "Deadly Poison IV",
	["致命毒药 V"] = "Deadly Poison V",
	["Deadly Throw"] = "Deadly Throw",
	["死亡缠绕"] = "Death Coil",
	["死亡之愿"] = "Death Wish",
	["Deep Sleep"] = "Deep Sleep",
	["Deep Slumber"] = "Deep Slumber",
	["重度伤口"] = "Deep Wounds",
	["防御"] = "Defense",
	["防御姿态"] = "Defensive Stance",
	["防御姿态（被动）"] = "Defensive Stance Passive",
	["防御状态"] = "Defensive State",
	["防御状态 2"] = "Defensive State 2",
	["挑衅"] = "Defiance",
	["偏斜"] = "Deflection",
	["Delusions of Jin'do"] = "Delusions of Jin'do",
	["魔甲术"] = "Mage Armor",
	["恶魔皮肤"] = "Demon Skin",
	["恶魔之拥"] = "Demonic Embrace",
	["Demonic Frenzy"] = "Demonic Frenzy",
	["恶魔牺牲"] = "Demonic Sacrifice",
	["挫志咆哮"] = "Demoralizing Roar",
	["挫志怒吼"] = "Demoralizing Shout",
	["致密磨刀石"] = "Dense Sharpening Stone",
	["绝望祷言"] = "Desperate Prayer",
	["毁灭延伸"] = "Destructive Reach",
	["侦测"] = "Detect",
	["侦测强效隐形"] = "Detect Greater Invisibility",
	["侦测隐形"] = "Detect Invisibility",
	["侦测次级隐形"] = "Detect Lesser Invisibility",
	["侦测魔法"] = "Detect Magic",
	["侦测陷阱"] = "Detect Traps",
	["威慑"] = "Deterrence",
	["Detonation"] = "Detonation",
	["Devastate"] = "Devastate",
	["毁灭"] = "Ruin",
	["虔诚光环"] = "Devotion Aura",
	["吞噬魔法"] = "Devour Magic",
	["吞噬魔法效果"] = "Devour Magic Effect",
	["噬灵瘟疫"] = "Devouring Plague",
	["Diamond Flask"] = "Diamond Flask",
	["外交"] = "Diplomacy",
	["巨熊形态"] = "Dire Bear Form",
	["Dire Growl"] = "Dire Growl",
	["缴械"] = "Disarm",
	["解除陷阱"] = "Disarm Trap",
	["祛病图腾"] = "Poison Cleansing Totem",
	["Disease Cloud"] = "Disease Cloud",
	["Diseased Shot"] = "Diseased Shot",
	["Diseased Spit"] = "Diseased Spit",
	["分解"] = "Disenchant",
	["逃脱"] = "Disengage",
	["Disjunction"] = "Disjunction",
	["解散野兽"] = "Dismiss Pet",
	["驱散魔法"] = "Dispel Magic",
	["扰乱"] = "Distract",
	["Distracting Pain"] = "Distracting Pain",
	["扰乱射击"] = "Distracting Shot",
	["俯冲"] = "Dive",
	["神恩术"] = "Divine Favor",
	["神圣之怒"] = "Divine Fury",
	["Divine Illumination"] = "Divine Illumination",
	["神圣智慧"] = "Divine Intellect",
	["神圣干涉"] = "Divine Intervention",
	["圣佑术"] = "Divine Protection",
	["圣盾术"] = "Divine Shield",
	["神圣之灵"] = "Divine Spirit",
	["神圣之力"] = "Divine Strength",
	["Diving Sweep"] = "Diving Sweep",
	["躲闪"] = "Dodge",
	["Dominate Mind"] = "Dominate Mind",
	["Dragon's Breath"] = "Dragon's Breath",
	["龙鳞制皮"] = "Dragonscale Leatherworking",
	["吸取生命"] = "Drain Life",
	["吸取法力"] = "Drain Mana",
	["吸取灵魂"] = "Drain Soul",
	["Dredge Sickness"] = "Dredge Sickness",
	["喝水"] = "Drink",
	["Druid's Slumber"] = "Druid's Slumber",
	["双武器"] = "Dual Wield",
	["双武器专精"] = "Dual Wield Specialization",
	["决斗"] = "Duel",
	["Dust Field"] = "Dust Field",
	["鹰眼术"] = "Eagle Eye",
	["Earth Elemental Totem"] = "Earth Elemental Totem",
	["Earth Shield"] = "Earth Shield",
	["大地震击"] = "Earth Shock",
	["地缚图腾"] = "Earthbind Totem",
	["Earthborer Acid"] = "Earthborer Acid",
	["Earthgrab"] = "Earthgrab",
	["效率"] = "Efficiency",
	["Electric Discharge"] = "Electric Discharge",
	["Electrified Net"] = "Electrified Net",
	["元素集中"] = "Elemental Focus",
	["元素之怒"] = "Elemental Fury",
	["元素制皮"] = "Elemental Leatherworking",
	["元素掌握"] = "Elemental Mastery",
	["Elemental Precision"] = "Elemental Precision",
	["元素磨刀石"] = "Elemental Sharpening Stone",
	["艾露恩的赐福"] = "Elune's Grace",
	["飘忽不定"] = "Elusiveness",
	["琥珀风暴"] = "Emberstorm",
	["Enamored Water Spirit"] = "Enamored Water Spirit",
	["附魔"] = "Enchanting",
	["耐久"] = "Endurance",
	["耐久训练"] = "Endurance Training",
	["工程学"] = "Engineering",
	["工程学专精"] = "Engineering Specialization",
	["狂怒"] = "Enrage",
	["可口的魔法点心"] = "Enriched Manna Biscuit",
	["奴役恶魔"] = "Enslave Demon",
	["纠缠根须"] = "Entangling Roots",
	["诱捕"] = "Entrapment",
	["Enveloping Web"] = "Enveloping Web",
	["Enveloping Webs"] = "Enveloping Webs",
	["Enveloping Winds"] = "Enveloping Winds",
	["Envenom"] = "Envenom",
	["Ephemeral Power"] = "Ephemeral Power",
	["逃命专家"] = "Escape Artist",
	["Essence of Sapphiron"] = "Essence of Sapphiron",
	["闪避"] = "Evasion",
	["Eventide"] = "Eventide",
	["剔骨"] = "Eviscerate",
	["唤醒"] = "Evocation",
	["斩杀"] = "Execute",
	["驱邪术"] = "Exorcism",
	["开阔思维"] = "Expansive Mind",
	["Exploding Shot"] = "Exploding Shot",
	["Exploit Weakness"] = "Exploit Weakness",
	["Explosive Shot"] = "Explosive Shot",
	["爆炸陷阱"] = "Explosive Trap",
	["爆炸陷阱效果"] = "Explosive Trap Effect",
	["破甲"] = "Sunder Armor",
	["Expose Weakness"] = "Expose Weakness",
	["以眼还眼"] = "Eye for an Eye",
	["基尔罗格之眼"] = "Eye of Kilrogg",
	["The Eye of the Dead"] = "The Eye of the Dead",
	["野兽之眼"] = "Eyes of the Beast",
	["渐隐术"] = "Fade",
	["精灵之火"] = "Faerie Fire",
	["精灵之火（野性）"] = "Faerie Fire (Feral)",
	["视界术"] = "Far Sight",
	["Fatal Bite"] = "Fatal Bite",
	["恐惧术"] = "Fear",
	["防护恐惧结界"] = "Fear Ward",
	["喂养宠物"] = "Feed Pet",
	["回馈"] = "Feedback",
	["假死"] = "Feign Death",
	["佯攻"] = "Feint",
	["Fel Armor"] = "Fel Armor",
	["恶魔专注"] = "Fel Concentration",
	["恶魔支配"] = "Fel Domination",
	["恶魔智力"] = "Fel Intellect",
	["恶魔耐力"] = "Fel Stamina",
	["Fel Stomp"] = "Fel Stomp",
	["魔火"] = "Felfire",
	["豹之优雅"] = "Feline Grace",
	["豹之迅捷"] = "Feline Swiftness",
	["野性侵略"] = "Feral Aggression",
	["野性冲锋"] = "Feral Charge",
	["野性本能"] = "Feral Instinct",
	["凶猛撕咬"] = "Ferocious Bite",
	["凶暴"] = "Ferocity",
	["神像"] = "Fetish",
	["Fevered Plague"] = "Fevered Plague",
	["Fiery Burst"] = "Fiery Burst",
	["寻找草药"] = "Find Herbs",
	["寻找矿物"] = "Find Minerals",
	["寻找财宝"] = "Find Treasure",
	["火焰冲击"] = "Fire Blast",
	["Fire Elemental Totem"] = "Fire Elemental Totem",
	["Fire Nova"] = "Fire Nova",
	["火焰新星图腾"] = "Fire Nova Totem",
	["火焰强化"] = "Fire Power",
	["火焰抗性"] = "Fire Resistance",
	["火焰抗性光环"] = "Fire Resistance Aura",
	["抗火图腾"] = "Fire Resistance Totem",
	["火焰之盾"] = "Fire Shield",
	["Fire Shield Effect"] = "Fire Shield Effect",
	["Fire Shield Effect II"] = "Fire Shield Effect II",
	["Fire Shield Effect III"] = "Fire Shield Effect III",
	["Fire Shield Effect IV"] = "Fire Shield Effect IV",
	["Fire Storm"] = "Fire Storm",
	["火焰易伤"] = "Fire Vulnerability",
	["防护火焰结界"] = "Fire Ward",
	["Fire Weakness"] = "Fire Weakness",
	["火球术"] = "Fireball",
	["Fireball Volley"] = "Fireball Volley",
	["火焰箭"] = "Firebolt",
	["急救"] = "First Aid",
	["钓鱼"] = "Fishing",
	["鱼竿"] = "Fishing Poles",
	["Fist of Ragnaros"] = "Fist of Ragnaros",
	["拳套专精"] = "Fist Weapon Specialization",
	["拳套"] = "Fist Weapons",
	["Flame Buffet"] = "Flame Buffet",
	["Flame Cannon"] = "Flame Cannon",
	["Flame Lash"] = "Flame Lash",
	["烈焰震击"] = "Flame Shock",
	["Flame Spike"] = "Flame Spike",
	["Flame Spray"] = "Flame Spray",
	["烈焰投掷"] = "Flame Throwing",
	["Flames of Shahram"] = "Flames of Shahram",
	["烈焰冲击"] = "Flamestrike",
	["火焰喷射器"] = "Flamethrower",
	["火舌图腾"] = "Flametongue Totem",
	["火舌武器"] = "Flametongue Weapon",
	["照明弹"] = "Flare",
	["Flash Bomb"] = "Flash Bomb",
	["快速治疗"] = "Flash Heal",
	["圣光闪现"] = "Flash of Light",
	["Flight Form"] = "Flight Form",
	["乱舞"] = "Flurry",
	["专注施法"] = "Focused Casting",
	["Focused Mind"] = "Focused Mind",
	["进食"] = "Food",
	["自律"] = "Forbearance",
	["Force of Nature"] = "Force of Nature",
	["意志之力"] = "Force of Will",
	["Force Punch"] = "Force Punch",
	["Force Reactive Disk"] = "Force Reactive Disk",
	["Forked Lightning"] = "Forked Lightning",
	["Forsaken Skills"] = "Forsaken Skills",
	["Frailty"] = "Frailty",
	["Freeze Solid"] = "Freeze Solid",
	["冰冻陷阱"] = "Freezing Trap",
	["冰冻陷阱效果"] = "Freezing Trap Effect",
	["狂暴回复"] = "Frenzied Regeneration",
	["疯狂"] = "Frenzy",
	["霜甲术"] = "Frost Armor",
	["Frost Breath"] = "Frost Breath",
	["冰霜导能"] = "Frost Channeling",
	["冰霜新星"] = "Frost Nova",
	["冰霜抗性"] = "Frost Resistance",
	["冰霜抗性光环"] = "Frost Resistance Aura",
	["抗寒图腾"] = "Frost Resistance Totem",
	["冰霜震击"] = "Frost Shock",
	["Frost Shot"] = "Frost Shot",
	["冰霜陷阱"] = "Frost Trap",
	["冰霜陷阱光环"] = "Frost Trap Aura",
	["防护冰霜结界"] = "Frost Ward",
	["Frost Warding"] = "Frost Warding",
	["Frost Weakness"] = "Frost Weakness",
	["霜寒刺骨"] = "Frostbite",
	["寒冰箭"] = "Frostbolt",
	["Frostbolt Volley"] = "Frostbolt Volley",
	["冰封武器"] = "Frostbrand Weapon",
	["狂怒之嚎"] = "Furious Howl",
	["The Furious Storm"] = "The Furious Storm",
	["激怒"] = "Furor",
	["Fury of Ragnaros"] = "Fury of Ragnaros",
	["Gahz'ranka Slam"] = "Gahz'ranka Slam",
	["Gahz'rilla Slam"] = "Gahz'rilla Slam",
	["绞喉"] = "Garrote",
	["Gehennas' Curse"] = "Gehennas' Curse",
	["基本"] = "Generic",
	["幽魂之狼"] = "Ghost Wolf",
	["鬼魅攻击"] = "Ghostly Strike",
	["Gift of Life"] = "Gift of Life",
	["自然赐福"] = "Gift of Nature",
	["野性赐福"] = "Gift of the Wild",
	["Goblin Dragon Gun"] = "Goblin Dragon Gun",
	["Goblin Sapper Charge"] = "Goblin Sapper Charge",
	["凿击"] = "Gouge",
	["风之优雅图腾"] = "Grace of Air Totem",
	["Grace of the Sunwell"] = "Grace of the Sunwell",
	["Grasping Vines"] = "Grasping Vines",
	["持久耐力"] = "Great Stamina",
	["强效王者祝福"] = "Greater Blessing of Kings",
	["强效光明祝福"] = "Greater Blessing of Light",
	["强效力量祝福"] = "Greater Blessing of Might",
	["强效拯救祝福"] = "Greater Blessing of Salvation",
	["强效庇护祝福"] = "Greater Blessing of Sanctuary",
	["强效智慧祝福"] = "Greater Blessing of Wisdom",
	["强效治疗术"] = "Greater Heal",
	["无情延伸"] = "Grim Reach",
	["Ground Tremor"] = "Ground Tremor",
	["根基图腾"] = "Grounding Totem",
	["匍匐"] = "Grovel",
	["低吼"] = "Growl",
	["守护者的宠爱"] = "Guardian's Favor",
	["Guillotine"] = "Guillotine",
	["枪械专精"] = "Gun Specialization",
	["枪械"] = "Guns",
	["Hail Storm"] = "Hail Storm",
	["制裁之锤"] = "Hammer of Justice",
	["愤怒之锤"] = "Hammer of Wrath",
	["断筋"] = "Hamstring",
	["侵扰"] = "Harass",
	["坚韧"] = "Toughness",
	["Haunting Spirits"] = "Haunting Spirits",
	["鹰眼"] = "Hawk Eye",
	["Head Crack"] = "Head Crack",
	["治疗术"] = "Heal",
	["Healing Circle"] = "Healing Circle",
	["治疗专注"] = "Healing Focus",
	["治疗之光"] = "Healing Light",
	["Healing of the Ages"] = "Healing of the Ages",
	["治疗之泉图腾"] = "Healing Stream Totem",
	["治疗之触"] = "Healing Touch",
	["治疗波"] = "Healing Wave",
	["治疗之道"] = "Healing Way",
	["生命通道"] = "Health Funnel",
	["野性之心"] = "Heart of the Wild",
	["重磨刀石"] = "Heavy Sharpening Stone",
	["地狱烈焰"] = "Hellfire",
	["地狱烈焰效果"] = "Hellfire Effect",
	["出血"] = "Hemorrhage",
	["采集草药"] = "Herb Gathering",
	["草药学"] = "Herbalism",
	["英勇打击"] = "Heroic Strike",
	["Heroism"] = "Heroism",
	["Hex"] = "Hex",
	["Hex of Jammal'an"] = "Hex of Jammal'an",
	["虚弱妖术"] = "Hex of Weakness",
	["休眠"] = "Hibernate",
	["神圣之火"] = "Holy Fire",
	["圣光术"] = "Holy Light",
	["神圣新星"] = "Holy Nova",
	["神圣强化"] = "Holy Power",
	["神圣延伸"] = "Holy Reach",
	["神圣之盾"] = "Holy Shield",
	["神圣震击"] = "Holy Shock",
	["Holy Smite"] = "Holy Smite",
	["神圣专精"] = "Holy Specialization",
	["Holy Strength"] = "Holy Strength",
	["Holy Strike"] = "Holy Strike",
	["神圣愤怒"] = "Holy Wrath",
	["无荣誉目标"] = "Honorless Target",
	["Hooked Net"] = "Hooked Net",
	["骑术：马"] = "Horse Riding",
	["恐惧嚎叫"] = "Howl of Terror",
	["人类精魂"] = "The Human Spirit",
	["人型生物杀手"] = "Humanoid Slaying",
	["猎人印记"] = "Hunter's Mark",
	["飓风"] = "Hurricane",
	["冰甲术"] = "Ice Armor",
	["寒冰护体"] = "Ice Barrier",
	["Ice Blast"] = "Ice Blast",
	["寒冰屏障"] = "Ice Block",
	["Ice Lance"] = "Ice Lance",
	["Ice Nova"] = "Ice Nova",
	["寒冰碎片"] = "Ice Shards",
	["Icicle"] = "Icicle",
	["点燃"] = "Ignite",
	["启发"] = "Illumination",
	["献祭"] = "Immolate",
	["献祭陷阱"] = "Immolation Trap",
	["献祭陷阱效果"] = "Immolation Trap Effect",
	["冲击"] = "Impact",
	["穿刺"] = "Impale",
	["强化伏击"] = "Improved Ambush",
	["强化魔爆术"] = "Improved Arcane Explosion",
	["强化奥术飞弹"] = "Improved Arcane Missiles",
	["强化奥术射击"] = "Improved Arcane Shot",
	["强化雄鹰守护"] = "Improved Aspect of the Hawk",
	["强化灵猴守护"] = "Improved Aspect of the Monkey",
	["强化背刺"] = "Improved Backstab",
	["强化战斗怒吼"] = "Improved Battle Shout",
	["强化狂暴之怒"] = "Improved Berserker Rage",
	["强化力量祝福"] = "Improved Blessing of Might",
	["强化智慧祝福"] = "Improved Blessing of Wisdom",
	["强化暴风雪"] = "Improved Blizzard",
	["强化血性狂暴"] = "Improved Bloodrage",
	["强化治疗链"] = "Improved Chain Heal",
	["强化闪电链"] = "Improved Chain Lightning",
	["强化挑战怒吼"] = "Improved Challenging Shout",
	["强化冲锋"] = "Improved Charge",
	["强化偷袭"] = "Improved Cheap Shot",
	["强化顺劈斩"] = "Improved Cleave",
	["强化专注光环"] = "Improved Concentration Aura",
	["强化震荡射击"] = "Improved Concussive Shot",
	["强化冰锥术"] = "Improved Cone of Cold",
	["强化腐蚀术"] = "Improved Corruption",
	["强化法术反制"] = "Improved Counterspell",
	["强化痛苦诅咒"] = "Improved Curse of Agony",
	["强化疲劳诅咒"] = "Improved Curse of Exhaustion",
	["强化虚弱诅咒"] = "Improved Curse of Weakness",
	["强化魔法抑制"] = "Improved Dampen Magic",
	["强化致命毒药"] = "Improved Deadly Poison",
	["强化挫志怒吼"] = "Improved Demoralizing Shout",
	["强化虔诚光环"] = "Improved Devotion Aura",
	["强化缴械"] = "Improved Disarm",
	["强化扰乱"] = "Improved Distract",
	["强化吸取生命"] = "Improved Drain Life",
	["强化吸取法力"] = "Improved Drain Mana",
	["强化吸取灵魂"] = "Improved Drain Soul",
	["强化狂怒"] = "Improved Enrage",
	["强化奴役恶魔"] = "Improved Enslave Demon",
	["强化纠缠根须"] = "Improved Entangling Roots",
	["强化闪避"] = "Improved Evasion",
	["强化剔骨"] = "Improved Eviscerate",
	["强化斩杀"] = "Improved Execute",
	["强化破甲"] = "Improved Expose Armor",
	["强化野兽之眼"] = "Improved Eyes of the Beast",
	["强化渐隐术"] = "Improved Fade",
	["强化假死"] = "Improved Feign Death",
	["强化火焰冲击"] = "Improved Fire Blast",
	["强化火焰图腾"] = "Improved Fire Nova Totem",
	["强化防护火焰结界"] = "Improved Fire Ward",
	["强化火球术"] = "Improved Fireball",
	["强化火焰箭"] = "Improved Firebolt",
	["强化火焰石"] = "Improved Firestone",
	["强化烈焰冲击"] = "Improved Flamestrike",
	["强化火舌武器"] = "Improved Flametongue Weapon",
	["强化圣光闪现"] = "Improved Flash of Light",
	["强化冰霜新星"] = "Improved Frost Nova",
	["强化防护冰霜结界"] = "Improved Frost Ward",
	["强化寒冰箭"] = "Improved Frostbolt",
	["强化冰封武器"] = "Improved Frostbrand Weapon",
	["强化绞喉"] = "Improved Garrote",
	["强化幽魂之狼"] = "Improved Ghost Wolf",
	["强化凿击"] = "Improved Gouge",
	["强化风之优雅图腾"] = "Improved Grace of Air Totem",
	["强化根基图腾"] = "Improved Grounding Totem",
	["强化制裁之锤"] = "Improved Hammer of Justice",
	["强化断筋"] = "Improved Hamstring",
	["强化治疗术"] = "Improved Healing",
	["强化治疗之泉图腾"] = "Improved Healing Stream Totem",
	["强化治疗之触"] = "Improved Healing Touch",
	["强化治疗波"] = "Improved Healing Wave",
	["强化生命通道"] = "Improved Health Funnel",
	["强化治疗石"] = "Improved Healthstone",
	["强化英勇打击"] = "Improved Heroic Strike",
	["强化猎人印记"] = "Improved Hunter's Mark",
	["强化献祭"] = "Improved Immolate",
	["强化小鬼"] = "Improved Imp",
	["强化心灵之火"] = "Improved Inner Fire",
	["强化速效毒药"] = "Improved Instant Poison",
	["强化拦截"] = "Improved Intercept",
	["强化破胆怒吼"] = "Improved Intimidating Shout",
	["强化审判"] = "Improved Judgement",
	["强化脚踢"] = "Improved Kick",
	["强化肾击"] = "Improved Kidney Shot",
	["强化剧痛鞭笞"] = "Improved Lash of Pain",
	["强化圣疗术"] = "Improved Lay on Hands",
	["强化次级治疗波"] = "Improved Lesser Healing Wave",
	["强化生命分流"] = "Improved Life Tap",
	["强化闪电箭"] = "Improved Lightning Bolt",
	["强化闪电护盾"] = "Improved Lightning Shield",
	["强化熔岩图腾"] = "Improved Magma Totem",
	["强化法力燃烧"] = "Improved Mana Burn",
	["强化法力护盾"] = "Improved Mana Shield",
	["强化法力之泉图腾"] = "Improved Mana Spring Totem",
	["强化野性印记"] = "Improved Mark of the Wild",
	["强化治疗宠物"] = "Improved Mend Pet",
	["强化心灵震爆"] = "Improved Mind Blast",
	["强化月火术"] = "Improved Moonfire",
	["强化自然之握"] = "Improved Nature's Grasp",
	["强化压制"] = "Improved Overpower",
	["强化真言术：韧"] = "Improved Power Word: Fortitude",
	["强化圣言术：盾"] = "Improved Power Word: Shield",
	["强化治疗祷言"] = "Improved Prayer of Healing",
	["强化心灵尖啸"] = "Improved Psychic Scream",
	["强化拳击"] = "Improved Pummel",
	["强化愈合"] = "Improved Regrowth",
	["强化复生"] = "Improved Reincarnation",
	["强化回春"] = "Improved Rejuvenation",
	["强化撕裂"] = "Improved Rend",
	["强化恢复"] = "Improved Renew",
	["强化惩罚光环"] = "Improved Retribution Aura",
	["强化复仇"] = "Improved Revenge",
	["强化复活宠物"] = "Improved Revive Pet",
	["强化正义之怒"] = "Improved Righteous Fury",
	["强化石化武器"] = "Improved Rockbiter Weapon",
	["强化割裂"] = "Improved Rupture",
	["强化闷棍"] = "Improved Sap",
	["强化灼烧"] = "Improved Scorch",
	["强化毒蝎钉刺"] = "Improved Scorpid Sting",
	["强化正义圣印"] = "Improved Seal of Righteousness",
	["强化十字军圣印"] = "Improved Seal of the Crusader",
	["强化灼热之痛"] = "Improved Searing Pain",
	["强化灼热图腾"] = "Improved Searing Totem",
	["强化毒蛇钉刺"] = "Improved Serpent Sting",
	["强化暗影箭"] = "Improved Shadow Bolt",
	["强化暗言术：痛"] = "Improved Shadow Word: Pain",
	["强化盾击"] = "Improved Shield Bash",
	["强化盾牌格挡"] = "Improved Shield Block",
	["强化盾墙"] = "Improved Shield Wall",
	["强化撕碎"] = "Improved Shred",
	["强化邪恶攻击"] = "Improved Sinister Strike",
	["强化猛击"] = "Improved Slam",
	["强化切割"] = "Improved Slice and Dice",
	["强化法术石"] = "Improved Spellstone",
	["强化疾跑"] = "Improved Sprint",
	["强化星火术"] = "Improved Starfire",
	["强化石爪图腾"] = "Improved Stoneclaw Totem",
	["强化石肤图腾"] = "Improved Stoneskin Totem",
	["强化大地之力图腾"] = "Improved Strength of Earth Totem",
	["强化魅魔"] = "Improved Succubus",
	["强化破甲攻击"] = "Improved Sunder Armor",
	["强化嘲讽"] = "Improved Taunt",
	["强化荆棘术"] = "Improved Thorns",
	["强化雷霆一击"] = "Improved Thunder Clap",
	["强化宁静"] = "Improved Tranquility",
	["强化吸血鬼的拥抱"] = "Improved Vampiric Embrace",
	["强化消失"] = "Improved Vanish",
	["强化虚空行者"] = "Improved Voidwalker",
	["强化风怒武器"] = "Improved Windfury Weapon",
	["强化摔绊"] = "Improved Wing Clip",
	["强化愤怒"] = "Improved Wrath",
	["焚烧"] = "Incinerate",
	["Infected Bite"] = "Infected Bite",
	["Infected Wound"] = "Infected Wound",
	["地狱火"] = "Inferno",
	["Inferno Shell"] = "Inferno Shell",
	["先发制人"] = "Initiative",
	["心灵之火"] = "Inner Fire",
	["心灵专注"] = "Inner Focus",
	["激活"] = "Innervate",
	["虫群"] = "Insect Swarm",
	["灵感"] = "Inspiration",
	["速效毒药"] = "Instant Poison",
	["速效毒药 II"] = "Instant Poison II",
	["速效毒药 III"] = "Instant Poison III",
	["速效毒药 IV"] = "Instant Poison IV",
	["速效毒药 V"] = "Instant Poison V",
	["速效毒药 VI"] = "Instant Poison VI",
	["强烈"] = "Intensity",
	["拦截"] = "Intercept",
	["拦截昏迷"] = "Intercept Stun",
	["Intervene"] = "Intervene",
	["Intimidating Roar"] = "Intimidating Roar",
	["破胆怒吼"] = "Intimidating Shout",
	["胁迫"] = "Intimidation",
	["Intoxicating Venom"] = "Intoxicating Venom",
	["Invisibility"] = "Invisibility",
	["Iron Will"] = "Iron Will",
	["Jewelcrafting"] = "Jewelcrafting",
	["审判"] = "Judgement",
	["命令审判"] = "Judgement of Command",
	["公正审判"] = "Judgement of Justice",
	["光明审判"] = "Judgement of Light",
	["正义审判"] = "Judgement of Righteousness",
	["十字军审判"] = "Judgement of the Crusader",
	["智慧审判"] = "Judgement of Wisdom",
	["脚踢"] = "Kick",
	["脚踢 - 沉默"] = "Kick - Silenced",
	["肾击"] = "Kidney Shot",
	["Kill Command"] = "Kill Command",
	["杀戮本能"] = "Killer Instinct",
	["Knock Away"] = "Knock Away",
	["Knockdown"] = "Knockdown",
	["骑术：科多兽"] = "Kodo Riding",
	["Lacerate"] = "Lacerate",
	["Larva Goo"] = "Larva Goo",
	["Lash"] = "Lash",
	["剧痛鞭笞"] = "Lash of Pain",
	["破釜沉舟"] = "Last Stand",
	["持久审判"] = "Lasting Judgement",
	["Lava Spout Totem"] = "Lava Spout Totem",
	["圣疗术"] = "Lay on Hands",
	["兽群领袖"] = "Leader of the Pack",
	["皮甲"] = "Leather",
	["制皮"] = "Leatherworking",
	["Leech Poison"] = "Leech Poison",
	["次级治疗术"] = "Lesser Heal",
	["次级治疗波"] = "Lesser Healing Wave",
	["次级隐形术"] = "Lesser Invisibility",
	["夺命射击"] = "Lethal Shots",
	["致命偷袭"] = "Lethality",
	["漂浮"] = "Levitate",
	["圣物"] = "Libram",
	["Lich Slap"] = "Lich Slap",
	["生命分流"] = "Life Tap",
	["Lifebloom"] = "Lifebloom",
	["Lifegiving Gem"] = "Lifegiving Gem",
	["Lightning Blast"] = "Lightning Blast",
	["闪电箭"] = "Lightning Bolt",
	["闪电吐息"] = "Lightning Breath",
	["Lightning Cloud"] = "Lightning Cloud",
	["闪电掌握"] = "Lightning Mastery",
	["闪电反射"] = "Lightning Reflexes",
	["闪电护盾"] = "Lightning Shield",
	["Lightning Wave"] = "Lightning Wave",
	["光明之泉"] = "Lightwell",
	["光明之泉回复"] = "Lightwell Renew",
	["Lizard Bolt"] = "Lizard Bolt",
	["Localized Toxin"] = "Localized Toxin",
	["开锁"] = "Pick Lock",
	["长时间眩晕"] = "Long Daze",
	["锤类武器专精"] = "Mace Specialization",
	["锤击昏迷效果"] = "Mace Stun Effect",
	["Machine Gun"] = "Machine Gun",
	["Magic Attunement"] = "Magic Attunement",
	["Magma Splash"] = "Magma Splash",
	["熔岩图腾"] = "Magma Totem",
	["锁甲"] = "Mail",
	["Maim"] = "Maim",
	["恶意"] = "Malice",
	["法力燃烧"] = "Mana Burn",
	["Mana Feed"] = "Mana Feed",
	["法力护盾"] = "Mana Shield",
	["法力之泉图腾"] = "Mana Spring Totem",
	["法力之潮图腾"] = "Mana Tide Totem",
	["割碎"] = "Mangle",
	["Mangle (Bear)"] = "Mangle (Bear)",
	["Mangle (Cat)"] = "Mangle (Cat)",
	["Mark of Arlokk"] = "Mark of Arlokk",
	["野性印记"] = "Mark of the Wild",
	["殉难"] = "Martyrdom",
	["Mass Dispel"] = "Mass Dispel",
	["恶魔学识大师"] = "Master Demonologist",
	["欺诈高手"] = "Master of Deception",
	["Master of Elements"] = "Master of Elements",
	["召唤大师"] = "Master Summoner",
	["槌击"] = "Maul",
	["骑术：机械陆行鸟"] = "Mechanostrider Piloting",
	["冥想"] = "Meditation",
	["Megavolt"] = "Megavolt",
	["近战专精"] = "Melee Specialization",
	["Melt Ore"] = "Melt Ore",
	["治疗宠物"] = "Mend Pet",
	["精神敏锐"] = "Mental Agility",
	["心灵之力"] = "Mental Strength",
	["Mighty Blow"] = "Mighty Blow",
	["心灵震爆"] = "Mind Blast",
	["精神控制"] = "Mind Control",
	["精神鞭笞"] = "Mind Flay",
	["安抚心灵"] = "Mind Soothe",
	["Mind Tremor"] = "Mind Tremor",
	["心灵视界"] = "Mind Vision",
	["麻痹毒药"] = "Mind-numbing Poison",
	["麻痹毒药 II"] = "Mind-numbing Poison II",
	["麻痹毒药 III"] = "Mind-numbing Poison III",
	["采矿"] = "Mining",
	["Misdirection"] = "Misdirection",
	["惩戒痛击"] = "Mocking Blow",
	["Molten Armor"] = "Molten Armor",
	["Molten Blast"] = "Molten Blast",
	["Molten Metal"] = "Molten Metal",
	["猫鼬撕咬"] = "Mongoose Bite",
	["怪物杀手"] = "Monster Slaying",
	["月火术"] = "Moonfire",
	["月怒"] = "Moonfury",
	["月光"] = "Moonglow",
	["枭兽光环"] = "Moonkin Aura",
	["枭兽形态"] = "Moonkin Form",
	["Mortal Cleave"] = "Mortal Cleave",
	["致死射击"] = "Mortal Shots",
	["致死打击"] = "Mortal Strike",
	["Mortal Wound"] = "Mortal Wound",
	["多重射击"] = "Multi-Shot",
	["谋杀"] = "Murder",
	["Mutilate"] = "Mutilate",
	["Naralex's Nightmare"] = "Naralex's Nightmare",
	["自然护甲"] = "Natural Armor",
	["自然变形"] = "Natural Shapeshifter",
	["武器平衡"] = "Natural Weapons",
	["Nature Aligned"] = "Nature Aligned",
	["自然抗性"] = "Nature Resistance",
	["自然抗性图腾"] = "Nature Resistance Totem",
	["Nature Weakness"] = "Nature Weakness",
	["自然集中"] = "Nature's Focus",
	["自然之赐"] = "Nature's Grace",
	["自然之握"] = "Nature's Grasp",
	["自然延伸"] = "Nature's Reach",
	["自然迅捷"] = "Nature's Swiftness",
	["Necrotic Poison"] = "Necrotic Poison",
	["Negative Charge"] = "Negative Charge",
	["Net"] = "Net",
	["夜幕"] = "Nightfall",
	["Noxious Catalyst"] = "Noxious Catalyst",
	["Noxious Cloud"] = "Noxious Cloud",
	["清晰预兆"] = "Omen of Clarity",
	["单手斧"] = "One-Handed Axes",
	["单手锤"] = "One-Handed Maces",
	["单手剑"] = "One-Handed Swords",
	["单手武器专精"] = "One-Handed Weapon Specialization",
	["打开"] = "Opening",
	["打开 - No Text"] = "Opening - No Text",
	["伺机而动"] = "Opportunity",
	["压制"] = "Suppression",
	["Pacify"] = "Pacify",
	["Pain Suppression"] = "Pain Suppression",
	["Paralyzing Poison"] = "Paralyzing Poison",
	["多疑"] = "Paranoia",
	["Parasitic Serpent"] = "Parasitic Serpent",
	["招架"] = "Parry",
	["寻路"] = "Pathfinding",
	["感知"] = "Perception",
	["极寒冰霜"] = "Permafrost",
	["宠物好斗"] = "Pet Aggression",
	["宠物耐久"] = "Pet Hardiness",
	["宠物恢复"] = "Pet Recovery",
	["宠物抗魔"] = "Pet Resistance",
	["Petrify"] = "Petrify",
	["相位变换"] = "Phase Shift",
	["偷窃"] = "Pick Pocket",
	["Pierce Armor"] = "Pierce Armor",
	["刺耳怒吼"] = "Piercing Howl",
	["刺骨寒冰"] = "Piercing Ice",
	["Piercing Shadow"] = "Piercing Shadow",
	["Piercing Shot"] = "Piercing Shot",
	["Plague Cloud"] = "Plague Cloud",
	["板甲"] = "Plate Mail",
	["Poison"] = "Poison",
	["Poison Bolt"] = "Poison Bolt",
	["Poison Bolt Volley"] = "Poison Bolt Volley",
	["Poison Cloud"] = "Poison Cloud",
	["Poison Shock"] = "Poison Shock",
	["Poisoned Harpoon"] = "Poisoned Harpoon",
	["Poisoned Shot"] = "Poisoned Shot",
	["Poisonous Blood"] = "Poisonous Blood",
	["毒药"] = "Poisons",
	["长柄武器专精"] = "Polearm Specialization",
	["长柄武器"] = "Polearms",
	["变形术"] = "Polymorph",
	["变形术：猪"] = "Polymorph: Pig",
	["变形术：龟"] = "Polymorph: Turtle",
	["传送门：达纳苏斯"] = "Portal: Darnassus",
	[" 传送门：铁炉堡"] = "Portal: Ironforge",
	["传送门：奥格瑞玛"] = "Portal: Orgrimmar",
	["传送门：暴风城"] = "Portal: Stormwind",
	["传送门：雷霆崖"] = "Portal: Thunder Bluff",
	["传送门：幽暗城"] = "Portal: Undercity",
	["Positive Charge"] = "Positive Charge",
	["突袭"] = "Pounce Bleed",
	["能量灌注"] = "Power Infusion",
	["真言术：韧"] = "Power Word: Fortitude",
	["真言术：盾"] = "Power Word: Shield",
	["Prayer Beads Blessing"] = "Prayer Beads Blessing",
	["坚韧祷言"] = "Prayer of Fortitude",
	["治疗祷言"] = "Prayer of Healing",
	["Prayer of Mending"] = "Prayer of Mending",
	["暗影防护祷言"] = "Prayer of Shadow Protection",
	["精神祷言"] = "Prayer of Spirit",
	["精确"] = "Precision",
	["猛兽攻击"] = "Predatory Strikes",
	["预谋"] = "Premeditation",
	["伺机待发"] = "Preparation",
	["气定神闲"] = "Presence of Mind",
	["原始狂怒"] = "Primal Fury",
	["潜伏"] = "Prowl",
	["心灵尖啸"] = "Psychic Scream",
	["拳击"] = "Pummel",
	["Puncture"] = "Puncture",
	["净化术"] = "Purge",
	["净化"] = "Purification",
	["纯净术"] = "Purify",
	["正义追击"] = "Pursuit of Justice",
	["Putrid Breath"] = "Putrid Breath",
	["Putrid Enzyme"] = "Putrid Enzyme",
	["炎爆术"] = "Pyroblast",
	["火焰冲撞"] = "Pyroclasm",
	["快速射击"] = "Quick Shots",
	["迅捷"] = "Quickness",
	["Radiation"] = "Radiation",
	["Radiation Bolt"] = "Radiation Bolt",
	["Radiation Cloud"] = "Radiation Cloud",
	["Radiation Poisoning"] = "Radiation Poisoning",
	["火焰之雨"] = "Rain of Fire",
	["扫击"] = "Rake",
	["骑术：羊"] = "Ram Riding",
	["Rampage"] = "Rampage",
	["远程武器专精"] = "Ranged Weapon Specialization",
	["迅速隐蔽"] = "Rapid Concealment",
	["急速射击"] = "Rapid Fire",
	["骑术：迅猛龙"] = "Raptor Riding",
	["猛禽一击"] = "Raptor Strike",
	["Ravenous Claw"] = "Ravenous Claw",
	["准备就绪"] = "Readiness",
	["复生"] = "Reincarnation",
	["Rebuild"] = "Rebuild",
	["Recently Bandaged"] = "Recently Bandaged",
	["无畏冲锋"] = "Reckless Charge",
	["鲁莽"] = "Recklessness",
	["Recombobulate"] = "Recombobulate",
	["救赎"] = "Redemption",
	["盾牌壁垒"] = "Redoubt",
	["反射"] = "Reflection",
	["回复"] = "Regeneration",
	["愈合"] = "Regrowth",
	["回春术"] = "Rejuvenation",
	["无情打击"] = "Relentless Strikes",
	["冷酷"] = "Remorseless",
	["冷酷攻击"] = "Remorseless Attacks",
	["解除诅咒"] = "Remove Curse",
	["解除徽记"] = "Remove Insignia",
	["解除次级诅咒"] = "Remove Lesser Curse",
	["撕裂"] = "Rend",
	["恢复"] = "Renew",
	["忏悔"] = "Repentance",
	["Repulsive Gaze"] = "Repulsive Gaze",
	["Restorative Totems"] = "Restorative Totems",
	["复活"] = "Resurrection",
	["反击风暴"] = "Retaliation",
	["惩罚光环"] = "Retribution Aura",
	["复仇"] = "Vengeance",
	["复仇昏迷"] = "Revenge Stun",
	["回响"] = "Reverberation",
	["复活宠物"] = "Revive Pet",
	["Rhahk'Zor Slam"] = "Rhahk'Zor Slam",
	["Ribbon of Souls"] = "Ribbon of Souls",
	["Righteous Defense"] = "Righteous Defense",
	["正义之怒"] = "Righteous Fury",
	["撕扯"] = "Rip",
	["还击"] = "Riposte",
	["末日仪式"] = "Ritual of Doom",
	["末日仪式效果"] = "Ritual of Doom Effect",
	["Ritual of Souls"] = "Ritual of Souls",
	["召唤仪式"] = "Ritual of Summoning",
	["石化武器"] = "Rockbiter Weapon",
	["盗贼被动效果"] = "Rogue Passive",
	["劣质磨刀石"] = "Rough Sharpening Stone",
	["割裂"] = "Rupture",
	["无情"] = "Ruthlessness",
	["牺牲"] = "Sacrifice",
	["安全降落"] = "Safe Fall",
	["圣洁光环"] = "Sanctity Aura",
	["闷棍"] = "Sap",
	["野蛮暴怒"] = "Savage Fury",
	["野蛮打击"] = "Savage Strikes",
	["恐吓野兽"] = "Scare Beast",
	["驱散射击"] = "Scatter Shot",
	["灼烧"] = "Scorch",
	["蝎毒"] = "Scorpid Poison",
	["毒蝎钉刺"] = "Scorpid Sting",
	["Screams of the Past"] = "Screams of the Past",
	["尖啸"] = "Screech",
	["封印命运"] = "Seal Fate",
	["Seal of Blood"] = "Seal of Blood",
	["命令圣印"] = "Seal of Command",
	["公正圣印"] = "Seal of Justice",
	["光明圣印"] = "Seal of Light",
	["Seal of Reckoning"] = "Seal of Reckoning",
	["正义圣印"] = "Seal of Righteousness",
	["十字军圣印"] = "Seal of the Crusader",
	["Seal of Vengeance"] = "Seal of Vengeance",
	["智慧圣印"] = "Seal of Wisdom",
	["灼热之光"] = "Searing Light",
	["灼热之痛"] = "Searing Pain",
	["灼热图腾"] = "Searing Totem",
	["Second Wind"] = "Second Wind",
	["诱惑"] = "Seduction",
	["Seed of Corruption"] = "Seed of Corruption",
	["感知恶魔"] = "Sense Demons",
	["感知亡灵"] = "Sense Undead",
	["岗哨图腾"] = "Sentry Totem",
	["毒蛇钉刺"] = "Serpent Sting",
	["调整"] = "Setup",
	["束缚亡灵"] = "Shackle Undead",
	["暗影亲和"] = "Shadow Affinity",
	["暗影箭"] = "Shadow Bolt",
	["Shadow Bolt Volley"] = "Shadow Bolt Volley",
	["暗影集中"] = "Shadow Focus",
	["暗影掌握"] = "Shadow Mastery",
	["暗影防护"] = "Shadow Protection",
	["暗影延伸"] = "Shadow Reach",
	["暗影抗性"] = "Shadow Resistance",
	["暗影抗性光环"] = "Shadow Resistance Aura",
	["Shadow Shock"] = "Shadow Shock",
	["暗影冥思"] = "Shadow Trance",
	["暗影易伤"] = "Shadow Vulnerability",
	["防护暗影结界"] = "Shadow Ward",
	["Shadow Weakness"] = "Shadow Weakness",
	["暗影之波"] = "Shadow Weaving",
	["Shadow Word: Death"] = "Shadow Word: Death",
	["暗言术：痛"] = "Shadow Word: Pain",
	["暗影灼烧"] = "Shadowburn",
	["Shadowfiend"] = "Shadowfiend",
	["暗影形态"] = "Shadowform",
	["Shadowfury"] = "Shadowfury",
	["暗影守卫"] = "Shadowguard",
	["影遁"] = "Shadowmeld Passive",
	["Shadowstep"] = "Shadowstep",
	["Shamanistic Rage"] = "Shamanistic Rage",
	["锋利兽爪"] = "Sharpened Claws",
	["碎冰"] = "Shatter",
	["Sheep"] = "Sheep",
	["甲壳护盾"] = "Shell Shield",
	["盾牌"] = "Shield",
	["盾击"] = "Shield Bash",
	["盾击 - 沉默"] = "Shield Bash - Silenced",
	["盾牌格挡"] = "Shield Block",
	["盾牌猛击"] = "Shield Slam",
	["盾牌专精"] = "Shield Specialization",
	["盾墙"] = "Shield Wall",
	["Shiv"] = "Shiv",
	["Shock"] = "Shock",
	["射击"] = "Shoot",
	["弓射击"] = "Shoot Bow",
	["弩射击"] = "Shoot Crossbow",
	["枪械射击"] = "Shoot Gun",
	["撕碎"] = "Shred",
	["Shrink"] = "Shrink",
	["沉默"] = "Silence",
	["Silencing Shot"] = "Silencing Shot",
	["无声消退"] = "Silent Resolve",
	["邪恶攻击"] = "Sinister Strike",
	["生命虹吸"] = "Siphon Life",
	["剥皮"] = "Skinning",
	["Skull Crack"] = "Skull Crack",
	["猛击"] = "Slam",
	["沉睡"] = "Sleep",
	["切割"] = "Slice and Dice",
	["Slow"] = "Slow",
	["缓落术"] = "Slow Fall",
	["Slowing Poison"] = "Slowing Poison",
	["熔炼"] = "Smelting",
	["惩击"] = "Smite",
	["Smite Slam"] = "Smite Slam",
	["Smite Stomp"] = "Smite Stomp",
	["Smoke Bomb"] = "Smoke Bomb",
	["Snake Trap"] = "Snake Trap",
	["Snap Kick"] = "Snap Kick",
	["坚固的磨刀石"] = "Solid Sharpening Stone",
	["Sonic Burst"] = "Sonic Burst",
	["安抚动物"] = "Soothe Animal",
	["安抚之吻"] = "Soothing Kiss",
	["Soul Bite"] = "Soul Bite",
	["Soul Drain"] = "Soul Drain",
	["灵魂之火"] = "Soul Fire",
	["灵魂链接"] = "Soul Link",
	["灵魂虹吸"] = "Soul Siphon",
	["Soul Tap"] = "Soul Tap",
	["Soulshatter"] = "Soulshatter",
	["灵魂石复活"] = "Soulstone Resurrection",
	["法术封锁"] = "Spell Lock",
	["Spell Reflection"] = "Spell Reflection",
	["法术屏障"] = "Spell Warding",
	["Spellsteal"] = "Spellsteal",
	["灵魂连接"] = "Spirit Bond",
	["Spirit Burst"] = "Spirit Burst",
	["救赎之魂"] = "Spirit of Redemption",
	["精神分流"] = "Spirit Tap",
	["Spiritual Attunement"] = "Spiritual Attunement",
	["精神集中"] = "Spiritual Focus",
	["精神指引"] = "Spiritual Guidance",
	["精神治疗"] = "Spiritual Healing",
	["Spit"] = "Spit",
	["Spore Cloud"] = "Spore Cloud",
	["疾跑"] = "Sprint",
	["Stance Mastery"] = "Stance Mastery",
	["星火术"] = "Starfire",
	["星火昏迷"] = "Starfire Stun",
	["星辰碎片"] = "Starshards",
	["法杖"] = "Staves",
	["稳固射击"] = "Steady Shot",
	["潜行"] = "Stealth",
	["石爪图腾"] = "Stoneclaw Totem",
	["石像形态"] = "Stoneform",
	["石肤图腾"] = "Stoneskin Totem",
	["风暴打击"] = "Stormstrike",
	["大地之力图腾"] = "Strength of Earth Totem",
	["Strike"] = "Strike",
	["卡死"] = "Stuck",
	["Stun"] = "Stun",
	["微妙"] = "Subtlety",
	["受难"] = "Suffering",
	["召唤战马"] = "Summon Charger",
	["召唤恐惧战马"] = "Summon Dreadsteed",
	["Summon Felguard"] = "Summon Felguard",
	["召唤地狱猎犬"] = "Summon Felhunter",
	["召唤地狱战马"] = "Summon Felsteed",
	["召唤小鬼"] = "Summon Imp",
	["Summon Spawn of Bael'Gar"] = "Summon Spawn of Bael'Gar",
	["召唤魅魔"] = "Summon Succubus",
	["召唤虚空行者"] = "Summon Voidwalker",
	["召唤军马"] = "Summon Warhorse",
	["Summon Water Elemental"] = "Summon Water Elemental",
	["稳固"] = "Surefooted",
	["生存专家"] = "Survivalist",
	["Sweeping Slam"] = "Sweeping Slam",
	["横扫攻击"] = "Sweeping Strikes",
	["迅捷治愈"] = "Swiftmend",
	["挥击"] = "Swipe",
	["Swoop"] = "Swoop",
	["剑类武器专精"] = "Sword Specialization",
	["战术掌握"] = "Tactical Mastery",
	["裁缝"] = "Tailoring",
	["腐坏之血"] = "Tainted Blood",
	["驯服野兽"] = "Tame Beast",
	["驯服宠物（被动）"] = "Tamed Pet Passive",
	["嘲讽"] = "Taunt",
	["传送：达纳苏斯"] = "Teleport: Darnassus",
	["传送：铁炉堡"] = "Teleport: Ironforge",
	["传送：月光林地"] = "Teleport: Moonglade",
	["传送：奥格瑞玛"] = "Teleport: Orgrimmar",
	["传送：暴风城"] = "Teleport: Stormwind",
	["传送：雷霆崖"] = "Teleport: Thunder Bluff",
	["传送：幽暗城"] = "Teleport: Undercity",
	["Tendon Rip"] = "Tendon Rip",
	["Tendon Slice"] = "Tendon Slice",
	["Terrify"] = "Terrify",
	["Terrifying Screech"] = "Terrifying Screech",
	["厚皮"] = "Thick Hide",
	["Thorn Volley"] = "Thorn Volley",
	["荆棘术"] = "Thorns",
	["Thousand Blades"] = "Thousand Blades",
	["Threatening Gaze"] = "Threatening Gaze",
	["投掷"] = "Thrown",
	["Throw Axe"] = "Throw Axe",
	["Throw Dynamite"] = "Throw Dynamite",
	["Throw Liquid Fire"] = "Throw Liquid Fire",
	["Throw Wrench"] = "Throw Wrench",
	["投掷专精"] = "Throwing Specialization",
	["投掷武器专精"] = "Throwing Weapon Specialization",
	["雷霆一击"] = "Thunder Clap",
	["Thunderclap"] = "Thunderclap",
	["Thunderfury"] = "Thunderfury",
	["雷鸣猛击"] = "Thundering Strikes",
	["Thundershock"] = "Thundershock",
	["雷霆践踏"] = "Thunderstomp",
	["潮汐集中"] = "Tidal Focus",
	["潮汐掌握"] = "Tidal Mastery",
	["骑术：豹"] = "Tiger Riding",
	["猛虎之怒"] = "Tiger's Fury",
	["折磨"] = "Torment",
	["图腾"] = "Totem",
	["Totem of Wrath"] = "Totem of Wrath",
	["图腾集中"] = "Totemic Focus",
	["虚弱之触"] = "Touch of Weakness",
	["Toxic Saliva"] = "Toxic Saliva",
	["Toxic Spit"] = "Toxic Spit",
	["Toxic Volley"] = "Toxic Volley",
	["Traces of Silithyst"] = "Traces of Silithyst",
	["追踪野兽"] = "Track Beasts",
	["追踪恶魔"] = "Track Demons",
	["追踪龙类"] = "Track Dragonkin",
	["追踪元素生物"] = "Track Elementals",
	["追踪巨人"] = "Track Giants",
	["追踪隐藏生物"] = "Track Hidden",
	["追踪人型生物"] = "Track Humanoids",
	["追踪亡灵"] = "Track Undead",
	["Trample"] = "Trample",
	["宁静之风图腾"] = "Tranquil Air Totem",
	["宁静之魂"] = "Tranquil Spirit",
	["宁静"] = "Tranquility",
	["Tranquilizing Poison"] = "Tranquilizing Poison",
	["宁神射击"] = "Tranquilizing Shot",
	["陷阱掌握"] = "Trap Mastery",
	["旅行形态"] = "Travel Form",
	["Tree of Life"] = "Tree of Life",
	["战栗图腾"] = "Tremor Totem",
	["部族制皮"] = "Tribal Leatherworking",
	["强击光环"] = "Trueshot Aura",
	["超度亡灵"] = "Turn Undead",
	["Twisted Tranquility"] = "Twisted Tranquility",
	["双手斧"] = "Two-Handed Axes",
	["双手斧和锤"] = "Two-Handed Axes and Maces",
	["双手锤"] = "Two-Handed Maces",
	["无光泽的双刃刀"] = "Two-Handed Swords",
	["双手武器专精"] = "Two-Handed Weapon Specialization",
	["徒手"] = "Unarmed",
	["坚定意志"] = "Unbreakable Will",
	["怒不可遏"] = "Unbridled Wrath",
	["Unbridled Wrath Effect"] = "Unbridled Wrath Effect",
	["骑术：骸骨战马"] = "Undead Horsemanship",
	["水下呼吸"] = "Water Breathing",
	["魔息术"] = "Unending Breath",
	["Unholy Frenzy"] = "Unholy Frenzy",
	["邪恶强化"] = "Unholy Power",
	["狂怒释放"] = "Unleashed Fury",
	["Unleashed Rage"] = "Unleashed Rage",
	["Unstable Affliction"] = "Unstable Affliction",
	["Unstable Concoction"] = "Unstable Concoction",
	["Unstable Power"] = "Unstable Power",
	["不灭信仰"] = "Unyielding Faith",
	["Uppercut"] = "Uppercut",
	["吸血鬼的拥抱"] = "Vampiric Embrace",
	["Vampiric Touch"] = "Vampiric Touch",
	["消失"] = "Vanished",
	["Veil of Shadow"] = "Veil of Shadow",
	["Venom Spit"] = "Venom Spit",
	["Venom Sting"] = "Venom Sting",
	["Venomhide Poison"] = "Venomhide Poison",
	["Vicious Rend"] = "Vicious Rend",
	["Victory Rush"] = "Victory Rush",
	["精力"] = "Vigor",
	["恶性毒药"] = "Vile Poisons",
	["辩护"] = "Vindication",
	["蝰蛇钉刺"] = "Viper Sting",
	["Virulent Poison"] = "Virulent Poison",
	["Void Bolt"] = "Void Bolt",
	["乱射"] = "Volley",
	["Walking Bomb Effect"] = "Walking Bomb Effect",
	["魔杖掌握"] = "Wand Specialization",
	["Wandering Plague"] = "Wandering Plague",
	["魔杖"] = "Wands",
	["战争践踏"] = "War Stomp",
	["Water"] = "Water",
	["Water Shield"] = "Water Shield",
	["水上行走"] = "Water Walking",
	["Waterbolt"] = "Waterbolt",
	["Wavering Will"] = "Wavering Will",
	["虚弱灵魂"] = "Weakened Soul",
	["武器锻造师"] = "Weaponsmith",
	["Web"] = "Web",
	["Web Explosion"] = "Web Explosion",
	["Web Spin"] = "Web Spin",
	["Web Spray"] = "Web Spray",
	["Whirling Barrage"] = "Whirling Barrage",
	["Whirling Trip"] = "Whirling Trip",
	["旋风斩"] = "Whirlwind",
	["Wide Slash"] = "Wide Slash",
	["Will of Hakkar"] = "Will of Hakkar",
	["亡灵意志"] = "Will of the Forsaken",
	["风怒图腾"] = "Windfury Totem",
	["风怒武器"] = "Windfury Weapon",
	["Windsor's Frenzy"] = "Windsor's Frenzy",
	["风墙图腾"] = "Windwall Totem",
	["摔绊"] = "Wing Clip",
	["Wing Flap"] = "Wing Flap",
	["深冬之寒"] = "Winter's Chill",
	["精灵之魂"] = "Wisp Spirit",
	["骑术：狼"] = "Wolf Riding",
	["致伤毒药"] = "Wound Poison",
	["致伤毒药 II"] = "Wound Poison II",
	["致伤毒药 III"] = "Wound Poison III",
	["致伤毒药 IV"] = "Wound Poison IV",
	["愤怒"] = "Wrath",
	["Wrath of Air Totem"] = "Wrath of Air Totem",
	["翼龙钉刺"] = "Wyvern Sting",
}

end)
__bundle_register("Locale/zhCN/Spell.zhCN.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
	["Aspect of the Wolf"] = "孤狼守护",

	-- Vanilla 1.12
	["Abolish Disease"] = "驱除疾病",
	["Abolish Poison"] = "驱毒术",
	["Abolish Poison Effect"] = "驱毒术效果",
	["Acid Breath"] = "Acid Breath",-- TODO translate
	["Acid of Hakkar"] = "Acid of Hakkar",-- TODO translate
	["Acid Spit"] = "Acid Spit",-- TODO translate
	["Acid Splash"] = "Acid Splash",-- TODO translate
	["Activate MG Turret"] = "速射炮台",
	["Adrenaline Rush"] = "冲动",
	["Aftermath"] = "清算",
	["Aggression"] = "侵略",
	["Aimed Shot"] = "瞄准射击",
	["Alchemy"] = "炼金术",
	["Ambush"] = "伏击",
	["Amplify Curse"] = "诅咒增幅",
	["Amplify Damage"] = "Amplify Damage",-- TODO translate
	["Amplify Flames"] = "Amplify Flames",-- TODO translate
	["Amplify Magic"] = "魔法增效",
	["Ancestral Fortitude"] = "先祖坚韧",
	["Ancestral Healing"] = "先祖治疗",
	["Ancestral Knowledge"] = "先祖知识",
	["Ancestral Spirit"] = "先祖之魂",
	["Anesthetic Poison"] = "Anesthetic Poison",-- TODO translate
	["Anger Management"] = "愤怒掌控",
	["Anguish"] = "Anguish",-- TODO translate
	["Anticipation"] = "预知",
	["Aqua Jet"] = "Aqua Jet",-- TODO translate
	["Aquatic Form"] = "水栖形态",
	["Arcane Blast"] = "Arcane Blast",-- TODO translate
	["Arcane Bolt"] = "Arcane Bolt",-- TODO translate
	["Arcane Brilliance"] = "奥术光辉",
	["Arcane Concentration"] = "奥术专注",
	["Arcane Explosion"] = "魔爆术",
	["Arcane Focus"] = "奥术集中",
	["Arcane Instability"] = "奥术增效",
	["Arcane Intellect"] = "奥术智慧",
	["Arcane Meditation"] = "奥术冥想",
	["Arcane Mind"] = "奥术心智",
	["Arcane Missiles"] = "奥术飞弹",
	["Arcane Potency"] = "Arcane Potency",
	["Arcane Power"] = "奥术强化",
	["Arcane Resistance"] = "奥术抗性",
	["Arcane Shot"] = "奥术射击",
	["Arcane Subtlety"] = "奥术精妙",
	["Arcane Weakness"] = "Arcane Weakness",
	["Arcing Smash"] = "Arcing Smash",-- TODO translate
	["Arctic Reach"] = "极寒延伸",
	["Armorsmith"] = "护甲锻造师",
	["Arugal's Curse"] = "Arugal's Curse",-- TODO translate
	["Arugal's Gift"] = "Arugal's Gift",-- TODO translate
	["Ascendance"] = "Ascendance",-- TODO translate
	["Aspect of Arlokk"] = "Aspect of Arlokk",-- TODO translate
	["Aspect of Jeklik"] = "Aspect of Jeklik",-- TODO translate
	["Aspect of Mar'li"] = "Aspect of Mar'li",-- TODO translate
	["Aspect of the Beast"] = "野兽守护",
	["Aspect of the Cheetah"] = "猎豹守护",
	["Aspect of the Hawk"] = "雄鹰守护",
	["Aspect of the Monkey"] = "灵猴守护",
	["Aspect of the Pack"] = "豹群守护",
	["Aspect of the Viper"] = "Aspect of the Viper",-- TODO translate
	["Aspect of the Wild"] = "野性守护",
	["Aspect of Venoxis"] = "Aspect of Venoxis",-- TODO translate
	["Astral Recall"] = "星界传送",
	["Attack"] = "攻击",
	["Attacking"] = "攻击",
	["Aura of Command"] = "Aura of Command",-- TODO translate
	["Aural Shock"] = "Aural Shock",-- TODO translate
	["Auto Shot"] = "自动射击",
	["Avenger's Shield"] = "Avenger's Shield",-- TODO translate
	["Avenging Wrath"] = "Avenging Wrath",-- TODO translate
	["Avoidance"] = "Avoidance",
	["Axe Flurry"] = "Axe Flurry",-- TODO translate
	["Axe Specialization"] = "斧专精",
	["Axe Toss"] = "Axe Toss",-- TODO translate
	["Backhand"] = "Backhand",-- TODO translate
	["Backlash"] = "Backlash",-- TODO translate
	["Backstab"] = "背刺",
	["Bane"] = "灾祸",
	["Baneful Poison"] = "Baneful Poison",-- TODO translate
	["Banish"] = "放逐术",
	["Banshee Curse"] = "Banshee Curse",-- TODO translate
	["Banshee Shriek"] = "Banshee Shriek",-- TODO translate
	["Barbed Sting"] = "Barbed Sting",-- TODO translate
	["Barkskin"] = "树皮术",
	["Barkskin Effect"] = "树皮术效果",
	["Barrage"] = "弹幕",
	["Bash"] = "重击",
	["Basic Campfire"] = "基础营火",
	["Battle Shout"] = "战斗怒吼",
	["Battle Stance"] = "战斗姿态",
	["Battle Stance Passive"] = "战斗姿态（被动）",
	["Bear Form"] = "熊形态",
	["Beast Lore"] = "野兽知识",
	["Beast Slaying"] = "野兽杀手",
	["Beast Training"] = "训练野兽",
	["The Beast Within"] = "The Beast Within",-- TODO translate
	["Befuddlement"] = "Befuddlement",-- TODO translate
	["Benediction"] = "祈福",
	["Berserker Charge"] = "Berserker Charge",-- TODO translate
	["Berserker Rage"] = "狂暴之怒",
	["Berserker Stance"] = "狂暴姿态",
	["Berserker Stance Passive"] = "狂暴姿态（被动）",
	["Berserking"] = "狂暴",
	["Bestial Discipline"] = "野兽戒律",
	["Bestial Swiftness"] = "野兽迅捷",
	["Bestial Wrath"] = "狂野怒火",
	["Biletoad Infection"] = "Biletoad Infection",-- TODO translate
	["Binding Heal"] = "Binding Heal",-- TODO translate
	["Bite"] = "撕咬",
	["Black Arrow"] = "黑箭",
	["Blackout"] = "昏阙",
	["Blacksmithing"] = "锻造",
	["Blade Flurry"] = "剑刃乱舞",
	["Blast Wave"] = "冲击波",
	["Blaze"] = "Blaze",-- TODO translate
	["Blazing Speed"] = "Blazing Speed",-- TODO translate
	["Blessed Recovery"] = "神恩回复",
	["Blessing of Blackfathom"] = "Blessing of Blackfathom",-- TODO translate
	["Blessing of Freedom"] = "自由祝福",
	["Blessing of Kings"] = "王者祝福",
	["Blessing of Light"] = "光明祝福",
	["Blessing of Might"] = "力量祝福",
	["Blessing of Protection"] = "保护祝福",
	["Blessing of Sacrifice"] = "牺牲祝福",
	["Blessing of Salvation"] = "拯救祝福",
	["Blessing of Sanctuary"] = "庇护祝福",
	["Blessing of Shahram"] = "Blessing of Shahram",-- TODO translate
	["Blessing of Wisdom"] = "智慧祝福",
	["Blind"] = "致盲",
	["Blinding Powder"] = "致盲粉",
	["Blink"] = "闪现术",
	["Blizzard"] = "暴风雪",
	["Block"] = "格挡",
	["Blood Craze"] = "血之狂热",
	["Blood Frenzy"] = "血之狂暴",
	["Blood Funnel"] = "Blood Funnel",-- TODO translate
	["Blood Fury"] = "血性狂暴",
	["Blood Leech"] = "Blood Leech",-- TODO translate
	["Blood Pact"] = "血之契印",
	["Blood Siphon"] = "Blood Siphon",-- TODO translate
	["Blood Tap"] = "Blood Tap",-- TODO translate
	["Bloodlust"] = "Bloodlust",
	["Bloodrage"] = "血性狂暴",
	["Bloodthirst"] = "残忍",
	["Bomb"] = "Bomb",-- TODO translate
	["Booming Voice"] = "震耳嗓音",
	["Boulder"] = "Boulder",-- TODO translate
	["Bow Specialization"] = "弓专精",
	["Bows"] = "弓",
	["Brain Wash"] = "Brain Wash",-- TODO translate
	["Bright Campfire"] = "明亮篝火",
	["Brutal Impact"] = "野蛮冲撞",
	["Burning Adrenaline"] = "Burning Adrenaline",
	["Burning Soul"] = "燃烧之魂",
	["Burning Wish"] = "Burning Wish",
	["Butcher Drain"] = "Butcher Drain",-- TODO translate
	["Call of Flame"] = "烈焰召唤",
	["Call of the Grave"] = "Call of the Grave",-- TODO translate
	["Call of Thunder"] = "雷霆召唤",
	["Call Pet"] = "召唤宠物",
	["Camouflage"] = "伪装",
	["Cannibalize"] = "食尸",
	["Cat Form"] = "猎豹形态",
	["Cataclysm"] = "灾变",
	["Cause Insanity"] = "Cause Insanity",-- TODO translate
	["Chain Bolt"] = "Chain Bolt",-- TODO translate
	["Chain Burn"] = "Chain Burn",-- TODO translate
	["Chain Heal"] = "治疗链",
	["Chain Lightning"] = "闪电链",
	["Chained Bolt"] = "Chained Bolt",-- TODO translate
	["Chains of Ice"] = "Chains of Ice",-- TODO translate
	["Challenging Roar"] = "挑战咆哮",
	["Challenging Shout"] = "挑战怒吼",
	["Charge"] = "冲锋",
	["Charge Rage Bonus Effect"] = "冲锋额外怒气效果",-- [TODO Translate not sure about this one]
	["Charge Stun"] = "冲锋击昏",
	["Cheap Shot"] = "偷袭",
	["Chilled"] = "冰冻",
	["Chilling Touch"] = "Chilling Touch",-- TODO translate
	["Chromatic Infusion"] = "Chromatic Infusion",-- TODO translate
	["Circle of Healing"] = "Circle of Healing",-- TODO translate
	["Claw"] = "爪击",
	["Cleanse"] = "清洁术",
	["Cleanse Nova"] = "Cleanse Nova",-- TODO translate
	["Clearcasting"] = "节能施法",
	["Cleave"] = "顺劈斩",
	["Clever Traps"] = "灵巧陷阱",
	["Cloak of Shadows"] = "Cloak of Shadows",-- TODO translate
	["Closing"] = "关闭",
	["Cloth"] = "布甲",
	["Coarse Sharpening Stone"] = "粗制磨刀石",
	["Cobra Reflexes"] = "毒蛇反射",
	["Cold Blood"] = "冷血",
	["Cold Snap"] = "急速冷却",
	["Combat Endurance"] = "作战持久",
	["Combustion"] = "燃烧",
	["Command"] = "命令",
	["Commanding Shout"] = "Commanding Shout",
	["Concentration Aura"] = "专注光环",
	["Concussion"] = "震荡",
	["Concussion Blow"] = "震荡猛击",
	["Concussive Shot"] = "震荡射击",
	["Cone of Cold"] = "冰锥术",
	["Conflagrate"] = "燃烧",
	["Conjure Food"] = "造食术",
	["Conjure Mana Agate"] = "制造魔法玛瑙",
	["Conjure Mana Citrine"] = "制造魔法黄水晶",
	["Conjure Mana Jade"] = "制造魔法翡翠",
	["Conjure Mana Ruby"] = "制造魔法红宝石",
	["Conjure Water"] = "造水术",
	["Consecrated Sharpening Stone"] = "Consecrated Sharpening Stone",-- TODO translate
	["Consecration"] = "奉献",
	["Consume Magic"] = "Consume Magic",-- TODO translate
	["Consume Shadows"] = "吞噬暗影",
	["Consuming Shadows"] = "Consuming Shadows",-- TODO translate
	["Convection"] = "传导",
	["Conviction"] = "定罪",
	["Cooking"] = "烹饪",
	["Corrosive Acid Breath"] = "Corrosive Acid Breath",-- TODO translate
	["Corrosive Ooze"] = "Corrosive Ooze",-- TODO translate
	["Corrosive Poison"] = "Corrosive Poison",-- TODO translate
	["Corrupted Blood"] = "Corrupted Blood",-- TODO translate
	["Corruption"] = "腐蚀",
	["Counterattack"] = "反击",
	["Counterspell"] = "法术反制",
	["Counterspell - Silenced"] = "法术反制 - 沉默",
	["Cower"] = "畏缩",
	["Create Firestone"] = "制造火焰石",
	["Create Firestone (Greater)"] = "制造强效火焰石",
	["Create Firestone (Lesser)"] = "制造次级火焰石",
	["Create Firestone (Major)"] = "制造极效火焰石",
	["Create Healthstone"] = "制造治疗石",
	["Create Healthstone (Greater)"] = "制造强效治疗石",
	["Create Healthstone (Lesser)"] = "制造次级治疗石",
	["Create Healthstone (Major)"] = "制造极效治疗石",
	["Create Healthstone (Minor)"] = "制造初级治疗石",
	["Create Soulstone"] = "制造灵魂石",
	["Create Soulstone (Greater)"] = "制造强效灵魂石",
	["Create Soulstone (Lesser)"] = "制造次级灵魂石",
	["Create Soulstone (Major)"] = "制造极效灵魂石",
	["Create Soulstone (Minor)"] = "制造初级灵魂石",
	["Create Spellstone"] = "制造法术石",
	["Create Spellstone (Greater)"] = "制造强效法术石",
	["Create Spellstone (Major)"] = "制造极效法术石",
	["Create Spellstone (Master)"] = "Create Spellstone (Master)",-- TODO translate
	["Creeper Venom"] = "Creeper Venom",-- TODO translate
	["Cripple"] = "Cripple",-- TODO translate
	["Crippling Poison"] = "致残毒药",
	["Crippling Poison II"] = "致残毒药 II",
	["Critical Mass"] = "火焰重击",
	["Crossbows"] = "弩",
	["Crowd Pummel"] = "Crowd Pummel",-- TODO translate
	["Cruelty"] = "残忍",
	["Crusader Aura"] = "Crusader Aura",-- TODO translate
	["Crusader Strike"] = "Crusader Strike",
	["Crusader's Wrath"] = "Crusader's Wrath",-- TODO translate
	["Crystal Charge"] = "Crystal Charge",-- TODO translate
	["Crystal Force"] = "Crystal Force",-- TODO translate
	["Crystal Restore"] = "Crystal Restore",-- TODO translate
	["Crystal Spire"] = "Crystal Spire",-- TODO translate
	["Crystal Ward"] = "Crystal Ward",-- TODO translate
	["Crystal Yield"] = "Crystal Yield",-- TODO translate
	["Crystalline Slumber"] = "Crystalline Slumber",-- TODO translate
	["Cultivation"] = "栽培",
	["Cure Disease"] = "祛病术",
	["Cure Poison"] = "消毒术",
	["Curse of Agony"] = "痛苦诅咒",
	["Curse of Blood"] = "Curse of Blood",-- TODO translate
	["Curse of Doom"] = "厄运诅咒",
	["Curse of Doom Effect"] = "厄运诅咒效果",
	["Curse of Exhaustion"] = "疲劳诅咒",
	["Curse of Idiocy"] = "痴呆诅咒",
	["Curse of Recklessness"] = "鲁莽诅咒",
	["Curse of Shadow"] = "暗影诅咒",
	["Curse of the Deadwood"] = "Curse of the Deadwood",-- TODO translate
	["Curse of the Elemental Lord"] = "Curse of the Elemental Lord",-- TODO translate
	["Curse of the Elements"] = "元素诅咒",
	["Curse of Tongues"] = "语言诅咒",
	["Curse of Tuten'kash"] = "Curse of Tuten'kash",-- TODO translate
	["Curse of Weakness"] = "虚弱诅咒",
	["Cursed Blood"] = "Cursed Blood",-- TODO translate
	["Cyclone"] = "Cyclone",
	["Dagger Specialization"] = "匕首专精",
	["Daggers"] = "匕首",
	["Dampen Magic"] = "魔法抑制",
	["Dark Iron Bomb"] = "Dark Iron Bomb",-- TODO translate
	["Dark Offering"] = "Dark Offering",-- TODO translate
	["Dark Pact"] = "黑暗契约",
	["Darkness"] = "黑暗",
	["Dash"] = "急奔",
	["Dazed"] = "Dazed",
	["Deadly Poison"] = "致命毒药",
	["Deadly Poison II"] = "致命毒药 II",
	["Deadly Poison III"] = "致命毒药 III",
	["Deadly Poison IV"] = "致命毒药 IV",
	["Deadly Poison V"] = "致命毒药 V",
	["Deadly Throw"] = "Deadly Throw",-- TODO translate
	["Death Coil"] = "死亡缠绕",
	["Death Wish"] = "死亡之愿",
	["Deep Sleep"] = "Deep Sleep",-- TODO translate
	["Deep Slumber"] = "Deep Slumber",-- TODO translate
	["Deep Wounds"] = "重度伤口",
	["Defense"] = "防御",
	["Defensive Stance"] = "防御姿态",
	["Defensive Stance Passive"] = "防御姿态（被动）",
	["Defensive State"] = "防御状态",-- [TODO Translate not sure about this one]
	["Defensive State 2"] = "防御状态 2",-- [TODO Translate not sure about this one]
	["Defiance"] = "挑衅",
	["Deflection"] = "偏斜",
	["Delusions of Jin'do"] = "Delusions of Jin'do",-- TODO translate
	["Demon Armor"] = "魔甲术",
	["Demon Skin"] = "恶魔皮肤",
	["Demonic Embrace"] = "恶魔之拥",
	["Demonic Frenzy"] = "Demonic Frenzy",
	["Demonic Sacrifice"] = "恶魔牺牲",
	["Demoralizing Roar"] = "挫志咆哮",
	["Demoralizing Shout"] = "挫志怒吼",
	["Dense Sharpening Stone"] = "致密磨刀石",
	["Desperate Prayer"] = "绝望祷言",
	["Destructive Reach"] = "毁灭延伸",
	["Detect"] = "侦测",
	["Detect Greater Invisibility"] = "侦测强效隐形",
	["Detect Invisibility"] = "侦测隐形",
	["Detect Lesser Invisibility"] = "侦测次级隐形",
	["Detect Magic"] = "侦测魔法",
	["Detect Traps"] = "侦测陷阱",
	["Deterrence"] = "威慑",
	["Detonation"] = "Detonation",-- TODO translate
	["Devastate"] = "Devastate",
	["Devastation"] = "毁灭",
	["Devotion Aura"] = "虔诚光环",
	["Devour Magic"] = "吞噬魔法",
	["Devour Magic Effect"] = "吞噬魔法效果",
	["Devouring Plague"] = "噬灵瘟疫",
	["Diamond Flask"] = "Diamond Flask",-- TODO translate
	["Diplomacy"] = "外交",
	["Dire Bear Form"] = "巨熊形态",
	["Dire Growl"] = "Dire Growl",-- TODO translate
	["Disarm"] = "缴械",
	["Disarm Trap"] = "解除陷阱",
	["Disease Cleansing Totem"] = "祛病图腾",
	["Disease Cloud"] = "Disease Cloud",-- TODO translate
	["Diseased Shot"] = "Diseased Shot",-- TODO translate
	["Diseased Spit"] = "Diseased Spit",-- TODO translate
	["Disenchant"] = "分解",
	["Disengage"] = "逃脱",
	["Disjunction"] = "Disjunction",-- TODO translate
	["Dismiss Pet"] = "解散野兽",
	["Dispel Magic"] = "驱散魔法",
	["Distract"] = "扰乱",
	["Distracting Pain"] = "Distracting Pain",-- TODO translate
	["Distracting Shot"] = "扰乱射击",
	["Dive"] = "俯冲",
	["Divine Favor"] = "神恩术",
	["Divine Fury"] = "神圣之怒",
	["Divine Illumination"] = "Divine Illumination",-- TODO translate
	["Divine Intellect"] = "神圣智慧",
	["Divine Intervention"] = "神圣干涉",
	["Divine Protection"] = "圣佑术",
	["Divine Shield"] = "圣盾术",
	["Divine Spirit"] = "神圣之灵",
	["Divine Strength"] = "神圣之力",
	["Diving Sweep"] = "Diving Sweep",-- TODO translate
	["Dodge"] = "躲闪",
	["Dominate Mind"] = "Dominate Mind",-- TODO translate
	["Dragon's Breath"] = "Dragon's Breath",-- TODO translate
	["Dragonscale Leatherworking"] = "龙鳞制皮",
	["Drain Life"] = "吸取生命",
	["Drain Mana"] = "吸取法力",
	["Drain Soul"] = "吸取灵魂",
	["Dredge Sickness"] = "Dredge Sickness",-- TODO translate
	["Drink"] = "喝水",
	["Druid's Slumber"] = "Druid's Slumber",-- TODO translate
	["Dual Wield"] = "双武器",
	["Dual Wield Specialization"] = "双武器专精",
	["Duel"] = "决斗",
	["Dust Field"] = "Dust Field",-- TODO translate
	["Eagle Eye"] = "鹰眼术",
	["Earth Elemental Totem"] = "Earth Elemental Totem",-- TODO translate
	["Earth Shield"] = "Earth Shield",-- TODO translate
	["Earth Shock"] = "大地震击",
	["Earthbind Totem"] = "地缚图腾",
	["Earthborer Acid"] = "Earthborer Acid",-- TODO translate
	["Earthgrab"] = "Earthgrab",-- TODO translate
	["Efficiency"] = "效率",
	["Electric Discharge"] = "Electric Discharge",-- TODO translate
	["Electrified Net"] = "Electrified Net",-- TODO translate
	["Elemental Focus"] = "元素集中",
	["Elemental Fury"] = "元素之怒",
	["Elemental Leatherworking"] = "元素制皮",
	["Elemental Mastery"] = "元素掌握",
	["Elemental Precision"] = "Elemental Precision",
	["Elemental Sharpening Stone"] = "元素磨刀石",
	["Elune's Grace"] = "艾露恩的赐福",
	["Elusiveness"] = "飘忽不定",
	["Emberstorm"] = "琥珀风暴",
	["Enamored Water Spirit"] = "Enamored Water Spirit",-- TODO translate
	["Enchanting"] = "附魔",
	["Endurance"] = "耐久",
	["Endurance Training"] = "耐久训练",
	["Engineering"] = "工程学",
	["Engineering Specialization"] = "工程学专精",
	["Enrage"] = "狂怒",
	["Enriched Manna Biscuit"] = "可口的魔法点心",
	["Enslave Demon"] = "奴役恶魔",
	["Entangling Roots"] = "纠缠根须",
	["Entrapment"] = "诱捕",
	["Enveloping Web"] = "Enveloping Web",-- TODO translate
	["Enveloping Webs"] = "Enveloping Webs",-- TODO translate
	["Enveloping Winds"] = "Enveloping Winds",-- TODO translate
	["Envenom"] = "Envenom",-- TODO translate
	["Ephemeral Power"] = "Ephemeral Power",-- TODO translate
	["Escape Artist"] = "逃命专家",
	["Essence of Sapphiron"] = "Essence of Sapphiron",-- TODO translate
	["Evasion"] = "闪避",
	["Eventide"] = "Eventide",-- TODO translate
	["Eviscerate"] = "剔骨",
	["Evocation"] = "唤醒",
	["Execute"] = "斩杀",
	["Exorcism"] = "驱邪术",
	["Expansive Mind"] = "开阔思维",
	["Exploding Shot"] = "Exploding Shot",-- TODO translate
	["Exploit Weakness"] = "Exploit Weakness",-- TODO translate
	["Explosive Shot"] = "Explosive Shot",-- TODO translate
	["Explosive Trap"] = "爆炸陷阱",
	["Explosive Trap Effect"] = "爆炸陷阱效果",
	["Expose Armor"] = "破甲",
	["Expose Weakness"] = "Expose Weakness",
	["Eye for an Eye"] = "以眼还眼",
	["Eye of Kilrogg"] = "基尔罗格之眼",
	["The Eye of the Dead"] = "The Eye of the Dead",-- TODO translate
	["Eyes of the Beast"] = "野兽之眼",
	["Fade"] = "渐隐术",
	["Faerie Fire"] = "精灵之火",
	["Faerie Fire (Feral)"] = "精灵之火（野性）",
	["Far Sight"] = "视界术",
	["Fatal Bite"] = "Fatal Bite",-- TODO translate
	["Fear"] = "恐惧术",
	["Fear Ward"] = "防护恐惧结界",
	["Feed Pet"] = "喂养宠物",
	["Feedback"] = "回馈",
	["Feign Death"] = "假死",
	["Feint"] = "佯攻",
	["Fel Armor"] = "Fel Armor",-- TODO translate
	["Fel Concentration"] = "恶魔专注",
	["Fel Domination"] = "恶魔支配",
	["Fel Intellect"] = "恶魔智力",
	["Fel Stamina"] = "恶魔耐力",
	["Fel Stomp"] = "Fel Stomp",-- TODO translate
	["Felfire"] = "魔火",
	["Feline Grace"] = "豹之优雅",
	["Feline Swiftness"] = "豹之迅捷",
	["Feral Aggression"] = "野性侵略",
	["Feral Charge"] = "野性冲锋",
	["Feral Instinct"] = "野性本能",
	["Ferocious Bite"] = "凶猛撕咬",
	["Ferocity"] = "凶暴",
	["Fetish"] = "神像",
	["Fevered Plague"] = "Fevered Plague",-- TODO translate
	["Fiery Burst"] = "Fiery Burst",-- TODO translate
	["Find Herbs"] = "寻找草药",
	["Find Minerals"] = "寻找矿物",
	["Find Treasure"] = "寻找财宝",
	["Fire Blast"] = "火焰冲击",
	["Fire Elemental Totem"] = "Fire Elemental Totem",-- TODO translate
	["Fire Nova"] = "Fire Nova",-- TODO translate
	["Fire Nova Totem"] = "火焰新星图腾",
	["Fire Power"] = "火焰强化",
	["Fire Resistance"] = "火焰抗性",
	["Fire Resistance Aura"] = "火焰抗性光环",
	["Fire Resistance Totem"] = "抗火图腾",
	["Fire Shield"] = "火焰之盾",
	["Fire Shield Effect"] = "Fire Shield Effect",-- TODO translate
	["Fire Shield Effect II"] = "Fire Shield Effect II",-- TODO translate
	["Fire Shield Effect III"] = "Fire Shield Effect III",-- TODO translate
	["Fire Shield Effect IV"] = "Fire Shield Effect IV",-- TODO translate
	["Fire Storm"] = "Fire Storm",-- TODO translate
	["Fire Vulnerability"] = "火焰易伤",
	["Fire Ward"] = "防护火焰结界",
	["Fire Weakness"] = "Fire Weakness",
	["Fireball"] = "火球术",
	["Fireball Volley"] = "Fireball Volley",-- TODO translate
	["Firebolt"] = "火焰箭",
	["First Aid"] = "急救",
	["Fishing"] = "钓鱼",
	["Fishing Poles"] = "鱼竿",
	["Fist of Ragnaros"] = "Fist of Ragnaros",-- TODO translate
	["Fist Weapon Specialization"] = "拳套专精",
	["Fist Weapons"] = "拳套",
	["Flame Buffet"] = "Flame Buffet",-- TODO translate
	["Flame Cannon"] = "Flame Cannon",-- TODO translate
	["Flame Lash"] = "Flame Lash",-- TODO translate
	["Flame Shock"] = "烈焰震击",
	["Flame Spike"] = "Flame Spike",-- TODO translate
	["Flame Spray"] = "Flame Spray",-- TODO translate
	["Flame Throwing"] = "烈焰投掷",
	["Flames of Shahram"] = "Flames of Shahram",-- TODO translate
	["Flamestrike"] = "烈焰冲击",
	["Flamethrower"] = "火焰喷射器",
	["Flametongue Totem"] = "火舌图腾",
	["Flametongue Weapon"] = "火舌武器",
	["Flare"] = "照明弹",
	["Flash Bomb"] = "Flash Bomb",-- TODO translate
	["Flash Heal"] = "快速治疗",
	["Flash of Light"] = "圣光闪现",
	["Flight Form"] = "Flight Form",-- TODO translate
	["Flurry"] = "乱舞",
	["Focused Casting"] = "专注施法",
	["Focused Mind"] = "Focused Mind",
	["Food"] = "进食",
	["Forbearance"] = "自律",
	["Force of Nature"] = "Force of Nature",-- TODO translate
	["Force of Will"] = "意志之力",
	["Force Punch"] = "Force Punch",-- TODO translate
	["Force Reactive Disk"] = "Force Reactive Disk",-- TODO translate
	["Forked Lightning"] = "Forked Lightning",-- TODO translate
	["Forsaken Skills"] = "Forsaken Skills",-- TODO translate
	["Frailty"] = "Frailty",-- TODO translate
	["Freeze Solid"] = "Freeze Solid",-- TODO translate
	["Freezing Trap"] = "冰冻陷阱",
	["Freezing Trap Effect"] = "冰冻陷阱效果",
	["Frenzied Regeneration"] = "狂暴回复",
	["Frenzy"] = "疯狂",
	["Frost Armor"] = "霜甲术",
	["Frost Breath"] = "Frost Breath",-- TODO translate
	["Frost Channeling"] = "冰霜导能",
	["Frost Nova"] = "冰霜新星",
	["Frost Resistance"] = "冰霜抗性",
	["Frost Resistance Aura"] = "冰霜抗性光环",
	["Frost Resistance Totem"] = "抗寒图腾",
	["Frost Shock"] = "冰霜震击",
	["Frost Shot"] = "Frost Shot",-- TODO translate
	["Frost Trap"] = "冰霜陷阱",
	["Frost Trap Aura"] = "冰霜陷阱光环",
	["Frost Ward"] = "防护冰霜结界",
	["Frost Warding"] = "Frost Warding",
	["Frost Weakness"] = "Frost Weakness",
	["Frostbite"] = "霜寒刺骨",
	["Frostbolt"] = "寒冰箭",
	["Frostbolt Volley"] = "Frostbolt Volley",-- TODO translate
	["Frostbrand Weapon"] = "冰封武器",
	["Furious Howl"] = "狂怒之嚎",
	["The Furious Storm"] = "The Furious Storm",-- TODO translate
	["Furor"] = "激怒",
	["Fury of Ragnaros"] = "Fury of Ragnaros",-- TODO translate
	["Gahz'ranka Slam"] = "Gahz'ranka Slam",-- TODO translate
	["Gahz'rilla Slam"] = "Gahz'rilla Slam",-- TODO translate
	["Garrote"] = "绞喉",
	["Gehennas' Curse"] = "Gehennas' Curse",-- TODO translate
	["Generic"] = "基本",-- [TODO Translate not sure about this one]
	["Ghost Wolf"] = "幽魂之狼",
	["Ghostly Strike"] = "鬼魅攻击",
	["Gift of Life"] = "Gift of Life",
	["Gift of Nature"] = "自然赐福",
	["Gift of the Wild"] = "野性赐福",
	["Goblin Dragon Gun"] = "Goblin Dragon Gun",-- TODO translate
	["Goblin Sapper Charge"] = "Goblin Sapper Charge",-- TODO translate
	["Gouge"] = "凿击",
	["Grace of Air Totem"] = "风之优雅图腾",
	["Grace of the Sunwell"] = "Grace of the Sunwell",-- TODO translate
	["Grasping Vines"] = "Grasping Vines",-- TODO translate
	["Great Stamina"] = "持久耐力",
	["Greater Blessing of Kings"] = "强效王者祝福",
	["Greater Blessing of Light"] = "强效光明祝福",
	["Greater Blessing of Might"] = "强效力量祝福",
	["Greater Blessing of Salvation"] = "强效拯救祝福",
	["Greater Blessing of Sanctuary"] = "强效庇护祝福",
	["Greater Blessing of Wisdom"] = "强效智慧祝福",
	["Greater Heal"] = "强效治疗术",
	["Grim Reach"] = "无情延伸",
	["Ground Tremor"] = "Ground Tremor",-- TODO translate
	["Grounding Totem"] = "根基图腾",
	["Grovel"] = "匍匐",
	["Growl"] = "低吼",
	["Guardian's Favor"] = "守护者的宠爱",
	["Guillotine"] = "Guillotine",-- TODO translate
	["Gun Specialization"] = "枪械专精",
	["Guns"] = "枪械",
	["Hail Storm"] = "Hail Storm",-- TODO translate
	["Hammer of Justice"] = "制裁之锤",
	["Hammer of Wrath"] = "愤怒之锤",
	["Hamstring"] = "断筋",
	["Harass"] = "侵扰",
	["Hardiness"] = "坚韧",
	["Haunting Spirits"] = "Haunting Spirits",-- TODO translate
	["Hawk Eye"] = "鹰眼",
	["Head Crack"] = "Head Crack",-- TODO translate
	["Heal"] = "治疗术",
	["Healing Circle"] = "Healing Circle",-- TODO translate
	["Healing Focus"] = "治疗专注",
	["Healing Light"] = "治疗之光",
	["Healing of the Ages"] = "Healing of the Ages",-- TODO translate
	["Healing Stream Totem"] = "治疗之泉图腾",
	["Healing Touch"] = "治疗之触",
	["Healing Wave"] = "治疗波",
	["Healing Way"] = "治疗之道",
	["Health Funnel"] = "生命通道",
	["Heart of the Wild"] = "野性之心",
	["Heavy Sharpening Stone"] = "重磨刀石",
	["Hellfire"] = "地狱烈焰",
	["Hellfire Effect"] = "地狱烈焰效果",
	["Hemorrhage"] = "出血",
	["Herb Gathering"] = "采集草药",
	["Herbalism"] = "草药学",
	["Heroic Strike"] = "英勇打击",
	["Heroism"] = "Heroism",
	["Hex"] = "Hex",-- TODO translate
	["Hex of Jammal'an"] = "Hex of Jammal'an",-- TODO translate
	["Hex of Weakness"] = "虚弱妖术",
	["Hibernate"] = "休眠",
	["Holy Fire"] = "神圣之火",
	["Holy Light"] = "圣光术",
	["Holy Nova"] = "神圣新星",
	["Holy Power"] = "神圣强化",
	["Holy Reach"] = "神圣延伸",
	["Holy Shield"] = "神圣之盾",
	["Holy Shock"] = "神圣震击",
	["Holy Smite"] = "Holy Smite",-- TODO translate
	["Holy Specialization"] = "神圣专精",
	["Holy Strength"] = "Holy Strength",-- TODO translate
	["Holy Strike"] = "Holy Strike",-- TODO translate
	["Holy Wrath"] = "神圣愤怒",
	["Honorless Target"] = "无荣誉目标",
	["Hooked Net"] = "Hooked Net",-- TODO translate
	["Horse Riding"] = "骑术：马",
	["Howl of Terror"] = "恐惧嚎叫",
	["The Human Spirit"] = "人类精魂",
	["Humanoid Slaying"] = "人型生物杀手",
	["Hunter's Mark"] = "猎人印记",
	["Hurricane"] = "飓风",
	["Ice Armor"] = "冰甲术",
	["Ice Barrier"] = "寒冰护体",
	["Ice Blast"] = "Ice Blast",-- TODO translate
	["Ice Block"] = "寒冰屏障",
	["Ice Lance"] = "Ice Lance",-- TODO translate
	["Ice Nova"] = "Ice Nova",-- TODO translate
	["Ice Shards"] = "寒冰碎片",
	["Icicle"] = "Icicle",-- TODO translate
	["Ignite"] = "点燃",
	["Illumination"] = "启发",
	["Immolate"] = "献祭",
	["Immolation Trap"] = "献祭陷阱",
	["Immolation Trap Effect"] = "献祭陷阱效果",
	["Impact"] = "冲击",
	["Impale"] = "穿刺",
	["Improved Ambush"] = "强化伏击",
	["Improved Arcane Explosion"] = "强化魔爆术",
	["Improved Arcane Missiles"] = "强化奥术飞弹",
	["Improved Arcane Shot"] = "强化奥术射击",
	["Improved Aspect of the Hawk"] = "强化雄鹰守护",
	["Improved Aspect of the Monkey"] = "强化灵猴守护",
	["Improved Backstab"] = "强化背刺",
	["Improved Battle Shout"] = "强化战斗怒吼",
	["Improved Berserker Rage"] = "强化狂暴之怒",
	["Improved Blessing of Might"] = "强化力量祝福",
	["Improved Blessing of Wisdom"] = "强化智慧祝福",
	["Improved Blizzard"] = "强化暴风雪",
	["Improved Bloodrage"] = "强化血性狂暴",
	["Improved Chain Heal"] = "强化治疗链",
	["Improved Chain Lightning"] = "强化闪电链",
	["Improved Challenging Shout"] = "强化挑战怒吼",
	["Improved Charge"] = "强化冲锋",
	["Improved Cheap Shot"] = "强化偷袭",
	["Improved Cleave"] = "强化顺劈斩",
	["Improved Concentration Aura"] = "强化专注光环",
	["Improved Concussive Shot"] = "强化震荡射击",
	["Improved Cone of Cold"] = "强化冰锥术",
	["Improved Corruption"] = "强化腐蚀术",
	["Improved Counterspell"] = "强化法术反制",
	["Improved Curse of Agony"] = "强化痛苦诅咒",
	["Improved Curse of Exhaustion"] = "强化疲劳诅咒",
	["Improved Curse of Weakness"] = "强化虚弱诅咒",
	["Improved Dampen Magic"] = "强化魔法抑制",
	["Improved Deadly Poison"] = "强化致命毒药",
	["Improved Demoralizing Shout"] = "强化挫志怒吼",
	["Improved Devotion Aura"] = "强化虔诚光环",
	["Improved Disarm"] = "强化缴械",
	["Improved Distract"] = "强化扰乱",
	["Improved Drain Life"] = "强化吸取生命",
	["Improved Drain Mana"] = "强化吸取法力",
	["Improved Drain Soul"] = "强化吸取灵魂",
	["Improved Enrage"] = "强化狂怒",
	["Improved Enslave Demon"] = "强化奴役恶魔",
	["Improved Entangling Roots"] = "强化纠缠根须",
	["Improved Evasion"] = "强化闪避",
	["Improved Eviscerate"] = "强化剔骨",
	["Improved Execute"] = "强化斩杀",
	["Improved Expose Armor"] = "强化破甲",
	["Improved Eyes of the Beast"] = "强化野兽之眼",
	["Improved Fade"] = "强化渐隐术",
	["Improved Feign Death"] = "强化假死",
	["Improved Fire Blast"] = "强化火焰冲击",
	["Improved Fire Nova Totem"] = "强化火焰图腾",
	["Improved Fire Ward"] = "强化防护火焰结界",
	["Improved Fireball"] = "强化火球术",
	["Improved Firebolt"] = "强化火焰箭",
	["Improved Firestone"] = "强化火焰石",
	["Improved Flamestrike"] = "强化烈焰冲击",
	["Improved Flametongue Weapon"] = "强化火舌武器",
	["Improved Flash of Light"] = "强化圣光闪现",
	["Improved Frost Nova"] = "强化冰霜新星",
	["Improved Frost Ward"] = "强化防护冰霜结界",
	["Improved Frostbolt"] = "强化寒冰箭",
	["Improved Frostbrand Weapon"] = "强化冰封武器",
	["Improved Garrote"] = "强化绞喉",
	["Improved Ghost Wolf"] = "强化幽魂之狼",
	["Improved Gouge"] = "强化凿击",
	["Improved Grace of Air Totem"] = "强化风之优雅图腾",
	["Improved Grounding Totem"] = "强化根基图腾",
	["Improved Hammer of Justice"] = "强化制裁之锤",
	["Improved Hamstring"] = "强化断筋",
	["Improved Healing"] = "强化治疗术",
	["Improved Healing Stream Totem"] = "强化治疗之泉图腾",
	["Improved Healing Touch"] = "强化治疗之触",
	["Improved Healing Wave"] = "强化治疗波",
	["Improved Health Funnel"] = "强化生命通道",
	["Improved Healthstone"] = "强化治疗石",
	["Improved Heroic Strike"] = "强化英勇打击",
	["Improved Hunter's Mark"] = "强化猎人印记",
	["Improved Immolate"] = "强化献祭",
	["Improved Imp"] = "强化小鬼",
	["Improved Inner Fire"] = "强化心灵之火",
	["Improved Instant Poison"] = "强化速效毒药",
	["Improved Intercept"] = "强化拦截",
	["Improved Intimidating Shout"] = "强化破胆怒吼",
	["Improved Judgement"] = "强化审判",
	["Improved Kick"] = "强化脚踢",
	["Improved Kidney Shot"] = "强化肾击",
	["Improved Lash of Pain"] = "强化剧痛鞭笞",
	["Improved Lay on Hands"] = "强化圣疗术",
	["Improved Lesser Healing Wave"] = "强化次级治疗波",
	["Improved Life Tap"] = "强化生命分流",
	["Improved Lightning Bolt"] = "强化闪电箭",
	["Improved Lightning Shield"] = "强化闪电护盾",
	["Improved Magma Totem"] = "强化熔岩图腾",
	["Improved Mana Burn"] = "强化法力燃烧",
	["Improved Mana Shield"] = "强化法力护盾",
	["Improved Mana Spring Totem"] = "强化法力之泉图腾",
	["Improved Mark of the Wild"] = "强化野性印记",
	["Improved Mend Pet"] = "强化治疗宠物",
	["Improved Mind Blast"] = "强化心灵震爆",
	["Improved Moonfire"] = "强化月火术",
	["Improved Nature's Grasp"] = "强化自然之握",
	["Improved Overpower"] = "强化压制",
	["Improved Power Word: Fortitude"] = "强化真言术：韧",
	["Improved Power Word: Shield"] = "强化圣言术：盾",
	["Improved Prayer of Healing"] = "强化治疗祷言",
	["Improved Psychic Scream"] = "强化心灵尖啸",
	["Improved Pummel"] = "强化拳击",
	["Improved Regrowth"] = "强化愈合",
	["Improved Reincarnation"] = "强化复生",
	["Improved Rejuvenation"] = "强化回春",
	["Improved Rend"] = "强化撕裂",
	["Improved Renew"] = "强化恢复",
	["Improved Retribution Aura"] = "强化惩罚光环",
	["Improved Revenge"] = "强化复仇",
	["Improved Revive Pet"] = "强化复活宠物",
	["Improved Righteous Fury"] = "强化正义之怒",
	["Improved Rockbiter Weapon"] = "强化石化武器",
	["Improved Rupture"] = "强化割裂",
	["Improved Sap"] = "强化闷棍",
	["Improved Scorch"] = "强化灼烧",
	["Improved Scorpid Sting"] = "强化毒蝎钉刺",
	["Improved Seal of Righteousness"] = "强化正义圣印",
	["Improved Seal of the Crusader"] = "强化十字军圣印",
	["Improved Searing Pain"] = "强化灼热之痛",
	["Improved Searing Totem"] = "强化灼热图腾",
	["Improved Serpent Sting"] = "强化毒蛇钉刺",
	["Improved Shadow Bolt"] = "强化暗影箭",
	["Improved Shadow Word: Pain"] = "强化暗言术：痛",
	["Improved Shield Bash"] = "强化盾击",
	["Improved Shield Block"] = "强化盾牌格挡",
	["Improved Shield Wall"] = "强化盾墙",
	["Improved Shred"] = "强化撕碎",
	["Improved Sinister Strike"] = "强化邪恶攻击",
	["Improved Slam"] = "强化猛击",
	["Improved Slice and Dice"] = "强化切割",
	["Improved Spellstone"] = "强化法术石",
	["Improved Sprint"] = "强化疾跑",
	["Improved Starfire"] = "强化星火术",
	["Improved Stoneclaw Totem"] = "强化石爪图腾",
	["Improved Stoneskin Totem"] = "强化石肤图腾",
	["Improved Strength of Earth Totem"] = "强化大地之力图腾",
	["Improved Succubus"] = "强化魅魔",
	["Improved Sunder Armor"] = "强化破甲攻击",
	["Improved Taunt"] = "强化嘲讽",
	["Improved Thorns"] = "强化荆棘术",
	["Improved Thunder Clap"] = "强化雷霆一击",
	["Improved Tranquility"] = "强化宁静",
	["Improved Vampiric Embrace"] = "强化吸血鬼的拥抱",
	["Improved Vanish"] = "强化消失",
	["Improved Voidwalker"] = "强化虚空行者",
	["Improved Windfury Weapon"] = "强化风怒武器",
	["Improved Wing Clip"] = "强化摔绊",
	["Improved Wrath"] = "强化愤怒",
	["Incinerate"] = "焚烧",
	["Infected Bite"] = "Infected Bite",-- TODO translate
	["Infected Wound"] = "Infected Wound",-- TODO translate
	["Inferno"] = "地狱火",
	["Inferno Shell"] = "Inferno Shell",-- TODO translate
	["Initiative"] = "先发制人",
	["Inner Fire"] = "心灵之火",
	["Inner Focus"] = "心灵专注",
	["Innervate"] = "激活",
	["Insect Swarm"] = "虫群",
	["Inspiration"] = "灵感",
	["Instant Poison"] = "速效毒药",
	["Instant Poison II"] = "速效毒药 II",
	["Instant Poison III"] = "速效毒药 III",
	["Instant Poison IV"] = "速效毒药 IV",
	["Instant Poison V"] = "速效毒药 V",
	["Instant Poison VI"] = "速效毒药 VI",
	["Intensity"] = "强烈",
	["Intercept"] = "拦截",
	["Intercept Stun"] = "拦截昏迷",
	["Intervene"] = "Intervene",-- TODO translate
	["Intimidating Roar"] = "Intimidating Roar",-- TODO translate
	["Intimidating Shout"] = "破胆怒吼",
	["Intimidation"] = "胁迫",
	["Intoxicating Venom"] = "Intoxicating Venom",-- TODO translate
	["Invisibility"] = "Invisibility",-- TODO translate
	["Iron Will"] = "Iron Will",-- TODO translate
	["Jewelcrafting"] = "Jewelcrafting",
	["Judgement"] = "审判",
	["Judgement of Command"] = "命令审判",
	["Judgement of Justice"] = "公正审判",
	["Judgement of Light"] = "光明审判",
	["Judgement of Righteousness"] = "正义审判",
	["Judgement of the Crusader"] = "十字军审判",
	["Judgement of Wisdom"] = "智慧审判",
	["Kick"] = "脚踢",
	["Kick - Silenced"] = "脚踢 - 沉默",
	["Kidney Shot"] = "肾击",
	["Kill Command"] = "Kill Command",-- TODO translate
	["Killer Instinct"] = "杀戮本能",
	["Knock Away"] = "Knock Away",-- TODO translate
	["Knockdown"] = "Knockdown",-- TODO translate
	["Kodo Riding"] = "骑术：科多兽",
	["Lacerate"] = "Lacerate",
	["Larva Goo"] = "Larva Goo",-- TODO translate
	["Lash"] = "Lash",-- TODO translate
	["Lash of Pain"] = "剧痛鞭笞",
	["Last Stand"] = "破釜沉舟",
	["Lasting Judgement"] = "持久审判",
	["Lava Spout Totem"] = "Lava Spout Totem",-- TODO translate
	["Lay on Hands"] = "圣疗术",
	["Leader of the Pack"] = "兽群领袖",
	["Leather"] = "皮甲",
	["Leatherworking"] = "制皮",
	["Leech Poison"] = "Leech Poison",-- TODO translate
	["Lesser Heal"] = "次级治疗术",
	["Lesser Healing Wave"] = "次级治疗波",
	["Lesser Invisibility"] = "次级隐形术",
	["Lethal Shots"] = "夺命射击",
	["Lethality"] = "致命偷袭",
	["Levitate"] = "漂浮",
	["Libram"] = "圣物",
	["Lich Slap"] = "Lich Slap",-- TODO translate
	["Life Tap"] = "生命分流",
	["Lifebloom"] = "Lifebloom",-- TODO translate
	["Lifegiving Gem"] = "Lifegiving Gem",
	["Lightning Blast"] = "Lightning Blast",-- TODO translate
	["Lightning Bolt"] = "闪电箭",
	["Lightning Breath"] = "闪电吐息",
	["Lightning Cloud"] = "Lightning Cloud",-- TODO translate
	["Lightning Mastery"] = "闪电掌握",
	["Lightning Reflexes"] = "闪电反射",
	["Lightning Shield"] = "闪电护盾",
	["Lightning Wave"] = "Lightning Wave",-- TODO translate
	["Lightwell"] = "光明之泉",
	["Lightwell Renew"] = "光明之泉回复",
	["Lizard Bolt"] = "Lizard Bolt",-- TODO translate
	["Localized Toxin"] = "Localized Toxin",-- TODO translate
	["Lockpicking"] = "开锁",
	["Long Daze"] = "长时间眩晕",
	["Mace Specialization"] = "锤类武器专精",
	["Mace Stun Effect"] = "锤击昏迷效果",
	["Machine Gun"] = "Machine Gun",-- TODO translate
	["Mage Armor"] = "魔甲术",
	["Magic Attunement"] = "Magic Attunement",
	["Magma Splash"] = "Magma Splash",-- TODO translate
	["Magma Totem"] = "熔岩图腾",
	["Mail"] = "锁甲",
	["Maim"] = "Maim",-- TODO translate
	["Malice"] = "恶意",
	["Mana Burn"] = "法力燃烧",
	["Mana Feed"] = "Mana Feed",
	["Mana Shield"] = "法力护盾",
	["Mana Spring Totem"] = "法力之泉图腾",
	["Mana Tide Totem"] = "法力之潮图腾",
	["Mangle"] = "割碎",
	["Mangle (Bear)"] = "Mangle (Bear)",-- TODO translate
	["Mangle (Cat)"] = "Mangle (Cat)",-- TODO translate
	["Mark of Arlokk"] = "Mark of Arlokk",-- TODO translate
	["Mark of the Wild"] = "野性印记",
	["Martyrdom"] = "殉难",
	["Mass Dispel"] = "Mass Dispel",
	["Master Demonologist"] = "恶魔学识大师",
	["Master of Deception"] = "欺诈高手",
	["Master of Elements"] = "Master of Elements",
	["Master Summoner"] = "召唤大师",
	["Maul"] = "槌击",
	["Mechanostrider Piloting"] = "骑术：机械陆行鸟",
	["Meditation"] = "冥想",
	["Megavolt"] = "Megavolt",-- TODO translate
	["Melee Specialization"] = "近战专精",
	["Melt Ore"] = "Melt Ore",-- TODO translate
	["Mend Pet"] = "治疗宠物",
	["Mental Agility"] = "精神敏锐",
	["Mental Strength"] = "心灵之力",
	["Mighty Blow"] = "Mighty Blow",-- TODO translate
	["Mind Blast"] = "心灵震爆",
	["Mind Control"] = "精神控制",
	["Mind Flay"] = "精神鞭笞",
	["Mind Soothe"] = "安抚心灵",
	["Mind Tremor"] = "Mind Tremor",-- TODO translate
	["Mind Vision"] = "心灵视界",
	["Mind-numbing Poison"] = "麻痹毒药",
	["Mind-numbing Poison II"] = "麻痹毒药 II",
	["Mind-numbing Poison III"] = "麻痹毒药 III",
	["Mining"] = "采矿",
	["Misdirection"] = "Misdirection",-- TODO translate
	["Mocking Blow"] = "惩戒痛击",
	["Molten Armor"] = "Molten Armor",-- TODO translate
	["Molten Blast"] = "Molten Blast",-- TODO translate
	["Molten Metal"] = "Molten Metal",-- TODO translate
	["Mongoose Bite"] = "猫鼬撕咬",
	["Monster Slaying"] = "怪物杀手",
	["Moonfire"] = "月火术",
	["Moonfury"] = "月怒",
	["Moonglow"] = "月光",
	["Moonkin Aura"] = "枭兽光环",
	["Moonkin Form"] = "枭兽形态",
	["Mortal Cleave"] = "Mortal Cleave",-- TODO translate
	["Mortal Shots"] = "致死射击",
	["Mortal Strike"] = "致死打击",
	["Mortal Wound"] = "Mortal Wound",-- TODO translate
	["Multi-Shot"] = "多重射击",
	["Murder"] = "谋杀",
	["Mutilate"] = "Mutilate",-- TODO translate
	["Naralex's Nightmare"] = "Naralex's Nightmare",-- TODO translate
	["Natural Armor"] = "自然护甲",
	["Natural Shapeshifter"] = "自然变形",
	["Natural Weapons"] = "武器平衡",
	["Nature Aligned"] = "Nature Aligned",-- TODO translate
	["Nature Resistance"] = "自然抗性",
	["Nature Resistance Totem"] = "自然抗性图腾",
	["Nature Weakness"] = "Nature Weakness",-- TODO translate
	["Nature's Focus"] = "自然集中",
	["Nature's Grace"] = "自然之赐",
	["Nature's Grasp"] = "自然之握",
	["Nature's Reach"] = "自然延伸",
	["Nature's Swiftness"] = "自然迅捷",
	["Necrotic Poison"] = "Necrotic Poison",-- TODO translate
	["Negative Charge"] = "Negative Charge",-- TODO translate
	["Net"] = "Net",-- TODO translate
	["Nightfall"] = "夜幕",
	["Noxious Catalyst"] = "Noxious Catalyst",-- TODO translate
	["Noxious Cloud"] = "Noxious Cloud",-- TODO translate
	["Omen of Clarity"] = "清晰预兆",
	["One-Handed Axes"] = "单手斧",
	["One-Handed Maces"] = "单手锤",
	["One-Handed Swords"] = "单手剑",
	["One-Handed Weapon Specialization"] = "单手武器专精",
	["Opening"] = "打开",
	["Opening - No Text"] = "打开 - No Text",-- [TODO Translate not sure what this is]
	["Opportunity"] = "伺机而动",
	["Overpower"] = "压制",
	["Pacify"] = "Pacify",-- TODO translate
	["Pain Suppression"] = "Pain Suppression",-- TODO translate
	["Paralyzing Poison"] = "Paralyzing Poison",-- TODO translate
	["Paranoia"] = "多疑",
	["Parasitic Serpent"] = "Parasitic Serpent",-- TODO translate
	["Parry"] = "招架",
	["Pathfinding"] = "寻路",
	["Perception"] = "感知",
	["Permafrost"] = "极寒冰霜",
	["Pet Aggression"] = "宠物好斗",
	["Pet Hardiness"] = "宠物耐久",
	["Pet Recovery"] = "宠物恢复",
	["Pet Resistance"] = "宠物抗魔",
	["Petrify"] = "Petrify",-- TODO translate
	["Phase Shift"] = "相位变换",
	["Pick Lock"] = "开锁",
	["Pick Pocket"] = "偷窃",
	["Pierce Armor"] = "Pierce Armor",-- TODO translate
	["Piercing Howl"] = "刺耳怒吼",
	["Piercing Ice"] = "刺骨寒冰",
	["Piercing Shadow"] = "Piercing Shadow",-- TODO translate
	["Piercing Shot"] = "Piercing Shot",-- TODO translate
	["Plague Cloud"] = "Plague Cloud",-- TODO translate
	["Plate Mail"] = "板甲",
	["Poison"] = "Poison",-- TODO translate
	["Poison Bolt"] = "Poison Bolt",-- TODO translate
	["Poison Bolt Volley"] = "Poison Bolt Volley",-- TODO translate
	["Poison Cleansing Totem"] = "祛病图腾",
	["Poison Cloud"] = "Poison Cloud",-- TODO translate
	["Poison Shock"] = "Poison Shock",-- TODO translate
	["Poisoned Harpoon"] = "Poisoned Harpoon",-- TODO translate
	["Poisoned Shot"] = "Poisoned Shot",-- TODO translate
	["Poisonous Blood"] = "Poisonous Blood",-- TODO translate
	["Poisons"] = "毒药",
	["Polearm Specialization"] = "长柄武器专精",
	["Polearms"] = "长柄武器",
	["Polymorph"] = "变形术",
	["Polymorph: Pig"] = "变形术：猪",
	["Polymorph: Turtle"] = "变形术：龟",
	["Portal: Darnassus"] = "传送门：达纳苏斯",
	["Portal: Ironforge"] = " 传送门：铁炉堡",
	["Portal: Orgrimmar"] = "传送门：奥格瑞玛",
	["Portal: Stormwind"] = "传送门：暴风城",
	["Portal: Thunder Bluff"] = "传送门：雷霆崖",
	["Portal: Undercity"] = "传送门：幽暗城",
	["Positive Charge"] = "Positive Charge",
	["Pounce"] = "突袭",
	["Pounce Bleed"] = "突袭",
	["Power Infusion"] = "能量灌注",
	["Power Word: Fortitude"] = "真言术：韧",
	["Power Word: Shield"] = "真言术：盾",
	["Prayer Beads Blessing"] = "Prayer Beads Blessing",-- TODO translate
	["Prayer of Fortitude"] = "坚韧祷言",
	["Prayer of Healing"] = "治疗祷言",
	["Prayer of Mending"] = "Prayer of Mending",-- TODO translate
	["Prayer of Shadow Protection"] = "暗影防护祷言",
	["Prayer of Spirit"] = "精神祷言",
	["Precision"] = "精确",
	["Predatory Strikes"] = "猛兽攻击",
	["Premeditation"] = "预谋",
	["Preparation"] = "伺机待发",
	["Presence of Mind"] = "气定神闲",
	["Primal Fury"] = "原始狂怒",
	["Prowl"] = "潜伏",
	["Psychic Scream"] = "心灵尖啸",
	["Pummel"] = "拳击",
	["Puncture"] = "Puncture",-- TODO translate
	["Purge"] = "净化术",
	["Purification"] = "净化",
	["Purify"] = "纯净术",
	["Pursuit of Justice"] = "正义追击",
	["Putrid Breath"] = "Putrid Breath",-- TODO translate
	["Putrid Enzyme"] = "Putrid Enzyme",-- TODO translate
	["Pyroblast"] = "炎爆术",
	["Pyroclasm"] = "火焰冲撞",
	["Quick Shots"] = "快速射击",
	["Quickness"] = "迅捷",
	["Radiation"] = "Radiation",-- TODO translate
	["Radiation Bolt"] = "Radiation Bolt",-- TODO translate
	["Radiation Cloud"] = "Radiation Cloud",-- TODO translate
	["Radiation Poisoning"] = "Radiation Poisoning",-- TODO translate
	["Rain of Fire"] = "火焰之雨",
	["Rake"] = "扫击",
	["Ram Riding"] = "骑术：羊",
	["Rampage"] = "Rampage",-- TODO translate
	["Ranged Weapon Specialization"] = "远程武器专精",
	["Rapid Concealment"] = "迅速隐蔽",
	["Rapid Fire"] = "急速射击",
	["Raptor Riding"] = "骑术：迅猛龙",
	["Raptor Strike"] = "猛禽一击",
	["Ravage"] = "毁灭",
	["Ravenous Claw"] = "Ravenous Claw",-- TODO translate
	["Readiness"] = "准备就绪",
	["Rebirth"] = "复生",
	["Rebuild"] = "Rebuild",-- TODO translate
	["Recently Bandaged"] = "Recently Bandaged",-- TODO translate
	["Reckless Charge"] = "无畏冲锋",
	["Recklessness"] = "鲁莽",
	["Reckoning"] = "清算",
	["Recombobulate"] = "Recombobulate",-- TODO translate
	["Redemption"] = "救赎",
	["Redoubt"] = "盾牌壁垒",
	["Reflection"] = "反射",
	["Regeneration"] = "回复",
	["Regrowth"] = "愈合",
	["Reincarnation"] = "复生",
	["Rejuvenation"] = "回春术",
	["Relentless Strikes"] = "无情打击",
	["Remorseless"] = "冷酷",
	["Remorseless Attacks"] = "冷酷攻击",
	["Remove Curse"] = "解除诅咒",
	["Remove Insignia"] = "解除徽记",
	["Remove Lesser Curse"] = "解除次级诅咒",
	["Rend"] = "撕裂",
	["Renew"] = "恢复",
	["Repentance"] = "忏悔",
	["Repulsive Gaze"] = "Repulsive Gaze",-- TODO translate
	["Restorative Totems"] = "Restorative Totems",
	["Resurrection"] = "复活",
	["Retaliation"] = "反击风暴",
	["Retribution Aura"] = "惩罚光环",
	["Revenge"] = "复仇",
	["Revenge Stun"] = "复仇昏迷",
	["Reverberation"] = "回响",
	["Revive Pet"] = "复活宠物",
	["Rhahk'Zor Slam"] = "Rhahk'Zor Slam",-- TODO translate
	["Ribbon of Souls"] = "Ribbon of Souls",-- TODO translate
	["Righteous Defense"] = "Righteous Defense",-- TODO translate
	["Righteous Fury"] = "正义之怒",
	["Rip"] = "撕扯",
	["Riposte"] = "还击",
	["Ritual of Doom"] = "末日仪式",
	["Ritual of Doom Effect"] = "末日仪式效果",
	["Ritual of Souls"] = "Ritual of Souls",-- TODO translate
	["Ritual of Summoning"] = "召唤仪式",
	["Rockbiter Weapon"] = "石化武器",
	["Rogue Passive"] = "盗贼被动效果",-- [TODO Translate not sure]
	["Rough Sharpening Stone"] = "劣质磨刀石",
	["Ruin"] = "毁灭",
	["Rupture"] = "割裂",
	["Ruthlessness"] = "无情",
	["Sacrifice"] = "牺牲",
	["Safe Fall"] = "安全降落",
	["Sanctity Aura"] = "圣洁光环",
	["Sap"] = "闷棍",
	["Savage Fury"] = "野蛮暴怒",
	["Savage Strikes"] = "野蛮打击",
	["Scare Beast"] = "恐吓野兽",
	["Scatter Shot"] = "驱散射击",
	["Scorch"] = "灼烧",
	["Scorpid Poison"] = "蝎毒",
	["Scorpid Sting"] = "毒蝎钉刺",
	["Screams of the Past"] = "Screams of the Past",-- TODO translate
	["Screech"] = "尖啸",
	["Seal Fate"] = "封印命运",
	["Seal of Blood"] = "Seal of Blood",-- TODO translate
	["Seal of Command"] = "命令圣印",
	["Seal of Justice"] = "公正圣印",
	["Seal of Light"] = "光明圣印",
	["Seal of Reckoning"] = "Seal of Reckoning",-- TODO translate
	["Seal of Righteousness"] = "正义圣印",
	["Seal of the Crusader"] = "十字军圣印",
	["Seal of Vengeance"] = "Seal of Vengeance",-- TODO translate
	["Seal of Wisdom"] = "智慧圣印",
	["Searing Light"] = "灼热之光",
	["Searing Pain"] = "灼热之痛",
	["Searing Totem"] = "灼热图腾",
	["Second Wind"] = "Second Wind",
	["Seduction"] = "诱惑",
	["Seed of Corruption"] = "Seed of Corruption",-- TODO translate
	["Sense Demons"] = "感知恶魔",
	["Sense Undead"] = "感知亡灵",
	["Sentry Totem"] = "岗哨图腾",
	["Serpent Sting"] = "毒蛇钉刺",
	["Setup"] = "调整",
	["Shackle Undead"] = "束缚亡灵",
	["Shadow Affinity"] = "暗影亲和",
	["Shadow Bolt"] = "暗影箭",
	["Shadow Bolt Volley"] = "Shadow Bolt Volley",-- TODO translate
	["Shadow Focus"] = "暗影集中",
	["Shadow Mastery"] = "暗影掌握",
	["Shadow Protection"] = "暗影防护",
	["Shadow Reach"] = "暗影延伸",
	["Shadow Resistance"] = "暗影抗性",
	["Shadow Resistance Aura"] = "暗影抗性光环",
	["Shadow Shock"] = "Shadow Shock",-- TODO translate
	["Shadow Trance"] = "暗影冥思",
	["Shadow Vulnerability"] = "暗影易伤",
	["Shadow Ward"] = "防护暗影结界",
	["Shadow Weakness"] = "Shadow Weakness",
	["Shadow Weaving"] = "暗影之波",
	["Shadow Word: Death"] = "Shadow Word: Death",-- TODO translate
	["Shadow Word: Pain"] = "暗言术：痛",
	["Shadowburn"] = "暗影灼烧",
	["Shadowfiend"] = "Shadowfiend",-- TODO translate
	["Shadowform"] = "暗影形态",
	["Shadowfury"] = "Shadowfury",-- TODO translate
	["Shadowguard"] = "暗影守卫",
	["Shadowmeld"] = "影遁",
	["Shadowmeld Passive"] = "影遁",
	["Shadowstep"] = "Shadowstep",-- TODO translate
	["Shamanistic Rage"] = "Shamanistic Rage",-- TODO translate
	["Sharpened Claws"] = "锋利兽爪",
	["Shatter"] = "碎冰",
	["Sheep"] = "Sheep",-- TODO translate
	["Shell Shield"] = "甲壳护盾",
	["Shield"] = "盾牌",
	["Shield Bash"] = "盾击",
	["Shield Bash - Silenced"] = "盾击 - 沉默",
	["Shield Block"] = "盾牌格挡",
	["Shield Slam"] = "盾牌猛击",
	["Shield Specialization"] = "盾牌专精",
	["Shield Wall"] = "盾墙",
	["Shiv"] = "Shiv",-- TODO translate
	["Shock"] = "Shock",-- TODO translate
	["Shoot"] = "射击",
	["Shoot Bow"] = "弓射击",
	["Shoot Crossbow"] = "弩射击",
	["Shoot Gun"] = "枪械射击",
	["Shred"] = "撕碎",
	["Shrink"] = "Shrink",-- TODO translate
	["Silence"] = "沉默",
	["Silencing Shot"] = "Silencing Shot",
	["Silent Resolve"] = "无声消退",
	["Sinister Strike"] = "邪恶攻击",
	["Siphon Life"] = "生命虹吸",
	["Skinning"] = "剥皮",
	["Skull Crack"] = "Skull Crack",-- TODO translate
	["Slam"] = "猛击",
	["Sleep"] = "沉睡",-- [TODO Translate not so sure]
	["Slice and Dice"] = "切割",
	["Slow"] = "Slow",
	["Slow Fall"] = "缓落术",
	["Slowing Poison"] = "Slowing Poison",-- TODO translate
	["Smelting"] = "熔炼",
	["Smite"] = "惩击",
	["Smite Slam"] = "Smite Slam",-- TODO translate
	["Smite Stomp"] = "Smite Stomp",-- TODO translate
	["Smoke Bomb"] = "Smoke Bomb",-- TODO translate
	["Snake Trap"] = "Snake Trap",-- TODO translate
	["Snap Kick"] = "Snap Kick",-- TODO translate
	["Solid Sharpening Stone"] = "坚固的磨刀石",
	["Sonic Burst"] = "Sonic Burst",-- TODO translate
	["Soothe Animal"] = "安抚动物",
	["Soothing Kiss"] = "安抚之吻",
	["Soul Bite"] = "Soul Bite",-- TODO translate
	["Soul Drain"] = "Soul Drain",-- TODO translate
	["Soul Fire"] = "灵魂之火",
	["Soul Link"] = "灵魂链接",
	["Soul Siphon"] = "灵魂虹吸",
	["Soul Tap"] = "Soul Tap",-- TODO translate
	["Soulshatter"] = "Soulshatter",-- TODO translate
	["Soulstone Resurrection"] = "灵魂石复活",
	["Spell Lock"] = "法术封锁",
	["Spell Reflection"] = "Spell Reflection",
	["Spell Warding"] = "法术屏障",
	["Spellsteal"] = "Spellsteal",-- TODO translate
	["Spirit Bond"] = "灵魂连接",
	["Spirit Burst"] = "Spirit Burst",-- TODO translate
	["Spirit of Redemption"] = "救赎之魂",
	["Spirit Tap"] = "精神分流",
	["Spiritual Attunement"] = "Spiritual Attunement",-- TODO translate
	["Spiritual Focus"] = "精神集中",
	["Spiritual Guidance"] = "精神指引",
	["Spiritual Healing"] = "精神治疗",
	["Spit"] = "Spit",-- TODO translate
	["Spore Cloud"] = "Spore Cloud",-- TODO translate
	["Sprint"] = "疾跑",
	["Stance Mastery"] = "Stance Mastery",-- TODO translate
	["Starfire"] = "星火术",
	["Starfire Stun"] = "星火昏迷",
	["Starshards"] = "星辰碎片",
	["Staves"] = "法杖",
	["Steady Shot"] = "稳固射击",
	["Stealth"] = "潜行",
	["Stoneclaw Totem"] = "石爪图腾",
	["Stoneform"] = "石像形态",
	["Stoneskin Totem"] = "石肤图腾",
	["Stormstrike"] = "风暴打击",
	["Strength of Earth Totem"] = "大地之力图腾",
	["Strike"] = "Strike",-- TODO translate
	["Stuck"] = "卡死",
	["Stun"] = "Stun",-- TODO translate
	["Subtlety"] = "微妙",
	["Suffering"] = "受难",
	["Summon Charger"] = "召唤战马",
	["Summon Dreadsteed"] = "召唤恐惧战马",
	["Summon Felguard"] = "Summon Felguard",-- TODO translate
	["Summon Felhunter"] = "召唤地狱猎犬",
	["Summon Felsteed"] = "召唤地狱战马",
	["Summon Imp"] = "召唤小鬼",
	["Summon Spawn of Bael'Gar"] = "Summon Spawn of Bael'Gar",-- TODO translate
	["Summon Succubus"] = "召唤魅魔",
	["Summon Voidwalker"] = "召唤虚空行者",
	["Summon Warhorse"] = "召唤军马",
	["Summon Water Elemental"] = "Summon Water Elemental",
	["Sunder Armor"] = "破甲",
	["Suppression"] = "压制",
	["Surefooted"] = "稳固",
	["Survivalist"] = "生存专家",
	["Sweeping Slam"] = "Sweeping Slam",-- TODO translate
	["Sweeping Strikes"] = "横扫攻击",
	["Swiftmend"] = "迅捷治愈",
	["Swipe"] = "挥击",
	["Swoop"] = "Swoop",-- TODO translate
	["Sword Specialization"] = "剑类武器专精",
	["Tactical Mastery"] = "战术掌握",
	["Tailoring"] = "裁缝",
	["Tainted Blood"] = "腐坏之血",
	["Tame Beast"] = "驯服野兽",
	["Tamed Pet Passive"] = "驯服宠物（被动）",
	["Taunt"] = "嘲讽",
	["Teleport: Darnassus"] = "传送：达纳苏斯",
	["Teleport: Ironforge"] = "传送：铁炉堡",
	["Teleport: Moonglade"] = "传送：月光林地",
	["Teleport: Orgrimmar"] = "传送：奥格瑞玛",
	["Teleport: Stormwind"] = "传送：暴风城",
	["Teleport: Thunder Bluff"] = "传送：雷霆崖",
	["Teleport: Undercity"] = "传送：幽暗城",
	["Tendon Rip"] = "Tendon Rip",-- TODO translate
	["Tendon Slice"] = "Tendon Slice",-- TODO translate
	["Terrify"] = "Terrify",-- TODO translate
	["Terrifying Screech"] = "Terrifying Screech",-- TODO translate
	["Thick Hide"] = "厚皮",
	["Thorn Volley"] = "Thorn Volley",-- TODO translate
	["Thorns"] = "荆棘术",
	["Thousand Blades"] = "Thousand Blades",-- TODO translate
	["Threatening Gaze"] = "Threatening Gaze",-- TODO translate
	["Throw"] = "投掷",
	["Throw Axe"] = "Throw Axe",-- TODO translate
	["Throw Dynamite"] = "Throw Dynamite",-- TODO translate
	["Throw Liquid Fire"] = "Throw Liquid Fire",-- TODO translate
	["Throw Wrench"] = "Throw Wrench",-- TODO translate
	["Throwing Specialization"] = "投掷专精",
	["Throwing Weapon Specialization"] = "投掷武器专精",
	["Thrown"] = "投掷",
	["Thunder Clap"] = "雷霆一击",
	["Thunderclap"] = "Thunderclap",-- TODO translate
	["Thunderfury"] = "Thunderfury",-- TODO translate
	["Thundering Strikes"] = "雷鸣猛击",
	["Thundershock"] = "Thundershock",-- TODO translate
	["Thunderstomp"] = "雷霆践踏",
	["Tidal Focus"] = "潮汐集中",
	["Tidal Mastery"] = "潮汐掌握",
	["Tiger Riding"] = "骑术：豹",
	["Tiger's Fury"] = "猛虎之怒",
	["Torment"] = "折磨",
	["Totem"] = "图腾",
	["Totem of Wrath"] = "Totem of Wrath",-- TODO translate
	["Totemic Focus"] = "图腾集中",
	["Touch of Weakness"] = "虚弱之触",
	["Toughness"] = "坚韧",
	["Toxic Saliva"] = "Toxic Saliva",-- TODO translate
	["Toxic Spit"] = "Toxic Spit",-- TODO translate
	["Toxic Volley"] = "Toxic Volley",-- TODO translate
	["Traces of Silithyst"] = "Traces of Silithyst",
	["Track Beasts"] = "追踪野兽",
	["Track Demons"] = "追踪恶魔",
	["Track Dragonkin"] = "追踪龙类",
	["Track Elementals"] = "追踪元素生物",
	["Track Giants"] = "追踪巨人",
	["Track Hidden"] = "追踪隐藏生物",
	["Track Humanoids"] = "追踪人型生物",
	["Track Undead"] = "追踪亡灵",
	["Trample"] = "Trample",-- TODO translate
	["Tranquil Air Totem"] = "宁静之风图腾",
	["Tranquil Spirit"] = "宁静之魂",
	["Tranquility"] = "宁静",
	["Tranquilizing Poison"] = "Tranquilizing Poison",-- TODO translate
	["Tranquilizing Shot"] = "宁神射击",
	["Trap Mastery"] = "陷阱掌握",
	["Travel Form"] = "旅行形态",
	["Tree of Life"] = "Tree of Life",-- TODO translate
	["Tremor Totem"] = "战栗图腾",
	["Tribal Leatherworking"] = "部族制皮",
	["Trueshot Aura"] = "强击光环",
	["Turn Undead"] = "超度亡灵",
	["Twisted Tranquility"] = "Twisted Tranquility",-- TODO translate
	["Two-Handed Axes"] = "双手斧",
	["Two-Handed Axes and Maces"] = "双手斧和锤",
	["Two-Handed Maces"] = "双手锤",
	["Two-Handed Swords"] = "无光泽的双刃刀",
	["Two-Handed Weapon Specialization"] = "双手武器专精",
	["Unarmed"] = "徒手",
	["Unbreakable Will"] = "坚定意志",
	["Unbridled Wrath"] = "怒不可遏",
	["Unbridled Wrath Effect"] = "Unbridled Wrath Effect",-- TODO translate
	["Undead Horsemanship"] = "骑术：骸骨战马",
	["Underwater Breathing"] = "水下呼吸",
	["Unending Breath"] = "魔息术",
	["Unholy Frenzy"] = "Unholy Frenzy",-- TODO translate
	["Unholy Power"] = "邪恶强化",
	["Unleashed Fury"] = "狂怒释放",
	["Unleashed Rage"] = "Unleashed Rage",
	["Unstable Affliction"] = "Unstable Affliction",-- TODO translate
	["Unstable Concoction"] = "Unstable Concoction",-- TODO translate
	["Unstable Power"] = "Unstable Power",-- TODO translate
	["Unyielding Faith"] = "不灭信仰",
	["Uppercut"] = "Uppercut",-- TODO translate
	["Vampiric Embrace"] = "吸血鬼的拥抱",
	["Vampiric Touch"] = "Vampiric Touch",-- TODO translate
	["Vanish"] = "消失",
	["Vanished"] = "消失",
	["Veil of Shadow"] = "Veil of Shadow",-- TODO translate
	["Vengeance"] = "复仇",
	["Venom Spit"] = "Venom Spit",-- TODO translate
	["Venom Sting"] = "Venom Sting",-- TODO translate
	["Venomhide Poison"] = "Venomhide Poison",-- TODO translate
	["Vicious Rend"] = "Vicious Rend",-- TODO translate
	["Victory Rush"] = "Victory Rush",-- TODO translate
	["Vigor"] = "精力",
	["Vile Poisons"] = "恶性毒药",
	["Vindication"] = "辩护",
	["Viper Sting"] = "蝰蛇钉刺",
	["Virulent Poison"] = "Virulent Poison",-- TODO translate
	["Void Bolt"] = "Void Bolt",-- TODO translate
	["Volley"] = "乱射",
	["Walking Bomb Effect"] = "Walking Bomb Effect",-- TODO translate
	["Wand Specialization"] = "魔杖掌握",
	["Wandering Plague"] = "Wandering Plague",-- TODO translate
	["Wands"] = "魔杖",
	["War Stomp"] = "战争践踏",
	["Water"] = "Water",-- TODO translate
	["Water Breathing"] = "水下呼吸",
	["Water Shield"] = "Water Shield",-- TODO translate
	["Water Walking"] = "水上行走",
	["Waterbolt"] = "Waterbolt",-- TODO translate
	["Wavering Will"] = "Wavering Will",-- TODO translate
	["Weakened Soul"] = "虚弱灵魂",
	["Weaponsmith"] = "武器锻造师",
	["Web"] = "Web",-- TODO translate
	["Web Explosion"] = "Web Explosion",-- TODO translate
	["Web Spin"] = "Web Spin",-- TODO translate
	["Web Spray"] = "Web Spray",-- TODO translate
	["Whirling Barrage"] = "Whirling Barrage",-- TODO translate
	["Whirling Trip"] = "Whirling Trip",-- TODO translate
	["Whirlwind"] = "旋风斩",
	["Wide Slash"] = "Wide Slash",-- TODO translate
	["Will of Hakkar"] = "Will of Hakkar",-- TODO translate
	["Will of the Forsaken"] = "亡灵意志",
	["Windfury Totem"] = "风怒图腾",
	["Windfury Weapon"] = "风怒武器",
	["Windsor's Frenzy"] = "Windsor's Frenzy",-- TODO translate
	["Windwall Totem"] = "风墙图腾",
	["Wing Clip"] = "摔绊",
	["Wing Flap"] = "Wing Flap",-- TODO translate
	["Winter's Chill"] = "深冬之寒",
	["Wisp Spirit"] = "精灵之魂",
	["Wolf Riding"] = "骑术：狼",
	["Wound Poison"] = "致伤毒药",
	["Wound Poison II"] = "致伤毒药 II",
	["Wound Poison III"] = "致伤毒药 III",
	["Wound Poison IV"] = "致伤毒药 IV",
	["Wrath"] = "愤怒",
	["Wrath of Air Totem"] = "Wrath of Air Totem",-- TODO translate
	["Wyvern Sting"] = "翼龙钉刺",
}

end)
__bundle_register("Locale/enUS/Translations.enUS.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
	["Announces in chat when your tranquilizing shot hits or misses a target."] = "Announces in chat when your tranquilizing shot hits or misses a target.",
	["Aspect Tracker"] = "Aspect Tracker",
	["Auto Shot Timer"] = "Auto Shot Timer",
	["Border Style"] = "Border Style",
	["Both Directions"] = "Both Directions",
	["Castbar"] = "Castbar",
	["Casting"] = "Casting",
	["Casting Tranq Shot"] = "Casting Tranq Shot",
	["Close"] = "Close",
	["Close Window"] = "Close Window",
	["Dead Zone"] = "Dead Zone",
	["Debug Level"] = "Debug Level",
	["Hunter's Mark"] = "Hunter's Mark",
	["It's always safe to upgrade Quiver. You won't lose any of your configuration."] = "It's always safe to upgrade Quiver. You won't lose any of your configuration.",
	["Left to Right"] = "Left to Right",
	["Lock/Unlock Frames"] = "Lock/Unlock Frames",
	["Long Range"] = "Long Range",
	["Melee Range"] = "Melee Range",
	["*** MISSED Tranq Shot ***"] = "*** MISSED Tranq Shot ***",
	["New version %s available at %s"] = "New version %s available at %s",
	["None"] = "None",
	["Out of Range"] = "Out of Range",
	["Quiver is for hunters."] = "Quiver is for hunters.",
	["Quiver Unlocked. Show config dialog with /qq or /quiver.\nClick the lock icon when done."] = "Quiver Unlocked. Show config dialog with /qq or /quiver.\nClick the lock icon when done.",
	["Range Indicator"] = "Range Indicator",
	["Reloading"] = "Reloading",
	["Reset All Frame Sizes and Positions"] = "Reset All Frame Sizes and Positions",
	["Reset Color"] = "Reset Color",
	["Reset Frame Size and Position"] = "Reset Frame Size and Position",
	["Reset Miss Message to Default"] = "Reset Miss Message to Default",
	["Reset Tranq Message to Default"] = "Reset Tranq Message to Default",
	["Scare Beast"] = "Scare Beast",
	["Scatter Shot"] = "Scatter Shot",
	["Shoot / Reload"] = "Shoot / Reload",
	["Shooting"] = "Shooting",
	["Short Range"] = "Short Range",
	["Shows Aimed Shot, Multi-Shot, and Steady Shot."] = "Shows Aimed Shot, Multi-Shot, and Steady Shot.",
	["Shows when abilities are in range. Requires spellbook abilities placed somewhere on your action bars."] = "Shows when abilities are in range. Requires spellbook abilities placed somewhere on your action bars.",
	["Simple"] = "Simple",
	["Swap Shoot and Reload Colors"] = "Swap Shoot and Reload Colors",
	["Tooltip"] = "Tooltip",
	["Tranq Shot Announcer"] = "Tranq Shot Announcer",
	["Tranq Speech"] = "Tranq Speech",
	["Trueshot Aura Alarm"] = "Trueshot Aura Alarm",
	["Verbose"] = "Verbose",
}

end)
__bundle_register("Locale/enUS/Client.enUS.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Spell = require("Locale/enUS/Spell.enUS.lua")
-- local Zone = require "Locale/enUS/Zone.enUS.lua"

return {
	CombatLog = {
		Consumes = {
			ManaPotion = "You gain (.*) Mana from Restore Mana.",
			HealthPotion = "Your Healing Potion heals you for (.*).",
			Healthstone = "Your (.*) Healthstone heals you for (.*).",
			Tea = "Your Tea with Sugar heals you for (.*).",
		},
		Tranq = {
			Fail = "You fail to dispel",
			Miss = "Your Tranquilizing Shot miss",
			Resist = "Your Tranquilizing Shot was resisted",
		},
	},
	Spell = Spell,
	SpellReverse = Spell,
}

end)
__bundle_register("Locale/enUS/Spell.enUS.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
	["Aspect of the Wolf"] = "Aspect of the Wolf",
	["Abolish Disease"] = "Abolish Disease",
	["Abolish Poison"] = "Abolish Poison",
	["Abolish Poison Effect"] = "Abolish Poison Effect",
	["Acid Breath"] = "Acid Breath",
	["Acid of Hakkar"] = "Acid of Hakkar",
	["Acid Spit"] = "Acid Spit",
	["Acid Splash"] = "Acid Splash",
	["Activate MG Turret"] = "Activate MG Turret",
	["Adrenaline Rush"] = "Adrenaline Rush",
	["Aftermath"] = "Aftermath",
	["Aggression"] = "Aggression",
	["Aimed Shot"] = "Aimed Shot",
	["Alchemy"] = "Alchemy",
	["Ambush"] = "Ambush",
	["Amplify Curse"] = "Amplify Curse",
	["Amplify Damage"] = "Amplify Damage",
	["Amplify Flames"] = "Amplify Flames",
	["Amplify Magic"] = "Amplify Magic",
	["Ancestral Fortitude"] = "Ancestral Fortitude",
	["Ancestral Healing"] = "Ancestral Healing",
	["Ancestral Knowledge"] = "Ancestral Knowledge",
	["Ancestral Spirit"] = "Ancestral Spirit",
	["Anesthetic Poison"] = "Anesthetic Poison",
	["Anger Management"] = "Anger Management",
	["Anguish"] = "Anguish",
	["Anticipation"] = "Anticipation",
	["Aqua Jet"] = "Aqua Jet",
	["Aquatic Form"] = "Aquatic Form",
	["Arcane Blast"] = "Arcane Blast",
	["Arcane Bolt"] = "Arcane Bolt",
	["Arcane Brilliance"] = "Arcane Brilliance",
	["Arcane Concentration"] = "Arcane Concentration",
	["Arcane Explosion"] = "Arcane Explosion",
	["Arcane Focus"] = "Arcane Focus",
	["Arcane Instability"] = "Arcane Instability",
	["Arcane Intellect"] = "Arcane Intellect",
	["Arcane Meditation"] = "Arcane Meditation",
	["Arcane Mind"] = "Arcane Mind",
	["Arcane Missiles"] = "Arcane Missiles",
	["Arcane Potency"] = "Arcane Potency",
	["Arcane Power"] = "Arcane Power",
	["Arcane Resistance"] = "Arcane Resistance",
	["Arcane Shot"] = "Arcane Shot",
	["Arcane Subtlety"] = "Arcane Subtlety",
	["Arcane Weakness"] = "Arcane Weakness",
	["Arcing Smash"] = "Arcing Smash",
	["Arctic Reach"] = "Arctic Reach",
	["Armorsmith"] = "Armorsmith",
	["Arugal's Curse"] = "Arugal's Curse",
	["Arugal's Gift"] = "Arugal's Gift",
	["Ascendance"] = "Ascendance",
	["Aspect of Arlokk"] = "Aspect of Arlokk",
	["Aspect of Jeklik"] = "Aspect of Jeklik",
	["Aspect of Mar'li"] = "Aspect of Mar'li",
	["Aspect of the Beast"] = "Aspect of the Beast",
	["Aspect of the Cheetah"] = "Aspect of the Cheetah",
	["Aspect of the Hawk"] = "Aspect of the Hawk",
	["Aspect of the Monkey"] = "Aspect of the Monkey",
	["Aspect of the Pack"] = "Aspect of the Pack",
	["Aspect of the Viper"] = "Aspect of the Viper",
	["Aspect of the Wild"] = "Aspect of the Wild",
	["Aspect of Venoxis"] = "Aspect of Venoxis",
	["Astral Recall"] = "Astral Recall",
	["Attack"] = "Attack",
	["Attacking"] = "Attacking",
	["Aura of Command"] = "Aura of Command",
	["Aural Shock"] = "Aural Shock",
	["Auto Shot"] = "Auto Shot",
	["Avenger's Shield"] = "Avenger's Shield",
	["Avenging Wrath"] = "Avenging Wrath",
	["Avoidance"] = "Avoidance",
	["Axe Flurry"] = "Axe Flurry",
	["Axe Specialization"] = "Axe Specialization",
	["Axe Toss"] = "Axe Toss",
	["Backhand"] = "Backhand",
	["Backlash"] = "Backlash",
	["Backstab"] = "Backstab",
	["Bane"] = "Bane",
	["Baneful Poison"] = "Baneful Poison",
	["Banish"] = "Banish",
	["Banshee Curse"] = "Banshee Curse",
	["Banshee Shriek"] = "Banshee Shriek",
	["Barbed Sting"] = "Barbed Sting",
	["Barkskin"] = "Barkskin",
	["Barkskin Effect"] = "Barkskin Effect",
	["Barrage"] = "Barrage",
	["Bash"] = "Bash",
	["Basic Campfire"] = "Basic Campfire",
	["Battle Shout"] = "Battle Shout",
	["Battle Stance"] = "Battle Stance",
	["Battle Stance Passive"] = "Battle Stance Passive",
	["Bear Form"] = "Bear Form",
	["Beast Lore"] = "Beast Lore",
	["Beast Slaying"] = "Beast Slaying",
	["Beast Training"] = "Beast Training",
	["The Beast Within"] = "The Beast Within",
	["Befuddlement"] = "Befuddlement",
	["Benediction"] = "Benediction",
	["Berserker Charge"] = "Berserker Charge",
	["Berserker Rage"] = "Berserker Rage",
	["Berserker Stance"] = "Berserker Stance",
	["Berserker Stance Passive"] = "Berserker Stance Passive",
	["Berserking"] = "Berserking",
	["Bestial Discipline"] = "Bestial Discipline",
	["Bestial Swiftness"] = "Bestial Swiftness",
	["Bestial Wrath"] = "Bestial Wrath",
	["Biletoad Infection"] = "Biletoad Infection",
	["Binding Heal"] = "Binding Heal",
	["Bite"] = "Bite",
	["Black Arrow"] = "Black Arrow",
	["Blackout"] = "Blackout",
	["Blacksmithing"] = "Blacksmithing",
	["Blade Flurry"] = "Blade Flurry",
	["Blast Wave"] = "Blast Wave",
	["Blaze"] = "Blaze",
	["Blazing Speed"] = "Blazing Speed",
	["Blessed Recovery"] = "Blessed Recovery",
	["Blessing of Blackfathom"] = "Blessing of Blackfathom",
	["Blessing of Freedom"] = "Blessing of Freedom",
	["Blessing of Kings"] = "Blessing of Kings",
	["Blessing of Light"] = "Blessing of Light",
	["Blessing of Might"] = "Blessing of Might",
	["Blessing of Protection"] = "Blessing of Protection",
	["Blessing of Sacrifice"] = "Blessing of Sacrifice",
	["Blessing of Salvation"] = "Blessing of Salvation",
	["Blessing of Sanctuary"] = "Blessing of Sanctuary",
	["Blessing of Shahram"] = "Blessing of Shahram",
	["Blessing of Wisdom"] = "Blessing of Wisdom",
	["Blind"] = "Blind",
	["Blinding Powder"] = "Blinding Powder",
	["Blink"] = "Blink",
	["Blizzard"] = "Blizzard",
	["Block"] = "Block",
	["Blood Craze"] = "Blood Craze",
	["Blood Frenzy"] = "Blood Frenzy",
	["Blood Funnel"] = "Blood Funnel",
	["Blood Fury"] = "Blood Fury",
	["Blood Leech"] = "Blood Leech",
	["Blood Pact"] = "Blood Pact",
	["Blood Siphon"] = "Blood Siphon",
	["Blood Tap"] = "Blood Tap",
	["Bloodlust"] = "Bloodlust",
	["Bloodrage"] = "Bloodrage",
	["Bloodthirst"] = "Bloodthirst",
	["Bomb"] = "Bomb",
	["Booming Voice"] = "Booming Voice",
	["Boulder"] = "Boulder",
	["Bow Specialization"] = "Bow Specialization",
	["Bows"] = "Bows",
	["Brain Wash"] = "Brain Wash",
	["Bright Campfire"] = "Bright Campfire",
	["Brutal Impact"] = "Brutal Impact",
	["Burning Adrenaline"] = "Burning Adrenaline",
	["Burning Soul"] = "Burning Soul",
	["Burning Wish"] = "Burning Wish",
	["Butcher Drain"] = "Butcher Drain",
	["Call of Flame"] = "Call of Flame",
	["Call of the Grave"] = "Call of the Grave",
	["Call of Thunder"] = "Call of Thunder",
	["Call Pet"] = "Call Pet",
	["Camouflage"] = "Camouflage",
	["Cannibalize"] = "Cannibalize",
	["Cat Form"] = "Cat Form",
	["Cataclysm"] = "Cataclysm",
	["Cause Insanity"] = "Cause Insanity",
	["Chain Bolt"] = "Chain Bolt",
	["Chain Burn"] = "Chain Burn",
	["Chain Heal"] = "Chain Heal",
	["Chain Lightning"] = "Chain Lightning",
	["Chained Bolt"] = "Chained Bolt",
	["Chains of Ice"] = "Chains of Ice",
	["Challenging Roar"] = "Challenging Roar",
	["Challenging Shout"] = "Challenging Shout",
	["Charge"] = "Charge",
	["Charge Rage Bonus Effect"] = "Charge Rage Bonus Effect",
	["Charge Stun"] = "Charge Stun",
	["Cheap Shot"] = "Cheap Shot",
	["Chilled"] = "Chilled",
	["Chilling Touch"] = "Chilling Touch",
	["Chromatic Infusion"] = "Chromatic Infusion",
	["Circle of Healing"] = "Circle of Healing",
	["Claw"] = "Claw",
	["Cleanse"] = "Cleanse",
	["Cleanse Nova"] = "Cleanse Nova",
	["Clearcasting"] = "Clearcasting",
	["Cleave"] = "Cleave",
	["Clever Traps"] = "Clever Traps",
	["Cloak of Shadows"] = "Cloak of Shadows",
	["Closing"] = "Closing",
	["Cloth"] = "Cloth",
	["Coarse Sharpening Stone"] = "Coarse Sharpening Stone",
	["Cobra Reflexes"] = "Cobra Reflexes",
	["Cold Blood"] = "Cold Blood",
	["Cold Snap"] = "Cold Snap",
	["Combat Endurance"] = "Combat Endurance",
	["Combustion"] = "Combustion",
	["Command"] = "Command",
	["Commanding Shout"] = "Commanding Shout",
	["Concentration Aura"] = "Concentration Aura",
	["Concussion"] = "Concussion",
	["Concussion Blow"] = "Concussion Blow",
	["Concussive Shot"] = "Concussive Shot",
	["Cone of Cold"] = "Cone of Cold",
	["Conflagrate"] = "Conflagrate",
	["Conjure Food"] = "Conjure Food",
	["Conjure Mana Agate"] = "Conjure Mana Agate",
	["Conjure Mana Citrine"] = "Conjure Mana Citrine",
	["Conjure Mana Jade"] = "Conjure Mana Jade",
	["Conjure Mana Ruby"] = "Conjure Mana Ruby",
	["Conjure Water"] = "Conjure Water",
	["Consecrated Sharpening Stone"] = "Consecrated Sharpening Stone",
	["Consecration"] = "Consecration",
	["Consume Magic"] = "Consume Magic",
	["Consume Shadows"] = "Consume Shadows",
	["Consuming Shadows"] = "Consuming Shadows",
	["Convection"] = "Convection",
	["Conviction"] = "Conviction",
	["Cooking"] = "Cooking",
	["Corrosive Acid Breath"] = "Corrosive Acid Breath",
	["Corrosive Ooze"] = "Corrosive Ooze",
	["Corrosive Poison"] = "Corrosive Poison",
	["Corrupted Blood"] = "Corrupted Blood",
	["Corruption"] = "Corruption",
	["Counterattack"] = "Counterattack",
	["Counterspell"] = "Counterspell",
	["Counterspell - Silenced"] = "Counterspell - Silenced",
	["Cower"] = "Cower",
	["Create Firestone"] = "Create Firestone",
	["Create Firestone (Greater)"] = "Create Firestone (Greater)",
	["Create Firestone (Lesser)"] = "Create Firestone (Lesser)",
	["Create Firestone (Major)"] = "Create Firestone (Major)",
	["Create Healthstone"] = "Create Healthstone",
	["Create Healthstone (Greater)"] = "Create Healthstone (Greater)",
	["Create Healthstone (Lesser)"] = "Create Healthstone (Lesser)",
	["Create Healthstone (Major)"] = "Create Healthstone (Major)",
	["Create Healthstone (Minor)"] = "Create Healthstone (Minor)",
	["Create Soulstone"] = "Create Soulstone",
	["Create Soulstone (Greater)"] = "Create Soulstone (Greater)",
	["Create Soulstone (Lesser)"] = "Create Soulstone (Lesser)",
	["Create Soulstone (Major)"] = "Create Soulstone (Major)",
	["Create Soulstone (Minor)"] = "Create Soulstone (Minor)",
	["Create Spellstone"] = "Create Spellstone",
	["Create Spellstone (Greater)"] = "Create Spellstone (Greater)",
	["Create Spellstone (Major)"] = "Create Spellstone (Major)",
	["Create Spellstone (Master)"] = "Create Spellstone (Master)",
	["Creeper Venom"] = "Creeper Venom",
	["Cripple"] = "Cripple",
	["Crippling Poison"] = "Crippling Poison",
	["Crippling Poison II"] = "Crippling Poison II",
	["Critical Mass"] = "Critical Mass",
	["Crossbows"] = "Crossbows",
	["Crowd Pummel"] = "Crowd Pummel",
	["Cruelty"] = "Cruelty",
	["Crusader Aura"] = "Crusader Aura",
	["Crusader Strike"] = "Crusader Strike",
	["Crusader's Wrath"] = "Crusader's Wrath",
	["Crystal Charge"] = "Crystal Charge",
	["Crystal Force"] = "Crystal Force",
	["Crystal Restore"] = "Crystal Restore",
	["Crystal Spire"] = "Crystal Spire",
	["Crystal Ward"] = "Crystal Ward",
	["Crystal Yield"] = "Crystal Yield",
	["Crystalline Slumber"] = "Crystalline Slumber",
	["Cultivation"] = "Cultivation",
	["Cure Disease"] = "Cure Disease",
	["Cure Poison"] = "Cure Poison",
	["Curse of Agony"] = "Curse of Agony",
	["Curse of Blood"] = "Curse of Blood",
	["Curse of Doom"] = "Curse of Doom",
	["Curse of Doom Effect"] = "Curse of Doom Effect",
	["Curse of Exhaustion"] = "Curse of Exhaustion",
	["Curse of Idiocy"] = "Curse of Idiocy",
	["Curse of Recklessness"] = "Curse of Recklessness",
	["Curse of Shadow"] = "Curse of Shadow",
	["Curse of the Deadwood"] = "Curse of the Deadwood",
	["Curse of the Elemental Lord"] = "Curse of the Elemental Lord",
	["Curse of the Elements"] = "Curse of the Elements",
	["Curse of Tongues"] = "Curse of Tongues",
	["Curse of Tuten'kash"] = "Curse of Tuten'kash",
	["Curse of Weakness"] = "Curse of Weakness",
	["Cursed Blood"] = "Cursed Blood",
	["Cyclone"] = "Cyclone",
	["Dagger Specialization"] = "Dagger Specialization",
	["Daggers"] = "Daggers",
	["Dampen Magic"] = "Dampen Magic",
	["Dark Iron Bomb"] = "Dark Iron Bomb",
	["Dark Offering"] = "Dark Offering",
	["Dark Pact"] = "Dark Pact",
	["Darkness"] = "Darkness",
	["Dash"] = "Dash",
	["Dazed"] = "Dazed",
	["Deadly Poison"] = "Deadly Poison",
	["Deadly Poison II"] = "Deadly Poison II",
	["Deadly Poison III"] = "Deadly Poison III",
	["Deadly Poison IV"] = "Deadly Poison IV",
	["Deadly Poison V"] = "Deadly Poison V",
	["Deadly Throw"] = "Deadly Throw",
	["Death Coil"] = "Death Coil",
	["Death Wish"] = "Death Wish",
	["Deep Sleep"] = "Deep Sleep",
	["Deep Slumber"] = "Deep Slumber",
	["Deep Wounds"] = "Deep Wounds",
	["Defense"] = "Defense",
	["Defensive Stance"] = "Defensive Stance",
	["Defensive Stance Passive"] = "Defensive Stance Passive",
	["Defensive State"] = "Defensive State",
	["Defensive State 2"] = "Defensive State 2",
	["Defiance"] = "Defiance",
	["Deflection"] = "Deflection",
	["Delusions of Jin'do"] = "Delusions of Jin'do",
	["Demon Armor"] = "Demon Armor",
	["Demon Skin"] = "Demon Skin",
	["Demonic Embrace"] = "Demonic Embrace",
	["Demonic Frenzy"] = "Demonic Frenzy",
	["Demonic Sacrifice"] = "Demonic Sacrifice",
	["Demoralizing Roar"] = "Demoralizing Roar",
	["Demoralizing Shout"] = "Demoralizing Shout",
	["Dense Sharpening Stone"] = "Dense Sharpening Stone",
	["Desperate Prayer"] = "Desperate Prayer",
	["Destructive Reach"] = "Destructive Reach",
	["Detect"] = "Detect",
	["Detect Greater Invisibility"] = "Detect Greater Invisibility",
	["Detect Invisibility"] = "Detect Invisibility",
	["Detect Lesser Invisibility"] = "Detect Lesser Invisibility",
	["Detect Magic"] = "Detect Magic",
	["Detect Traps"] = "Detect Traps",
	["Deterrence"] = "Deterrence",
	["Detonation"] = "Detonation",
	["Devastate"] = "Devastate",
	["Devastation"] = "Devastation",
	["Devotion Aura"] = "Devotion Aura",
	["Devour Magic"] = "Devour Magic",
	["Devour Magic Effect"] = "Devour Magic Effect",
	["Devouring Plague"] = "Devouring Plague",
	["Diamond Flask"] = "Diamond Flask",
	["Diplomacy"] = "Diplomacy",
	["Dire Bear Form"] = "Dire Bear Form",
	["Dire Growl"] = "Dire Growl",
	["Disarm"] = "Disarm",
	["Disarm Trap"] = "Disarm Trap",
	["Disease Cleansing Totem"] = "Disease Cleansing Totem",
	["Disease Cloud"] = "Disease Cloud",
	["Diseased Shot"] = "Diseased Shot",
	["Diseased Spit"] = "Diseased Spit",
	["Disenchant"] = "Disenchant",
	["Disengage"] = "Disengage",
	["Disjunction"] = "Disjunction",
	["Dismiss Pet"] = "Dismiss Pet",
	["Dispel Magic"] = "Dispel Magic",
	["Distract"] = "Distract",
	["Distracting Pain"] = "Distracting Pain",
	["Distracting Shot"] = "Distracting Shot",
	["Dive"] = "Dive",
	["Divine Favor"] = "Divine Favor",
	["Divine Fury"] = "Divine Fury",
	["Divine Illumination"] = "Divine Illumination",
	["Divine Intellect"] = "Divine Intellect",
	["Divine Intervention"] = "Divine Intervention",
	["Divine Protection"] = "Divine Protection",
	["Divine Shield"] = "Divine Shield",
	["Divine Spirit"] = "Divine Spirit",
	["Divine Strength"] = "Divine Strength",
	["Diving Sweep"] = "Diving Sweep",
	["Dodge"] = "Dodge",
	["Dominate Mind"] = "Dominate Mind",
	["Dragon's Breath"] = "Dragon's Breath",
	["Dragonscale Leatherworking"] = "Dragonscale Leatherworking",
	["Drain Life"] = "Drain Life",
	["Drain Mana"] = "Drain Mana",
	["Drain Soul"] = "Drain Soul",
	["Dredge Sickness"] = "Dredge Sickness",
	["Drink"] = "Drink",
	["Druid's Slumber"] = "Druid's Slumber",
	["Dual Wield"] = "Dual Wield",
	["Dual Wield Specialization"] = "Dual Wield Specialization",
	["Duel"] = "Duel",
	["Dust Field"] = "Dust Field",
	["Eagle Eye"] = "Eagle Eye",
	["Earth Elemental Totem"] = "Earth Elemental Totem",
	["Earth Shield"] = "Earth Shield",
	["Earth Shock"] = "Earth Shock",
	["Earthbind Totem"] = "Earthbind Totem",
	["Earthborer Acid"] = "Earthborer Acid",
	["Earthgrab"] = "Earthgrab",
	["Efficiency"] = "Efficiency",
	["Electric Discharge"] = "Electric Discharge",
	["Electrified Net"] = "Electrified Net",
	["Elemental Focus"] = "Elemental Focus",
	["Elemental Fury"] = "Elemental Fury",
	["Elemental Leatherworking"] = "Elemental Leatherworking",
	["Elemental Mastery"] = "Elemental Mastery",
	["Elemental Precision"] = "Elemental Precision",
	["Elemental Sharpening Stone"] = "Elemental Sharpening Stone",
	["Elune's Grace"] = "Elune's Grace",
	["Elusiveness"] = "Elusiveness",
	["Emberstorm"] = "Emberstorm",
	["Enamored Water Spirit"] = "Enamored Water Spirit",
	["Enchanting"] = "Enchanting",
	["Endurance"] = "Endurance",
	["Endurance Training"] = "Endurance Training",
	["Engineering"] = "Engineering",
	["Engineering Specialization"] = "Engineering Specialization",
	["Enrage"] = "Enrage",
	["Enriched Manna Biscuit"] = "Enriched Manna Biscuit",
	["Enslave Demon"] = "Enslave Demon",
	["Entangling Roots"] = "Entangling Roots",
	["Entrapment"] = "Entrapment",
	["Enveloping Web"] = "Enveloping Web",
	["Enveloping Webs"] = "Enveloping Webs",
	["Enveloping Winds"] = "Enveloping Winds",
	["Envenom"] = "Envenom",
	["Ephemeral Power"] = "Ephemeral Power",
	["Escape Artist"] = "Escape Artist",
	["Essence of Sapphiron"] = "Essence of Sapphiron",
	["Evasion"] = "Evasion",
	["Eventide"] = "Eventide",
	["Eviscerate"] = "Eviscerate",
	["Evocation"] = "Evocation",
	["Execute"] = "Execute",
	["Exorcism"] = "Exorcism",
	["Expansive Mind"] = "Expansive Mind",
	["Exploding Shot"] = "Exploding Shot",
	["Exploit Weakness"] = "Exploit Weakness",
	["Explosive Shot"] = "Explosive Shot",
	["Explosive Trap"] = "Explosive Trap",
	["Explosive Trap Effect"] = "Explosive Trap Effect",
	["Expose Armor"] = "Expose Armor",
	["Expose Weakness"] = "Expose Weakness",
	["Eye for an Eye"] = "Eye for an Eye",
	["Eye of Kilrogg"] = "Eye of Kilrogg",
	["The Eye of the Dead"] = "The Eye of the Dead",
	["Eyes of the Beast"] = "Eyes of the Beast",
	["Fade"] = "Fade",
	["Faerie Fire"] = "Faerie Fire",
	["Faerie Fire (Feral)"] = "Faerie Fire (Feral)",
	["Far Sight"] = "Far Sight",
	["Fatal Bite"] = "Fatal Bite",
	["Fear"] = "Fear",
	["Fear Ward"] = "Fear Ward",
	["Feed Pet"] = "Feed Pet",
	["Feedback"] = "Feedback",
	["Feign Death"] = "Feign Death",
	["Feint"] = "Feint",
	["Fel Armor"] = "Fel Armor",
	["Fel Concentration"] = "Fel Concentration",
	["Fel Domination"] = "Fel Domination",
	["Fel Intellect"] = "Fel Intellect",
	["Fel Stamina"] = "Fel Stamina",
	["Fel Stomp"] = "Fel Stomp",
	["Felfire"] = "Felfire",
	["Feline Grace"] = "Feline Grace",
	["Feline Swiftness"] = "Feline Swiftness",
	["Feral Aggression"] = "Feral Aggression",
	["Feral Charge"] = "Feral Charge",
	["Feral Instinct"] = "Feral Instinct",
	["Ferocious Bite"] = "Ferocious Bite",
	["Ferocity"] = "Ferocity",
	["Fetish"] = "Fetish",
	["Fevered Plague"] = "Fevered Plague",
	["Fiery Burst"] = "Fiery Burst",
	["Find Herbs"] = "Find Herbs",
	["Find Minerals"] = "Find Minerals",
	["Find Treasure"] = "Find Treasure",
	["Fire Blast"] = "Fire Blast",
	["Fire Elemental Totem"] = "Fire Elemental Totem",
	["Fire Nova"] = "Fire Nova",
	["Fire Nova Totem"] = "Fire Nova Totem",
	["Fire Power"] = "Fire Power",
	["Fire Resistance"] = "Fire Resistance",
	["Fire Resistance Aura"] = "Fire Resistance Aura",
	["Fire Resistance Totem"] = "Fire Resistance Totem",
	["Fire Shield"] = "Fire Shield",
	["Fire Shield Effect"] = "Fire Shield Effect",
	["Fire Shield Effect II"] = "Fire Shield Effect II",
	["Fire Shield Effect III"] = "Fire Shield Effect III",
	["Fire Shield Effect IV"] = "Fire Shield Effect IV",
	["Fire Storm"] = "Fire Storm",
	["Fire Vulnerability"] = "Fire Vulnerability",
	["Fire Ward"] = "Fire Ward",
	["Fire Weakness"] = "Fire Weakness",
	["Fireball"] = "Fireball",
	["Fireball Volley"] = "Fireball Volley",
	["Firebolt"] = "Firebolt",
	["First Aid"] = "First Aid",
	["Fishing"] = "Fishing",
	["Fishing Poles"] = "Fishing Poles",
	["Fist of Ragnaros"] = "Fist of Ragnaros",
	["Fist Weapon Specialization"] = "Fist Weapon Specialization",
	["Fist Weapons"] = "Fist Weapons",
	["Flame Buffet"] = "Flame Buffet",
	["Flame Cannon"] = "Flame Cannon",
	["Flame Lash"] = "Flame Lash",
	["Flame Shock"] = "Flame Shock",
	["Flame Spike"] = "Flame Spike",
	["Flame Spray"] = "Flame Spray",
	["Flame Throwing"] = "Flame Throwing",
	["Flames of Shahram"] = "Flames of Shahram",
	["Flamestrike"] = "Flamestrike",
	["Flamethrower"] = "Flamethrower",
	["Flametongue Totem"] = "Flametongue Totem",
	["Flametongue Weapon"] = "Flametongue Weapon",
	["Flare"] = "Flare",
	["Flash Bomb"] = "Flash Bomb",
	["Flash Heal"] = "Flash Heal",
	["Flash of Light"] = "Flash of Light",
	["Flight Form"] = "Flight Form",
	["Flurry"] = "Flurry",
	["Focused Casting"] = "Focused Casting",
	["Focused Mind"] = "Focused Mind",
	["Food"] = "Food",
	["Forbearance"] = "Forbearance",
	["Force of Nature"] = "Force of Nature",
	["Force of Will"] = "Force of Will",
	["Force Punch"] = "Force Punch",
	["Force Reactive Disk"] = "Force Reactive Disk",
	["Forked Lightning"] = "Forked Lightning",
	["Forsaken Skills"] = "Forsaken Skills",
	["Frailty"] = "Frailty",
	["Freeze Solid"] = "Freeze Solid",
	["Freezing Trap"] = "Freezing Trap",
	["Freezing Trap Effect"] = "Freezing Trap Effect",
	["Frenzied Regeneration"] = "Frenzied Regeneration",
	["Frenzy"] = "Frenzy",
	["Frost Armor"] = "Frost Armor",
	["Frost Breath"] = "Frost Breath",
	["Frost Channeling"] = "Frost Channeling",
	["Frost Nova"] = "Frost Nova",
	["Frost Resistance"] = "Frost Resistance",
	["Frost Resistance Aura"] = "Frost Resistance Aura",
	["Frost Resistance Totem"] = "Frost Resistance Totem",
	["Frost Shock"] = "Frost Shock",
	["Frost Shot"] = "Frost Shot",
	["Frost Trap"] = "Frost Trap",
	["Frost Trap Aura"] = "Frost Trap Aura",
	["Frost Ward"] = "Frost Ward",
	["Frost Warding"] = "Frost Warding",
	["Frost Weakness"] = "Frost Weakness",
	["Frostbite"] = "Frostbite",
	["Frostbolt"] = "Frostbolt",
	["Frostbolt Volley"] = "Frostbolt Volley",
	["Frostbrand Weapon"] = "Frostbrand Weapon",
	["Furious Howl"] = "Furious Howl",
	["The Furious Storm"] = "The Furious Storm",
	["Furor"] = "Furor",
	["Fury of Ragnaros"] = "Fury of Ragnaros",
	["Gahz'ranka Slam"] = "Gahz'ranka Slam",
	["Gahz'rilla Slam"] = "Gahz'rilla Slam",
	["Garrote"] = "Garrote",
	["Gehennas' Curse"] = "Gehennas' Curse",
	["Generic"] = "Generic",
	["Ghost Wolf"] = "Ghost Wolf",
	["Ghostly Strike"] = "Ghostly Strike",
	["Gift of Life"] = "Gift of Life",
	["Gift of Nature"] = "Gift of Nature",
	["Gift of the Wild"] = "Gift of the Wild",
	["Goblin Dragon Gun"] = "Goblin Dragon Gun",
	["Goblin Sapper Charge"] = "Goblin Sapper Charge",
	["Gouge"] = "Gouge",
	["Grace of Air Totem"] = "Grace of Air Totem",
	["Grace of the Sunwell"] = "Grace of the Sunwell",
	["Grasping Vines"] = "Grasping Vines",
	["Great Stamina"] = "Great Stamina",
	["Greater Blessing of Kings"] = "Greater Blessing of Kings",
	["Greater Blessing of Light"] = "Greater Blessing of Light",
	["Greater Blessing of Might"] = "Greater Blessing of Might",
	["Greater Blessing of Salvation"] = "Greater Blessing of Salvation",
	["Greater Blessing of Sanctuary"] = "Greater Blessing of Sanctuary",
	["Greater Blessing of Wisdom"] = "Greater Blessing of Wisdom",
	["Greater Heal"] = "Greater Heal",
	["Grim Reach"] = "Grim Reach",
	["Ground Tremor"] = "Ground Tremor",
	["Grounding Totem"] = "Grounding Totem",
	["Grovel"] = "Grovel",
	["Growl"] = "Growl",
	["Guardian's Favor"] = "Guardian's Favor",
	["Guillotine"] = "Guillotine",
	["Gun Specialization"] = "Gun Specialization",
	["Guns"] = "Guns",
	["Hail Storm"] = "Hail Storm",
	["Hammer of Justice"] = "Hammer of Justice",
	["Hammer of Wrath"] = "Hammer of Wrath",
	["Hamstring"] = "Hamstring",
	["Harass"] = "Harass",
	["Hardiness"] = "Hardiness",
	["Haunting Spirits"] = "Haunting Spirits",
	["Hawk Eye"] = "Hawk Eye",
	["Head Crack"] = "Head Crack",
	["Heal"] = "Heal",
	["Healing Circle"] = "Healing Circle",
	["Healing Focus"] = "Healing Focus",
	["Healing Light"] = "Healing Light",
	["Healing of the Ages"] = "Healing of the Ages",
	["Healing Stream Totem"] = "Healing Stream Totem",
	["Healing Touch"] = "Healing Touch",
	["Healing Wave"] = "Healing Wave",
	["Healing Way"] = "Healing Way",
	["Health Funnel"] = "Health Funnel",
	["Heart of the Wild"] = "Heart of the Wild",
	["Heavy Sharpening Stone"] = "Heavy Sharpening Stone",
	["Hellfire"] = "Hellfire",
	["Hellfire Effect"] = "Hellfire Effect",
	["Hemorrhage"] = "Hemorrhage",
	["Herb Gathering"] = "Herb Gathering",
	["Herbalism"] = "Herbalism",
	["Heroic Strike"] = "Heroic Strike",
	["Heroism"] = "Heroism",
	["Hex"] = "Hex",
	["Hex of Jammal'an"] = "Hex of Jammal'an",
	["Hex of Weakness"] = "Hex of Weakness",
	["Hibernate"] = "Hibernate",
	["Holy Fire"] = "Holy Fire",
	["Holy Light"] = "Holy Light",
	["Holy Nova"] = "Holy Nova",
	["Holy Power"] = "Holy Power",
	["Holy Reach"] = "Holy Reach",
	["Holy Shield"] = "Holy Shield",
	["Holy Shock"] = "Holy Shock",
	["Holy Smite"] = "Holy Smite",
	["Holy Specialization"] = "Holy Specialization",
	["Holy Strength"] = "Holy Strength",
	["Holy Strike"] = "Holy Strike",
	["Holy Wrath"] = "Holy Wrath",
	["Honorless Target"] = "Honorless Target",
	["Hooked Net"] = "Hooked Net",
	["Horse Riding"] = "Horse Riding",
	["Howl of Terror"] = "Howl of Terror",
	["The Human Spirit"] = "The Human Spirit",
	["Humanoid Slaying"] = "Humanoid Slaying",
	["Hunter's Mark"] = "Hunter's Mark",
	["Hurricane"] = "Hurricane",
	["Ice Armor"] = "Ice Armor",
	["Ice Barrier"] = "Ice Barrier",
	["Ice Blast"] = "Ice Blast",
	["Ice Block"] = "Ice Block",
	["Ice Lance"] = "Ice Lance",
	["Ice Nova"] = "Ice Nova",
	["Ice Shards"] = "Ice Shards",
	["Icicle"] = "Icicle",
	["Ignite"] = "Ignite",
	["Illumination"] = "Illumination",
	["Immolate"] = "Immolate",
	["Immolation Trap"] = "Immolation Trap",
	["Immolation Trap Effect"] = "Immolation Trap Effect",
	["Impact"] = "Impact",
	["Impale"] = "Impale",
	["Improved Ambush"] = "Improved Ambush",
	["Improved Arcane Explosion"] = "Improved Arcane Explosion",
	["Improved Arcane Missiles"] = "Improved Arcane Missiles",
	["Improved Arcane Shot"] = "Improved Arcane Shot",
	["Improved Aspect of the Hawk"] = "Improved Aspect of the Hawk",
	["Improved Aspect of the Monkey"] = "Improved Aspect of the Monkey",
	["Improved Backstab"] = "Improved Backstab",
	["Improved Battle Shout"] = "Improved Battle Shout",
	["Improved Berserker Rage"] = "Improved Berserker Rage",
	["Improved Blessing of Might"] = "Improved Blessing of Might",
	["Improved Blessing of Wisdom"] = "Improved Blessing of Wisdom",
	["Improved Blizzard"] = "Improved Blizzard",
	["Improved Bloodrage"] = "Improved Bloodrage",
	["Improved Chain Heal"] = "Improved Chain Heal",
	["Improved Chain Lightning"] = "Improved Chain Lightning",
	["Improved Challenging Shout"] = "Improved Challenging Shout",
	["Improved Charge"] = "Improved Charge",
	["Improved Cheap Shot"] = "Improved Cheap Shot",
	["Improved Cleave"] = "Improved Cleave",
	["Improved Concentration Aura"] = "Improved Concentration Aura",
	["Improved Concussive Shot"] = "Improved Concussive Shot",
	["Improved Cone of Cold"] = "Improved Cone of Cold",
	["Improved Corruption"] = "Improved Corruption",
	["Improved Counterspell"] = "Improved Counterspell",
	["Improved Curse of Agony"] = "Improved Curse of Agony",
	["Improved Curse of Exhaustion"] = "Improved Curse of Exhaustion",
	["Improved Curse of Weakness"] = "Improved Curse of Weakness",
	["Improved Dampen Magic"] = "Improved Dampen Magic",
	["Improved Deadly Poison"] = "Improved Deadly Poison",
	["Improved Demoralizing Shout"] = "Improved Demoralizing Shout",
	["Improved Devotion Aura"] = "Improved Devotion Aura",
	["Improved Disarm"] = "Improved Disarm",
	["Improved Distract"] = "Improved Distract",
	["Improved Drain Life"] = "Improved Drain Life",
	["Improved Drain Mana"] = "Improved Drain Mana",
	["Improved Drain Soul"] = "Improved Drain Soul",
	["Improved Enrage"] = "Improved Enrage",
	["Improved Enslave Demon"] = "Improved Enslave Demon",
	["Improved Entangling Roots"] = "Improved Entangling Roots",
	["Improved Evasion"] = "Improved Evasion",
	["Improved Eviscerate"] = "Improved Eviscerate",
	["Improved Execute"] = "Improved Execute",
	["Improved Expose Armor"] = "Improved Expose Armor",
	["Improved Eyes of the Beast"] = "Improved Eyes of the Beast",
	["Improved Fade"] = "Improved Fade",
	["Improved Feign Death"] = "Improved Feign Death",
	["Improved Fire Blast"] = "Improved Fire Blast",
	["Improved Fire Nova Totem"] = "Improved Fire Nova Totem",
	["Improved Fire Ward"] = "Improved Fire Ward",
	["Improved Fireball"] = "Improved Fireball",
	["Improved Firebolt"] = "Improved Firebolt",
	["Improved Firestone"] = "Improved Firestone",
	["Improved Flamestrike"] = "Improved Flamestrike",
	["Improved Flametongue Weapon"] = "Improved Flametongue Weapon",
	["Improved Flash of Light"] = "Improved Flash of Light",
	["Improved Frost Nova"] = "Improved Frost Nova",
	["Improved Frost Ward"] = "Improved Frost Ward",
	["Improved Frostbolt"] = "Improved Frostbolt",
	["Improved Frostbrand Weapon"] = "Improved Frostbrand Weapon",
	["Improved Garrote"] = "Improved Garrote",
	["Improved Ghost Wolf"] = "Improved Ghost Wolf",
	["Improved Gouge"] = "Improved Gouge",
	["Improved Grace of Air Totem"] = "Improved Grace of Air Totem",
	["Improved Grounding Totem"] = "Improved Grounding Totem",
	["Improved Hammer of Justice"] = "Improved Hammer of Justice",
	["Improved Hamstring"] = "Improved Hamstring",
	["Improved Healing"] = "Improved Healing",
	["Improved Healing Stream Totem"] = "Improved Healing Stream Totem",
	["Improved Healing Touch"] = "Improved Healing Touch",
	["Improved Healing Wave"] = "Improved Healing Wave",
	["Improved Health Funnel"] = "Improved Health Funnel",
	["Improved Healthstone"] = "Improved Healthstone",
	["Improved Heroic Strike"] = "Improved Heroic Strike",
	["Improved Hunter's Mark"] = "Improved Hunter's Mark",
	["Improved Immolate"] = "Improved Immolate",
	["Improved Imp"] = "Improved Imp",
	["Improved Inner Fire"] = "Improved Inner Fire",
	["Improved Instant Poison"] = "Improved Instant Poison",
	["Improved Intercept"] = "Improved Intercept",
	["Improved Intimidating Shout"] = "Improved Intimidating Shout",
	["Improved Judgement"] = "Improved Judgement",
	["Improved Kick"] = "Improved Kick",
	["Improved Kidney Shot"] = "Improved Kidney Shot",
	["Improved Lash of Pain"] = "Improved Lash of Pain",
	["Improved Lay on Hands"] = "Improved Lay on Hands",
	["Improved Lesser Healing Wave"] = "Improved Lesser Healing Wave",
	["Improved Life Tap"] = "Improved Life Tap",
	["Improved Lightning Bolt"] = "Improved Lightning Bolt",
	["Improved Lightning Shield"] = "Improved Lightning Shield",
	["Improved Magma Totem"] = "Improved Magma Totem",
	["Improved Mana Burn"] = "Improved Mana Burn",
	["Improved Mana Shield"] = "Improved Mana Shield",
	["Improved Mana Spring Totem"] = "Improved Mana Spring Totem",
	["Improved Mark of the Wild"] = "Improved Mark of the Wild",
	["Improved Mend Pet"] = "Improved Mend Pet",
	["Improved Mind Blast"] = "Improved Mind Blast",
	["Improved Moonfire"] = "Improved Moonfire",
	["Improved Nature's Grasp"] = "Improved Nature's Grasp",
	["Improved Overpower"] = "Improved Overpower",
	["Improved Power Word: Fortitude"] = "Improved Power Word: Fortitude",
	["Improved Power Word: Shield"] = "Improved Power Word: Shield",
	["Improved Prayer of Healing"] = "Improved Prayer of Healing",
	["Improved Psychic Scream"] = "Improved Psychic Scream",
	["Improved Pummel"] = "Improved Pummel",
	["Improved Regrowth"] = "Improved Regrowth",
	["Improved Reincarnation"] = "Improved Reincarnation",
	["Improved Rejuvenation"] = "Improved Rejuvenation",
	["Improved Rend"] = "Improved Rend",
	["Improved Renew"] = "Improved Renew",
	["Improved Retribution Aura"] = "Improved Retribution Aura",
	["Improved Revenge"] = "Improved Revenge",
	["Improved Revive Pet"] = "Improved Revive Pet",
	["Improved Righteous Fury"] = "Improved Righteous Fury",
	["Improved Rockbiter Weapon"] = "Improved Rockbiter Weapon",
	["Improved Rupture"] = "Improved Rupture",
	["Improved Sap"] = "Improved Sap",
	["Improved Scorch"] = "Improved Scorch",
	["Improved Scorpid Sting"] = "Improved Scorpid Sting",
	["Improved Seal of Righteousness"] = "Improved Seal of Righteousness",
	["Improved Seal of the Crusader"] = "Improved Seal of the Crusader",
	["Improved Searing Pain"] = "Improved Searing Pain",
	["Improved Searing Totem"] = "Improved Searing Totem",
	["Improved Serpent Sting"] = "Improved Serpent Sting",
	["Improved Shadow Bolt"] = "Improved Shadow Bolt",
	["Improved Shadow Word: Pain"] = "Improved Shadow Word: Pain",
	["Improved Shield Bash"] = "Improved Shield Bash",
	["Improved Shield Block"] = "Improved Shield Block",
	["Improved Shield Wall"] = "Improved Shield Wall",
	["Improved Shred"] = "Improved Shred",
	["Improved Sinister Strike"] = "Improved Sinister Strike",
	["Improved Slam"] = "Improved Slam",
	["Improved Slice and Dice"] = "Improved Slice and Dice",
	["Improved Spellstone"] = "Improved Spellstone",
	["Improved Sprint"] = "Improved Sprint",
	["Improved Starfire"] = "Improved Starfire",
	["Improved Stoneclaw Totem"] = "Improved Stoneclaw Totem",
	["Improved Stoneskin Totem"] = "Improved Stoneskin Totem",
	["Improved Strength of Earth Totem"] = "Improved Strength of Earth Totem",
	["Improved Succubus"] = "Improved Succubus",
	["Improved Sunder Armor"] = "Improved Sunder Armor",
	["Improved Taunt"] = "Improved Taunt",
	["Improved Thorns"] = "Improved Thorns",
	["Improved Thunder Clap"] = "Improved Thunder Clap",
	["Improved Tranquility"] = "Improved Tranquility",
	["Improved Vampiric Embrace"] = "Improved Vampiric Embrace",
	["Improved Vanish"] = "Improved Vanish",
	["Improved Voidwalker"] = "Improved Voidwalker",
	["Improved Windfury Weapon"] = "Improved Windfury Weapon",
	["Improved Wing Clip"] = "Improved Wing Clip",
	["Improved Wrath"] = "Improved Wrath",
	["Incinerate"] = "Incinerate",
	["Infected Bite"] = "Infected Bite",
	["Infected Wound"] = "Infected Wound",
	["Inferno"] = "Inferno",
	["Inferno Shell"] = "Inferno Shell",
	["Initiative"] = "Initiative",
	["Inner Fire"] = "Inner Fire",
	["Inner Focus"] = "Inner Focus",
	["Innervate"] = "Innervate",
	["Insect Swarm"] = "Insect Swarm",
	["Inspiration"] = "Inspiration",
	["Instant Poison"] = "Instant Poison",
	["Instant Poison II"] = "Instant Poison II",
	["Instant Poison III"] = "Instant Poison III",
	["Instant Poison IV"] = "Instant Poison IV",
	["Instant Poison V"] = "Instant Poison V",
	["Instant Poison VI"] = "Instant Poison VI",
	["Intensity"] = "Intensity",
	["Intercept"] = "Intercept",
	["Intercept Stun"] = "Intercept Stun",
	["Intervene"] = "Intervene",
	["Intimidating Roar"] = "Intimidating Roar",
	["Intimidating Shout"] = "Intimidating Shout",
	["Intimidation"] = "Intimidation",
	["Intoxicating Venom"] = "Intoxicating Venom",
	["Invisibility"] = "Invisibility",
	["Iron Will"] = "Iron Will",
	["Jewelcrafting"] = "Jewelcrafting",
	["Judgement"] = "Judgement",
	["Judgement of Command"] = "Judgement of Command",
	["Judgement of Justice"] = "Judgement of Justice",
	["Judgement of Light"] = "Judgement of Light",
	["Judgement of Righteousness"] = "Judgement of Righteousness",
	["Judgement of the Crusader"] = "Judgement of the Crusader",
	["Judgement of Wisdom"] = "Judgement of Wisdom",
	["Kick"] = "Kick",
	["Kick - Silenced"] = "Kick - Silenced",
	["Kidney Shot"] = "Kidney Shot",
	["Kill Command"] = "Kill Command",
	["Killer Instinct"] = "Killer Instinct",
	["Knock Away"] = "Knock Away",
	["Knockdown"] = "Knockdown",
	["Kodo Riding"] = "Kodo Riding",
	["Lacerate"] = "Lacerate",
	["Larva Goo"] = "Larva Goo",
	["Lash"] = "Lash",
	["Lash of Pain"] = "Lash of Pain",
	["Last Stand"] = "Last Stand",
	["Lasting Judgement"] = "Lasting Judgement",
	["Lava Spout Totem"] = "Lava Spout Totem",
	["Lay on Hands"] = "Lay on Hands",
	["Leader of the Pack"] = "Leader of the Pack",
	["Leather"] = "Leather",
	["Leatherworking"] = "Leatherworking",
	["Leech Poison"] = "Leech Poison",
	["Lesser Heal"] = "Lesser Heal",
	["Lesser Healing Wave"] = "Lesser Healing Wave",
	["Lesser Invisibility"] = "Lesser Invisibility",
	["Lethal Shots"] = "Lethal Shots",
	["Lethality"] = "Lethality",
	["Levitate"] = "Levitate",
	["Libram"] = "Libram",
	["Lich Slap"] = "Lich Slap",
	["Life Tap"] = "Life Tap",
	["Lifebloom"] = "Lifebloom",
	["Lifegiving Gem"] = "Lifegiving Gem",
	["Lightning Blast"] = "Lightning Blast",
	["Lightning Bolt"] = "Lightning Bolt",
	["Lightning Breath"] = "Lightning Breath",
	["Lightning Cloud"] = "Lightning Cloud",
	["Lightning Mastery"] = "Lightning Mastery",
	["Lightning Reflexes"] = "Lightning Reflexes",
	["Lightning Shield"] = "Lightning Shield",
	["Lightning Wave"] = "Lightning Wave",
	["Lightwell"] = "Lightwell",
	["Lightwell Renew"] = "Lightwell Renew",
	["Lizard Bolt"] = "Lizard Bolt",
	["Localized Toxin"] = "Localized Toxin",
	["Lockpicking"] = "Lockpicking",
	["Long Daze"] = "Long Daze",
	["Mace Specialization"] = "Mace Specialization",
	["Mace Stun Effect"] = "Mace Stun Effect",
	["Machine Gun"] = "Machine Gun",
	["Mage Armor"] = "Mage Armor",
	["Magic Attunement"] = "Magic Attunement",
	["Magma Splash"] = "Magma Splash",
	["Magma Totem"] = "Magma Totem",
	["Mail"] = "Mail",
	["Maim"] = "Maim",
	["Malice"] = "Malice",
	["Mana Burn"] = "Mana Burn",
	["Mana Feed"] = "Mana Feed",
	["Mana Shield"] = "Mana Shield",
	["Mana Spring Totem"] = "Mana Spring Totem",
	["Mana Tide Totem"] = "Mana Tide Totem",
	["Mangle"] = "Mangle",
	["Mangle (Bear)"] = "Mangle (Bear)",
	["Mangle (Cat)"] = "Mangle (Cat)",
	["Mark of Arlokk"] = "Mark of Arlokk",
	["Mark of the Wild"] = "Mark of the Wild",
	["Martyrdom"] = "Martyrdom",
	["Mass Dispel"] = "Mass Dispel",
	["Master Demonologist"] = "Master Demonologist",
	["Master of Deception"] = "Master of Deception",
	["Master of Elements"] = "Master of Elements",
	["Master Summoner"] = "Master Summoner",
	["Maul"] = "Maul",
	["Mechanostrider Piloting"] = "Mechanostrider Piloting",
	["Meditation"] = "Meditation",
	["Megavolt"] = "Megavolt",
	["Melee Specialization"] = "Melee Specialization",
	["Melt Ore"] = "Melt Ore",
	["Mend Pet"] = "Mend Pet",
	["Mental Agility"] = "Mental Agility",
	["Mental Strength"] = "Mental Strength",
	["Mighty Blow"] = "Mighty Blow",
	["Mind Blast"] = "Mind Blast",
	["Mind Control"] = "Mind Control",
	["Mind Flay"] = "Mind Flay",
	["Mind Soothe"] = "Mind Soothe",
	["Mind Tremor"] = "Mind Tremor",
	["Mind Vision"] = "Mind Vision",
	["Mind-numbing Poison"] = "Mind-numbing Poison",
	["Mind-numbing Poison II"] = "Mind-numbing Poison II",
	["Mind-numbing Poison III"] = "Mind-numbing Poison III",
	["Mining"] = "Mining",
	["Misdirection"] = "Misdirection",
	["Mocking Blow"] = "Mocking Blow",
	["Molten Armor"] = "Molten Armor",
	["Molten Blast"] = "Molten Blast",
	["Molten Metal"] = "Molten Metal",
	["Mongoose Bite"] = "Mongoose Bite",
	["Monster Slaying"] = "Monster Slaying",
	["Moonfire"] = "Moonfire",
	["Moonfury"] = "Moonfury",
	["Moonglow"] = "Moonglow",
	["Moonkin Aura"] = "Moonkin Aura",
	["Moonkin Form"] = "Moonkin Form",
	["Mortal Cleave"] = "Mortal Cleave",
	["Mortal Shots"] = "Mortal Shots",
	["Mortal Strike"] = "Mortal Strike",
	["Mortal Wound"] = "Mortal Wound",
	["Multi-Shot"] = "Multi-Shot",
	["Murder"] = "Murder",
	["Mutilate"] = "Mutilate",
	["Naralex's Nightmare"] = "Naralex's Nightmare",
	["Natural Armor"] = "Natural Armor",
	["Natural Shapeshifter"] = "Natural Shapeshifter",
	["Natural Weapons"] = "Natural Weapons",
	["Nature Aligned"] = "Nature Aligned",
	["Nature Resistance"] = "Nature Resistance",
	["Nature Resistance Totem"] = "Nature Resistance Totem",
	["Nature Weakness"] = "Nature Weakness",
	["Nature's Focus"] = "Nature's Focus",
	["Nature's Grace"] = "Nature's Grace",
	["Nature's Grasp"] = "Nature's Grasp",
	["Nature's Reach"] = "Nature's Reach",
	["Nature's Swiftness"] = "Nature's Swiftness",
	["Necrotic Poison"] = "Necrotic Poison",
	["Negative Charge"] = "Negative Charge",
	["Net"] = "Net",
	["Nightfall"] = "Nightfall",
	["Noxious Catalyst"] = "Noxious Catalyst",
	["Noxious Cloud"] = "Noxious Cloud",
	["Omen of Clarity"] = "Omen of Clarity",
	["One-Handed Axes"] = "One-Handed Axes",
	["One-Handed Maces"] = "One-Handed Maces",
	["One-Handed Swords"] = "One-Handed Swords",
	["One-Handed Weapon Specialization"] = "One-Handed Weapon Specialization",
	["Opening"] = "Opening",
	["Opening - No Text"] = "Opening - No Text",
	["Opportunity"] = "Opportunity",
	["Overpower"] = "Overpower",
	["Pacify"] = "Pacify",
	["Pain Suppression"] = "Pain Suppression",
	["Paralyzing Poison"] = "Paralyzing Poison",
	["Paranoia"] = "Paranoia",
	["Parasitic Serpent"] = "Parasitic Serpent",
	["Parry"] = "Parry",
	["Pathfinding"] = "Pathfinding",
	["Perception"] = "Perception",
	["Permafrost"] = "Permafrost",
	["Pet Aggression"] = "Pet Aggression",
	["Pet Hardiness"] = "Pet Hardiness",
	["Pet Recovery"] = "Pet Recovery",
	["Pet Resistance"] = "Pet Resistance",
	["Petrify"] = "Petrify",
	["Phase Shift"] = "Phase Shift",
	["Pick Lock"] = "Pick Lock",
	["Pick Pocket"] = "Pick Pocket",
	["Pierce Armor"] = "Pierce Armor",
	["Piercing Howl"] = "Piercing Howl",
	["Piercing Ice"] = "Piercing Ice",
	["Piercing Shadow"] = "Piercing Shadow",
	["Piercing Shot"] = "Piercing Shot",
	["Plague Cloud"] = "Plague Cloud",
	["Plate Mail"] = "Plate Mail",
	["Poison"] = "Poison",
	["Poison Bolt"] = "Poison Bolt",
	["Poison Bolt Volley"] = "Poison Bolt Volley",
	["Poison Cleansing Totem"] = "Poison Cleansing Totem",
	["Poison Cloud"] = "Poison Cloud",
	["Poison Shock"] = "Poison Shock",
	["Poisoned Harpoon"] = "Poisoned Harpoon",
	["Poisoned Shot"] = "Poisoned Shot",
	["Poisonous Blood"] = "Poisonous Blood",
	["Poisons"] = "Poisons",
	["Polearm Specialization"] = "Polearm Specialization",
	["Polearms"] = "Polearms",
	["Polymorph"] = "Polymorph",
	["Polymorph: Pig"] = "Polymorph: Pig",
	["Polymorph: Turtle"] = "Polymorph: Turtle",
	["Portal: Darnassus"] = "Portal: Darnassus",
	["Portal: Ironforge"] = "Portal: Ironforge",
	["Portal: Orgrimmar"] = "Portal: Orgrimmar",
	["Portal: Stormwind"] = "Portal: Stormwind",
	["Portal: Thunder Bluff"] = "Portal: Thunder Bluff",
	["Portal: Undercity"] = "Portal: Undercity",
	["Positive Charge"] = "Positive Charge",
	["Pounce"] = "Pounce",
	["Pounce Bleed"] = "Pounce Bleed",
	["Power Infusion"] = "Power Infusion",
	["Power Word: Fortitude"] = "Power Word: Fortitude",
	["Power Word: Shield"] = "Power Word: Shield",
	["Prayer Beads Blessing"] = "Prayer Beads Blessing",
	["Prayer of Fortitude"] = "Prayer of Fortitude",
	["Prayer of Healing"] = "Prayer of Healing",
	["Prayer of Mending"] = "Prayer of Mending",
	["Prayer of Shadow Protection"] = "Prayer of Shadow Protection",
	["Prayer of Spirit"] = "Prayer of Spirit",
	["Precision"] = "Precision",
	["Predatory Strikes"] = "Predatory Strikes",
	["Premeditation"] = "Premeditation",
	["Preparation"] = "Preparation",
	["Presence of Mind"] = "Presence of Mind",
	["Primal Fury"] = "Primal Fury",
	["Prowl"] = "Prowl",
	["Psychic Scream"] = "Psychic Scream",
	["Pummel"] = "Pummel",
	["Puncture"] = "Puncture",
	["Purge"] = "Purge",
	["Purification"] = "Purification",
	["Purify"] = "Purify",
	["Pursuit of Justice"] = "Pursuit of Justice",
	["Putrid Breath"] = "Putrid Breath",
	["Putrid Enzyme"] = "Putrid Enzyme",
	["Pyroblast"] = "Pyroblast",
	["Pyroclasm"] = "Pyroclasm",
	["Quick Shots"] = "Quick Shots",
	["Quickness"] = "Quickness",
	["Radiation"] = "Radiation",
	["Radiation Bolt"] = "Radiation Bolt",
	["Radiation Cloud"] = "Radiation Cloud",
	["Radiation Poisoning"] = "Radiation Poisoning",
	["Rain of Fire"] = "Rain of Fire",
	["Rake"] = "Rake",
	["Ram Riding"] = "Ram Riding",
	["Rampage"] = "Rampage",
	["Ranged Weapon Specialization"] = "Ranged Weapon Specialization",
	["Rapid Concealment"] = "Rapid Concealment",
	["Rapid Fire"] = "Rapid Fire",
	["Raptor Riding"] = "Raptor Riding",
	["Raptor Strike"] = "Raptor Strike",
	["Ravage"] = "Ravage",
	["Ravenous Claw"] = "Ravenous Claw",
	["Readiness"] = "Readiness",
	["Rebirth"] = "Rebirth",
	["Rebuild"] = "Rebuild",
	["Recently Bandaged"] = "Recently Bandaged",
	["Reckless Charge"] = "Reckless Charge",
	["Recklessness"] = "Recklessness",
	["Reckoning"] = "Reckoning",
	["Recombobulate"] = "Recombobulate",
	["Redemption"] = "Redemption",
	["Redoubt"] = "Redoubt",
	["Reflection"] = "Reflection",
	["Regeneration"] = "Regeneration",
	["Regrowth"] = "Regrowth",
	["Reincarnation"] = "Reincarnation",
	["Rejuvenation"] = "Rejuvenation",
	["Relentless Strikes"] = "Relentless Strikes",
	["Remorseless"] = "Remorseless",
	["Remorseless Attacks"] = "Remorseless Attacks",
	["Remove Curse"] = "Remove Curse",
	["Remove Insignia"] = "Remove Insignia",
	["Remove Lesser Curse"] = "Remove Lesser Curse",
	["Rend"] = "Rend",
	["Renew"] = "Renew",
	["Repentance"] = "Repentance",
	["Repulsive Gaze"] = "Repulsive Gaze",
	["Restorative Totems"] = "Restorative Totems",
	["Resurrection"] = "Resurrection",
	["Retaliation"] = "Retaliation",
	["Retribution Aura"] = "Retribution Aura",
	["Revenge"] = "Revenge",
	["Revenge Stun"] = "Revenge Stun",
	["Reverberation"] = "Reverberation",
	["Revive Pet"] = "Revive Pet",
	["Rhahk'Zor Slam"] = "Rhahk'Zor Slam",
	["Ribbon of Souls"] = "Ribbon of Souls",
	["Righteous Defense"] = "Righteous Defense",
	["Righteous Fury"] = "Righteous Fury",
	["Rip"] = "Rip",
	["Riposte"] = "Riposte",
	["Ritual of Doom"] = "Ritual of Doom",
	["Ritual of Doom Effect"] = "Ritual of Doom Effect",
	["Ritual of Souls"] = "Ritual of Souls",
	["Ritual of Summoning"] = "Ritual of Summoning",
	["Rockbiter Weapon"] = "Rockbiter Weapon",
	["Rogue Passive"] = "Rogue Passive",
	["Rough Sharpening Stone"] = "Rough Sharpening Stone",
	["Ruin"] = "Ruin",
	["Rupture"] = "Rupture",
	["Ruthlessness"] = "Ruthlessness",
	["Sacrifice"] = "Sacrifice",
	["Safe Fall"] = "Safe Fall",
	["Sanctity Aura"] = "Sanctity Aura",
	["Sap"] = "Sap",
	["Savage Fury"] = "Savage Fury",
	["Savage Strikes"] = "Savage Strikes",
	["Scare Beast"] = "Scare Beast",
	["Scatter Shot"] = "Scatter Shot",
	["Scorch"] = "Scorch",
	["Scorpid Poison"] = "Scorpid Poison",
	["Scorpid Sting"] = "Scorpid Sting",
	["Screams of the Past"] = "Screams of the Past",
	["Screech"] = "Screech",
	["Seal Fate"] = "Seal Fate",
	["Seal of Blood"] = "Seal of Blood",
	["Seal of Command"] = "Seal of Command",
	["Seal of Justice"] = "Seal of Justice",
	["Seal of Light"] = "Seal of Light",
	["Seal of Reckoning"] = "Seal of Reckoning",
	["Seal of Righteousness"] = "Seal of Righteousness",
	["Seal of the Crusader"] = "Seal of the Crusader",
	["Seal of Vengeance"] = "Seal of Vengeance",
	["Seal of Wisdom"] = "Seal of Wisdom",
	["Searing Light"] = "Searing Light",
	["Searing Pain"] = "Searing Pain",
	["Searing Totem"] = "Searing Totem",
	["Second Wind"] = "Second Wind",
	["Seduction"] = "Seduction",
	["Seed of Corruption"] = "Seed of Corruption",
	["Sense Demons"] = "Sense Demons",
	["Sense Undead"] = "Sense Undead",
	["Sentry Totem"] = "Sentry Totem",
	["Serpent Sting"] = "Serpent Sting",
	["Setup"] = "Setup",
	["Shackle Undead"] = "Shackle Undead",
	["Shadow Affinity"] = "Shadow Affinity",
	["Shadow Bolt"] = "Shadow Bolt",
	["Shadow Bolt Volley"] = "Shadow Bolt Volley",
	["Shadow Focus"] = "Shadow Focus",
	["Shadow Mastery"] = "Shadow Mastery",
	["Shadow Protection"] = "Shadow Protection",
	["Shadow Reach"] = "Shadow Reach",
	["Shadow Resistance"] = "Shadow Resistance",
	["Shadow Resistance Aura"] = "Shadow Resistance Aura",
	["Shadow Shock"] = "Shadow Shock",
	["Shadow Trance"] = "Shadow Trance",
	["Shadow Vulnerability"] = "Shadow Vulnerability",
	["Shadow Ward"] = "Shadow Ward",
	["Shadow Weakness"] = "Shadow Weakness",
	["Shadow Weaving"] = "Shadow Weaving",
	["Shadow Word: Death"] = "Shadow Word: Death",
	["Shadow Word: Pain"] = "Shadow Word: Pain",
	["Shadowburn"] = "Shadowburn",
	["Shadowfiend"] = "Shadowfiend",
	["Shadowform"] = "Shadowform",
	["Shadowfury"] = "Shadowfury",
	["Shadowguard"] = "Shadowguard",
	["Shadowmeld"] = "Shadowmeld",
	["Shadowmeld Passive"] = "Shadowmeld Passive",
	["Shadowstep"] = "Shadowstep",
	["Shamanistic Rage"] = "Shamanistic Rage",
	["Sharpened Claws"] = "Sharpened Claws",
	["Shatter"] = "Shatter",
	["Sheep"] = "Sheep",
	["Shell Shield"] = "Shell Shield",
	["Shield"] = "Shield",
	["Shield Bash"] = "Shield Bash",
	["Shield Bash - Silenced"] = "Shield Bash - Silenced",
	["Shield Block"] = "Shield Block",
	["Shield Slam"] = "Shield Slam",
	["Shield Specialization"] = "Shield Specialization",
	["Shield Wall"] = "Shield Wall",
	["Shiv"] = "Shiv",
	["Shock"] = "Shock",
	["Shoot"] = "Shoot",
	["Shoot Bow"] = "Shoot Bow",
	["Shoot Crossbow"] = "Shoot Crossbow",
	["Shoot Gun"] = "Shoot Gun",
	["Shred"] = "Shred",
	["Shrink"] = "Shrink",
	["Silence"] = "Silence",
	["Silencing Shot"] = "Silencing Shot",
	["Silent Resolve"] = "Silent Resolve",
	["Sinister Strike"] = "Sinister Strike",
	["Siphon Life"] = "Siphon Life",
	["Skinning"] = "Skinning",
	["Skull Crack"] = "Skull Crack",
	["Slam"] = "Slam",
	["Sleep"] = "Sleep",
	["Slice and Dice"] = "Slice and Dice",
	["Slow"] = "Slow",
	["Slow Fall"] = "Slow Fall",
	["Slowing Poison"] = "Slowing Poison",
	["Smelting"] = "Smelting",
	["Smite"] = "Smite",
	["Smite Slam"] = "Smite Slam",
	["Smite Stomp"] = "Smite Stomp",
	["Smoke Bomb"] = "Smoke Bomb",
	["Snake Trap"] = "Snake Trap",
	["Snap Kick"] = "Snap Kick",
	["Solid Sharpening Stone"] = "Solid Sharpening Stone",
	["Sonic Burst"] = "Sonic Burst",
	["Soothe Animal"] = "Soothe Animal",
	["Soothing Kiss"] = "Soothing Kiss",
	["Soul Bite"] = "Soul Bite",
	["Soul Drain"] = "Soul Drain",
	["Soul Fire"] = "Soul Fire",
	["Soul Link"] = "Soul Link",
	["Soul Siphon"] = "Soul Siphon",
	["Soul Tap"] = "Soul Tap",
	["Soulshatter"] = "Soulshatter",
	["Soulstone Resurrection"] = "Soulstone Resurrection",
	["Spell Lock"] = "Spell Lock",
	["Spell Reflection"] = "Spell Reflection",
	["Spell Warding"] = "Spell Warding",
	["Spellsteal"] = "Spellsteal",
	["Spirit Bond"] = "Spirit Bond",
	["Spirit Burst"] = "Spirit Burst",
	["Spirit of Redemption"] = "Spirit of Redemption",
	["Spirit Tap"] = "Spirit Tap",
	["Spiritual Attunement"] = "Spiritual Attunement",
	["Spiritual Focus"] = "Spiritual Focus",
	["Spiritual Guidance"] = "Spiritual Guidance",
	["Spiritual Healing"] = "Spiritual Healing",
	["Spit"] = "Spit",
	["Spore Cloud"] = "Spore Cloud",
	["Sprint"] = "Sprint",
	["Stance Mastery"] = "Stance Mastery",
	["Starfire"] = "Starfire",
	["Starfire Stun"] = "Starfire Stun",
	["Starshards"] = "Starshards",
	["Staves"] = "Staves",
	["Steady Shot"] = "Steady Shot",
	["Stealth"] = "Stealth",
	["Stoneclaw Totem"] = "Stoneclaw Totem",
	["Stoneform"] = "Stoneform",
	["Stoneskin Totem"] = "Stoneskin Totem",
	["Stormstrike"] = "Stormstrike",
	["Strength of Earth Totem"] = "Strength of Earth Totem",
	["Strike"] = "Strike",
	["Stuck"] = "Stuck",
	["Stun"] = "Stun",
	["Subtlety"] = "Subtlety",
	["Suffering"] = "Suffering",
	["Summon Charger"] = "Summon Charger",
	["Summon Dreadsteed"] = "Summon Dreadsteed",
	["Summon Felguard"] = "Summon Felguard",
	["Summon Felhunter"] = "Summon Felhunter",
	["Summon Felsteed"] = "Summon Felsteed",
	["Summon Imp"] = "Summon Imp",
	["Summon Spawn of Bael'Gar"] = "Summon Spawn of Bael'Gar",
	["Summon Succubus"] = "Summon Succubus",
	["Summon Voidwalker"] = "Summon Voidwalker",
	["Summon Warhorse"] = "Summon Warhorse",
	["Summon Water Elemental"] = "Summon Water Elemental",
	["Sunder Armor"] = "Sunder Armor",
	["Suppression"] = "Suppression",
	["Surefooted"] = "Surefooted",
	["Survivalist"] = "Survivalist",
	["Sweeping Slam"] = "Sweeping Slam",
	["Sweeping Strikes"] = "Sweeping Strikes",
	["Swiftmend"] = "Swiftmend",
	["Swipe"] = "Swipe",
	["Swoop"] = "Swoop",
	["Sword Specialization"] = "Sword Specialization",
	["Tactical Mastery"] = "Tactical Mastery",
	["Tailoring"] = "Tailoring",
	["Tainted Blood"] = "Tainted Blood",
	["Tame Beast"] = "Tame Beast",
	["Tamed Pet Passive"] = "Tamed Pet Passive",
	["Taunt"] = "Taunt",
	["Teleport: Darnassus"] = "Teleport: Darnassus",
	["Teleport: Ironforge"] = "Teleport: Ironforge",
	["Teleport: Moonglade"] = "Teleport: Moonglade",
	["Teleport: Orgrimmar"] = "Teleport: Orgrimmar",
	["Teleport: Stormwind"] = "Teleport: Stormwind",
	["Teleport: Thunder Bluff"] = "Teleport: Thunder Bluff",
	["Teleport: Undercity"] = "Teleport: Undercity",
	["Tendon Rip"] = "Tendon Rip",
	["Tendon Slice"] = "Tendon Slice",
	["Terrify"] = "Terrify",
	["Terrifying Screech"] = "Terrifying Screech",
	["Thick Hide"] = "Thick Hide",
	["Thorn Volley"] = "Thorn Volley",
	["Thorns"] = "Thorns",
	["Thousand Blades"] = "Thousand Blades",
	["Threatening Gaze"] = "Threatening Gaze",
	["Throw"] = "Throw",
	["Throw Axe"] = "Throw Axe",
	["Throw Dynamite"] = "Throw Dynamite",
	["Throw Liquid Fire"] = "Throw Liquid Fire",
	["Throw Wrench"] = "Throw Wrench",
	["Throwing Specialization"] = "Throwing Specialization",
	["Throwing Weapon Specialization"] = "Throwing Weapon Specialization",
	["Thrown"] = "Thrown",
	["Thunder Clap"] = "Thunder Clap",
	["Thunderclap"] = "Thunderclap",
	["Thunderfury"] = "Thunderfury",
	["Thundering Strikes"] = "Thundering Strikes",
	["Thundershock"] = "Thundershock",
	["Thunderstomp"] = "Thunderstomp",
	["Tidal Focus"] = "Tidal Focus",
	["Tidal Mastery"] = "Tidal Mastery",
	["Tiger Riding"] = "Tiger Riding",
	["Tiger's Fury"] = "Tiger's Fury",
	["Torment"] = "Torment",
	["Totem"] = "Totem",
	["Totem of Wrath"] = "Totem of Wrath",
	["Totemic Focus"] = "Totemic Focus",
	["Touch of Weakness"] = "Touch of Weakness",
	["Toughness"] = "Toughness",
	["Toxic Saliva"] = "Toxic Saliva",
	["Toxic Spit"] = "Toxic Spit",
	["Toxic Volley"] = "Toxic Volley",
	["Traces of Silithyst"] = "Traces of Silithyst",
	["Track Beasts"] = "Track Beasts",
	["Track Demons"] = "Track Demons",
	["Track Dragonkin"] = "Track Dragonkin",
	["Track Elementals"] = "Track Elementals",
	["Track Giants"] = "Track Giants",
	["Track Hidden"] = "Track Hidden",
	["Track Humanoids"] = "Track Humanoids",
	["Track Undead"] = "Track Undead",
	["Trample"] = "Trample",
	["Tranquil Air Totem"] = "Tranquil Air Totem",
	["Tranquil Spirit"] = "Tranquil Spirit",
	["Tranquility"] = "Tranquility",
	["Tranquilizing Poison"] = "Tranquilizing Poison",
	["Tranquilizing Shot"] = "Tranquilizing Shot",
	["Trap Mastery"] = "Trap Mastery",
	["Travel Form"] = "Travel Form",
	["Tree of Life"] = "Tree of Life",
	["Tremor Totem"] = "Tremor Totem",
	["Tribal Leatherworking"] = "Tribal Leatherworking",
	["Trueshot Aura"] = "Trueshot Aura",
	["Turn Undead"] = "Turn Undead",
	["Twisted Tranquility"] = "Twisted Tranquility",
	["Two-Handed Axes"] = "Two-Handed Axes",
	["Two-Handed Axes and Maces"] = "Two-Handed Axes and Maces",
	["Two-Handed Maces"] = "Two-Handed Maces",
	["Two-Handed Swords"] = "Two-Handed Swords",
	["Two-Handed Weapon Specialization"] = "Two-Handed Weapon Specialization",
	["Unarmed"] = "Unarmed",
	["Unbreakable Will"] = "Unbreakable Will",
	["Unbridled Wrath"] = "Unbridled Wrath",
	["Unbridled Wrath Effect"] = "Unbridled Wrath Effect",
	["Undead Horsemanship"] = "Undead Horsemanship",
	["Underwater Breathing"] = "Underwater Breathing",
	["Unending Breath"] = "Unending Breath",
	["Unholy Frenzy"] = "Unholy Frenzy",
	["Unholy Power"] = "Unholy Power",
	["Unleashed Fury"] = "Unleashed Fury",
	["Unleashed Rage"] = "Unleashed Rage",
	["Unstable Affliction"] = "Unstable Affliction",
	["Unstable Concoction"] = "Unstable Concoction",
	["Unstable Power"] = "Unstable Power",
	["Unyielding Faith"] = "Unyielding Faith",
	["Uppercut"] = "Uppercut",
	["Vampiric Embrace"] = "Vampiric Embrace",
	["Vampiric Touch"] = "Vampiric Touch",
	["Vanish"] = "Vanish",
	["Vanished"] = "Vanished",
	["Veil of Shadow"] = "Veil of Shadow",
	["Vengeance"] = "Vengeance",
	["Venom Spit"] = "Venom Spit",
	["Venom Sting"] = "Venom Sting",
	["Venomhide Poison"] = "Venomhide Poison",
	["Vicious Rend"] = "Vicious Rend",
	["Victory Rush"] = "Victory Rush",
	["Vigor"] = "Vigor",
	["Vile Poisons"] = "Vile Poisons",
	["Vindication"] = "Vindication",
	["Viper Sting"] = "Viper Sting",
	["Virulent Poison"] = "Virulent Poison",
	["Void Bolt"] = "Void Bolt",
	["Volley"] = "Volley",
	["Walking Bomb Effect"] = "Walking Bomb Effect",
	["Wand Specialization"] = "Wand Specialization",
	["Wandering Plague"] = "Wandering Plague",
	["Wands"] = "Wands",
	["War Stomp"] = "War Stomp",
	["Water"] = "Water",
	["Water Breathing"] = "Water Breathing",
	["Water Shield"] = "Water Shield",
	["Water Walking"] = "Water Walking",
	["Waterbolt"] = "Waterbolt",
	["Wavering Will"] = "Wavering Will",
	["Weakened Soul"] = "Weakened Soul",
	["Weaponsmith"] = "Weaponsmith",
	["Web"] = "Web",
	["Web Explosion"] = "Web Explosion",
	["Web Spin"] = "Web Spin",
	["Web Spray"] = "Web Spray",
	["Whirling Barrage"] = "Whirling Barrage",
	["Whirling Trip"] = "Whirling Trip",
	["Whirlwind"] = "Whirlwind",
	["Wide Slash"] = "Wide Slash",
	["Will of Hakkar"] = "Will of Hakkar",
	["Will of the Forsaken"] = "Will of the Forsaken",
	["Windfury Totem"] = "Windfury Totem",
	["Windfury Weapon"] = "Windfury Weapon",
	["Windsor's Frenzy"] = "Windsor's Frenzy",
	["Windwall Totem"] = "Windwall Totem",
	["Wing Clip"] = "Wing Clip",
	["Wing Flap"] = "Wing Flap",
	["Winter's Chill"] = "Winter's Chill",
	["Wisp Spirit"] = "Wisp Spirit",
	["Wolf Riding"] = "Wolf Riding",
	["Wound Poison"] = "Wound Poison",
	["Wound Poison II"] = "Wound Poison II",
	["Wound Poison III"] = "Wound Poison III",
	["Wound Poison IV"] = "Wound Poison IV",
	["Wrath"] = "Wrath",
	["Wrath of Air Totem"] = "Wrath of Air Totem",
	["Wyvern Sting"] = "Wyvern Sting",
}

end)
return __bundle_require("__root")