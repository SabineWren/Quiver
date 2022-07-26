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
		local LOCK_OPEN = "Interface\\AddOns\\Quiver\\Textures\\lock-open"
		local LOCK_CLOSED = "Interface\\AddOns\\Quiver\\Textures\\lock"
		local path = Quiver_Store.IsLockedFrames and LOCK_CLOSED or LOCK_OPEN
		f.Texture:QuiverSetTexture(1, path)
	end
	updateTexture()
	f:SetScript("OnClick", function(_self)
		setFrameLock(not Quiver_Store.IsLockedFrames)
		updateTexture()
	end)
	return f
end

Quiver_MainMenu_Create = function()
	local f = Quiver_UI_WithWindowTitle(
		Quiver_UI_Dialog(300, 250), "Quiver")
	f:Hide()

	local btnCloseTop = Quiver_Component_Button({
		Parent=f, Size=QUIVER.Size.Icon, TooltipText="Close Window" })
	btnCloseTop.Texture:QuiverSetTexture(0.7, "Interface\\AddOns\\Quiver\\Textures\\xmark")
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

	--test:SetPoint("BottomLeft", f, "BottomLeft", 30, 30)
	return f
end
