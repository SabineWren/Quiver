--[[
WoW persists positions for frames that have global names.
However, we use custom meta (size+position) logic because
otherwise each login clears all frame data for disabled addons.
We use TopLeft origin because GetPoint() uses TopLeft
]]

local GRIP_HEIGHT = 12

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

local createResizeGripHandle = function(parent, meta, gripOptions)
	local margin = gripOptions.GripMargin
	local f = Quiver_Component_Button({ Parent=parent, Size=GRIP_HEIGHT })
	if Quiver_Store.IsLockedFrames then f:Hide() else f:Show() end
	tinsert(Quiver_UI_FrameMeta_InteractiveFrames, f)

	local scale = 0.5
	f.Texture:QuiverSetTexture(scale, QUIVER.Icon.GripHandle)
	f.HighlightTexture = Quiver_Components_Button_CreateTexture(f, "OVERLAY")
	f:SetHighlightTexture(f.HighlightTexture)
	f.HighlightTexture:QuiverSetTexture(scale, QUIVER.Icon.GripHandle)

	f:SetPoint("BottomRight", parent, "BottomRight", -margin, margin)

	parent:SetResizable(true)
	f:SetScript("OnMouseDown", function()
		if not Quiver_Store.IsLockedFrames then
			parent:StartSizing("BottomRight")
			if parent.QuiverOnResizeStart ~= nil then parent.QuiverOnResizeStart() end
		end
	end)
	f:SetScript("OnMouseUp", function()
		parent:StopMovingOrSizing()
		meta.W = math.floor(parent:GetWidth() / 2) * 2
		meta.H = math.floor(parent:GetHeight() / 2) * 2
		parent:SetWidth(meta.W)
		parent:SetHeight(meta.H)
		if parent.QuiverOnResizeEnd ~= nil then parent.QuiverOnResizeEnd() end
	end)
	return f
end

Quiver_UI_FrameMeta_Customize = function(f, meta, gripOptions)
	f:SetWidth(meta.W)
	f:SetHeight(meta.H)
	f:SetMinResize(30, GRIP_HEIGHT)
	f:SetMaxResize(GetScreenWidth()/2, GetScreenHeight()/2)

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
		meta.X = math.floor(x)
		meta.Y = math.floor(y)
		f:SetPoint("TopLeft", nil, "TopLeft", meta.X, meta.Y)
	end)

	f.GripHandle = createResizeGripHandle(f, meta, gripOptions)
end
