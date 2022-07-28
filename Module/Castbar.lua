local frameMeta = {}
local frame = nil
local maxBarWidth = 0
local borderSize = 1

local castTime = 0
local isCasting = false
local timeStartCasting = 0

-- ************ UI ************
local updateCastbarSize = function()
	maxBarWidth = frameMeta.W - 2 * borderSize
	frame.Castbar:SetWidth(1)
	frame.Castbar:SetHeight(frameMeta.H - 2 * borderSize)
	frame.Castbar:Show()
end
local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("HIGH")
	f.Castbar = CreateFrame("Frame", nil, f)
	Quiver_UI_FrameMeta_Customize(f, frameMeta, { GripMargin=0 })
	f.QuiverOnResizeStart = function() frame.Castbar:Hide() end
	f.QuiverOnResizeEnd = updateCastbarSize

	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
		edgeFile = "Interface/BUTTONS/WHITE8X8", edgeSize = borderSize,
	})
	f.Castbar:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8", tile = false,
	})
	f:SetBackdropColor(0, 0, 0, 0.8)
	f:SetBackdropBorderColor(1, 1, 1, 0.8)
	f.Castbar:SetBackdropColor(0.42 ,0.41 ,0.53, 1)

	f.Castbar:SetPoint("Left", f, "Left", 0, 0)
	return f
end

-- ************ Custom Event Handlers ************
local onSpellcast = function(spellName)
	if not Quiver_Store.ModuleEnabled.Castbar or isCasting then return end
	isCasting = true
	timeStartCasting = GetTime()
	castTime = Quiver_Lib_Spellbook_GetCastTime(spellName)
	frame.Castbar:SetWidth(1)
	frame:Show()
end
Quiver_Events_Spellcast_Subscribe(onSpellcast)

-- ************ Frame Update Handlers ************
local handleUpdate = function()
	local timePassed = GetTime() - timeStartCasting
	if not isCasting then
		frame.Castbar:SetWidth(1)
	elseif timePassed <= castTime then
		frame.Castbar:SetWidth(maxBarWidth * timePassed / castTime)
	else
		frame.Castbar:SetWidth(maxBarWidth)
	end
end

-- ************ Event Handlers ************
local handleEvent = function()
	if event == "SPELLCAST_DELAYED" then
		castTime = castTime + arg1 / 1000
	elseif event == "SPELLCAST_STOP" then
		isCasting = false
		if Quiver_Store.IsLockedFrames then frame:Hide() end
	end
end

-- ************ Initialization ************
local events = {
	"SPELLCAST_STOP",
	"SPELLCAST_DELAYED",
}
local onEnable = function()
	if frame == nil then frame = createUI(); updateCastbarSize() end
	updateCastbarSize()
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in events do frame:RegisterEvent(e) end
	frame:Show()
	if not Quiver_Store.IsLockedFrames then frame:Show() end
end
local onDisable = function()
	frame:Hide()
	for _k, e in events do frame:UnregisterEvent(e) end
end

Quiver_Module_Castbar = {
	Id = "Castbar",
	OnRestoreSavedVariables = function(savedVariables, savedFrameMeta)
		frameMeta = savedFrameMeta
		local defaultWidth = 240
		frameMeta.W = frameMeta.W or defaultWidth
		frameMeta.H = frameMeta.H or 14
		frameMeta.X = frameMeta.X or (GetScreenWidth() - defaultWidth) / 2
		frameMeta.Y = frameMeta.Y or -(GetScreenHeight() - 240)
	end,
	OnPersistSavedVariables = function() return {} end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() if not isCasting then frame:Hide() end end,
	OnInterfaceUnlock = function() frame:Show() end,
}
