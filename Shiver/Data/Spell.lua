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
return {
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
