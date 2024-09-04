local Util = require "Component/_Util.lua"
local Widget = require "Shiver/Widget.lua"

local _SIZE = 16

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
	local r = {
		Icon = icon,
		IsChecked = bag.IsChecked,
		TexPathOff = bag.TexPathOff,
		TexPathOn = bag.TexPathOn,
		Texture = icon:CreateTexture(nil, "OVERLAY"),
		isEnabled = true,
		isHover = false,
		isMouseDown = false,
	}
	setmetatable(r, self)
	self.__index = self

	r.Texture:SetAllPoints(r.Icon)

	local onEnter = function()
		r.isHover = true
		resetTexture(r)
		Util.ToggleTooltip(r, r.Icon, bag.TooltipText)
	end
	local onLeave = function()
		r.isHover = false
		resetTexture(r)
		Util.ToggleTooltip(r, r.Icon, bag.TooltipText)
	end

	local onMouseDown = function()
		r.isMouseDown = true
		resetTexture(r)
	end
	local onMouseUp = function()
		r.isMouseDown = false
		if MouseIsOver(r.Icon) == 1 then
			r.IsChecked = not r.IsChecked
			bag.OnChange(r.IsChecked)
		end
		resetTexture(r)
	end

	r.Icon:SetScript("OnEnter", onEnter)
	r.Icon:SetScript("OnLeave", onLeave)
	r.Icon:SetScript("OnMouseDown", onMouseDown)
	r.Icon:SetScript("OnMouseUp", onMouseUp)

	r.Icon:EnableMouse(true)
	r.Icon:SetWidth(_SIZE)
	r.Icon:SetHeight(_SIZE)

	resetTexture(r)
	return r
end

return QqCheckButton
