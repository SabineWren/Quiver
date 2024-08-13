local Button = require "Component/Button.lua"
local L = require "Lib/All.lua"

local _BORDER, _INSET, _SPACING = 1, 4, 4
local _OPTION_PAD_H, _OPTION_PAD_V = 8, 4
local _MENU_PAD_TOP = 6

---@type Frame[]
local allMenus = {}

---@param parent Frame
---@param labelText string
---@param optionsText string[]
---@param selectedText nil|string
---@param onSet fun(text: string): nil
local Create = function(parent, labelText, optionsText, selectedText, onSet)
	local select = CreateFrame("Button", nil, parent)
	local menu = CreateFrame("Frame", nil, parent)
	local btnCaret = Button.Caret(select, QUIVER.Size.Icon)
	local label = select:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	local selected = select:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	table.insert(allMenus, menu)

	menu:SetFrameStrata("TOOLTIP")
	menu:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile="Interface/BUTTONS/WHITE8X8",
		edgeSize=1,
	})
	menu:SetBackdropColor(0, 0, 0, 1)
	menu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

	btnCaret:SetPoint("Right", select, "Right", -_INSET, 0)

	label:SetPoint("Left", select, "Left", _INSET, 0)
	label:SetPoint("Top", select, "Top", 0, -_INSET)
	label:SetText(labelText)

	selected:SetPoint("Bottom", select, "Bottom", 0, _INSET)
	selected:SetPoint("Left", select, "Left", _INSET, 0)
	selected:SetPoint("Right", select, "Right", -_INSET - btnCaret:GetWidth(), 0)
	selected:SetText(selectedText or optionsText[1])

	local options = L.Array.Mapi(optionsText, function(t, i)
		local option = CreateFrame("Button", nil, menu)
		local optionFs = option:CreateFontString(nil, "OVERLAY", "GameFontNormal")

		option:SetFontString(optionFs)
		optionFs:SetPoint("TopLeft", option, "TopLeft", _OPTION_PAD_H, -_OPTION_PAD_V)
		optionFs:SetText(t)

		option:SetHeight(optionFs:GetHeight() + 2 * _OPTION_PAD_V)
		option:SetPoint("Left", menu, "Left", _BORDER, 0)
		option:SetPoint("Right", menu, "Right", -_BORDER, 0)
		option:SetPoint("Top", menu, "Top", 0, -i * option:GetHeight() - _BORDER - _MENU_PAD_TOP)

		local texHighlight = option:CreateTexture(nil, "OVERLAY")
		-- It would probably look better to set a fancy texture and adjust vertex color.
		texHighlight:SetTexture(0.22, 0.1, 0)
		texHighlight:SetAllPoints(option)
		option:SetHighlightTexture(texHighlight)

		return option
	end)

	for _k, oLoop in options do
		local option = oLoop---@type Button
		option:SetScript("OnClick", function()
			local text = option:GetFontString():GetText() or ""
			onSet(text)
			selected:SetText(text)
			menu:Hide()
		end)
	end

	local sumOptionHeights =
		L.Array.MapReduce(options, function(o) return o:GetHeight() end, L.Add, 0)
	local maxOptionWidth =
		L.Array.MapReduce(options, function(o) return o:GetFontString():GetWidth() end, math.max, 0)

	local handleClick = function()
		local isVisible = menu:IsVisible()
		for _k, m in allMenus do m:Hide() end
		if not isVisible then menu:Show() end
	end
	local hoverStart = function()
		btnCaret:LockHighlight()
		select:SetBackdrop({
			edgeFile="Interface/BUTTONS/WHITE8X8",
			edgeSize=_BORDER,
		})
		select:SetBackdropBorderColor(1.0, 0.6, 0, 0.35)
	end
	local hoverEnd = function()
		if not MouseIsOver(select) then
			select:SetBackdropBorderColor(0, 0, 0, 0)
			btnCaret:UnlockHighlight()
		end
	end
	select:SetScript("OnClick", handleClick)
	select:SetScript("OnEnter", hoverStart)
	select:SetScript("OnLeave", hoverEnd)
	btnCaret:SetScript("OnClick", handleClick)
	btnCaret:SetScript("OnEnter", hoverStart)
	btnCaret:SetScript("OnLeave", hoverEnd)

	select:SetHeight(
		selected:GetHeight()
		+ _SPACING
		+ label:GetHeight()
		+ 2 * _INSET
	)
	select:SetWidth(
		math.max(label:GetWidth(), maxOptionWidth)
		+ btnCaret:GetWidth()
		+ _SPACING
		+ _INSET * 2
	)

	menu:SetHeight(sumOptionHeights + _MENU_PAD_TOP + 2 * _BORDER)
	menu:SetWidth(maxOptionWidth + 2 * (_OPTION_PAD_H + _BORDER))
	menu:SetPoint("Right", select, "Right", 0, 0)
	menu:SetPoint("Top", select, "Top", 0, -select:GetHeight())
	menu:Hide()

	return select
end

return {
	Create = Create,
}
