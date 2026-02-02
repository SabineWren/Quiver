---@alias BorderStyle "Simple" | "Tooltip"

---@type (fun(x: BorderStyle): nil)[]
local callbacks = {}

---@param moduleId string
---@param callback fun(x: BorderStyle): nil
---@return nil
local Subscribe = function(moduleId, callback)
	callbacks[moduleId] = callback
end

---@param moduleId string
local Dispose = function(moduleId)
	callbacks[moduleId] = nil
end

return {
	Dispose = Dispose,
	Subscribe = Subscribe,

	---@param style BorderStyle
	---@return nil
	ChangeAndPublish = function(style)
		Quiver_Store.Border_Style = style
		for _i, v in ipairs(callbacks) do
			v(style)
		end
	end,

	GetColor = function() return 0.6, 0.7, 0.7, 1.0 end,

	---@return integer
	---@nodiscard
	GetInsetSize = function()
		return Quiver_Store.Border_Style == "Tooltip" and 3 or 1
	end,

	-- TODO Ideally, subscribing would return a provider instance that can access state.
	-- However, that's going to require considerable re-architecting to support with type safety.
	---@return BorderStyle
	---@nodiscard
	GetStyle = function() return Quiver_Store.Border_Style end,
}
