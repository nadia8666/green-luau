--!nonstrict

local types = require("../types")
local element = require("./element")

local tuple_literal_element = setmetatable({}, element)
tuple_literal_element.__index = tuple_literal_element
tuple_literal_element.node_type = "tuple_literal"

local inst = setmetatable(element.new(), tuple_literal_element)

function tuple_literal_element:generate_node(parser: types.parser)
	local start_token = parser:peek()
	parser:consume("[")
	local values = {}
	if parser:peek().value ~= "]" then
		repeat
			table.insert(values, parser:parse_expression())
			if parser:peek().value == "," then
				parser:consume(",")
			end
		until parser:peek().value == "]"
	end
	parser:consume("]")
	return {
		type = "tuple_literal",
		values = values,
		line = start_token.line,
		column = start_token.column,
	}
end

function tuple_literal_element:output(transpiler: types.transpiler, node: types.tuple_literal_node)
	local vals = {}
	for _, val in node.values do
		table.insert(vals, transpiler:build_node(val))
	end
	return "{ " .. table.concat(vals, ", ") .. " }"
end

function tuple_literal_element:type_check(checker: types.type_checker, node: types.tuple_literal_node)
	local element_types = {}
	for _, val in node.values do
		table.insert(element_types, checker:check_node(val) or { kind = "builtin", name = "any" })
	end
	return { kind = "tuple", types = element_types }
end

return inst
