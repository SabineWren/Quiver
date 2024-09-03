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

local _TOOLTIP_NAME = "QuiverScanningTooltip"
local tooltip = createTooltip(_TOOLTIP_NAME)

---@param fsName "TextLeft" | "TextRight"
---@param lineNumber integer
---@return nil|string
local GetText = function(fsName, lineNumber)
	---@type nil|FontString
	local fs = _G[_TOOLTIP_NAME .. fsName .. lineNumber]
	return fs and fs:GetText()
end

--- Handles setup and teardown when scanning.
---@generic Output
---@param f fun(t: GameTooltip): Output
---@return Output
---@nodiscard
local Scan = function(f)
	tooltip:SetOwner(WorldFrame, "Center")
	local output = f(tooltip)
	tooltip:Hide()
	return output
end

return {
	GetText = GetText,
	Scan = Scan,
}
