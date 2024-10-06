local Spell = require "Locale/zhCN/Spell.zhCN.lua"
local SpellReverse = require "Locale/zhCN/Spell.reverse.zhCN.lua"
-- local Zone = require "Locale/zhCN/Zone.zhCN.lua"

return {
	CombatLog = {
		Consumes = {
			ManaPotion = "你从恢复法力中获得(.*)点法力值。",
			HealthPotion = "你的治疗药水为你恢复了(.*)点生命值。",
			Healthstone = "你的(.*)治疗石为你恢复了(.*)点生命值。",
			Tea = "你的糖水茶为你恢复了(.*)点生命值。",
		},
		Tranq = {
			Fail = "你未能驱散",
			Miss = "你的宁神射击未命中",
			Resist = "你的宁神射击被抵抗了",
		},
	},
	Spell = Spell,
	-- TODO it turns out spellnames aren't unique in Chinese.
	-- This approach isn't going to work in the general case.
	SpellReverse = SpellReverse,
}
