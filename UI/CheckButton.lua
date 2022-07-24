Quiver_UI_CheckButton = function(p)
	local parent, y, isChecked, label, tooltip, onClick =
		p.Parent, p.Y, p.IsChecked, p.Label, p.Tooltip, p.OnClick

	local f = CreateFrame("CheckButton", nil, parent, "OptionsCheckButtonTemplate")
	f:SetChecked(isChecked)
	f:SetPoint("Left", parent, "Left", 20, 0)
	f:SetPoint("Top", parent, "Top", 0, y)
	f.text = f:CreateFontString("Status", "LOW", "GameFontNormal")
	f.text:SetPoint("Left", f, "Left", 35, 0)
	f.text:SetText(label)
	f:SetTextColor(.5, 1, .8, 1)
	if tooltip ~= nil then f.tooltipText = tooltip end
	f:SetScript("OnClick", function() onClick(f:GetChecked() == 1) end)
	return f
end
