local HUNTER_CASTABLE_SHOTS = {
	[QUIVER_T.Spellbook.Aimed_Shot] = 3.0,
	[QUIVER_T.Spellbook.Multi_Shot] = 0.5,
	[QUIVER_T.Spellbook.Trueshot] = 1.0,
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
	local baseTime = HUNTER_CASTABLE_SHOTS[spellName]
	local _,_, latency = GetNetStats()
	local start = GetTime() + latency / 1000
	local casttime = baseTime / getRangedAttackSpeedMultiplier()
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

-- Copied from HSK
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
		-- Sometimes spells return a CD of 0 when cast fails
		-- If it's non-zero, we should have a valid timeStart to check
		if durationCD == 1.5 and timeStartCD ~= lastCdStart then
			return true, timeStartCD
		end
	end
	return false, lastCdStart
end
