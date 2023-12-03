-- TODO parse spellbook in case a patch changes them, instead of hard-coding here
local HUNTER_CASTABLE_SHOTS = {
	[QUIVER_T.Spellbook.Aimed_Shot] = 3.0,
	[QUIVER_T.Spellbook.Multi_Shot] = 0.0,
	[QUIVER_T.Spellbook.Trueshot] = 1.0,
}

local _HUNTER_INSTANT_SHOTS = {
	QUIVER_T.Spellbook.Arcane_Shot,
	QUIVER_T.Spellbook.Concussive_Shot,
	QUIVER_T.Spellbook.Scatter_Shot,
	QUIVER_T.Spellbook.Scorpid_Sting,
	QUIVER_T.Spellbook.Serpent_Sting,
	QUIVER_T.Spellbook.Viper_Sting,
	QUIVER_T.Spellbook.Wyvern_Sting,
}

local calcRangedWeaponSpeedBase = (function()
	local resetTooltip = Quiver_Lib_Tooltip_Factory("QuiverRangedWeaponScanningTooltip")

	-- Might be cachable. GetInventoryItemLink("Player", slot#) returns a link, ex. [name]
	-- Weapon name always appears at line TextLeft1
	return function()
		local tooltip = resetTooltip()
		tooltip:ClearLines()
		tooltip:SetInventoryItem("player", 18)-- ranged weapon slot

		for i=1, tooltip:NumLines() do
			local fs = _G["QuiverRangedWeaponScanningTooltipTextRight"..i]
			local text = fs and fs:GetText()
			if text ~= nil then
				local _, _, speed = string.find(text, "Speed (%d+%.%d+)")
				if speed ~= nil then
					local parsed = tonumber(speed)
					if parsed ~= nil then
						return parsed
					end
				end
			end
		end
	end
end)()

Quiver_Lib_Spellbook_CalcCastTime = function(spellName)
	local baseTime = HUNTER_CASTABLE_SHOTS[spellName]
	local _,_, msLatency = GetNetStats()
	local startLocal = GetTime()
	local startLatAdjusted = startLocal + msLatency / 1000

	local speedCurrent = UnitRangedDamage("player")
	local speedBase = calcRangedWeaponSpeedBase()
	local speedMultiplier = speedCurrent / speedBase

	-- https://www.mmo-champion.com/content/2188-Patch-4-0-6-Feb-22-Hotfixes-Blue-Posts-Artworks-Comic
	local casttime = 0.5 + baseTime * speedMultiplier
	return casttime, startLatAdjusted, startLocal
end

local GetIsSpellLearned = function(spellName)
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
local GetSpellNameFromTexture = function(textureSeek)
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

Quiver_Lib_Spellbook_GetIsSpellCastableShot = function(spellName)
	for name, _castTime in HUNTER_CASTABLE_SHOTS do
		if spellName == name then return true end
	end
	return false
end
Quiver_Lib_Spellbook_GetIsSpellInstantShot = function(spellName)
	for _index, name in _HUNTER_INSTANT_SHOTS do
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
		if GetSpellName(spellIndex, BOOKTYPE_SPELL) == spellName then
			return spellIndex;
		end
	end
	return nil
end

local CheckNewCd = function(cooldown, lastCdStart, spellName)
	local spellId = getSpellIndexByName(spellName)
	if spellId ~= nil then
		local timeStartCD, durationCD = GetSpellCooldown(spellId, BOOKTYPE_SPELL)
		-- Sometimes spells return a CD of 0 when cast fails.
		-- If it's non-zero, we have a valid timeStart to check.
		if durationCD == cooldown and timeStartCD ~= lastCdStart then
			return true, timeStartCD
		end
	end
	return false, lastCdStart
end

local CheckNewGCD = function(lastCdStart)
	return CheckNewCd(1.5, lastCdStart, QUIVER_T.Spellbook.Serpent_Sting)
end

Quiver_Lib_Spellbook = {
	CheckNewCd=CheckNewCd,
	CheckNewGCD=CheckNewGCD,
	GetIsSpellLearned = GetIsSpellLearned,
	GetSpellNameFromTexture=GetSpellNameFromTexture,
	HUNTER_CASTABLE_SHOTS=HUNTER_CASTABLE_SHOTS,
}
