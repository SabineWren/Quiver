local GAP = QUIVER.Size.Gap

Quiver_Component_EditBox = function(parent, p)
	tooltipReset = p.TooltipReset

	local f = CreateFrame("EditBox", nil, parent)
	f:SetWidth(300)
	f:SetHeight(25)

	local GAP_RESET = 4
	local fMarginLeft = QUIVER.Size.Border + GAP
	local fMarginRight = QUIVER.Size.Border + GAP + QUIVER.Size.Icon + GAP_RESET

	f.BtnReset = Quiver_Component_Button({
		Parent=f, Size=QUIVER.Size.Icon,
		TooltipText=tooltipReset,
	})
	f.BtnReset.Texture:QuiverSetTexture(0.75, QUIVER.Icon.Reset)
	f.BtnReset:SetPoint("Right", f, "Right", GAP_RESET + f.BtnReset:GetWidth(), 0)

	f:SetPoint("Left", parent, "Left", fMarginLeft, 0)
	f:SetPoint("Right", parent, "Right", -fMarginRight, 0)
	f:SetTextColor(.5, 1, .8, 1)
	f:SetJustifyH("Left")
	f:SetMaxLetters(50)

	f:SetFontObject(GameFontNormalSmall)

	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
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
	return f
end
