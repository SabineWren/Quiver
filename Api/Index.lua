local Action = require "Api/Action.lua"
local Aero = require "Api/Aero.lua"
local Aura = require "Api/Aura.lua"
local Enum = require "Api/Enum.lua"
local Pet = require "Api/Pet.lua"
local Spell = require "Api/Spell.lua"
local Tooltip = require "Api/Tooltip.lua"

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
	--- @type fun(r: Region): number
	_Height = function(r) return r:GetHeight() end,

	--- @type fun(r: Region): number
	_Width = function(r) return r:GetWidth() end,

	-- ************ Button ************
	--- @type fun(r: Button): FontString
	_FontString = function(r) return r:GetFontString() end,
}
