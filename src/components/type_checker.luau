--!nonstrict

local types = require("./types")
local builtins = require("./builtins")

local type_checker = {}
type_checker.__index = type_checker

function type_checker.new(type_system: types.type_node)
	local self = setmetatable({
		type_system = type_system,
		scopes = { {} },
		diagnostics = {},
	}, type_checker)

	for name, node in builtins.get_globals() do
		self:declare_symbol(name, node)
	end

	return self
end

function type_checker:push_scope()
	table.insert(self.scopes, {})
end

function type_checker:pop_scope()
	table.remove(self.scopes)
end

function type_checker:current_scope(): { [string]: types.type_node }
	return self.scopes[#self.scopes]
end

function type_checker:declare_symbol(name: string, type_info: types.type_node)
	self:current_scope()[name] = type_info
end

function type_checker:lookup_symbol(name: string): types.type_node?
	for i = #self.scopes, 1, -1 do
		if self.scopes[i][name] then
			local res = self.scopes[i][name]
			return res
		end
	end
	return nil
end

function type_checker:resolve_type(type_expr: types.type_node): types.type_node
	return self.type_system:resolve_type(type_expr, function(name)
		return self:lookup_symbol(name)
	end)
end

function type_checker:check_node(node: types.node): types.type_node?
	if not node then
		return nil
	end
	if node.type == "var" then
		return self:check_var(node)
	elseif node.type == "func" then
		return self:check_func(node)
	elseif node.type == "call" then
		return self:check_call(node)
	elseif node.type == "binary" then
		return self:check_binary(node)
	elseif node.type == "object_literal" then
		return self:check_object_literal(node)
	elseif node.type == "type_decl" then
		return self:check_type_decl(node)
	elseif node.type == "num" then
		return { kind = "literal", value = node.value }
	elseif node.type == "str" then
		return { kind = "literal", value = node.value }
	elseif node.type == "bool" then
		return { kind = "literal", value = node.value }
	elseif node.type == "id" then
		local symbol = self:lookup_symbol(node.name)
		if not symbol then
			self:add_diagnostic("error", `unknown symbol: {node.name}`, node.line, node.column)
			return { kind = "builtin", name = "any" }
		end
		return symbol
	elseif node.type == "parenthesis" then
		return self:check_node(node.expression)
	elseif node.type == "member" then
		local object_type = self:check_node(node.object)
		if not object_type then
			return nil
		end
		local field_type = self.type_system:get_field(object_type, node.property)
		if not field_type then
			self:add_diagnostic("error", `property "{node.property}" does not exist on type`, node.line, node.column)
			return { kind = "builtin", name = "any" }
		end
		return field_type
	elseif node.type == "assign" then
		return self:check_assignment(node)
	elseif node.type == "return" then
		return node.value and self:check_node(node.value) or nil
	elseif node.type == "tuple_literal" then
		local element_types = {}
		for _, val in node.values do
			table.insert(element_types, self:check_node(val) or { kind = "builtin", name = "any" })
		end
		return { kind = "tuple", types = element_types }
	end
	return nil
end

function type_checker:check_var(node: types.node)
	local declared_type = { kind = "builtin", name = "any" }

	if node.type_annotation then
		declared_type = self:resolve_type(node.type_annotation)
		if declared_type.kind == "reference" and not self.type_system:get_type(declared_type.name) then
			self:add_diagnostic(
				"error",
				`unknown type: {declared_type.name}`,
				declared_type.line or node.line,
				declared_type.column or node.column
			)
		end
	end

	if node.init then
		local value_type = self:check_node(node.init)
		if node.type_annotation then
			if value_type and not self.type_system:check_assignable(value_type, declared_type) then
				self:add_diagnostic(
					"error",
					"type mismatch in assignment",
					declared_type.line or node.line,
					declared_type.column or node.column
				)
			end
		else
			if node.kind == "const" then
				declared_type = value_type
			else
				-- widen
				if value_type and value_type.kind == "literal" then
					if typeof(value_type.value) == "string" then
						declared_type = self.type_system:get_type("string")
					elseif typeof(value_type.value) == "number" then
						declared_type = self.type_system:get_type("number")
					elseif typeof(value_type.value) == "boolean" then
						declared_type = self.type_system:get_type("boolean")
					else
						declared_type = value_type
					end
				else
					declared_type = value_type or declared_type
				end
			end
		end
	end

	self:declare_symbol(node.id, declared_type)

	return declared_type
end

function type_checker:check_func(node: types.node)
	self:push_scope()
	if node.type_params then
		for _, name in node.type_params do
			self:declare_symbol(name, { kind = "generic", name = name })
		end
	end

	local param_types = {}
	for _, param in node.params do
		local param_type = self:resolve_type(param.type_annotation or { kind = "builtin", name = "any" })
		table.insert(param_types, param_type)
	end

	local return_type = node.return_type and self:resolve_type(node.return_type) or { kind = "builtin", name = "any" }
	local func_type = { kind = "function", params = param_types, returns = return_type, type_params = node.type_params }

	if node.name then
		local current_scope = self.scopes[#self.scopes]
		local parent_scope = self.scopes[#self.scopes - 1]
		if parent_scope then
			parent_scope[node.name] = func_type
		else
			current_scope[node.name] = func_type
		end
	end

	for i, param in node.params do
		self:declare_symbol(param.name, param_types[i])
	end

	for _, stmt in node.body do
		local stmt_type = self:check_node(stmt)
		if stmt.type == "return" then
			if stmt_type and not self.type_system:check_assignable(stmt_type, return_type) then
				self:add_diagnostic(
					"error",
					`return type mismatch: expected {return_type.name or return_type.kind}, got {stmt_type.name or stmt_type.kind}`,
					stmt.line,
					stmt.column
				)
			end
		end
	end

	self:pop_scope()
	return func_type
end

function type_checker:check_call(node: types.node)
	local callee_type = self:check_node(node.callee)
	if not callee_type then
		return { kind = "builtin", name = "any" }
	end

	if callee_type.kind ~= "function" then
		self:add_diagnostic("error", "cannot call non-function", node.line, node.column)
		return { kind = "builtin", name = "any" }
	end

	if callee_type.type_params then
		local mapping = {}
		if node.type_args then
			for i, name in callee_type.type_params do
				local arg = node.type_args[i]
				if arg then
					mapping[name] = self:resolve_type(arg)
				else
					mapping[name] = { kind = "builtin", name = "any" }
				end
			end
		end
		callee_type = self.type_system:substitute(callee_type, mapping)
	end

	if #node.arguments < #callee_type.params then
		self:add_diagnostic(
			"error",
			`too few arguments in call: expected {#callee_type.params}, got {#node.arguments}`,
			node.line,
			node.column
		)
	end

	for i, arg in node.arguments do
		local arg_type = self:check_node(arg)
		local param_type = callee_type.params[i]

		if not param_type then
			local last_param = callee_type.params[#callee_type.params]
			if last_param and last_param.kind == "variadic" then
				param_type = last_param.inner
			else
				self:add_diagnostic(
					"error",
					`argument mismatch for expression, expected {#callee_type.params} args, got {i}`,
					arg.line,
					arg.column
				)
				continue
			end
		elseif param_type.kind == "variadic" then
			param_type = param_type.inner
		end

		if arg_type and not self.type_system:check_assignable(arg_type, param_type) then
			self:add_diagnostic(
				"error",
				`type mismatch in call: argument {i} expected {param_type.name or param_type.kind}, got {arg_type.name or arg_type.kind}`,
				arg.line,
				arg.column
			)
		end
	end

	return callee_type.returns or { kind = "builtin", name = "any" }
end

function type_checker:check_binary(node: types.node)
	return { kind = "builtin", name = "any" }
end

function type_checker:check_assignment(node: types.node)
	local target_type = self:check_node(node.left)
	local value_type = self:check_node(node.value)

	if target_type and value_type and not self.type_system:check_assignable(value_type, target_type) then
		self:add_diagnostic("error", "type mismatch in assignment", node.line, node.column)
	end

	return target_type
end

function type_checker:check_object_literal(node: types.node)
	local fields = {}
	for _, field in node.fields do
		fields[field.name] = self:check_node(field.value) or { kind = "builtin", name = "any" }
	end
	return { kind = "object", fields = fields }
end

function type_checker:check_type_decl(node: types.node)
	local type_def = node.type_def
	if node.type_params then
		type_def = { kind = "generic", type_params = node.type_params, inner = type_def }
	end
	self.type_system:register_type(node.name, type_def)
	return nil
end

function type_checker:add_diagnostic(severity: string, message: string, line: number, column: number)
	table.insert(self.diagnostics, {
		severity = severity,
		message = message,
		line = line,
		column = column,
	})
end

function type_checker:get_diagnostics(): { { severity: string, message: string, line: number, column: number } }
	return self.diagnostics
end

function type_checker:check_tree(ast: types.tree)
	self.diagnostics = {}
	self:push_scope()

	if ast.type == "program" then
		for _, stmt in ast.body do
			self:check_node(stmt)
		end
	end

	self:pop_scope()
	return self.diagnostics
end

return type_checker
