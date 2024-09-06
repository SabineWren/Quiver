local EditBox = require "Component/EditBox.lua"
local TranqAnnouncer = require "Modules/TranqAnnouncer.lua"

-- TODO this is tightly coupled to tranq announcer,
-- which doesn't make sense for a separate component.
local Create = function(parent, gap)
	local store = Quiver_Store.ModuleStore[TranqAnnouncer.Id]
	local f = CreateFrame("Frame", nil, parent)

	local editCast = EditBox:Create(f, Quiver.T["Reset Tranq Message to Default"])
	editCast.Box:SetText(store.MsgTranqCast)
	editCast.Box:SetScript("OnTextChanged", function()
		store.MsgTranqCast = editCast.Box:GetText()
	end)
	editCast.Reset.HookClick = function()
		editCast.Box:SetText(Quiver.T["Casting Tranq Shot"])
	end

	local editMiss = EditBox:Create(f, Quiver.T["Reset Miss Message to Default"])
	editMiss.Box:SetText(store.MsgTranqMiss)
	editMiss.Box:SetScript("OnTextChanged", function()
		store.MsgTranqMiss = editMiss.Box:GetText()
	end)
	editMiss.Reset.HookClick = function()
		editMiss.Box:SetText(Quiver.T["*** MISSED Tranq Shot ***"])
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
