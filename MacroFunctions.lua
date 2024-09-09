local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local Pet = require "Shiver/API/Pet.lua"
local Spell = require "Shiver/API/Spell.lua"

---@param spellName string
---@return nil
local CastNoClip = function(spellName)
	if not AutoShotTimer.PredMidShot() then
		CastSpellByName(spellName)
	end
end

---@param actionName string
---@return nil
local CastPetAction = function(actionName)
	-- local hasSpells = HasPetUI()
	-- local hasUI = HasPetUI()
	if GetPetActionsUsable() then
		Pet.CastActionByName(actionName)
	end
end

-- Casts feign death (if needed) and sets pet passive (if needed).
-- Usage:
-- /cast Frost Trap
-- /script Quiver.FdPrepareTrap()
local FdPrepareTrap = function()
	-- Requires level 16, which makes it the lowest level trap
	local trap = Quiver.L.Spell["Immolation Trap"]
	local spellIndex = Spell.FindSpellIndex(trap)
	if spellIndex == nil then
		DEFAULT_CHAT_FRAME:AddMessage("Could not find "..trap.." in spellbook.")
	else
		local timeStartCdTrap, _ = GetSpellCooldown(spellIndex, BOOKTYPE_SPELL)
		local timeStartCdFd = 0

		local fd = Quiver.L.Spell["Feign Death"]
		local fdIndex = Spell.FindSpellIndex(fd)
		if fdIndex ~= nil then
			timeStartCdFd = GetSpellCooldown(fdIndex, BOOKTYPE_SPELL)
		end

		if timeStartCdTrap == 0 and timeStartCdFd == 0 and UnitAffectingCombat("player") then
			if UnitExists("pettarget") and UnitAffectingCombat("pet") then
				PetPassiveMode()
			end
			CastSpellByName(fd)
		end
	end
end

return function()
	Quiver.CastNoClip = CastNoClip
	Quiver.CastPetAction = CastPetAction
	Quiver.FdPrepareTrap = FdPrepareTrap
	Quiver.PredMidShot = AutoShotTimer.PredMidShot
end
