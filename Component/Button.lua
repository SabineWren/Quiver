local Api = require "Api/Index.lua"
local Util = require "Component/_Util.lua"
local L = require "Lib/Index.lua"

local _GAP = 6
local _SIZE = 16

-- see [IconButton](lua://QqIconButton)
-- see [Switch](lua://QqSwitch)
---@class (exact) QqButton : IMouseInteract
---@field private __index? QqButton
---@field Container Frame
---@field HookClick nil|(fun(): nil)
---@field HookMouseDown nil|(fun(): nil)
---@field HookMouseUp nil|(fun(): nil)
---@field Icon Frame
---@field Label? FontString
---@field TooltipText? string
---@field Texture Texture
---@field private isEnabled boolean
---@field private isHover boolean
---@field private isMouseDown boolean
local QqButton = {}

function QqButton:resetTexture()
	local r, g, b = Util.SelectColor(self)
	self.Texture:SetVertexColor(r, g, b)
	if self.Label ~= nil then
		self.Label:SetTextColor(r, g, b)
	end
end

function QqButton:OnHoverStart()
	self.isHover = true
	self:resetTexture()
	Util.ToggleTooltip(self, self.Container, self.TooltipText)
end

function QqButton:OnHoverEnd()
	self.isHover = false
	self:resetTexture()
	Util.ToggleTooltip(self, self.Container, self.TooltipText)
end

function QqButton:OnMouseDown()
	self.isMouseDown = true
	if self.HookMouseDown ~= nil then self.HookMouseDown() end
	self:resetTexture()
end

function QqButton:OnMouseUp()
	self.isMouseDown = false
	if self.HookMouseUp ~= nil then self.HookMouseUp() end
	if MouseIsOver(self.Container) == 1 and self.HookClick ~= nil then
		self.HookClick()
	end
	self:resetTexture()
end

---@param isEnabled boolean
function QqButton:ToggleEnabled(isEnabled)
	self.isEnabled = isEnabled
	self:resetTexture()
end

---@param isHover boolean
function QqButton:ToggleHover(isHover)
	self.isHover = isHover
	self:resetTexture()
end


---@param parent Frame
---@param texPath string
---@param labelText? string
---@param scale? number
---@return QqButton
function QqButton:Create(parent, texPath, labelText, scale)
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

	container:SetScript("OnEnter", function() r:OnHoverStart() end)
	container:SetScript("OnLeave", function() r:OnHoverEnd() end)
	container:SetScript("OnMouseDown", function() r:OnMouseDown() end)
	container:SetScript("OnMouseUp", function() r:OnMouseUp() end)
	container:EnableMouse(true)

	r.Texture:SetAllPoints(r.Icon)
	local scaleOr = scale and scale or 1.0
	r.Icon:SetWidth(_SIZE * scaleOr)
	r.Icon:SetHeight(_SIZE * scaleOr)
	r.Texture:SetTexture(texPath)

	r.Icon:SetPoint("Left", container, "Left", 0, 0)
	local h, w = 0, 0
	if labelText then
		r.Label = container:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		r.Label:SetText(labelText)
		r.Label:SetPoint("Right", container, "Right", 0, 0)
		h = L.Psi(L.Sg.Max.Op, Api._Height, r.Icon, r.Label)
		w = L.Psi(L.M.Add.Op, Api._Width, r.Icon, r.Label) + _GAP
	else
		h = r.Icon:GetHeight()
		w = r.Icon:GetWidth()
	end
	container:SetHeight(h)
	container:SetWidth(w)

	r:resetTexture()
	return r
end

return QqButton
