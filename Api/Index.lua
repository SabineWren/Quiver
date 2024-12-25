local Action = require "Api/Action.lua"
local Aero = require "Api/Aero.lua"
local Aura = require "Api/Aura.lua"
local Enum = require "Api/Enum.lua"
local Pet = require "Api/Pet.lua"
local Region = require "Api/Region.lua"
local Spell = require "Api/Spell.lua"
local Tooltip = require "Api/Tooltip.lua"

-- ************ Region ************
--- @type fun(r: Region): number
local _Height = function(r) return r:GetHeight() end

--- @type fun(r: Region): number
local _Width = function(r) return r:GetWidth() end

-- ************ Button ************
--- @type fun(r: Button): FontString
local _FontString = function(r) return r:GetFontString() end

return {
	Action = Action,
	Aero = Aero,
	Aura = Aura,
	Enum = Enum,
	Pet = Pet,
	Region = Region,
	Spell = Spell,
	Tooltip = Tooltip,
	-- Elm and FSharp use underscore syntax for sugaring property getters.
	_FontString = _FontString,
	_Height = _Height,
	_Width = _Width,
}
