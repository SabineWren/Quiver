local Button = require "Component/Button.lua"

local _GAP = QUIVER.Size.Gap

---@class QqEditBox
---@field Box EditBox
---@field Reset QqButton

---@param parent Frame
---@param tooltipText string
---@return QqEditBox
local Create = function(parent, tooltipText)
	local box = CreateFrame("EditBox", nil, parent)
	box:SetWidth(300)
	box:SetHeight(25)

	---@type QqEditBox
	local eb = {
		Box = box,
		Reset = Button:Create(box, {
			TexPath = QUIVER.Icon.Reset,
			TooltipText = tooltipText,
		}),
	}


	local GAP_RESET = 4
	local fMarginLeft = QUIVER.Size.Border + _GAP
	local fMarginRight = QUIVER.Size.Border + _GAP + QUIVER.Size.Icon + GAP_RESET

	local xr = eb.Reset.Container:GetWidth() + GAP_RESET
	eb.Reset.Container:SetPoint("Right", box, "Right", xr, 0)

	box:SetPoint("Left", parent, "Left", fMarginLeft, 0)
	box:SetPoint("Right", parent, "Right", -fMarginRight, 0)
	box:SetTextColor(.5, 1, .8, 1)
	box:SetJustifyH("Left")
	box:SetMaxLetters(50)

	box:SetFontObject(GameFontNormalSmall)

	box:SetBackdrop({
		bgFile = "Interface/BUTTONS/WHITE8X8",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 10,
		insets = { left=3, right=3, top=3, bottom=3 },
	})
	box:SetBackdropColor(0, 0, 0, 1)
	box:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
	box:SetTextInsets(6,6,0,0)

	box:SetAutoFocus(false)
	box:SetScript("OnEscapePressed", function() box:ClearFocus() end)
	box:SetScript("OnEnterPressed", function() box:ClearFocus() end)
	return eb
end

return {
	Create = Create,
}
