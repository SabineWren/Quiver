local Api = require "Api/Index.lua"
local Util = require "Component/_Util.lua"
local Const = require "Constants.lua"
local L = require "Lib/Index.lua"

local _BORDER, _INSET, _SPACING = 1, 4, 4
local _OPTION_PAD_H, _OPTION_PAD_V = 8, 4
local _MENU_PAD_TOP = 6

---@type QqSelect[]
local allSelects = {}

---@class Icon
---@field Frame Frame
---@field Texture Texture

---@param container Frame
---@return Icon
---@nodiscard
local createIcon = function(container)
	local f = CreateFrame("Frame", nil, container)
	f:SetPoint("Right", container, "Right", -_INSET, 0)
	f:SetWidth(16)
	f:SetHeight(16)

	local t = f:CreateTexture(nil, "OVERLAY")
	t:SetAllPoints(f)
	t:SetTexture(Const.Icon.CaretDown)
	return { Frame=f, Texture=t }
end

---@class (exact) QqSelect : IMouseInteract
---@field private __index? QqSelect
---@field Container Frame
---@field private icon Icon
---@field private label FontString
---@field private isEnabled boolean
---@field private isHover boolean
---@field private isMouseDown boolean
---@field Menu Frame
---@field Selected FontString
local QqSelect = {}

function QqSelect:resetTexture()
	local r, g, b = Util.SelectColor(self)

	local borderAlpha = self.isHover and 0.6 or 0.0
	self.Container:SetBackdropBorderColor(r, g, b, borderAlpha)

	self.label:SetTextColor(r, g, b)
	self.Selected:SetTextColor(r, g, b)

	self.icon.Texture:SetVertexColor(r, g, b)

	-- Vertically flip caret
	if self.Menu:IsVisible() then
		self.icon.Texture:SetTexCoord(0, 1, 1, 0)
	else
		self.icon.Texture:SetTexCoord(0, 1, 0, 1)
	end
end

function QqSelect:OnHoverStart()
	self.isHover = true
	self:resetTexture()
end

function QqSelect:OnHoverEnd()
	self.isHover = false
	self:resetTexture()
end

function QqSelect:OnMouseDown()
	self.isMouseDown = true
	self:resetTexture()
end

function QqSelect:OnMouseUp()
	self.isMouseDown = false
	if self:predMouseOver() then
		local isVisible = self.Menu:IsVisible()
		for _i, v in ipairs(allSelects) do
			v.Menu:Hide()
			v:resetTexture()
		end
		if not isVisible then self.Menu:Show() end
	end
	self:resetTexture()
end

---@private
---@return boolean
---@nodiscard
function QqSelect:predMouseOver()
	local xs = { self.Container, self.icon.Frame }
	return L.Array.Some(xs, MouseIsOver)
end

---@param parent Frame
---@param labelText string
---@param optionsText string[]
---@param selectedText nil|string
---@param onSet fun(text: string): nil
---@return QqSelect
function QqSelect:Create(parent, labelText, optionsText, selectedText, onSet)
	local select = CreateFrame("Frame", nil, parent)

	---@type QqSelect
	local r = {
		Container = select,
		icon = createIcon(select),
		label = select:CreateFontString(nil, "BACKGROUND", "GameFontNormal"),
		isEnabled = true,
		isHover = false,
		isMouseDown = false,
		Menu = CreateFrame("Frame", nil, parent),
		Selected = select:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	}
	setmetatable(r, self)
	self.__index = self
	table.insert(allSelects, r)

	r.Container:SetBackdrop({
		edgeFile="Interface/BUTTONS/WHITE8X8",
		edgeSize=_BORDER,
	})

	r.Menu:SetFrameStrata("TOOLTIP")
	r.Menu:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile="Interface/BUTTONS/WHITE8X8",
		edgeSize=1,
	})
	r.Menu:SetBackdropColor(0, 0, 0, 1)
	r.Menu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

	r.label:SetPoint("Left", select, "Left", _INSET, 0)
	r.label:SetPoint("Top", select, "Top", 0, -_INSET)
	r.label:SetText(labelText)

	r.Selected:SetPoint("Bottom", select, "Bottom", 0, _INSET)
	r.Selected:SetPoint("Left", select, "Left", _INSET, 0)
	r.Selected:SetPoint("Right", select, "Right", -_INSET - r.icon.Frame:GetWidth(), 0)
	r.Selected:SetText(selectedText or optionsText[1])

	local options = L.Array.Mapi(optionsText, function(t, i)
		local option = CreateFrame("Button", nil, r.Menu)
		local optionFs = option:CreateFontString(nil, "OVERLAY", "GameFontNormal")

		option:SetFontString(optionFs)
		optionFs:SetPoint("TopLeft", option, "TopLeft", _OPTION_PAD_H, -_OPTION_PAD_V)
		optionFs:SetText(t)

		option:SetHeight(optionFs:GetHeight() + 2 * _OPTION_PAD_V)
		option:SetPoint("Left", r.Menu, "Left", _BORDER, 0)
		option:SetPoint("Right", r.Menu, "Right", -_BORDER, 0)
		option:SetPoint("Top", r.Menu, "Top", 0, -i * option:GetHeight() - _BORDER - _MENU_PAD_TOP)

		local texHighlight = option:CreateTexture(nil, "OVERLAY")
		-- It would probably look better to set a fancy texture and adjust vertex color.
		texHighlight:SetTexture(0.22, 0.1, 0)
		texHighlight:SetAllPoints(option)
		option:SetHighlightTexture(texHighlight)

		return option
	end)

	for _i, v in ipairs(options) do
		local option = v---@type Button
		option:SetScript("OnClick", function()
			local text = option:GetFontString():GetText() or ""
			onSet(text)
			r.Selected:SetText(text)
			r.Menu:Hide()
		end)
	end

	local sumOptionHeights = L.Array.MapReduce(options, Api._Height, L.M.Add)
	local maxOptionWidth = L.Array.MapSeduce(options, L.Flow(Api._FontString, Api._Width), L.Sg.Max, 0)

	select:SetScript("OnEnter", function() r:OnHoverStart() end)
	select:SetScript("OnLeave", function() r:OnHoverEnd() end)
	select:SetScript("OnMouseDown", function() r:OnMouseDown() end)
	select:SetScript("OnMouseUp", function() r:OnMouseUp() end)
	select:EnableMouse(true)

	select:SetHeight(
		r.Selected:GetHeight()
		+ r.label:GetHeight()
		+ _SPACING + 2 * _INSET
	)
	select:SetWidth(
		math.max(r.label:GetWidth(), maxOptionWidth)
		+ r.icon.Frame:GetWidth()
		+ _SPACING + 2 * _INSET
	)

	r.Menu:SetHeight(sumOptionHeights + _MENU_PAD_TOP + 2 * _BORDER)
	r.Menu:SetWidth(maxOptionWidth + 2 * (_OPTION_PAD_H + _BORDER))
	r.Menu:SetPoint("Right", select, "Right", 0, 0)
	r.Menu:SetPoint("Top", select, "Top", 0, -select:GetHeight())
	r.Menu:Hide()

	r:resetTexture()
	return r
end

return QqSelect
