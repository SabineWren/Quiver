local println = Quiver_Lib_Print_Factory("Range Indicator")
local frame = nil
local fontString = nil

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	if Quiver_Store.IsLockedFrames then f:Hide() end

	Quiver_UI_FrameMeta_Customize(f, Quiver_Store.FrameMeta.RangeIndicator, 135, 35)

	f:SetFrameStrata("LOW")
	f:SetBackdrop({
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 16,
		insets = { left=4, right=4, top=4, bottom=4 },
	})
	f:SetBackdropColor(0, 0, 0, 0.6)
	f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

	local fs = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	fs:SetAllPoints(f)
	fs:SetJustifyH("Center")
	fs:SetJustifyV("Center")
	fs:SetText("Range Indicator")
	fs:SetTextColor(1, 1, 1)

	return f, fs
end

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
	fontString:SetText(text)
	local r, g, b, a = unpack(colour)
	frame:SetBackdropColor(r, g, b, a)
	frame:SetBackdropBorderColor(r, g, b, a)
	frame.GripHandle:GetNormalTexture():SetVertexColor(r, g, b)
	frame.GripHandle:GetHighlightTexture():SetVertexColor(r, g, b)
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
	if UnitExists("target")
		and (not UnitIsDead("target"))
		and UnitCanAttack("player", "target")
	then
		frame:Show()
	elseif Quiver_Store.IsLockedFrames
		then frame:Hide()
	end
end

-- ************ Initialization ************
local events = { "PLAYER_TARGET_CHANGED", "UNIT_FACTION" }
local onEnable = function()
	if frame == nil then frame, fontString = createUI() end
	-- These print warnings if they fail on first call
	-- It's better to discover that during init than during combat
	_ = checkActionBarDistance(QUIVER_T.Spellbook.Auto_Shot)
	_ = checkActionBarDistance(QUIVER_T.Spellbook.Hunters_Mark)
	_ = checkActionBarDistance(QUIVER_T.Spellbook.Scatter_Shot)
	_ = checkActionBarDistance(QUIVER_T.Spellbook.Wing_Clip)

	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _k, e in events do frame:RegisterEvent(e) end
	if not Quiver_Store.IsLockedFrames then frame:Show() end
end

local onDisable = function()
	frame:Hide()
	for _k, e in events do frame:UnregisterEvent(e) end
end

Quiver_Module_RangeIndicator = {
	Name = "RangeIndicator",
	OnRestoreSavedVariables = function(store) return nil end,
	OnPersistSavedVariables = function() return {} end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() handleEvent() end,
	OnInterfaceUnlock = function() frame:Show() end,
}
