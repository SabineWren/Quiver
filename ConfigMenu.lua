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
		Quiver_Event_FrameLock_Set(not Quiver_Store.IsLockedFrames)
		updateTexture()
	end)
	return f
end

local createCheckboxesModuleEnabled = function(f, yOffset, gap)
	local height = 0
	for _k, vLoop in _G.Quiver_Modules do
		local v = vLoop
		local isEnabled = Quiver_Store.ModuleEnabled[v.Id]
		local label = QUIVER_T.ModuleName[v.Id]
		local tooltip = QUIVER_T.ModuleTooltip[v.Id]
		local checkbutton = Quiver_Component_CheckButton({
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

Quiver_ConfigMenu_Create = function()
	local f = Quiver_Component_Dialog(300, QUIVER.Size.Border)

	local titleBox = Quiver_Component_TitleBox(f, "Quiver")
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

	f:SetHeight(-1 * yOffset + QUIVER.Size.Border + QUIVER.Size.Button)
	return f
end
