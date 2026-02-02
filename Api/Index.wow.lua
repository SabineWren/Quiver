local Action = require "Api/Action.wow.lua"
local Aero = require "Api/Aero.wow.lua"
local Aura = require "Api/Aura.wow.lua"
local Enum = require "Api/Enum.wow.lua"
local Pet = require "Api/Pet.wow.lua"
local Spell = require "Api/Spell.wow.lua"
local Tooltip = require "Api/Tooltip.wow.lua"

-- Elm and FSharp use underscore syntax for sugaring property getters.
return {
	Action = Action,
	Aero = Aero,
	Aura = Aura,
	Enum = Enum,
	Pet = Pet,
	Spell = Spell,
	Tooltip = Tooltip,

	-- ************ Region ************
	_Height = WorldFrame.GetHeight,
	_Width = WorldFrame.GetWidth,

	-- ************ Button ************
	--- @type fun(r: Button): FontString
	_FontString = function(r) return r:GetFontString() end,
}
