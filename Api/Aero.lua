-- Support Aero animations if installed.
-- https://github.com/gashole/Aero

---@param f Frame
local RegisterFrame = function(f)
	Aero = IsAddOnLoaded("Aero") and Aero or nil
	if Aero ~= nil then
		if f.GetName then
			Aero:RegisterFrames(f:GetName())
		else
			DEFAULT_CHAT_FRAME:AddMessage("Must pass frame by reference", 1, 0.5, 0)
		end
	end
end

--- Aero calls Show/Hide internally, leading to duplicate calls.
--- - https://github.com/gashole/Aero/issues/2
--- - Update: Aero fixed in latest version, but it may take a long time for users to update.
---@param frame Frame
---@param event "OnHide"|"OnShow"
---@param f function
local SetScript = function(frame, event, f)
	local fAero = frame---@type any
	frame:SetScript(event, function()
		Aero = IsAddOnLoaded("Aero") and Aero or nil
		local animating = Aero ~= nil and fAero.aero and fAero.aero.animating
		if not animating then f() end
	end)
end

return {
	RegisterFrame = RegisterFrame,
	SetScript = SetScript,
}
