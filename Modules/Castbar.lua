local MODULE_ID = "Castbar"
local store
local frame = nil
local maxBarWidth = 0
local BORDER = 1

local castTime = 0
local isCasting = false
local timeStartCasting = 0

-- ************ UI ************
local updateCastbarSize = function()
	maxBarWidth = store.FrameMeta.W - 2 * BORDER
	frame.Castbar:SetWidth(1)
	frame.SpellName:SetWidth(maxBarWidth)
	frame.SpellTime:SetWidth(maxBarWidth)

	local path, _size, flags = frame.SpellName:GetFont()
	local calcFontSize = store.FrameMeta.H - 4 * BORDER
	local fontSize = calcFontSize > 18 and 18
		or calcFontSize < 10 and 10
		or calcFontSize

	frame.SpellName:SetFont(path, fontSize, flags)
	frame.SpellTime:SetFont(path, fontSize, flags)
end

local createUI = function()
	local fCastbar = CreateFrame("Frame", nil, UIParent)
	fCastbar:SetFrameStrata("HIGH")
	local centerVertically = function(ele)
		ele:SetPoint("Top", fCastbar, "Top", 0, -1 * BORDER)
		ele:SetPoint("Bottom", fCastbar, "Bottom", 0, BORDER)
	end

	fCastbar.Castbar = CreateFrame("Frame", nil, fCastbar)
	fCastbar.Castbar:SetPoint("Left", fCastbar, "Left", BORDER, 0)

	fCastbar.SpellName = fCastbar.Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fCastbar.SpellName:SetPoint("Left", fCastbar, "Left", 4*BORDER, 0)
	fCastbar.SpellName:SetJustifyH("Left")
	fCastbar.SpellName:SetTextColor(1, 1, 1)

	fCastbar.SpellTime = fCastbar.Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fCastbar.SpellTime:SetPoint("Right", fCastbar, "Right", -4*BORDER, 0)
	fCastbar.SpellTime:SetJustifyH("Right")
	fCastbar.SpellTime:SetTextColor(1, 1, 1)

	fCastbar:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
		edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = BORDER,
	})
	fCastbar.Castbar:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
	})
	fCastbar:SetBackdropColor(0, 0, 0, 0.8)
	fCastbar:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
	fCastbar.Castbar:SetBackdropColor(0.42 ,0.41 ,0.53, 1)

	centerVertically(fCastbar.Castbar)
	centerVertically(fCastbar.SpellTime)
	centerVertically(fCastbar.SpellName)

	Quiver_Event_FrameLock_MakeMoveable(fCastbar, store.FrameMeta)
	Quiver_Event_FrameLock_MakeResizeable(fCastbar, store.FrameMeta, {
		GripMargin=0,
		OnResizeEnd=updateCastbarSize,
		IsCenterX=true,
	})
	return fCastbar
end

-- ************ Custom Event Handlers ************
local displayTime = function(current)
	if current < 0 then current = 0 end
	frame.SpellTime:SetText(string.format("%.1f / %.1f", current, castTime))
end
local onSpellcast = function(spellName)
	if isCasting then return end
	isCasting = true
	castTime, timeStartCasting = Quiver_Lib_Spellbook_GetCastTime(spellName)
	frame.SpellName:SetText(spellName)
	frame.Castbar:SetWidth(1)
	displayTime(0)
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
	updateCastbarSize()
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	if Quiver_Store.IsLockedFrames then frame:Hide() else frame:Show() end
	Quiver_Event_CastableShot_Subscribe(MODULE_ID, onSpellcast)
end
local onDisable = function()
	Quiver_Event_CastableShot_Unsubscribe(MODULE_ID)
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

Quiver_Module_Castbar = {
	Id = MODULE_ID,
	OnInitFrames = function(options)
		local defaultOf = function(val, fallback)
			if options.IsReset or val == nil then return fallback else return val end
		end
		local width = 240
		store.FrameMeta.W = defaultOf(store.FrameMeta.W, width)
		store.FrameMeta.H = defaultOf(store.FrameMeta.H, 20)
		store.FrameMeta.X = defaultOf(store.FrameMeta.X, (GetScreenWidth() - width) / 2)
		store.FrameMeta.Y = defaultOf(store.FrameMeta.Y, -1 * GetScreenHeight() + 268)
		if frame ~= nil then
			frame:SetPoint("TopLeft", store.FrameMeta.X, store.FrameMeta.Y)
			updateCastbarSize()
		end
	end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() if not isCasting then frame:Hide() end end,
	OnInterfaceUnlock = function() frame:Show() end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.FrameMeta = store.FrameMeta or {}
	end,
	OnSavedVariablesPersist = function() return {} end,
}
