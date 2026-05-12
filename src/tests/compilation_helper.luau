local compilation_helper = {}
local main = require("../main")

function compilation_helper.new(code: string)
	local success, output = main.transpile(code)

	if success then
		return output
	end

	error(output)
end

return compilation_helper
