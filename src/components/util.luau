--!nonstrict

local util = {}

function util.format_table(tab: { any }, indents: number): string
	local out = "{\n"
	local outer_spacing = string.rep("  ", indents)
	local inner_spacing = string.rep("  ", indents + 1)

	for key, value in pairs(tab) do
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
	local arg_count = select("#", ...)
	local args = { ... }

	local out = ""

	for index = 1, arg_count do
		local target = args[index]

		out = `{out}{index > 1 and " " or ""}{typeof(target) == "table" and util.format_table(target, 0) or target}`
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
		out = `{out}{idx > 1 and separator or ""}{value}`
	end

	return out
end

return util
