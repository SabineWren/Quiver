--[[
WoW persists positions for frames that have global names.
However, we use custom meta (size+position) logic because
otherwise each login clears all frame data for disabled addons.
We use TopLeft origin because GetPoint() uses TopLeft
]]

-- Frames to show if and only if UI unlocked
Quiver_UI_FrameMeta_InteractiveFrames = {}

local absClamp = function(vOpt, vMax)
	local fallback = vMax / 2
	if vOpt == nil then return fallback end

	local v = math.abs(vOpt)
	if v > 0 and v < vMax
	then return v
	else return fallback
	end
end

local GRIP_HANDLE = "Interface\\AddOns\\Quiver\\Textures\\grip-handle"
local createResizeGripHandle = function(parent, meta)
	local f = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	if Quiver_Store.IsLockedFrames then f:Hide() else f:Show() end
	tinsert(Quiver_UI_FrameMeta_InteractiveFrames, f)

	f:SetWidth(QUIVER_SIZE.Icon)
	f:SetHeight(QUIVER_SIZE.Icon)
	f:SetPoint("BottomRight", parent, "BottomRight", -2, 2)

	f:SetNormalTexture(GRIP_HANDLE)
	f:SetHighlightTexture(GRIP_HANDLE)
	f:SetPushedTexture(nil)
	f:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
	f:GetHighlightTexture():SetTexCoord(0, 1, 0, 1)
	f:GetHighlightTexture():SetBlendMode("ADD")

	parent:SetResizable(true)
	f:EnableMouse(true)
	f:SetScript("OnMouseDown", function()
		if not Quiver_Store.IsLockedFrames then
			parent:StartSizing("BottomRight")
		end
	end)
	f:SetScript("OnMouseUp", function()
		parent:StopMovingOrSizing()
		meta.W = parent:GetWidth()
		meta.H = parent:GetHeight()
	end)
	return f
end

Quiver_UI_FrameMeta_Customize = function(f, meta, widthDefault, heightDefault)
	meta.W = meta.W or widthDefault
	meta.H = meta.H or heightDefault
	f:SetWidth(meta.W)
	f:SetHeight(meta.H)
	f:SetMinResize(widthDefault, heightDefault)
	f:SetMaxResize(widthDefault*2, heightDefault*2)

	local xMax = GetScreenWidth() - meta.W
	local yMax = GetScreenHeight() - meta.H
	local x = absClamp(meta.X, xMax)
	local y = -1 * absClamp(meta.Y, yMax)
	f:SetPoint("TopLeft", nil, "TopLeft", x, y)

	f:EnableMouse(true)
	f:SetMovable(true)
	f:SetScript("OnMouseDown", function()
		if not Quiver_Store.IsLockedFrames then f:StartMoving() end
	end)
	f:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		local _, _, _, x, y = f:GetPoint()
		meta.X = x
		meta.Y = y
	end)

	f.GripHandle = createResizeGripHandle(f, meta)
end
