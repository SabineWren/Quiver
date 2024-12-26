local Api = require "Api/Index.lua"
local Const = require "Constants.lua"
local FrameLock = require "Events/FrameLock.lua"
local Spellcast = require "Events/Spellcast.lua"

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
	for _i, v in ipairs(_EVENTS) do frame:RegisterEvent(v) end
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
	for _i, v in ipairs(_EVENTS) do frame:UnregisterEvent(v) end
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
