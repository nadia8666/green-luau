--!nonstrict

local types = require("./types")
local type_system = require("./type_system")
local json = require("@std/json")
local block = require("./components/block")
local assign = require("./components/assign")
local binary = require("./components/binary")
local call = require("./components/call")
local member = require("./components/member")
local id = require("./components/id")
local bool = require("./components/bool")
local num = require("./components/num")
local object_literal = require("./components/object_literal")
local parenthesis = require("./components/parenthesis")
local registry = require("./components/registry")
local str = require("./components/str")
local tuple_literal = require("./components/tuple_literal")
local unary = require("./components/unary")

local parser = {} :: types.parser
parser.__index = parser

function parser.new(tokens: { types.token })
	local self = setmetatable({
		tokens = tokens,
		cursor = 1,
		statement_parsers = {},
		type_system = type_system.new(),
		components = registry,
	}, parser)

	self:register_defaults()
	return self
end

function parser:peek()
	return self.tokens[self.cursor]
end

--[[
	report parsing errors
	use is_json if passing through a raw json error
]]
function parser:report_error(reason: string, is_json: boolean?)
	local log

	if is_json then
		log = reason
	else
		local token = self:peek()
		log = json.serialize({
			error_type = "PARSE",
			token = token,
			reason = reason,
		})
	end

	error(log, 0)
end

--[[
    read token and advance cursor
    fails if it encounters an unmatched symbol
]]
function parser:consume(expected_value: string?)
	local token = self.tokens[self.cursor]
	if expected_value and token.value ~= expected_value then
		self:report_error(json.serialize({
			error_type = "PARSE",
			token = token,
			reason = `expected "{expected_value}" but got "{token.value}"`,
		}))
	end
	self.cursor += 1
	return token
end

function parser:multi_consume(expected_values: { string })
	local tokens = {}

	for _, token in expected_values do
		table.insert(tokens, self:consume(token))
	end

	return tokens
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
	for _, comp in self.components do
		if comp.statement_keywords and comp.generate_node then
			for _, kw in comp.statement_keywords do
				self:register_statement(kw, function(p, ...)
					return comp:generate_node(p, ...)
				end)
			end
		end
	end
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
	function parser:parse_primary()
		local token = self:peek()
		local left

		if token.value == "(" then
			left = parenthesis:generate_node(self)
		elseif token.value == "{" then
			left = object_literal:generate_node(self)
		elseif token.value == "[" then
			left = tuple_literal:generate_node(self)
		elseif token.type == "num" then
			left = num:generate_node(self)
		elseif token.type == "str" then
			left = str:generate_node(self)
		elseif token.type == "id" then
			if token.value == "true" or token.value == "false" then
				left = bool:generate_node(self)
			else
				left = id:generate_node(self)
			end
		else
			self:report_error(
				json.serialize({
					error_type = "PARSE",
					token = token,
					reason = `unexpected token in expression: {token.value}`,
				}),
				true
			)
			return nil
		end

		while true do
			local next_token = self:peek()
			if next_token.value == "." then
				left = member:generate_node(self, left)
			elseif next_token.value == "(" or next_token.value == "<" then
				left = call:generate_node(self, left)
			else
				break
			end
		end

		return left
	end

	function parser:parse_expression()
		local left = self:parse_unary_expression()
		return binary:generate_node(self, left, 0)
	end

	function parser:parse_statement()
		local token = self:peek()

		if token.type == "comment" then
			self:consume()
			return {
				type = "comment",
				value = token.value,
				is_block = token.is_block or false,
				line = token.line,
				column = token.column,
			}
		elseif token.type == "keyword" then
			if self.statement_parsers[token.value] then
				return self.statement_parsers[token.value][1](self, unpack(self.statement_parsers[token.value][2]))
			end
		elseif token.type == "id" then
			local expr = self:parse_expression()
			local next_token = self:peek()

			if next_token.value == "=" or next_token.value == "+=" or next_token.value == "-=" then
				return assign:generate_node(self, expr)
			end

			if next_token.value == ";" then
				self:consume(";")
			end
			return expr
		end

		self:report_error(
			json.serialize({
				error_type = "PARSE",
				token = token,
				reason = `failed to parse statement: unexpected token "{token.value}"`,
			}),
			true
		)

		return nil
	end

	function parser:parse_unary_expression()
		return unary:generate_node(self)
	end

	function parser:parse_block()
		return block:generate_node(self)
	end
end

return parser
