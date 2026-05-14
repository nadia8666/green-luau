--!nonstrict

local types = require("./types")
local builtins = {
	types = {},
	globals = {},
}

function declare_type(name: string, node: types.type_node)
	builtins.types[name] = node
end

function declare_global(name: string, node: types.type_node)
	builtins.globals[name] = node
end

function builtins.get_types()
	return builtins.types
end

function builtins.get_globals()
	return builtins.globals
end

function builtins.get()
    local all = {}
    for k, v in builtins.types do all[k] = v end
    for k, v in builtins.globals do all[k] = v end
	return all
end

local kind = {
	["object"] = "object",
	["function"] = "function",
	["builtin"] = "builtin",
}

local any_type = { kind = kind.builtin, name = "any" }
local string_type = { kind = kind.builtin, name = "string", value = "" }
local number_type = { kind = kind.builtin, name = "number", value = 0 }
local boolean_type = { kind = kind.builtin, name = "boolean", value = false }
local table_type = { kind = kind.builtin, name = "table" }
local thread_type = { kind = kind.builtin, name = "thread" }
local buffer_type = { kind = kind.builtin, name = "buffer" }
local vector_type = { kind = kind.builtin, name = "vector" }
local userdata_type = { kind = kind.builtin, name = "userdata" }

declare_type("any", any_type)
declare_type("string", string_type)
declare_type("number", number_type)
declare_type("boolean", boolean_type)
declare_type("table", table_type)
declare_type("thread", thread_type)
declare_type("buffer", buffer_type)
declare_type("vector", vector_type)
declare_type("userdata", userdata_type)

declare_global("print", { kind = kind["function"], params = { { kind = "variadic", inner = any_type } } })
declare_global("warn", { kind = kind["function"], params = { { kind = "variadic", inner = any_type } } })
declare_global("error", { kind = kind["function"], params = { any_type, number_type } })
declare_global("assert", { kind = kind["function"], params = { any_type, string_type } })
declare_global("gcinfo", { kind = kind["function"], params = {}, returns = number_type })
declare_global("getfenv", { kind = kind["function"], params = { any_type }, returns = table_type })
declare_global("getmetatable", { kind = kind["function"], params = { any_type }, returns = table_type })
declare_global("next", { kind = kind["function"], params = { table_type, any_type }, returns = any_type })
declare_global("newproxy", { kind = kind["function"], params = { boolean_type }, returns = userdata_type })
declare_global("rawequal", { kind = kind["function"], params = { any_type, any_type }, returns = boolean_type })
declare_global("rawget", { kind = kind["function"], params = { table_type, any_type }, returns = any_type })
declare_global("rawlen", { kind = kind["function"], params = { any_type }, returns = number_type })
declare_global("rawset", { kind = kind["function"], params = { table_type, any_type, any_type }, returns = table_type })
declare_global("select", { kind = kind["function"], params = { any_type, { kind = "variadic", inner = any_type } }, returns = any_type })
declare_global("setfenv", { kind = kind["function"], params = { any_type, table_type }, returns = table_type })
declare_global("setmetatable", { kind = kind["function"], params = { table_type, table_type }, returns = table_type })
declare_global("tonumber", { kind = kind["function"], params = { string_type, number_type }, returns = number_type })
declare_global("tostring", { kind = kind["function"], params = { any_type }, returns = string_type })
declare_global("type", { kind = kind["function"], params = { any_type }, returns = string_type })
declare_global("typeof", { kind = kind["function"], params = { any_type }, returns = string_type })
declare_global("ipairs", { kind = kind["function"], params = { table_type }, returns = any_type })
declare_global("pairs", { kind = kind["function"], params = { table_type }, returns = any_type })
declare_global("pcall", { kind = kind["function"], params = { { kind = kind["function"], params = {} }, { kind = "variadic", inner = any_type } }, returns = any_type })
declare_global("xpcall", { kind = kind["function"], params = { { kind = kind["function"], params = {} }, { kind = kind["function"], params = {} }, { kind = "variadic", inner = any_type } }, returns = any_type })
declare_global("unpack", { kind = kind["function"], params = { table_type, number_type, number_type }, returns = any_type })

declare_global("math", {
	kind = kind.object,
	fields = {
		{ name = "abs", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "acos", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "asin", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "atan2", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "atan", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "ceil", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "cosh", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "cos", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "deg", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "exp", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "floor", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "fmod", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "frexp", field_type = { kind = kind["function"], params = { number_type }, returns = any_type } },
		{ name = "ldexp", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "lerp", field_type = { kind = kind["function"], params = { number_type, number_type, number_type }, returns = number_type } },
		{ name = "map", field_type = { kind = kind["function"], params = { number_type, number_type, number_type, number_type, number_type }, returns = number_type } },
		{ name = "log10", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "log", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "max", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = number_type } }, returns = number_type } },
		{ name = "min", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = number_type } }, returns = number_type } },
		{ name = "modf", field_type = { kind = kind["function"], params = { number_type }, returns = any_type } },
		{ name = "pow", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "rad", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "random", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "randomseed", field_type = { kind = kind["function"], params = { number_type } } },
		{ name = "sinh", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "sin", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "sqrt", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "tanh", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "tan", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "noise", field_type = { kind = kind["function"], params = { number_type, number_type, number_type }, returns = number_type } },
		{ name = "clamp", field_type = { kind = kind["function"], params = { number_type, number_type, number_type }, returns = number_type } },
		{ name = "sign", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "round", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "pi", field_type = number_type },
		{ name = "huge", field_type = number_type },
	},
})

declare_global("table", {
	kind = kind.object,
	fields = {
		{ name = "concat", field_type = { kind = kind["function"], params = { table_type, string_type, number_type, number_type }, returns = string_type } },
		{ name = "insert", field_type = { kind = kind["function"], params = { table_type, any_type, any_type } } },
		{ name = "remove", field_type = { kind = kind["function"], params = { table_type, number_type }, returns = any_type } },
		{ name = "sort", field_type = { kind = kind["function"], params = { table_type, any_type } } },
		{ name = "pack", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = any_type } }, returns = table_type } },
		{ name = "unpack", field_type = { kind = kind["function"], params = { table_type, number_type, number_type }, returns = any_type } },
		{ name = "move", field_type = { kind = kind["function"], params = { table_type, number_type, number_type, number_type, table_type }, returns = table_type } },
		{ name = "create", field_type = { kind = kind["function"], params = { number_type, any_type }, returns = table_type } },
		{ name = "find", field_type = { kind = kind["function"], params = { table_type, any_type, number_type }, returns = number_type } },
		{ name = "clear", field_type = { kind = kind["function"], params = { table_type } } },
		{ name = "freeze", field_type = { kind = kind["function"], params = { table_type }, returns = table_type } },
		{ name = "isfrozen", field_type = { kind = kind["function"], params = { table_type }, returns = boolean_type } },
		{ name = "clone", field_type = { kind = kind["function"], params = { table_type }, returns = table_type } },
	},
})

declare_global("string", {
	kind = kind.object,
	fields = {
		{ name = "byte", field_type = { kind = kind["function"], params = { string_type, number_type, number_type }, returns = any_type } },
		{ name = "char", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = number_type } }, returns = string_type } },
		{ name = "find", field_type = { kind = kind["function"], params = { string_type, string_type, number_type, boolean_type }, returns = any_type } },
		{ name = "format", field_type = { kind = kind["function"], params = { string_type, { kind = "variadic", inner = any_type } }, returns = string_type } },
		{ name = "gmatch", field_type = { kind = kind["function"], params = { string_type, string_type }, returns = any_type } },
		{ name = "gsub", field_type = { kind = kind["function"], params = { string_type, string_type, any_type, number_type }, returns = any_type } },
		{ name = "len", field_type = { kind = kind["function"], params = { string_type }, returns = number_type } },
		{ name = "lower", field_type = { kind = kind["function"], params = { string_type }, returns = string_type } },
		{ name = "match", field_type = { kind = kind["function"], params = { string_type, string_type, number_type }, returns = any_type } },
		{ name = "rep", field_type = { kind = kind["function"], params = { string_type, number_type }, returns = string_type } },
		{ name = "reverse", field_type = { kind = kind["function"], params = { string_type }, returns = string_type } },
		{ name = "sub", field_type = { kind = kind["function"], params = { string_type, number_type, number_type }, returns = string_type } },
		{ name = "upper", field_type = { kind = kind["function"], params = { string_type }, returns = string_type } },
		{ name = "split", field_type = { kind = kind["function"], params = { string_type, string_type }, returns = table_type } },
		{ name = "pack", field_type = { kind = kind["function"], params = { string_type, { kind = "variadic", inner = any_type } }, returns = string_type } },
		{ name = "packsize", field_type = { kind = kind["function"], params = { string_type }, returns = number_type } },
		{ name = "unpack", field_type = { kind = kind["function"], params = { string_type, string_type }, returns = any_type } },
	},
})

declare_global("coroutine", {
	kind = kind.object,
	fields = {
		{ name = "create", field_type = { kind = kind["function"], params = { { kind = kind["function"], params = {} } }, returns = thread_type } },
		{ name = "running", field_type = { kind = kind["function"], params = {}, returns = thread_type } },
		{ name = "status", field_type = { kind = kind["function"], params = { thread_type }, returns = string_type } },
		{ name = "wrap", field_type = { kind = kind["function"], params = { { kind = kind["function"], params = {} } }, returns = any_type } },
		{ name = "yield", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = any_type } }, returns = any_type } },
		{ name = "isyieldable", field_type = { kind = kind["function"], params = {}, returns = boolean_type } },
		{ name = "resume", field_type = { kind = kind["function"], params = { thread_type, { kind = "variadic", inner = any_type } }, returns = any_type } },
		{ name = "close", field_type = { kind = kind["function"], params = { thread_type }, returns = any_type } },
	},
})

declare_global("bit32", {
	kind = kind.object,
	fields = {
		{ name = "arshift", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "band", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = number_type } }, returns = number_type } },
		{ name = "bnot", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "bor", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = number_type } }, returns = number_type } },
		{ name = "bxor", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = number_type } }, returns = number_type } },
		{ name = "btest", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = number_type } }, returns = boolean_type } },
		{ name = "extract", field_type = { kind = kind["function"], params = { number_type, number_type, number_type }, returns = number_type } },
		{ name = "lrotate", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "lshift", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "replace", field_type = { kind = kind["function"], params = { number_type, number_type, number_type, number_type }, returns = number_type } },
		{ name = "rrotate", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "rshift", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "countlz", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "countrz", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
		{ name = "byteswap", field_type = { kind = kind["function"], params = { number_type }, returns = number_type } },
	},
})

declare_global("utf8", {
	kind = kind.object,
	fields = {
		{ name = "offset", field_type = { kind = kind["function"], params = { string_type, number_type, number_type }, returns = number_type } },
		{ name = "codepoint", field_type = { kind = kind["function"], params = { string_type, number_type, number_type }, returns = any_type } },
		{ name = "char", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = number_type } }, returns = string_type } },
		{ name = "len", field_type = { kind = kind["function"], params = { string_type, number_type, number_type }, returns = any_type } },
		{ name = "codes", field_type = { kind = kind["function"], params = { string_type }, returns = any_type } },
	},
})

declare_global("os", {
	kind = kind.object,
	fields = {
		{ name = "clock", field_type = { kind = kind["function"], params = {}, returns = number_type } },
		{ name = "date", field_type = { kind = kind["function"], params = { string_type, number_type }, returns = any_type } },
		{ name = "difftime", field_type = { kind = kind["function"], params = { number_type, number_type }, returns = number_type } },
		{ name = "time", field_type = { kind = kind["function"], params = { table_type }, returns = number_type } },
	},
})

declare_global("debug", {
	kind = kind.object,
	fields = {
		{ name = "info", field_type = { kind = kind["function"], params = { any_type, any_type, string_type }, returns = any_type } },
		{ name = "traceback", field_type = { kind = kind["function"], params = { any_type, string_type, number_type }, returns = string_type } },
		{ name = "create", field_type = { kind = kind["function"], params = { number_type }, returns = any_type } },
	},
})

declare_global("buffer", {
	kind = kind.object,
	fields = {
		{ name = "create", field_type = { kind = kind["function"], params = { number_type }, returns = buffer_type } },
		{ name = "fromstring", field_type = { kind = kind["function"], params = { string_type }, returns = buffer_type } },
		{ name = "tostring", field_type = { kind = kind["function"], params = { buffer_type }, returns = string_type } },
		{ name = "len", field_type = { kind = kind["function"], params = { buffer_type }, returns = number_type } },
		{ name = "readi8", field_type = { kind = kind["function"], params = { buffer_type, number_type }, returns = number_type } },
		{ name = "readu8", field_type = { kind = kind["function"], params = { buffer_type, number_type }, returns = number_type } },
		{ name = "readi16", field_type = { kind = kind["function"], params = { buffer_type, number_type }, returns = number_type } },
		{ name = "readu16", field_type = { kind = kind["function"], params = { buffer_type, number_type }, returns = number_type } },
		{ name = "readi32", field_type = { kind = kind["function"], params = { buffer_type, number_type }, returns = number_type } },
		{ name = "readu32", field_type = { kind = kind["function"], params = { buffer_type, number_type }, returns = number_type } },
		{ name = "readf32", field_type = { kind = kind["function"], params = { buffer_type, number_type }, returns = number_type } },
		{ name = "readf64", field_type = { kind = kind["function"], params = { buffer_type, number_type }, returns = number_type } },
		{ name = "writei8", field_type = { kind = kind["function"], params = { buffer_type, number_type, number_type } } },
		{ name = "writeu8", field_type = { kind = kind["function"], params = { buffer_type, number_type, number_type } } },
		{ name = "writei16", field_type = { kind = kind["function"], params = { buffer_type, number_type, number_type } } },
		{ name = "writeu16", field_type = { kind = kind["function"], params = { buffer_type, number_type, number_type } } },
		{ name = "writei32", field_type = { kind = kind["function"], params = { buffer_type, number_type, number_type } } },
		{ name = "writeu32", field_type = { kind = kind["function"], params = { buffer_type, number_type, number_type } } },
		{ name = "writef32", field_type = { kind = kind["function"], params = { buffer_type, number_type, number_type } } },
		{ name = "writef64", field_type = { kind = kind["function"], params = { buffer_type, number_type, number_type } } },
		{ name = "readstring", field_type = { kind = kind["function"], params = { buffer_type, number_type, number_type }, returns = string_type } },
		{ name = "writestring", field_type = { kind = kind["function"], params = { buffer_type, number_type, string_type, number_type } } },
		{ name = "copy", field_type = { kind = kind["function"], params = { buffer_type, number_type, buffer_type, number_type, number_type } } },
		{ name = "fill", field_type = { kind = kind["function"], params = { buffer_type, number_type, number_type, number_type } } },
	},
})

declare_global("vector", {
	kind = kind.object,
	fields = {
		{ name = "zero", field_type = vector_type },
		{ name = "one", field_type = vector_type },
		{ name = "create", field_type = { kind = kind["function"], params = { number_type, number_type, number_type, number_type }, returns = vector_type } },
		{ name = "magnitude", field_type = { kind = kind["function"], params = { vector_type }, returns = number_type } },
		{ name = "normalize", field_type = { kind = kind["function"], params = { vector_type }, returns = vector_type } },
		{ name = "cross", field_type = { kind = kind["function"], params = { vector_type, vector_type }, returns = vector_type } },
		{ name = "dot", field_type = { kind = kind["function"], params = { vector_type, vector_type }, returns = number_type } },
		{ name = "angle", field_type = { kind = kind["function"], params = { vector_type, vector_type, vector_type }, returns = number_type } },
		{ name = "floor", field_type = { kind = kind["function"], params = { vector_type }, returns = vector_type } },
		{ name = "ceil", field_type = { kind = kind["function"], params = { vector_type }, returns = vector_type } },
		{ name = "abs", field_type = { kind = kind["function"], params = { vector_type }, returns = vector_type } },
		{ name = "sign", field_type = { kind = kind["function"], params = { vector_type }, returns = vector_type } },
		{ name = "clamp", field_type = { kind = kind["function"], params = { vector_type, vector_type, vector_type }, returns = vector_type } },
		{ name = "max", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = vector_type } }, returns = vector_type } },
		{ name = "min", field_type = { kind = kind["function"], params = { { kind = "variadic", inner = vector_type } }, returns = vector_type } },
	},
})

table.freeze(builtins)

return builtins
