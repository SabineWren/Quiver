local BORDER, INSET, SPACING = 1, 4, 4
local OPTION_PAD_H, OPTION_PAD_V = 8, 3

local createCaretButton = function(parent, size)
	local f = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	f:SetWidth(size)
	f:SetHeight(size)
	f.Texture = Quiver_Component_Button_CreateTexture(f, "OVERLAY")
	f:SetNormalTexture(f.Texture)
	f:SetHighlightTexture(nil)
	f:SetPushedTexture(nil)
	f:SetDisabledTexture(nil)
	return f
end

Quiver_Component_DropdownSelect = function(parent, label, optionsText, selected)
	local f = CreateFrame("Button", nil, parent)

	f.Menu = CreateFrame("Frame", nil, parent)
	f.Menu:SetFrameStrata("Tooltip")
	f.Menu:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile="Interface/BUTTONS/WHITE8X8", edgeSize=1
	})
	f.Menu:SetBackdropColor(0, 0, 0, 0.9)
	f.Menu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

	f.Button = CreateFrame("Button", nil, f)
	f.Button = createCaretButton(f, QUIVER.Size.Icon)
	f.Button.Texture:QuiverSetTexture(0.75, QUIVER.Icon.CaretDown)
	f.Button:SetPoint("Top", f, "Top", 0, -INSET)
	f.Button:SetPoint("Bottom", f, "Bottom", 0, INSET)
	f.Button:SetPoint("Right", f, "Right", -INSET, 0)

	f.Label = f:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	f.Label:SetPoint("Left", f, "Left", INSET, 0)
	f.Label:SetPoint("Top", f, "Top", 0, -INSET)
	f.Label:SetText(label)

	f.Selected = f:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	f.Selected:SetPoint("Bottom", f, "Bottom", 0, INSET)
	f.Selected:SetPoint("Left", f, "Left", INSET, 0)
	f.Selected:SetPoint("Right", f, "Right", -INSET - f.Button:GetWidth(), 0)
	f.Selected:SetText(selected)

	f.Menu.Options = Quiver_Lib_F.Map(optionsText, function(t, i)
		local option = CreateFrame("Button", nil, f.Menu)
		option.Text = option:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		option.Text:SetText(t)
		option.Text:SetPoint("TopLeft", option, "TopLeft", OPTION_PAD_H, -OPTION_PAD_V)

		option:SetHeight(option.Text:GetHeight() + 2 * OPTION_PAD_V)
		option:SetPoint("Left", f.Menu, "Left", BORDER, 0)
		option:SetPoint("Right", f.Menu, "Right", -BORDER, 0)
		option:SetPoint("Top", f.Menu, "Top", 0, -i * option:GetHeight() - BORDER)

		option:SetBackdrop({ bgFile = "Interface/BUTTONS/WHITE8X8" })
		option:SetBackdropColor(0, 0, 0, 0)
		return option
	end)
	for _k,oLoop in f.Menu.Options do
		local option = oLoop
		option:SetScript("OnEnter", function() option:SetBackdropColor(0.2, 0.1, 0, 1.0) end)
		option:SetScript("OnLeave", function() option:SetBackdropColor(0, 0, 0, 0) end)
	end
	local widths = Quiver_Lib_F.Map(f.Menu.Options, function(o) return o.Text:GetWidth() end)
	local heights = Quiver_Lib_F.Map(f.Menu.Options, function(o) return o:GetHeight() end)
	local maxOptionWidth = Quiver_Lib_F.Max(widths) + 2 * OPTION_PAD_H
	local maxWidth = f.Label:GetWidth() > maxOptionWidth and f.Label:GetWidth() or maxOptionWidth

	local handleClick = function()
		if f.Menu:IsVisible() then
			f.Menu:Hide()
		else
			f.Menu:Show()
		end
	end
	local hoverStart = function()
		f.Button.Texture:QuiverHighlight()
		f:SetBackdrop({ edgeFile="Interface/BUTTONS/WHITE8X8", edgeSize=BORDER })
		f:SetBackdropBorderColor(1.0, 0.6, 0, 0.35)
	end
	local hoverEnd = function()
		local isHover = MouseIsOver(f) or MouseIsOver(f.Button)
		if isHover then return end
		f:SetBackdropBorderColor(0, 0, 0, 0)
		f.Button.Texture:QuiverResetColor()
	end
	f:SetScript("OnClick", handleClick)
	f:SetScript("OnEnter", hoverStart)
	f:SetScript("OnLeave", hoverEnd)
	f.Button:SetScript("OnClick", handleClick)
	f.Button:SetScript("OnEnter", hoverStart)
	f.Button:SetScript("OnLeave", hoverEnd)

	f:SetHeight(f.Selected:GetHeight() + SPACING + f.Label:GetHeight() + 2 * INSET)
	f:SetWidth(maxWidth + f.Button:GetWidth() + SPACING + INSET * 2)

	f.Menu:SetHeight(Quiver_Lib_F.Sum(heights) + 2 * BORDER)
	f.Menu:SetWidth(maxOptionWidth + 2 * BORDER)
	f.Menu:SetPoint("Right", f, "Right", 0, 0)
	f.Menu:SetPoint("Top", f, "Top", 0, -f:GetHeight())
	f.Menu:Hide()

	return f
end
