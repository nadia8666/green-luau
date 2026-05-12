--!nonstrict

local parser = require("./components/parser")
local lexer = require("./components/lexer")
local transpiler = require("./components/transpiler")

local main = {}

function main.process(input: string): string?
	local success, output = pcall(function()
		local tokens = lexer.new(input):build()
		local ast = parser.new(tokens):build()
		local output = transpiler.new(ast):build()

		return output
	end)

	if not success then
		error(`file processing failed!\n{output}`)
	end

	return output
end

return main
