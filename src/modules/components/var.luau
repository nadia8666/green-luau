--!nonstrict

local types = require("../types")
local element = require("./element")

local var_element = setmetatable({}, element)
var_element.__index = var_element
var_element.node_type = "var"
var_element.statement_keywords = { "let", "const", "var" }

local inst = setmetatable(element.new(), var_element)

function var_element:generate_node(parser: types.parser): types.var_node
	local start_token = parser:peek()
	local kind = parser:consume().value
	local id_name = parser:consume().value
	local type_annotation = nil
	if parser:peek().value == ":" then
		parser:consume(":")
		type_annotation = require("./type_decl").parse_type_expr(parser)
	end
	parser:consume("=")
	local init = parser:parse_expression()
	parser:consume(";")
	return {
		type = "var",
		kind = kind,
		id = id_name,
		init = init,
		type_annotation = type_annotation,
		line = start_token.line,
		column = start_token.column,
	}
end

function var_element:output(transpiler: types.transpiler, node: types.var_node)
	local luau_keyword = (node.kind == "let" or node.kind == "var") and "local" or (node.kind == "const") and "const" or ""
	return `{luau_keyword} {node.id} = {transpiler:build_node(node.init :: types.node)}`
end

function var_element:type_check(checker: types.type_checker, node: types.var_node)
	local declared_type = { kind = "builtin", name = "any" } :: types.builtin_type_node
	if node.type_annotation then
		declared_type = checker:resolve_type(node.type_annotation :: types.type_node)
		if declared_type.kind == "reference" and not checker.type_system:get_type(declared_type.name) then
			checker:add_diagnostic(
				"error",
				`unknown type: {declared_type.name}`,
				declared_type.line or node.line,
				declared_type.column or node.column
			)
		end
	end
	if node.init then
		local value_type = checker:check_node(node.init)
		if node.type_annotation then
			if value_type and not checker.type_system:check_assignable(value_type, declared_type) then
				checker:add_diagnostic(
					"error",
					`type mismatch in assignment`,
					declared_type.line or node.line,
					declared_type.column or node.column
				)
			end
		else
			if node.kind == "const" then
				declared_type = value_type
			else
				if value_type and value_type.kind == "literal" then
					if typeof(value_type.value) == "string" then
						declared_type = checker.type_system:get_type("string")
					elseif typeof(value_type.value) == "number" then
						declared_type = checker.type_system:get_type("number")
					elseif typeof(value_type.value) == "boolean" then
						declared_type = checker.type_system:get_type("boolean")
					else
						declared_type = value_type
					end
				else
					declared_type = value_type or declared_type
				end
			end
		end
	end
	checker:declare_symbol(node.id, declared_type)
	return declared_type
end

return inst
