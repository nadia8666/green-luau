--!nonstrict

local registry = require("./components/registry")
local types = require("./types")

local lexer = {} :: types.lexer
lexer.__index = lexer

function lexer.new(input: string)
	return setmetatable({
		input = input,
		cursor = 1 :: number,
		line = 1,
		column = 1,
		length = #input,
		components = registry,
	}, lexer) :: types.lexer
end

function lexer:peek()
	return string.sub(self.input, self.cursor, self.cursor)
end

function lexer:consume_char()
	local char = self:peek()
	if char == "\n" then
		self.line += 1
		self.column = 1
	else
		self.column += 1
	end
	self.cursor += 1
	return char
end

function lexer:build()
	local tokens: { types.token } = {}

	while self.cursor <= self.length do
		local start_cursor = self.cursor
		local token = nil

		for _, component in self.components do
			if component.tokenize then
				token = component:tokenize(self)
				if token then
					break
				end
			end
		end

		if token then
			if token.type ~= "skip" then
				table.insert(tokens, token)
			end
		else
			if self.cursor == start_cursor then
				local char = self:consume_char()
				table.insert(tokens, { type = "symbol", value = char, line = self.line, column = self.column - 1 })
			end
		end
	end

	table.insert(tokens, { type = "eof", value = "", line = self.line, column = self.column })
	return tokens
end

return lexer
