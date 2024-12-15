--- @param text string
--- @return nil
local logVerbose = function(text)
	if Quiver_Store.DebugLevel == "Verbose" then
		DEFAULT_CHAT_FRAME:AddMessage(text)
	end
end

return {
	Debug = logVerbose,
	Error = logVerbose,
}
