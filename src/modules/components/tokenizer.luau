--!nonstrict

local types = require("../types")
local element = require("./element")

local lexer_element = setmetatable({}, element)
lexer_element.__index = lexer_element
local inst = setmetatable(element.new(), lexer_element)

local keywords = {
	"let",
	"const",
	"var",
	"function",
	"if",
	"else",
	"type",
	"return",
	"and",
	"or",
	"not",
}
local keyword_map = {}
for _, kw in keywords do
	keyword_map[kw] = true
end

local multi_symbols = { "==", "+=", "-=", "!=", "<=", ">=", "&&", "||", "..." }
local multi_map = {}
for _, sym in multi_symbols do
	multi_map[sym] = true
end

function lexer_element:tokenize(lexer: types.lexer): types.token?
	local char = lexer:peek()
	if string.match(char, "%s") then
		lexer:consume_char()
		return { type = "skip" } :: any
	elseif char == "/" and string.sub(lexer.input, lexer.cursor + 1, lexer.cursor + 1) == "/" then
		local start_line = lexer.line
		local start_column = lexer.column
		lexer:consume_char()
		lexer:consume_char()
		local start = lexer.cursor :: number
		while lexer.cursor <= lexer.length and lexer:peek() ~= "\n" do
			lexer:consume_char()
		end
		local value = string.sub(lexer.input, start, lexer.cursor - 1)
		return { type = "comment", value = value, line = start_line, column = start_column, is_block = false }
	elseif char == "/" and string.sub(lexer.input, lexer.cursor + 1, lexer.cursor + 1) == "*" then
		local start_line = lexer.line
		local start_column = lexer.column
		lexer:consume_char()
		lexer:consume_char()
		local start = lexer.cursor :: number
		while lexer.cursor <= lexer.length do
			if lexer:peek() == "*" and string.sub(lexer.input, lexer.cursor + 1, lexer.cursor + 1) == "/" then
				local value = string.sub(lexer.input, start, lexer.cursor - 1)
				lexer:consume_char()
				lexer:consume_char()
				return { type = "comment", value = value, line = start_line, column = start_column, is_block = true }
			else
				lexer:consume_char()
			end
		end
	elseif string.match(char, "[%a_]") then
		local start_line = lexer.line
		local start_column = lexer.column
		local start = lexer.cursor :: number
		while lexer.cursor <= lexer.length and string.match(lexer:peek(), "[%w_]") do
			lexer:consume_char()
		end
		local value = string.sub(lexer.input, start, lexer.cursor - 1)
		return {
			type = keyword_map[value] and "keyword" or "id",
			value = value,
			line = start_line,
			column = start_column,
		}
	elseif string.match(char, "%d") then
		local start_line = lexer.line
		local start_column = lexer.column
		local start = lexer.cursor :: number
		while lexer.cursor <= lexer.length and string.match(lexer:peek(), "%d") do
			lexer:consume_char()
		end
		local value = string.sub(lexer.input, start, lexer.cursor - 1)
		return { type = "num", value = value, line = start_line, column = start_column }
	elseif char == '"' or char == "'" or char == "`" then
		local start_line = lexer.line
		local start_column = lexer.column
		lexer:consume_char()
		local start = lexer.cursor :: number
		while lexer.cursor <= lexer.length and lexer:peek() ~= char do
			lexer:consume_char()
		end
		local value = string.sub(lexer.input, start, lexer.cursor - 1)
		lexer:consume_char()
		return { type = "str", value = value, quote = char, line = start_line, column = start_column }
	else
		local start_line = lexer.line
		local start_column = lexer.column
		local c = lexer:consume_char()
		local combined = c
		while true do
			local next_combined = combined .. lexer:peek()
			local found = false
			for symbol in multi_map do
				if typeof(symbol) == "number" or typeof(symbol) == "boolean" then
					continue
				end
				if symbol:sub(0, #next_combined) == next_combined then
					combined = next_combined
					found = true
					lexer:consume_char()
					break
				end
			end
			if not found then
				break
			end
		end
		if multi_map[combined] then
			return { type = "symbol", value = combined, line = start_line, column = start_column }
		end
		return { type = "symbol", value = c, line = start_line, column = start_column }
	end
	return nil
end

return inst
