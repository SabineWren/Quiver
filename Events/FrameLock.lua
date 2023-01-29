--[[
WoW persists positions for frames that have global names.
However, we use custom meta (size+position) logic because
otherwise each login clears all frame data for disabled addons.
TopLeft origin because GetPoint() uses TopLeft


Must use entire store as parameter for functions, because we reset by setting FrameMeta to null.
If we only pass FrameMeta, then several event listeners will mutate the wrong object.
]]

local GRIP_HEIGHT = 12
local framesMoveable = {}
local framesResizeable = {}
local openWarning

-- Screensize scales after initializing, but when it does, the UI scale value also changes.
-- Therefore, the result of size * scale never changes, but the result of either size or scale does.
-- Disabling useUIScale doesn't affect the scale value, so we have to conditionally scale saved frame positions.
local getRealScreenWidth = function()
	local scale = GetCVar("useUiScale") == 1 and UIParent:GetEffectiveScale() or 1
	return GetScreenWidth() * scale
end
local getRealScreenheight = function()
	local scale = GetCVar("useUiScale") == 1 and UIParent:GetEffectiveScale() or 1
	return GetScreenHeight() * scale
end

local defaultOf = function(val, fallback)
	if val == nil then return fallback else return val end
end
Quiver_Event_FrameLock_SideEffectRestoreSize = function(store, args)
	local sw = getRealScreenWidth()
	local sh = getRealScreenheight()

	local m = store.FrameMeta or {}
	local w, h, dx, dy = args.w, args.h, args.dx, args.dy
	m.W = defaultOf(m.W, w)
	m.H = defaultOf(m.H, h)
	m.X = defaultOf(m.X, sw / 2 + dx)
	m.Y = defaultOf(m.Y, -1 * sh / 2 + dy)
	store.FrameMeta = m
end

-- Tons of users don't read the readme file AT ALL. Not even the first line!
-- We have to guide and strongly encourage them to lock the frames.
Quiver_Event_FrameLock_Init = function()
	openWarning = CreateFrame("Frame", nil, UIParent)
	openWarning:SetFrameStrata("Medium")
	openWarning.Text = openWarning:CreateFontString(nil, "Medium", "GameFontNormal")
	openWarning.Text:SetAllPoints(openWarning)
	openWarning.Text:SetJustifyH("Center")
	openWarning.Text:SetJustifyV("Center")
	openWarning.Text:SetText(QUIVER_T.UI.WarnUnlocked)
	openWarning.Text:SetTextColor(1, 1, 1)
	openWarning:SetAllPoints(UIParent)
	if Quiver_Store.IsLockedFrames
	then openWarning:Hide()
	else openWarning:Show()
	end
end

local addFrameMoveable = function(frame)
	if not Quiver_Store.IsLockedFrames then
		frame:EnableMouse(true)
		frame:SetMovable(true)
	end
	table.insert(framesMoveable, frame)
end
local addFrameResizable = function(frame, handle)
	frame.QuiverGripHandle = handle
	if Quiver_Store.IsLockedFrames
	then handle:Hide()
	else frame:SetResizable(true)
	end
	table.insert(framesResizeable, frame)
end

local lockFrames = function()
	openWarning:Hide()
	for _k, f in framesMoveable do
		f:EnableMouse(false)
		f:SetMovable(false)
	end
	for _k, f in framesResizeable do
		f.QuiverGripHandle:Hide()
		f:SetResizable(false)
	end
	for _k, v in _G.Quiver_Modules do
		if Quiver_Store.ModuleEnabled[v.Id] then v.OnInterfaceLock() end
	end
end
local unlockFrames = function()
	openWarning:Show()
	for _k, f in framesMoveable do
		f:EnableMouse(true)
		f:SetMovable(true)
	end
	for _k, f in framesResizeable do
		f.QuiverGripHandle:Show()
		f:SetResizable(true)
	end
	for _k, v in _G.Quiver_Modules do
		if Quiver_Store.ModuleEnabled[v.Id] then v.OnInterfaceUnlock() end
	end
end

Quiver_Event_FrameLock_Set = function(isChecked)
	Quiver_Store.IsLockedFrames = isChecked
	if isChecked then lockFrames() else unlockFrames() end
end

local absClamp = function(vOpt, vMax)
	local fallback = vMax / 2
	if vOpt == nil then return fallback end

	local v = math.abs(vOpt)
	if v > 0 and v < vMax
	then return v
	else return fallback
	end
end

Quiver_Event_FrameLock_SideEffectMakeMoveable = function(f, store)
	f:SetWidth(store.FrameMeta.W)
	f:SetHeight(store.FrameMeta.H)
	f:SetMinResize(30, GRIP_HEIGHT)
	local sw = getRealScreenWidth()
	local sh = getRealScreenheight()
	f:SetMaxResize(sw/2, sh/2)

	local xMax = sw - store.FrameMeta.W
	local yMax = sh - store.FrameMeta.H
	local x = absClamp(store.FrameMeta.X, xMax)
	local y = -1 * absClamp(store.FrameMeta.Y, yMax)
	f:SetPoint("TopLeft", nil, "TopLeft", x, y)
	f:SetScript("OnMouseDown", function()
		if not Quiver_Store.IsLockedFrames then f:StartMoving() end
	end)
	f:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		local _, _, _, x, y = f:GetPoint()
		store.FrameMeta.X = math.floor(x)
		store.FrameMeta.Y = math.floor(y)
		f:SetPoint("TopLeft", nil, "TopLeft", store.FrameMeta.X, store.FrameMeta.Y)
		DEFAULT_CHAT_FRAME:AddMessage("resize " .. store.FrameMeta.X)
	end)

	addFrameMoveable(f)
end

Quiver_Event_FrameLock_SideEffectMakeResizeable = function(frame, store, args)
	local margin, isCenterX, onResizeEnd, onResizeDrag =
		args.GripMargin, args.IsCenterX, args.OnResizeEnd, args.OnResizeDrag

	if isCenterX then
		frame:SetScript("OnSizeChanged", function()
			local wOld = store.FrameMeta.W
			local delta = frame:GetWidth() - wOld
			store.FrameMeta.W = wOld + 2 * delta
			store.FrameMeta.X = store.FrameMeta.X - delta
			frame:SetWidth(store.FrameMeta.W)
			frame:SetPoint("TopLeft", store.FrameMeta.X, store.FrameMeta.Y)
			if onResizeDrag ~= nil then onResizeDrag() end
		end)
	elseif onResizeDrag ~= nil then
		frame:SetScript("OnSizeChanged", onResizeDrag)
	end

	local handle = Quiver_Component_Button({ Parent=frame, Size=GRIP_HEIGHT })
	addFrameResizable(frame, handle)
	handle:SetFrameLevel(100)-- Should be top element
	handle:SetPoint("BottomRight", frame, "BottomRight", -margin, margin)

	local scale = 0.5
	handle.Texture:QuiverSetTexture(scale, QUIVER.Icon.GripHandle)
	handle.HighlightTexture = Quiver_Component_Button_CreateTexture(handle, "OVERLAY")
	handle:SetHighlightTexture(handle.HighlightTexture)
	handle.HighlightTexture:QuiverSetTexture(scale, QUIVER.Icon.GripHandle)

	handle:SetScript("OnMouseDown", function()
		if frame:IsResizable() then frame:StartSizing("BottomRight") end
	end)
	handle:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
		store.FrameMeta.W = math.floor(frame:GetWidth() + 0.5)
		store.FrameMeta.H = math.floor(frame:GetHeight() + 0.5)
		frame:SetWidth(store.FrameMeta.W)
		frame:SetHeight(store.FrameMeta.H)
		if onResizeEnd ~= nil then onResizeEnd() end
	end)
end
