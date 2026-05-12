--!nonstrict

local types = require("./types")
local type_system = require("./type_system")

local parser = {}
parser.__index = parser

-- i think this is right. its PEMDAS
local token_priority = {
	["=="] = 1,
	["!="] = 1,
	["<"] = 1,
	[">"] = 1,
	["<="] = 1,
	[">="] = 1,
	["+"] = 2,
	["-"] = 2,
	["*"] = 3,
	["/"] = 3,
	["^"] = 4,
}

function parser.new(tokens: { types.token })
	local self = setmetatable({
		tokens = tokens,
		cursor = 1,
		statement_parsers = {},
		type_system = type_system.new(),
	}, parser)

	self:register_defaults()
	return self
end

function parser:peek()
	return self.tokens[self.cursor]
end

function parser:report_error(message: string)
	local token = self:peek()
	local log = `[Line {token.line}:{token.column}] {message}`
	error(log)
end

--[[
    read token and advance cursor
    fails if it encounters an unmatched symbol
]]
function parser:consume(expected_value: string?)
	local token = self.tokens[self.cursor]
	if expected_value and token.value ~= expected_value then
		self:report_error(`expected "{expected_value}" but got "{token.value}"`)
	end
	self.cursor += 1
	return token
end

function parser:register_statement(
	keywords: string | { string },
	handler: (typeof(parser.new(nil))) -> types.node,
	...: any
)
	if typeof(keywords) == "table" then
		for _, keyword in keywords do
			self.statement_parsers[keyword] = { handler, { ... } }
		end
	else
		self.statement_parsers[keywords] = { handler, { ... } }
	end
end

function parser:register_defaults()
	local function parse_declaration(parser_self)
		local kind = parser_self:consume().value
		local id_name = parser_self:consume().value
		local type_annotation = nil
		if parser_self:peek().value == ":" then
			parser_self:consume(":")
			type_annotation = parser_self:parse_type_expr()
		end
		parser_self:consume("=")
		local init = parser_self:parse_expression()
		parser_self:consume(";")
		return { type = "var", kind = kind, id = id_name, init = init, type_annotation = type_annotation }
	end

	self:register_statement({ "let", "const", "var" }, parse_declaration)

	self:register_statement("type", function(parser_self)
		parser_self:consume("type")
		local type_name = parser_self:consume().value
		parser_self:consume("=")
		local type_def = parser_self:parse_type_expr()
		parser_self:consume(";")
		parser_self.type_system:register_type(type_name, type_def)
		return { type = "type_decl", name = type_name, type_def = type_def }
	end)

	self:register_statement("function", function(parser_self)
		parser_self:consume("function")
		local func_name = parser_self:consume().value
		parser_self:consume("(")
		local params = {}
		if parser_self:peek().value ~= ")" then
			repeat
				local param_name = parser_self:consume().value
				local param_type = nil
				if parser_self:peek().value == ":" then
					parser_self:consume(":")
					param_type = parser_self:parse_type_expr()
				end
				table.insert(params, { name = param_name, type_annotation = param_type })
				if parser_self:peek().value == "," then
					parser_self:consume(",")
				end
			until parser_self:peek().value == ")"
		end
		parser_self:consume(")")
		parser_self:consume("{")
		local body = {}
		while parser_self:peek().value ~= "}" do
			table.insert(body, parser_self:parse_statement())
		end
		parser_self:consume("}")
		return { type = "func", name = func_name, params = params, body = body }
	end)
end

function parser:build()
	local program = { type = "program", body = {} }
	while self:peek().type ~= "eof" do
		table.insert(program.body, self:parse_statement())
	end
	return program
end

-- parsers
do
	-- use this. this is the one you call first. it is the one that trickles down to all other parsers
	function parser:parse_expression(): types.node
		local left = self:parse_unary_expression()

		return self:parse_binary_expression(left, 0)
	end

	-- match statement to handler
	function parser:parse_statement()
		local token = self:peek()

		if token.type == "comment" then
			self:consume()
			return {
				type = "comment",
				value = token.value,
				is_block = token.is_block or false,
			}
		elseif token.type == "keyword" then
			if token.value == "if" then
				return self:parse_if_statement()
			elseif self.statement_parsers[token.value] then
				return self.statement_parsers[token.value][1](self, unpack(self.statement_parsers[token.value][2]))
			end
		elseif token.type == "id" then
			local name = self:consume().value
			local next_token = self:peek()

			if next_token.value == "(" then
				return self:parse_call(name)
			elseif next_token.value == "=" or next_token.value == "+=" or next_token.value == "-=" then
				return self:parse_assignment(name)
			end
		end

		error(`failed for statement at {token.value}`)
	end

	function parser:parse_call(callee: string)
		self:consume("(")
		local args = {}
		if self:peek().value ~= ")" then
			repeat
				table.insert(args, self:parse_expression())
				if self:peek().value == "," then
					self:consume(",")
				end
			until self:peek().value == ")"
		end
		self:consume(")")
		if self:peek().value == ";" then
			self:consume(";")
		end
		return { type = "call", callee = callee, arguments = args }
	end

	function parser:parse_binary_expression(left: types.node, min_prec: number): types.node
		while true do
			local token = self:peek()
			local prec = token.type == "symbol" and token_priority[token.value] or -1

			if prec < min_prec then
				break
			end

			local operator = self:consume().value
			local right = self:parse_primary()

			local next_prec = self:peek().type == "symbol" and token_priority[self:peek().value] or -1
			if prec < next_prec then
				right = self:parse_binary_expression(right, prec + 1)
			end

			left = { type = "binary", operator = operator, left = left, right = right }
		end
		return left
	end

	function parser:parse_unary_expression(): types.node
		local token = self:peek()
		if token.value == "-" or token.value == "!" then
			local operator = self:consume().value
			return {
				type = "unary",
				operator = operator,
				argument = self:parse_unary_expression(),
			}
		end
		return self:parse_primary()
	end

	function parser:parse_primary(): types.node
		local token = self:peek()

		if token.value == "(" then
			self:consume("(")
			local expr = self:parse_expression()
			self:consume(")")
			return { type = "parenthesis", expression = expr }
		elseif token.value == "{" then
			return self:parse_object_literal()
		end

		local lit = self:consume()
		if lit.type == "num" then
			return { type = "num", value = tonumber(lit.value) }
		elseif lit.type == "str" then
			return { type = "str", value = lit.value }
		elseif lit.type == "id" then
			if lit.value == "true" or lit.value == "false" then
				return { type = "bool", value = lit.value == "true" }
			end
			return { type = "id", name = lit.value }
		end

		error(`unexpected token in expression: {lit.value}`)
	end

	function parser:parse_object_literal(): types.node
		self:consume("{")
		local fields = {}
		if self:peek().value ~= "}" then
			repeat
				local field_name = self:consume().value
				self:consume(":")
				local field_value = self:parse_expression()
				table.insert(fields, { name = field_name, value = field_value })
				if self:peek().value == "," then
					self:consume(",")
				end
			until self:peek().value == "}"
		end
		self:consume("}")
		return { type = "object_literal", fields = fields }
	end

	function parser:parse_assignment(id: string)
		local operator = self:consume().value
		local value = self:parse_expression()
		if self:peek().value == ";" then
			self:consume(";")
		end
		return { type = "assign", id = id, operator = operator, value = value }
	end

	function parser:parse_if_statement()
		self:consume("if")
		self:consume("(")
		local test = self:parse_expression()
		self:consume(")")

		local consequent = self:parse_block()
		local alternate = nil

		if self:peek().value == "else" then
			self:consume("else")
			if self:peek().value == "if" then
				alternate = self:parse_if_statement()
			else
				alternate = self:parse_block()
			end
		end

		return { type = "if", test = test, consequent = consequent, alternate = alternate }
	end

	function parser:parse_block()
		self:consume("{")
		local body = {}
		while self:peek().value ~= "}" do
			local statement = self:parse_statement()
			if statement then
				table.insert(body, statement)
			end
		end
		self:consume("}")
		return { type = "block", body = body }
	end

	function parser:parse_type_expr(): any
		local token = self:peek()

		if token.value == "{" then
			return self:parse_object_type()
		elseif token.type == "str" then
			local value = self:consume().value
			return { kind = "literal", value = value }
		elseif token.type == "id" then
			local name = self:consume().value
			return { kind = "reference", name = name }
		end

		self:report_error(`unexpected token in type: {token.value}`)
		return nil
	end

	function parser:parse_object_type(): any
		self:consume("{")
		local fields = {}
		if self:peek().value ~= "}" then
			repeat
				local field_name = self:consume().value
				self:consume(":")
				local field_type = self:parse_type_expr()
				table.insert(fields, { name = field_name, field_type = field_type })
				if self:peek().value == "," then
					self:consume(",")
				end
			until self:peek().value == "}"
		end
		self:consume("}")
		return { kind = "object", fields = fields }
	end
end

return parser
