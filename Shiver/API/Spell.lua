---@param spellName string
---@return nil|integer spellIndex
local FindSpellIndex = function(spellName)
	local numTabs = GetNumSpellTabs()
	local _, _, tabOffset, numEntries = GetSpellTabInfo(numTabs)
	local numSpells = tabOffset + numEntries
	for spellIndex=1, numSpells do
		local name, _rank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
		if name == spellName then
			return spellIndex
		end
	end
	return nil
end

--- This assumes the texture uniquely identifies a spell, which may not be true.
---@param texturePath string
---@return nil|string spellName
---@return nil|integer spellIndex
---@nodiscard
local FindSpellByTexture = function(texturePath)
	local i = 0
	while true do
		i = i + 1
		local t = GetSpellTexture(i, BOOKTYPE_SPELL)
		local name, _rank = GetSpellName(i, BOOKTYPE_SPELL)
		if not t or not name then
			break-- Base Case
		elseif t == texturePath then
			return name, i
		end
	end
	return nil, nil
end

return {
	FindSpellByTexture = FindSpellByTexture,
	FindSpellIndex = FindSpellIndex,
}
