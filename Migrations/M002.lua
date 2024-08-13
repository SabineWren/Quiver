local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"

return function()
	local mstore = Quiver_Store.ModuleStore or {}
	local s = mstore[AutoShotTimer.Id] or {}

	-- Change colour to color
	if s.ColourShoot then s.ColorShoot = s.ColourShoot end
	if s.ColorReload then s.ColorReload = s.ColourReload end
	s.ColourShoot = nil
	s.ColourReload = nil
end
