local colourize = function(p)
	local texture, isHighlight = p.Texture, p.IsHighlight
	local r, g, b = texture:GetParent():GetTextColor()
	if isHighlight
	then texture:SetVertexColor(r+0.3, g-0.2, b)
	else texture:SetVertexColor(r, g, b)
	end
end

local createIconButton = function(p)
	local parent, texturePath, tooltipText = p.Parent, p.TexturePath, p.TooltipText

	local f = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	f:SetWidth(QUIVER_SIZE.Icon)
	f:SetHeight(QUIVER_SIZE.Icon)

	f:SetNormalTexture(texturePath)
	--f:SetHighlightTexture(nil)
	f:SetPushedTexture(nil)

	local texture = f:GetNormalTexture()
	texture:SetTexCoord(0, 1, 0, 1)
	colourize({ Texture=texture, IsHighlight=false })
	f:SetScript("OnEnter", function()
		GameTooltip:SetOwner(f, "ANCHOR_RIGHT", 0)
		GameTooltip:AddLine(tooltipText)
		GameTooltip:Show()
		colourize({ Texture=texture, IsHighlight=true })
	end)
	f:SetScript("OnLeave", function()
		GameTooltip:Hide()
		GameTooltip:ClearLines()
		colourize({ Texture=texture, IsHighlight=false })
	end)

	return f
end

Quiver_UI_Button_Close = function(p)
	local f = createIconButton({
		Parent = p,
		TexturePath = "Interface\\AddOns\\Quiver\\Textures\\xmark",
		TooltipText = "Close Window",
	})
	local texture = f:GetNormalTexture()
	texture:ClearAllPoints()
	texture:SetWidth(f:GetWidth() * 0.75)
	texture:SetHeight(f:GetHeight() * 0.75)
	texture:SetPoint("Center", 0, 0)
	return f
end

Quiver_UI_Button_Reset = function(p, tooltip)
	local f = createIconButton({
		Parent = p,
		TexturePath = "Interface\\AddOns\\Quiver\\Textures\\arrow-rotate-right",
		TooltipText = tooltip,
	})
	local texture = f:GetNormalTexture()
	texture:ClearAllPoints()
	texture:SetWidth(f:GetWidth() * 0.75)
	texture:SetHeight(f:GetHeight() * 0.75)
	texture:SetPoint("Center", 0, 0)
	return f
end

Quiver_UI_Button_ToggleLock = function(p)
	local LOCK_OPEN = "Interface\\AddOns\\Quiver\\Textures\\lock-open"
	local LOCK_CLOSED = "Interface\\AddOns\\Quiver\\Textures\\lock"
	local f = createIconButton({
		Parent = p,
		TexturePath = Quiver_Store.IsLockedFrames and LOCK_CLOSED or LOCK_OPEN,
		TooltipText = "Lock/Unlock Frames",
	})
	f:SetScript("OnClick", function()
		Quiver_Store.IsLockedFrames = not Quiver_Store.IsLockedFrames
		if Quiver_Store.IsLockedFrames
		then f:SetNormalTexture(LOCK_CLOSED)
		else f:SetNormalTexture(LOCK_OPEN)
		end
	end)
	return f
end
