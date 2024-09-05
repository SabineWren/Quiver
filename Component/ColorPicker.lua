local Button = require "Component/Button.lua"

-- TODO this componnt has low code quality and type warnings

---@param parent Frame
---@param color Color
---@return Frame
---@nodiscard
local createColorPicker = function(parent, color)
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


	f:SetScript("OnClick", function(_self)
		-- colors at time of opening picker
		local ri, gi, bi = color:Rgb()

		-- Must replace existing callback before changing anything else,
		-- or edits can fire previous callback, contaminating other values.
		ColorPickerFrame.func = function()
			local r, g, b = ColorPickerFrame:GetColorRGB()
			color:SetRgb(r, g, b)
			f:SetBackdropColor(r, g, b, 1)
		end

		ColorPickerFrame.cancelFunc = function()
			color:SetRgb(ri, gi, bi)
			f:SetBackdropColor(ri, gi, bi, 1)
		end

		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame:SetColorRGB(ri, gi, bi)
		ColorPickerFrame:Show()
	end)

	return f
end


---@class ButtonColorPicker
---@field Button Button
---@field ColorShoot StoreColor
---@field Container Frame
---@field Label FontString
---@field WidthMinusLabel number

---@param color Color
local CreateWithResetLabel = function(parent, labelText, color)
	local container = CreateFrame("Frame", nil, parent)

	---@type ButtonColorPicker
	local r = {
		Button = nil,
		ColorShoot = nil,
		Container = container,
		Label = container:CreateFontString(nil, "BACKGROUND", "GameFontNormal"),
		WidthMinusLabel = 0,
	}

	r.Label:SetPoint("Left", container, "Left", 0, 0)
	r.Label:SetText(labelText)

	local reset = Button:Create(container, {
		TexPath = QUIVER.Icon.Reset,
		TooltipText = QUIVER_T.UI.ResetColor,
	})
	reset.OnClick = function()
		color:Reset()
		r.Button:SetBackdropColor(color:Rgb())
	end
	reset.Container:SetPoint("Right", container, "Right", 0, 0)

	local x = 4 + reset.Container:GetWidth()
	r.Button = createColorPicker(container, color)
	r.Button:SetPoint("Right", container, "Right", -x, 0)

	r.Container:SetHeight(r.Button:GetHeight())
	r.WidthMinusLabel = 6 + x + r.Button:GetWidth()

	return r
end

return {
	CreateWithResetLabel = CreateWithResetLabel,
}
