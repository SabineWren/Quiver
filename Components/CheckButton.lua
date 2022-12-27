Quiver_Component_CheckButton = function(p)
	local parent, x, y, isChecked, label, tooltip, onClick =
		p.Parent, p.X, p.Y, p.IsChecked, p.Label, p.Tooltip, p.OnClick

	local f = CreateFrame("CheckButton", nil, parent, "OptionsCheckButtonTemplate")
	f:SetWidth(QUIVER.Size.Icon)
	f:SetHeight(QUIVER.Size.Icon)
	f:SetChecked(isChecked)
	f:SetPoint("Left", parent, "Left", x, 0)
	f:SetPoint("Top", parent, "Top", 0, y)
	f.Text = f:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	f.Text:SetPoint("Left", f, "Left", QUIVER.Size.Icon + QUIVER.Size.Gap, 0)
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
