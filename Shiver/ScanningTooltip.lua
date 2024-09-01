--- Creates a scanning tooltip for later use
---@param name string Name of global tooltip frame
---@return GameTooltip
---@nodiscard
local createTooltip = function(name)
	local tt = CreateFrame("GameTooltip", name, nil, "GameTooltipTemplate")
	tt:SetScript("OnHide", function() tt:SetOwner(WorldFrame, "Center") end)
	tt:Hide()
	tt:SetFrameStrata("TOOLTIP")
	return tt
end

---@param tooltip GameTooltip
---@param fsName "TextLeft" | "TextRight"
---@param lineNumber integer
---@return nil|string
local GetText = function(tooltip, fsName, lineNumber)
	local name = tooltip:GetName()
	if name == nil then
		return nil
	else
		---@type nil|FontString
		local fs = _G[name .. fsName .. lineNumber]
		return fs and fs:GetText()
	end
end

---Returns a function that clears the tooltip and gets a reference to it.
---@param name string Name for tooltip element
---@return fun(): GameTooltip
local Init = function(name)
	local tooltip = createTooltip(name)
	return function()
		tooltip:SetOwner(WorldFrame, "Center")
		return tooltip
	end
end

-- TODO Caller has to hide tooltip. Figure out a 'Scan' function to hide automatically.
return {
	GetText = GetText,
	Init = Init,
}
