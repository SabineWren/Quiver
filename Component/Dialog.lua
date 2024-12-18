local Const = require "Constants.lua"

---@param padding number
---@param frameName nil|string
---@return Frame
---@nodiscard
local Create = function(padding, frameName)
	local f = CreateFrame("Frame", frameName, UIParent)
	f:Hide()
	f:SetFrameStrata("DIALOG")
	f:SetPoint("Center", nil, "Center", 0, 0)
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
	f:SetScript("OnMouseDown", function() f:StartMoving() end)
	f:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

	local btnCloseBottom = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	btnCloseBottom:SetWidth(70)
	btnCloseBottom:SetHeight(Const.Size.Button)
	btnCloseBottom:SetPoint("BottomRight", f, "BottomRight", -padding, padding)
	btnCloseBottom:SetText(Quiver.T["Close"])
	btnCloseBottom:SetScript("OnClick", function() f:Hide() end)

	return f
end

return {
	Create = Create,
}
