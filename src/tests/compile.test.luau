local test = require("@std/test")
local helper = require("./compilation_helper")

test.suite("transpile", function(suite)
	suite:case("variables.var", function(asserts)
		asserts.eq("local x = 1", helper.new("var x = 1;"))
	end)

	suite:case("variables.let", function(asserts)
		asserts.eq("local x = 1", helper.new("let x = 1;"))
	end)

	suite:case("variables.const", function(asserts)
		asserts.eq("const x = 1", helper.new("const x = 1;"))
	end)

	suite:case("types.noTranspileTypes", function(asserts)
		asserts.eq(
			[[]],
			helper.new([[type test = {
    test: string,
    num: number,
    strliteral: "strliteral",
};]])
		)
	end)

	suite:case("types.throwsMissingType", function(asserts)
		asserts.throws(
			helper.new,
			[[type test = {
    test: string,
    num: number,
    strliteral: "strliteral",
};

const test_value: other = {
    test: "hi",
    num: 1,
    strliteral: "strliteral"
};]]
		)
	end)

	suite:case("types.throwsTypeMismatch", function(asserts)
		asserts.throws(
			helper.new,
			[[function test(a: string, b: number) {}
test(0, 1)]]
		)
	end)

	suite:case("types.throwsArgmentCountMismatch", function(asserts)
		asserts.throws(
			helper.new,
			[[function test(a: string, b: number) {}
test(0, 0, 0)]]
		)
	end)

	suite:case("types.validReference", function(asserts)
		asserts.eq(
			[[const x = 0
print(x)]],
			helper.new([[const x = 0;
print(x);]])
		)
	end)

	suite:case("types.builtin", function(asserts)
		asserts.eq('print("hi green luau")', helper.new('print("hi green luau")'))
	end)

	suite:case("transpiler.allStrings", function(asserts)
		asserts.eq([[const string1 = `a`
const string2 = "b"
const string3 = 'c']], helper.new([[const string1 = `a`;
const string2 = "b";
const string3 = 'c';]]))
	end)

	suite:case("types.builtinModule", function(asserts)
		asserts.eq("debug.create(8)", helper.new("debug.create(8);"))
	end)

	suite:case("types.inference", function(asserts)
		asserts.eq("local x = 0\nprint(x)", helper.new("let x = 0; print(x);"))
	end)

	suite:case("types.buildsTypes", function(asserts)
		asserts.eq(
			'\nconst test_value = { test = "hi", num = 1, strliteral = "strliteral" }',
			helper.new([[type test = {
    test: string,
    num: number,
    strliteral: "strliteral",
};

const test_value: test = {
    test: "hi",
    num: 1,
    strliteral: "strliteral"
};]])
		)
	end)
end)