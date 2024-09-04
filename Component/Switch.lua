local L = require "Shiver/Lib/All.lua"
local Sugar = require "Shiver/Sugar.lua"
local Widget = require "Shiver/Widget.lua"

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

---@class QqSwitch
---@field Container Frame
---@field Icon Frame
---@field IsChecked boolean
---@field IsEnabled boolean
---@field Label FontString
---@field Texture Texture

---@class paramsSwitch
---@field Gap number
---@field IsChecked boolean
---@field LabelText string
---@field OnChange fun(b: boolean): nil
---@field TooltipText? string

local _COLOR_NORMAL = { 1.0, 0.82, 0.0 }---@type Rgb
local _COLOR_HOVER = { 1.0, 0.6, 0.0 }---@type Rgb
local _COLOR_MOUSEDOWN = { 1.0, 0.3, 0.0 }---@type Rgb
local _COLOR_DISABLE = { 0.3, 0.3, 0.3 }---@type Rgb
local _SIZE = 18

---@param sw QqSwitch
---@param isHover boolean
---@param isMouseDown boolean
local resetTexture = function(sw, isHover, isMouseDown)
	local path = sw.IsChecked and QUIVER.Icon.ToggleOn or QUIVER.Icon.ToggleOff
	local c = (function()
		if not sw.IsEnabled then
			return _COLOR_DISABLE
		elseif isMouseDown then
			return _COLOR_MOUSEDOWN
		elseif isHover then
			return _COLOR_HOVER
		else
			return _COLOR_NORMAL
		end
	end)()

	sw.Texture:SetTexture(path)
	local r, g, b = Widget.UnpackRgb(c)
	local a = sw.IsChecked and 1.0 or 0.7
	sw.Texture:SetVertexColor(r, g, b, a)
	sw.Label:SetTextColor(r, g, b, a)
end

---@param sw QqSwitch
---@param isHighlight boolean
---@param text nil|string
local toggleTooltip = function(sw, isHighlight, text)
	if text ~= nil then
		if isHighlight then
			Widget.PositionTooltip(sw.Icon)
			GameTooltip:AddLine(text, nil, nil, nil, 1)
			GameTooltip:Show()
		else
			GameTooltip:Hide()
			GameTooltip:ClearLines()
		end
	end
end

---@type fun(parent: Frame, bag: paramsSwitch): QqSwitch
local Create = function(parent, bag)
	local container = CreateFrame("Frame", nil, parent, nil)
	local icon = CreateFrame("Frame", nil, container, nil)
	---@type QqSwitch
	local sw = {
		Container = container,
		Icon = icon,
		Label = container:CreateFontString(nil, "BACKGROUND", "GameFontNormal"),
		IsChecked = bag.IsChecked,
		IsEnabled = true,
		Texture = icon:CreateTexture(nil, "OVERLAY")
	}
	sw.Texture:SetAllPoints(sw.Icon)
	sw.Label:SetText(bag.LabelText)

	local isHover = false
	local isMouseDown = false

	local onEnter = function()
		isHover = true
		resetTexture(sw, isHover, isMouseDown)
		toggleTooltip(sw, isHover, bag.TooltipText)
	end
	local onLeave = function()
		isHover = false
		resetTexture(sw, isHover, isMouseDown)
		toggleTooltip(sw, isHover, bag.TooltipText)
	end

	local onMouseDown = function()
		isMouseDown = true
		resetTexture(sw, isHover, isMouseDown)
	end
	local onMouseUp = function()
		isMouseDown = false
		if MouseIsOver(sw.Container) == 1 then
			sw.IsChecked = not sw.IsChecked
			bag.OnChange(sw.IsChecked)
		end
		resetTexture(sw, isHover, isMouseDown)
	end

	container:SetScript("OnEnter", onEnter)
	container:SetScript("OnLeave", onLeave)
	container:SetScript("OnMouseDown", onMouseDown)
	container:SetScript("OnMouseUp", onMouseUp)

	container:EnableMouse(true)
	sw.Icon:SetWidth(_SIZE * 1.2)
	sw.Icon:SetHeight(_SIZE)
	resetTexture(sw, isHover, isMouseDown)

	sw.Icon:SetPoint("Left", container, "Left", 0, 0)
	sw.Label:SetPoint("Right", container, "Right", 0, 0)

	local h = L.Psi(L.Max, Sugar.Region._GetHeight, sw.Icon, sw.Label)
	local w = L.Psi(L.Add, Sugar.Region._GetWidth, sw.Icon, sw.Label)
	container:SetHeight(h)
	container:SetWidth(w + bag.Gap)

	return sw
end

return {
	Create = Create,
}
