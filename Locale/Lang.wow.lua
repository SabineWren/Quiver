local enUS_C = require "Locale/enUS/Client.enUS.pure.lua"
local enUS_T = require "Locale/enUS/Translations.enUS.pure.lua"
local zhCN_C = require "Locale/zhCN/Client.zhCN.pure.lua"
local zhCN_T = require "Locale/zhCN/Translations.zhCN.pure.lua"

return function()
	local translation = {
		["enUS"] = enUS_T,
		["zhCN"] = zhCN_T,
	}
	local client = {
		["enUS"] = enUS_C,
		["zhCN"] = zhCN_C,
	}
	local currentLang = GetLocale()
	Quiver.T = translation[currentLang] or translation["enUS"]
	Quiver.L = client[currentLang] or client["enUS"]
end
