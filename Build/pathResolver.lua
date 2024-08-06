-- This plugin allows the language server to track imports.
-- To view print output in vscode: output -> select lua (restart vscode on file change).
print("Loaded path resolver plugin.")

---@param uri string The URI of file
---@param name string Argument of require()
---@return string[]
function ResolveRequire(uri, name)
	local path = uri .. "/" .. name
	print(path)
	return { path }
end
