local compilation_helper = {}
local main = require("../main")

function compilation_helper.new(code: string)
	local success, output, stage = main.run_full(code)

	if success then
		return output
	end

	error(`failed to build during stage {stage}!\n{output}`)
end

return compilation_helper
