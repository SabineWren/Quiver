local Api = require "Api/Index.lua"
local Const = require "Constants.lua"
local FrameLock = require "Events/FrameLock.lua"

local MODULE_ID = "RangeIndicator"
local store = nil
local frame = nil
local fontString = nil

local setFramePosition = function(f, s)
	FrameLock.SideEffectRestoreSize(s, {
		w=190, h=35, dx=190 * -0.5, dy=-183,
	})
	f:SetWidth(s.FrameMeta.W)
	f:SetHeight(s.FrameMeta.H)
	f:SetPoint("TopLeft", s.FrameMeta.X, s.FrameMeta.Y)
end

local createUI = function()
	local f = CreateFrame("Frame", nil, UIParent)
	setFramePosition(f, store)
	FrameLock.SideEffectMakeMoveable(f, store)
	FrameLock.SideEffectMakeResizeable(f, store, { GripMargin=4 })

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
	fs:SetJustifyV("Middle")
	fs:SetText("Range Indicator")
	fs:SetTextColor(1, 1, 1)

	return f, fs
end

---@param name string
---@return boolean
---@nodiscard
local predSpellInRange = function(name)
	local slot = Api.Action.FindBySpellName(name)
	if slot == nil then
		return false
	else
		return IsActionInRange(slot) == 1
	end
end

local checkDistance = {
	-- https://wowwiki-archive.fandom.com/wiki/API_CheckInteractDistance
	Inspect=function() return CheckInteractDistance("target", 1) end,-- 11.11 yards
	Trade=function() return CheckInteractDistance("target", 2) end,-- 11.11 yards
	Duel=function() return CheckInteractDistance("target", 3) end,-- 9.9 yards (or 10?)
	Follow=function() return CheckInteractDistance("target", 4) end,-- 28 yards
	-- Using Action Bars
	Melee=function() return predSpellInRange(Quiver.L.Spell["Wing Clip"]) end,-- 5 yards
	Mark=function() return predSpellInRange(Quiver.L.Spell["Hunter's Mark"]) end,-- 100 yards
	Ranged=function() return predSpellInRange(Quiver.L.Spell["Auto Shot"]) end,-- 35-41 yards (talents)
	Scare=function() return predSpellInRange(Quiver.L.Spell["Scare Beast"]) end,-- 10 yards
	Scatter=function() return predSpellInRange(Quiver.L.Spell["Scatter Shot"]) end,-- 15-21 yards (talents)
}

local render = function(color, text)
	fontString:SetText(text)
	local r, g, b, a = unpack(color)
	frame:SetBackdropColor(r, g, b, a)
	frame:SetBackdropBorderColor(r, g, b, a)
	-- if not Quiver_Store.IsLockedFrames then
	-- 	TODO do we care about grip handle color here?
	-- 	frame.QuiverGripHandle:GetNormalTexture():SetVertexColor(r, g, b)
	-- 	frame.QuiverGripHandle:GetHighlightTexture():SetVertexColor(r+0.3, g-0.1, b+0.3)
	-- end
end

-- ************ Event Handlers ************
local handleUpdate = function()
	if checkDistance.Melee() then
		render(store.ColorMelee, Quiver.T["Melee Range"])
	elseif checkDistance.Ranged() then
		if UnitCreatureType("target") == "Beast" and checkDistance.Scare() then
			render(store.ColorScareBeast, Quiver.T["Scare Beast"])
		elseif checkDistance.Scatter() then
			render(store.ColorScatterShot, Quiver.T["Scatter Shot"])
		elseif checkDistance.Follow() then
			render(store.ColorShort, Quiver.T["Short Range"])
		else
			render(store.ColorLong, Quiver.T["Long Range"])
		end
	elseif checkDistance.Follow() then
		render(store.ColorDeadZone, Quiver.T["Dead Zone"])
	elseif checkDistance.Mark() then
		render(store.ColorMark, Quiver.T["Hunter's Mark"])
	else
		render(store.ColorTooFar, Quiver.T["Out of Range"])
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
--- @type Event[]
local _EVENTS = {
	"PLAYER_TARGET_CHANGED",
	"UNIT_FACTION",
}
local onEnable = function()
	if frame == nil then frame, fontString = createUI() end
	frame:SetScript("OnEvent", handleEvent)
	frame:SetScript("OnUpdate", handleUpdate)
	for _i, v in ipairs(_EVENTS) do frame:RegisterEvent(v) end
	if Quiver_Store.IsLockedFrames then handleEvent() else frame:Show() end
end

local onDisable = function()
	frame:Hide()
	for _i, v in ipairs(_EVENTS) do frame:UnregisterEvent(v) end
end

---@type QqModule
return {
	Id = MODULE_ID,
	GetName = function() return Quiver.T["Range Indicator"] end,
	GetTooltipText = function() return Quiver.T["Shows when abilities are in range. Requires spellbook abilities placed somewhere on your action bars."] end,
	OnEnable = onEnable,
	OnDisable = onDisable,
	OnInterfaceLock = function() handleEvent() end,
	OnInterfaceUnlock = function() frame:Show() end,
	OnResetFrames = function()
		store.FrameMeta = nil
		if frame then setFramePosition(frame, store) end
	end,
	OnSavedVariablesRestore = function(savedVariables)
		store = savedVariables
		store.ColorMelee = store.ColorMelee or Const.ColorDefault.Range.Melee
		store.ColorDeadZone = store.ColorDeadZone or Const.ColorDefault.Range.DeadZone
		store.ColorScareBeast = store.ColorScareBeast or Const.ColorDefault.Range.ScareBeast
		store.ColorScatterShot = store.ColorScatterShot or Const.ColorDefault.Range.ScatterShot
		store.ColorShort = store.ColorShort or Const.ColorDefault.Range.Short
		store.ColorLong = store.ColorLong or Const.ColorDefault.Range.Long
		store.ColorMark = store.ColorMark or Const.ColorDefault.Range.Mark
		store.ColorTooFar = store.ColorTooFar or Const.ColorDefault.Range.TooFar
	end,
	OnSavedVariablesPersist = function() return store end,
}
