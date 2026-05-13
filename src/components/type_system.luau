--!nonstrict

local types = require("./types")

local type_system = {}
type_system.__index = type_system

function type_system.new()
	return setmetatable({
		types = {},
		builtin_types = {
			["string"] = { kind = "builtin", name = "string" },
			["number"] = { kind = "builtin", name = "number" },
			["boolean"] = { kind = "builtin", name = "boolean" },
			["any"] = { kind = "builtin", name = "any" },
		},
	}, type_system)
end

function type_system:register_type(name: string, type_def: types.type_node)
	self.types[name] = type_def
end

function type_system:get_type(name: string): types.type_node?
	return self.types[name] or self.builtin_types[name]
end

function type_system:resolve_type(type_expr: types.type_node): types.type_node
	if typeof(type_expr) == "table" then
		if type_expr.kind == "object" then
			return type_expr
		elseif type_expr.kind == "literal" then
			return type_expr
		elseif type_expr.kind == "reference" then
			return self:get_type(type_expr.name) or type_expr
		elseif type_expr.kind == "union" then
			return type_expr
		end
		return type_expr
	elseif typeof(type_expr) == "string" then
		return self:get_type(type_expr)
	end
	return type_expr
end

function type_system:check_assignable(from: types.type_node, to: types.type_node): boolean
	if to.name == "any" or from.name == "any" then
		return true
	end
	if from.name == to.name and from.name ~= nil then
		return true
	end
	if from.kind == "literal" and to.kind == "literal" then
		return from.value == to.value
	end
	if from.kind == "object" and to.kind == "object" then
		for name, to_field in to.fields do
			local from_field = from.fields[name]
			if not from_field or not self:check_assignable(from_field, to_field) then
				return false
			end
		end
		return true
	end
	return false
end

function type_system:export_types(): { [string]: types.type_node }
	local exported = {}
	for name, type_def in self.types do
		exported[name] = type_def
	end
	return exported
end

return type_system
