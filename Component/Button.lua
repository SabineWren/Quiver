local Widget = require "Shiver/Widget.lua"

-- We could edit the texture file, but it's a raster image
-- SetAllPoints() doesn't let us adjust padding
-- SetTexCoord(0, 1, 0, 1) clips instead of overflowing
-- This scaling approach is the easiest way to customize padding
-- TODO -- this is a stupid approach to sizing
-- See instead:
-- Texture:SetTexCoord overload for affine transformations
-- Texture:SetTexCoordModifiesRect
---@param b Button
---@param path string
---@param scale number
---@return Texture
---@nodiscard
local createTexture = function(b, path, scale)
	local t = b:CreateTexture(nil, "OVERLAY")
	t:SetWidth(b:GetWidth() * scale)
	t:SetHeight(b:GetHeight() * scale)
	t:SetPoint("Center", b, "Center", 0, 0)
	t:SetTexture(path)
	return t
end

---@param bag { Parent: Frame, Size: number, Texture?: string, TooltipText?: string }
local Create = function(bag)
	local btn = CreateFrame("Button", nil, bag.Parent, "UIPanelButtonTemplate")
	btn:SetWidth(bag.Size)
	btn:SetHeight(bag.Size)

	if bag.Texture then
		local r, g, b, _ = btn:GetTextColor()
		local norm = createTexture(btn, bag.Texture, 0.7)
		local high = createTexture(btn, bag.Texture, 0.7)
		local push = createTexture(btn, bag.Texture, 0.7)
		local disa = createTexture(btn, bag.Texture, 0.7)

		btn:SetNormalTexture(norm)
		btn:SetHighlightTexture(high)
		btn:SetPushedTexture(push)
		btn:SetDisabledTexture(disa)

		norm:SetVertexColor(r, g, b)
		high:SetVertexColor(r+0.3, g-0.2, b-0.1)
		push:SetVertexColor(1.0, 0.0, 0.0)
		disa:SetVertexColor(0.3, 0.3, 0.3)

		-- This disables normal texture on hover so can darken instead of lighten.
		-- This doesn't work for pushed, and doesn't override transparency.
		high:SetBlendMode("DISABLE")
	end

	if bag.TooltipText then
		btn:SetScript("OnEnter", function()
			Widget.PositionTooltip(btn)
			GameTooltip:AddLine(bag.TooltipText)
			GameTooltip:Show()
		end)
		btn:SetScript("OnLeave", function()
			GameTooltip:Hide()
			GameTooltip:ClearLines()
		end)
	end

	return btn
end

return {
	Create = Create,
}
