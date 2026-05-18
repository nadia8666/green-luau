--!strict

local types = require("../types")
local element = require("./element")

local block_element = setmetatable({}, element)
block_element.__index = block_element
block_element.node_type = "block"

local inst = setmetatable(element.new(), block_element)

function block_element:generate_node(parser: types.parser)
	local start_token = parser:peek()
	parser:consume("{")
	local body = {}
	while parser:peek().value ~= "}" do
		local statement = parser:parse_statement()
		if statement then
			table.insert(body, statement)
		end
	end
	parser:consume("}")
	return {
		type = "block",
		body = body,
		line = start_token.line,
		column = start_token.column,
	}
end

function block_element:output(transpiler: types.transpiler, node: types.block_node)
	local lines = {}
	for _, stmt in node.body do
		table.insert(lines, `	{transpiler:build_node(stmt)}`)
	end
	return table.concat(lines, "\n")
end

function block_element:type_check(checker: types.type_checker, node: types.block_node)
	checker:push_scope()
	for _, stmt in node.body do
		checker:check_node(stmt)
	end
	checker:pop_scope()
	return nil
end

return inst
