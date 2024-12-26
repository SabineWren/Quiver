local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"

return function()
	local mstore = Quiver_Store.ModuleStore
	if mstore == nil or Quiver_Store.FrameMeta == nil then return end

	-- Rename Auto Shot timer module
	Quiver_Store.ModuleEnabled[AutoShotTimer.Id] = Quiver_Store.ModuleEnabled["AutoShotCastbar"]
	Quiver_Store.ModuleEnabled["AutoShotCastbar"] = nil

	mstore[AutoShotTimer.Id] = mstore["AutoShotCastbar"]
	mstore["AutoShotCastbar"] = nil

	Quiver_Store.FrameMeta[AutoShotTimer.Id] = Quiver_Store.FrameMeta["AutoShotCastbar"]
	Quiver_Store.FrameMeta["AutoShotCastbar"] = nil

	-- Move all module-specific frame data into module stores
	for _i, v in ipairs(_G.Quiver_Modules) do
		if mstore[v.Id] and Quiver_Store.FrameMeta[v.Id] then
			mstore[v.Id].FrameMeta = Quiver_Store.FrameMeta[v.Id]
		end
	end
	Quiver_Store.FrameMeta = nil
end
