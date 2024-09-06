local Button = require "Component/Button.lua"
local ColorSwatch = require "Component/ColorSwatch.lua"
local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local Castbar = require "Modules/Castbar.lua"
local RangeIndicator = require "Modules/RangeIndicator.lua"
local Color = require "Shiver/Color.lua"
local L = require "Shiver/Lib/All.lua"

---@param c1 Color
---@param c2 Color
local createBtnColorSwap = function(parent, f1, f2, c1, c2)
	local f = Button:Create(parent, QUIVER.Icon.ArrowsSwap, Quiver.T["Shoot / Reload"])
	f.TooltipText = Quiver.T["Swap Shoot and Reload Colours"]
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

---@param f Frame
---@param label string
---@param store Rgb
---@param default Rgb
local swatch = function(f, label, store, default)
	local color = Color:LiftReset(store, default)
	return ColorSwatch:Create(f, label, color)
end

local Create = function(parent, gap)
	local storeAutoShotTimer = Quiver_Store.ModuleStore[AutoShotTimer.Id]
	local storeCastbar = Quiver_Store.ModuleStore[Castbar.Id]
	local storeRange = Quiver_Store.ModuleStore[RangeIndicator.Id]
	local f = CreateFrame("Frame", nil, parent)

	local colorShoot = Color:LiftReset(storeAutoShotTimer.ColorShoot, QUIVER.ColorDefault.AutoShotShoot)
	local colorReload = Color:LiftReset(storeAutoShotTimer.ColorReload, QUIVER.ColorDefault.AutoShotReload)
	local optionShoot = ColorSwatch:Create(f, Quiver.T["Shooting"], colorShoot)
	local optionReload = ColorSwatch:Create(f, Quiver.T["Reloading"], colorReload)

	local elements = {
		swatch(f, Quiver.T["Casting"], storeCastbar.ColorCastbar, QUIVER.ColorDefault.Castbar),
		createBtnColorSwap(f, optionShoot, optionReload, colorShoot, colorReload),
		optionShoot,
		optionReload,
		swatch(f, Quiver.T["Melee Range"], storeRange.ColorMelee, QUIVER.ColorDefault.Range.Melee),
		swatch(f, Quiver.T["Dead Zone"], storeRange.ColorDeadZone, QUIVER.ColorDefault.Range.DeadZone),
		swatch(f, Quiver.T["Scare Beast"], storeRange.ColorScareBeast, QUIVER.ColorDefault.Range.ScareBeast),
		swatch(f, Quiver.T["Scatter Shot"], storeRange.ColorScatterShot, QUIVER.ColorDefault.Range.ScatterShot),
		swatch(f, Quiver.T["Short Range"], storeRange.ColorShort, QUIVER.ColorDefault.Range.Short),
		swatch(f, Quiver.T["Long Range"], storeRange.ColorLong, QUIVER.ColorDefault.Range.Long),
		swatch(f, Quiver.T["Hunter's Mark"], storeRange.ColorMark, QUIVER.ColorDefault.Range.Mark),
		swatch(f, Quiver.T["Out of Range"], storeRange.ColorTooFar, QUIVER.ColorDefault.Range.TooFar),
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
