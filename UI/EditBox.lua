Quiver_UI_EditBox = function(p)
	local parent, y, label, textValue, onChange =
		p.Parent, p.Y, p.Label, p.Text, p.OnChange

	local f = CreateFrame("EditBox", nil, parent)-- "InputBoxTemplate"
	f:SetText(textValue)
	f:SetTextColor(.5, 1, .8, 1)
	f:SetJustifyH("Left")
	f:SetMaxLetters(50)
	f:SetWidth(200)
	f:SetHeight(25)
	f:SetPoint("Left", parent, "Left", 60, 0)
	f:SetPoint("Right", parent, "Right", -20, 0)
	f:SetPoint("Top", parent, "Top", 0, y)
	f:SetFontObject(GameFontNormalSmall)

	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 10,
		insets = { left=3, right=3, top=3, bottom=3 },
	})
	f:SetBackdropColor(0, 0, 0, 1)
	f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	f:SetTextInsets(6,6,0,0)

	f:SetAutoFocus(false)
	f:SetScript("OnEscapePressed", function() f:ClearFocus() end)
	f:SetScript("OnEnterPressed", function() f:ClearFocus() end)
	f:SetScript("OnTextChanged", function() onChange(f:GetText()) end)

	f.text = f:CreateFontString("Status", "LOW", "GameFontNormalSmall")
	f.text:SetPoint("Left", f, "Left", -40, 0)
	f.text:SetPoint("Right", f, "Left", 0, 0)
	f.text:SetJustifyH("Center")
	f.text:SetText(label)
	return f
end
