local println = Quiver_Lib_Print_Factory("Range Indicator")

local checkActionBarDistance = function(spellName)
	local slot = Quiver_Lib_ActionBar_FindSlot(println, spellName)
	return IsActionInRange(slot) == 1
end
local checkDistance = {
	-- High Performance Builtin
	-- https://wowwiki-archive.fandom.com/wiki/API_CheckInteractDistance
	Inspect=function() return CheckInteractDistance("target", 1) end,-- 28 yards
	Trade=function() return CheckInteractDistance("target", 2) end,-- 11.11 yards
	Duel=function() return CheckInteractDistance("target", 3) end,-- 9.9 yards
	Follow=function() return CheckInteractDistance("target", 4) end,-- 28 yards
	-- Using Action Bars
	Melee=function() return checkActionBarDistance(QUIVER_T.Spellbook.Wing_Clip) end,-- 5 yards
	Mark=function() return checkActionBarDistance(QUIVER_T.Spellbook.Hunters_Mark) end,-- 100 yards
	Ranged=function() return checkActionBarDistance(QUIVER_T.Spellbook.Auto_Shot) end,-- 30-36 yards (talents)
	Scatter=function() return checkActionBarDistance(QUIVER_T.Spellbook.Scatter_Shot) end,-- 15 yards
}

local render = function(colour, text)
	RangeIndicator_FontString:SetText(text)
	local r, g, b, a = unpack(colour)
	Quiver_Module_RangeIndicator_Frame:SetBackdropColor(r, g, b, a)
	Quiver_Module_RangeIndicator_Frame:SetBackdropBorderColor(r, g, b, a)
end
local showRange = {
	Melee=function() render({0, 1, 0, 0.7}, "Melee Range") end,
	Deadzone=function() render({1, 0.5, 0, 0.7}, "Dead Zone") end,
	Scatter=function() render({0, 1, 0.8, 0.7}, "Scatter Range") end,
	Short=function() render({0, 0.8, 0.8, 0.7}, "Short Range") end,
	Long=function() render({0, 0.8, 0.8, 0.7}, "Long Range") end,
	Mark=function() render({1, 0.2, 0, 0.7}, "Mark Range") end,
	TooFar=function() render({1, 0, 0, 0.7}, "Out of Range") end,
}

-- ************ Event Handlers ************
local handleUpdate = function()
	if checkDistance.Melee() then showRange.Melee()
	elseif checkDistance.Ranged() then
		if checkDistance.Scatter() then showRange.Scatter()
		elseif checkDistance.Follow() then showRange.Short()
		else showRange.Long()
		end
	elseif checkDistance.Follow() then showRange.Deadzone()
	elseif checkDistance.Mark() then showRange.Mark()
	else showRange.TooFar()
	end
end

local handleEvent = function()
	local isShow = UnitExists("target")
		and (not UnitIsDead("target"))
		and UnitCanAttack("player", "target")
	if isShow
	then Quiver_Module_RangeIndicator_Frame:Show()
	else Quiver_Module_RangeIndicator_Frame:Hide()
	end
end

-- ************ Initialization ************
local events = { "PLAYER_TARGET_CHANGED", "UNIT_FACTION" }
local frame = nil
Quiver_Module_RangeIndicator_Enable = function()
	frame = Quiver_Module_RangeIndicator_Frame
	-- These print warnings if they fail on first call
	-- It's better to discover that during init than during combat
	_ = checkActionBarDistance(QUIVER_T.Spellbook.Auto_Shot)
	_ = checkActionBarDistance(QUIVER_T.Spellbook.Hunters_Mark)
	_ = checkActionBarDistance(QUIVER_T.Spellbook.Scatter_Shot)
	_ = checkActionBarDistance(QUIVER_T.Spellbook.Wing_Clip)

	RangeIndicator_FontString:SetTextColor(1, 1, 1)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() frame:StartMoving() end)
	frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in events do frame:RegisterEvent(e) end
end

Quiver_Module_RangeIndicator_Disable = function()
	frame:Hide()
	for _k, e in events do frame:UnregisterEvent(e) end
end
