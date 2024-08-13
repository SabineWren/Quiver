local Create = function(parent, p)
	local isChecked, label, tooltip, onClick =
		p.IsChecked, p.Label, p.Tooltip, p.OnClick

	-- Button width doesn't include label, which complicates outside code using GetWidth()
	-- Solution is to handle that complexity here, and wrap it in a container.
	local wrapper = CreateFrame("Frame", nil, parent)

	local btn = CreateFrame("CheckButton", nil, wrapper, "OptionsCheckButtonTemplate")
	btn:SetPoint("Left", wrapper, "Left")
	btn:SetWidth(QUIVER.Size.Icon)
	btn:SetHeight(QUIVER.Size.Icon)
	btn:SetChecked(isChecked)

	btn.Text = btn:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	btn.Text:SetPoint("Right", wrapper, "Right")
	btn.Text:SetText(label)
	if tooltip ~= nil then btn.tooltipText = tooltip end
	btn:SetScript("OnClick", function(_self) onClick(btn:GetChecked() == 1) end)

	-- Kludge to increase texture size. By default, it doesn't
	-- cover the entire button.
	-- TODO this is horrible. Use Texture:SetTexCoord or something.
	---@param tex Texture
	local removeDefaultPadding = function(tex)
		tex:ClearAllPoints()
		tex:SetWidth(btn:GetWidth() * 1.2)
		tex:SetHeight(btn:GetHeight() * 1.2)
		tex:SetPoint("Center", btn, "Center")
	end
	removeDefaultPadding(btn:GetCheckedTexture())
	removeDefaultPadding(btn:GetNormalTexture())
	removeDefaultPadding(btn:GetHighlightTexture())
	removeDefaultPadding(btn:GetPushedTexture())

	wrapper:SetHeight(btn:GetHeight())
	wrapper:SetWidth(btn:GetWidth() + QUIVER.Size.Gap + btn.Text:GetWidth())
	return wrapper
end

return {
	Create = Create,
}
