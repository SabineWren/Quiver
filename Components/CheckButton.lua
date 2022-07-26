Quiver_Components_CheckButton = function(p)
	local parent, y, isChecked, label, tooltip, onClick =
		p.Parent, p.Y, p.IsChecked, p.Label, p.Tooltip, p.OnClick

	local xStart = QUIVER_SIZE.Border + QUIVER_SIZE.Gap
	local f = CreateFrame("CheckButton", nil, parent, "OptionsCheckButtonTemplate")
	f:SetWidth(QUIVER_SIZE.Icon)
	f:SetHeight(QUIVER_SIZE.Icon)
	f:SetChecked(isChecked)
	f:SetPoint("Left", parent, "Left", xStart, 0)
	f:SetPoint("Top", parent, "Top", 0, y)
	f.Text = f:CreateFontString("Status", "LOW", "GameFontNormal")
	f.Text:SetPoint("Left", f, "Left", QUIVER_SIZE.Icon + QUIVER_SIZE.Gap, 0)
	f.Text:SetText(label)
	if tooltip ~= nil then f.tooltipText = tooltip end
	f:SetScript("OnClick", function(_self) onClick(f:GetChecked() == 1) end)

	local removeDefaultPadding = function(tex)
		tex:ClearAllPoints()
		tex:SetWidth(f:GetWidth() * 1.5)
		tex:SetHeight(f:GetHeight() * 1.5)
		tex:SetPoint("Center", 0, 0)
	end
	removeDefaultPadding(f:GetCheckedTexture())
	removeDefaultPadding(f:GetNormalTexture())
	removeDefaultPadding(f:GetHighlightTexture())
	return f
end
