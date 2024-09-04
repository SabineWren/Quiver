local EditBox = require "Components/EditBox.lua"
local TranqAnnouncer = require "Modules/TranqAnnouncer.lua"

-- TODO this is tightly coupled to tranq announcer,
-- which doesn't make sense for a text component.
local Create = function(parent, gap)
	local store = Quiver_Store.ModuleStore[TranqAnnouncer.Id]
	local f = CreateFrame("Frame", nil, parent)

	local editCast = EditBox.Create(f, QUIVER_T.Tranq.TooltipCast)
	editCast.Box:SetText(store.MsgTranqCast)
	editCast.Box:SetScript("OnTextChanged", function()
		store.MsgTranqCast = editCast.Box:GetText()
	end)
	editCast.Reset.OnClick = function()
		editCast.Box:SetText(QUIVER_T.Tranq.DefaultCast)
	end

	local editMiss = EditBox.Create(f, QUIVER_T.Tranq.TooltipMiss)
	editMiss.Box:SetText(store.MsgTranqMiss)
	editMiss.Box:SetScript("OnTextChanged", function()
		store.MsgTranqMiss = editMiss.Box:GetText()
	end)
	editMiss.Reset.OnClick = function()
		editMiss.Box:SetText(QUIVER_T.Tranq.DefaultMiss)
	end

	local height1 = editCast.Box:GetHeight()
	editCast.Box:SetPoint("Top", f, "Top", 0, 0)
	editMiss.Box:SetPoint("Top", f, "Top", 0, -1 * (height1 + gap))

	f:SetWidth(parent:GetWidth())
	f:SetHeight(height1 + gap + editMiss.Box:GetHeight())
	return f
end

return {
	Create = Create,
}
