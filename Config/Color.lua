local createBtnColorSwap = function(parent, f1, f2, c1, c2)
	local f = Quiver_Component_Button({
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

Quiver_Config_Colors = function(parent, gap)
	local storeAutoShotTimer = Quiver_Store.ModuleStore[Quiver_Module_AutoShotTimer.Id]
	local storeCastbar = Quiver_Store.ModuleStore[Quiver_Module_Castbar.Id]
	local storeRange = Quiver_Store.ModuleStore[Quiver_Module_RangeIndicator.Id]
	local f = CreateFrame("Frame", nil, parent)

	local wrap = Quiver_Component_ColorPicker_WrapColor
	local colorShoot = wrap(storeAutoShotTimer, "ColorShoot", QUIVER.ColorDefault.AutoShotShoot)
	local colorReload = wrap(storeAutoShotTimer, "ColorReload", QUIVER.ColorDefault.AutoShotReload)
	local optionShoot = Quiver_Component_ColorPicker_WithResetLabel(f, "Shooting", colorShoot)
	local optionReload = Quiver_Component_ColorPicker_WithResetLabel(f, "Reloading", colorReload)

	local frames = {
		Quiver_Component_ColorPicker_WithResetLabel(f, "Casting",
			wrap(storeCastbar, "ColorCastbar", QUIVER.ColorDefault.Castbar)),
		optionShoot,
		optionReload,
		createBtnColorSwap(f, optionShoot, optionReload, colorShoot, colorReload),
		Quiver_Component_ColorPicker_WithResetLabel(f, QUIVER_T.Range.Melee,
			wrap(storeRange, "ColorMelee", QUIVER.ColorDefault.Range.Melee)),
		Quiver_Component_ColorPicker_WithResetLabel(f, QUIVER_T.Range.DeadZone,
			wrap(storeRange, "ColorDeadZone", QUIVER.ColorDefault.Range.DeadZone)),
		Quiver_Component_ColorPicker_WithResetLabel(f, QUIVER_T.Range.ScareBeast,
			wrap(storeRange, "ColorScareBeast", QUIVER.ColorDefault.Range.ScareBeast)),
		Quiver_Component_ColorPicker_WithResetLabel(f, QUIVER_T.Range.ScatterShot,
			wrap(storeRange, "ColorScatterShot", QUIVER.ColorDefault.Range.ScatterShot)),
		Quiver_Component_ColorPicker_WithResetLabel(f, QUIVER_T.Range.Short,
			wrap(storeRange, "ColorShort", QUIVER.ColorDefault.Range.Short)),
		Quiver_Component_ColorPicker_WithResetLabel(f, QUIVER_T.Range.Long,
			wrap(storeRange, "ColorLong", QUIVER.ColorDefault.Range.Long)),
		Quiver_Component_ColorPicker_WithResetLabel(f, QUIVER_T.Range.Mark,
			wrap(storeRange, "ColorMark", QUIVER.ColorDefault.Range.Mark)),
		Quiver_Component_ColorPicker_WithResetLabel(f, QUIVER_T.Range.TooFar,
			wrap(storeRange, "ColorTooFar", QUIVER.ColorDefault.Range.TooFar)),
	}
	local labels = {}; for _,frame in frames do table.insert(labels, frame.Label) end

	-- Right align buttons using minimum amount of space
	local getWidth = function(f) return f:GetWidth() end
	local labelWidths = Quiver_Lib_F.Map(labels, getWidth)
	local labelMaxWidth = Quiver_Lib_F.Max(labelWidths)

	local y = 0
	for _,frame in frames do
		if frame.WidthMinusLabel ~= nil then
			frame:SetWidth(frame.WidthMinusLabel + labelMaxWidth)
		end
		frame:SetPoint("Left", f, "Left", 0, 0)
		frame:SetPoint("Top", f, "Top", 0, -y)
		y = y + frame:GetHeight() + gap
	end

	local frameWidths = Quiver_Lib_F.Map(frames, getWidth)
	f:SetWidth(Quiver_Lib_F.Max(frameWidths))
	f:SetHeight(y)
	return f
end
