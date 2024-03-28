local createTooltip = function(frameName)
	-- https://wowwiki-archive.fandom.com/wiki/UIOBJECT_GameTooltip
	local tt = CreateFrame("GameTooltip", frameName, nil, "GameTooltipTemplate")
	tt:SetScript("OnHide", function() tt:SetOwner(WorldFrame, "ANCHOR_NONE") end)
	tt:Hide()
	tt:SetFrameStrata("Tooltip")
	return tt
end

--[[ [ Quiver_Lib_Tooltip_Factory ]
	@description Returns a function that clears the tooltip and gets a reference to it.
	@param frameName string name for tooltip element
]]
Quiver_Lib_Tooltip_Factory = function(frameName)
	local tooltip = createTooltip(frameName)
	return function()
		tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
		return tooltip
	end
end
