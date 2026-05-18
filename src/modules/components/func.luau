--!nonstrict

local types = require("../types")
local element = require("./element")

local func_element = setmetatable({}, element)
func_element.__index = func_element
func_element.node_type = "func"
func_element.statement_keywords = { "function" }

local inst = setmetatable(element.new(), func_element)

function func_element:generate_node(parser: types.parser): types.node
	local start_token = parser:peek()
	parser:consume("function")
	local func_name = parser:consume().value
	local type_params = nil
	if parser:peek().value == "<" then
		type_params = require("./type_decl").parse_type_params(parser)
	end
	parser:consume("(")
	local params = {}
	if parser:peek().value ~= ")" then
		repeat
			local param = parser:consume()
			local param_name = param.value
			local param_type = nil
			if param_name == "..." then
				if parser:peek().value == ":" then
					parser:consume(":")
					param_type = require("./type_decl").parse_type_expr(parser)
				end
				table.insert(params, {
					name = "...",
					type_annotation = {
						kind = "variadic",
						inner = param_type,
						line = param.line,
						column = param.column,
					},
					variadic = true,
				})
				break
			end
			if parser:peek().value == ":" then
				parser:consume(":")
				param_type = require("./type_decl").parse_type_expr(parser)
			end
			table.insert(params, { name = param_name, type_annotation = param_type })
			if parser:peek().value == "," then
				parser:consume(",")
			end
		until parser:peek().value == ")"
	end
	parser:consume(")")
	local return_type = nil
	if parser:peek().value == ":" then
		parser:consume(":")
		return_type = require("./type_decl").parse_type_expr(parser)
	end
	parser:consume("{")
	local body = {}
	while parser:peek().value ~= "}" do
		table.insert(body, parser:parse_statement())
	end
	parser:consume("}")
	return {
		type = "func",
		name = func_name,
		type_params = type_params,
		params = params,
		return_type = return_type,
		body = body,
		line = start_token.line,
		column = start_token.column,
	}
end

function func_element:output(transpiler: types.transpiler, node: types.func_node)
	local param_names = {}
	for _, param in node.params do
		if typeof(param) == "table" then
			table.insert(param_names, param.name)
		else
			table.insert(param_names, param)
		end
	end
	local params = table.concat(param_names, ", ")
	local body_lines = {}
	for _, stmt in node.body do
		table.insert(body_lines, `	{transpiler:build_node(stmt)}`)
	end
	return `function {node.name}({params})\n{table.concat(body_lines, "\\n")}\nend`
end

function func_element:type_check(checker: types.type_checker, node: types.func_node)
	checker:push_scope()
	if node.type_params then
		for _, name in node.type_params do
			checker:declare_type_symbol(name, { kind = "generic", name = name })
		end
	end
	local param_types = {}
	for _, param in node.params do
		table.insert(param_types, checker:resolve_type(param.type_annotation or { kind = "builtin", name = "any" }))
	end
	local return_type = node.return_type and checker:resolve_type(node.return_type) or { kind = "builtin", name = "any" }
	local func_type = { kind = "function", params = param_types, returns = return_type, type_params = node.type_params }
	if node.name then
		local current_scope = checker.scopes[#checker.scopes]
		local parent_scope = checker.scopes[#checker.scopes - 1]
		if parent_scope then
			parent_scope[node.name] = func_type
		else
			current_scope[node.name] = func_type
		end
	end
	for i, param in node.params do
		checker:declare_symbol(param.name, param_types[i])
	end
	for _, stmt in node.body do
		local stmt_type = checker:check_node(stmt)
		if stmt.type == "return" then
			if stmt_type and not checker.type_system:check_assignable(stmt_type, return_type) then
				checker:add_diagnostic("error", `return type mismatch`, stmt.line, stmt.column)
			end
		end
	end
	checker:pop_scope()
	return func_type
end

return inst
