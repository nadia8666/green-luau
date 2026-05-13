--!nonstrict

local builtins = require("./builtins")
local types = require("./types")

local type_system = {}
type_system.__index = type_system

function type_system.new()
	return setmetatable({
		types = {},
		builtin_types = builtins.get_types(),
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
			for _, field in type_expr.fields do
				field.field_type = self:resolve_type(field.field_type)
			end
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

function type_system:get_field(obj_type: types.type_node, name: string): types.type_node?
	obj_type = self:resolve_type(obj_type)
	if obj_type.kind ~= "object" then
		return nil
	end

	if obj_type.fields[name] then
		return self:resolve_type(obj_type.fields[name])
	end

	for _, field in obj_type.fields do
		if typeof(field) == "table" and field.name == name then
			return self:resolve_type(field.field_type)
		end
	end

	return nil
end

function type_system:check_assignable(from: types.type_node, to: types.type_node): boolean
	from = self:resolve_type(from)
	to = self:resolve_type(to)

	if from.kind == "builtin" and to.kind == "builtin" then
		if from.name == to.name then
			return true
		end
		if to.name == "any" then
			return true
		end
	end

	if from.kind == "builtin" and to.kind == "literal" then
		return false
	end

	if from.kind == "literal" and to.kind == "builtin" then
		if to.name == "string" and typeof(from.value) == "string" then
			return true
		end
		if to.name == "number" and typeof(from.value) == "number" then
			return true
		end
		if to.name == "boolean" and typeof(from.value) == "boolean" then
			return true
		end
		if to.name == "any" then
			return true
		end
	end

	if from.kind == "literal" and to.kind == "literal" then
		return from.value == to.value
	end

	if from.kind == "object" and to.kind == "object" then
		for key, to_field in to.fields do
			local field_name, field_type

			if typeof(key) == "number" and typeof(to_field) == "table" and to_field.name then
				field_name = to_field.name
				field_type = to_field.field_type
			else
				field_name = key
				field_type = to_field
			end

			local from_field = from.fields[field_name]
			if not from_field then
				for _, f in from.fields do
					if typeof(f) == "table" and f.name == field_name then
						from_field = f.field_type
						break
					end
				end
			end

			if not from_field or not self:check_assignable(from_field, field_type) then
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
