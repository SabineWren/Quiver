local HUNTER_SPELLS = {
	[QUIVER_T.Spellbook.Aimed_Shot] = 3.0,
	[QUIVER_T.Spellbook.Multi_Shot] = 0.5,
	[QUIVER_T.Spellbook.Trueshot] = 1.0,
}

local cacheTexture = {}
Quiver_Lib_Spellbook_TryFindTexture = function(nameSeek)
	if cacheTexture[nameSeek] ~= nil then
		return cacheTexture[nameSeek]
	end

	local i = 0
	while true do
		i = i + 1
		local name, _rank = GetSpellName(i, BOOKTYPE_SPELL)
		local texture = GetSpellTexture(i, BOOKTYPE_SPELL)
		if not name then return nil end
		if name == nameSeek then
			cacheTexture[nameSeek] = texture
			return texture
		end
	end
end

-- 10% at full hp, to a max of 30% at 40% hp
-- That's a line with equation f(hp)= (130-hp) / 3, but capped at 30%
local getTrollBerserkBonus = function()
	local percent = UnitHealth("player") / UnitHealthMax("player")
	return math.min(0.3, (1.30 - percent) / 3.0)
end

local getRangedAttackSpeedMultiplier = function()
	local speed = 1.0
	for i=1,QUIVER.Buff_Cap do
		if UnitBuff("player", i) == QUIVER.Icon.CurseOfTongues then
			speed = speed * 0.5
		elseif UnitBuff("player", i) == QUIVER.Icon.NaxxTrinket then
			speed = speed * 1.2
		elseif UnitBuff("player", i) == QUIVER.Icon.Quickshots then
			speed = speed * 1.3
		elseif UnitBuff("player", i) == QUIVER.Icon.RapidFire then
			speed = speed * 1.4
		elseif UnitBuff("player", i) == QUIVER.Icon.TrollBerserk then
			speed = speed * (1.0 + getTrollBerserkBonus())
		end
	end
	return speed
end

Quiver_Lib_Spellbook_GetCastTime = function(spellName)
	local baseTime = HUNTER_SPELLS[spellName]
	local _,_, latency = GetNetStats()
	local start = GetTime() + latency / 1000
	local casttime = baseTime / getRangedAttackSpeedMultiplier()
	return casttime, start
end

Quiver_Lib_Spellbook_TryGetCastableShot = function(actionTexture)
	for k, _v in HUNTER_SPELLS do
		if actionTexture == Quiver_Lib_Spellbook_TryFindTexture(k) then return k end
	end
	return nil
end

Quiver_Lib_Spellbook_GetIsSpellCastableShot = function(spellName)
	for k, _v in HUNTER_SPELLS do
		if spellName == k then return true end
	end
	return false
end


-- Copied from HSK. Not sure how safe or performant this is
local getSpellIndexByName = function(spellName)
	local _schoolName, _schoolIcon, indexOffset, numEntries = GetSpellTabInfo(GetNumSpellTabs())
	local numSpells = indexOffset + numEntries
	local offset = 0
	for spellIndex=numSpells, offset+1, -1 do
		if GetSpellName(spellIndex, "BOOKTYPE_SPELL") == spellName then
			return spellIndex;
		end
	end
	return nil
end
Quiver_Lib_Spellbook_CheckGCD = function()
	local spellId = getSpellIndexByName(QUIVER_T.Spellbook.Serpent_Sting)
	if spellId ~= nil then
	return GetSpellCooldown(spellId, "BOOKTYPE_SPELL")
	else return 0, 0
	end
end
