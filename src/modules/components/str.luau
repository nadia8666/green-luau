--!nonstrict

local types = require("../types")
local element = require("./element")

local str_element = setmetatable({}, element)
str_element.__index = str_element
str_element.node_type = "str"

local inst = setmetatable(element.new(), str_element)

function str_element:generate_node(parser: types.parser)
	local lit = parser:consume()
	return { type = "str", value = lit.value, quote = lit.quote, line = lit.line, column = lit.column }
end

function str_element:output(transpiler: types.transpiler, node: types.str_node)
	local q = node.quote or '"'
	return `{q}{node.value}{q}`
end

function str_element:type_check(checker: types.type_checker, node: types.str_node)
	return { kind = "literal", value = node.value }
end

return inst
