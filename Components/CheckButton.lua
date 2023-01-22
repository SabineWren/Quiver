Quiver_Component_CheckButton = function(parent, p)
	local isChecked, label, tooltip, onClick =
		p.IsChecked, p.Label, p.Tooltip, p.OnClick

	-- Button width doesn't include label, which complicates outside code using GetWidth()
	-- Solution is to handle that complexity here, and wrap it in a container.
	local wrapper = CreateFrame("Frame", nil, parent)

	local btn = CreateFrame("CheckButton", nil, wrapper, "OptionsCheckButtonTemplate")
	btn:SetPoint("TopLeft", wrapper, "TopLeft", 0, 0)
	btn:SetWidth(QUIVER.Size.Icon)
	btn:SetHeight(QUIVER.Size.Icon)
	btn:SetChecked(isChecked)

	btn.Text = btn:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	btn.Text:SetPoint("Right", wrapper, "Right", 0, 0)
	btn.Text:SetText(label)
	if tooltip ~= nil then btn.tooltipText = tooltip end
	btn:SetScript("OnClick", function(_self) onClick(btn:GetChecked() == 1) end)

	local removeDefaultPadding = function(tex)
		tex:ClearAllPoints()
		tex:SetWidth(btn:GetWidth() * 1.5)
		tex:SetHeight(btn:GetHeight() * 1.5)
		tex:SetPoint("Center", 0, 0)
	end
	removeDefaultPadding(btn:GetCheckedTexture())
	removeDefaultPadding(btn:GetNormalTexture())
	removeDefaultPadding(btn:GetHighlightTexture())

	wrapper:SetHeight(btn:GetHeight())
	wrapper:SetWidth(btn:GetWidth() + QUIVER.Size.Gap + btn.Text:GetWidth())
	return wrapper
end
