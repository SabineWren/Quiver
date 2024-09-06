local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local Pet = require "Shiver/API/Pet.lua"

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

return function()
	Quiver.CastNoClip = CastNoClip
	Quiver.CastPetAction = CastPetAction
	Quiver.PredMidShot = AutoShotTimer.PredMidShot
end
