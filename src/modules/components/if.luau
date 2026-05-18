--!nonstrict

local types = require("../types")
local element = require("./element")

local if_element = setmetatable({}, element)
if_element.__index = if_element
if_element.node_type = "if"
if_element.statement_keywords = { "if" }

local inst = setmetatable(element.new(), if_element)

function if_element:generate_node(parser: types.parser)
	local start_token = parser:peek()
	parser:consume("if")
	parser:consume("(")
	local test = parser:parse_expression()
	parser:consume(")")
	local consequent = parser:parse_block()
	local alternate = nil
	if parser:peek().value == "else" then
		parser:consume("else")
		if parser:peek().value == "if" then
			alternate = self:generate_node(parser)
		else
			alternate = parser:parse_block()
		end
	end
	return {
		type = "if",
		test = test,
		consequent = consequent,
		alternate = alternate,
		line = start_token.line,
		column = start_token.column,
	}
end

function if_element:output(transpiler: types.transpiler, node: types.if_node)
	local out = `if {transpiler:build_node(node.test)} then\n{transpiler:build_node(node.consequent)}`
	if node.alternate then
		if node.alternate.type == "if" then
			local alt = transpiler:build_node(node.alternate)
			alt = alt:sub(4, -5)
			out ..= `\nelseif {alt}`
		else
			out ..= `\nelse\n{transpiler:build_node(node.alternate)}`
		end
	end
	return out .. "\nend"
end

function if_element:type_check(checker: types.type_checker, node: types.if_node)
	checker:check_node(node.test)
	checker:check_node(node.consequent)
	if node.alternate then
		checker:check_node(node.alternate)
	end
	return nil
end

return inst
