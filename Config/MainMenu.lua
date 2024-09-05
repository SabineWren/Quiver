local Button = require "Component/Button.lua"
local CheckButton = require "Component/CheckButton.lua"
local Dialog = require "Component/Dialog.lua"
local Select = require "Component/Select.lua"
local Switch = require "Component/Switch.lua"
local TitleBox = require "Component/TitleBox.lua"
local Color = require "Config/Color.lua"
local InputText = require "Config/InputText.lua"
local FrameLock = require "Events/FrameLock.lua"
local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local TranqAnnouncer = require "Modules/TranqAnnouncer.lua"
local L = require "Shiver/Lib/All.lua"

local createModuleControls = function(parent, m)
	local f = CreateFrame("Frame", nil, parent)

	local btnReset = Button:Create(f, {
		TexPath = QUIVER.Icon.Reset,
		TooltipText = QUIVER_T.UI.ResetFramesTooltip,
	})
	btnReset.OnClick = function() m.OnResetFrames() end
	if not Quiver_Store.ModuleEnabled[m.Id] then
		btnReset:ToggleEnabled(false)
	end

	local switch = Switch:Create(f, {
		IsChecked = Quiver_Store.ModuleEnabled[m.Id],
		LabelText = m.Name,
		TooltipText = QUIVER_T.ModuleTooltip[m.Id],
		OnChange = function (isChecked)
			Quiver_Store.ModuleEnabled[m.Id] = isChecked
			if isChecked then
				m.OnEnable()
			else
				m.OnDisable()
			end
			btnReset:ToggleEnabled(isChecked)
		end,
	})

	local x = 0
	local gap = 8
	btnReset.Container:SetPoint("Left", f, "Left", x, 0)
	x = x + btnReset.Container:GetWidth() + gap
	switch.Container:SetPoint("Left", f, "Left", x, 0)
	x = x + switch.Container:GetWidth()

	f:SetHeight(switch.Container:GetHeight())
	f:SetWidth(x)
	return f
end

local createAllModuleControls = function(parent, gap)
	local f = CreateFrame("Frame", nil, parent)
	local frames = L.Array.Mapi(_G.Quiver_Modules, function(m, i)
		local frame = createModuleControls(f, m)
		local yOffset = i * (frame:GetHeight() + gap)
		frame:SetPoint("Left", f, "Left", 0, 0)
		frame:SetPoint("Top", f, "Top", 0, -yOffset)
		return frame
	end)

	local maxWidths =
		L.Array.MapReduce(frames, function(x) return x:GetWidth() end, math.max, 0)
	local totalHeight =
		L.Array.MapReduce(frames, function(x) return x:GetHeight() + gap end, L.Add, 0)
		- gap
	f:SetHeight(totalHeight)
	f:SetWidth(maxWidths)

	return f
end

local Create = function()
	-- WoW uses border-box content sizing
	local _PADDING_CLOSE = QUIVER.Size.Border + 6
	local _PADDING_FAR = QUIVER.Size.Border + QUIVER.Size.Gap
	local dialog = Dialog.Create(_PADDING_CLOSE)

	local titleText = "Quiver " .. GetAddOnMetadata("Quiver", "Version")
	local titleBox = TitleBox.Create(dialog, titleText)
	titleBox:SetPoint("Center", dialog, "Top", 0, -10)

	local btnCloseTop = Button:Create(dialog, {
		TexPath = QUIVER.Icon.XMark,
		TooltipText = QUIVER_T.UI.CloseWindowTooltip,
	})
	btnCloseTop.OnClick = function() dialog:Hide() end
	btnCloseTop.Container:SetPoint("TopRight", dialog, "TopRight", -_PADDING_CLOSE, -_PADDING_CLOSE)

	local btnToggleLock = CheckButton:Create(dialog, {
		IsChecked = Quiver_Store.IsLockedFrames,
		OnChange = function(isLocked) FrameLock.SetIsLocked(isLocked) end,
		TexPathOff = QUIVER.Icon.LockOpen,
		TexPathOn = QUIVER.Icon.LockClosed,
		TooltipText=QUIVER_T.UI.FrameLockToggleTooltip,
	})
	FrameLock.Init()

	local lockOffsetX = _PADDING_CLOSE + QUIVER.Size.Icon + QUIVER.Size.Gap/2
	btnToggleLock.Icon:SetPoint("TopRight", dialog, "TopRight", -lockOffsetX, -_PADDING_CLOSE)

	local btnResetFrames = Button:Create(dialog, {
		TexPath = QUIVER.Icon.Reset,
		TooltipText = QUIVER_T.UI.ResetFramesTooltipAll,
	})
	btnResetFrames.OnClick = function()
		for _k, v in _G.Quiver_Modules do v.OnResetFrames() end
	end
	local resetOffsetX = lockOffsetX + btnResetFrames.Container:GetWidth() + QUIVER.Size.Gap/2
	btnResetFrames.Container:SetPoint("TopRight", dialog, "TopRight", -resetOffsetX, -_PADDING_CLOSE)

	local controls = createAllModuleControls(dialog, QUIVER.Size.Gap)
	local colorPickers = Color.Create(dialog, QUIVER.Size.Gap)

	local yOffset = -_PADDING_CLOSE - QUIVER.Size.Icon - QUIVER.Size.Gap
	controls:SetPoint("Top", dialog, "Top", 0, yOffset)
	controls:SetPoint("Left", dialog, "Left", _PADDING_FAR, 0)
	colorPickers:SetPoint("Top", dialog, "Top", 0, yOffset)
	colorPickers:SetPoint("Right", dialog, "Right", -_PADDING_FAR, 0)
	dialog:SetWidth(_PADDING_FAR + controls:GetWidth() + _PADDING_FAR + colorPickers:GetWidth() + _PADDING_FAR)

	local dropdownX = _PADDING_FAR + colorPickers:GetWidth() + _PADDING_FAR
	local dropdownY = 0

	local selectDebugLevel = Select.Create(dialog,
		"Debug Level",
		{ "None", "Verbose" },
		Quiver_Store.DebugLevel,
		function(text)
			Quiver_Store.DebugLevel = text
		end
	)
	dropdownY = yOffset - colorPickers:GetHeight() + selectDebugLevel:GetHeight() + QUIVER.Size.Gap
	selectDebugLevel:SetPoint("Right", dialog, "Right", -dropdownX, 0)
	selectDebugLevel:SetPoint("Top", dialog, "Top", 0, dropdownY)

	-- Dropdown auto shot bar direction
	local selectAutoShotTimerDirection = Select.Create(dialog,
		QUIVER_T.ModuleName.AutoShotTimer,
		{ QUIVER_T.AutoShot.LeftToRight, QUIVER_T.AutoShot.BothDirections },
		QUIVER_T.AutoShot[Quiver_Store.ModuleStore[AutoShotTimer.Id].BarDirection],
		function(text)
			-- Maps from localized text to binary key
			local direction = text == QUIVER_T.AutoShot.LeftToRight and "LeftToRight" or "BothDirections"
			Quiver_Store.ModuleStore[AutoShotTimer.Id].BarDirection = direction
			AutoShotTimer.UpdateDirection()
		end
	)
	dropdownY = dropdownY + QUIVER.Size.Gap + selectAutoShotTimerDirection:GetHeight()
	selectAutoShotTimerDirection:SetPoint("Right", dialog, "Right", -dropdownX, 0)
	selectAutoShotTimerDirection:SetPoint("Top", dialog, "Top", 0, dropdownY)

	-- Dropdown tranq shot announce channel
	local defaultTranqText = (function()
		local store = Quiver_Store.ModuleStore[TranqAnnouncer.Id]
		-- TODO DRY violation -- dropdown must match the module store init
		return store and store.TranqChannel or "/Say"
	end)()
	local selectChannelHit = Select.Create(dialog,
		"Tranq Speech",
		{ "None", "/Say", "/Raid" },
		defaultTranqText,
		function(text)
			-- TODO Keys aren't localized, so right now we don't need to map option text to key
			Quiver_Store.ModuleStore[TranqAnnouncer.Id].TranqChannel = text or "/Say"
		end
	)
	dropdownY = dropdownY + QUIVER.Size.Gap + selectChannelHit:GetHeight()
	selectChannelHit:SetPoint("Right", dialog, "Right", -dropdownX, 0)
	selectChannelHit:SetPoint("Top", dialog, "Top", 0, dropdownY)

	local hLeft = controls:GetHeight()
	local hRight = colorPickers:GetHeight()
	local hMax = hRight > hLeft and hRight or hLeft
	yOffset = yOffset - hMax - QUIVER.Size.Gap

	local tranqOptions = InputText.Create(dialog, QUIVER.Size.Gap)
	tranqOptions:SetPoint("TopLeft", dialog, "TopLeft", 0, yOffset)
	yOffset = yOffset - tranqOptions:GetHeight()
	yOffset = yOffset - QUIVER.Size.Gap

	dialog:SetHeight(-1 * yOffset + _PADDING_CLOSE + QUIVER.Size.Button)
	return dialog
end

return {
	Create = Create,
}
