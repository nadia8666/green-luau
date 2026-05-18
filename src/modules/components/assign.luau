--!strict

local types = require("../types")
local element = require("./element")

local assign_element = setmetatable({}, element)
assign_element.__index = assign_element
assign_element.node_type = "assign"

local inst = setmetatable(element.new(), assign_element)

function assign_element:generate_node(parser: types.parser, left: types.node)
	local operator = parser:consume().value
	local value = parser:parse_expression()
	if parser:peek().value == ";" then
		parser:consume(";")
	end
	return {
		type = "assign",
		left = left,
		operator = operator,
		value = value,
		line = left.line,
		column = left.column,
	}
end

function assign_element:output(transpiler: types.transpiler, node: types.assign_node)
	return `{transpiler:build_node(node.left)} {node.operator} {transpiler:build_node(node.value)}`
end

function assign_element:type_check(checker: types.type_checker, node: types.assign_node)
	local target_type = checker:check_node(node.left)
	local value_type = checker:check_node(node.value)
	if target_type and value_type and not checker.type_system:check_assignable(value_type, target_type) then
		checker:add_diagnostic("error", `type mismatch in assignment`, node.line, node.column)
	end
	return target_type
end

return inst
