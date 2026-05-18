--!nonstrict

local types = require("../types")
local element = require("./element")

local num_element = setmetatable({}, element)
num_element.__index = num_element
num_element.node_type = "num"

local inst = setmetatable(element.new(), num_element)

function num_element:generate_node(parser: types.parser)
	local lit = parser:consume()
	return { type = "num", value = tonumber(lit.value) :: number, line = lit.line, column = lit.column }
end

function num_element:output(transpiler: types.transpiler, node: types.num_node)
	return tostring(node.value)
end

function num_element:type_check(checker: types.type_checker, node: types.num_node)
	return { kind = "literal", value = node.value }
end

return inst
