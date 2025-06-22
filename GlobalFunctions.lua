local Api = require "Api/Index.lua"
local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local TrinketSwap = require "Modules/TrinketSwap.lua"

---@param spellName string
---@return nil
local CastNoClip = function(spellName)
	if not AutoShotTimer.PredMidShot() then
		CastSpellByName(spellName)
	end
end

---@param actionName string
---@return nil
local CastPetActionByName = function(actionName)
	-- local hasSpells = HasPetUI()
	-- local hasUI = HasPetUI()
	if GetPetActionsUsable() then
		Api.Pet.CastActionByName(actionName)
	end
end

---@param spellNameLocalized string
local predOffCd = function(spellNameLocalized)
	local index = Api.Spell.FindSpellIndex(spellNameLocalized)
	if index ~= nil then
		local timeStartCd, _ = GetSpellCooldown(index, BOOKTYPE_SPELL)
		return timeStartCd == 0
	else
		return false
	end
end

-- Casts feign death (if needed) and sets pet passive (if needed).
-- Usage:
-- /cast Frost Trap
-- /script Quiver.FdPrepareTrap()
local FdPrepareTrap = function()
	-- Requires level 16, which makes it the lowest level trap
	local trap = Quiver.L.Spell["Immolation Trap"]
	local fd = Quiver.L.Spell["Feign Death"]
	if UnitAffectingCombat("player") and predOffCd(trap) and predOffCd(fd) then
		if UnitExists("pettarget") and UnitAffectingCombat("pet") then
			PetPassiveMode()
			PetFollow()
		end
		CastSpellByName(fd)
	end
end

return function()
	Quiver.CastNoClip = CastNoClip
	Quiver.CastPetAction = CastPetActionByName
	Quiver.FdPrepareTrap = FdPrepareTrap
	Quiver.GetSecondsRemainingReload = AutoShotTimer.GetSecondsRemainingReload
	Quiver.GetSecondsRemainingShoot = AutoShotTimer.GetSecondsRemainingShoot
	Quiver.PredMidShot = AutoShotTimer.PredMidShot

	-- WIP - starting with macros, should really be a UI like trinketmenu.
	-- Not documented in README.md because you shouldn't expect this to work.
	-- /run Quiver.TrinketSwap1("Interface\\Icons\\INV_Trinket_Naxxramas03")
	-- /run Quiver.TrinketSwap2("Interface\\Icons\\INV_Misc_Token_ArgentDawn2")
	Quiver.TrinketSwap1 = function(texName) TrinketSwap("Trinket0Slot", texName) end
	Quiver.TrinketSwap2 = function(texName) TrinketSwap("Trinket1Slot", texName) end
end
