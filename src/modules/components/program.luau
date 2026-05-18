--!nonstrict

local types = require("../types")
local element = require("./element")

local program_element = setmetatable({}, element)
program_element.__index = program_element
program_element.node_type = "program"

local inst = setmetatable(element.new(), program_element)

function program_element:output(transpiler: types.transpiler, node: types.program_node)
	local lines = {}
	for _, statement in node.body do
		table.insert(lines, transpiler:build_node(statement))
	end
	return table.concat(lines, "\n")
end

return inst
