function Quiver_UI_MainMenu_Create()
	local f = Quiver_UI_WithWindowTitle(
		Quiver_UI_Dialog(300, 300), "Quiver")
	f:Hide()

	_ = Quiver_UI_CheckButton({
		Parent = f, Y = -25,
		IsChecked = Quiver_Store.ModuleEnabled.AimedShotCastbar,
		Label = QUIVER_T.Module.AimedShotCastbar,
		OnClick = function (isChecked)
			Quiver_Store.ModuleEnabled.AimedShotCastbar = isChecked
			-- TODO
		end,
	})

	local _ = Quiver_UI_Button_ToggleLock(f)

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

	_ = Quiver_UI_EditBox({
		Parent = f, Y = -150, Label = "Hit",
		Text = Quiver_Store.MsgTranqHit,
		OnChange = function(text) Quiver_Store.MsgTranqHit = text end,
	})
	_ = Quiver_UI_EditBox({
		Parent = f, Y = -180, Label = "Miss",
		Text = Quiver_Store.MsgTranqMiss,
		OnChange = function(text) Quiver_Store.MsgTranqMiss = text end,
	})

	return f
end
