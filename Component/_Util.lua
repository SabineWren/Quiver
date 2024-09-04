local Widget = require "Shiver/Widget.lua"

---@class IMouseInteract
---@field isEnabled boolean
---@field isHover boolean
---@field isMouseDown boolean

local _COLOR_NORMAL = { 1.0, 0.82, 0.0 }---@type Rgb
local _COLOR_HOVER = { 1.0, 0.6, 0.0 }---@type Rgb
local _COLOR_MOUSEDOWN = { 1.0, 0.3, 0.0 }---@type Rgb
local _COLOR_DISABLE = { 0.3, 0.3, 0.3 }---@type Rgb

---@param self IMouseInteract
local SelectColor = function(self)
	if not self.isEnabled then
		return _COLOR_DISABLE
	elseif self.isMouseDown then
		return _COLOR_MOUSEDOWN
	elseif self.isHover then
		return _COLOR_HOVER
	else
		return _COLOR_NORMAL
	end
end

---@param self IMouseInteract
---@param frame Frame
---@param text nil|string
local ToggleTooltip = function(self, frame, text)
	if text ~= nil then
		if self.isHover then
			Widget.PositionTooltip(frame)
			GameTooltip:AddLine(text, nil, nil, nil, 1)
			GameTooltip:Show()
		else
			GameTooltip:Hide()
			GameTooltip:ClearLines()
		end
	end
end

return {
	SelectColor = SelectColor,
	ToggleTooltip = ToggleTooltip,
}
