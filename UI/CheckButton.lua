Quiver_UI_CheckButton = function(p)
	local parent, y, isChecked, label, tooltip, onClick =
		p.Parent, p.Y, p.IsChecked, p.Label, p.Tooltip, p.OnClick

	-- Builtin values that we have to guess
	local CHECKBOX_PADDING = 3
	local CHECKBOX_WIDTH = 30

	local xStart = QUIVER_SIZE.Border + QUIVER_SIZE.Gap - CHECKBOX_PADDING
	local f = CreateFrame("CheckButton", nil, parent, "OptionsCheckButtonTemplate")
	f:SetChecked(isChecked)
	f:SetPoint("Left", parent, "Left", xStart, 0)
	f:SetPoint("Top", parent, "Top", 0, y)
	f.Text = f:CreateFontString("Status", "LOW", "GameFontNormal")
	f.Text:SetPoint("Left", f, "Left", CHECKBOX_WIDTH + QUIVER_SIZE.Gap, 0)
	f.Text:SetText(label)
	f:SetTextColor(.5, 1, .8, 1)
	if tooltip ~= nil then f.tooltipText = tooltip end
	f:SetScript("OnClick", function() onClick(f:GetChecked() == 1) end)
	return f
end
