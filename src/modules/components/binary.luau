--!nonstrict

local types = require("../types")
local element = require("./element")

local binary_element = setmetatable({}, element)
binary_element.__index = binary_element
binary_element.node_type = "binary"

local inst = setmetatable(element.new(), binary_element)

local token_priority = {
	["||"] = 1,
	["or"] = 1,
	["&&"] = 2,
	["and"] = 2,
	["=="] = 3,
	["!="] = 3,
	["<"] = 3,
	[">"] = 3,
	["<="] = 3,
	[">="] = 3,
	["+"] = 4,
	["-"] = 4,
	["*"] = 5,
	["/"] = 5,
	["^"] = 6,
}

function binary_element:generate_node(parser: types.parser, left: types.node, min_prec: number)
	while true do
		local token = parser:peek()
		local prec = token_priority[token.value] or -1

		if prec < min_prec then
			break
		end

		local operator = parser:consume().value
		local right = parser:parse_unary_expression()

		local next_prec = token_priority[parser:peek().value] or -1
		if prec < next_prec then
			right = self:generate_node(parser, right, prec + 1)
		end

		left = {
			type = "binary",
			operator = operator,
			left = left,
			right = right,
			line = left.line,
			column = left.column,
		}
	end
	return left
end

function binary_element:output(transpiler: types.transpiler, node: types.binary_node)
	local operator = node.operator
	if operator == "!=" then
		operator = "~="
	elseif operator == "&&" then
		operator = "and"
	elseif operator == "||" then
		operator = "or"
	end
	return `{transpiler:build_node(node.left)} {operator} {transpiler:build_node(node.right)}`
end

function binary_element:type_check(checker: types.type_checker, node: types.binary_node)
	local left_type = checker:check_node(node.left)
	local right_type = checker:check_node(node.right)
	local op = node.operator
	if op == "+" or op == "-" or op == "*" or op == "/" or op == "%" or op == "^" then
		if left_type and not checker.type_system:check_assignable(left_type, { kind = "builtin", name = "number" }) then
			checker:add_diagnostic("error", `operator {op} expected number on left`, node.line, node.column)
		end
		if
			right_type and not checker.type_system:check_assignable(right_type, { kind = "builtin", name = "number" })
		then
			checker:add_diagnostic("error", `operator {op} expected number on right`, node.line, node.column)
		end
		return { kind = "builtin", name = "number" }
	elseif op == "==" or op == "!=" or op == "<" or op == ">" or op == "<=" or op == ">=" then
		return { kind = "builtin", name = "boolean" }
	elseif op == ".." then
		return { kind = "builtin", name = "string" }
	elseif op == "&&" or op == "||" or op == "and" or op == "or" then
		return { kind = "builtin", name = "any" }
	end
	return { kind = "builtin", name = "any" }
end

return inst
