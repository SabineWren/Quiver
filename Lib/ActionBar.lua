local cacheTexture = {}
local tryFindTexture = function(nameSeek)
	if cacheTexture[nameSeek] ~= nil then
		return cacheTexture[nameSeek]
	end

	local i = 0
	while true do
		i = i + 1
		local name, _rank = GetSpellName(i, BOOKTYPE_SPELL)
		local texture = GetSpellTexture(i, BOOKTYPE_SPELL)
		if not name then return nil end
		if name == nameSeek then
			cacheTexture[nameSeek] = texture
			return texture
		end
	end
end

local tryFindSlot = function(texture)
	for n=0,300 do
		if HasAction(n) then
			-- Ignore macros, items, etc. that might use the same texture
			-- Raw abilities always return a nil action name
			if GetActionText(n) == nil and GetActionTexture(n) == texture then return n end
		end
	end
	return nil
end

local cacheSlot = {}
Quiver_Lib_ActionBar_FindSlot = function(println, nameSeek)
	if cacheSlot[nameSeek] ~= nil then return cacheSlot[nameSeek] end

	local texture = tryFindTexture(nameSeek)
	if texture == nil then
		println.Warning("Can't find in spellbook: "..nameSeek)
		cacheSlot[nameSeek] = 0
		return 0
	end

	local slot = tryFindSlot(texture)
	if slot == nil then
		println.Warning("Can't find on action bars: "..nameSeek)
		println.Warning("Searched for texture: "..texture)
		cacheSlot[nameSeek] = 0
		return 0
	end

	cacheSlot[nameSeek] = slot
	return slot
end

Quiver_Lib_ActionBar_ValidateCache = function(_slotChanged)
	for name, texture in pairs(cacheTexture) do
		local slotNew = tryFindSlot(texture) or 0
		local slotOld = cacheSlot[name]
		if slotNew ~= slotOld then
			if slotNew > 0 then
				Quiver_Lib_Print.Success("Discovered " .. name .. " in slot " .. tostring(slotNew))
			else
				Quiver_Lib_Print.Warning("Lost " .. name .. " from slot " .. tostring(slotOld))
			end
			cacheSlot[name] = slotNew
		end
	end
end

-- Copied from HSK. Not sure how safe or performant this is
local getSpellIndexByName = function(spellName)
	local _schoolName, _schoolIcon, indexOffset, numEntries = GetSpellTabInfo(GetNumSpellTabs())
	local numSpells = indexOffset + numEntries
	local offset = 0
	for spellIndex=numSpells, offset+1, -1 do
		if GetSpellName(spellIndex, "BOOKTYPE_SPELL") == spellName then
			return spellIndex;
		end
	end
	return nil
end
Quiver_Lib_ActionBar_CheckGCD = function()
	local spellId = getSpellIndexByName(QUIVER_T.Spellbook.Serpent_Sting)
	if spellId then
		local cooldownStartTime, spellCD, _enabled = GetSpellCooldown(spellId, "BOOKTYPE_SPELL")
		return cooldownStartTime, spellCD
	end
end
