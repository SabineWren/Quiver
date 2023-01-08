Quiver_Config_InputText_TranqAnnouncer = function(parent, gap)
	local store = Quiver_Store.ModuleStore[Quiver_Module_TranqAnnouncer.Id]
	local f = CreateFrame("Frame", nil, parent)

	local editCast = Quiver_Component_EditBox(f, { TooltipReset=QUIVER_T.Tranq.TooltipCast })
	editCast:SetText(store.MsgTranqCast)
	editCast:SetScript("OnTextChanged", function()
		store.MsgTranqCast = editCast:GetText()
	end)
	editCast.BtnReset:SetScript("OnClick", function()
		editCast:SetText(QUIVER_T.Tranq.DefaultCast)
	end)

	local editMiss = Quiver_Component_EditBox(f, { TooltipReset=QUIVER_T.Tranq.TooltipMiss })
	editMiss:SetText(store.MsgTranqMiss)
	editMiss:SetScript("OnTextChanged", function()
		store.MsgTranqMiss = editMiss:GetText()
	end)
	editMiss.BtnReset:SetScript("OnClick", function()
		editMiss:SetText(QUIVER_T.Tranq.DefaultMiss)
	end)

	local height1 = editCast:GetHeight()
	editCast:SetPoint("Top", f, "Top", 0, 0)
	editMiss:SetPoint("Top", f, "Top", 0, -1 * (height1 + gap))

	f:SetWidth(parent:GetWidth())
	f:SetHeight(height1 + gap + editMiss:GetHeight())
	return f
end
