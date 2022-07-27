local setFrameLock = function(isChecked)
	Quiver_Store.IsLockedFrames = isChecked
	if Quiver_Store.IsLockedFrames then
		for _k, f in Quiver_UI_FrameMeta_InteractiveFrames do
			f:Hide()
		end
		for _k, v in _G.Quiver_Modules do
			if Quiver_Store.ModuleEnabled[v.Name] then v.OnInterfaceLock() end
		end
	else
		for _k, f in Quiver_UI_FrameMeta_InteractiveFrames do
			f:Show()
		end
		for _k, v in _G.Quiver_Modules do
			if Quiver_Store.ModuleEnabled[v.Name] then v.OnInterfaceUnlock() end
		end
	end
end

local createIconBtnLock = function(parent)
	local f = Quiver_Component_Button({
		Parent=parent, Size=QUIVER.Size.Icon, TooltipText="Lock/Unlock Frames" })
	local updateTexture = function()
		local path = Quiver_Store.IsLockedFrames
			and QUIVER.Icon.LockClosed
			or QUIVER.Icon.LockOpen
		f.Texture:QuiverSetTexture(1, path)
	end
	updateTexture()
	f:SetScript("OnClick", function(_self)
		setFrameLock(not Quiver_Store.IsLockedFrames)
		updateTexture()
	end)
	return f
end

local createSlider = function(parent, o)
	local padding, y, min, max, value =
		o.Padding, o.Y, o.Min, o.Max, o.Value
	local f = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
	local sliderWidth = f:GetWidth() - 2 * padding
	f:SetWidth(sliderWidth)
	f:SetHeight(15)
	f:SetPoint("Left", parent, "Left", padding, 0)
	f:SetPoint("Right", parent, "Right", -padding, 0)
	f:SetPoint("Top", parent, "Top", 0, y)

	f:SetMinMaxValues(min, max)
	f:SetValue(value)
	-- slider:SetValueStep(stepSize) Doesn't work
	--slider:SetObeyStepOnDrag(true)
	return f
end

Quiver_MainMenu_Create = function()
	local f = Quiver_UI_WithWindowTitle(
		Quiver_UI_Dialog(300, 350), "Quiver")
	f:Hide()

	local btnCloseTop = Quiver_Component_Button({
		Parent=f, Size=QUIVER.Size.Icon, TooltipText="Close Window" })
	btnCloseTop.Texture:QuiverSetTexture(0.7, QUIVER.Icon.XMark)
	btnCloseTop:SetPoint("TopRight", f, "TopRight", -QUIVER.Size.Border, -QUIVER.Size.Border)
	btnCloseTop:SetScript("OnClick", function() f:Hide() end)

	local btnToggleLock = createIconBtnLock(f)
	local lockOffset = QUIVER.Size.Border + QUIVER.Size.Icon + QUIVER.Size.Gap/2
	btnToggleLock:SetPoint("TopRight", f, "TopRight", -lockOffset, -QUIVER.Size.Border)

	_ = Quiver_Components_CheckButton({
		Parent = f, Y = -25,
		IsChecked = Quiver_Store.ModuleEnabled.AutoShotCastbar,
		Label = QUIVER_T.Module.AutoShotCastbar,
		OnClick = function (isChecked)
			Quiver_Store.ModuleEnabled.AutoShotCastbar = isChecked
			if isChecked
			then Quiver_Module_AutoShotCastbar.OnEnable()
			else Quiver_Module_AutoShotCastbar.OnDisable()
			end
		end,
	})

	_ = Quiver_Components_CheckButton({
		Parent = f, Y = -55,
		IsChecked = Quiver_Store.ModuleEnabled.RangeIndicator,
		Label = QUIVER_T.Module.RangeIndicator,
		Tooltip = "Shows when abilities are in range. Requires spellbook abilities placed somewhere on your action bars.",
		OnClick = function (isChecked)
			Quiver_Store.ModuleEnabled.RangeIndicator = isChecked
			if isChecked
			then Quiver_Module_RangeIndicator.OnEnable()
			else Quiver_Module_RangeIndicator.OnDisable()
			end
		end,
	})

	_ = Quiver_Components_CheckButton({
		Parent = f, Y = -85,
		IsChecked = Quiver_Store.ModuleEnabled.TranqAnnouncer,
		Label = QUIVER_T.Module.TranqAnnouncer,
		Tooltip = "Announces in /Raid chat when your tranquilizing shot hits or misses a target.",
		OnClick = function (isChecked)
			Quiver_Store.ModuleEnabled.TranqAnnouncer = isChecked
			if isChecked
			then Quiver_Module_TranqAnnouncer.OnEnable()
			else Quiver_Module_TranqAnnouncer.OnDisable()
			end
		end,
	})

	-- TODO rewrite
	local _, _ = Quiver_Module_TranqAnnouncer_CreateMenuOptions(f)

	local margin = QUIVER.Size.Gap + QUIVER.Size.Border

	local sliderLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	sliderLabel:SetWidth(f:GetWidth() - 2 * margin)
	sliderLabel:SetHeight(20)
	sliderLabel:SetPoint("Left", f, "Left", margin, 0)
	sliderLabel:SetPoint("Right", f, "Right", -margin, 0)
	sliderLabel:SetPoint("Top", f, "Top", 0, -185)
	sliderLabel:SetJustifyH("Center")
	sliderLabel:SetText("YOffset     ***     Width     ***     Height")

	local range = GetScreenHeight() * 0.9
	local meta = Quiver_Store.FrameMeta.AutoShotCastbar
	local yoffsetSlider = createSlider(f, {
		Padding=margin, Y=-205,
		Min=-range/2, Max=range/2,
		Value=meta.Y,
	})
	yoffsetSlider:SetScript("OnValueChanged", function()
		local stepSize = 2
		meta.Y = math.floor(this:GetValue() / stepSize) * stepSize
		Quiver_Module_AutoShotCastbar_MoveY()
	end)

	local widthSlider = createSlider(f, {
		Padding=margin, Y=-240,
		Min=80, Max=400,
		Value=meta.W,
	})
	widthSlider:SetScript("OnValueChanged", function()
		local stepSize = 1
		meta.W = math.floor(this:GetValue() / stepSize) * stepSize
		Quiver_Module_AutoShotCastbar_Resize()
	end)

	local heightSlider = createSlider(f, {
		Padding=margin, Y=-275,
		Min=10, Max=25,
		Value=meta.H,
	})
	heightSlider:SetScript("OnValueChanged", function()
		local stepSize = 1
		meta.H = math.floor(this:GetValue() / stepSize) * stepSize
		Quiver_Module_AutoShotCastbar_Resize()
	end)

	return f
end
