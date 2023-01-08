Quiver_Migrations_M003 = function()
	local mstore = Quiver_Store.ModuleStore or {}
	local s = mstore[Quiver_Module_TranqAnnouncer.Id] or {}

	-- Change colour to color
	if s.ColourShoot then s.ColorShoot = s.ColourShoot end
	if s.ColorReload then s.ColorReload = s.ColourReload end
	s.ColourShoot = nil
	s.ColourReload = nil

	if s.MsgTranqHit then
		-- We notify on tranq cast instead of hit. To prevent a breaking
		-- release version, attempt changing contradictory text.
		local startPos, _ = string.find(string.lower(s.MsgTranqHit), "hit")
		if startPos then
			s.MsgTranqHit = QUIVER_T.Tranq.DefaultCast
		end

		-- Change name to account for new behaviour
		s.MsgTranqCast = s.MsgTranqHit
		s.MsgTranqHit = nil
	end
end
