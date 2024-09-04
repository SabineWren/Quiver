local Button = require "Components/Button.lua"
local Dialog = require "Components/Dialog.lua"
local Select = require "Component/Select.lua"
local Switch = require "Component/Switch.lua"
local TitleBox = require "Components/TitleBox.lua"
local Color = require "Config/Color.lua"
local InputText = require "Config/InputText.lua"
local FrameLock = require "Events/FrameLock.lua"
local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local TranqAnnouncer = require "Modules/TranqAnnouncer.lua"
local L = require "Shiver/Lib/All.lua"

local createIconBtnLock = function(parent)
	local f = Button.Create({
		Parent=parent,
		Size=QUIVER.Size.Icon,
		TooltipText=QUIVER_T.UI.FrameLockToggleTooltip,
	})
	local updateTexture = function()
		local path = Quiver_Store.IsLockedFrames
			and QUIVER.Icon.LockClosed
			or QUIVER.Icon.LockOpen
		f.Texture:QuiverSetTexture(1, path)
	end
	updateTexture()
	f:SetScript("OnClick", function(_self)
		FrameLock.SetIsLocked(not Quiver_Store.IsLockedFrames)
		updateTexture()
	end)
	FrameLock.Init()
	return f
end

local createIconResetAll = function(parent)
	local f = Button.Create({
		Parent=parent, Size=QUIVER.Size.Icon,
		TooltipText=QUIVER_T.UI.ResetFramesTooltipAll,
	})
	f.Texture:QuiverSetTexture(0.75, QUIVER.Icon.Reset)
	f:SetScript("OnClick", function(_self)
		for _k, v in _G.Quiver_Modules do v.OnResetFrames() end
	end)
	return f
end

local createModuleControls = function(parent, m)
	local f = CreateFrame("Frame", nil, parent)

	local btnReset = Button.Create({
		Parent=f,
		Size=QUIVER.Size.Icon,
		TooltipText=QUIVER_T.UI.ResetFramesTooltip,
	})
	btnReset.Texture:QuiverSetTexture(0.75, QUIVER.Icon.Reset)
	btnReset:SetScript("OnClick", function(_self) m.OnResetFrames() end)

	if not Quiver_Store.ModuleEnabled[m.Id] then
		btnReset.QuiverDisable()
	end

	local switch = Switch.Create(f, {
		Gap = 6,
		IsChecked = Quiver_Store.ModuleEnabled[m.Id],
		LabelText = m.Name,
		TooltipText = QUIVER_T.ModuleTooltip[m.Id],
		OnChange = function (isChecked)
			Quiver_Store.ModuleEnabled[m.Id] = isChecked
			if isChecked then
				m.OnEnable()
				btnReset.QuiverEnable()
			else
				m.OnDisable()
				btnReset.QuiverDisable()
			end
		end,
	})

	local x = 0
	local gap = 8
	btnReset:SetPoint("Left", f, "Left", x, 0)
	x = x + btnReset:GetWidth() + gap
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
	local PADDING_CLOSE = QUIVER.Size.Border + 4
	local PADDING_FAR = QUIVER.Size.Border + QUIVER.Size.Gap
	local f = Dialog.Create(PADDING_CLOSE)
	f:SetFrameStrata("DIALOG")

	local titleBox = TitleBox.Create(f)
	titleBox:SetPoint("Center", f, "Top", 0, -10)

	local btnCloseTop = Button.Create({
		Parent=f, Size=QUIVER.Size.Icon,
		TooltipText=QUIVER_T.UI.CloseWindowTooltip })
	btnCloseTop.Texture:QuiverSetTexture(0.7, QUIVER.Icon.XMark)
	btnCloseTop:SetPoint("TopRight", f, "TopRight", -PADDING_CLOSE, -PADDING_CLOSE)
	btnCloseTop:SetScript("OnClick", function() f:Hide() end)

	local btnToggleLock = createIconBtnLock(f)
	local lockOffsetX = PADDING_CLOSE + QUIVER.Size.Icon + QUIVER.Size.Gap/2
	btnToggleLock:SetPoint("TopRight", f, "TopRight", -lockOffsetX, -PADDING_CLOSE)

	local btnResetFrames = createIconResetAll(f)
	local resetOffsetX = lockOffsetX + QUIVER.Size.Icon + QUIVER.Size.Gap/2
	btnResetFrames:SetPoint("TopRight", f, "TopRight", -resetOffsetX, -PADDING_CLOSE)

	local controls = createAllModuleControls(f, QUIVER.Size.Gap)
	local colorPickers = Color.Create(f, QUIVER.Size.Gap)

	local yOffset = -PADDING_CLOSE - QUIVER.Size.Icon - QUIVER.Size.Gap
	controls:SetPoint("Top", f, "Top", 0, yOffset)
	controls:SetPoint("Left", f, "Left", PADDING_FAR, 0)
	colorPickers:SetPoint("Top", f, "Top", 0, yOffset)
	colorPickers:SetPoint("Right", f, "Right", -PADDING_FAR, 0)
	f:SetWidth(PADDING_FAR + controls:GetWidth() + PADDING_FAR + colorPickers:GetWidth() + PADDING_FAR)

	local dropdownX = PADDING_FAR + colorPickers:GetWidth() + PADDING_FAR
	local dropdownY = 0

	local selectDebugLevel = Select.Create(f,
		"Debug Level",
		{ "None", "Verbose" },
		Quiver_Store.DebugLevel,
		function(text)
			Quiver_Store.DebugLevel = text
		end
	)
	dropdownY = yOffset - colorPickers:GetHeight() + selectDebugLevel:GetHeight() + QUIVER.Size.Gap
	selectDebugLevel:SetPoint("Right", f, "Right", -dropdownX, 0)
	selectDebugLevel:SetPoint("Top", f, "Top", 0, dropdownY)

	-- Dropdown auto shot bar direction
	local selectAutoShotTimerDirection = Select.Create(f,
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
	selectAutoShotTimerDirection:SetPoint("Right", f, "Right", -dropdownX, 0)
	selectAutoShotTimerDirection:SetPoint("Top", f, "Top", 0, dropdownY)

	-- Dropdown tranq shot announce channel
	local defaultTranqText = (function()
		local store = Quiver_Store.ModuleStore[TranqAnnouncer.Id]
		-- TODO DRY violation -- dropdown must match the module store init
		return store and store.TranqChannel or "/Say"
	end)()
	local selectChannelHit = Select.Create(f,
		"Tranq Speech",
		{ "None", "/Say", "/Raid" },
		defaultTranqText,
		function(text)
			-- TODO Keys aren't localized, so right now we don't need to map option text to key
			Quiver_Store.ModuleStore[TranqAnnouncer.Id].TranqChannel = text or "/Say"
		end
	)
	dropdownY = dropdownY + QUIVER.Size.Gap + selectChannelHit:GetHeight()
	selectChannelHit:SetPoint("Right", f, "Right", -dropdownX, 0)
	selectChannelHit:SetPoint("Top", f, "Top", 0, dropdownY)

	local hLeft = controls:GetHeight()
	local hRight = colorPickers:GetHeight()
	local hMax = hRight > hLeft and hRight or hLeft
	yOffset = yOffset - hMax - QUIVER.Size.Gap

	local tranqOptions = InputText.Create(f, QUIVER.Size.Gap)
	tranqOptions:SetPoint("TopLeft", f, "TopLeft", 0, yOffset)
	yOffset = yOffset - tranqOptions:GetHeight()
	yOffset = yOffset - QUIVER.Size.Gap

	f:SetHeight(-1 * yOffset + PADDING_CLOSE + QUIVER.Size.Button)
	return f
end

return {
	Create = Create,
}
