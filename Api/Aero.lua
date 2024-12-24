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

---@param f Frame
---@return boolean
---@nodiscard
local predAnimating = function(f)
	Aero = IsAddOnLoaded("Aero") and Aero or nil
	local ff = f---@type { aero: { animating: boolean } }
	return Aero ~= nil and ff.aero and ff.aero.animating
end

--- Aero calls Show/Hide internally, leading to duplicate calls.
---@param frame Frame
---@param event "OnHide"|"OnShow"
---@param f function
local SetScript = function(frame, event, f)
	frame:SetScript(event, function()
		if not predAnimating(frame) then f() end
	end)
end

return {
	RegisterFrame = RegisterFrame,
	SetScript = SetScript,
}
