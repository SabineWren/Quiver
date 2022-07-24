local LOCK_OPEN = "Interface\\AddOns\\Quiver\\Textures\\lock-open"
local LOCK_CLOSED = "Interface\\AddOns\\Quiver\\Textures\\lock"

Quiver_UI_Button_ToggleLock = function(p)
	local f = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
	f:SetWidth(16)
	f:SetHeight(16)
	f:SetPoint("TopRight", p, "TopRight", -40, -16)

	f:SetNormalTexture(Quiver_Store.IsLockedFrames and LOCK_CLOSED or LOCK_OPEN)
	f:SetHighlightTexture(nil)
	f:SetPushedTexture(nil)
	local tex = f:GetNormalTexture()
	tex:SetTexCoord(0, 1, 0, 1)

	f:SetScript("OnClick", function()
		Quiver_Store.IsLockedFrames = not Quiver_Store.IsLockedFrames
		if Quiver_Store.IsLockedFrames
		then f:SetNormalTexture(LOCK_CLOSED)
		else f:SetNormalTexture(LOCK_OPEN)
		end
	end)

	local r, g, b = f:GetTextColor()
	tex:SetVertexColor(r, g, b)
	f:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0)
		GameTooltip:AddLine("Lock/Unlock Frames")
		GameTooltip:Show()
		tex:SetVertexColor(r+0.3, g-0.2, b)
	end)
	f:SetScript("OnLeave", function()
		GameTooltip:Hide()
		GameTooltip:ClearLines()
		tex:SetVertexColor(r, g, b)
	end)
	return f
end
