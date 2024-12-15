local Button = require "Component/Button.lua"
local Const = require "Constants.lua"

---@param color Color
---@param button Frame
local openColorPicker = function(color, button)
	-- colors at time of opening picker
	local ri, gi, bi = color:Rgb()

	-- Must replace existing callback before changing anything else,
	-- or edits can fire previous callback, contaminating other values.
	ColorPickerFrame.func = function()
		local r, g, b = ColorPickerFrame:GetColorRGB()
		color:SetRgb(r, g, b)
		button:SetBackdropColor(r, g, b, 1)
	end

	ColorPickerFrame.cancelFunc = function()
		color:SetRgb(ri, gi, bi)
		button:SetBackdropColor(ri, gi, bi, 1)
		-- Reset native picker
		ColorPickerFrame:SetFrameStrata("MEDIUM")
	end

	ColorPickerFrame.hasOpacity = false
	ColorPickerFrame:SetColorRGB(ri, gi, bi)
	ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	ColorPickerFrame:Show()
end

---@param parent Frame
---@param color Color
---@return Frame
local createButton = function(parent, color)
	local f = CreateFrame("Button", nil, parent)
	f:SetWidth(40)
	f:SetHeight(20)
	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left=2, right=2, top=2, bottom=2 },
	})
	f:SetBackdropColor(color:Rgb())
	f:SetScript("OnClick", function() openColorPicker(color, f) end)
	return f
end

---@class (exact) QqColorSwatch
---@field private __index? QqColorSwatch
---@field Button Frame
---@field Container Frame
---@field Label FontString
---@field WidthMinusLabel number
local QqColorSwatch = {}

---@param parent Frame
---@param labelText string
---@param color Color
---@return QqColorSwatch
function QqColorSwatch:Create(parent, labelText, color)
	local container = CreateFrame("Frame", nil, parent)

	---@type QqColorSwatch
	local r = {
		Button = createButton(container, color),
		Container = container,
		Label = container:CreateFontString(nil, "BACKGROUND", "GameFontNormal"),
		WidthMinusLabel = 0,
	}
	setmetatable(r, self)
	self.__index = self

	r.Label:SetPoint("Left", container, "Left", 0, 0)
	r.Label:SetText(labelText)

	local reset = Button:Create(container, Const.Icon.Reset)
	reset.TooltipText = Quiver.T["Reset Color"]
	reset.HookClick = function()
		color:Reset()
		r.Button:SetBackdropColor(color:Rgb())
	end
	reset.Container:SetPoint("Right", container, "Right", 0, 0)

	local x = 4 + reset.Container:GetWidth()
	r.Button:SetPoint("Right", container, "Right", -x, 0)

	r.Container:SetHeight(r.Button:GetHeight())
	r.WidthMinusLabel = 6 + x + r.Button:GetWidth()

	return r
end

return QqColorSwatch
