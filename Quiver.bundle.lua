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
local RegisterMacroFunctions = require("MacroFunctions.lua")

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
		local frameConfigMenu = MainMenu.Create()
		SlashCmdList["QUIVER"] = function(_args, _box) frameConfigMenu:Show() end
		for _k, v in _G.Quiver_Modules do
			if Quiver_Store.ModuleEnabled[v.Id] then v.OnEnable() end
		end
		frameConfigMenu:Show()-- TODO temp code for faster debugging
	else
		SlashCmdList["QUIVER"] = function() DEFAULT_CHAT_FRAME:AddMessage(Quiver.T["Quiver is for hunters."], 1, 0.5, 0) end
	end
end

--[[
// TODO revisit this now that we don't load any pfUI plugins
https://wowpedia.fandom.com/wiki/AddOn_loading_process
All of these events fire on login and UI reload. We don't need to clutter chat
until the user interacts with Quiver, and we don't pre-cache action bars. That
means it's okay to load before other addons (action bars, chat windows).
pfUI loads before we register plugins for it. Quiver comes alphabetically later,
but it's safer to use a later event in case names change.

ADDON_LOADED Fires each time any addon loads, but can't yet print to pfUI's chat menu
PLAYER_LOGIN Fires once, but can't yet read talent tree
PLAYER_ENTERING_WORLD fires on every load screen
SPELLS_CHANGED fires every time the spellbook changes
]]
local frame = CreateFrame("Frame", nil)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" and arg1 == "Quiver" then
		-- TODO set preferred language in saved variables to use here
		LoadLocale()-- Must run before everything else
		Migrations()-- Modifies saved variables
		savedVariablesRestore()-- Passes saved data to modules for init
		initSlashCommandsAndModules()
		RegisterMacroFunctions()
	elseif event == "PLAYER_LOGIN" then
		UpdateNotifierInit()
	elseif event == "PLAYER_LOGOUT" then
		savedVariablesPersist()
	end
end)

end)
__bundle_register("MacroFunctions.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local AutoShotTimer = require("Modules/Auto_Shot_Timer/AutoShotTimer.lua")
local Pet = require("Shiver/API/Pet.lua")

---@param spellName string
---@return nil
local CastNoClip = function(spellName)
	if not AutoShotTimer.PredMidShot() then
		CastSpellByName(spellName)
	end
end

---@param actionName string
---@return nil
local CastPetAction = function(actionName)
	-- local hasSpells = HasPetUI()
	-- local hasUI = HasPetUI()
	if GetPetActionsUsable() then
		Pet.CastActionByName(actionName)
	end
end

return function()
	Quiver.CastNoClip = CastNoClip
	Quiver.CastPetAction = CastPetAction
	Quiver.PredMidShot = AutoShotTimer.PredMidShot
end

end)
__bundle_register("Shiver/API/Pet.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
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
__bundle_register("Modules/Auto_Shot_Timer/AutoShotTimer.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local FrameLock = require("Events/FrameLock.lua")
local Spellcast = require("Events/Spellcast.lua")
local Spell = require("Shiver/API/Spell.lua")
local Haste = require("Shiver/Haste.lua")

local MODULE_ID = "AutoShotTimer"
local store = nil---@type StoreAutoShotTimer
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
	for _k, v in Quiver.L.CombatLog.Consumes do
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
	FrameLock.SideEffectRestoreSize(s, {
		w=240, h=14, dx=240 * -0.5, dy=-136,
	})

	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)

	setBarAutoShot(f)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("HIGH")
	f.BarAutoShot = CreateFrame("Frame", nil, f)

	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/BUTTONS/WHITE8X8",
		edgeSize = BORDER,
		tile = false,
	})
	f.BarAutoShot:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		tile = false,
	})
	f:SetBackdropColor(0, 0, 0, 0.8)
	f:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)

	setFramePosition(f, store)
	local resizeBarAutoShot = function() setBarAutoShot(f) end

	FrameLock.SideEffectMakeMoveable(f, store)
	FrameLock.SideEffectMakeResizeable(f, store, {
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
	timeStartReloading = time
	isReloading = true
	reloadTime = UnitRangedDamage("player") - AIMING_TIME
	log("starting reload")
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
--- @type Event[]
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

---@param spellName string
local onSpellcast = function(spellName)
	-- User can spam the ability while it's already casting
	if isCasting then return end
	isCasting = true
	local _latAdjusted
	castTime, _latAdjusted, timeStartCastLocal = Haste.CalcCastTime(spellName)
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
---@return boolean
---@nodiscard
local PredMidShot = function()
	return isShooting and not isReloading
end

-- ************ Initialization ************
local onEnable = function()
	if frame == nil then
		frame = createUI()
	end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	if Quiver_Store.IsLockedFrames then frame:SetAlpha(0) else frame:SetAlpha(1) end
	Spellcast.CastableShot.Subscribe(MODULE_ID, onSpellcast)
	Spellcast.Instant.Subscribe(MODULE_ID, function(spellName)
		isFiredInstant = Spell.PredInstantShotByName(spellName)
	end)
	frame:Show()
end

local onDisable = function()
	Spellcast.Instant.Dispose(MODULE_ID)
	Spellcast.CastableShot.Dispose(MODULE_ID)
	if frame ~= nil then
		frame:Hide()
		for _k, e in EVENTS do frame:UnregisterEvent(e) end
	end
end

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
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.BarDirection = savedVariables.BarDirection or "LeftToRight"
		store.ColorShoot = savedVariables.ColorShoot or QUIVER.ColorDefault.AutoShotShoot
		store.ColorReload = savedVariables.ColorReload or QUIVER.ColorDefault.AutoShotReload
	end,
	OnSavedVariablesPersist = function() return store end,
	PredMidShot = PredMidShot,
	UpdateDirection = function()
		if frame then setBarAutoShot(frame) end
	end
}

end)
__bundle_register("Shiver/Haste.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local DB_SPELL = require("Shiver/Data/Spell.lua")
local ScanningTooltip = require("Shiver/ScanningTooltip.lua")
local Enum = require("Shiver/Enum.lua")

-- GetInventoryItemLink("Player", slot#) returns a link, ex. [name]
-- Weapon name always appears at line TextLeft1
-- TODo Might be cachable. Experiment which events would clear cache.
local calcRangedWeaponSpeedBase = function()
	return ScanningTooltip.Scan(function(tooltip)
		tooltip:ClearLines()
		local _RANGED = Enum.INVENTORY_SLOT.Ranged
		local _, _, _ = tooltip:SetInventoryItem("player", _RANGED)

		for i=1, tooltip:NumLines() do
			local text = ScanningTooltip.GetText("TextRight", i)
			if text ~= nil then
				-- ex. "Speed 3.2"
				-- Not matching on the text part since that requires localization
				local _, _, speed = string.find(text, "(%d+%.%d+)")
				if speed ~= nil then
					local parsed = tonumber(speed)
					if parsed ~= nil then
						tooltip:Hide()
						return parsed
					end
				end
			end
		end

		-- Something went wrong. Maybe there's no ranged weapon equipped.
		return nil
	end)
end

---@param name string
---@return number casttime
---@return number startLatAdjusted
---@return number startLocal
---@nodiscard
local CalcCastTime = function(name)
	local meta = DB_SPELL[name]
	local baseTime = meta and meta.Time or 0
	local offset = meta and meta.Offset or 0

	local _,_, msLatency = GetNetStats()
	local startLocal = GetTime()
	local startLatAdjusted = startLocal + msLatency / 1000

	if meta.Haste == "range" then
		local speedCurrent, _, _ , _, _, _ = UnitRangedDamage("player")
		local speedBaseNil = calcRangedWeaponSpeedBase()
		local speedBase = speedBaseNil and speedBaseNil or speedCurrent
		local speedMultiplier = speedCurrent / speedBase
		-- https://www.mmo-champion.com/content/2188-Patch-4-0-6-Feb-22-Hotfixes-Blue-Posts-Artworks-Comic
		local casttime = (offset + baseTime * speedMultiplier) / 1000
		return casttime, startLatAdjusted, startLocal
	end

	-- LuaLS doesn't support exhaustive checks? TODO investigate
	local timeFallback = (meta.Time + meta.Offset) / 1000
	return timeFallback, startLatAdjusted, startLocal
end

return {
	CalcCastTime = CalcCastTime,
}

end)
__bundle_register("Shiver/Enum.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
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
__bundle_register("Shiver/ScanningTooltip.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
--- Creates a scanning tooltip for later use
---@param name string Name of global tooltip frame
---@return GameTooltip
---@nodiscard
local createTooltip = function(name)
	local tt = CreateFrame("GameTooltip", name, nil, "GameTooltipTemplate")
	tt:SetScript("OnHide", function() tt:SetOwner(WorldFrame, "Center") end)
	tt:Hide()
	tt:SetFrameStrata("TOOLTIP")
	return tt
end

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
	tooltip:SetOwner(WorldFrame, "Center")
	local output = f(tooltip)
	tooltip:Hide()
	return output
end

return {
	GetText = GetText,
	Scan = Scan,
}

end)
__bundle_register("Shiver/Data/Spell.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
-- Data is fully denormalized since we don't have a database.
-- This will probably cause maintenance problems.
return {
	-- Casted Shots
	["Aimed Shot"]={ Class="hunter", Time=3000, Offset=500, Haste="range", Icon="INV_Spear_07", IsAmmo=true },
	["Multi-Shot"]={ Class="hunter", Time=0, Offset=500, Haste="range", Icon="Ability_UpgradeMoonGlaive", IsAmmo=true },
	["Trueshot"]={ Class="hunter", Time=1000, Offset=500, Haste="range", Icon="Ability_TrueShot", IsAmmo=true },

	-- Instant Shots
	["Arcane Shot"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Ability_ImpalingBolt", IsAmmo=true },
	["Concussive Shot"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Spell_Frost_Stun", IsAmmo=true },
	["Scatter Shot"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Ability_GolemStormBolt", IsAmmo=true },
	["Scorpid Sting"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Ability_Hunter_CriticalShot", IsAmmo=true },
	["Serpent Sting"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Ability_Hunter_Quickshot", IsAmmo=true },
	["Viper Sting"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Ability_Hunter_AimedShot", IsAmmo=true },
	["Wyvern Sting"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="INV_Spear_02", IsAmmo=true },
}

end)
__bundle_register("Shiver/API/Spell.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local DB_SPELL = require("Shiver/Data/Spell.lua")

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

--- Returns true if spell is instant cast
--- If meta is nil, we can't run cast time code, so assume instant.
---@param meta nil|{ Time: number; Offset: number }
---@return boolean
---@nodiscard
local PredInstant = function(meta)
	if meta == nil then
		return true
	else
		return 0 == meta.Time + meta.Offset
	end
end

---@param name string
---@return boolean
---@nodiscard
local PredInstantShotByName = function(name)
	local meta = DB_SPELL[name]
	return meta ~= nil and meta.IsAmmo and (meta.Offset + meta.Time == 0)
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
	local spellId = FindSpellIndex(spellName)
	if spellId ~= nil then
		local timeStartCD, durationCD = GetSpellCooldown(spellId, BOOKTYPE_SPELL)
		-- Sometimes spells return a CD of 0 when cast fails.
		-- If it's non-zero, we have a valid timeStart to check.
		if durationCD == cooldown and timeStartCD ~= lastCdStart then
			return true, timeStartCD
		end
	end
	return false, lastCdStart
end

local CheckNewGCD = function(lastCdStart)
	return CheckNewCd(1.5, lastCdStart, Quiver.L.Spellbook["Serpent Sting"])
end

return {
	CheckNewCd=CheckNewCd,
	CheckNewGCD=CheckNewGCD,
	FindSpellByTexture = FindSpellByTexture,
	FindSpellIndex = FindSpellIndex,
	PredInstant = PredInstant,
	PredInstantShotByName = PredInstantShotByName,
	PredSpellLearned = PredSpellLearned,
}

end)
__bundle_register("Events/Spellcast.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Action = require("Shiver/API/Action.lua")
local Spell = require("Shiver/API/Spell.lua")
local DB_SPELL = require("Shiver/Data/Spell.lua")
local Print = require("Util/Print.lua")

local log = function(text)
	if Quiver_Store.DebugLevel == "Verbose" then
		DEFAULT_CHAT_FRAME:AddMessage(text)
	end
end

-- Hooks get called even if spell didn't fire, but successful cast triggers GCD.
local lastGcdStart = 0
local checkGCD = function()
	local isTriggeredGcd, newStart = Spell.CheckNewGCD(lastGcdStart)
	lastGcdStart = newStart
	return isTriggeredGcd
end

-- Castable shot event has 2 triggers:
-- 1. User starts casting Aimed Shot, Multi-Shot, or Trueshot
-- 2. User is already casting, but presses the spell again
-- It's up to the subscriber to differentiate.
local callbacksCastableShot = {}
local publishShotCastable = function(spellname)
	for _i, v in callbacksCastableShot do v(spellname) end
end
local CastableShot = {
	Subscribe = function(moduleId, callback)
		callbacksCastableShot[moduleId] = callback
	end,
	Dispose = function(moduleId)
		callbacksCastableShot[moduleId] = nil
	end,
}

local callbacksInstant = {}
local publishInstant = function(spellname)
	for _i, v in callbacksInstant do v(spellname) end
end
local Instant = {
	---@param moduleId string
	---@param callback fun(n: string): nil
	Subscribe = function(moduleId, callback)
		callbacksInstant[moduleId] = callback
	end,
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

-- TODO This is ϴ(n). Maybe we should build a reverse-map table instead?
-- The spell table is small, so with cache hits this loop might actually be faster.
local findSpellId = function(nameLocalized)
	-- Short circuit for performance. I didn't check if it actually helps.
	if GetLocale() == "enUS" then return nameLocalized end

	for k,v in Quiver.L.Spellbook do
		if v == nameLocalized then
			return k
		end
	end
	return nil
end

---@param nameLocalized string
---@param isCurrentAction nil|1
local handleCastByName = function(nameLocalized, isCurrentAction)
	local name = findSpellId(nameLocalized)
	if name == nil then
		log("Localized spellname not found: "..nameLocalized)
	else
		local meta = DB_SPELL[name]
		local isCastable = not Spell.PredInstant(meta)

		-- We pre-hook the cast, so confirm we actually cast it before triggering callbacks.
		-- If it's castable, then check we're casting it, else check that we triggered GCD.
		if isCastable then
			if isCurrentAction then
				publishShotCastable(name)
			elseif Action.FindBySpellName(name) == nil then
				println.Warning(name .. " not on action bars, so can't track cast.")
			end
		elseif checkGCD() then
			publishInstant(name)
		end
	end
end

---@param spellIndex number
---@param bookType BookType
---@return nil
CastSpell = function(spellIndex, bookType)
	super.CastSpell(spellIndex, bookType)
	local name, _rank = GetSpellName(spellIndex, bookType)
	if name ~= nil then
		log("Cast as spell... " .. name)
		handleCastByName(name, Action.PredSomeActionBusy())
	end
end

-- Some spells trigger this one time when spamming, others multiple
---@param name string
---@param isSelf? boolean
---@return nil
CastSpellByName = function(name, isSelf)
	super.CastSpellByName(name, isSelf)
	log("Cast by name... " .. name)
	handleCastByName(name, Action.PredSomeActionBusy())
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
		local name, index = Spell.FindSpellByTexture(texturePath)
		if name ~= nil and index ~= nil then
			log("Cast as Action... " .. name)
			handleCastByName(name, IsCurrentAction(slot))
		else
			log("Skip Action... ")
		end
	end
end

return {
	CastableShot = CastableShot,
	Instant = Instant,
}

end)
__bundle_register("Util/Print.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local danger = function(text) DEFAULT_CHAT_FRAME:AddMessage(text, 1, 0, 0) end
local neutral = function(text) DEFAULT_CHAT_FRAME:AddMessage(text) end
local success = function(text) DEFAULT_CHAT_FRAME:AddMessage(text, 0, 1, 0) end
local warning = function(text) DEFAULT_CHAT_FRAME:AddMessage(text, 1, 0.6, 0) end

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
	Line = PrintLine,
	PrefixedF = PrintPrefixedF,
}

end)
__bundle_register("Shiver/API/Action.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Spell = require("Shiver/API/Spell.lua")

---@param name string
---@return nil|ActionBarSlot
---@nodiscard
local FindBySpellName = function(name)
	local index = Spell.FindSpellIndex(name)
	if index ~= nil then
		local texture = GetSpellTexture(index, BOOKTYPE_SPELL)
		for i=0,120 do
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
	for i=1,120 do
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
__bundle_register("Events/FrameLock.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Button = require("Component/Button.lua")

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
		store.FrameMeta.X = math.floor(x)
		store.FrameMeta.Y = math.floor(y)
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
			local delta = frame:GetWidth() - wOld
			store.FrameMeta.W = wOld + 2 * delta
			store.FrameMeta.X = store.FrameMeta.X - delta
			frame:SetWidth(store.FrameMeta.W)
			frame:SetPoint("TopLeft", store.FrameMeta.X, store.FrameMeta.Y)
			if onResizeDrag ~= nil then onResizeDrag() end
		end)
	elseif onResizeDrag ~= nil then
		frame:SetScript("OnSizeChanged", onResizeDrag)
	end

	local handle = Button:Create(frame, QUIVER.Icon.GripHandle, nil, 0.5)
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
local Util = require("Component/_Util.lua")
local L = require("Shiver/Lib/All.lua")
local Sugar = require("Shiver/Sugar.lua")

local _GAP = 6
local _SIZE = 16

-- see [CheckButton](lua://QqCheckButton)
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
		h = L.Psi(L.Max, Sugar.Region._GetHeight, r.Icon, r.Label)
		w = L.Psi(L.Add, Sugar.Region._GetWidth, r.Icon, r.Label) + _GAP
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
__bundle_register("Shiver/Sugar.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Region = {
	--- @type fun(r: Region): number
	_GetHeight = function(r) return r:GetHeight() end,

	--- @type fun(r: Region): number
	_GetWidth = function(r) return r:GetWidth() end,
}

return {
	Region = Region,
}

end)
__bundle_register("Shiver/Lib/All.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
-- Reference library:
-- https://github.com/codereport/blackbird/blob/main/combinators.hpp
local Array = require("Shiver/Lib/Array.lua")
local Op = require("Shiver/Lib/Operator.lua")

-- ************ Combinators ************
--- (>>), forward function composition
---@generic A
---@generic B
---@generic C
---@param f fun(a: A): B
---@param g fun(y: B): C
---@return fun(x: A): C
local Forward = function(f, g)
	return function(a)
		return g(f(a))
	end
end

-- No support yet for generic overloads
-- https://github.com/LuaLS/lua-language-server/issues/723
---@generic A
---@generic B
---@generic C
--@generic D
--@generic E
---@type fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C)): C
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): D
--@overload fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D), i: (fun(d: D): E)): D
local Pipe = function(a, ...)
	local out = a
	for _, fn in ipairs(arg) do
		out = fn(out)
	end
	return out
end

-- No support yet for generic overloads
-- https://github.com/LuaLS/lua-language-server/issues/723
---@generic A
---@generic B
---@generic C
---@generic D
---@type fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D)): D
local Pipe3 = Pipe

-- No support yet for generic overloads
-- https://github.com/LuaLS/lua-language-server/issues/723
---@generic A
---@generic B
---@generic C
---@generic D
---@generic E
---@type fun(a: A, f: (fun(a: A): B), g: (fun(b: B): C), h: (fun(c: C): D), i: (fun(d: D): E)): D
local Pipe4 = Pipe

--- f(g(x), (y))
---@generic A
---@generic B
---@generic C
---@type fun(f: (fun(x: B, y: B): C), g: (fun(x: A): B), x: A, y: A): C
local Psi = function(f, g, x, y)
	return f(g(x), g(y))
end

return {
	Array = Array,
	-- Combinators
	Fw = Forward,
	Pipe = Pipe,
	Pipe3 = Pipe3,
	Pipe4 = Pipe4,
	Psi = Psi,
	-- Binary / Unary
	Add = Op.Add,
	Max = Op.Max,
	-- Comparison
	Lt = Op.Lt,
	Le = Op.Le,
	Eq = Op.Eq,
	Ne = Op.Ne,
	Ge = Op.Ge,
	Gt = Op.Gt,
	-- Logic
	And = Op.And,
	Or = Op.Or,
}

end)
__bundle_register("Shiver/Lib/Operator.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
	-- ************ Binary / Unary ************
	---@type fun(a: number, b: number): number
	Add = function(a, b) return a + b end,

	---@type fun(a: number, b: number): number
	Max = function(a, b) return math.max(a, b) end,

	-- ************ Comparison ************
	---@generic A
	---@type fun(a: A, b: A): boolean
	Lt = function(a, b) return a < b end,
	---@generic A
	---@type fun(a: A, b: A): boolean
	Le = function(a, b) return a <= b end,
	---@generic A
	---@type fun(a: A, b: A): boolean
	Eq = function(a, b) return a == b end,
	---@generic A
	---@type fun(a: A, b: A): boolean
	Ne = function(a, b) return a ~= b end,
	---@generic A
	---@type fun(a: A, b: A): boolean
	Ge = function(a, b) return a >= b end,
	---@generic A
	---@type fun(a: A, b: A): boolean
	Gt = function(a, b) return a > b end,

	-- ************ Logic ************
	---@type fun(a: boolean, b: boolean): boolean
	And = function(a, b) return a and b end,

	---@type fun(a: boolean, b: boolean): boolean
	Or = function(a, b) return a or b end,
}

end)
__bundle_register("Shiver/Lib/Array.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return boolean
local Every = function(xs, f)
	for _k, v in ipairs(xs) do
		if not f(v) then return false end
	end
	return true
end

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return nil|A
local Find = function(xs, f)
	for _k, v in ipairs(xs) do
		if f(v) then
			return v
		end
	end
	return nil
end

---ϴ(N)
---@generic A
---@param xs A[]
---@return integer
local Length = function(xs)
	local l = 0
	for _k, _v in ipairs(xs) do l = l + 1 end
	return l
end

---@generic A
---@generic B
---@param xs A[]
---@param f fun(x: A): B
---@return B[]
local Map = function(xs, f)
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
local Mapi = function(xs, f)
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
local MapReduce = function(xs, f, reducer, identity)
	local zRef = identity
	for _k, x in ipairs(xs) do
		zRef = reducer(f(x), zRef)
	end
	return zRef
end

---@generic A
---@param xs A[]
---@param f fun(x: A): boolean
---@return boolean
local Some = function(xs, f)
	for _k, v in ipairs(xs) do
		if f(v) then return true end
	end
	return false
end

---@param xs number[]
---@return number
local Sum = function(xs)
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
local Reduce = function(xs, reducer, identity)
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
local Zip2 = function(as, bs)
	local zipped = {}
	local l1, l2 = Length(as), Length(bs)
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

return {
	Every=Every,
	Find=Find,
	Length=Length,
	Map=Map,
	Mapi=Mapi,
	MapReduce=MapReduce,
	Some=Some,
	Sum=Sum,
	Reduce=Reduce,
	Zip2=Zip2,
}

end)
__bundle_register("Component/_Util.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Color = require("Shiver/Color.lua")
local Widget = require("Shiver/Widget.lua")

---@class IMouseInteract
---@field isEnabled boolean
---@field isHover boolean
---@field isMouseDown boolean

local _COLOR_NORMAL = Color:Lift({ 1.0, 0.82, 0.0 })
local _COLOR_HOVER = Color:Lift({ 1.0, 0.6, 0.0 })
local _COLOR_MOUSEDOWN = Color:Lift({ 1.0, 0.3, 0.0 })
local _COLOR_DISABLE = Color:Lift({ 0.3, 0.3, 0.3 })

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
			Widget.PositionTooltip(frame)
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
__bundle_register("Shiver/Widget.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
---@param anchor Frame
---@return FrameAnchor
---@nodiscard
local calcBestAnchorSide = function(anchor)
	local screenW = GetScreenWidth()
	local center = screenW / 2.0

	-- TODO library coalesce
	local leftNil = anchor:GetLeft()
	local rightNil = anchor:GetRight()
	local left = leftNil and leftNil or 0
	local right = rightNil and rightNil or screenW

	-- TODO library psi combinator
	local dLeft = math.abs(center - left)
	local dRight = math.abs(center - right)
	return dLeft < dRight and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_BOTTOMLEFT"
end

-- TODO figure out how to let caller specify preferred side, then
-- flip if there isn't enough room for tooltip. This is hard because
-- we don't know how big the tooltip is until after rendering it.
---@param anchor Frame
---@param x? number
---@param y? number
---@return nil
local PositionTooltip = function(anchor, x, y)
	local anchorSide = calcBestAnchorSide(anchor)
	-- TODO library coalesce
	local xx = (x and x or 0)
	local yy = (y and y or 0) + anchor:GetHeight()
	GameTooltip:SetOwner(anchor, anchorSide, xx, yy)
end

return {
	PositionTooltip = PositionTooltip,
}

end)
__bundle_register("Shiver/Color.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
---@alias Rgb [number, number, number]

---@class Color
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
local EVENTS = {
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
	for _k, e in EVENTS do frame:RegisterEvent(e) end
end

end)
__bundle_register("Util/Version.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
---@class Version
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
local FrameLock = require("Events/FrameLock.lua")
local Spellcast = require("Events/Spellcast.lua")
local Spell = require("Shiver/API/Spell.lua")
local Aura = require("Util/Aura.lua")

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
			knowsAura = Spell.PredSpellLearned(Quiver.L.Spellbook["Trueshot Aura"])
				or not Quiver_Store.IsLockedFrames
			isActive, timeLeft = Aura.GetIsActiveAndTimeLeftByTexture(QUIVER.Icon.Trueshot)
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
	f.Icon:SetBackdrop({ bgFile = QUIVER.Icon.Trueshot, tile = false })
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
local EVENTS = {
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
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	frame:Show()
	aura.UpdateUI()
	Spellcast.Instant.Subscribe(MODULE_ID, function(spellName)
		if spellName == Quiver.L.Spellbook["Trueshot Aura"] then
			-- Buffs don't update right away, but we want fast user feedback
			updateDelay = UPDATE_DELAY_FAST
		end
	end)
end
local onDisable = function()
	Spellcast.Instant.Dispose(MODULE_ID)
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

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
__bundle_register("Util/Aura.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local ScanningTooltip = require("Shiver/ScanningTooltip.lua")

-- This doesn't work for duplicate textures (ex. cheetah + zg mount).
-- For those you have to scan by name using the GameTooltip.
local GetIsActiveAndTimeLeftByTexture = function(targetTexture)
	-- This seems to check debuffs as well (tested with deserter)
	local maxIndex = QUIVER.Aura_Cap - 1
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
	return ScanningTooltip.Scan(function(tooltip)
		for i=0, QUIVER.Buff_Cap do
			local buffIndex, _untilCancelled = GetPlayerBuff(i, "HELPFUL|PASSIVE")
			if buffIndex >= 0 then
				tooltip:ClearLines()
				tooltip:SetPlayerBuff(buffIndex)
				if ScanningTooltip.GetText("TextLeft", 1) == buffname then
					return true
				end
			end
		end
		return false
	end)
end


-- This works great. Don't delete because I'm sure it will be useful in the future.
--[[
local PredIsBuffActiveTimeLeftByName = function(buffname)
	local tooltip = resetTooltip()
	for i=0,QUIVER.Buff_Cap do
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
__bundle_register("Modules/TranqAnnouncer.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local FrameLock = require("Events/FrameLock.lua")
local Spell = require("Shiver/API/Spell.lua")
local L = require("Shiver/Lib/All.lua")
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
	frame:SetBackdropBorderColor(0.6, 0.9, 0.7, 1.0)

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
local EVENTS = {
	"CHAT_MSG_ADDON",-- Also works with macros
	"CHAT_MSG_SPELL_SELF_DAMAGE",-- Detect misses
	"SPELL_UPDATE_COOLDOWN",
}
local lastCastStart = 0
local getHasFiredTranq = function()
	local isCast, cdStart = Spell.CheckNewCd(
		TRANQ_CD_SEC, lastCastStart, Quiver.L.Spellbook["Tranquilizing Shot"])
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
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	if getCanHide() then hideFrameDeleteBars() else frame:Show() end
end
local onDisable = function()
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

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
local FrameLock = require("Events/FrameLock.lua")
local Action = require("Shiver/API/Action.lua")

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
	local slot = Action.FindBySpellName(name)
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
	Melee=function() return predSpellInRange(Quiver.L.Spellbook["Wing Clip"]) end,-- 5 yards
	Mark=function() return predSpellInRange(Quiver.L.Spellbook["Hunter's Mark"]) end,-- 100 yards
	Ranged=function() return predSpellInRange(Quiver.L.Spellbook["Auto Shot"]) end,-- 35-41 yards (talents)
	Scare=function() return predSpellInRange(Quiver.L.Spellbook["Scare Beast"]) end,-- 10 yards
	Scatter=function() return predSpellInRange(Quiver.L.Spellbook["Scatter Shot"]) end,-- 15-21 yards (talents)
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
local EVENTS = {
	"PLAYER_TARGET_CHANGED",
	"UNIT_FACTION",
}
local onEnable = function()
	if frame == nil then frame, fontString = createUI() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	if Quiver_Store.IsLockedFrames then handleEvent() else frame:Show() end
end

local onDisable = function()
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

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
		store.ColorMelee = store.ColorMelee or QUIVER.ColorDefault.Range.Melee
		store.ColorDeadZone = store.ColorDeadZone or QUIVER.ColorDefault.Range.DeadZone
		store.ColorScareBeast = store.ColorScareBeast or QUIVER.ColorDefault.Range.ScareBeast
		store.ColorScatterShot = store.ColorScatterShot or QUIVER.ColorDefault.Range.ScatterShot
		store.ColorShort = store.ColorShort or QUIVER.ColorDefault.Range.Short
		store.ColorLong = store.ColorLong or QUIVER.ColorDefault.Range.Long
		store.ColorMark = store.ColorMark or QUIVER.ColorDefault.Range.Mark
		store.ColorTooFar = store.ColorTooFar or QUIVER.ColorDefault.Range.TooFar
	end,
	OnSavedVariablesPersist = function() return store end,
}

end)
__bundle_register("Modules/Castbar.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local FrameLock = require("Events/FrameLock.lua")
local Spellcast = require("Events/Spellcast.lua")
local Haste = require("Shiver/Haste.lua")

local MODULE_ID = "Castbar"
local store = nil
local frame = nil

local BORDER = 1
local maxBarWidth = 0
local castTime = 0
local isCasting = false
local timeStartCasting = 0

-- ************ UI ************
local setCastbarSize = function(f, s)
	maxBarWidth = s.FrameMeta.W - 2 * BORDER
	f.Castbar:SetWidth(1)
	f.SpellName:SetWidth(maxBarWidth)
	f.SpellTime:SetWidth(maxBarWidth)

	local path, _size, flags = f.SpellName:GetFont()
	local calcFontSize = s.FrameMeta.H - 4 * BORDER
	local fontSize = calcFontSize > 18 and 18
		or calcFontSize < 10 and 10
		or calcFontSize

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
	setCastbarSize(f, s)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("HIGH")
	local centerVertically = function(ele)
		ele:SetPoint("Top", f, "Top", 0, -BORDER)
		ele:SetPoint("Bottom", f, "Bottom", 0, BORDER)
	end

	f.Castbar = CreateFrame("Frame", nil, f)
	f.Castbar:SetPoint("Left", f, "Left", BORDER, 0)

	f.SpellName = f.Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.SpellName:SetPoint("Left", f, "Left", 4*BORDER, 0)
	f.SpellName:SetJustifyH("Left")
	f.SpellName:SetTextColor(1, 1, 1)

	f.SpellTime = f.Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.SpellTime:SetPoint("Right", f, "Right", -4*BORDER, 0)
	f.SpellTime:SetJustifyH("Right")
	f.SpellTime:SetTextColor(1, 1, 1)

	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/BUTTONS/WHITE8X8",
		edgeSize = BORDER,
		tile = false,
	})
	f.Castbar:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
	})
	f:SetBackdropColor(0, 0, 0, 0.8)
	f:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)

	centerVertically(f.Castbar)
	centerVertically(f.SpellTime)
	centerVertically(f.SpellName)

	setFramePosition(f, store)
	FrameLock.SideEffectMakeMoveable(f, store)
	FrameLock.SideEffectMakeResizeable(f, store, {
		GripMargin=0,
		OnResizeEnd=function() setCastbarSize(f, store) end,
		IsCenterX=true,
	})
	return f
end

-- ************ Custom Event Handlers ************
local displayTime = function(current)
	if current < 0 then current = 0 end
	frame.SpellTime:SetText(string.format("%.1f / %.2f", current, castTime))
end
---@param spellName string
local onSpellcast = function(spellName)
	if isCasting then return end
	isCasting = true
	local _timeStartLocal
	castTime, timeStartCasting, _timeStartLocal = Haste.CalcCastTime(spellName)
	frame.SpellName:SetText(spellName)
	frame.Castbar:SetWidth(1)
	displayTime(0)

	local r, g, b = unpack(store.ColorCastbar)
	frame.Castbar:SetBackdropColor(r, g, b, 1)
	frame:Show()
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
local EVENTS = {
	"SPELLCAST_DELAYED",
	"SPELLCAST_FAILED",
	"SPELLCAST_INTERRUPTED",
	"SPELLCAST_STOP",
}
local onEnable = function()
	if frame == nil then frame = createUI() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	if Quiver_Store.IsLockedFrames then frame:Hide() else frame:Show() end
	Spellcast.CastableShot.Subscribe(MODULE_ID, onSpellcast)
end
local onDisable = function()
	Spellcast.CastableShot.Dispose(MODULE_ID)
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

return {
	Id = MODULE_ID,
	GetName = function() return Quiver.T["Castbar"] end,
	GetTooltipText = function() return Quiver.T["Shows Aimed Shot, Multi-Shot, and Trueshot."] end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() if not isCasting then frame:Hide() end end,
	OnInterfaceUnlock = function() frame:Show() end,
	OnResetFrames = function()
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.ColorCastbar = store.ColorCastbar or QUIVER.ColorDefault.Castbar
	end,
	OnSavedVariablesPersist = function() return store end,
}

end)
__bundle_register("Modules/Aspect_Tracker/AspectTracker.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local FrameLock = require("Events/FrameLock.lua")
local Spell = require("Shiver/API/Spell.lua")
local Aura = require("Util/Aura.lua")

local MODULE_ID = "AspectTracker"
local store = nil
local frame = nil

local DEFAULT_ICON_SIZE = 40
local INSET = 5
local TRANSPARENCY = 0.5

local chooseIconTexture = function()
	if Aura.PredBuffActive(Quiver.L.Spellbook["Aspect of the Beast"]) then
		return QUIVER.Icon.Aspect_Beast
	elseif Aura.PredBuffActive(Quiver.L.Spellbook["Aspect of the Cheetah"]) then
		return QUIVER.Icon.Aspect_Cheetah
	elseif Aura.PredBuffActive(Quiver.L.Spellbook["Aspect of the Monkey"]) then
		return QUIVER.Icon.Aspect_Monkey
	elseif Aura.PredBuffActive(Quiver.L.Spellbook["Aspect of the Wild"]) then
		return QUIVER.Icon.Aspect_Wild
	elseif Aura.PredBuffActive(Quiver.L.Spellbook["Aspect of the Wolf"]) then
		return QUIVER.Icon.Aspect_Wolf
	elseif Spell.PredSpellLearned(Quiver.L.Spellbook["Aspect of the Hawk"])
		and not Aura.PredBuffActive(Quiver.L.Spellbook["Aspect of the Hawk"])
		or not Quiver_Store.IsLockedFrames
	then
		return QUIVER.Icon.Aspect_Hawk
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
	if Aura.PredBuffActive(Quiver.L.Spellbook["Aspect of the Pack"]) then
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
local EVENTS = {
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
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	frame:Show()
end
local onDisable = function()
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

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
local Button = require("Component/Button.lua")
local CheckButton = require("Component/CheckButton.lua")
local Dialog = require("Component/Dialog.lua")
local Select = require("Component/Select.lua")
local Switch = require("Component/Switch.lua")
local TitleBox = require("Component/TitleBox.lua")
local Color = require("Config/Color.lua")
local InputText = require("Config/InputText.lua")
local FrameLock = require("Events/FrameLock.lua")
local AutoShotTimer = require("Modules/Auto_Shot_Timer/AutoShotTimer.lua")
local TranqAnnouncer = require("Modules/TranqAnnouncer.lua")
local L = require("Shiver/Lib/All.lua")

local createModuleControls = function(parent, m)
	local f = CreateFrame("Frame", nil, parent)

	local btnReset = Button:Create(f, QUIVER.Icon.Reset)
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
			if isChecked then
				m.OnEnable()
			else
				m.OnDisable()
			end
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

	local maxWidths =
		L.Array.MapReduce(frames, function(x) return x:GetWidth() end, math.max, 0)
	local totalHeight =
		L.Array.MapReduce(frames, function(x) return x:GetHeight() + gap end, L.Add, 0)
		- gap
	f:SetHeight(totalHeight)
	f:SetWidth(maxWidths)

	return f
end

local Create = function()
	-- WoW uses border-box content sizing
	local _PADDING_CLOSE = QUIVER.Size.Border + 6
	local _PADDING_FAR = QUIVER.Size.Border + QUIVER.Size.Gap
	local dialog = Dialog.Create(_PADDING_CLOSE)

	local titleText = "Quiver " .. GetAddOnMetadata("Quiver", "Version")
	local titleBox = TitleBox.Create(dialog, titleText)
	titleBox:SetPoint("Center", dialog, "Top", 0, -10)

	local btnCloseTop = Button:Create(dialog, QUIVER.Icon.XMark)
	btnCloseTop.TooltipText = Quiver.T["Close Window"]
	btnCloseTop.HookClick = function() dialog:Hide() end
	btnCloseTop.Container:SetPoint("TopRight", dialog, "TopRight", -_PADDING_CLOSE, -_PADDING_CLOSE)

	local btnToggleLock = CheckButton:Create(dialog, {
		IsChecked = Quiver_Store.IsLockedFrames,
		OnChange = function(isLocked) FrameLock.SetIsLocked(isLocked) end,
		TexPathOff = QUIVER.Icon.LockOpen,
		TexPathOn = QUIVER.Icon.LockClosed,
		TooltipText=Quiver.T["Lock/Unlock Frames"],
	})
	FrameLock.Init()

	local lockOffsetX = _PADDING_CLOSE + QUIVER.Size.Icon + QUIVER.Size.Gap/2
	btnToggleLock.Icon:SetPoint("TopRight", dialog, "TopRight", -lockOffsetX, -_PADDING_CLOSE)

	local btnResetFrames = Button:Create(dialog, QUIVER.Icon.Reset)
	btnResetFrames.TooltipText = Quiver.T["Reset All Frame Sizes and Positions"]
	btnResetFrames.HookClick = function()
		for _k, v in _G.Quiver_Modules do v.OnResetFrames() end
	end
	local resetOffsetX = lockOffsetX + btnResetFrames.Container:GetWidth() + QUIVER.Size.Gap/2
	btnResetFrames.Container:SetPoint("TopRight", dialog, "TopRight", -resetOffsetX, -_PADDING_CLOSE)

	local controls = createAllModuleControls(dialog, QUIVER.Size.Gap)
	local colorPickers = Color.Create(dialog, QUIVER.Size.Gap)

	local yOffset = -_PADDING_CLOSE - QUIVER.Size.Icon - QUIVER.Size.Gap
	controls:SetPoint("Top", dialog, "Top", 0, yOffset)
	controls:SetPoint("Left", dialog, "Left", _PADDING_FAR, 0)
	colorPickers:SetPoint("Top", dialog, "Top", 0, yOffset)
	colorPickers:SetPoint("Right", dialog, "Right", -_PADDING_FAR, 0)
	dialog:SetWidth(_PADDING_FAR + controls:GetWidth() + _PADDING_FAR + colorPickers:GetWidth() + _PADDING_FAR)

	local dropdownX = _PADDING_FAR + colorPickers:GetWidth() + _PADDING_FAR
	local dropdownY = 0

	local selectDebugLevel = Select:Create(dialog,
		Quiver.T["Debug Level"],
		{ Quiver.T["None"], Quiver.T["Verbose"] },
		Quiver_Store.DebugLevel,
		function(text)
			local level = text == Quiver.T["None"] and "None" or "Verbose"
			Quiver_Store.DebugLevel = level
		end
	)
	dropdownY = yOffset - colorPickers:GetHeight() + selectDebugLevel.Container:GetHeight() + QUIVER.Size.Gap
	selectDebugLevel.Container:SetPoint("Right", dialog, "Right", -dropdownX, 0)
	selectDebugLevel.Container:SetPoint("Top", dialog, "Top", 0, dropdownY)

	-- Factored out until we can re-render options upon locale change.
	-- Otherwise, the change handler with compare wrong locale.
	local leftToRight = Quiver.T["Left to Right"]
	local selectedDirection = Quiver_Store.ModuleStore[AutoShotTimer.Id].BarDirection
	-- Dropdown auto shot bar direction
	local selectAutoShotTimerDirection = Select:Create(dialog,
		Quiver.T["Auto Shot Timer"],
		{ leftToRight, Quiver.T["Both Directions"] },
		Quiver.T[selectedDirection],
		function(text)
			-- Maps from localized text to binary key
			local direction = text == leftToRight and "LeftToRight" or "BothDirections"
			Quiver_Store.ModuleStore[AutoShotTimer.Id].BarDirection = direction
			AutoShotTimer.UpdateDirection()
		end
	)
	dropdownY = dropdownY + QUIVER.Size.Gap + selectAutoShotTimerDirection.Container:GetHeight()
	selectAutoShotTimerDirection.Container:SetPoint("Right", dialog, "Right", -dropdownX, 0)
	selectAutoShotTimerDirection.Container:SetPoint("Top", dialog, "Top", 0, dropdownY)

	-- Dropdown tranq shot announce channel
	local defaultTranqText = (function()
		local store = Quiver_Store.ModuleStore[TranqAnnouncer.Id]
		-- TODO DRY violation -- dropdown must match the module store init
		return store and store.TranqChannel or "/Say"
	end)()
	local selectChannelHit = Select:Create(dialog,
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
	dropdownY = dropdownY + QUIVER.Size.Gap + selectChannelHit.Container:GetHeight()
	selectChannelHit.Container:SetPoint("Right", dialog, "Right", -dropdownX, 0)
	selectChannelHit.Container:SetPoint("Top", dialog, "Top", 0, dropdownY)

	local hLeft = controls:GetHeight()
	local hRight = colorPickers:GetHeight()
	local hMax = hRight > hLeft and hRight or hLeft
	yOffset = yOffset - hMax - QUIVER.Size.Gap

	local tranqOptions = InputText.Create(dialog, QUIVER.Size.Gap)
	tranqOptions:SetPoint("TopLeft", dialog, "TopLeft", 0, yOffset)
	yOffset = yOffset - tranqOptions:GetHeight()
	yOffset = yOffset - QUIVER.Size.Gap

	dialog:SetHeight(-1 * yOffset + _PADDING_CLOSE + QUIVER.Size.Button)
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

local _GAP = QUIVER.Size.Gap
local _GAP_RESET = 4

---@class QqEditBox
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
		Reset = Button:Create(box, QUIVER.Icon.Reset),
	}
	r.Reset.TooltipText = tooltipText
	setmetatable(r, self)
	self.__index = self

	local fMarginLeft = QUIVER.Size.Border + _GAP
	local fMarginRight = QUIVER.Size.Border + _GAP + QUIVER.Size.Icon + _GAP_RESET

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
local AutoShotTimer = require("Modules/Auto_Shot_Timer/AutoShotTimer.lua")
local Castbar = require("Modules/Castbar.lua")
local RangeIndicator = require("Modules/RangeIndicator.lua")
local Color = require("Shiver/Color.lua")
local L = require("Shiver/Lib/All.lua")

---@param c1 Color
---@param c2 Color
local createBtnColorSwap = function(parent, f1, f2, c1, c2)
	local f = Button:Create(parent, QUIVER.Icon.ArrowsSwap, Quiver.T["Shoot / Reload"])
	f.TooltipText = Quiver.T["Swap Shoot and Reload Colours"]
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
	local color = Color:LiftReset(store, default)
	return ColorSwatch:Create(f, label, color)
end

local Create = function(parent, gap)
	local storeAutoShotTimer = Quiver_Store.ModuleStore[AutoShotTimer.Id]
	local storeCastbar = Quiver_Store.ModuleStore[Castbar.Id]
	local storeRange = Quiver_Store.ModuleStore[RangeIndicator.Id]
	local f = CreateFrame("Frame", nil, parent)

	local colorShoot = Color:LiftReset(storeAutoShotTimer.ColorShoot, QUIVER.ColorDefault.AutoShotShoot)
	local colorReload = Color:LiftReset(storeAutoShotTimer.ColorReload, QUIVER.ColorDefault.AutoShotReload)
	local optionShoot = ColorSwatch:Create(f, Quiver.T["Shooting"], colorShoot)
	local optionReload = ColorSwatch:Create(f, Quiver.T["Reloading"], colorReload)

	local elements = {
		swatch(f, Quiver.T["Casting"], storeCastbar.ColorCastbar, QUIVER.ColorDefault.Castbar),
		createBtnColorSwap(f, optionShoot, optionReload, colorShoot, colorReload),
		optionShoot,
		optionReload,
		swatch(f, Quiver.T["Melee Range"], storeRange.ColorMelee, QUIVER.ColorDefault.Range.Melee),
		swatch(f, Quiver.T["Dead Zone"], storeRange.ColorDeadZone, QUIVER.ColorDefault.Range.DeadZone),
		swatch(f, Quiver.T["Scare Beast"], storeRange.ColorScareBeast, QUIVER.ColorDefault.Range.ScareBeast),
		swatch(f, Quiver.T["Scatter Shot"], storeRange.ColorScatterShot, QUIVER.ColorDefault.Range.ScatterShot),
		swatch(f, Quiver.T["Short Range"], storeRange.ColorShort, QUIVER.ColorDefault.Range.Short),
		swatch(f, Quiver.T["Long Range"], storeRange.ColorLong, QUIVER.ColorDefault.Range.Long),
		swatch(f, Quiver.T["Hunter's Mark"], storeRange.ColorMark, QUIVER.ColorDefault.Range.Mark),
		swatch(f, Quiver.T["Out of Range"], storeRange.ColorTooFar, QUIVER.ColorDefault.Range.TooFar),
	}
	-- Right align buttons using minimum amount of space
	local labelMaxWidth = L.Array.MapReduce(
		elements,
		function(x) return x.Label and x.Label:GetWidth() or 0 end,
		L.Max,
		0
	)

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

---@class ButtonColorPicker
---@field Button Frame
---@field Container Frame
---@field Label FontString
---@field WidthMinusLabel number
local ColorSwatch = {}

---@param parent Frame
---@param labelText string
---@param color Color
---@return ButtonColorPicker
function ColorSwatch:Create(parent, labelText, color)
	local container = CreateFrame("Frame", nil, parent)

	---@type ButtonColorPicker
	local r = {
		Button = createButton(container, color),
		Container = container,
		Label = container:CreateFontString(nil, "BACKGROUND", "GameFontNormal"),
		WidthMinusLabel = 0,
	}

	r.Label:SetPoint("Left", container, "Left", 0, 0)
	r.Label:SetText(labelText)

	local reset = Button:Create(container, QUIVER.Icon.Reset)
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

return ColorSwatch

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
local Util = require("Component/_Util.lua")
local L = require("Shiver/Lib/All.lua")
local Sugar = require("Shiver/Sugar.lua")

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
-- see [CheckButton](lua://QqCheckButton)
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
	local path = self.isChecked and QUIVER.Icon.ToggleOn or QUIVER.Icon.ToggleOff
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
	local h = L.Psi(L.Max, Sugar.Region._GetHeight, r.Icon, r.Label)
	local w = L.Psi(L.Add, Sugar.Region._GetWidth, r.Icon, r.Label) + _GAP
	container:SetHeight(h)
	container:SetWidth(w)

	resetTexture(r)
	return r
end

return QqSwitch

end)
__bundle_register("Component/Select.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Util = require("Component/_Util.lua")
local L = require("Shiver/Lib/All.lua")

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
	t:SetTexture(QUIVER.Icon.CaretDown)
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
	return L.Array.MapReduce(xs, function(x) return MouseIsOver(x) == 1 end, L.Or, false)
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

	local sumOptionHeights =
		L.Array.MapReduce(options, function(o) return o:GetHeight() end, L.Add, 0)
	local maxOptionWidth =
		L.Array.MapReduce(options, function(o) return o:GetFontString():GetWidth() end, math.max, 0)

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
__bundle_register("Component/Dialog.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Create = function(padding)
	local f = CreateFrame("Frame", nil, UIParent)
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
	btnCloseBottom:SetHeight(QUIVER.Size.Button)
	btnCloseBottom:SetPoint("BottomRight", f, "BottomRight", -padding, padding)
	btnCloseBottom:SetText(Quiver.T["Close"])
	btnCloseBottom:SetScript("OnClick", function() f:Hide() end)

	return f
end

return {
	Create = Create,
}

end)
__bundle_register("Component/CheckButton.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local Util = require("Component/_Util.lua")

local _SIZE = 16

-- see [Button](lua://QqButton)
-- see [Switch](lua://QqSwitch)
---@class (exact) QqCheckButton : IMouseInteract
---@field private __index? QqCheckButton
---@field Icon Frame
---@field IsChecked boolean
---@field TexPathOff string
---@field TexPathOn string
---@field Texture Texture
---@field isEnabled boolean
---@field isHover boolean
---@field isMouseDown boolean
local QqCheckButton = {}

---@class (exact) paramsCheckButton
---@field IsChecked boolean
---@field OnChange fun(b: boolean): nil
---@field TexPathOff string
---@field TexPathOn string
---@field TooltipText? string

---@param self QqCheckButton
local resetTexture = function(self)
	local path = self.IsChecked and self.TexPathOn or self.TexPathOff
	self.Texture:SetTexture(path)

	local r, g, b = Util.SelectColor(self)
	self.Texture:SetVertexColor(r, g, b)
end

---@param parent Frame
---@param bag paramsCheckButton
---@return QqCheckButton
---@nodiscard
function QqCheckButton:Create(parent, bag)
	local icon = CreateFrame("Frame", nil, parent, nil)

	---@type QqCheckButton
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

return QqCheckButton

end)
__bundle_register("Locale/Lang.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
local enUS_C = require("Locale/enUS.client.lua")
local enUS_T = require("Locale/enUS.translations.lua")
local zhCN_C = require("Locale/zhCN.client.lua")
local zhCN_T = require("Locale/zhCN.translations.lua")

return function()
	local currentLang = GetLocale()
	DEFAULT_CHAT_FRAME:AddMessage("Quiver: "..currentLang)

	local translation = {
		["enUS"] = enUS_T,
		["zhCN"] = zhCN_T,
	}
	local client = {
		["enUS"] = enUS_C,
		["zhCN"] = zhCN_C,
	}

	Quiver.T = translation[currentLang] or translation["enUS"]
	Quiver.L = client[currentLang] or client["enUS"]
end

end)
__bundle_register("Locale/zhCN.translations.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
	["Announces in chat when your tranquilizing shot hits or misses a target."] = "在“/团队”聊天中通告你的宁神射击是否命中目标。",
	["Aspect Tracker"] = "守护追踪器",
	["Auto Shot Timer"] = "自动射击计时器",
	["Both Directions"] = "双向",
	["Castbar"] = "施法条",
	["Casting"] = "Casting",-- TODO
	["Casting Tranq Shot"] = "施放宁神射击",
	["Close"] = "Close",-- TODO
	["Close Window"] = "关闭窗口",
	["Dead Zone"] = "死区",
	["Debug Level"] = "Debug Level",-- TODO
	["Hunter's Mark"] = "猎人印记",
	["It's always safe to upgrade Quiver. You won't lose any of your configuration."] = "升级Quiver是安全的，你不会丢失任何配置。",
	["Left to Right"] = "从左到右",
	["Lock/Unlock Frames"] = "锁定/解锁框架",
	["Long Range"] = "远距离",
	["Melee Range"] = "近战范围",
	["*** MISSED Tranq Shot ***"] = "*** 宁神射击未命中 ***",
	["New version %s available at %s"] = "新版本%s可在%s下载",
	["None"] = "None",-- TODO
	["Out of Range"] = "超出范围",
	["Quiver is for hunters."] = "Quiver仅适用于猎人。",
	["Quiver Unlocked. Show config dialog with /qq or /quiver.\nClick the lock icon when done."] = "Quiver已解锁。使用/qq或/quiver显示配置对话框。\n完成后点击锁定图标。",
	["Range Indicator"] = "距离指示器",
	["Reloading"] = "Reloading",-- TODO
	["Reset All Frame Sizes and Positions"] = "重置所有框架大小和位置",
	["Reset Color"] = "重置颜色",
	["Reset Frame Size and Position"] = "重置框架大小和位置",
	["Reset Miss Message to Default"] = "重置未命中消息为默认",
	["Reset Tranq Message to Default"] = "重置宁神射击消息为默认",
	["Scare Beast"] = "恐吓野兽",
	["Scatter Shot"] = "驱散射击",
	["Shoot / Reload"] = "射击/装填",
	["Shooting"] = "Shooting",-- TODO
	["Short Range"] = "近距离",
	["Shows Aimed Shot, Multi-Shot, and Trueshot."] = "显示瞄准射击、多重射击和强击光环的施法条。",
	["Shows when abilities are in range. Requires spellbook abilities placed somewhere on your action bars."] = "显示技能是否在范围内。需要将技能书中的技能放在动作条上。",
	["Swap Shoot and Reload Colours"] = "交换射击和装填颜色",
	["Tranq Shot Announcer"] = "宁神射击通告器",
	["Tranq Speech"] = "Tranq Speech",-- TODO
	["Trueshot Aura Alarm"] = "强击光环警报",
	["Verbose"] = "Verbose",-- TODO
}

end)
__bundle_register("Locale/zhCN.client.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
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
	Spellbook = {
		-- Aspect
		["Aspect of the Beast"] = "野兽守护",
		["Aspect of the Cheetah"] = "猎豹守护",
		["Aspect of the Hawk"] = "雄鹰守护",
		["Aspect of the Monkey"] = "灵猴守护",
		["Aspect of the Pack"] = "豹群守护",
		["Aspect of the Wild"] = "野性守护",
		["Aspect of the Wolf"] = "孤狼守护",
		-- Uses Ammo
		["Aimed Shot"] = "瞄准射击",
		["Arcane Shot"] = "奥术射击",
		["Auto Shot"] = "自动射击",
		["Concussive Shot"] = "震荡射击",
		["Multi-Shot"] = "多重射击",
		["Scatter Shot"] = "驱散射击",
		["Scorpid Sting"] = "毒蝎钉刺",
		["Serpent Sting"] = "毒蛇钉刺",
		["Tranquilizing Shot"] = "宁神射击",
		["Trueshot"] = "稳固射击",
		["Viper Sting"] = "蝰蛇钉刺",
		["Wyvern Sting"] = "翼龙钉刺",
		-- Trap
		["Explosive Trap"] = "爆炸陷阱",
		["Freezing Trap"] = "冰冻陷阱",
		["Frost Trap"] = "冰霜陷阱",
		["Immolation Trap"] = "献祭陷阱",
		-- Misc
		["Call Pet"] = "召唤宠物",
		["Counterattack"] = "反击",
		["Deterrence"] = "威慑",
		["Feign Death"] = "假死",
		["Flare"] = "照明弹",
		["Quick Shots"] = "快速射击",
		["Rapid Fire"] = "急速射击",
		["Hunter's Mark"] = "猎人印记",
		["Scare Beast"] = "恐吓野兽",
		["Trueshot Aura"] = "强击光环",
		["Wing Clip"] = "摔绊",
	},
}

end)
__bundle_register("Locale/enUS.translations.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
return {
	["Announces in chat when your tranquilizing shot hits or misses a target."] = "Announces in chat when your tranquilizing shot hits or misses a target.",
	["Aspect Tracker"] = "Aspect Tracker",
	["Auto Shot Timer"] = "Auto Shot Timer",
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
	["Shows Aimed Shot, Multi-Shot, and Trueshot."] = "Shows Aimed Shot, Multi-Shot, and Trueshot.",
	["Shows when abilities are in range. Requires spellbook abilities placed somewhere on your action bars."] = "Shows when abilities are in range. Requires spellbook abilities placed somewhere on your action bars.",
	["Swap Shoot and Reload Colours"] = "Swap Shoot and Reload Colours",
	["Tranq Shot Announcer"] = "Tranq Shot Announcer",
	["Tranq Speech"] = "Tranq Speech",
	["Trueshot Aura Alarm"] = "Trueshot Aura Alarm",
	["Verbose"] = "Verbose",
}

end)
__bundle_register("Locale/enUS.client.lua", function(require, _LOADED, __bundle_register, __bundle_modules)
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
	Spellbook = {
		-- Aspect
		["Aspect of the Beast"] = "Aspect of the Beast",
		["Aspect of the Cheetah"] = "Aspect of the Cheetah",
		["Aspect of the Hawk"] = "Aspect of the Hawk",
		["Aspect of the Monkey"] = "Aspect of the Monkey",
		["Aspect of the Pack"] = "Aspect of the Pack",
		["Aspect of the Wild"] = "Aspect of the Wild",
		["Aspect of the Wolf"] = "Aspect of the Wolf",
		-- Uses Ammo
		["Aimed Shot"] = "Aimed Shot",
		["Arcane Shot"] = "Arcane Shot",
		["Auto Shot"] = "Auto Shot",
		["Concussive Shot"] = "Concussive Shot",
		["Multi-Shot"] = "Multi-Shot",
		["Scatter Shot"] = "Scatter Shot",
		["Scorpid Sting"] = "Scorpid Sting",
		["Serpent Sting"] = "Serpent Sting",
		["Tranquilizing Shot"] = "Tranquilizing Shot",
		["Trueshot"] = "Trueshot",
		["Viper Sting"] = "Viper Sting",
		["Wyvern Sting"] = "Wyvern Sting",
		-- Trap
		["Explosive Trap"] = "Explosive Trap",
		["Freezing Trap"] = "Freezing Trap",
		["Frost Trap"] = "Frost Trap",
		["Immolation Trap"] = "Immolation Trap",
		-- Misc
		["Call Pet"] = "Call Pet",
		["Counterattack"] = "Counterattack",
		["Deterrence"] = "Deterrence",
		["Feign Death"] = "Feign Death",
		["Flare"] = "Flare",
		["Quick Shots"] = "Quick Shots",
		["Rapid Fire"] = "Rapid Fire",
		["Hunter's Mark"] = "Hunter's Mark",
		["Scare Beast"] = "Scare Beast",
		["Trueshot Aura"] = "Trueshot Aura",
		["Wing Clip"] = "Wing Clip",
	},
}

end)
return __bundle_require("__root")