local createIconBtnLock = function(parent)
	local f = Quiver_Component_Button({
		Parent=parent, Size=QUIVER.Size.Icon, TooltipText=QUIVER_T.UI.FrameLockToggleTooltip })
	local updateTexture = function()
		local path = Quiver_Store.IsLockedFrames
			and QUIVER.Icon.LockClosed
			or QUIVER.Icon.LockOpen
		f.Texture:QuiverSetTexture(1, path)
	end
	updateTexture()
	f:SetScript("OnClick", function(_self)
		Quiver_Event_FrameLock_Set(not Quiver_Store.IsLockedFrames)
		updateTexture()
	end)
	Quiver_Event_FrameLock_Init()
	return f
end

local createIconResetAll = function(parent)
	local f = Quiver_Component_Button({
		Parent=parent, Size=QUIVER.Size.Icon,
		TooltipText=QUIVER_T.UI.ResetFramesTooltipAll,
	})
	f.Texture:QuiverSetTexture(0.75, QUIVER.Icon.Reset)
	f:SetScript("OnClick", function(_self)
		for _k, v in _G.Quiver_Modules do v.OnResetFrames() end
	end)
	return f
end

local createModuleControls = function(parent, m, gap)
	local f = CreateFrame("Frame", nil, parent)

	local sizeReset = QUIVER.Size.Icon
	f.BtnReset = Quiver_Component_Button({
		Parent=f, Size=sizeReset,
		TooltipText=QUIVER_T.UI.ResetFramesTooltip,
	})
	f.BtnReset.Texture:QuiverSetTexture(0.75, QUIVER.Icon.Reset)
	f.BtnReset:SetScript("OnClick", function(_self) m.OnResetFrames() end)
	f.BtnReset:SetPoint("Left", f, "Left", 0, 0)
	f.BtnReset:SetPoint("Top", f, "Top", 0, 0)

	if not Quiver_Store.ModuleEnabled[m.Id] then
		f.BtnReset.QuiverDisable()
	end

	f.BtnSwitch = Quiver_Component_CheckButton(f, {
		IsChecked = Quiver_Store.ModuleEnabled[m.Id],
		Label = m.Name,
		Tooltip = QUIVER_T.ModuleTooltip[m.Id],
		OnClick = function (isChecked)
			Quiver_Store.ModuleEnabled[m.Id] = isChecked
			if isChecked then
				m.OnEnable()
				f.BtnReset.QuiverEnable()
			else
				m.OnDisable()
				f.BtnReset.QuiverDisable()
			end
		end,
	})
	f.BtnSwitch:SetPoint("Top", f, "Top", 0, 0)
	f.BtnSwitch:SetPoint("Right", f, "Right", 0, 0)

	f:SetHeight(f.BtnSwitch:GetHeight())
	f:SetWidth(f.BtnReset:GetWidth() + gap + f.BtnSwitch:GetWidth())
	return f
end

local createAllModuleControls = function(parent, gap)
	local f = CreateFrame("Frame", nil, parent)
	local frames = Quiver_Lib_F.Map(_G.Quiver_Modules, function(m, i)
		local frame = createModuleControls(f, m, gap)
		local yOffset = i * (frame:GetHeight() + gap)
		frame:SetPoint("Left", f, "Left", 0, 0)
		frame:SetPoint("Top", f, "Top", 0, -yOffset)
		return frame
	end)
	local widths = Quiver_Lib_F.Map(frames, function(x) return x:GetWidth() end)
	local heights = Quiver_Lib_F.Map(frames, function(x) return x:GetHeight() + gap end)
	f:SetHeight(Quiver_Lib_F.Sum(heights) - gap)
	f:SetWidth(Quiver_Lib_F.Max(widths))
	return f
end

Quiver_Config_MainMenu_Create = function()
	-- WoW uses border-box content sizing
	local PADDING_CLOSE = QUIVER.Size.Border + 4
	local PADDING_FAR = QUIVER.Size.Border + QUIVER.Size.Gap
	local f = Quiver_Component_Dialog(PADDING_CLOSE)
	f:SetFrameStrata("Dialog")

	local titleBox = Quiver_Component_TitleBox(f)
	titleBox:SetPoint("Center", f, "Top", 0, -10)

	local btnCloseTop = Quiver_Component_Button({
		Parent=f, Size=QUIVER.Size.Icon,
		TooltipText=QUIVER_T.UI.CloseWindowTooltip })
	btnCloseTop.Texture:QuiverSetTexture(0.7, QUIVER.Icon.XMark)
	btnCloseTop:SetPoint("TopRight", f, "TopRight", -PADDING_CLOSE, -PADDING_CLOSE)
	btnCloseTop:SetScript("OnClick", function() f:Hide() end)

	local btnToggleLock = createIconBtnLock(f)
	local lockOffsetX = PADDING_CLOSE + QUIVER.Size.Icon + QUIVER.Size.Gap/2
	btnToggleLock:SetPoint("TopRight", f, "TopRight", -lockOffsetX, -PADDING_CLOSE)

	local btnResetFrames = createIconResetAll(f)
	local resetOffsetX = lockOffsetX + QUIVER.Size.Icon + QUIVER.Size.Gap/2
	btnResetFrames:SetPoint("TopRight", f, "TopRight", -resetOffsetX, -PADDING_CLOSE)

	local controls = createAllModuleControls(f, QUIVER.Size.Gap)
	local colorPickers = Quiver_Config_Colors(f, QUIVER.Size.Gap)

	local yOffset = -PADDING_CLOSE - QUIVER.Size.Icon - QUIVER.Size.Gap
	controls:SetPoint("Top", f, "Top", 0, yOffset)
	controls:SetPoint("Left", f, "Left", PADDING_FAR, 0)
	colorPickers:SetPoint("Top", f, "Top", 0, yOffset)
	colorPickers:SetPoint("Right", f, "Right", -PADDING_FAR, 0)
	f:SetWidth(PADDING_FAR + controls:GetWidth() + PADDING_FAR + colorPickers:GetWidth() + PADDING_FAR)

	local dropdownX = PADDING_FAR + colorPickers:GetWidth() + PADDING_FAR
	local dropdownY = 0

	-- Dropdown debug level. Maybe hide this from users? Could use slash commands instead.
	local selectDebugLevel = Quiver_Component_DropdownSelect(f,
		"Debug Level",
		{ "None", "Verbose" },
		Quiver_Store.DebugLevel
	)
	dropdownY = yOffset - colorPickers:GetHeight() + selectDebugLevel:GetHeight() + QUIVER.Size.Gap
	selectDebugLevel:SetPoint("Right", f, "Right", -dropdownX, 0)
	selectDebugLevel:SetPoint("Top", f, "Top", 0, dropdownY)
	-- Dropdown options
	for _k,oLoop in selectDebugLevel.Menu.Options do
		local option = oLoop
		option:SetScript("OnClick", function()
			local text = option.Text:GetText()
			Quiver_Store.DebugLevel = text
			selectDebugLevel.Selected:SetText(text)
			selectDebugLevel.Menu:Hide()
		end)
	end

	-- Dropdown auto shot bar direction
	local directionToText = function()

	end
	local selectAutoShotTimerDirection = Quiver_Component_DropdownSelect(f,
		QUIVER_T.ModuleName.AutoShotTimer,
		{ QUIVER_T.AutoShot.LeftToRight, QUIVER_T.AutoShot.BothDirections },
		QUIVER_T.AutoShot[Quiver_Store.ModuleStore[Quiver_Module_AutoShotTimer.Id].BarDirection]
	)
	dropdownY = dropdownY + QUIVER.Size.Gap + selectAutoShotTimerDirection:GetHeight()
	selectAutoShotTimerDirection:SetPoint("Right", f, "Right", -dropdownX, 0)
	selectAutoShotTimerDirection:SetPoint("Top", f, "Top", 0, dropdownY)
	-- Dropdown options
	for _k,oLoop in selectAutoShotTimerDirection.Menu.Options do
		local option = oLoop
		option:SetScript("OnClick", function()
			local text = option.Text:GetText()
			selectAutoShotTimerDirection.Selected:SetText(text)
			selectAutoShotTimerDirection.Menu:Hide()
			local direction = text == QUIVER_T.AutoShot.LeftToRight and "LeftToRight" or "BothDirections"
			Quiver_Store.ModuleStore[Quiver_Module_AutoShotTimer.Id].BarDirection = direction
			DEFAULT_CHAT_FRAME:AddMessage("Set to "..direction)
			Quiver_Module_AutoShotTimer.UpdateDirection()
		end)
	end

	-- Dropdown tranq shot announce channel
	local selectChannelHit = Quiver_Component_DropdownSelect(f,
		"Tranq Speech",
		{ "None", "/Say", "/Raid" },
		Quiver_Store.ModuleStore[Quiver_Module_TranqAnnouncer.Id].TranqChannel
	)
	dropdownY = dropdownY + QUIVER.Size.Gap + selectChannelHit:GetHeight()
	selectChannelHit:SetPoint("Right", f, "Right", -dropdownX, 0)
	selectChannelHit:SetPoint("Top", f, "Top", 0, dropdownY)
	-- Dropdown options
	for _k,oLoop in selectChannelHit.Menu.Options do
		local option = oLoop
		option:SetScript("OnClick", function()
			local text = option.Text:GetText()
			Quiver_Store.ModuleStore[Quiver_Module_TranqAnnouncer.Id].TranqChannel = text
			selectChannelHit.Selected:SetText(text)
			selectChannelHit.Menu:Hide()
		end)
	end

	local hLeft = controls:GetHeight()
	local hRight = colorPickers:GetHeight()
	local hMax = hRight > hLeft and hRight or hLeft
	yOffset = yOffset - hMax - QUIVER.Size.Gap

	local tranqOptions = Quiver_Config_InputText_TranqAnnouncer(f, QUIVER.Size.Gap)
	tranqOptions:SetPoint("TopLeft", f, "TopLeft", 0, yOffset)
	yOffset = yOffset - tranqOptions:GetHeight()
	yOffset = yOffset - QUIVER.Size.Gap

	f:SetHeight(-1 * yOffset + PADDING_CLOSE + QUIVER.Size.Button)
	return f
end
