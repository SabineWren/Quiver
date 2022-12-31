local MODULE_ID = "AutoShotTimer"
local store = nil
local frame = nil

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
	s.FrameMeta = Quiver_Event_FrameLock_RestoreSize(s.FrameMeta, {
		w=240, h=14, dx=240 * -0.5, dy=-136,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
	setBarSizes(f, s)
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

	setFramePosition(f, store)
	local resizeBarAutoShot = function() setBarAutoShot(f) end
	Quiver_Event_FrameLock_MakeMoveable(f, store.FrameMeta)
	Quiver_Event_FrameLock_MakeResizeable(f, store.FrameMeta, {
		GripMargin=0,
		OnResizeDrag=resizeBarAutoShot,
		OnResizeEnd=resizeBarAutoShot,
		IsCenterX=true,
	})
	return f
end

local SIZE_GAP = 4
local createColourSwap = function(parent, fShoot, fReload, cs, cr)
	local btnSwap = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	btnSwap:SetWidth(120)
	btnSwap:SetHeight(QUIVER.Size.Button)
	btnSwap:SetText("Swap Colors")
	btnSwap:SetScript("OnClick", function()
		-- Swap colors
		local r, g, b = cs.Get()
		cs.Set(cr.Get())
		cr.Set(r, g, b)
		-- Update button preview
		local a, b, c = cs.Get()
		local d, e, f = cr.Get()
		fShoot.Button:SetBackdropColor(a, b, c, 1)
		fReload.Button:SetBackdropColor(d, e, f, 1)
	end)
	return btnSwap
end

local createColorPicker = function(parent, labelText, color)
	local f = CreateFrame("Frame", nil, parent)

	f.Label = f:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	f.Label:SetPoint("Left", f, "Left", QUIVER.Size.Gap, 0)
	f.Label:SetText(labelText)

	f.Button = CreateFrame("Button", nil, f)
	f.Button:SetWidth(48)
	f.Button:SetHeight(20)
	f.Button:SetPoint("Right", f, "Right", 0, 0)

	f.Button:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left=2, right=2, top=2, bottom=2 },
	})
	local a, b, c = color.Get()
	f.Button:SetBackdropColor(a, b, c, 1)

	f.Button:SetScript("OnClick", function(_self)
		-- Must replace existing callback before changing anything else,
		-- or edits can fire previous callback
		ColorPickerFrame.func = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			color.Set(r, g, b)
			f.Button:SetBackdropColor(r, g, b, 1)
		end

		-- colours at time of opening picker
		local cr, cg, cb = color.Get()
		ColorPickerFrame.cancelFunc = function()
			local r, g, b = cr, cg, cb
			color.Set(r, g, b)
			f.Button:SetBackdropColor(r, g, b, 1)
		end

		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame:SetColorRGB(cr, cg, cb)
		ColorPickerFrame:Show()
	end)

	f:SetWidth(120)
	f:SetHeight(f.Button:GetHeight())
	return f
end

Quiver_Module_AutoShotTimer_MakeOptionsColor = function(parent)
	local f = CreateFrame("Frame", nil, parent)

	local colorShoot = {
		Get = function() return unpack(store.ColorShoot) end,
		Set = function(r, g, b) store.ColorShoot = { r, g, b } end,
		Reset = function()
			local r, g, b = unpack(QUIVER.Color.AutoAttackDefaultShoot)
			store.ColorShoot = { r, g, b }
		end,
	}
	local colorReload = {
		Get = function() return unpack(store.ColorReload) end,
		Set = function(r, g, b) store.ColorReload = { r, g, b } end,
		Reset = function()
			local r, g, b = unpack(QUIVER.Color.AutoAttackDefaultReload)
			store.ColorReload = { r, g, b }
		end,
	}

	local f1 = createColorPicker(f, "Shooting", colorShoot)
	local f2 = createColorPicker(f, "Reloading", colorReload)
	local f3 = createColourSwap(f, f1, f2, colorShoot, colorReload)

	f1:SetPoint("Left", f, "Left", SIZE_GAP, 0)
	f2:SetPoint("Left", f, "Left", SIZE_GAP, 0)
	f3:SetPoint("Left", f, "Left", SIZE_GAP, 0)

	local h1, h2, h3 = f1:GetHeight(), f2:GetHeight(), f3:GetHeight()
	local y2 = -1 * (h1 + SIZE_GAP)
	local y3 = -1 * (h1 + SIZE_GAP + h2 + SIZE_GAP)
	f1:SetPoint("Top", f, "Top", 0, 0)
	f2:SetPoint("Top", f, "Top", 0, y2)
	f3:SetPoint("Top", f, "Top", 0, y3)

	f:SetWidth(parent:GetWidth())
	f:SetHeight(h1 + SIZE_GAP + h2 + SIZE_GAP + h3)
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

-- ************ Event Handlers ************
--[[
Some actions trigger multiple events in sequence:
Instant Shot while either moving or in middle of reload
-> (hook) OnInstant
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
Instant Shot as Auto Shot fires (assuming state is already shooting)
-> (hook) OnInstant
-> ITEM_LOCK_CHANGED
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
Casted Shot starts as Auto Shot fires (assuming state is already shooting)
-> (hook) OnCast
-> ITEM_LOCK_CHANGED
-> ITEM_LOCK_CHANGED
-> SPELLCAST_STOP
]]
local EVENTS = {
	"CHAT_MSG_SPELL_SELF_BUFF",-- To ignore whitelisted inventory events corresponding to consumables
	"ITEM_LOCK_CHANGED",-- Inventory event, such as using ammo
	-- Spellcast events can also fire when spell succeedes, but we drop target after starting cast
	"SPELLCAST_DELAYED",-- Pushback
	"SPELLCAST_FAILED",-- Spell on CD or already in progress
	"SPELLCAST_INTERRUPTED",-- Knockback etc.
	"SPELLCAST_STOP",
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
		-- We fired a cast or instant but haven't yet called "SPELLCAST_STOP"
		-- If we fired an Auto Shot at the same time, then "ITEM_LOCK_CHANGED" will
		-- get called twice before "SPELLCAST_STOP", so we mark the first one as done
			isFiredInstant = false
		elseif isCasting then
			local ellapsed = GetTime() - timeStartCast
			if isShooting and ellapsed < castTime then
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

-- ************ Initialization ************
local onEnable = function()
	if frame == nil then frame = createUI() end
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
	ResetUI = function()
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.ColorShoot = store.ColorShoot or QUIVER.Color.AutoAttackDefaultShoot
		store.ColorReload = store.ColorReload or QUIVER.Color.AutoAttackDefaultReload
		store.FrameMeta = store.FrameMeta or {}
	end,
	OnSavedVariablesPersist = function() return store end,
}
