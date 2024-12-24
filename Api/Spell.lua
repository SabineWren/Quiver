---@class SpellMetaAll
---@field Class CharacterClass
---@field Icon string

---@class SpellMetaCastedShot: SpellMetaAll
---@field Haste "range"
---@field IsAmmo true
---@field Time integer
---@field Offset integer

---@class SpellMetaInstantShot: SpellMetaAll
---@field Haste "none"
---@field IsAmmo true

-- Data is fully denormalized since we don't have a database.
-- This will probably cause maintenance problems.
local DB_SPELL = {
	-- Casted Shots
	["Aimed Shot"]={ Class="HUNTER", Time=3000, Offset=500, Haste="range", Icon="INV_Spear_07", IsAmmo=true },---@type SpellMetaCastedShot
	["Multi-Shot"]={ Class="HUNTER", Time=0, Offset=500, Haste="range", Icon="Ability_UpgradeMoonGlaive", IsAmmo=true },---@type SpellMetaCastedShot
	["Steady Shot"]={ Class="HUNTER", Time=1000, Offset=500, Haste="range", Icon="Ability_Hunter_SteadyShot", IsAmmo=true },---@type SpellMetaCastedShot

	-- Instant Shots
	["Arcane Shot"]={ Class="HUNTER", Haste="none", Icon="Ability_ImpalingBolt", IsAmmo=true },---@type SpellMetaInstantShot
	["Concussive Shot"]={ Class="HUNTER", Haste="none", Icon="Spell_Frost_Stun", IsAmmo=true },---@type SpellMetaInstantShot
	["Scatter Shot"]={ Class="HUNTER", Haste="none", Icon="Ability_GolemStormBolt", IsAmmo=true },---@type SpellMetaInstantShot
	["Scorpid Sting"]={ Class="HUNTER", Haste="none", Icon="Ability_Hunter_CriticalShot", IsAmmo=true },---@type SpellMetaInstantShot
	["Serpent Sting"]={ Class="HUNTER", Haste="none", Icon="Ability_Hunter_Quickshot", IsAmmo=true },---@type SpellMetaInstantShot
	["Viper Sting"]={ Class="HUNTER", Haste="none", Icon="Ability_Hunter_AimedShot", IsAmmo=true },---@type SpellMetaInstantShot
	["Wyvern Sting"]={ Class="HUNTER", Haste="none", Icon="INV_Spear_02", IsAmmo=true },---@type SpellMetaInstantShot
}

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

--- Returns true if spell is instant cast. If nil, assume instant.
---@param name string
---@return boolean
---@nodiscard
local PredInstantCast = function(name)
	local meta = DB_SPELL[name]
	if meta == nil then
		return true
	else
		return meta.Haste == "none"
	end
end

---@param name string
---@return boolean
---@nodiscard
local PredInstantShot = function(name)
	local meta = DB_SPELL[name]
	return meta ~= nil and meta.IsAmmo and PredInstantCast(name)
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
	local spellIndex = FindSpellIndex(spellName)
	if spellIndex ~= nil then
		local timeStartCD, durationCD = GetSpellCooldown(spellIndex, BOOKTYPE_SPELL)
		-- Sometimes spells return a CD of 0 when cast fails.
		-- If it's non-zero, we have a valid timeStart to check.
		if durationCD == cooldown and timeStartCD ~= lastCdStart then
			return true, timeStartCD
		end
	end
	return false, lastCdStart
end

local CheckNewGCD = function(lastCdStart)
	return CheckNewCd(1.5, lastCdStart, Quiver.L.Spell["Serpent Sting"])
end

return {
	CheckNewCd = CheckNewCd,
	CheckNewGCD = CheckNewGCD,
	Db = DB_SPELL,
	FindSpellByTexture = FindSpellByTexture,
	FindSpellIndex = FindSpellIndex,
	PredInstantCast = PredInstantCast,
	PredInstantShot = PredInstantShot,
	PredSpellLearned = PredSpellLearned,
}
