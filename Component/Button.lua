local Util = require "Component/_Util.lua"
local Widget = require "Shiver/Widget.lua"

local _SIZE = 14

-- see [CheckButton](lua://QqCheckButton)
-- see [Switch](lua://QqSwitch)
---@class (exact) QqButton : IMouseInteract
---@field __index? QqButton
---@field Icon Frame
---@field OnClick nil|(fun(): nil)
---@field Texture Texture
---@field isEnabled boolean
---@field isHover boolean
---@field isMouseDown boolean

---@class QqButton
local QqButton = {}

---@class (exact) paramsButton
---@field TexPath string
---@field TooltipText? string

---@param self QqButton
local resetTexture = function(self)
	local c = Util.SelectColor(self)
	local r, g, b = Widget.UnpackRgb(c)
	self.Texture:SetVertexColor(r, g, b)
end

---@param isHover boolean
function QqButton:ToggleHover(isHover)
	self.isHover = isHover
	resetTexture(self)
end

---@param parent Frame
---@param bag paramsButton
---@return QqButton
function QqButton:Create(parent, bag)
	local icon = CreateFrame("Frame", nil, parent, nil)

	---@type QqButton
	local bn = {
		Icon = icon,
		Texture = icon:CreateTexture(nil, "OVERLAY"),
		isEnabled = true,
		isHover = false,
		isMouseDown = false,
	}
	setmetatable(bn, self)
	self.__index = self

	icon:EnableMouse(true)
	icon:SetWidth(_SIZE)
	icon:SetHeight(_SIZE)

	bn.Texture:SetAllPoints(bn.Icon)
	bn.Texture:SetTexture(bag.TexPath)
	resetTexture(bn)

	local onEnter = function()
		bn.isHover = true
		resetTexture(bn)
		Util.ToggleTooltip(bn, bn.Icon, bag.TooltipText)
	end
	local onLeave = function()
		bn.isHover = false
		resetTexture(bn)
		Util.ToggleTooltip(bn, bn.Icon, bag.TooltipText)
	end

	local onMouseDown = function()
		bn.isMouseDown = true
		resetTexture(bn)
	end
	local onMouseUp = function()
		bn.isMouseDown = false
		if MouseIsOver(bn.Icon) == 1 and bn.OnClick ~= nil then
			bn.OnClick()
		end
		resetTexture(bn)
	end

	bn.Icon:SetScript("OnEnter", onEnter)
	bn.Icon:SetScript("OnLeave", onLeave)
	bn.Icon:SetScript("OnMouseDown", onMouseDown)
	bn.Icon:SetScript("OnMouseUp", onMouseUp)

	return bn
end

return QqButton
