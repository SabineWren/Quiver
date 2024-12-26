local Button = require "Component/Button.lua"
local Const = require "Constants.lua"

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
local SideEffectRestoreSize = function(store, args)
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
local Init = function()
	openWarning = CreateFrame("Frame", nil, UIParent)
	openWarning:SetFrameStrata("MEDIUM")
	openWarning.Text = openWarning:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	openWarning.Text:SetAllPoints(openWarning)
	openWarning.Text:SetJustifyH("Center")
	openWarning.Text:SetJustifyV("Center")
	openWarning.Text:SetText(Quiver.T["Quiver Unlocked. Show config dialog with /qq or /quiver.\nClick the lock icon when done."])
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
	then frame.QuiverGripHandle.Container:Hide()
	else frame:SetResizable(true)
	end
	table.insert(framesResizeable, frame)
end

local lockFrames = function()
	openWarning:Hide()
	for _i, v in ipairs(framesMoveable) do
		v:EnableMouse(false)
		v:SetMovable(false)
	end
	for _i, v in ipairs(framesResizeable) do
		v.QuiverGripHandle.Container:Hide()
		v:SetResizable(false)
	end
	for _i, v in ipairs(_G.Quiver_Modules) do
		if Quiver_Store.ModuleEnabled[v.Id] then v.OnInterfaceLock() end
	end
end
local unlockFrames = function()
	openWarning:Show()
	for _i, v in ipairs(framesMoveable) do
		v:EnableMouse(true)
		v:SetMovable(true)
	end
	for _i, v in ipairs(framesResizeable) do
		v.QuiverGripHandle.Container:Show()
		v:SetResizable(true)
	end
	for _i, v in ipairs(_G.Quiver_Modules) do
		if Quiver_Store.ModuleEnabled[v.Id] then v.OnInterfaceUnlock() end
	end
end

local SetIsLocked = function(isChecked)
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


---@param a number
---@return integer
local round = function(a)
	return math.floor(a + 0.5)
end
---@param a number
---@return integer
local round4 = function(a)
	return math.floor(a / 4 + 0.5) * 4
end

local SideEffectMakeMoveable = function(f, store)
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
		store.FrameMeta.X = round4(x)
		store.FrameMeta.Y = round4(y)
		f:SetPoint("TopLeft", nil, "TopLeft", store.FrameMeta.X, store.FrameMeta.Y)
	end)

	addFrameMoveable(f)
end

local SideEffectMakeResizeable = function(frame, store, args)
	local margin, isCenterX, onResizeEnd, onResizeDrag =
		args.GripMargin, args.IsCenterX, args.OnResizeEnd, args.OnResizeDrag

	if isCenterX then
		frame:SetScript("OnSizeChanged", function()
			local wOld = store.FrameMeta.W
			local delta = round(frame:GetWidth() - wOld)
			store.FrameMeta.W = wOld + 2 * delta
			store.FrameMeta.X = store.FrameMeta.X - delta
			frame:SetWidth(store.FrameMeta.W)
			frame:SetPoint("TopLeft", store.FrameMeta.X, store.FrameMeta.Y)
			if onResizeDrag ~= nil then onResizeDrag() end
		end)
	elseif onResizeDrag ~= nil then
		frame:SetScript("OnSizeChanged", onResizeDrag)
	end

	local handle = Button:Create(frame, Const.Icon.GripHandle, nil, 0.5)
	addFrameResizable(frame, handle)
	handle.Container:SetFrameLevel(100)-- Should be top element
	handle.Container:SetPoint("BottomRight", frame, "BottomRight", -margin, margin)

	handle.HookMouseDown = function()
		if frame:IsResizable() then frame:StartSizing("BottomRight") end
	end
	handle.HookMouseUp = function()
		frame:StopMovingOrSizing()
		store.FrameMeta.W = math.floor(frame:GetWidth() + 0.5)
		store.FrameMeta.H = math.floor(frame:GetHeight() + 0.5)
		frame:SetWidth(store.FrameMeta.W)
		frame:SetHeight(store.FrameMeta.H)
		if onResizeEnd ~= nil then onResizeEnd() end
	end
end

return {
	Init = Init,
	SetIsLocked = SetIsLocked,
	SideEffectMakeMoveable = SideEffectMakeMoveable,
	SideEffectMakeResizeable = SideEffectMakeResizeable,
	SideEffectRestoreSize = SideEffectRestoreSize,
}
