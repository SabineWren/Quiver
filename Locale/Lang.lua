local enUS_L = require "Locale/enUS.client.lua"
local enUS_T = require "Locale/enUS.translations.lua"
local zhCN_L = require "Locale/zhCN.client.lua"
local zhCN_T = require "Locale/zhCN.translations.lua"

local currentLang = GetLocale()
DEFAULT_CHAT_FRAME:AddMessage("Quiver: "..currentLang)

local translation = {
	["enUS"] = enUS_T,
	["zhCN"] = zhCN_T,
}

return function()
	Quiver = Quiver or {}
	Quiver.T = translation[currentLang] or translation["enUS"]
end
