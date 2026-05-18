--!strict

local types = require("../types")
local element = require("./element")


local bool_element = setmetatable({}, element)
bool_element.__index = bool_element
bool_element.node_type = "bool"

local inst = setmetatable(element.new(), bool_element)

function bool_element:generate_node(parser: types.parser)
	local lit = parser:consume()
	return { type = "bool", value = lit.value == "true", line = lit.line, column = lit.column }
end

function bool_element:output(transpiler: types.transpiler, node: types.node)
	local n = node :: types.bool_node
	return tostring(n.value)
end

function bool_element:type_check(checker: types.type_checker, node: types.node)
	local n = node :: types.bool_node
	return { kind = "literal", value = n.value }
end

return inst
