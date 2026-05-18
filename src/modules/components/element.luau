--!nonstrict

local types = require("../types")
local element = {}
element.__index = element

function element.new()
	local self = setmetatable({}, element)

	return self
end

function element:tokenize(lexer: types.lexer): types.token?
	return nil
end

function element:generate_node(parser: types.parser): types.node?
	return nil
end

function element:output(transpiler: types.transpiler, node: types.node): string?
	return nil
end

function element:type_check(checker: types.type_checker, node: types.node): types.type_node?
	return nil
end

export type element = typeof(element.new())
return element
