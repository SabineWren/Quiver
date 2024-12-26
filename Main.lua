local Api = require "Api/Index.lua"
local MainMenu = require "Config/MainMenu.lua"
local LoadLocale = require "Locale/Lang.lua"
local Migrations = require "Migrations/Runner.lua"
local AspectTracker = require "Modules/Aspect_Tracker/AspectTracker.lua"
local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local Castbar = require "Modules/Castbar.lua"
local RangeIndicator = require "Modules/RangeIndicator.lua"
local TranqAnnouncer = require "Modules/TranqAnnouncer.lua"
local TrueshotAuraAlarm = require "Modules/TrueshotAuraAlarm.lua"
local UpdateNotifierInit = require "Modules/UpdateNotifier.lua"
local RegisterGlobalFunctions = require "GlobalFunctions.lua"

_G = _G or getfenv()
Quiver = Quiver or {}
_G.Quiver_Modules = {
	AspectTracker,
	AutoShotTimer,
	Castbar,
	RangeIndicator,
	TranqAnnouncer,
	TrueshotAuraAlarm,
}

local savedVariablesRestore = function()
	-- If first time running Quiver, then savedVars are nil, so make defaults
	Quiver_Store.IsLockedFrames = Quiver_Store.IsLockedFrames == true
	Quiver_Store.ModuleEnabled = Quiver_Store.ModuleEnabled or {}
	Quiver_Store.ModuleStore = Quiver_Store.ModuleStore or {}
	Quiver_Store.DebugLevel = Quiver_Store.DebugLevel or "None"
	Quiver_Store.Border_Style = Quiver_Store.Border_Style or "Simple"
	for _i, v in ipairs(_G.Quiver_Modules) do
		Quiver_Store.ModuleEnabled[v.Id] = Quiver_Store.ModuleEnabled[v.Id] ~= false
		Quiver_Store.ModuleStore[v.Id] = Quiver_Store.ModuleStore[v.Id] or {}
		-- Loading saved variables into each module gives them a chance to set their own defaults.
		v.OnSavedVariablesRestore(Quiver_Store.ModuleStore[v.Id])
	end
end
local savedVariablesPersist = function()
	for _i, v in ipairs(_G.Quiver_Modules) do
		Quiver_Store.ModuleStore[v.Id] = v.OnSavedVariablesPersist()
	end
end

local initSlashCommandsAndModules = function()
	SLASH_QUIVER1 = "/qq"
	SLASH_QUIVER2 = "/quiver"
	local _, cl = UnitClass("player")
	if cl == "HUNTER" then
		local frameConfigMenu = MainMenu.Create("QuiverConfigDialog")
		Api.Aero.RegisterFrame(frameConfigMenu)

		SlashCmdList["QUIVER"] = function(_args, _box) frameConfigMenu:Show() end
		for _i, v in ipairs(_G.Quiver_Modules) do
			if Quiver_Store.ModuleEnabled[v.Id] then v.OnEnable() end
		end
	else
		SlashCmdList["QUIVER"] = function() DEFAULT_CHAT_FRAME:AddMessage(Quiver.T["Quiver is for hunters."], 1, 0.5, 0) end
	end
end

--[[
-- https://wowpedia.fandom.com/wiki/AddOn_loading_process
-- Addon load alphabetically (affected by color characters)
1 - ADDON_LOADED Fires each time any addon can load variables (arg1 = addon name) (can't yet print to pfUI chat frame)
2 - VARIABLES_LOADED Fires once after variables are available to all addons
3 - PLAYER_LOGIN Fires once, but can't yet read talent tree
]]
local frame = CreateFrame("Frame", nil)
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function()
	if event == "VARIABLES_LOADED" then
		LoadLocale()-- Must run before everything else
		Migrations()-- Modifies saved variables
		savedVariablesRestore()-- Passes saved data to modules for init
		initSlashCommandsAndModules()
		RegisterGlobalFunctions()
	elseif event == "PLAYER_LOGIN" then
		UpdateNotifierInit()
	elseif event == "PLAYER_LOGOUT" then
		savedVariablesPersist()
	end
end)
