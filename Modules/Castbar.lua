local MODULE_ID = "Castbar"
local frameMeta = {}
local frame = nil
local maxBarWidth = 0
local BORDER = 1

local castTime = 0
local isCasting = false
local timeStartCasting = 0

-- ************ UI ************
local updateCastbarSize = function()
	maxBarWidth = frameMeta.W - 2 * BORDER
	frame.Castbar:SetWidth(1)
	frame.SpellName:SetWidth(maxBarWidth)
	frame.SpellTime:SetWidth(maxBarWidth)

	local path, _size, flags = frame.SpellName:GetFont()
	local calcFontSize = frameMeta.H - 4 * BORDER
	local fontSize = calcFontSize > 18 and 18
		or calcFontSize < 10 and 10
		or calcFontSize

	frame.SpellName:SetFont(path, fontSize, flags)
	frame.SpellTime:SetFont(path, fontSize, flags)
end
local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("HIGH")
	local centerVertically = function(ele)
		ele:SetPoint("Top", f, "Top", 0, -1 * BORDER)
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
	f.Castbar:SetBackdropColor(0.42 ,0.41 ,0.53, 1)

	centerVertically(f.Castbar)
	centerVertically(f.SpellTime)
	centerVertically(f.SpellName)

	Quiver_Event_FrameLock_MakeMoveable(f, frameMeta)
	Quiver_Event_FrameLock_MakeResizeable(f, frameMeta,
		{ GripMargin=0, OnResizeEnd=updateCastbarSize })
	return f
end

-- ************ Custom Event Handlers ************
local displayTime = function(current)
	if current < 0 then current = 0 end
	frame.SpellTime:SetText(string.format("%.1f / %.1f", current, castTime))
end
local onSpellcast = function(spellName)
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
	Quiver_Event_Spellcast_Subscribe(MODULE_ID, onSpellcast)
end
local onDisable = function()
	Quiver_Event_Spellcast_Unsubscribe(MODULE_ID)
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

Quiver_Module_Castbar = {
	Id = MODULE_ID,
	OnRestoreSavedVariables = function(savedVariables, savedFrameMeta)
		frameMeta = savedFrameMeta
		local defaultWidth = 240
		frameMeta.W = frameMeta.W or defaultWidth
		frameMeta.H = frameMeta.H or 20
		frameMeta.X = frameMeta.X or (GetScreenWidth() - defaultWidth) / 2
		frameMeta.Y = frameMeta.Y or -1 * GetScreenHeight() + 268
	end,
	OnPersistSavedVariables = function() return {} end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() if not isCasting then frame:Hide() end end,
	OnInterfaceUnlock = function() frame:Show() end,
}
