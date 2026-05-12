export type token_type = "keyword" | "id" | "num" | "str" | "symbol" | "eof"

export type token = {
	type: token_type,
	value: string,
	line: number,
	column: number,
}

export type node = {
	type: string,
	[string]: any, -- TODO: statically type all nodes
}

-- program is top level
export type tree = {
	body: { node },
	type: "program",
}

return {}
