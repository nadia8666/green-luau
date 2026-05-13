--!nonstrict

local types = require("./types")

local transpiler = {}
transpiler.__index = transpiler

function transpiler.new(ast: types.tree)
	local self = setmetatable({
		ast = ast,
		handlers = {},
	}, transpiler)

	self:register_defaults()
	return self
end

function transpiler:register_handler(node_type: string, handler: (typeof(transpiler.new(nil)), types.node) -> string)
	self.handlers[node_type] = handler
end

function transpiler:build_node(node: types.node): string
	local handler = self.handlers[node.type]
	if not handler then
		error(`no handler for node of type: {node.type}`)
	end
	return handler(self, node)
end

function transpiler:register_defaults()
	self:register_handler("program", function(self, node)
		local lines = {}
		for _, stmt in node.body do
			table.insert(lines, self:build_node(stmt))
		end
		return table.concat(lines, "\n")
	end)

	self:register_handler("var", function(self, node)
		local luau_keyword = (node.kind == "let" or node.kind == "var") and "local"
			or (node.kind == "const") and "const"
			or ""
		return `{luau_keyword} {node.id} = {self:build_node(node.init)}`
	end)

	self:register_handler("func", function(self, node)
		local param_names = {}
		for _, param in node.params do
			if typeof(param) == "table" then
				table.insert(param_names, param.name)
			else
				table.insert(param_names, param)
			end
		end
		local params = table.concat(param_names, ", ")
		local body_lines = {}
		for _, stmt in node.body do
			table.insert(body_lines, `  {self:build_node(stmt)}`)
		end
		local body = table.concat(body_lines, "\n")
		return `function {node.name}({params})\n{body}\nend`
	end)

	self:register_handler("call", function(self, node)
		local args = {}
		for _, arg in node.arguments do
			table.insert(args, self:build_node(arg))
		end
		return `{node.callee}({table.concat(args, ", ")})`
	end)

	self:register_handler("num", function(self, node)
		return tostring(node.value)
	end)

	self:register_handler("str", function(self, node)
		return `"{node.value}"`
	end)

	self:register_handler("bool", function(self, node)
		return `{node.value}`
	end)

	self:register_handler("id", function(self, node)
		return node.name
	end)

	self:register_handler("parenthesis", function(self, node)
		return `({self:build_node(node.expression)})`
	end)

	self:register_handler("if", function(self, node)
		local out = `if {self:build_node(node.test)} then\n{self:build_node(node.consequent)}`

		if node.alternate then
			if node.alternate.type == "if" then
				local alt = self:build_node(node.alternate)
				alt = alt:sub(4, -5)
				out ..= `\nelseif {alt}`
			else
				out ..= `\nelse\n{self:build_node(node.alternate)}`
			end
		end

		return out .. "\nend"
	end)

	self:register_handler("block", function(self, node)
		local lines = {}
		for _, stmt in node.body do
			table.insert(lines, `  {self:build_node(stmt)}`)
		end
		return table.concat(lines, "\n")
	end)

	self:register_handler("binary", function(self, node)
		local operator = node.operator
		if operator == "!=" then
			operator = "~="
		elseif operator == "&&" then
			operator = "and"
		elseif operator == "||" then
			operator = "or"
		end
		return `{self:build_node(node.left)} {operator} {self:build_node(node.right)}`
	end)

	self:register_handler("unary", function(self, node)
		local op = node.operator == "!" and "not " or node.operator
		return `{op}{self:build_node(node.argument)}`
	end)

	self:register_handler("assign", function(self, node)
		return `{node.id} {node.operator} {self:build_node(node.value)}`
	end)

	self:register_handler("comment", function(self, node)
		if node.is_block then
			return `--[[{node.value}]]`
		else
			return `--{node.value}`
		end
	end)

	self:register_handler("type_decl", function(self, node)
		return ""
	end)

	self:register_handler("object_literal", function(self, node)
		local pairs = {}
		for _, field in node.fields do
			table.insert(pairs, `{field.name} = {self:build_node(field.value)}`)
		end
		return "{ " .. table.concat(pairs, ", ") .. " }"
	end)
end

function transpiler:build()
	return self:build_node(self.ast)
end

return transpiler
