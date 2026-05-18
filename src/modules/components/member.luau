--!nonstrict

local types = require("../types")
local element = require("./element")

local member_element = setmetatable({}, element)
member_element.__index = member_element
member_element.node_type = "member"

local inst = setmetatable(element.new(), member_element)

function member_element:generate_node(parser: types.parser, left: types.node)
	parser:consume(".")
	local property_token = parser:consume()
	if property_token.type ~= "id" then
		parser:report_error(`expected property name after "." but got {property_token.value}`)
	end
	return {
		type = "member",
		object = left,
		property = property_token.value,
		line = left.line,
		column = left.column,
	}
end

function member_element:output(transpiler: types.transpiler, node: types.member_node)
	return `{transpiler:build_node(node.object)}.{node.property}`
end

function member_element:type_check(checker: types.type_checker, node: types.member_node)
	local object_type = checker:check_node(node.object)
	if not object_type then
		return nil
	end
	local field_type = checker.type_system:get_field(object_type, node.property)
	if not field_type then
		checker:add_diagnostic("error", `property "{node.property}" does not exist on type`, node.line, node.column)
		return { kind = "builtin", name = "any" }
	end
	return field_type
end

return inst
