local MODULE_ID = "AspectTracker"
local store = nil
local frame = nil

local DEFAULT_ICON_SIZE = 40
local BORDER_SIZE = 4
local TRANSPARENCY = 0.5

local chooseIconTexture = function()
	if Quiver_Lib_Aura_GetIsBuffActive(QUIVER_T.Spellbook.Aspect_Beast) then
		return QUIVER.Icon.Aspect_Beast
	elseif Quiver_Lib_Aura_GetIsBuffActive(QUIVER_T.Spellbook.Aspect_Cheetah) then
		return QUIVER.Icon.Aspect_Cheetah
	elseif Quiver_Lib_Aura_GetIsBuffActive(QUIVER_T.Spellbook.Aspect_Monkey) then
		return QUIVER.Icon.Aspect_Monkey
	elseif Quiver_Lib_Aura_GetIsBuffActive(QUIVER_T.Spellbook.Aspect_Wild) then
		return QUIVER.Icon.Aspect_Wild
	elseif Quiver_Lib_Aura_GetIsBuffActive(QUIVER_T.Spellbook.Aspect_Wolf) then
		return QUIVER.Icon.Aspect_Wolf
	elseif Quiver_Lib_Spellbook_GetIsSpellLearned(QUIVER_T.Spellbook.Aspect_Hawk)
		and not Quiver_Lib_Aura_GetIsBuffActive(QUIVER_T.Spellbook.Aspect_Hawk)
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
	if Quiver_Lib_Aura_GetIsBuffActive(QUIVER_T.Spellbook.Aspect_Pack) then
		frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 16,
			insets = { left=BORDER_SIZE, right=BORDER_SIZE, top=BORDER_SIZE, bottom=BORDER_SIZE },
		})
		frame:SetBackdropBorderColor(0.8, 0.9, 1.0, 1.0)
	else
		frame:SetBackdrop({ bgFile = "Interface/BUTTONS/WHITE8X8", tile = false })
	end
	frame:SetBackdropColor(0, 0, 0, 0)
end

local sizeIconSize = function(f)
	f.Icon:SetWidth(f:GetWidth() - BORDER_SIZE * 2)
	f.Icon:SetHeight(f:GetHeight() - BORDER_SIZE * 2)
	f.Icon:SetPoint("Center", 0, 0)
end

local setFramePosition = function(f, s)
	s.FrameMeta = Quiver_Event_FrameLock_RestoreSize(s.FrameMeta, {
		w=DEFAULT_ICON_SIZE,
		h=DEFAULT_ICON_SIZE,
		dx=DEFAULT_ICON_SIZE * -0.5,
		dy=DEFAULT_ICON_SIZE * -0.5,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
	sizeIconSize(f)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("Low")
	f.Icon = CreateFrame("Frame", nil, f)

	setFramePosition(f, store)
	local resizeIcon = function() sizeIconSize(f) end
	Quiver_Event_FrameLock_MakeMoveable(f, store.FrameMeta)
	Quiver_Event_FrameLock_MakeResizeable(f, store.FrameMeta, {
		GripMargin=0,
		OnResizeDrag=resizeIcon,
		OnResizeEnd=resizeIcon,
	})
	return f
end

-- ************ Event Handlers ************
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

Quiver_Module_AspectTracker = {
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
		store.FrameMeta = store.FrameMeta or {}
	end,
	OnSavedVariablesPersist = function() return store end,
}
