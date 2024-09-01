local DB_SPELL = require "Shiver/Data/Spell.lua"

---@param spellName string
---@return nil|integer spellIndex
local FindSpellIndex = function(spellName)
	local numTabs = GetNumSpellTabs()
	local _, _, tabOffset, numEntries = GetSpellTabInfo(numTabs)
	local numSpells = tabOffset + numEntries
	for spellIndex=1, numSpells do
		local name, _rank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
		if name == spellName then
			return spellIndex
		end
	end
	return nil
end

--- This assumes the texture uniquely identifies a spell, which may not be true.
---@param texturePath string
---@return nil|string spellName
---@return nil|integer spellIndex
---@nodiscard
local FindSpellByTexture = function(texturePath)
	local i = 0
	while true do
		i = i + 1
		local t = GetSpellTexture(i, BOOKTYPE_SPELL)
		local name, _rank = GetSpellName(i, BOOKTYPE_SPELL)
		if not t or not name then
			break-- Base Case
		elseif t == texturePath then
			return name, i
		end
	end
	return nil, nil
end

--- Returns true if spell is instant cast
--- If meta is nil, we can't run cast time code, so assume instant.
---@param meta nil|{ Time: number; Offset: number }
---@return boolean
---@nodiscard
local PredInstant = function(meta)
	if meta == nil then
		return true
	else
		return 0 == meta.Time + meta.Offset
	end
end

---@param name string
---@return boolean
---@nodiscard
local PredInstantShotByName = function(name)
	local meta = DB_SPELL[name]
	return meta ~= nil and meta.IsAmmo and (meta.Offset + meta.Time == 0)
end

---@param spellName string
---@return boolean
---@nodiscard
local PredSpellLearned = function(spellName)
	local i = 0
	while true do
		i = i + 1
		local name, _rank = GetSpellName(i, BOOKTYPE_SPELL)
		if not name then return false
		elseif name == spellName then return true
		end
	end
end

local CheckNewCd = function(cooldown, lastCdStart, spellName)
	local spellId = FindSpellIndex(spellName)
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

return {
	CheckNewCd=CheckNewCd,
	CheckNewGCD=CheckNewGCD,
	FindSpellByTexture = FindSpellByTexture,
	FindSpellIndex = FindSpellIndex,
	PredInstant = PredInstant,
	PredInstantShotByName = PredInstantShotByName,
	PredSpellLearned = PredSpellLearned,
}
