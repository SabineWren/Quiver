local TEXT_PADDING_H = 12

local createBtnColorSwap = function(parent, f1, f2, c1, c2)
	local f = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	f:SetHeight(QUIVER.Size.Button)
	f:SetText("Swap")

	-- Size button to fit text
	local fs = f:GetFontString()
	f:SetWidth(fs:GetWidth() + 2 * TEXT_PADDING_H)
	fs:SetPoint("Left", TEXT_PADDING_H, 0)
	fs:SetPoint("Right", -TEXT_PADDING_H, 0)

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

local findMaxWidth = function(frames)
	local max = 0
	for _k, f in frames do
		local w = f:GetWidth()
		if w > max then max = w end
	end
	return max
end

Quiver_Config_Color_Bars = function(parent, gap)
	local storeAutoShotTimer = Quiver_Store.ModuleStore[Quiver_Module_AutoShotTimer.Id]
	local storeCastbar = Quiver_Store.ModuleStore[Quiver_Module_Castbar.Id]
	local f = CreateFrame("Frame", nil, parent)

	local colorCast = Quiver_Component_ColorPicker_WrapColor(
		storeCastbar, "ColorCastbar", QUIVER.ColorDefault.Castbar)
	local colorShoot = Quiver_Component_ColorPicker_WrapColor(
		storeAutoShotTimer, "ColorShoot", QUIVER.ColorDefault.AutoShotShoot)
	local colorReload = Quiver_Component_ColorPicker_WrapColor(
		storeAutoShotTimer, "ColorReload", QUIVER.ColorDefault.AutoShotReload)

	local fc = Quiver_Component_ColorPicker_WithResetLabel(
		f, "Casting", colorCast)
	local fs1 = Quiver_Component_ColorPicker_WithResetLabel(
		f, "Shooting", colorShoot)
	local fs2 = Quiver_Component_ColorPicker_WithResetLabel(
		f, "Reloading", colorReload)

	local frames = { fc, fs1, fs2 }
	local labels = {}; for _,frame in frames do table.insert(labels, frame.Label) end

	-- Right align buttons using minimum amount of space
	local labelMaxWidth = findMaxWidth(labels)
	local w = fc.WidthMinusLabel + labelMaxWidth
	local h = fc:GetHeight()
	local y = 0
	for _,frame in frames do
		frame:SetWidth(w)
		frame:SetPoint("Left", f, "Left", 0, 0)
		frame:SetPoint("Top", f, "Top", 0, y)
		y = y - h - gap
	end

	local _, _, _, btnX, _ = fs1.Button:GetPoint()
	local button = createBtnColorSwap(f, fs1, fs2, colorShoot, colorReload)
	button:SetPoint("Right", f, "Right", btnX, 0)
	button:SetPoint("Top", f, "Top", 0, y)

	f:SetWidth(findMaxWidth(frames))
	f:SetHeight(3*h + 3*gap + button:GetHeight())
	return f
end

Quiver_Config_Color_Range = function(parent, gap)
	local store = Quiver_Store.ModuleStore[Quiver_Module_RangeIndicator.Id]
	local f = CreateFrame("Frame", nil, parent)

	local wrap = Quiver_Component_ColorPicker_WrapColor
	local f1 = Quiver_Component_ColorPicker_WithResetLabel(
		f, QUIVER_T.Range.Melee,
		wrap(store, "ColorMelee", QUIVER.ColorDefault.Range.Melee))
	local f2 = Quiver_Component_ColorPicker_WithResetLabel(
		f, QUIVER_T.Range.DeadZone,
		wrap(store, "ColorDeadZone", QUIVER.ColorDefault.Range.DeadZone))
	local f3 = Quiver_Component_ColorPicker_WithResetLabel(
		f, QUIVER_T.Range.ScareBeast,
		wrap(store, "ColorScareBeast", QUIVER.ColorDefault.Range.ScareBeast))
	local f4 = Quiver_Component_ColorPicker_WithResetLabel(
		f, QUIVER_T.Range.ScatterShot,
		wrap(store, "ColorScatterShot", QUIVER.ColorDefault.Range.ScatterShot))
	local f5 = Quiver_Component_ColorPicker_WithResetLabel(
		f, QUIVER_T.Range.Short,
		wrap(store, "ColorShort", QUIVER.ColorDefault.Range.Short))
	local f6 = Quiver_Component_ColorPicker_WithResetLabel(
		f, QUIVER_T.Range.Long,
		wrap(store, "ColorLong", QUIVER.ColorDefault.Range.Long))
	local f7 = Quiver_Component_ColorPicker_WithResetLabel(
		f, QUIVER_T.Range.Mark,
		wrap(store, "ColorMark", QUIVER.ColorDefault.Range.Mark))
	local f8 = Quiver_Component_ColorPicker_WithResetLabel(
		f, QUIVER_T.Range.TooFar,
		wrap(store, "ColorTooFar", QUIVER.ColorDefault.Range.TooFar))

	local frames = { f1, f2, f3, f4, f5, f6, f7, f8 }
	local labels = {}; for _,frame in frames do table.insert(labels, frame.Label) end

	-- Right align buttons using minimum amount of space
	local labelMaxWidth = findMaxWidth(labels)
	local w = f1.WidthMinusLabel + labelMaxWidth
	local h = f1:GetHeight()
	local y = 0
	for _,frame in frames do
		frame:SetWidth(w)
		frame:SetPoint("Left", f, "Left", 0, 0)
		frame:SetPoint("Top", f, "Top", 0, y)
		y = y - h - gap
	end

	f:SetWidth(findMaxWidth(frames))
	f:SetHeight(8*h + 7*gap)
	return f
end
