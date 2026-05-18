--!nonstrict

local types = require("../types")
local element = require("./element")

local variadic_element = setmetatable({}, element)
variadic_element.__index = variadic_element
variadic_element.node_type = "variadic"

local inst = setmetatable(element.new(), variadic_element)

function variadic_element:output(transpiler: types.transpiler, node: types.variadic_node)
	return "..."
end

return inst
