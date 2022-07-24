Quiver_UI_Dialog = function(width, height)
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetWidth(width)
	f:SetHeight(height)
	f:SetPoint("Center", 0, 0)
	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left=8, right=8, top=8, bottom=8 },
	})
	f:SetBackdropColor(0, 0, 0, 0.6)
	f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetScript("OnMouseDown", function() this:StartMoving() end)
	f:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)

	local btnCloseTop = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	btnCloseTop:SetPoint("TopRight", f, "TopRight", -8, -8)

	local btnCloseBottom = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	btnCloseBottom:SetWidth(70)
	btnCloseBottom:SetHeight(18)
	btnCloseBottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 12)
	btnCloseBottom:SetText("Close")
	btnCloseBottom:SetScript("OnClick", function() f:Hide() end)

	return f
end
