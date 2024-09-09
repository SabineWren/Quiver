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

--- Casts feign death (if needed) and sets pet passive (if needed)
--- Usage:
--- /cast "Frost Trap"<br>
--- /script Quiver.FdForTrap("Frost Trap")
---@param trapName string
---@return nil
local FdForTrap = function(trapName)
	local spellIndex = Spell.FindSpellIndex(trapName)
	if spellIndex == nil then
		DEFAULT_CHAT_FRAME:AddMessage("Could not find "..trapName.." in spellbook.")
	else
		local timeStartCd, _ = GetSpellCooldown(spellIndex, BOOKTYPE_SPELL)
		if timeStartCd == 0 and UnitAffectingCombat("player") then
			if UnitExists("pettarget") and UnitAffectingCombat("pet") then
				PetPassiveMode()
			end
			-- TODO implement more locale strings
			local fd = Quiver.L["Feign Death"]
			CastSpellByName("Feign Death")
		end
	end
end

return function()
	Quiver.CastNoClip = CastNoClip
	Quiver.CastPetAction = CastPetAction
	Quiver.FdForTrap = FdForTrap
	Quiver.PredMidShot = AutoShotTimer.PredMidShot
end
