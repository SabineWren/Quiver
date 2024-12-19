local L = require "Shiver/Lib/All.lua"

-- TODO figure out how to let caller specify preferred side, then
-- flip if there isn't enough room for tooltip. This is hard because
-- we don't know how big the tooltip is until after rendering it.
---@param anchor Frame
---@param x? number
---@param y? number
---@return nil
local PositionTooltip = function(anchor, x, y)
	local screenW = GetScreenWidth()
	local center = screenW / 2.0

	local closestAnchorSide = L.Psi(
		function(a, b) return a < b and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_BOTTOMLEFT" end,
		function(a) return math.abs(center - a) end,
		L.GetNil(anchor:GetLeft(), 0),
		L.GetNil(anchor:GetRight(), screenW)
	)

	local xx = L.GetNil(x, 0)
	local yy = L.GetNil(y, 0) + anchor:GetHeight()
	GameTooltip:SetOwner(anchor, closestAnchorSide, xx, yy)
end

return {
	PositionTooltip = PositionTooltip,
}
