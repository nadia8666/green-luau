export type token_type = "keyword" | "id" | "num" | "str" | "symbol" | "comment" | "eof"

export type token = {
	type: token_type,
	value: string,
	line: number,
	column: number,
}

export type node = {
	type: string,
	line: number,
	column: number,
	[string]: any, -- TODO: statically type all nodes
}

-- program is top level
export type tree = {
	body: { node },
	type: "program",
}

export type type_node = {
	kind: "builtin" | "reference" | "literal" | "object" | "function" | "union",
	[string]: any,
}

return {}
