--!nonstrict

local types = require("../types")
local element = require("./element")

local unary_element = setmetatable({}, element)
unary_element.__index = unary_element
unary_element.node_type = "unary"

local inst = setmetatable(element.new(), unary_element)

function unary_element:generate_node(parser: types.parser)
	local start_token = parser:peek()
	if start_token.value == "-" or start_token.value == "!" or start_token.value == "not" then
		local operator = parser:consume().value
		return {
			type = "unary",
			operator = operator,
			argument = parser:parse_unary_expression(),
			line = start_token.line,
			column = start_token.column,
		}
	end
	return parser:parse_primary()
end

function unary_element:output(transpiler: types.transpiler, node: types.unary_node)
	local op = (node.operator == "!" or node.operator == "not") and "not " or node.operator
	return `{op}{transpiler:build_node(node.argument)}`
end

function unary_element:type_check(checker: types.type_checker, node: types.unary_node)
	local arg_type = checker:check_node(node.argument)
	if node.operator == "-" then
		if arg_type and not checker.type_system:check_assignable(arg_type, { kind = "builtin", name = "number" }) then
			checker:add_diagnostic("error", "expected number", node.line, node.column)
		end
		return { kind = "builtin", name = "number" }
	elseif node.operator == "!" or node.operator == "not" then
		return { kind = "builtin", name = "boolean" }
	end
	return { kind = "builtin", name = "any" }
end

return inst
