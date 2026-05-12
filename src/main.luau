--!nonstrict

local parser = require("./components/parser")
local lexer = require("./components/lexer")
local transpiler = require("./components/transpiler")
local type_checker = require("./components/type_checker")
local type_system = require("./components/type_system")

local main = {}

--[[
	transpile glua code into luau
	returns success, and either the compiled code on success or the returned error
]]
function main.transpile(input: string): (boolean, string)
	local success, output = pcall(function()
		local tokens = lexer.new(input):build()
		local ast = parser.new(tokens):build()
		local output = transpiler.new(ast):build()

		return output
	end)

	return success, output
end

function main.check(input: string): { diagnostics: any, ast: any? }
	local ts = type_system.new()

	local success, result = pcall(function()
		local tokens = lexer.new(input):build()
		local ast = parser.new(tokens):build()
		local checker = type_checker.new(ts)
		local diagnostics = checker:check_tree(ast)

		return { diagnostics = diagnostics, ast = ast }
	end)

	if not success then
		return {
			diagnostics = {
				{
					severity = "error",
					message = tostring(result),
					line = 1,
					column = 1,
				},
			},
		}
	end

	return result
end

function main.run_full(input: string): (boolean, string, string)
	local ts = type_system.new()
	local stage = "TOKENIZE"

	local ast
	local pre_success, result = pcall(function()
		local tokens = lexer.new(input):build()
		stage = "PARSE"
		ast = parser.new(tokens):build()
		
		stage = "TYPE_CHECK"
		local checker = type_checker.new(ts)
		local diagnostics = checker:check_tree(ast)

		return { diagnostics = diagnostics, ast = ast }
	end)

	if pre_success and ast then
		local success, output = pcall(function()
			return transpiler.new(ast):build()
		end)

		return success, output, "TRANSPILE"
	else
		return false, typeof(result) == "table" and result.diagnostics or result, stage
	end
end

return main
