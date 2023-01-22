Quiver_Component_Button_CreateTexture = function(parent, layer)
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

Quiver_Component_Button = function(args)
	local parent, size, tooltipText =
		args.Parent, args.Size, args.TooltipText
	local f = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	f:SetWidth(size)
	f:SetHeight(size)

	f:SetScript("OnEnter", function()
		f.Texture:QuiverHighlight()
		if tooltipText ~= nil then
			GameTooltip:SetOwner(f, "ANCHOR_RIGHT", 0)
			GameTooltip:AddLine(tooltipText)
			GameTooltip:Show()
		end
	end)
	f:SetScript("OnLeave", function()
		f.Texture:QuiverResetColor()
		GameTooltip:Hide()
		GameTooltip:ClearLines()
	end)

	f.Texture = Quiver_Component_Button_CreateTexture(f, "OVERLAY")
	f:SetNormalTexture(f.Texture)
	-- Custom glow texture would go here
	--f:SetHighlightTexture(nil)
	f:SetPushedTexture(nil)
	f:SetDisabledTexture(nil)

	f.QuiverDisable = function()
		f:Disable()
		f.Texture:SetVertexColor(0.6, 0.6, 0.6)
	end
	f.QuiverEnable = function()
		f:Enable()
		f.Texture:QuiverResetColor()
	end
	return f
end
