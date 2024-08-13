---@meta

---@class Leaf
---@field Tag "Leaf"
---@field Content Region
---@field Grow boolean

---@class Flexbox
---@field Tag "Flexbox"
---@field Direction "H"|"V"
---@field Children Tree[]

--[[
---@class Wrapper
---@field Tag "Wrapper"
---@field Border? { L?: number, R?: number, T?: number, B?: number }
---@field Padding? { L?: number, R?: number, T?: number, B?: number }
---@field Tree Flexbox|Leaf
]]

---@alias Tree Flexbox|Leaf
