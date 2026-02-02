---@param parent Frame
---@param text string
---@return Frame
local Create = function(parent, text)
	local f = CreateFrame("Frame", nil, parent)
	local fs = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetAllPoints(f)
	fs:SetJustifyH("Center")
	fs:SetJustifyV("Middle")
	fs:SetText(text)

	f:SetWidth(fs:GetStringWidth() + 30)
	f:SetHeight(35)
	f:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		tile = true,
		tileSize = 24,
		edgeSize = 24,
		insets = { left=8, right=8, top=8, bottom=8 },
	})
	-- TODO figure out how to clip parent frame instead of 100% opacity.
	f:SetBackdropColor(0, 0, 0, 1)
	f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	return f
end

return {
	Create = Create,
}
