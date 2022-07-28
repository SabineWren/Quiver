local getIsBusy = function()
	for i=1,120 do
		if IsCurrentAction(i) then return true end
	end
	return false
end

local spellcastCallbacks = {}
local publish = function(spellname)
	for _i, v in spellcastCallbacks do v(spellname) end
end
Quiver_Events_Spellcast_Subscribe = function(callback)
	tinsert(spellcastCallbacks, callback)
end

local super = {
	CastSpell = CastSpell,
	CastSpellByName = CastSpellByName,
	UseAction = UseAction,
}
CastSpell = function(spellId, spellbookTabNum)
	super.CastSpell(spellId, spellbookTabNum)
	local spellName, _rank = GetSpellName(spellId, spellbookTabNum)
	if not getIsBusy() then return end
	local isShot = Quiver_Lib_Spellbook_GetIsSpellCastableShot(spellName)
	if isShot then publish(spellName) end
end
CastSpellByName = function(spellName, onSelf)
	super.CastSpellByName(spellName, onSelf)
	if not getIsBusy() then return end
	local isShot = Quiver_Lib_Spellbook_GetIsSpellCastableShot(spellName)
	if isShot then publish(spellName) end
end
UseAction = function(slot, checkCursor, onSelf)
	super.UseAction(slot, checkCursor, onSelf)
	-- Raw abilities return a nil action name. Macros, items, etc. don't.
	if GetActionText(slot) or not IsCurrentAction(slot) or GetActionText(slot) ~= nil then return end
	local actionTexture = GetActionTexture(slot)
	local spellName = Quiver_Lib_Spellbook_TryGetCastableShot(actionTexture)
	if spellName ~= nil then publish(spellName) end
end
