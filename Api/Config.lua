-- Screen size scales after initializing, but when it does, the UI scale value also changes.
-- Therefore, the result of size * scale never changes, but the result of either size or scale does.
-- Disabling useUIScale doesn't affect the scale value, so we have to conditionally scale saved frame positions.
local GetScreenWidthScaled = function()
	local scale = GetCVar("useUiScale") == 1 and UIParent:GetEffectiveScale() or 1
	return GetScreenWidth() * scale
end
local GetScreenHeightScaled = function()
	local scale = GetCVar("useUiScale") == 1 and UIParent:GetEffectiveScale() or 1
	return GetScreenHeight() * scale
end

return {
	GetScreenWidthScaled = GetScreenWidthScaled,
	GetScreenHeightScaled = GetScreenHeightScaled,
}
