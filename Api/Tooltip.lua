local L = require "Lib/Index.lua"

-- TODO figure out how to let caller specify preferred side, then
-- flip if there isn't enough room for tooltip. This is hard because
-- we don't know how big the tooltip is until after rendering it.
---@param anchor Frame
---@param x? number
---@param y? number
---@return nil
local Position = function(anchor, x, y)
	local screenW = GetScreenWidth()
	local center = screenW / 2.0

	local closestAnchorSide = L.Psi(
		function(a, b) return a < b and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_BOTTOMLEFT" end,
		function(a) return math.abs(center - a) end,
		L.Nil.GetOr(anchor:GetLeft(), 0),
		L.Nil.GetOr(anchor:GetRight(), screenW)
	)

	local xx = L.Nil.GetOr(x, 0)
	local yy = L.Nil.GetOr(y, 0) + anchor:GetHeight()
	GameTooltip:SetOwner(anchor, closestAnchorSide, xx, yy)
end

--- Creates a scanning tooltip for later use
---@param name string Name of global tooltip frame
---@return GameTooltip
---@nodiscard
local createTooltip = function(name)
	local tt = CreateFrame("GameTooltip", name, nil, "GameTooltipTemplate")
	tt:SetScript("OnHide", function() tt:SetOwner(WorldFrame, "ANCHOR_NONE") end)
	tt:Hide()
	tt:SetFrameStrata("TOOLTIP")
	return tt
end

-- ************ Scanning ************
local _TOOLTIP_NAME = "QuiverScanningTooltip"
local tooltip = createTooltip(_TOOLTIP_NAME)

---@param fsName "TextLeft" | "TextRight"
---@param lineNumber integer
---@return nil|string
local GetText = function(fsName, lineNumber)
	---@type nil|FontString
	local fs = _G[_TOOLTIP_NAME .. fsName .. lineNumber]
	return fs and fs:GetText()
end

--- Handles setup and teardown when scanning.
---@generic Output
---@param f fun(t: GameTooltip): Output
---@return Output
---@nodiscard
local Scan = function(f)
	tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	local output = f(tooltip)
	tooltip:Hide()
	return output
end

return {
	GetText = GetText,
	Position = Position,
	Scan = Scan,
}
