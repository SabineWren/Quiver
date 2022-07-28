local setFrameLock = function(isChecked)
	Quiver_Store.IsLockedFrames = isChecked
	if Quiver_Store.IsLockedFrames then
		for _k, f in Quiver_UI_FrameMeta_InteractiveFrames do f:Hide() end
		for _k, v in _G.Quiver_Modules do
			if Quiver_Store.ModuleEnabled[v.Id] then v.OnInterfaceLock() end
		end
	else
		for _k, f in Quiver_UI_FrameMeta_InteractiveFrames do f:Show() end
		for _k, v in _G.Quiver_Modules do
			if Quiver_Store.ModuleEnabled[v.Id] then v.OnInterfaceUnlock() end
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

local createCheckboxesModuleEnabled = function(f, yOffset, gap)
	local height = 0
	for _k, vLoop in _G.Quiver_Modules do
		local v = vLoop
		local isEnabled = Quiver_Store.ModuleEnabled[v.Id]
		local label = QUIVER_T.ModuleName[v.Id]
		local tooltip = QUIVER_T.ModuleTooltip[v.Id]
		local checkbutton = Quiver_Components_CheckButton({
			Parent = f,
			Y = yOffset - height,
			IsChecked = isEnabled, Label = label, Tooltip = tooltip,
			OnClick = function (isChecked)
				Quiver_Store.ModuleEnabled[v.Id] = isChecked
				if isChecked then v.OnEnable() else v.OnDisable() end
			end,
		})
		height = height + checkbutton:GetHeight() + gap
	end
	return height - gap
end

Quiver_MainMenu_Create = function()
	local f = Quiver_Components_Dialog(300, QUIVER.Size.Border)

	local titleBox = Quiver_Components_TitleBox(f, "Quiver")
	titleBox:SetPoint("Center", f, "Top", 0, -10)

	local btnCloseTop = Quiver_Component_Button({
		Parent=f, Size=QUIVER.Size.Icon, TooltipText="Close Window" })
	btnCloseTop.Texture:QuiverSetTexture(0.7, QUIVER.Icon.XMark)
	btnCloseTop:SetPoint("TopRight", f, "TopRight", -QUIVER.Size.Border, -QUIVER.Size.Border)
	btnCloseTop:SetScript("OnClick", function() f:Hide() end)

	local btnToggleLock = createIconBtnLock(f)
	local lockOffset = QUIVER.Size.Border + QUIVER.Size.Icon + QUIVER.Size.Gap/2
	btnToggleLock:SetPoint("TopRight", f, "TopRight", -lockOffset, -QUIVER.Size.Border)

	local yOffset = -25
	yOffset = yOffset - createCheckboxesModuleEnabled(f, yOffset, QUIVER.Size.Gap)
	yOffset = yOffset - QUIVER.Size.Gap

	local tranqOptions = Quiver_Module_TranqAnnouncer_CreateMenuOptions(f, QUIVER.Size.Gap)
	tranqOptions:SetPoint("Top", f, "Top", 0, yOffset)
	yOffset = yOffset - tranqOptions:GetHeight()
	yOffset = yOffset - QUIVER.Size.Gap

	local margin = QUIVER.Size.Gap + QUIVER.Size.Border
	local sliderLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	sliderLabel:SetWidth(f:GetWidth() - 2 * margin)
	sliderLabel:SetHeight(18)
	sliderLabel:SetPoint("Left", f, "Left", margin, 0)
	sliderLabel:SetPoint("Right", f, "Right", -margin, 0)
	sliderLabel:SetPoint("Top", f, "Top", 0, yOffset)
	sliderLabel:SetJustifyH("Center")
	sliderLabel:SetText("YOffset     ***     Width     ***     Height")
	yOffset = yOffset - sliderLabel:GetHeight()
	yOffset = yOffset - QUIVER.Size.Gap

	local range = GetScreenHeight() * 0.9
	local gapSlider = 18
	local meta = Quiver_Store.FrameMeta.AutoShotCastbar
	local yoffsetSlider = createSlider(f, {
		Padding=margin, Y=yOffset,
		Min=-range/2, Max=range/2,
		Value=meta.Y,
	})
	yoffsetSlider:SetScript("OnValueChanged", function()
		local stepSize = 2
		meta.Y = math.floor(this:GetValue() / stepSize) * stepSize
		Quiver_Module_AutoShotCastbar_UpdateFamePosition()
	end)
	yOffset = yOffset - yoffsetSlider:GetHeight()
	yOffset = yOffset - gapSlider

	local widthSlider = createSlider(f, {
		Padding=margin, Y=yOffset,
		Min=80, Max=400,
		Value=meta.W,
	})
	widthSlider:SetScript("OnValueChanged", function()
		local stepSize = 1
		meta.W = math.floor(this:GetValue() / stepSize) * stepSize
		Quiver_Module_AutoShotCastbar_Resize()
	end)
	yOffset = yOffset - widthSlider:GetHeight()
	yOffset = yOffset - gapSlider

	local heightSlider = createSlider(f, {
		Padding=margin, Y=yOffset,
		Min=12, Max=25,
		Value=meta.H,
	})
	heightSlider:SetScript("OnValueChanged", function()
		local stepSize = 1
		meta.H = math.floor(this:GetValue() / stepSize) * stepSize
		Quiver_Module_AutoShotCastbar_Resize()
	end)
	yOffset = yOffset - heightSlider:GetHeight()
	yOffset = yOffset - gapSlider

	f:SetHeight(-1 * yOffset + QUIVER.Size.Border + QUIVER.Size.Button)
	return f
end
