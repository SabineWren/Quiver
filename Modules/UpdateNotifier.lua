local Version = require "Util/Version.lua"

-- This file based on pfUI's updatenotify.lua
-- Copyright (c) 2016-2021 Eric Mauser (Shagu)
-- Copyright (c) 2022 SabineWren
local hasNotified = false
local CURRENT = Version:ParseThrows(GetAddOnMetadata("Quiver", "Version"))

local broadcast = (function()
	local channelsLogin = { "BATTLEGROUND", "RAID", "GUILD" }
	local channelsPlayerGroup = { "BATTLEGROUND", "RAID" }
	local send = function(channels)
		for _i, v in ipairs(channels) do
			SendAddonMessage("Quiver", "VERSION:"..CURRENT.Text, v)
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

--- @type Event[]
local _EVENTS = {
	"CHAT_MSG_ADDON",
	"PARTY_MEMBERS_CHANGED",
	"PLAYER_ENTERING_WORLD",
}
local handleEvent = function()
	if event == "CHAT_MSG_ADDON" and arg1 == "Quiver" then
		local _, _, versionText = string.find(arg2, "VERSION:(.*)")
		if versionText ~= nil
			and CURRENT:PredNewer(versionText)
			and not hasNotified
		then
			local URL = "https://github.com/SabineWren/Quiver"
			local m1 = Quiver.T["New version %s available at %s"]
			local m2 = Quiver.T["It's always safe to upgrade Quiver. You won't lose any of your configuration."]
			local text = string.format(m1, versionText, URL)
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Quiver|r - "..text)
			DEFAULT_CHAT_FRAME:AddMessage("|cffdddddd"..m2)
			hasNotified = true
		end
	elseif event == "PARTY_MEMBERS_CHANGED" then
		if checkGroupGrew() then broadcast.Group() end
	elseif event == "PLAYER_ENTERING_WORLD" then
		broadcast.Login()
	end
end

-- ************ Initialization ************
return function()
	local frame = CreateFrame("Frame", nil)
	frame:SetScript("OnEvent", handleEvent)
	-- We don't need to unsubscribe, as we never disable the update notifier
	for _i, v in ipairs(_EVENTS) do frame:RegisterEvent(v) end
end
