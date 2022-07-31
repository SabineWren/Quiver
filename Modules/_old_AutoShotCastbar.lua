local MODULE_ID = "AutoShotCastbar"
local store = {}
local frameMeta = {}
local frame = nil
local maxBarWidth = 0
local BORDER = 1
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
			local cooldownStartTime, spellCD = Quiver_Lib_Spellbook_CheckGCD()
			if spellCD == 1.5 then gcdStartTime = cooldownStartTime end
		end,
		CheckShotWasAuto = function()
			local cooldownStartTime, spellCD = Quiver_Lib_Spellbook_CheckGCD()
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

-- ************ Custom Event Handlers ************
local onSpellcast = function(spellName)
	if isCasting then return end
	isCasting = true
	if isShooting and (not isReloading) then
		timeStartShootOrReload = GetTime()
	end
	castTime, timeStartCasting = Quiver_Lib_Spellbook_GetCastTime(spellName)
end

-- ************ Frame Update Handlers ************
local updateShooting = function()
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

local hideBar = function()
	if Quiver_Store.IsLockedFrames
	then frame:SetAlpha(0)
	else frame.BarAutoShot:SetWidth(1)
	end
end

local updateReloading = function()
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
			updateShooting()-- Optional. I think this saves a frame
		else
			hideBar()
		end
	end
end

local handleUpdate = function()
	if isReloading then updateReloading()
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
-- This got unexpectedly complicated, and triggers reload from moving ammo in inventory.
-- TODO As an alternative to "ITEM_LOCK_CHANGED", we could parse the combat log for
-- player Auto Shot and trigger a custom event. The other events are much more reliable.
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
	-- "SPELLCAST_FAILED", "SPELLCAST_INTERRUPTED"
	-- Rare edge case from spell interrupt.
	else
		isCasting = false
	end
end

-- ************ Initialization ************
local EVENTS = {
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
end
local onDisable = function()
	Quiver_Event_CastableShot_Unsubscribe(MODULE_ID)
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
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
		if (not isShooting) and (not isReloading) then hideBar() end
	end,
	OnInterfaceUnlock = function() frame:SetAlpha(1) end,
}
