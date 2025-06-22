--- @type BagId[]
local _BAGS = { 0, 1, 2, 3, 4 }

-- TODO use item names instead of textures.
-- ItemLink might be the best way.
-- --- itemLink = GetContainerItemLink(i,j) or ""
-- --- _,_,itemID,itemName = string.find(itemLink, "item:(%d+).+%[(.+)%]")
-- --- if equipSlot=="INVTYPE_TRINKET" then ... end

-- local ta = "Mark of The Champion"
-- local tb = "The Heart of Dreams"
-- local x = UnitCreatureType("target")
-- TrinketSwap2(x == ("Undead") or x == "Demon" and ta or tb)

---@param texName string
---@return nil | integer bagSlot
---@return boolean locked
local findBagSlotByTexture = function(texName)
	for _i, bagId in ipairs(_BAGS) do
		local numSlots = GetContainerNumSlots(bagId)
		for slot=1,numSlots do
			local texture, _, locked = GetContainerItemInfo(bagId, slot)
			if (texture == texName) then return slot, locked end
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("Quiver Trinket Failure: "..texName)
	return nil, false
end

---@param slotName InvSlotName
---@param texName string
---@return nil
local TrinketSwap = function(slotName, texName)
	local trinketSlot = GetInventorySlotInfo(slotName)
	local slot, bagItemLocked = findBagSlotByTexture(texName)

	if (
		slot ~= nil
		and not bagItemLocked
		and not CursorHasItem()
		and not SpellIsTargeting()
		and not IsInventoryItemLocked(trinketSlot)
	) then
		if UnitAffectingCombat("player") then
			if UnitExists("pettarget") and UnitAffectingCombat("pet") then
				PetPassiveMode()
				PetFollow()
			end
			CastSpellByName("Feign Death")
		end
		PickupContainerItem(0, slot)
		PickupInventoryItem(trinketSlot)
	end
end

return TrinketSwap
