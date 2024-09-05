local Button = require "Component/Button.lua"
local ColorPicker = require "Component/ColorPicker.lua"
local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local Castbar = require "Modules/Castbar.lua"
local RangeIndicator = require "Modules/RangeIndicator.lua"
local Color = require "Shiver/Color.lua"
local L = require "Shiver/Lib/All.lua"

---@param c1 Color
---@param c2 Color
local createBtnColorSwap = function(parent, f1, f2, c1, c2)
	local f = Button:Create(parent, QUIVER.Icon.ArrowsSwap, QUIVER_T.UI.SwapColorsShort)
	f.TooltipText = QUIVER_T.UI.SwapColorsLong
	f.HookClick = function()
		-- Swap colors
		local r, g, b = c1:Rgb()
		c1:SetRgb(c2:Rgb())
		c2:SetRgb(r, g, b)

		-- Update preview button
		f1.Button:SetBackdropColor(c1:Rgb())
		f2.Button:SetBackdropColor(c2:Rgb())
	end

	return f
end

local Create = function(parent, gap)
	local storeAutoShotTimer = Quiver_Store.ModuleStore[AutoShotTimer.Id]
	local storeCastbar = Quiver_Store.ModuleStore[Castbar.Id]
	local storeRange = Quiver_Store.ModuleStore[RangeIndicator.Id]
	local f = CreateFrame("Frame", nil, parent)

	local colorShoot = Color:LiftReset(storeAutoShotTimer.ColorShoot, QUIVER.ColorDefault.AutoShotShoot)
	local colorReload = Color:LiftReset(storeAutoShotTimer.ColorReload, QUIVER.ColorDefault.AutoShotReload)
	local optionShoot = ColorPicker.CreateWithResetLabel(f, "Shooting", colorShoot)
	local optionReload = ColorPicker.CreateWithResetLabel(f, "Reloading", colorReload)

	local elements = {
		ColorPicker.CreateWithResetLabel(f, "Casting",
			Color:LiftReset(storeCastbar.ColorCastbar, QUIVER.ColorDefault.Castbar)),
		createBtnColorSwap(f, optionShoot, optionReload, colorShoot, colorReload),
		optionShoot,
		optionReload,
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.Melee,
			Color:LiftReset(storeRange.ColorMelee, QUIVER.ColorDefault.Range.Melee)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.DeadZone,
			Color:LiftReset(storeRange.ColorDeadZone, QUIVER.ColorDefault.Range.DeadZone)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.ScareBeast,
			Color:LiftReset(storeRange.ColorScareBeast, QUIVER.ColorDefault.Range.ScareBeast)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.ScatterShot,
			Color:LiftReset(storeRange.ColorScatterShot, QUIVER.ColorDefault.Range.ScatterShot)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.Short,
			Color:LiftReset(storeRange.ColorShort, QUIVER.ColorDefault.Range.Short)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.Long,
			Color:LiftReset(storeRange.ColorLong, QUIVER.ColorDefault.Range.Long)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.Mark,
			Color:LiftReset(storeRange.ColorMark, QUIVER.ColorDefault.Range.Mark)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.TooFar,
			Color:LiftReset(storeRange.ColorTooFar, QUIVER.ColorDefault.Range.TooFar)),
	}
	-- Right align buttons using minimum amount of space
	local labelMaxWidth = L.Array.MapReduce(
		elements,
		function(x) return x.Label and x.Label:GetWidth() or 0 end,
		L.Max,
		0
	)

	local y = 0
	for _,ele in elements do
		if ele.WidthMinusLabel ~= nil then
			ele.Container:SetWidth(ele.WidthMinusLabel + labelMaxWidth)
		end
		ele.Container:SetPoint("Left", f, "Left", 0, 0)
		ele.Container:SetPoint("Top", f, "Top", 0, -y)
		y = y + ele.Container:GetHeight() + gap
	end

	f:SetWidth(L.Array.MapReduce(elements, function(x) return x.Container:GetWidth() end, math.max, 0))
	f:SetHeight(y)
	return f
end

return {
	Create = Create,
}
