-- ****** TODO ******
-- Since we have 2 dropdowns, let's make ONE of them differently:
-- Use LockHightlight() on the button
-- Set a highlight texture on the button to apply

---@param bag { Parent: Frame, Size: number, TooltipText?: string }
local Create = function(bag)
	local btn = CreateFrame("Button", nil, bag.Parent, "UIPanelButtonTemplate")
	btn:SetWidth(bag.Size)
	btn:SetHeight(bag.Size)

	local ta = btn:GetNormalTexture():GetTexture()
	local tb = btn:GetDisabledTexture():GetTexture()
	local tc = btn:GetHighlightTexture():GetTexture()
	local td = btn:GetPushedTexture():GetTexture()
	-- DEFAULT_CHAT_FRAME:AddMessage("Btn Normal: " .. ta)
	-- DEFAULT_CHAT_FRAME:AddMessage("Btn Disabl: " .. tb)
	-- DEFAULT_CHAT_FRAME:AddMessage("Btn Highli: " .. tc)
	-- DEFAULT_CHAT_FRAME:AddMessage("Btn Pushed: " .. td)

	if bag.TooltipText then
		btn:SetScript("OnEnter", function()
			GameTooltip:SetOwner(btn, "BottomLeft", 0)
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

---@param parent Frame
---@return Button
local Caret = function(parent, size)
	local btn = Create({ Parent=parent, Size=size })

	local texNormal = btn:CreateTexture(nil, "OVERLAY")
	local texHighlight = btn:CreateTexture(nil, "OVERLAY")
	btn:SetNormalTexture(texNormal)
	btn:SetHighlightTexture(texHighlight)
	btn:SetPushedTexture(nil)
	btn:SetDisabledTexture(nil)

	local r, g, b, _ = btn:GetTextColor()
	texNormal:SetVertexColor(r, g, b)
	texHighlight:SetVertexColor(r+0.3, g-0.2, b)
	texHighlight:SetBlendMode("BLEND")

	-- We could edit the texture file, but it's a raster image
	-- SetAllPoints() doesn't let us adjust padding
	-- SetTexCoord(0, 1, 0, 1) clips instead of overflowing
	-- This scaling approach is the easiest way to customize padding
	-- UPDATE -- this is a stupid approach
	-- See instead:
	-- Texture:SetTexCoord overload for affine transformations
	-- Texture:SetTexCoordModifiesRect
	local resizeTexture = function(tex, scale)
		local path = QUIVER.Icon.CaretDown
		tex:SetWidth(btn:GetWidth() * scale)
		tex:SetHeight(btn:GetHeight() * scale)
		tex:SetPoint("Center", btn, "Center", 0, 0)
		tex:SetTexture(path)
	end
	resizeTexture(texNormal, 0.7)
	resizeTexture(texHighlight, 0.7)

	return btn
end

return {
	Caret = Caret,
	Create = Create,
}
