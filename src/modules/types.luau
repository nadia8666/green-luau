export type token_type = "keyword" | "id" | "num" | "str" | "symbol" | "comment" | "eof"

export type token = {
	type: token_type,
	value: string,
	quote: string?,
	line: number,
	column: number,
	is_block: boolean?,
}

export type base_node = {
	type: string,
	line: number,
	column: number,
}

export type var_node = base_node & {
	type: "var",
	kind: string,
	id: string,
	init: node?,
	type_annotation: type_node?,
}

export type func_node = base_node & {
	type: "func",
	name: string,
	type_params: { string }?,
	params: { { name: string, type_annotation: type_node?, variadic: boolean? } },
	return_type: type_node?,
	body: { node },
}

export type call_node = base_node & {
	type: "call",
	callee: node,
	type_args: { type_node }?,
	arguments: { node },
}

export type num_node = base_node & {
	type: "num",
	value: number,
}

export type str_node = base_node & {
	type: "str",
	value: string,
	quote: string?,
}

export type bool_node = base_node & {
	type: "bool",
	value: boolean,
}

export type id_node = base_node & {
	type: "id",
	name: string,
}

export type parenthesis_node = base_node & {
	type: "parenthesis",
	expression: node,
}

export type member_node = base_node & {
	type: "member",
	object: node,
	property: string,
}

export type if_node = base_node & {
	type: "if",
	test: node,
	consequent: node,
	alternate: node?,
}

export type block_node = base_node & {
	type: "block",
	body: { node },
}

export type binary_node = base_node & {
	type: "binary",
	operator: string,
	left: node,
	right: node,
}

export type unary_node = base_node & {
	type: "unary",
	operator: string,
	argument: node,
}

export type assign_node = base_node & {
	type: "assign",
	left: node,
	operator: string,
	value: node,
}

export type return_node = base_node & {
	type: "return",
	value: node?,
}

export type comment_node = base_node & {
	type: "comment",
	value: string,
	is_block: boolean,
}

export type type_decl_node = base_node & {
	type: "type_decl",
	name: string,
	type_params: { string }?,
	type_def: type_node,
}

export type object_literal_node = base_node & {
	type: "object_literal",
	fields: { { name: string, value: node } },
}

export type tuple_literal_node = base_node & {
	type: "tuple_literal",
	values: { node },
}

export type variadic_node = base_node & {
	type: "variadic",
}

export type program_node = base_node & {
	type: "program",
	body: { node },
}

export type node =
	var_node
	| func_node
	| call_node
	| num_node
	| str_node
	| bool_node
	| id_node
	| parenthesis_node
	| member_node
	| if_node
	| block_node
	| binary_node
	| unary_node
	| assign_node
	| return_node
	| comment_node
	| type_decl_node
	| object_literal_node
	| tuple_literal_node
	| variadic_node
	| program_node

-- program is top level
export type tree = program_node

export type base_type_node = {
	kind: string,
	line: number?,
	column: number?,
}

export type builtin_type_node = base_type_node & {
	kind: "builtin",
	name: string,
}

export type reference_type_node = base_type_node & {
	kind: "reference",
	name: string,
	type_args: { type_node }?,
}

export type literal_type_node = base_type_node & {
	kind: "literal",
	value: any,
	quote: string?,
}

export type object_type_node = base_type_node & {
	kind: "object",
	fields: { [any]: type_node | { name: string, field_type: type_node } },
}

export type function_type_node = base_type_node & {
	kind: "function",
	params: { type_node },
	returns: type_node?,
	type_params: { string }?,
}

export type union_type_node = base_type_node & {
	kind: "union",
	types: { type_node },
}

export type tuple_type_node = base_type_node & {
	kind: "tuple",
	types: { type_node },
}

export type generic_type_node = base_type_node & {
	kind: "generic",
	name: string?,
	type_params: { string }?,
	inner: type_node?,
}

export type variadic_type_node = base_type_node & {
	kind: "variadic",
	inner: type_node,
}

export type type_node =
	builtin_type_node
	| reference_type_node
	| literal_type_node
	| object_type_node
	| function_type_node
	| union_type_node
	| tuple_type_node
	| generic_type_node
	| variadic_type_node

export type component = {
	new: () -> component,
	tokenize: (self: component, lexer: lexer) -> token,
	generate_node: (self: component, parser: parser) -> node,
	output: (self: component, transpiler: transpiler, node: node) -> string,
	type_check: (self: component, checker: type_checker, node: node) -> type_node,
	statement_keywords: { string }?,
	node_type: string?,
}
export type lexer = {
	new: (input: string) -> lexer,

	input: string,
	cursor: number,
	line: number,
	column: number,
	length: number,
	components: { component },

	peek: (self: lexer) -> string,
	consume_char: (self: lexer) -> string,
	build: (self: lexer) -> { token },

	__index: lexer,
}
export type parser = {
	new: (tokens: { token }) -> parser,

	tokens: { token },
	input: string,
	cursor: number,
	statement_parsers: { [string]: { ((parser) -> node) | { any } } },
	type_system: type_system,
	components: { component },

	peek: (self: parser) -> token,
	report_error: (self: parser, reason: string, is_json: boolean?) -> nil,
	consume: (self: parser, expected_value: string?) -> token,
	multi_consume: (self: parser, expected_values: { string }) -> { token },
	register_statement: (self: parser, keywords: string | { string }, handler: (parser) -> node, ...any) -> tree,
	register_defaults: (self: parser) -> nil,
	build: (self: parser) -> tree,

	parse_primary: (self: parser) -> node,
	parse_expression: (self: parser) -> node,
	parse_statement: (self: parser) -> node,
	parse_unary_expression: (self: parser) -> node,
	parse_block: (self: parser) -> node,

	__index: parser,
}
export type transpiler = {
	new: (ast: tree) -> transpiler,

	ast: tree,
	handlers: { [string]: (node) -> string },
	components: { component },

	register_handler: (self: transpiler, node_type: string, handler: (transpiler, node) -> string) -> nil,
	build_node: (self: transpiler, node: node) -> string,
	register_defaults: (self: transpiler) -> nil,
	transpile_type: (self: transpiler, t: type_node) -> string,
	build: (self: transpiler) -> nil,

	__index: transpiler,
}
export type diagnostic = {
	severity: string,
	message: string,
	line: number,
	column: number,
}
export type type_checker = {
	new: (type_system: type_system) -> type_checker,

	type_system: type_system,
	scopes: { { [string]: type_node } },
	type_scopes: { { [string]: type_node } },
	diagnostics: { diagnostic },
	handlers: { [string]: (node) -> string },
	components: { component },

	push_scope: (self: type_checker) -> nil,
	pop_scope: (self: type_checker) -> nil,
	current_scope: (self: type_checker) -> { [string]: type_node },
	declare_symbol: (self: type_checker, name: string, type_info: type_node) -> nil,
	lookup_symbol: (self: type_checker, name: string) -> type_node?,
	declare_type_symbol: (self: type_checker, name: string, type_info: type_node) -> nil,
	lookup_type_symbol: (self: type_checker, name: string) -> type_node?,
	get_type_name: (self: type_checker, t: type_node) -> string,
	resolve_type: (self: type_checker, type_expr: type_node) -> type_node,
	check_node: (self: type_checker, node: node) -> type_node?,
	add_diagnostic: (self: type_checker, severity: string, message: string, line: number, column: number) -> nil,
	get_diagnostics: (self: type_checker) -> { diagnostic },
	check_tree: (self: type_checker, ast: tree) -> { diagnostic },

	__index: type_checker,
}
export type type_system = {
	new: () -> type_system,

	types: tree,
	builtin_types: { [string]: type_node },
	components: { component },

	register_type: (self: type_system, name: string, type_def: type_node) -> nil,
	get_type: (self: type_system, name: string, resolver: ((string) -> type_node?)?) -> type_node?,
	resolve_type: (self: type_system, type_expr: type_node, resolver: ((string) -> type_node?)?) -> type_node,
	get_field: (self: type_system, obj_type: type_node, name: string) -> type_node?,
	check_assignable: (self: type_system, from: type_node, to: type_node) -> boolean,
	substitute: (self: type_system, type_expr: type_node, mapping: { [string]: type_node }) -> type_node,
	export_types: (self: type_system) -> { [string]: type_node },

	__index: type_system,
}

return {}
