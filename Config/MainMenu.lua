local Api = require "Api/Index.lua"
local Button = require "Component/Button.lua"
local Dialog = require "Component/Dialog.lua"
local IconButton = require "Component/IconButton.lua"
local Select = require "Component/Select.lua"
local Switch = require "Component/Switch.lua"
local TitleBox = require "Component/TitleBox.lua"
local Color = require "Config/Color.lua"
local InputText = require "Config/InputText.lua"
local Const = require "Constants.lua"
local FrameLock = require "Events/FrameLock.lua"
local L = require "Lib/Index.lua"
local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local BorderStyle = require "Modules/BorderStyle.provider.lua"
local TranqAnnouncer = require "Modules/TranqAnnouncer.lua"

local createModuleControls = function(parent, m)
	local f = CreateFrame("Frame", nil, parent)

	local btnReset = Button:Create(f, Const.Icon.Reset)
	btnReset.TooltipText = Quiver.T["Reset Frame Size and Position"]
	btnReset.HookClick = function() m.OnResetFrames() end
	if not Quiver_Store.ModuleEnabled[m.Id] then
		btnReset:ToggleEnabled(false)
	end

	local switch = Switch:Create(f, {
		IsChecked = Quiver_Store.ModuleEnabled[m.Id],
		LabelText = m.GetName(),
		TooltipText = m.GetTooltipText(),
		OnChange = function (isChecked)
			Quiver_Store.ModuleEnabled[m.Id] = isChecked
			;(isChecked and m.OnEnable or m.OnDisable)()
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

	local maxWidths = L.Array.MapSeduce(frames, Api._Width, L.Sg.Max, 0)
	local totalHeight = L.Array.MapIntersperseSum(frames, Api._Height, gap)
	f:SetHeight(totalHeight)
	f:SetWidth(maxWidths)

	return f
end

local makeSelectAutoShotTimerDirection = function(parent)
	-- Factored out text until we can re-render options upon locale change.
	-- Otherwise, the change handler with compare wrong locale.
	local both = Quiver.T["Both Directions"]
	local selected = Quiver_Store.ModuleStore[AutoShotTimer.Id].BarDirection
	local options = { Quiver.T["Left to Right"], both }
	return Select:Create(parent,
		Quiver.T["Auto Shot Timer"],
		options,
		Quiver.T[selected],
		function(text)
			-- Reverse map from localized text to saved value
			local direction = text == both and "BothDirections" or "LeftToRight"
			Quiver_Store.ModuleStore[AutoShotTimer.Id].BarDirection = direction
			AutoShotTimer.UpdateDirection()
		end
	)
end

local makeSelectBorderStyle = function(parent)
	local tooltip = Quiver.T["Tooltip"]
	local selected = Quiver_Store.Border_Style
	local options = { Quiver.T["Simple"], tooltip }
	return Select:Create(parent,
		Quiver.T["Border Style"],
		options,
		Quiver.T[selected],
		function(text)
			-- Reverse map from localized text to saved value
			local style = text == tooltip and "Tooltip" or "Simple"
			BorderStyle.ChangeAndPublish(style)
		end
	)
end

local makeSelectChannelHit = function(parent)
	local defaultTranqText = (function()
		local store = Quiver_Store.ModuleStore[TranqAnnouncer.Id]
		-- TODO DRY violation -- dropdown must match the module store init
		return store and store.TranqChannel or "/Say"
	end)()
	return Select:Create(parent,
		Quiver.T["Tranq Speech"],
		{ Quiver.T["None"], "/Say", "/Raid" },
		defaultTranqText,
		function(text)
			local val = (function()
				if text == Quiver.T["None"] then
					return "None"
				else
					return text or "/Say"
				end
			end)()
			Quiver_Store.ModuleStore[TranqAnnouncer.Id].TranqChannel = val
		end
	)
end

local makeSelectDebugLevel = function(parent)
	return Select:Create(parent,
		Quiver.T["Debug Level"],
		{ Quiver.T["None"], Quiver.T["Verbose"] },
		Quiver_Store.DebugLevel == "Verbose" and Quiver.T["Verbose"] or Quiver.T["None"],
		function(text)
			local level = text == Quiver.T["Verbose"] and "Verbose" or "None"
			Quiver_Store.DebugLevel = level
		end
	)
end

---@param frameName string
---@return Frame
---@nodiscard
local Create = function(frameName)
	-- WoW uses border-box content sizing
	local _PADDING_CLOSE = Const.Size.Border + 6
	local _PADDING_FAR = Const.Size.Border + Const.Size.Gap
	local dialog = Dialog.Create(_PADDING_CLOSE, frameName)
	Api.Aero.SetScript(dialog, "OnShow", function()
		PlaySoundFile("Interface\\AddOns\\Quiver\\Assets\\removing_wood_arrow_from_bow_4.wav")
	end)
	Api.Aero.SetScript(dialog, "OnHide", function()
		PlaySoundFile("Interface\\AddOns\\Quiver\\Assets\\sheathing_a_few_arrows_loosely_into_a_quiver_3.wav")
	end)
	-- This allows escape key to close, and preserves frame position.
	table.insert(UISpecialFrames, frameName)

	local titleText = "Quiver " .. GetAddOnMetadata("Quiver", "Version")
	local titleBox = TitleBox.Create(dialog, titleText)
	titleBox:SetPoint("Center", dialog, "Top", 0, -10)

	local btnCloseTop = Button:Create(dialog, Const.Icon.XMark)
	btnCloseTop.TooltipText = Quiver.T["Close Window"]
	btnCloseTop.HookClick = function() dialog:Hide() end
	btnCloseTop.Container:SetPoint("TopRight", dialog, "TopRight", -_PADDING_CLOSE, -_PADDING_CLOSE)

	local btnToggleLock = IconButton:Create(dialog, {
		IsChecked = Quiver_Store.IsLockedFrames,
		OnChange = function(isLocked) FrameLock.SetIsLocked(isLocked) end,
		TexPathOff = Const.Icon.LockOpen,
		TexPathOn = Const.Icon.LockClosed,
		TooltipText = Quiver.T["Lock/Unlock Frames"],
	})
	FrameLock.Init()

	local lockOffsetX = _PADDING_CLOSE + Const.Size.Icon + Const.Size.Gap/2
	btnToggleLock.Icon:SetPoint("TopRight", dialog, "TopRight", -lockOffsetX, -_PADDING_CLOSE)

	local btnResetFrames = Button:Create(dialog, Const.Icon.Reset)
	btnResetFrames.TooltipText = Quiver.T["Reset All Frame Sizes and Positions"]
	btnResetFrames.HookClick = function()
		for _i, v in ipairs(_G.Quiver_Modules) do v.OnResetFrames() end
	end
	local resetOffsetX = lockOffsetX + btnResetFrames.Container:GetWidth() + Const.Size.Gap/2
	btnResetFrames.Container:SetPoint("TopRight", dialog, "TopRight", -resetOffsetX, -_PADDING_CLOSE)

	local controls = createAllModuleControls(dialog, Const.Size.Gap)
	local colorPickers = Color.Create(dialog, Const.Size.Gap)

	local yOffset = -_PADDING_CLOSE - Const.Size.Icon - Const.Size.Gap
	controls:SetPoint("Top", dialog, "Top", 0, yOffset)
	controls:SetPoint("Left", dialog, "Left", _PADDING_FAR, 0)
	colorPickers:SetPoint("Top", dialog, "Top", 0, yOffset)
	colorPickers:SetPoint("Right", dialog, "Right", -_PADDING_FAR, 0)
	dialog:SetWidth(_PADDING_FAR + controls:GetWidth() + _PADDING_FAR + colorPickers:GetWidth() + _PADDING_FAR)

	local ddContainer = CreateFrame("Frame", nil, dialog)
	local selectChannelHit = makeSelectChannelHit(ddContainer)
	local selectAutoShotTimerDirection = makeSelectAutoShotTimerDirection(ddContainer)
	local selectBorderStyle = makeSelectBorderStyle(ddContainer)
	local selectDebugLevel = makeSelectDebugLevel(ddContainer)

	selectChannelHit.Container:SetPoint("Right", ddContainer, "Right")
	selectAutoShotTimerDirection.Container:SetPoint("Right", ddContainer, "Right")
	selectBorderStyle.Container:SetPoint("Right", ddContainer, "Right")
	selectDebugLevel.Container:SetPoint("Right", ddContainer, "Right")

	local dropdownY = 0
	selectChannelHit.Container:SetPoint("Top", ddContainer, "Top", 0, dropdownY)
	dropdownY = dropdownY - Const.Size.Gap - selectChannelHit.Container:GetHeight()

	selectAutoShotTimerDirection.Container:SetPoint("Top", ddContainer, "Top", 0, dropdownY)
	dropdownY = dropdownY - Const.Size.Gap - selectAutoShotTimerDirection.Container:GetHeight()

	selectBorderStyle.Container:SetPoint("Top", ddContainer, "Top", 0, dropdownY)
	dropdownY = dropdownY - Const.Size.Gap - selectBorderStyle.Container:GetHeight()

	selectDebugLevel.Container:SetPoint("Top", ddContainer, "Top", 0, dropdownY)
	dropdownY = dropdownY - selectDebugLevel.Container:GetHeight()

	ddContainer:SetPoint("Top", dialog, "Top", 0, yOffset - controls:GetHeight() - _PADDING_FAR)
	ddContainer:SetPoint("Right", dialog, "Right", -(_PADDING_FAR + colorPickers:GetWidth() + _PADDING_FAR), 0)
	ddContainer:SetHeight(-dropdownY)

	local dropdowns = { selectChannelHit, selectAutoShotTimerDirection, selectBorderStyle, selectDebugLevel }
	local maxWidth = L.Array.MapSeduce(dropdowns, function(x) return x.Container:GetWidth() end, L.Sg.Max, 0)
	ddContainer:SetHeight(-dropdownY)
	ddContainer:SetWidth(maxWidth)

	local hLeft = controls:GetHeight() + _PADDING_FAR + ddContainer:GetHeight()
	local hRight = colorPickers:GetHeight()
	local hMax = hRight > hLeft and hRight or hLeft
	yOffset = yOffset - hMax - Const.Size.Gap

	local tranqOptions = InputText.Create(dialog, Const.Size.Gap)
	tranqOptions:SetPoint("TopLeft", dialog, "TopLeft", 0, yOffset)
	yOffset = yOffset - tranqOptions:GetHeight()
	yOffset = yOffset - Const.Size.Gap

	dialog:SetHeight(-1 * yOffset + _PADDING_CLOSE + Const.Size.Button)
	return dialog
end

return {
	Create = Create,
}
