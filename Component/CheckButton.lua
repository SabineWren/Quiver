local Util = require "Component/_Util.lua"
local Widget = require "Shiver/Widget.lua"

local _SIZE = 18

-- see [Button](lua://QqButton)
-- see [Switch](lua://QqSwitch)
---@class (exact) QqCheckButton : IMouseInteract
---@field __index? QqCheckButton
---@field Icon Frame
---@field IsChecked boolean
---@field TexPathOff string
---@field TexPathOn string
---@field Texture Texture
---@field isEnabled boolean
---@field isHover boolean
---@field isMouseDown boolean

---@class QqCheckButton
local QqCheckButton = {}

---@class (exact) paramsCheckButton
---@field IsChecked boolean
---@field OnChange fun(b: boolean): nil
---@field TexPathOff string
---@field TexPathOn string
---@field TooltipText? string

---@param self QqCheckButton
local resetTexture = function(self)
	local path = self.IsChecked and self.TexPathOn or self.TexPathOff
	self.Texture:SetTexture(path)

	local c = Util.SelectColor(self)
	local r, g, b = Widget.UnpackRgb(c)
	self.Texture:SetVertexColor(r, g, b)
end

---@param parent Frame
---@param bag paramsCheckButton
---@return QqCheckButton
---@nodiscard
function QqCheckButton:Create(parent, bag)
	local icon = CreateFrame("Frame", nil, parent, nil)

	---@type QqCheckButton
	local cb = {
		Icon = icon,
		IsChecked = bag.IsChecked,
		TexPathOff = bag.TexPathOff,
		TexPathOn = bag.TexPathOn,
		Texture = icon:CreateTexture(nil, "OVERLAY"),
		isEnabled = true,
		isHover = false,
		isMouseDown = false,
	}
	setmetatable(cb, self)
	self.__index = self

	cb.Texture:SetAllPoints(cb.Icon)

	local onEnter = function()
		cb.isHover = true
		resetTexture(cb)
		Util.ToggleTooltip(cb, cb.Icon, bag.TooltipText)
	end
	local onLeave = function()
		cb.isHover = false
		resetTexture(cb)
		Util.ToggleTooltip(cb, cb.Icon, bag.TooltipText)
	end

	local onMouseDown = function()
		cb.isMouseDown = true
		resetTexture(cb)
	end
	local onMouseUp = function()
		cb.isMouseDown = false
		if MouseIsOver(cb.Icon) == 1 then
			cb.IsChecked = not cb.IsChecked
			bag.OnChange(cb.IsChecked)
		end
		resetTexture(cb)
	end

	cb.Icon:SetScript("OnEnter", onEnter)
	cb.Icon:SetScript("OnLeave", onLeave)
	cb.Icon:SetScript("OnMouseDown", onMouseDown)
	cb.Icon:SetScript("OnMouseUp", onMouseUp)

	cb.Icon:EnableMouse(true)
	cb.Icon:SetWidth(_SIZE)
	cb.Icon:SetHeight(_SIZE)
	resetTexture(cb)

	return cb
end

return QqCheckButton
