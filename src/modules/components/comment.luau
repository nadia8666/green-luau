--!strict

local types = require("../types")
local element = require("./element")

local comment_element = setmetatable({}, element)
comment_element.__index = comment_element
comment_element.node_type = "comment"

local inst = setmetatable(element.new(), comment_element)

function comment_element:output(transpiler: types.transpiler, node: types.comment_node)
	if node.is_block then
		return `--[[{node.value}]]` -- TODO: fix formatting
	else
		return `--{node.value}`
	end
end

return inst
