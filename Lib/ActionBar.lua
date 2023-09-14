--[[
DO NOT PRELOAD CACHE
Occasionally the cache populates incorrectly at login.
I suspect this might be from Quiver initializing before an action bar addon.
We don't need the cache for performance, but it's useful for printing spell discovery. ]]
local actionBarSlotCache = {}
local requiredSpells = {}

local tryFindSlot = function(texture)
	if texture == nil then return nil end
	for n=0,300 do
		if HasAction(n) then
			-- Raw abilities return a nil action name. Macros, items, etc. don't.
			if GetActionText(n) == nil and GetActionTexture(n) == texture then return n end
		end
	end
	return nil
end

Quiver_Lib_ActionBar_FindSlot = function(callerName)
	local println = Quiver_Lib_Print_Factory(callerName)
	return function(nameSeek)
		if actionBarSlotCache[nameSeek] ~= nil then return actionBarSlotCache[nameSeek] end

		local texture = Quiver_Lib_Spellbook_TryFindTexture(nameSeek)
		table.insert(requiredSpells, nameSeek)
		if texture == nil then
			println.Warning("Can't find in spellbook: "..nameSeek)
			actionBarSlotCache[nameSeek] = 0
			return 0
		end

		local slot = tryFindSlot(texture)
		if slot == nil then
			println.Warning("Can't find on action bars: "..nameSeek)
			println.Warning("Searched for texture: "..texture)
			actionBarSlotCache[nameSeek] = 0
			return 0
		end

		actionBarSlotCache[nameSeek] = slot
		return slot
	end
end

local getIsRequiredSpell = function(spellName)
	for _k, requiredName in requiredSpells do
		if spellName == requiredName then return true end
	end
	return false
end

Quiver_Lib_ActionBar_ValidateCache = function(_slotChanged)
	for spellName, slotOld in actionBarSlotCache do
		local texture = Quiver_Lib_Spellbook_TryFindTexture(spellName)
		local slotNew = tryFindSlot(texture) or 0
		actionBarSlotCache[spellName] = slotNew
		--[[
		Auto Shot changes icon when swapping weapon, and other addons
		can change action bars. This leads to unexpected spam, so we
		disable debug messages when not in config mode. ]]
		local isPrintDebug = not Quiver_Store.IsLockedFrames
			and slotOld ~= slotNew
			and getIsRequiredSpell(spellName)
		if isPrintDebug then
			if slotNew > 0 then
				Quiver_Lib_Print.Success("Discovered " .. spellName .. " in slot " .. tostring(slotNew))
			else
				Quiver_Lib_Print.Warning("Lost " .. spellName .. " from slot " .. tostring(slotOld))
			end
		end
	end
end
