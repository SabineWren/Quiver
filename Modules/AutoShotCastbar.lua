local MODULE_ID = "AutoShotCastbar"
local store = {}
local frame = nil
local frameMeta = {}
local BORDER = 1
local maxBarWidth = 0
-- Aimed Shot, Multi-Shot, Trueshot
local castTime = 0
local isCasting = false
local isFiredInstant = false
local timeStartCast = 0
-- Auto Shot
local AIMING_TIME = 0.65
local isReloading = false
local isShooting = false
local reloadTime = 0
local timeStartShootOrReload = GetTime()
-- Consumables
local isConsumable

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

-- ************ UI ************
local updateBarSizes = function()
	frame:SetWidth(frameMeta.W)
	frame:SetHeight(frameMeta.H)
	maxBarWidth = frameMeta.W - 2 * BORDER
	frame.BarAutoShot:SetWidth(1)
	frame.BarAutoShot:SetHeight(frameMeta.H - 2 * BORDER)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("HIGH")
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

	Quiver_Event_FrameLock_MakeMoveable(f, frameMeta)
	Quiver_Event_FrameLock_MakeResizeable(f, frameMeta, {
		GripMargin=0,
		OnResizeEnd=updateBarSizes,
		IsCenterX=true,
	})
	return f
end

-- Temporary code until I figure out how to make a colour picker
Quiver_Module_AutoShotCastbar_MakeOptionsColour = function(parent)
	local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	btn:SetWidth(120)
	btn:SetHeight(QUIVER.Size.Button)
	btn:SetText("Toggle Colours")
	btn:SetScript("OnClick", function()
		local shoot = QUIVER.Colour.AutoAttackDefaultShoot
		local reload = QUIVER.Colour.AutoAttackDefaultReload
		if store.ColourShoot[1] == shoot[1] and store.ColourShoot[2] == shoot[2] then
			store.ColourShoot = reload
			store.ColourReload = shoot
		else
			store.ColourShoot = shoot
			store.ColourReload = reload
		end
	end)
	return btn
end

-- ************ Frame Update Handlers ************
local updateBarShooting = function()
	frame:SetAlpha(1)
	local r, g, b = unpack(store.ColourShoot)
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

local tryHideBar = function()
	if Quiver_Store.IsLockedFrames
	then frame:SetAlpha(0)
	else frame.BarAutoShot:SetWidth(1)
	end
end

local updateBarReload = function()
	frame:SetAlpha(1)
	local r, g, b = unpack(store.ColourReload)
	frame.BarAutoShot:SetBackdropColor(r, g, b, 0.8)
	local timePassed = GetTime() - timeStartShootOrReload
	if timePassed <= reloadTime then
		frame.BarAutoShot:SetWidth(maxBarWidth - maxBarWidth * timePassed / reloadTime)
	else
		isReloading = false
		if isShooting then
			timeStartShootOrReload = GetTime()
			position.UpdateXY()
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
		tryHideBar()
		-- Reset bar in case it doesn't hide
		timeStartShootOrReload = GetTime()
	end
end

local startReload = function()
	reloadTime = UnitRangedDamage("player") - AIMING_TIME
	isReloading = true
	timeStartShootOrReload = GetTime()
end

-- ************ Event Handlers ************
--[[
Rough Event Order
- (Hook) Start casting shot
- (Hook) Cast instant shot

- ITEM_LOCK_CHANGED

- SPELLCAST_STOP (cast or cancel)
- SPELLCAST_DELAYED

-- These can also fire when a spell succeedes after we drop target
- SPELLCAST_INTERRUPTED (cancelled)
- SPELLCAST_FAILED (action in progress)

Known Cases:
Start shooting
-> START_AUTOREPEAT_SPELL
Stop shooting
-> STOP_AUTOREPEAT_SPELL
Instant while either moving or in middle of reload
-> (hook) OnInstant
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
Instant as shot fires (assuming state is already shooting)
-> (hook) OnInstant
-> ITEM_LOCK_CHANGED
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
Cast right as shot fires (assuming state is already shooting)
-> (hook) OnCast
-> ITEM_LOCK_CHANGED
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
Various inventory events
-> ITEM_LOCK_CHANGED, sometimes first one with arg1 "LeftButton"
]]
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

local lastInstantGcd = 0
local onInstant = function(spellName)
	local isTriggeredGcd, newStart = Quiver_Lib_Spellbook_CheckNewGCD(lastInstantGcd)
	lastInstantGcd = newStart
	if isTriggeredGcd then isFiredInstant = true end
end
local handleEvent = function()
	-- DEFAULT_CHAT_FRAME:AddMessage(event)
	local e = event
	-- Fires after SPELLCAST_STOP, but before ITEM_LOCK_CHANGED
	if e == "CHAT_MSG_SPELL_SELF_BUFF" then
		-- You gain <n> Mana from Restore Mana.
		-- Your Healing Potion heals you for <n>.
		isConsumable =
			string.find(arg1, " Mana from Restore Mana.")
			or string.find(arg1, "Your Healing Potion heals you for ")
			-- TODO add healthstones and other potion types
			-- DEFAULT_CHAT_FRAME:AddMessage(arg1)
	elseif e == "SPELLCAST_DELAYED"
		then castTime = castTime + arg1 / 1000
	-- This works because shooting consumes ammo, which triggers an inventory event
	elseif e == "ITEM_LOCK_CHANGED" then
		if isConsumable then
		-- Case 1 -- We used a potion or something. Ignore it.
			isConsumable = false
		elseif isFiredInstant then
		-- Case 2
		-- We fired a cast or instant but haven't yet called "SPELLCAST_STOP"
		-- If we fired an Auto Shot at the same time, then "ITEM_LOCK_CHANGED" will
		-- get called twice before "SPELLCAST_STOP", so we mark the first one as done
			isFiredInstant = false
		elseif isCasting then
			local ellapsed = GetTime() - timeStartCast
			if isShooting and ellapsed < castTime then
		-- Case 3
		-- We started casting immediately after firing an Auto Shot. We're both casting and reloading.
				startReload()
			else
		-- Case 4
		-- We finished a cast. If we're done reloading, we can shoot again
				if not isReloading then timeStartShootOrReload = GetTime() end
				isCasting = false
			end
		--[[
		We check isShooting to reduce false positives from inventory events.
		If we also started a cast before this event fired, we'll hit Case 1 instead.
		If we cancelled Auto Shot as we fired, this still works because "STOP_AUTOREPEAT_SPELL" is lower priority. ]]
		elseif isShooting then
		-- Case 5 -- Fired Auto Shot
			startReload()
		else
		-- Case 6
		-- This was an inventory event we can safely ignore.
		end
	elseif e == "SPELLCAST_STOP" or e == "SPELLCAST_FAILED" or e == "SPELLCAST_INTERRUPTED" then
		isCasting = false
	elseif e == "START_AUTOREPEAT_SPELL" then
		isShooting = true
	elseif e == "STOP_AUTOREPEAT_SPELL" then
		isShooting = false
	end
end

-- ************ Initialization ************
local EVENTS = {
	"CHAT_MSG_SPELL_SELF_BUFF",
	"ITEM_LOCK_CHANGED",
	"SPELLCAST_DELAYED",
	"SPELLCAST_FAILED",
	"SPELLCAST_INTERRUPTED",
	"SPELLCAST_STOP",
	"START_AUTOREPEAT_SPELL",
	"STOP_AUTOREPEAT_SPELL",
}
local onEnable = function()
	if frame == nil then frame = createUI(); updateBarSizes() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	frame:Show()
	if Quiver_Store.IsLockedFrames then frame:SetAlpha(0) else frame:SetAlpha(1) end
	Quiver_Event_CastableShot_Subscribe(MODULE_ID, onSpellcast)
	Quiver_Event_InstantShot_Subscribe(MODULE_ID, onInstant)
end
local onDisable = function()
	Quiver_Event_InstantShot_Unsubscribe(MODULE_ID)
	Quiver_Event_CastableShot_Unsubscribe(MODULE_ID)
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

Quiver_Module_AutoShotCastbar = {
	Id = MODULE_ID,
	OnRestoreSavedVariables = function(savedVariables)
		store = savedVariables
		store.ColourShoot = store.ColourShoot or QUIVER.Colour.AutoAttackDefaultShoot
		store.ColourReload = store.ColourReload or QUIVER.Colour.AutoAttackDefaultReload
	end,
	OnPersistSavedVariables = function() return store end,
	OnInitFrames = function(savedFrameMeta, options)
		frameMeta = savedFrameMeta
		local defaultOf = function(val, fallback)
			if options.IsReset or val == nil then return fallback else return val end
		end
		local width = 240
		frameMeta.W = defaultOf(frameMeta.W, width)
		frameMeta.H = defaultOf(frameMeta.H, 14)
		frameMeta.X = defaultOf(frameMeta.X, (GetScreenWidth() - width) / 2)
		frameMeta.Y = defaultOf(frameMeta.Y, -1 * GetScreenHeight() + 248)
		if options.IsReset and frame ~= nil then
			frame:SetPoint("TopLeft", frameMeta.X, frameMeta.Y)
			updateBarSizes()
		end
	end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function()
		if (not isShooting) and (not isReloading) then tryHideBar() end
	end,
	OnInterfaceUnlock = function() frame:SetAlpha(1) end,
}
