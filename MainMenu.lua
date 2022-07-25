function Quiver_MainMenu_Create()
	local f = Quiver_UI_WithWindowTitle(
		Quiver_UI_Dialog(300, 250), "Quiver")
	f:Hide()

	local btnCloseTop = Quiver_UI_Button_Close(f)
	btnCloseTop:SetPoint("TopRight", f, "TopRight", -QUIVER_SIZE.Border, -QUIVER_SIZE.Border)
	btnCloseTop:SetScript("OnClick", function() f:Hide() end)

	local btnToggleLock = Quiver_UI_Button_ToggleLock(f, function(isChecked)
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
	end)
	local lockOffset = QUIVER_SIZE.Border + QUIVER_SIZE.Icon + QUIVER_SIZE.Gap/2
	btnToggleLock:SetPoint("TopRight", f, "TopRight", -lockOffset, -QUIVER_SIZE.Border)

	_ = Quiver_UI_CheckButton({
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

	_ = Quiver_UI_CheckButton({
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

	_ = Quiver_UI_CheckButton({
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

	return f
end
