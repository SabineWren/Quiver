local Api = require "Api/Index.lua"
local Util = require "Component/_Util.lua"
local Const = require "Constants.lua"
local L = require "Lib/Index.lua"

local _GAP = 6
local _SIZE = 18

-- Three frame types exist for implementing a Switch: CheckButton, Button, Frame
-- For custom functionality with minimal code, Frame is the easiest starting point.

-- - CheckButton
-- The built-in texture slots don't allow different highlight/pushed effects for checked/unchecked.
-- Also inherits all problems from Button.

-- - Button
-- 1. Requires a pushed texture, otherwise icon disappears when user drags mouse.
--    That's twice the code of putting a single texture on a frame.
-- 2. Requires re-creating textures every time the button state changes, or
--    the next click causes a nil reference.
-- 3. If we use the built-in hover slot, the hover MUST stack with normal texture.
--    i.e. can't darken on hover.
-- 4. The built-in pushed effect doesn't take effect until MouseUp.

-- - Frame
-- 1. Mouse disabled by default.
-- 2. Click event not implemented.
-- 3. Disabled not implemented.

-- see [Button](lua://QqButton)
-- see [IconButton](lua://QqIconButton)
---@class (exact) QqSwitch : IMouseInteract
---@field private __index? QqSwitch
---@field Container Frame
---@field Icon Frame
---@field Label FontString
---@field Texture Texture
---@field isChecked boolean
---@field isEnabled boolean
---@field isHover boolean
---@field isMouseDown boolean
local QqSwitch = {}

---@class (exact) paramsSwitch
---@field IsChecked boolean
---@field LabelText string
---@field OnChange fun(b: boolean): nil
---@field TooltipText? string

---@param self QqSwitch
local resetTexture = function(self)
	local path = self.isChecked and Const.Icon.ToggleOn or Const.Icon.ToggleOff
	self.Texture:SetTexture(path)

	local r, g, b = Util.SelectColor(self)
	local a = self.isChecked and 1.0 or 0.7
	self.Texture:SetVertexColor(r, g, b, a)
	self.Label:SetTextColor(r, g, b, a)
end

---@param parent Frame
---@param bag paramsSwitch
---@return QqSwitch
---@nodiscard
function QqSwitch:Create(parent, bag)
	local container = CreateFrame("Frame", nil, parent, nil)
	local icon = CreateFrame("Frame", nil, container, nil)

	---@type QqSwitch
	local r = {
		Container = container,
		Icon = icon,
		Label = container:CreateFontString(nil, "BACKGROUND", "GameFontNormal"),
		Texture = icon:CreateTexture(nil, "OVERLAY"),
		isChecked = bag.IsChecked,
		isEnabled = true,
		isHover = false,
		isMouseDown = false,
	}
	setmetatable(r, self)
	self.__index = self

	local onEnter = function()
		r.isHover = true
		resetTexture(r)
		Util.ToggleTooltip(r, r.Container, bag.TooltipText)
	end
	local onLeave = function()
		r.isHover = false
		resetTexture(r)
		Util.ToggleTooltip(r, r.Container, bag.TooltipText)
	end

	local onMouseDown = function()
		r.isMouseDown = true
		resetTexture(r)
	end
	local onMouseUp = function()
		r.isMouseDown = false
		if MouseIsOver(r.Container) == 1 then
			r.isChecked = not r.isChecked
			bag.OnChange(r.isChecked)
		end
		resetTexture(r)
	end

	container:SetScript("OnEnter", onEnter)
	container:SetScript("OnLeave", onLeave)
	container:SetScript("OnMouseDown", onMouseDown)
	container:SetScript("OnMouseUp", onMouseUp)
	container:EnableMouse(true)

	r.Texture:SetAllPoints(r.Icon)
	r.Icon:SetWidth(_SIZE * 1.2)
	r.Icon:SetHeight(_SIZE)
	r.Label:SetText(bag.LabelText)

	r.Icon:SetPoint("Left", container, "Left", 0, 0)
	r.Label:SetPoint("Right", container, "Right", 0, 0)
	local h = L.Psi(L.Sg.Max.Op, Api._Height, r.Icon, r.Label)
	local w = L.Psi(L.M.Add.Op, Api._Width, r.Icon, r.Label) + _GAP
	container:SetHeight(h)
	container:SetWidth(w)

	resetTexture(r)
	return r
end

return QqSwitch
