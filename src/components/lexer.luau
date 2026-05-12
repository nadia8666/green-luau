local lexer = {}
lexer.__index = lexer

local keywords = {
	"let",
	"const",
	"var",
	"function",
	"if",
	"else",
}

for _, keyword_value in keywords do
	keywords[keyword_value] = true
end

function lexer.new(input: string)
	return setmetatable({
		input = input,
		cursor = 1,
		line = 1,
		column = 1,
		length = #input,
	}, lexer)
end

function lexer:peek()
	return string.sub(self.input, self.cursor, self.cursor)
end

-- read character and advance cursor
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
	local tokens = {}

	while self.cursor <= self.length do
		local char = self:peek()

		if string.match(char, "%s") then
			-- %s is whitespace
			self:consume_char()
		elseif string.match(char, "[%a_]") then
			-- generic
			local start = self.cursor
			while self.cursor <= self.length and string.match(self:peek(), "[%w_]") do
				self.cursor += 1
			end
			local value = string.sub(self.input, start, self.cursor - 1)
			table.insert(tokens, {
				type = keywords[value] and "keyword" or "id",
				value = value,
				line = self.line,
				column = self.column - #value,
			})
		elseif string.match(char, "%d") then
			-- number literals
			local start = self.cursor
			while self.cursor <= self.length and string.match(self:peek(), "%d") do
				self.cursor += 1
			end
			local value = string.sub(self.input, start, self.cursor - 1)
			table.insert(tokens, {
				type = "num",
				value = value,
				line = self.line,
				column = self.column - #value,
			})
		elseif char == '"' or char == "'" or char == "`" then
			-- string literal
			self:consume_char()
			local start = self.cursor
			while self.cursor <= self.length and self:peek() ~= char do
				self.cursor += 1
			end
			local value = string.sub(self.input, start, self.cursor - 1)
			self:consume_char()
			table.insert(tokens, {
				type = "str",
				value = value,
				line = self.line,
				column = self.column - #value,
			})
		else
			-- operators
			table.insert(tokens, self:make_symbol())
		end
	end

	table.insert(tokens, { type = "eof", value = "", line = self.line, column = self.column })
	return tokens
end

function lexer:make_symbol()
	local char = self:consume_char()
	local next_char = self:peek()
	local combined = char .. next_char

	local multi_symbols = {
		["=="] = true,
		["+="] = true,
		["-="] = true,
		["!="] = true,
		["<="] = true,
		[">="] = true,
	}

	if multi_symbols[combined] then
		self:consume_char()
		return { type = "symbol", value = combined, line = self.line, column = self.column - #combined }
	end

	return { type = "symbol", value = char, line = self.line, column = self.column - #char }
end

return lexer
