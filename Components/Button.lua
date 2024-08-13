---@param parent Frame
---@param layer DrawLayer
---@return Texture
local CreateHighlightTexture = function(parent, layer)
	local t = parent:CreateTexture(nil, layer)
	t.QuiverSetTexture = function(self, scale, texturePath)
		-- We could edit the texture file, but it's a raster image
		-- SetAllPoints() doesn't let us adjust padding
		-- SetTexCoord(0, 1, 0, 1) clips instead of overflowing
		-- This scaling approach is the easiest way to customize padding
		local parent = self:GetParent()
		self:SetWidth(parent:GetWidth() * scale)
		self:SetHeight(parent:GetHeight() * scale)
		self:SetPoint("Center", parent, "Center", 0, 0)
		self:SetTexture(texturePath)
	end
	t.QuiverHighlight = function(self)
		local r, g, b, _ = self:GetParent():GetTextColor()
		self:SetVertexColor(r+0.3, g-0.2, b)
	end
	t.QuiverResetColor = function(self)
		local r, g, b, _ = self:GetParent():GetTextColor()
		self:SetVertexColor(r, g, b)
	end
	t:QuiverResetColor()
	return t
end

local Create = function(args)
	local parent, size, tooltipText =
		args.Parent, args.Size, args.TooltipText
	local frame = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	frame:SetWidth(size)
	frame:SetHeight(size)

	frame:SetScript("OnEnter", function()
		frame.Texture:QuiverHighlight()
		if tooltipText ~= nil then
			GameTooltip:SetOwner(frame, "ANCHOR_RIGHT", 0)
			GameTooltip:AddLine(tooltipText)
			GameTooltip:Show()
		end
	end)
	frame:SetScript("OnLeave", function()
		frame.Texture:QuiverResetColor()
		GameTooltip:Hide()
		GameTooltip:ClearLines()
	end)

	frame.Texture = CreateHighlightTexture(frame, "OVERLAY")
	frame:SetNormalTexture(frame.Texture)
	-- Custom glow texture would go here
	--f:SetHighlightTexture(nil)
	frame:SetPushedTexture(nil)
	frame:SetDisabledTexture(nil)

	frame.QuiverDisable = function()
		frame:Disable()
		frame.Texture:SetVertexColor(0.6, 0.6, 0.6)
	end
	frame.QuiverEnable = function()
		frame:Enable()
		frame.Texture:QuiverResetColor()
	end
	return frame
end

return {
	Create = Create,
	CreateHighlightTexture = CreateHighlightTexture,
}
