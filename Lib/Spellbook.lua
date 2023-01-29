local HUNTER_CASTABLE_SHOTS = {
	[QUIVER_T.Spellbook.Aimed_Shot] = 3.0,
	[QUIVER_T.Spellbook.Multi_Shot] = 0.5,
	[QUIVER_T.Spellbook.Trueshot] = 1.3,
}
local HUNTER_INSTANT_SHOTS = {
	QUIVER_T.Spellbook.Arcane_Shot,
	QUIVER_T.Spellbook.Concussive_Shot,
	QUIVER_T.Spellbook.Scatter_Shot,
	QUIVER_T.Spellbook.Scorpid_Sting,
	QUIVER_T.Spellbook.Serpent_Sting,
	QUIVER_T.Spellbook.Viper_Sting,
	QUIVER_T.Spellbook.Wyvern_Sting,
}

Quiver_Lib_Spellbook_GetIsSpellLearned = function(spellName)
	local i = 0
	while true do
		i = i + 1
		local name, _rank = GetSpellName(i, BOOKTYPE_SPELL)
		if not name then return false
		elseif name == spellName then return true
		end
	end
end

-- This assumes every Hunter spell has a unique texture. I don't
-- know if that's true for all spells, but at time of writing
-- we only care about spells that consume ammo.
local cacheTextureName = {}
Quiver_Lib_Spellbook_GetSpellNameFromTexture = function(textureSeek)
	if cacheTextureName[textureSeek] ~= nil then
		return cacheTextureName[textureSeek]
	end
	local i = 0
	while true do
		i = i + 1
		local name, _rank = GetSpellName(i, BOOKTYPE_SPELL)
		local texture = GetSpellTexture(i, BOOKTYPE_SPELL)
		if not name then return nil end
		if texture == textureSeek then
			cacheTextureName[textureSeek] = name
			return name
		end
	end
end

-- Spells can change texture, such as Auto Shot when equipping a ranged weapon.
-- Therefore, don't rely on this always returning the correct texture
local cacheNameTexture = {}
Quiver_Lib_Spellbook_TryFindTexture = function(nameSeek)
	if cacheNameTexture[nameSeek] ~= nil then
		return cacheNameTexture[nameSeek]
	end
	local i = 0
	while true do
		i = i + 1
		local name, _rank = GetSpellName(i, BOOKTYPE_SPELL)
		local texture = GetSpellTexture(i, BOOKTYPE_SPELL)
		if not name then return nil end
		if name == nameSeek then
			cacheNameTexture[nameSeek] = texture
			return texture
		end
	end
end

Quiver_Lib_Spellbook_GetCastTime = function(spellName)
	local baseTime = HUNTER_CASTABLE_SHOTS[spellName]
	local _,_, msLatency = GetNetStats()
	local start = GetTime() + msLatency / 1000
	local casttime = baseTime / Quiver_Lib_Aura_GetRangedAttackSpeedMultiplier()
	return casttime, start
end

Quiver_Lib_Spellbook_GetIsSpellCastableShot = function(spellName)
	for name, _castTime in HUNTER_CASTABLE_SHOTS do
		if spellName == name then return true end
	end
	return false
end
Quiver_Lib_Spellbook_GetIsSpellInstantShot = function(spellName)
	for _index, name in HUNTER_INSTANT_SHOTS do
		if spellName == name then return true end
	end
	return false
end

-- This function copied from HSK and MIT licensed,
-- Copyright (c) 2018 Anielle@Lightshope-Lightbringer
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

Quiver_Lib_Spellbook_CheckNewGCD = function(lastCdStart)
	local spellId = getSpellIndexByName(QUIVER_T.Spellbook.Serpent_Sting)
	if spellId ~= nil then
		local timeStartCD, durationCD = GetSpellCooldown(spellId, "BOOKTYPE_SPELL")
		-- Sometimes spells return a CD of 0 when cast fails.
		-- If it's non-zero, we have a valid timeStart to check.
		if durationCD == 1.5 and timeStartCD ~= lastCdStart then
			return true, timeStartCD
		end
	end
	return false, lastCdStart
end
