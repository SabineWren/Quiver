local L = require "Lib/Index.lua"
local Const = require "Constants.lua"
local FrameLock = require "Events/FrameLock.lua"
local Spellcast = require "Events/Spellcast.lua"
local BorderStyle = require "Modules/BorderStyle.provider.lua"
local Haste = require "Util/Haste.lua"

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
	local fontSize = L.Clamp(10, 18)(f:GetHeight() - sizeInset - textMargin)

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
	for _i, v in ipairs(_EVENTS) do frame:RegisterEvent(v) end
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
		for _i, v in ipairs(_EVENTS) do frame:UnregisterEvent(v) end
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
