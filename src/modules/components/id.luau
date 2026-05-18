--!nonstrict

local types = require("../types")
local element = require("./element")

local id_element = setmetatable({}, element)
id_element.__index = id_element
id_element.node_type = "id"

local inst = setmetatable(element.new(), id_element)

function id_element:generate_node(parser: types.parser)
	local lit = parser:consume()
	return { type = "id", name = lit.value, line = lit.line, column = lit.column }
end

function id_element:output(transpiler: types.transpiler, node: types.id_node)
	return node.name
end

function id_element:type_check(checker: types.type_checker, node: types.id_node)
	local symbol = checker:lookup_symbol(node.name)
	if not symbol then
		checker:add_diagnostic("error", `unknown symbol: {node.name}`, node.line, node.column)
		return { kind = "builtin", name = "any" }
	end
	return symbol
end

return inst
