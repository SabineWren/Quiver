local FrameLock = require "Events/FrameLock.lua"
local Aura = require "Lib/Aura.lua"
local Spellbook = require "Lib/Spellbook.lua"

local MODULE_ID = "AspectTracker"
local store = nil
local frame = nil

local DEFAULT_ICON_SIZE = 40
local INSET = 5
local TRANSPARENCY = 0.5

local chooseIconTexture = function()
	if Aura.PredIsBuffActive(QUIVER_T.Spellbook.Aspect_Beast) then
		return QUIVER.Icon.Aspect_Beast
	elseif Aura.PredIsBuffActive(QUIVER_T.Spellbook.Aspect_Cheetah) then
		return QUIVER.Icon.Aspect_Cheetah
	elseif Aura.PredIsBuffActive(QUIVER_T.Spellbook.Aspect_Monkey) then
		return QUIVER.Icon.Aspect_Monkey
	elseif Aura.PredIsBuffActive(QUIVER_T.Spellbook.Aspect_Wild) then
		return QUIVER.Icon.Aspect_Wild
	elseif Aura.PredIsBuffActive(QUIVER_T.Spellbook.Aspect_Wolf) then
		return QUIVER.Icon.Aspect_Wolf
	elseif Spellbook.GetIsSpellLearned(QUIVER_T.Spellbook.Aspect_Hawk)
		and not Aura.PredIsBuffActive(QUIVER_T.Spellbook.Aspect_Hawk)
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
	if Aura.PredIsBuffActive(QUIVER_T.Spellbook.Aspect_Pack) then
		frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background", tile = false,
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 20,
			insets = { left=INSET, right=INSET, top=INSET, bottom=INSET },
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
	Name = QUIVER_T.ModuleName[MODULE_ID],
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
