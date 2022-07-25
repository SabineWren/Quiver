Quiver_Store_Persist = function() Quiver_Store = Quiver_Store end
Quiver_Store_Restore = function()
	Quiver_Store = Quiver_Store or {}
	Quiver_Store.ModuleEnabled = Quiver_Store.ModuleEnabled or {}

	local me = Quiver_Store.ModuleEnabled
	me.AimedShotCastbar = me.AimedShotCastbar ~= false
	me.AutoShotCastbar = me.AutoShotCastbar ~= false
	me.RangeIndicator = me.RangeIndicator ~= false
	me.TranqAnnouncer = me.TranqAnnouncer ~= false

	Quiver_Store.IsLockedFrames = Quiver_Store.IsLockedFrames == true
	Quiver_Store.FrameMeta = Quiver_Store.FrameMeta or {}
	local fm = Quiver_Store.FrameMeta
	fm.AutoShotCastbar = fm.AutoShotCastbar or {}
	fm.RangeIndicator = fm.RangeIndicator or {}

	Quiver_Store.MsgTranqHit = Quiver_Store.MsgTranqHit or QUIVER_T.DefaultTranqHit
	Quiver_Store.MsgTranqMiss = Quiver_Store.MsgTranqMiss or QUIVER_T.DefaultTranqMiss
end

QUIVER_SIZE = {
	Border = 12,
	Gap = 8,
	Icon = 18,
}
