--!nonstrict

local util = {
	debug_mode = false
}

function util.format_table(tab: { any }, indents: number): string
	local out = "{\n"
	local outer_spacing = string.rep("  ", indents)
	local inner_spacing = string.rep("  ", indents + 1)

	for key, value in tab do
		local formatted_key = type(key) == "string" and key or `[{key}]`
		local formatted_value = ""

		if typeof(value) == "table" then
			formatted_value = util.format_table(value, indents + 1)
		else
			formatted_value = typeof(value) == "string" and `"{value}"` or tostring(value)
		end

		out ..= `{inner_spacing}{formatted_key} = {formatted_value},\n`
	end

	return `{out}{outer_spacing}}`
end

function util.print(...: any)
	if not util.debug_mode then return end

	local arg_count = select("#", ...)
	local args = { ... }

	local out = ""

	for index = 1, arg_count do
		local target = args[index]

		out ..= `{index > 1 and " " or ""}{typeof(target) == "table" and util.format_table(target, 0) or target}`
	end

	print(out)

	return out
end

util.table = {}
function util.table.concat_up_to(entries: { [number]: string }, index: number, separator: string)
	local out = ""

	for idx = 1, #entries do
		if idx > index then
			break
		end
		local value = entries[idx]
		out ..= `{idx > 1 and separator or ""}{value}`
	end

	return out
end

local formatting = {
	reset = "\27[0m",
	bold = "\27[1m",
	
	r = "\27[31m",
	y = "\27[33m",
	b = "\27[34m",
	g = "\27[90m",
}

function util.pretty_diagnostics(diagnostics: {[number]: {severity: string, message: string, line: number?, column: number?}})
	local out = ""
	for i, diag in diagnostics do
		local color = diag.severity == "error" and formatting.r or formatting.y
		local label = `{formatting.bold}{color}{diag.severity:upper()}{formatting.reset}`
		
		local pos = ""
		if diag.line and diag.column then
			pos = `{formatting.g}[{diag.line}:{diag.column}]{formatting.reset} `
		end

		local line_entry = `{label} {pos}{diag.message}`
		out ..= `{line_entry}{(i < #diagnostics and "\n" or "")}`
	end

	return out
end

return util
