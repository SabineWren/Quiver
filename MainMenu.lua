function Quiver_MainMenu_Create()
	local f = Quiver_UI_WithWindowTitle(
		Quiver_UI_Dialog(300, 300), "Quiver")
	f:Hide()

	local btnCloseTop = Quiver_UI_Button_Close(f)
	btnCloseTop:SetPoint("TopRight", f, "TopRight", -QUIVER_SIZE.Border, -QUIVER_SIZE.Border)
	btnCloseTop:SetScript("OnClick", function() f:Hide() end)

	local btnToggleLock = Quiver_UI_Button_ToggleLock(f)
	local lockOffset = QUIVER_SIZE.Border + QUIVER_SIZE.Icon + QUIVER_SIZE.Gap/2
	btnToggleLock:SetPoint("TopRight", f, "TopRight", -lockOffset, -QUIVER_SIZE.Border)

	_ = Quiver_UI_CheckButton({
		Parent = f, Y = -25,
		IsChecked = Quiver_Store.ModuleEnabled.AimedShotCastbar,
		Label = QUIVER_T.Module.AimedShotCastbar,
		OnClick = function (isChecked)
			Quiver_Store.ModuleEnabled.AimedShotCastbar = isChecked
			-- TODO
		end,
	})

	_ = Quiver_UI_CheckButton({
		Parent = f, Y = -55,
		IsChecked = Quiver_Store.ModuleEnabled.AutoShotCastbar,
		Label = QUIVER_T.Module.AutoShotCastbar,
		OnClick = function (isChecked)
			Quiver_Store.ModuleEnabled.AutoShotCastbar = isChecked
			if isChecked
			then Quiver_Module_AutoShotCastbar_Enable()
			else Quiver_Module_AutoShotCastbar_Disable()
			end
		end,
	})

	_ = Quiver_UI_CheckButton({
		Parent = f, Y = -85,
		IsChecked = Quiver_Store.ModuleEnabled.RangeIndicator,
		Label = "Range Indicator",
		Tooltip = "Shows when abilities are in range. Requires spellbook abilities placed somewhere on your action bars.",
		OnClick = function (isChecked)
			Quiver_Store.ModuleEnabled.RangeIndicator = isChecked
			if isChecked
			then Quiver_Module_RangeIndicator_Enable()
			else Quiver_Module_RangeIndicator_Disable()
			end
		end,
	})

	_ = Quiver_UI_CheckButton({
		Parent = f, Y = -115,
		IsChecked = Quiver_Store.ModuleEnabled.TranqAnnouncer,
		Label = "Tranq Shot Announcer",
		Tooltip = "Announces in /Raid chat when your tranquilizing shot hits or misses a target.",
		OnClick = function (isChecked)
			Quiver_Store.ModuleEnabled.TranqAnnouncer = isChecked
			if isChecked
			then Quiver_Module_TranqAnnouncer_Enable()
			else Quiver_Module_TranqAnnouncer_Disable()
			end
		end,
	})

	local editHit = Quiver_UI_EditBox({
		Parent = f, YOffset = -150,
		TooltipReset="Reset Hit Message to Default",
		Text = Quiver_Store.MsgTranqHit,
	})
	editHit:SetScript("OnTextChanged", function()
		Quiver_Store.MsgTranqHit = editHit:GetText()
	end)
	editHit.BtnReset:SetScript("OnClick", function()
		editHit:SetText(QUIVER_T.DefaultTranqHit)
	end)

	local editMiss = Quiver_UI_EditBox({
		Parent = f, YOffset = -180,
		TooltipReset="Reset Miss Message to Default",
		Text = Quiver_Store.MsgTranqMiss,
	})
	editMiss:SetScript("OnTextChanged", function()
		Quiver_Store.MsgTranqMiss = editMiss:GetText()
	end)
	editMiss.BtnReset:SetScript("OnClick", function()
		editMiss:SetText(QUIVER_T.DefaultTranqMiss)
	end)

	return f
end
