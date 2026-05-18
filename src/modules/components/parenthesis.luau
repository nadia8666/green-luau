--!strict

local types = require("../types")
local element = require("./element")

local paren_element = setmetatable({}, element)
paren_element.__index = paren_element
paren_element.node_type = "parenthesis"

local inst = setmetatable(element.new(), paren_element)

function paren_element:generate_node(parser: types.parser)
	local token = parser:peek()
	parser:consume("(")
	local expr = parser:parse_expression()
	parser:consume(")")
	return {
		type = "parenthesis",
		expression = expr,
		line = token.line,
		column = token.column,
	}
end

function paren_element:output(transpiler: types.transpiler, node: types.parenthesis_node)
	return `({transpiler:build_node(node.expression)})`
end

function paren_element:type_check(checker: types.type_checker, node: types.parenthesis_node)
	return checker:check_node(node.expression)
end

return inst
