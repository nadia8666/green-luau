local compilation_helper = {}
local util = require("../components/util")
local main = require("../main")

function compilation_helper.new(code: string)
	local success, output, stage = main.run_full(code)

	if success then
		return output
	end

	error(`failed to build during stage {stage}!\n{typeof(output) == "table" and util.format_table(output, 0) or output}`)
end

return compilation_helper
