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

local createIconResetCastbars = function(parent)
	local f = Quiver_Component_Button({
		Parent=parent, Size=QUIVER.Size.Icon,
		TooltipText=QUIVER_T.UI.ResetCastbarsTooltip,
	})
	f.Texture:QuiverSetTexture(0.75, QUIVER.Icon.Reset)
	f:SetScript("OnClick", function(_self)
		for _k, v in _G.Quiver_Modules do
			if v.ResetUI ~= nil then v.ResetUI() end
		end
	end)
	return f
end

local createCheckboxesModuleEnabled = function(f, yOffset, gap)
	local height = 0
	for _k, mLoop in _G.Quiver_Modules do
		local m = mLoop
		local checkbutton = Quiver_Component_CheckButton({
			Parent = f,
			Y = yOffset - height,
			IsChecked = Quiver_Store.ModuleEnabled[m.Id],
			Label = m.Name,
			Tooltip = QUIVER_T.ModuleTooltip[m.Id],
			OnClick = function (isChecked)
				Quiver_Store.ModuleEnabled[m.Id] = isChecked
				if isChecked then m.OnEnable() else m.OnDisable() end
			end,
		})
		height = height + checkbutton:GetHeight() + gap
	end
	return height - gap
end

Quiver_ConfigMenu_Create = function()
	-- WoW uses border-box content sizing
	local PADDING = QUIVER.Size.Border + 4
	local f = Quiver_Component_Dialog(300, PADDING)

	local titleBox = Quiver_Component_TitleBox(f)
	titleBox:SetPoint("Center", f, "Top", 0, -10)

	local btnCloseTop = Quiver_Component_Button({
		Parent=f, Size=QUIVER.Size.Icon,
		TooltipText=QUIVER_T.UI.CloseWindowTooltip })
	btnCloseTop.Texture:QuiverSetTexture(0.7, QUIVER.Icon.XMark)
	btnCloseTop:SetPoint("TopRight", f, "TopRight", -PADDING, -PADDING)
	btnCloseTop:SetScript("OnClick", function() f:Hide() end)

	local btnToggleLock = createIconBtnLock(f)
	local lockOffsetX = PADDING + QUIVER.Size.Icon + QUIVER.Size.Gap/2
	btnToggleLock:SetPoint("TopRight", f, "TopRight", -lockOffsetX, -PADDING)

	local btnResetFrames = createIconResetCastbars(f)
	local resetOffsetX = lockOffsetX + QUIVER.Size.Icon + QUIVER.Size.Gap/2
	btnResetFrames:SetPoint("TopRight", f, "TopRight", -resetOffsetX, -PADDING)

	local yOffset = -(PADDING + QUIVER.Size.Icon)
	yOffset = yOffset - createCheckboxesModuleEnabled(f, yOffset, QUIVER.Size.Gap)
	yOffset = yOffset - QUIVER.Size.Gap

	local tranqOptions = Quiver_Module_TranqAnnouncer_CreateMenuOptions(f, QUIVER.Size.Gap)
	tranqOptions:SetPoint("Top", f, "Top", 0, yOffset)
	yOffset = yOffset - tranqOptions:GetHeight()
	yOffset = yOffset - QUIVER.Size.Gap

	local toggleColors = Quiver_Module_AutoShotTimer_MakeOptionsColor(f)
	toggleColors:SetPoint("TopLeft", f, "TopLeft", PADDING, yOffset)
	yOffset = yOffset - toggleColors:GetHeight()

	f:SetHeight(-1 * yOffset + PADDING + QUIVER.Size.Button)
	return f
end
