local enUS_L = require "Locale/enUS.client.lua"
local enUS_T = require "Locale/enUS.translations.lua"
local zhCN_L = require "Locale/zhCN.client.lua"
local zhCN_T = require "Locale/zhCN.translations.lua"

local currentLang = GetLocale()
DEFAULT_CHAT_FRAME:AddMessage(currentLang)

-- This file explores the translation architecture used by pfUI.
-- The only major issue so far is lack of type safety in translation lookups.
-- ex.
-- Quiver.T["valid key"] -- infers nil, no error
-- Quiver.T["not a key anywhere"] -- infers nil, no error
--
-- If a locale doesn't have a value (or the value is nil), we set it equal to the key. We only
-- need to return the key, so I suspect updating the table is a caching optimization by Shagu.
local fallbackToKey = function(tab, key)
	local value = key
	rawset(tab, key, value)
	return value
end
local withFallback = function(t)
	return setmetatable(t, { __index = fallbackToKey })
end
local translation = {
	["enUS"] = withFallback(enUS_T),
	["zhCN"] = withFallback(zhCN_T),
}

return function()
	Quiver = Quiver or {}
	Quiver.T = translation[currentLang] or translation["enUS"]
end
