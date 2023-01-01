local TEXT_PADDING_H = 12

local createBtnColorSwap = function(parent, f1, f2, c1, c2)
	local f = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	f:SetHeight(QUIVER.Size.Button)
	f:SetText("Swap Shoot / Reload")

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

local findMax = function(xs)
	local max = 0
	for _k, v in xs do
		if v > max then max = v end
	end
	return max
end

Quiver_Config_Color = function(parent, gap)
	local storeAutoShotTimer = Quiver_Store.ModuleStore[Quiver_Module_AutoShotTimer.Id]
	local storeCastbar = Quiver_Store.ModuleStore[Quiver_Module_Castbar.Id]
	local f = CreateFrame("Frame", nil, parent)

	local colorCast = Quiver_Component_ColorPicker_WrapColor(
		storeCastbar, "ColorCastbar", QUIVER.Color.CastbarDefault)
	local colorShoot = Quiver_Component_ColorPicker_WrapColor(
		storeAutoShotTimer, "ColorShoot", QUIVER.Color.AutoAttackDefaultShoot)
	local colorReload = Quiver_Component_ColorPicker_WrapColor(
		storeAutoShotTimer, "ColorReload", QUIVER.Color.AutoAttackDefaultReload)

	local fc = Quiver_Component_ColorPicker_WithResetLabel(f, "Casting", colorCast)
	local fs1 = Quiver_Component_ColorPicker_WithResetLabel(f, "Shooting", colorShoot)
	local fs2 = Quiver_Component_ColorPicker_WithResetLabel(f, "Reloading", colorReload)
	local fsBtn = createBtnColorSwap(f, fs1, fs2, colorShoot, colorReload)

	-- Right align buttons using minimum amount of space
	local labelMaxWidth = findMax({
		fc.Label:GetWidth(),
		fs1.Label:GetWidth(),
		fs2.Label:GetWidth(),
	})
	local _, _, _, labelX, _y = fs1.Label:GetPoint()
	local width = labelX + labelMaxWidth + QUIVER.Size.Gap + fs1.Button:GetWidth()
	fc:SetWidth(width)
	fs1:SetWidth(width)
	fs2:SetWidth(width)

	fc:SetPoint("Left", f, "Left", 0, 0)
	fs1:SetPoint("Left", f, "Left", 0, 0)
	fs2:SetPoint("Left", f, "Left", 0, 0)
	fsBtn:SetPoint("Left", f, "Left", labelX, 0)

	local h1, h2, h3, h4 = fc:GetHeight(), fs1:GetHeight(), fs2:GetHeight(), fsBtn:GetHeight()
	local y2 = -1 * (h1 + gap)
	local y3 = y2 - h2 - gap
	local y4 = y3 - h3 - gap

	fc:SetPoint("Top", f, "Top", 0, 0)
	fs1:SetPoint("Top", f, "Top", 0, y2)
	fs2:SetPoint("Top", f, "Top", 0, y3)
	fsBtn:SetPoint("Top", f, "Top", 0, y4)

	f:SetWidth(parent:GetWidth())
	f:SetHeight(h1 + gap + h2 + gap + h3 + gap + h4)
	return f
end
