--!nonstrict

local types = require("../types")
local element = require("./element")

local return_element = setmetatable({}, element)
return_element.__index = return_element
return_element.node_type = "return"
return_element.statement_keywords = { "return" }

local inst = setmetatable(element.new(), return_element)

function return_element:generate_node(parser: types.parser): types.return_node
	local start_token = parser:peek()
	parser:consume("return")
	local value = nil
	local next_val = parser:peek().value
	if next_val ~= "}" and next_val ~= ";" and next_val ~= "else" then
		value = parser:parse_expression()
	end
	if parser:peek().value == ";" then
		parser:consume(";")
	end
	return { type = "return", value = value, line = start_token.line, column = start_token.column }
end

function return_element:output(transpiler: types.transpiler, node: types.return_node)
	if node.value then
		return `return {transpiler:build_node(node.value)}`
	else
		return "return"
	end
end

function return_element:type_check(checker: types.type_checker, node: types.return_node)
	return node.value and checker:check_node(node.value) or nil
end

return inst
