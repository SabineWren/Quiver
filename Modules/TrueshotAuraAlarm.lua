local MODULE_ID = "TrueshotAuraAlarm"
local store = nil
local frame = nil

local UPDATE_DELAY = 5-- used for tracking time remaining
local DEFAULT_ICON_SIZE = 48
local MINUTES_LEFT_WARNING = 5

-- ************ State ************
local aura = (function()
	local knowsAura, isActive, lastUpdate, timeLeft = false, false, 1800, 0
	return {
		ShouldUpdate = function(elapsed)
			lastUpdate = lastUpdate + elapsed
			return knowsAura and lastUpdate > UPDATE_DELAY
		end,
		UpdateUI = function()
			knowsAura = Quiver_Lib_Spellbook_GetIsSpellLearned(QUIVER_T.Spellbook.TrueshotAura)
				or not Quiver_Store.IsLockedFrames
			isActive, timeLeft = Quiver_Lib_Aura_GetIsActiveTimeLeftByTexture(QUIVER.Icon.Trueshot)
			lastUpdate = 0

			if not Quiver_Store.IsLockedFrames or knowsAura and not isActive then
				frame.Icon:SetAlpha(0.75)
				frame:SetBackdropColor(0.8, 0, 0, 0.8)
			elseif knowsAura and isActive and timeLeft < MINUTES_LEFT_WARNING * 60 then
				frame.Icon:SetAlpha(0.4)
				frame:SetBackdropColor(0, 0, 0, 0.1)
			else
				frame.Icon:SetAlpha(0.0)
				frame:SetBackdropColor(0, 0, 0, 0)
			end
		end,
	}
end)()

-- ************ UI ************
local resizeIcon = function()
	frame.Icon:SetWidth(frame:GetWidth())
	frame.Icon:SetHeight(frame:GetHeight())
	frame.Icon:SetPoint("Center", 0, 0)
end
local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetFrameStrata("HIGH")
	f:SetBackdrop({ bgFile = "Interface/BUTTONS/WHITE8X8", tile = false })

	f.Icon = CreateFrame("Frame", nil, f)
	f.Icon:SetWidth(store.FrameMeta.W)
	f.Icon:SetHeight(store.FrameMeta.H)
	f.Icon:SetPoint("Center", 0, 0)
	f.Icon:SetBackdrop({ bgFile = QUIVER.Icon.Trueshot, tile = false })

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
	for _k, e in EVENTS do frame:RegisterEvent(e) end
	frame:Show()
	aura.UpdateUI()
	Quiver_Event_Spellcast_Instant.Subscribe(MODULE_ID, function(spellName)
		if spellName == QUIVER_T.Spellbook.TrueshotAura then
			aura.UpdateUI()
		end
	end)
end
local onDisable = function()
	Quiver_Event_Spellcast_Instant.Dispose(MODULE_ID)
	frame:Hide()
	for _k, e in EVENTS do frame:UnregisterEvent(e) end
end

Quiver_Module_TrueshotAuraAlarm = {
	Id = MODULE_ID,
	Name = QUIVER_T.ModuleName[MODULE_ID],
	OnInitFrames = function(options)
		if options.IsReset then store.FrameMeta = nil end
		store.FrameMeta = Quiver_Event_FrameLock_RestoreSize(store.FrameMeta, {
			w=DEFAULT_ICON_SIZE,
			h=DEFAULT_ICON_SIZE,
			dx=DEFAULT_ICON_SIZE * -0.5,
			dy=DEFAULT_ICON_SIZE * -0.5,
		})
		if frame ~= nil then
			frame:SetWidth(store.FrameMeta.W)
			frame:SetHeight(store.FrameMeta.H)
			frame:SetPoint("TopLeft", store.FrameMeta.X, store.FrameMeta.Y)
			resizeIcon()
		end
	end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() aura.UpdateUI() end,
	OnInterfaceUnlock = function() aura.UpdateUI() end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.FrameMeta = store.FrameMeta or {}
	end,
	OnSavedVariablesPersist = function() return store end,
}
