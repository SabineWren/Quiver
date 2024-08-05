local Button = require "Components/Button.lua"
local ColorPicker = require "Components/ColorPicker.lua"
local AutoShotTimer = require "Modules/AutoShotTimer.lua"
local Castbar = require "Modules/Castbar.lua"
local RangeIndicator = require "Modules/RangeIndicator.lua"

--- Manually converting methods to functions
--- _Method = fun r -> r.Method()
local region = {
	--- @type fun(x: Region): number
	_GetWidth = function(f) return f:GetWidth() end
}

local createBtnColorSwap = function(parent, f1, f2, c1, c2)
	local f = Button.Create({
		Parent=parent, Size=QUIVER.Size.Icon,
		TooltipText=QUIVER_T.UI.SwapColorsLong,
	})
	f.Texture:QuiverSetTexture(0.75, QUIVER.Icon.ArrowsSwap)

	f.Label = f:CreateFontString(nil, "Background", "GameFontNormal")
	f.Label:SetPoint("Left", f, "Left", f:GetWidth() + 4, 0)
	f.Label:SetText(QUIVER_T.UI.SwapColorsShort)

	f:SetScript("OnClick", function()
		-- Swap colors
		local r, g, b = c1.Get()
		c1.Set(c2.R(), c2.G(), c2.B())
		c2.Set(r, g, b)
		-- Update preview button
		f1.Button:SetBackdropColor(c1.R(), c1.G(), c1.B(), 1)
		f2.Button:SetBackdropColor(c2.R(), c2.G(), c2.B(), 1)
	end)
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

	local frames = {
		ColorPicker.CreateWithResetLabel(f, "Casting",
			wrap(storeCastbar, "ColorCastbar", QUIVER.ColorDefault.Castbar)),
		optionShoot,
		optionReload,
		createBtnColorSwap(f, optionShoot, optionReload, colorShoot, colorReload),
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
	local labels = {}; for _,frame in frames do table.insert(labels, frame.Label) end

	-- Right align buttons using minimum amount of space
	local labelWidths = Quiver_Lib_F.Map(labels, region._GetWidth)
	local labelMaxWidth = Quiver_Lib_F.Max0(labelWidths)

	local y = 0
	for _,frame in frames do
		if frame.WidthMinusLabel ~= nil then
			frame:SetWidth(frame.WidthMinusLabel + labelMaxWidth)
		end
		frame:SetPoint("Left", f, "Left", 0, 0)
		frame:SetPoint("Top", f, "Top", 0, -y)
		y = y + frame:GetHeight() + gap
	end

	local frameWidths = Quiver_Lib_F.Map(frames, region._GetWidth)
	f:SetWidth(Quiver_Lib_F.Max0(frameWidths))
	f:SetHeight(y)
	return f
end

return {
	Create = Create,
}
