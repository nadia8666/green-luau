--!nonstrict

local types = require("../types")
local element = require("./element")

local type_decl_element = setmetatable({}, element)
type_decl_element.__index = type_decl_element
type_decl_element.node_type = "type_decl"
type_decl_element.statement_keywords = { "type" }

local inst = setmetatable(element.new(), type_decl_element)

function type_decl_element.parse_type_expr(parser: types.parser)
	local json = require("@std/json")
	local token = parser:peek()

	if token.value == "{" then
		return type_decl_element.parse_object_type(parser)
	elseif token.value == "[" then
		return type_decl_element.parse_tuple_type(parser)
	elseif token.value == "..." then
		parser:consume("...")
		local inner = type_decl_element.parse_type_expr(parser)
		return { kind = "variadic", inner = inner, line = token.line, column = token.column }
	elseif token.type == "str" then
		local value = parser:consume().value
		return { kind = "literal", value = value, quote = token.quote, line = token.line, column = token.column }
	elseif token.type == "id" then
		local name = parser:consume().value
		local type_args = type_decl_element.parse_type_args(parser)
		return { kind = "reference", name = name, type_args = type_args, line = token.line, column = token.column }
	end

	parser:report_error(
		json.serialize({
			error_type = "PARSE_TYPE",
			token = token,
			reason = `unexpected token in type: {token.value}`,
		}),
		true
	)
	return nil
end

function type_decl_element.parse_object_type(parser: types.parser)
	local start_token = parser:peek()
	parser:consume("{")
	local fields = {}
	if parser:peek().value ~= "}" then
		repeat
			local field_name = parser:consume().value
			parser:consume(":")
			local field_type = type_decl_element.parse_type_expr(parser)
			table.insert(fields, { name = field_name, field_type = field_type })
			if parser:peek().value == "," then
				parser:consume(",")
			end
		until parser:peek().value == "}"
	end
	parser:consume("}")
	return { kind = "object", fields = fields, line = start_token.line, column = start_token.column }
end

function type_decl_element.parse_tuple_type(parser: types.parser)
	local start_token = parser:peek()
	parser:consume("[")
	local t = {}
	if parser:peek().value ~= "]" then
		repeat
			table.insert(t, type_decl_element.parse_type_expr(parser))
			if parser:peek().value == "," then
				parser:consume(",")
			end
		until parser:peek().value == "]"
	end
	parser:consume("]")
	return { kind = "tuple", types = t, line = start_token.line, column = start_token.column }
end

function type_decl_element.parse_type_params(parser: types.parser)
	if parser:peek().value == "<" then
		parser:consume("<")
		local params = {}
		repeat
			table.insert(params, parser:consume().value)
			if parser:peek().value == "," then
				parser:consume(",")
			end
		until parser:peek().value == ">"
		parser:consume(">")
		return params
	end
	return nil
end

function type_decl_element.parse_type_args(parser: types.parser)
	if parser:peek().value == "<" then
		parser:consume("<")
		local args = {}
		repeat
			table.insert(args, type_decl_element.parse_type_expr(parser))
			if parser:peek().value == "," then
				parser:consume(",")
			end
		until parser:peek().value == ">"
		parser:consume(">")
		return args
	end
	return nil
end

function type_decl_element:generate_node(parser: types.parser): types.node
	local start_token = parser:peek()
	parser:consume("type")
	local type_name = parser:consume().value
	local type_params = type_decl_element.parse_type_params(parser)
	parser:consume("=")
	local type_def = type_decl_element.parse_type_expr(parser)
	parser:consume(";")
	parser.type_system:register_type(type_name, type_def)
	return {
		type = "type_decl",
		name = type_name,
		type_params = type_params,
		type_def = type_def,
		line = start_token.line,
		column = start_token.column,
	}
end

function type_decl_element:output(transpiler: types.transpiler, node: types.type_decl_node)
	return ""
end

function type_decl_element:type_check(checker: types.type_checker, node: types.type_decl_node)
	local type_def = node.type_def
	if node.type_params then
		type_def = { kind = "generic", type_params = node.type_params, inner = type_def }
	end
	checker.type_system:register_type(node.name, type_def)
	return nil
end

return inst
