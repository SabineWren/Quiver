Quiver_Config_InputText_TranqAnnouncer = function(parent, gap)
	local store = Quiver_Store.ModuleStore[Quiver_Module_TranqAnnouncer.Id]
	local f = CreateFrame("Frame", nil, parent)

	local editHit = Quiver_Component_EditBox(f, { TooltipReset=QUIVER_T.Tranq.TooltipHit })
	editHit:SetText(store.MsgTranqHit)
	editHit:SetScript("OnTextChanged", function()
		store.MsgTranqHit = editHit:GetText()
	end)
	editHit.BtnReset:SetScript("OnClick", function()
		editHit:SetText(QUIVER_T.Tranq.DefaultHit)
	end)

	local editMiss = Quiver_Component_EditBox(f, { TooltipReset=QUIVER_T.Tranq.TooltipMiss })
	editMiss:SetText(store.MsgTranqMiss)
	editMiss:SetScript("OnTextChanged", function()
		store.MsgTranqMiss = editMiss:GetText()
	end)
	editMiss.BtnReset:SetScript("OnClick", function()
		editMiss:SetText(QUIVER_T.Tranq.DefaultMiss)
	end)

	local height1 = editHit:GetHeight()
	editHit:SetPoint("Top", f, "Top", 0, 0)
	editMiss:SetPoint("Top", f, "Top", 0, -1 * (height1 + gap))

	f:SetWidth(editHit:GetWidth())
	f:SetHeight(height1 + gap + editMiss:GetHeight())
	return f
end
