local Region = {
	--- @type fun(r: Region): number
	_GetHeight = function(r) return r:GetHeight() end,

	--- @type fun(r: Region): number
	_GetWidth = function(r) return r:GetWidth() end,
}

return {
	Region = Region,
}
