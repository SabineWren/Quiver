local Button = require "Component/Button.lua"
local Const = require "Constants.lua"

local _GAP = Const.Size.Gap
local _GAP_RESET = 4

---@class (exact) QqEditBox
---@field private __index? QqEditBox
---@field Box EditBox
---@field Reset QqButton
local QqEditBox = {}

---@param parent Frame
---@param tooltipText string
---@return QqEditBox
function QqEditBox:Create(parent, tooltipText)
	local box = CreateFrame("EditBox", nil, parent)
	box:SetWidth(300)
	box:SetHeight(25)

	---@type QqEditBox
	local r = {
		Box = box,
		Reset = Button:Create(box, Const.Icon.Reset),
	}
	setmetatable(r, self)
	self.__index = self
	r.Reset.TooltipText = tooltipText

	local fMarginLeft = Const.Size.Border + _GAP
	local fMarginRight = Const.Size.Border + _GAP + Const.Size.Icon + _GAP_RESET

	local xr = r.Reset.Container:GetWidth() + _GAP_RESET
	r.Reset.Container:SetPoint("Right", box, "Right", xr, 0)

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
	return r
end

return QqEditBox
