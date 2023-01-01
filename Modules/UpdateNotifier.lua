-- This file based on pfUI's updatenotify.lua
-- Copyright (c) 2016-2021 Eric Mauser (Shagu)
-- Copyright (c) 2022 SabineWren
local hasNotified = false
local CURRENT = GetAddOnMetadata("Quiver", "Version")

local broadcast = (function()
	local channelsLogin = { "BATTLEGROUND", "RAID", "GUILD" }
	local channelsPlayerGroup = { "BATTLEGROUND", "RAID" }
	local send = function(channels)
		for _k, chan in channels do
			SendAddonMessage("Quiver", "VERSION:"..CURRENT, chan)
		end
	end
	return {
		Group = function() send(channelsPlayerGroup) end,
		Login = function() send(channelsLogin) end,
	}
end)()

local checkGroupGrew = (function()
	local lastSize = 0
	return function()
		local sizeRaid = GetNumRaidMembers()
		local sizeParty = GetNumPartyMembers()
		local sizeGroup = sizeRaid > 0 and sizeRaid
			or sizeParty > 0 and sizeParty
			or 0
		local isLarger = sizeGroup > lastSize
		lastSize = sizeGroup
		return isLarger
	end
end)()

local EVENTS = {
	"CHAT_MSG_ADDON",
	"PARTY_MEMBERS_CHANGED",
	"PLAYER_ENTERING_WORLD",
}
local handleEvent = function()
	if event == "CHAT_MSG_ADDON" and arg1 == "Quiver" then
		local _, _, version = strfind(arg2, "VERSION:(.*)")
		if version ~= nil
			and Quiver_Lib_Version_GetIsNewer(CURRENT, version)
			and not hasNotified
		then
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Quiver|r - New version " .. version .. " available at https://github.com/SabineWren/Quiver")
			DEFAULT_CHAT_FRAME:AddMessage("|cffddddddIt's always safe to upgrade Quiver. |cffddddddYou won't lose any of your configuration.")
			hasNotified = true
		end
	elseif event == "PARTY_MEMBERS_CHANGED" then
		if checkGroupGrew() then broadcast.Group() end
	elseif event == "PLAYER_ENTERING_WORLD" then
		broadcast.Login()
	end
end

-- ************ Initialization ************
Quiver_Module_UpdateNotifier_Init = function()
	local frame = CreateFrame("Frame", nil)
	frame:SetScript("OnEvent", handleEvent)
	-- We don't need to unsubscribe, as we never disable the update notifier
	for _k, e in EVENTS do frame:RegisterEvent(e) end
end
