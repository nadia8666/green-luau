--!nonstrict

local types = require("./types")

local type_checker = {}
type_checker.__index = type_checker

function type_checker.new(type_system: types.type_node)
	return setmetatable({
		type_system = type_system,
		scopes = { {} },
		diagnostics = {},
	}, type_checker)
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
			return self.scopes[i][name]
		end
	end
	return nil
end

function type_checker:check_node(node: types.node): types.type_node?
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
	end
	return nil
end

function type_checker:check_var(node: types.node)
	local declared_type = { kind = "builtin", name = "any" }

	if node.type_annotation then
		declared_type = self.type_system:resolve_type(node.type_annotation)
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
		if value_type and not self.type_system:check_assignable(value_type, declared_type) then
			self:add_diagnostic(
				"error",
				"type mismatch in assignment",
				declared_type.line or node.line,
				declared_type.column or node.column
			)
		end
	end

	return declared_type
end

function type_checker:check_func(node: types.node)
	self:push_scope()
	local param_types = {}
	for _, param in node.params do
		local param_type = self.type_system:resolve_type(param.type_annotation or { kind = "builtin", name = "any" })
		param_types[param.name] = param_type
		self:declare_symbol(param.name, param_type)
	end

	for _, stmt in node.body do
		self:check_node(stmt)
	end

	self:pop_scope()
	return { kind = "function", params = param_types }
end

function type_checker:check_call(node: types.node)
	return { kind = "builtin", name = "any" }
end

function type_checker:check_binary(node: types.node)
	return { kind = "builtin", name = "any" }
end

function type_checker:check_object_literal(node: types.node)
	local fields = {}
	for _, field in node.fields do
		fields[field.name] = self:check_node(field.value) or { kind = "builtin", name = "any" }
	end
	return { kind = "object", fields = fields }
end

function type_checker:check_type_decl(node: types.node)
	self.type_system:register_type(node.name, node.type_def)
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
