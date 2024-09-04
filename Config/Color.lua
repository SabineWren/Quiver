local Button = require "Component/Button.lua"
local ColorPicker = require "Components/ColorPicker.lua"
local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local Castbar = require "Modules/Castbar.lua"
local RangeIndicator = require "Modules/RangeIndicator.lua"
local L = require "Shiver/Lib/All.lua"
local W = require "Shiver/Sugar.lua"

local createBtnColorSwap = function(parent, f1, f2, c1, c2)
	local f = Button:Create(parent, {
		LabelText = QUIVER_T.UI.SwapColorsShort,
		TexPath = QUIVER.Icon.ArrowsSwap,
		TooltipText = QUIVER_T.UI.SwapColorsLong,
	})
	f.OnClick = function()
		-- Swap colors
		local r, g, b = c1.Get()
		c1.Set(c2.R(), c2.G(), c2.B())
		c2.Set(r, g, b)
		-- Update preview button
		f1.Button:SetBackdropColor(c1.R(), c1.G(), c1.B(), 1)
		f2.Button:SetBackdropColor(c2.R(), c2.G(), c2.B(), 1)
	end

	return f
end

local Create = function(parent, gap)
	local storeAutoShotTimer = Quiver_Store.ModuleStore[AutoShotTimer.Id]
	local storeCastbar = Quiver_Store.ModuleStore[Castbar.Id]
	local storeRange = Quiver_Store.ModuleStore[RangeIndicator.Id]
	local f = CreateFrame("Frame", nil, parent)

	local wrap = ColorPicker.WrapColor
	local colorShoot = wrap(storeAutoShotTimer, "ColorShoot", QUIVER.ColorDefault.AutoShotShoot)
	local colorReload = wrap(storeAutoShotTimer, "ColorReload", QUIVER.ColorDefault.AutoShotReload)
	local optionShoot = ColorPicker.CreateWithResetLabel(f, "Shooting", colorShoot)
	local optionReload = ColorPicker.CreateWithResetLabel(f, "Reloading", colorReload)

	local elements = {
		ColorPicker.CreateWithResetLabel(f, "Casting",
			wrap(storeCastbar, "ColorCastbar", QUIVER.ColorDefault.Castbar)),
		createBtnColorSwap(f, optionShoot, optionReload, colorShoot, colorReload),
		optionShoot,
		optionReload,
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.Melee,
			wrap(storeRange, "ColorMelee", QUIVER.ColorDefault.Range.Melee)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.DeadZone,
			wrap(storeRange, "ColorDeadZone", QUIVER.ColorDefault.Range.DeadZone)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.ScareBeast,
			wrap(storeRange, "ColorScareBeast", QUIVER.ColorDefault.Range.ScareBeast)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.ScatterShot,
			wrap(storeRange, "ColorScatterShot", QUIVER.ColorDefault.Range.ScatterShot)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.Short,
			wrap(storeRange, "ColorShort", QUIVER.ColorDefault.Range.Short)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.Long,
			wrap(storeRange, "ColorLong", QUIVER.ColorDefault.Range.Long)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.Mark,
			wrap(storeRange, "ColorMark", QUIVER.ColorDefault.Range.Mark)),
		ColorPicker.CreateWithResetLabel(f, QUIVER_T.Range.TooFar,
			wrap(storeRange, "ColorTooFar", QUIVER.ColorDefault.Range.TooFar)),
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
