--!strict

local types = require("../types")
local element = require("./element")

local object_literal_element = setmetatable({}, element)
object_literal_element.__index = object_literal_element
object_literal_element.node_type = "object_literal"

local inst = setmetatable(element.new(), object_literal_element)

function object_literal_element:generate_node(parser: types.parser)
	local json = require("@std/json")
	local start_token = parser:peek()
	parser:consume("{")
	local fields = {}
	if parser:peek().value ~= "}" then
		repeat
			local token = parser:consume()
			local field_name = token.value
			local separator = parser:peek().value
			if separator == ":" or separator == "=" then
				parser:consume(separator)
			else
				parser:report_error(
					json.serialize({
						error_type = "PARSE",
						token = token,
						reason = `expected ":" or "=" but got "{separator}"`,
					}),
					true
				)
			end
			local field_value = parser:parse_expression()
			table.insert(fields, { name = field_name, value = field_value })
			if parser:peek().value == "," then
				parser:consume(",")
			end
		until parser:peek().value == "}"
	end
	parser:consume("}")
	return {
		type = "object_literal",
		fields = fields,
		line = start_token.line,
		column = start_token.column,
	}
end

function object_literal_element:output(transpiler: types.transpiler, node: types.object_literal_node)
	local pairs = {}
	for _, field in node.fields do
		table.insert(pairs, `{field.name} = {transpiler:build_node(field.value)}`)
	end
	return "{ " .. table.concat(pairs, ", ") .. " }"
end

function object_literal_element:type_check(checker: types.type_checker, node: types.object_literal_node)
	local fields = {}
	for _, field in node.fields do
		fields[field.name] = checker:check_node(field.value) or { kind = "builtin", name = "any" }
	end
	return { kind = "object", fields = fields }
end

return inst
