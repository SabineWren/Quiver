Quiver_Migrations_M001 = function()
	if Quiver_Store.ModuleStore == nil then return end
	local store = Quiver_Store.ModuleStore or {}

	-- Rename swing timer module
	if store["AutoShotCastbar"] then
		store[Quiver_Module_AutoShotTimer.Id] = store["AutoShotCastbar"]
		store["AutoShotCastbar"] = nil
	end
	if Quiver_Store.FrameMeta["AutoShotCastbar"] then
		Quiver_Store.FrameMeta[Quiver_Module_AutoShotTimer.Id] = Quiver_Store.FrameMeta["AutoShotCastbar"]
		Quiver_Store.FrameMeta["AutoShotCastbar"] = nil
	end

	-- Move all module-specific frame data into module stores
	for _k, v in _G.Quiver_Modules do
		if store[v.Id] and Quiver_Store.FrameMeta[v.Id] then
			store[v.Id].FrameMeta = Quiver_Store.FrameMeta[v.Id]
		end
	end
	Quiver_Store.FrameMeta = nil
end

--[[

]]
