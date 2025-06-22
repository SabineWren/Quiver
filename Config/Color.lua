local Button = require "Component/Button.lua"
local ColorSwatch = require "Component/ColorSwatch.lua"
local Const = require "Constants.lua"
local L = require "Lib/Index.lua"
local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local Castbar = require "Modules/Castbar.lua"
local RangeIndicator = require "Modules/RangeIndicator.lua"

---@param c1 Color
---@param c2 Color
local createBtnColorSwap = function(parent, f1, f2, c1, c2)
	local f = Button:Create(parent, Const.Icon.ArrowsSwap, Quiver.T["Shoot / Reload"])
	f.TooltipText = Quiver.T["Swap Shoot and Reload Colors"]
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
	local color = L.Color:LiftReset(store, default)
	return ColorSwatch:Create(f, label, color)
end

local Create = function(parent, gap)
	local storeAutoShotTimer = Quiver_Store.ModuleStore[AutoShotTimer.Id]
	local storeCastbar = Quiver_Store.ModuleStore[Castbar.Id]
	local storeRange = Quiver_Store.ModuleStore[RangeIndicator.Id]
	local f = CreateFrame("Frame", nil, parent)

	local colorShoot = L.Color:LiftReset(storeAutoShotTimer.ColorShoot, Const.ColorDefault.AutoShotShoot)
	local colorReload = L.Color:LiftReset(storeAutoShotTimer.ColorReload, Const.ColorDefault.AutoShotReload)
	local optionShoot = ColorSwatch:Create(f, Quiver.T["Shooting"], colorShoot)
	local optionReload = ColorSwatch:Create(f, Quiver.T["Reloading"], colorReload)

	local elements = {
		swatch(f, Quiver.T["Casting"], storeCastbar.ColorCastbar, Const.ColorDefault.Castbar),
		createBtnColorSwap(f, optionShoot, optionReload, colorShoot, colorReload),
		optionShoot,
		optionReload,
		swatch(f, Quiver.T["Melee Range"], storeRange.ColorMelee, Const.ColorDefault.Range.Melee),
		swatch(f, Quiver.T["Dead Zone"], storeRange.ColorDeadZone, Const.ColorDefault.Range.DeadZone),
		swatch(f, Quiver.T["Scare Beast"], storeRange.ColorScareBeast, Const.ColorDefault.Range.ScareBeast),
		swatch(f, Quiver.T["Scatter Shot"], storeRange.ColorScatterShot, Const.ColorDefault.Range.ScatterShot),
		swatch(f, Quiver.T["Short Range"], storeRange.ColorShort, Const.ColorDefault.Range.Short),
		swatch(f, Quiver.T["Long Range"], storeRange.ColorLong, Const.ColorDefault.Range.Long),
		swatch(f, Quiver.T["Hunter's Mark"], storeRange.ColorMark, Const.ColorDefault.Range.Mark),
		swatch(f, Quiver.T["Out of Range"], storeRange.ColorTooFar, Const.ColorDefault.Range.TooFar),
	}
	-- Right align buttons using minimum amount of space
	local getLabelWidth = function(x) return x.Label and x.Label:GetWidth() or 0 end
	local labelMaxWidth = L.Array.MapSeduce(elements, getLabelWidth, L.Sg.Max, 0)

	local y = 0
	for _i, v in ipairs(elements) do
		if v.WidthMinusLabel ~= nil then
			v.Container:SetWidth(v.WidthMinusLabel + labelMaxWidth)
		end
		v.Container:SetPoint("Left", f, "Left", 0, 0)
		v.Container:SetPoint("Top", f, "Top", 0, -y)
		y = y + v.Container:GetHeight() + gap
	end

	f:SetWidth(L.Array.MapSeduce(elements, function(x) return x.Container:GetWidth() end, L.Sg.Max, 0))
	f:SetHeight(y)
	return f
end

return {
	Create = Create,
}
