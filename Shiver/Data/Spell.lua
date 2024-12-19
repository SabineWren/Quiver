-- Data is fully denormalized since we don't have a database.
-- This will probably cause maintenance problems.
return {
	-- Casted Shots
	["Aimed Shot"]={ Class="hunter", Time=3000, Offset=500, Haste="range", Icon="INV_Spear_07", IsAmmo=true },
	["Multi-Shot"]={ Class="hunter", Time=0, Offset=500, Haste="range", Icon="Ability_UpgradeMoonGlaive", IsAmmo=true },
	["Steady Shot"]={ Class="hunter", Time=1000, Offset=500, Haste="range", Icon="Ability_Hunter_SteadyShot", IsAmmo=true },

	-- Instant Shots
	["Arcane Shot"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Ability_ImpalingBolt", IsAmmo=true },
	["Concussive Shot"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Spell_Frost_Stun", IsAmmo=true },
	["Scatter Shot"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Ability_GolemStormBolt", IsAmmo=true },
	["Scorpid Sting"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Ability_Hunter_CriticalShot", IsAmmo=true },
	["Serpent Sting"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Ability_Hunter_Quickshot", IsAmmo=true },
	["Viper Sting"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="Ability_Hunter_AimedShot", IsAmmo=true },
	["Wyvern Sting"]={ Class="hunter", Time=0, Offset=0, Haste="none", Icon="INV_Spear_02", IsAmmo=true },
}
