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
	local h = 0
	local maxW = 0
	for _k, mLoop in _G.Quiver_Modules do
		local m = mLoop
		local mFrame = createModuleControls(f, m, gap)
		mFrame:SetPoint("Left", f, "Left", 0, 0)
		mFrame:SetPoint("Top", f, "Top", 0, -h)
		h = h + mFrame:GetHeight() + gap
		local w = mFrame:GetWidth()
		maxW = maxW > w and maxW or w
	end
	f:SetHeight(h)
	f:SetWidth(maxW)
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
	colorPickers:SetPoint("Top", f, "Top", 0, yOffset)
	controls:SetPoint("Left", f, "Left", PADDING_FAR, 0)
	colorPickers:SetPoint("Right", f, "Right", -PADDING_FAR, 0)
	f:SetWidth(PADDING_FAR + controls:GetWidth() + PADDING_FAR + colorPickers:GetWidth() + PADDING_FAR)

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
