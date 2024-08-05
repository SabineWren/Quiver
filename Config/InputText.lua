local EditBox = require "Components/EditBox.lua"
local TranqAnnouncer = require "Modules/TranqAnnouncer.lua"

-- TODO this is tightly coupled to tranq announcer,
-- which doesn't make sense for a text component.
local Create = function(parent, gap)
	local store = Quiver_Store.ModuleStore[TranqAnnouncer.Id]
	local f = CreateFrame("Frame", nil, parent)

	local editCast = EditBox.Create(f, { TooltipReset=QUIVER_T.Tranq.TooltipCast })
	editCast:SetText(store.MsgTranqCast)
	editCast:SetScript("OnTextChanged", function()
		store.MsgTranqCast = editCast:GetText()
	end)
	editCast.BtnReset:SetScript("OnClick", function()
		editCast:SetText(QUIVER_T.Tranq.DefaultCast)
	end)

	local editMiss = EditBox.Create(f, { TooltipReset=QUIVER_T.Tranq.TooltipMiss })
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

return {
	Create = Create,
}
