-- Support Aero animations if installed.
-- https://github.com/gashole/Aero

---@param f Frame
---@return nil
local RegisterFrame = function(f)
	---@diagnostic disable-next-line undefined-global
	if IsAddOnLoaded("Aero") and Aero then
	---@diagnostic disable-next-line undefined-global
		Aero:RegisterFrames(f:GetName())
	end
end

return {
	RegisterFrame = RegisterFrame,
}
