local Config = require "Api/Config.wow.lua"
local Button = require "Component/Button.wow.lua"
local Const = require "Constants.pure.lua"
local L = require "Lib/Index.pure.lua"
local Nil = require "Lib/Nil.pure.lua"

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

local SideEffectRestoreSize = function(store, df)
	local m = store.FrameMeta or {}
	m.W = Nil.GetOr(m.W, df.w)
	m.H = Nil.GetOr(m.H, df.h)
	m.X = Nil.GetOr(m.X, Config.GetScreenWidthScaled() / 2 + df.dx)
	m.Y = Nil.GetOr(m.Y, -1 * Config.GetScreenHeightScaled() / 2 + df.dy)
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
	openWarning.Text:SetJustifyV("Middle")
	openWarning.Text:SetText(Quiver.T["Quiver Unlocked.Show config dialog with /qq or /quiver.\nClick the lock icon when done."])
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

local SideEffectMakeMoveable = function(f, store)
	f:SetClampedToScreen(true)
	f:SetWidth(store.FrameMeta.W)
	f:SetHeight(store.FrameMeta.H)
	f:SetMinResize(30, GRIP_HEIGHT)
	f:SetMaxResize(Config.GetScreenWidthScaled()/2, Config.GetScreenHeightScaled()/2)
	f:SetPoint("TopLeft", nil, "TopLeft", store.FrameMeta.X, store.FrameMeta.Y)

	f:SetScript("OnMouseDown", function()
		if not Quiver_Store.IsLockedFrames then f:StartMoving() end
	end)
	f:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		local _, _, _, x, y = f:GetPoint()
		store.FrameMeta.X = L.Round4(x)
		store.FrameMeta.Y = L.Round4(y)
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
			local delta = L.Round0(frame:GetWidth() - wOld)
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
