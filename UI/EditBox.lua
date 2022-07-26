local GAP = QUIVER_SIZE.Gap

local createBtnReset = function(parent, tooltipText)
	local f = Quiver_Component_Button({ Parent=parent, Size=16, TooltipText=tooltipText })
	local RESET = "Interface\\AddOns\\Quiver\\Textures\\arrow-rotate-right"
	f.Texture:QuiverSetTexture(0.75, RESET)
	return f
end

Quiver_UI_EditBox = function(p)
	local parent, yOffset, tooltipReset, textValue =
		p.Parent, p.YOffset, p.TooltipReset, p.Text

	local f = CreateFrame("EditBox", nil, parent)
	local fMarginLeft = QUIVER_SIZE.Border + GAP + QUIVER_SIZE.Icon + GAP
	local fMarginRight = QUIVER_SIZE.Border + GAP
	f:SetText(textValue)
	f:SetTextColor(.5, 1, .8, 1)
	f:SetJustifyH("Left")
	f:SetMaxLetters(50)
	f:SetHeight(25)
	f:SetPoint("Left", parent, "Left", fMarginLeft, 0)
	f:SetPoint("Right", parent, "Right", -fMarginRight, 0)
	f:SetPoint("Top", parent, "Top", 0, yOffset)
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

	f.BtnReset = createBtnReset(f, tooltipReset)
	f.BtnReset:SetPoint("Right", f, "Left", -GAP, 0)
	return f
end
