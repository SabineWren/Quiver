Quiver_UI_WithWindowTitle = function(window, titleText)
	local f = CreateFrame("Frame", nil, window)
	local fs = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetAllPoints(f)
	fs:SetJustifyH("Center")
	fs:SetJustifyV("Center")
	fs:SetText(titleText)

	f:SetWidth(fs:GetStringWidth() + 30)
	f:SetHeight(35)
	f:SetPoint("Center", window, "Top", 0, -10)
	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		tile = true,
		tileSize = 24,
		edgeSize = 24,
		insets = { left=8, right=8, top=8, bottom=8 },
	})
	-- TODO figure out how to clip parent frame instead of 100% opacity
	f:SetBackdropColor(0, 0, 0, 1)
	f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	return window
end
