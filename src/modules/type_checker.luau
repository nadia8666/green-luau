--!nonstrict

local types = require("./types")
local builtins = require("./builtins")
local registry = require("./components/registry")

local type_checker = {} :: types.type_checker
type_checker.__index = type_checker

function type_checker.new(type_system: types.type_system)
	local self = setmetatable({
		type_system = type_system,
		scopes = { {} },
		type_scopes = { {} },
		diagnostics = {},
		components = registry,
		handlers = {},
	}, type_checker)

	for name, node in builtins.get_globals() do
		self:declare_symbol(name, node)
	end

	for _, component in self.components do
		if component.node_type then
			self.handlers[component.node_type] = component
		end
	end

	return self
end

function type_checker:push_scope()
	table.insert(self.scopes, {})
	table.insert(self.type_scopes, {})
end

function type_checker:pop_scope()
	table.remove(self.scopes)
	table.remove(self.type_scopes)
end

function type_checker:current_scope()
	return self.scopes[#self.scopes]
end

function type_checker:declare_symbol(name: string, type_info: types.type_node)
	self:current_scope()[name] = type_info
end

function type_checker:lookup_symbol(name: string)
	for i = #self.scopes, 1, -1 do
		if self.scopes[i][name] then
			local res = self.scopes[i][name]
			return res
		end
	end
	return nil
end

function type_checker:declare_type_symbol(name: string, type_info: types.type_node)
	self.type_scopes[#self.type_scopes][name] = type_info
end

function type_checker:lookup_type_symbol(name: string)
	for i = #self.type_scopes, 1, -1 do
		if self.type_scopes[i][name] then
			return self.type_scopes[i][name]
		end
	end
	return nil
end

function type_checker:get_type_name(t: types.type_node)
	t = self:resolve_type(t)
	if t.kind == "builtin" then
		return t.name
	elseif t.kind == "literal" then
		return typeof(t.value) -- TODO: for now this is fine but probably change this later to be embedded
	elseif t.kind == "reference" then
		return t.name
	elseif t.kind == "generic" then
		return t.name or "generic"
	end
	return t.kind
end

function type_checker:resolve_type(type_expr: types.type_node)
	return self.type_system:resolve_type(type_expr, function(name)
		return self:lookup_type_symbol(name)
	end)
end

function type_checker:check_node(node: types.node)
	if not node then
		return nil
	end

	local handler = self.handlers[node.type]
	if handler and handler.type_check then
		return handler:type_check(self, node)
	end

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
