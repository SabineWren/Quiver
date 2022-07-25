Quiver_UI_CheckButton = function(p)
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
	--f:SetTextColor(.5, 1, .8, 1)
	if tooltip ~= nil then f.tooltipText = tooltip end
	f:SetScript("OnClick", function() onClick(f:GetChecked() == 1) end)

	-- Builtin textures have tons of padding
	local fixPadding = function(tex)
		tex:ClearAllPoints()
		tex:SetWidth(f:GetWidth() * 1.5)
		tex:SetHeight(f:GetHeight() * 1.5)
		tex:SetPoint("Center", 0, 0)
	end
	fixPadding(f:GetCheckedTexture())
	fixPadding(f:GetNormalTexture())
	fixPadding(f:GetHighlightTexture())
	return f
end
