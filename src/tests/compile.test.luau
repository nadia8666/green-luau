local test = require("@std/test")
local helper = require("./compilation_helper")

-- TODO: stop string comparisons from trimming whitespace

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

	suite:case("variables.assignment", function(asserts)
		asserts.eq(
			[[local x = 1
x += 1
x -= 1]],
			helper.new([[let x = 1;
x += 1;
x -= 1;]])
		)
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

	suite:case("allStrings", function(asserts)
		asserts.eq(
			[[const string1 = `a`
const string2 = "b"
const string3 = 'c']],
			helper.new([[const string1 = `a`;
const string2 = "b";
const string3 = 'c';]])
		)
	end)

	suite:case("types.builtinModule", function(asserts)
		asserts.eq("debug.create(8)", helper.new("debug.create(8);"))
	end)

	suite:case("types.inference", function(asserts)
		asserts.eq(
			[[local x = 0
print(x)]],
			helper.new([[let x = 0; 
print(x);]])
		)
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

	suite:case("types.generics.genericFunction", function(asserts)
		asserts.eq(
			[[function test(x)
	return x
end
const x = test(1)]],
			helper.new([[function test<T>(x: T): T {
	return x;
}
const x: number = test<number>(1);]])
		)
	end)

	suite:case("types.generics.genericType", function(asserts)
		asserts.eq(
			'\nconst b = { value = "hi" }',
			helper.new([[type holder<T> = { value: T };
const b: holder<string> = { value: "hi" };]])
		)
	end)

	suite:case("types.generics.tupleType", function(asserts)
		asserts.eq(
			'\nconst p = { "age", 25 }',
			helper.new([[type pair = [string, number];
const p: pair = ["age", 25];]])
		)
	end)

	suite:case("types.generics.varargsFunction", function(asserts)
		asserts.eq(
			[[function sum(...)
	return 0
end
sum(1, 2, 3)]],
			helper.new([[function sum(...: number) {
	return 0;
}
sum(1, 2, 3);]])
		)
	end)

	suite:case("types.generics.genericMismatch1", function(asserts)
		asserts.throws(
			helper.new,
			[[function test<T>(x: T): T { return x; }
const x: string = test<number>(1);]]
		)
	end)

	suite:case("types.generics.genericMismatch2", function(asserts)
		asserts.throws(
			helper.new,
			[[function test<T>(x: T): T { return x; }
const x: number = test<string>(1);]]
		)
	end)

	suite:case("types.variadic.builtin", function(asserts)
		asserts.eq(
			'print(1, 2, "three")',
			helper.new([[print(1, 2, "three");]])
		)
	end)

	suite:case("types.variadic.max", function(asserts)
		asserts.eq(
			'const x = math.max(1, 2, 3)',
			helper.new([[const x: number = math.max(1, 2, 3);]])
		)
	end)

	suite:case("types.variadic.pcall", function(asserts)
		asserts.eq(
			'const ok = pcall(print, "hi", "luau", `green :)`)',
			helper.new([[const ok: any = pcall(print, "hi", "luau", `green :)`);]])
		)
	end)
end)
