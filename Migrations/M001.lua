Quiver_Migrations_M001 = function()
	local mstore = Quiver_Store.ModuleStore
	if mstore == nil or Quiver_Store.FrameMeta == nil then return end

	-- Rename Auto Shot timer module
	Quiver_Store.ModuleEnabled[Quiver_Module_AutoShotTimer.Id] = Quiver_Store.ModuleEnabled["AutoShotCastbar"]
	Quiver_Store.ModuleEnabled["AutoShotCastbar"] = nil

	mstore[Quiver_Module_AutoShotTimer.Id] = mstore["AutoShotCastbar"]
	mstore["AutoShotCastbar"] = nil

	Quiver_Store.FrameMeta[Quiver_Module_AutoShotTimer.Id] = Quiver_Store.FrameMeta["AutoShotCastbar"]
	Quiver_Store.FrameMeta["AutoShotCastbar"] = nil

	-- Move all module-specific frame data into module stores
	for _k, v in _G.Quiver_Modules do
		if mstore[v.Id] and Quiver_Store.FrameMeta[v.Id] then
			mstore[v.Id].FrameMeta = Quiver_Store.FrameMeta[v.Id]
		end
	end
	Quiver_Store.FrameMeta = nil
end
