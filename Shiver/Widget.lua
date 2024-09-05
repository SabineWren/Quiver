---@param anchor Frame
---@return FrameAnchor
---@nodiscard
local calcBestAnchorSide = function(anchor)
	local screenW = GetScreenWidth()
	local center = screenW / 2.0

	-- TODO library coalesce
	local leftNil = anchor:GetLeft()
	local rightNil = anchor:GetRight()
	local left = leftNil and leftNil or 0
	local right = rightNil and rightNil or screenW

	-- TODO library psi combinator
	local dLeft = math.abs(center - left)
	local dRight = math.abs(center - right)
	return dLeft < dRight and "ANCHOR_BOTTOMRIGHT" or "ANCHOR_BOTTOMLEFT"
end

-- TODO figure out how to let caller specify preferred side, then
-- flip if there isn't enough room for tooltip. This is hard because
-- we don't know how big the tooltip is until after rendering it.
---@param anchor Frame
---@param x? number
---@param y? number
---@return nil
local PositionTooltip = function(anchor, x, y)
	local anchorSide = calcBestAnchorSide(anchor)
	-- TODO library coalesce
	local xx = (x and x or 0)
	local yy = (y and y or 0) + anchor:GetHeight()
	GameTooltip:SetOwner(anchor, anchorSide, xx, yy)
end

return {
	PositionTooltip = PositionTooltip,
}
