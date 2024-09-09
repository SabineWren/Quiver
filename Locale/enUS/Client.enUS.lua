local Spell = require "Locale/enUS/Spell.enUS.lua"
-- local Zone = require "Locale/enUS/Zone.enUS.lua"

return {
	CombatLog = {
		Consumes = {
			ManaPotion = "You gain (.*) Mana from Restore Mana.",
			HealthPotion = "Your Healing Potion heals you for (.*).",
			Healthstone = "Your (.*) Healthstone heals you for (.*).",
			Tea = "Your Tea with Sugar heals you for (.*).",
		},
		Tranq = {
			Fail = "You fail to dispel",
			Miss = "Your Tranquilizing Shot miss",
			Resist = "Your Tranquilizing Shot was resisted",
		},
	},
	Spell = Spell,
	SpellReverse = Spell,
}
