--!strict

local registry = {}

table.insert(registry, require("./var"))
table.insert(registry, require("./type_decl"))
table.insert(registry, require("./return"))
table.insert(registry, require("./func"))
table.insert(registry, require("./if"))
table.insert(registry, require("./block"))
table.insert(registry, require("./assign"))
table.insert(registry, require("./call"))
table.insert(registry, require("./binary"))
table.insert(registry, require("./unary"))
table.insert(registry, require("./parenthesis"))
table.insert(registry, require("./member"))
table.insert(registry, require("./num"))
table.insert(registry, require("./str"))
table.insert(registry, require("./bool"))
table.insert(registry, require("./id"))
table.insert(registry, require("./object_literal"))
table.insert(registry, require("./tuple_literal"))
table.insert(registry, require("./variadic"))
table.insert(registry, require("./tokenizer"))
table.insert(registry, require("./comment"))
table.insert(registry, require("./program"))

return registry
