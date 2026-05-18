--!nonstrict

local types = require("./types")
local registry = require("./components/registry")

local transpiler = {} :: types.transpiler
transpiler.__index = transpiler

function transpiler.new(ast: types.tree)
	local self = setmetatable({
		ast = ast,
		handlers = {},
		components = registry,
	}, transpiler)

	self:register_defaults()
	return self
end

function transpiler:register_handler(node_type: string, handler: (types.transpiler, types.node) -> string)
	self.handlers[node_type] = handler
end

function transpiler:build_node(node: types.node): string
	local handler = self.handlers[node.type]
	if not handler then
		error(`no handler for node of type: {node.type}`)
	end
	return handler(self, node)
end

function transpiler:register_defaults()
	for _, comp in self.components do
		if comp.node_type and comp.output then
			self:register_handler(comp.node_type, function(s, node)
				return comp:output(s, node)
			end)
		end
	end
end

function transpiler:transpile_type(t: types.type_node): string
	if not t then
		return "any"
	end
	if t.kind == "builtin" then
		return t.name
	elseif t.kind == "reference" then
		local args = ""
		if t.type_args then
			local t_args = {}
			for _, arg in t.type_args do
				table.insert(t_args, self:transpile_type(arg))
			end
			args = `<{table.concat(t_args, ", ")}>`
		end
		return t.name .. args
	elseif t.kind == "tuple" then
		local t_types = {}
		for _, inner in t.types do
			table.insert(t_types, self:transpile_type(inner))
		end
		return `[{table.concat(t_types, ", ")}]`
	elseif t.kind == "variadic" then
		return `...`
	end
	return "any"
end

function transpiler:build()
	return self:build_node(self.ast)
end

return transpiler
