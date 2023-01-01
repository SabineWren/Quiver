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
		for _k, v in _G.Quiver_Modules do
			if v.OnResetFrames ~= nil then v.OnResetFrames() end
		end
	end)
	return f
end

local createModuleControlButtons = function(f, yOffset, gap)
	local height = 0
	for _k, mLoop in _G.Quiver_Modules do
		local m = mLoop

		local x = QUIVER.Size.Border + QUIVER.Size.Gap
		local sizeReset = QUIVER.Size.Icon
		local btnReset = nil
		if m.OnResetFrames then
			btnReset = Quiver_Component_Button({
				Parent=f, Size=sizeReset,
				TooltipText=QUIVER_T.UI.ResetFramesTooltip,
			})
			btnReset.Texture:QuiverSetTexture(0.75, QUIVER.Icon.Reset)

			btnReset:SetScript("OnClick", function(_self)
				m.OnResetFrames()
			end)
			btnReset:SetPoint("Left", f, "Left", x, 0)
			btnReset:SetPoint("Top", f, "Top", 0, yOffset - height)

			if not Quiver_Store.ModuleEnabled[m.Id] then
				btnReset.QuiverDisable()
			end
		end

		x = x + sizeReset + QUIVER.Size.Gap
		local btnSwitch = Quiver_Component_CheckButton({
			Parent = f,
			X = x,
			Y = yOffset - height,
			IsChecked = Quiver_Store.ModuleEnabled[m.Id],
			Label = m.Name,
			Tooltip = QUIVER_T.ModuleTooltip[m.Id],
			OnClick = function (isChecked)
				Quiver_Store.ModuleEnabled[m.Id] = isChecked
				if isChecked then
					m.OnEnable()
					if btnReset then btnReset.QuiverEnable() end
				else
					m.OnDisable()
					if btnReset then btnReset.QuiverDisable() end
				end
			end,
		})
		height = height + btnSwitch:GetHeight() + gap
	end
	return height - gap
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

	local yOffset = -(PADDING_CLOSE + QUIVER.Size.Icon)
	yOffset = yOffset - createModuleControlButtons(f, yOffset, QUIVER.Size.Gap)
	yOffset = yOffset - QUIVER.Size.Gap

	-- *** Split Start ***
	local x = PADDING_FAR
	local colorPickersLeft = Quiver_Config_Color_Bars(f, QUIVER.Size.Gap)
	colorPickersLeft:SetPoint("TopLeft", f, "TopLeft", x, yOffset)
	x = x + colorPickersLeft:GetWidth() + 12
	local colorPickersRight = Quiver_Config_Color_Range(f, QUIVER.Size.Gap)
	colorPickersRight:SetPoint("TopLeft", f, "TopLeft", x, yOffset)
	local y1 = colorPickersLeft:GetHeight()
	local y2 = colorPickersRight:GetHeight()
	local yMax = y1 > y2 and y1 or y2
	yOffset = yOffset - yMax - QUIVER.Size.Gap
	-- *** Split End ***

	f:SetWidth(x + colorPickersRight:GetWidth() + PADDING_FAR)

	local tranqOptions = Quiver_Config_InputText_TranqAnnouncer(f, QUIVER.Size.Gap)
	tranqOptions:SetPoint("TopLeft", f, "TopLeft", 0, yOffset)
	yOffset = yOffset - tranqOptions:GetHeight()
	yOffset = yOffset - QUIVER.Size.Gap

	f:SetHeight(-1 * yOffset + PADDING_CLOSE + QUIVER.Size.Button)
	return f
end
