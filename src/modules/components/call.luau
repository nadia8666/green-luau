--!nonstrict

local types = require("../types")
local element = require("./element")

local call_element = setmetatable({}, element)
call_element.__index = call_element
call_element.node_type = "call"

local inst = setmetatable(element.new(), call_element)

function call_element:generate_node(parser: types.parser, callee: types.node)
	local start_token = parser:peek()
	local type_args = nil
	if parser:peek().value == "<" then
		type_args = require("./type_decl").parse_type_args(parser)
	end

	parser:consume("(")
	local arguments = {}
	if parser:peek().value ~= ")" then
		repeat
			table.insert(arguments, parser:parse_expression())
			if parser:peek().value == "," then
				parser:consume(",")
			end
		until parser:peek().value == ")"
	end
	parser:consume(")")

	return {
		type = "call",
		callee = callee,
		type_args = type_args,
		arguments = arguments,
		line = start_token.line,
		column = start_token.column,
	}
end

function call_element:output(transpiler: types.transpiler, node: types.call_node)
	local args = {}
	for _, arg in node.arguments do
		table.insert(args, transpiler:build_node(arg))
	end
	return `{transpiler:build_node(node.callee)}({table.concat(args, ", ")})`
end

function call_element:type_check(checker: types.type_checker, node: types.call_node)
	local callee_type = checker:check_node(node.callee)
	if not callee_type then
		return { kind = "builtin", name = "any" }
	end
	if callee_type.kind ~= "function" then
		checker:add_diagnostic("error", "cannot call non-function", node.line, node.column)
		return { kind = "builtin", name = "any" }
	end
	if callee_type.type_params then
		local mapping = {}
		if node.type_args then
			for i, name in callee_type.type_params do
				local arg = node.type_args[i]
				if arg then
					mapping[name] = checker:resolve_type(arg)
				else
					mapping[name] = { kind = "builtin", name = "any" }
				end
			end
		end
		callee_type = checker.type_system:substitute(callee_type, mapping)
	end
	for i, arg in node.arguments do
		local arg_type = checker:check_node(arg)
		local param_type = callee_type.params[i]
		if not param_type then
			local last_param = callee_type.params[#callee_type.params]
			if last_param and last_param.kind == "variadic" then
				param_type = last_param.inner
			else
				checker:add_diagnostic("error", `argument mismatch for expression`, arg.line, arg.column)
				continue
			end
		elseif param_type.kind == "variadic" then
			param_type = param_type.inner
		end
		if arg_type and not checker.type_system:check_assignable(arg_type, param_type) then
			checker:add_diagnostic("error", `type mismatch in call`, arg.line, arg.column)
		end
	end
	return callee_type.returns or { kind = "builtin", name = "any" }
end

return inst
