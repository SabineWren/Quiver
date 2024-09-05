local Util = require "Component/_Util.lua"
local L = require "Shiver/Lib/All.lua"
local Sugar = require "Shiver/Sugar.lua"

local _GAP = 6
local _SIZE = 16

-- see [CheckButton](lua://QqCheckButton)
-- see [Switch](lua://QqSwitch)
---@class (exact) QqButton : IMouseInteract
---@field private __index? QqButton
---@field Container Frame
---@field OnClick nil|(fun(): nil)
---@field OnMouseDown nil|(fun(): nil)
---@field OnMouseUp nil|(fun(): nil)
---@field Icon Frame
---@field Label? FontString
---@field Texture Texture
---@field isEnabled boolean
---@field isHover boolean
---@field isMouseDown boolean
local QqButton = {}

---@class (exact) paramsButton
---@field LabelText? string
---@field Scale? number
---@field TexPath string
---@field TooltipText? string

---@param self QqButton
local resetTexture = function(self)
	local r, g, b = Util.SelectColor(self)
	self.Texture:SetVertexColor(r, g, b)
	if self.Label ~= nil then
		self.Label:SetTextColor(r, g, b)
	end
end

---@param isEnabled boolean
function QqButton:ToggleEnabled(isEnabled)
	self.isEnabled = isEnabled
	resetTexture(self)
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
	local container = CreateFrame("Frame", nil, parent, nil)
	local icon = CreateFrame("Frame", nil, container, nil)

	---@type QqButton
	local r = {
		Container = container,
		Icon = icon,
		Texture = icon:CreateTexture(nil, "OVERLAY"),
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
		if r.OnMouseDown ~= nil then r.OnMouseDown() end
		resetTexture(r)
	end
	local onMouseUp = function()
		r.isMouseDown = false
		if r.OnMouseUp ~= nil then r.OnMouseUp() end
		if MouseIsOver(r.Container) == 1 and r.OnClick ~= nil then
			r.OnClick()
		end
		resetTexture(r)
	end

	container:SetScript("OnEnter", onEnter)
	container:SetScript("OnLeave", onLeave)
	container:SetScript("OnMouseDown", onMouseDown)
	container:SetScript("OnMouseUp", onMouseUp)
	container:EnableMouse(true)

	r.Texture:SetAllPoints(r.Icon)
	local scale = bag.Scale and bag.Scale or 1.0
	r.Icon:SetWidth(_SIZE * scale)
	r.Icon:SetHeight(_SIZE * scale)
	r.Texture:SetTexture(bag.TexPath)

	r.Icon:SetPoint("Left", container, "Left", 0, 0)
	local h, w = 0, 0
	if bag.LabelText then
		r.Label = container:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		r.Label:SetText(bag.LabelText)
		r.Label:SetPoint("Right", container, "Right", 0, 0)
		h = L.Psi(L.Max, Sugar.Region._GetHeight, r.Icon, r.Label)
		w = L.Psi(L.Add, Sugar.Region._GetWidth, r.Icon, r.Label) + _GAP
	else
		h = r.Icon:GetHeight()
		w = r.Icon:GetWidth()
	end
	container:SetHeight(h)
	container:SetWidth(w)

	resetTexture(r)
	return r
end

return QqButton
