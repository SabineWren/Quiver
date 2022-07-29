local getIsBusy = function()
	for i=1,120 do
		if IsCurrentAction(i) then return true end
	end
	return false
end

local callbacksCastableShot = {}
local publish = function(spellname)
	for _i, v in callbacksCastableShot do v(spellname) end
end
Quiver_Event_Spellcast_Subscribe = function(moduleId, callback)
	callbacksCastableShot[moduleId] = callback
end
Quiver_Event_Spellcast_Unsubscribe = function(moduleId)
	callbacksCastableShot[moduleId] = nil
end

local super = {
	CastSpell = CastSpell,
	CastSpellByName = CastSpellByName,
	UseAction = UseAction,
}
CastSpell = function(spellIndex, spellbookTabNum)
	super.CastSpell(spellIndex, spellbookTabNum)
	if not getIsBusy() then return end
	local spellName, _rank = GetSpellName(spellIndex, spellbookTabNum)
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
