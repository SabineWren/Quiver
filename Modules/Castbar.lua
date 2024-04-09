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
	Quiver_Event_FrameLock_SideEffectRestoreSize(s, {
		w=240, h=20, dx=240 * -0.5, dy=-116,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
	setCastbarSize(f, s)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("High")
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
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
		edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = BORDER,
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
	Quiver_Event_FrameLock_SideEffectMakeMoveable(f, store)
	Quiver_Event_FrameLock_SideEffectMakeResizeable(f, store, {
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
local onSpellcast = function(spellName)
	if isCasting then return end
	isCasting = true
	local _timeStartLocal
	castTime, timeStartCasting, _timeStartLocal = Quiver_Lib_Spellbook_CalcCastTime(spellName)
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
	Quiver_Event_Spellcast_CastableShot.Subscribe(MODULE_ID, onSpellcast)
end
local onDisable = function()
	Quiver_Event_Spellcast_CastableShot.Dispose(MODULE_ID)
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

Quiver_Module_Castbar = {
	Id = MODULE_ID,
	Name = QUIVER_T.ModuleName[MODULE_ID],
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
