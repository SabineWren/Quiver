local LoadLocale = require "Locale/Lang.lua"
local MainMenu = require "Config/MainMenu.lua"
local Migrations = require "Migrations/Runner.lua"
local AspectTracker = require "Modules/Aspect_Tracker/AspectTracker.lua"
local AutoShotTimer = require "Modules/Auto_Shot_Timer/AutoShotTimer.lua"
local Castbar = require "Modules/Castbar.lua"
local RangeIndicator = require "Modules/RangeIndicator.lua"
local TranqAnnouncer = require "Modules/TranqAnnouncer.lua"
local TrueshotAuraAlarm = require "Modules/TrueshotAuraAlarm.lua"
local UpdateNotifierInit = require "Modules/UpdateNotifier.lua"
local RegisterApiFunctions = require "Api.lua"

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
	for _k, v in _G.Quiver_Modules do
		Quiver_Store.ModuleEnabled[v.Id] = Quiver_Store.ModuleEnabled[v.Id] ~= false
		Quiver_Store.ModuleStore[v.Id] = Quiver_Store.ModuleStore[v.Id] or {}
		-- Loading saved variables into each module gives them a chance to set their own defaults.
		v.OnSavedVariablesRestore(Quiver_Store.ModuleStore[v.Id])
	end
end
local savedVariablesPersist = function()
	for _k, v in _G.Quiver_Modules do
		Quiver_Store.ModuleStore[v.Id] = v.OnSavedVariablesPersist()
	end
end

local initSlashCommandsAndModules = function()
	SLASH_QUIVER1 = "/qq"
	SLASH_QUIVER2 = "/quiver"
	local _, cl = UnitClass("player")
	if cl == "HUNTER" then
		local frameConfigMenu = MainMenu.Create()
		SlashCmdList["QUIVER"] = function(_args, _box) frameConfigMenu:Show() end
		for _k, v in _G.Quiver_Modules do
			if Quiver_Store.ModuleEnabled[v.Id] then v.OnEnable() end
		end
	else
		SlashCmdList["QUIVER"] = function() DEFAULT_CHAT_FRAME:AddMessage(Quiver.T["Quiver is for hunters."], 1, 0.5, 0) end
	end
end

--[[
// TODO revisit this now that we don't load any pfUI plugins
https://wowpedia.fandom.com/wiki/AddOn_loading_process
All of these events fire on login and UI reload. We don't need to clutter chat
until the user interacts with Quiver, and we don't pre-cache action bars. That
means it's okay to load before other addons (action bars, chat windows).
pfUI loads before we register plugins for it. Quiver comes alphabetically later,
but it's safer to use a later event in case names change.

ADDON_LOADED Fires each time any addon loads, but can't yet print to pfUI's chat menu
PLAYER_LOGIN Fires once, but can't yet read talent tree
PLAYER_ENTERING_WORLD fires on every load screen
SPELLS_CHANGED fires every time the spellbook changes
]]
local frame = CreateFrame("Frame", nil)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" and arg1 == "Quiver" then
		-- TODO set preferred language in saved variables to use here
		LoadLocale()-- Must run before everything else
		Migrations()-- Modifies saved variables
		savedVariablesRestore()-- Passes saved data to modules for init
		initSlashCommandsAndModules()
		RegisterApiFunctions()
	elseif event == "PLAYER_LOGIN" then
		UpdateNotifierInit()
	elseif event == "PLAYER_LOGOUT" then
		savedVariablesPersist()
	end
end)
