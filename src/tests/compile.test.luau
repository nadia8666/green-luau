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
--[[
let x = 1;
let y = 0;
var variable = true;
print("hello world", x, y);

function test(a, b, c) {
    let x = 5;
    const a = true;
    warn(a)
}

const abc = test;
abc(0, 0, 0);

y += 1;
y -= 3;
y = -1;
y = -y;

if (x == y) {
    error("it shouldnt :(")
}

if (true == true) {
    print("hi")
} else if (false == true) {
    warn("not cool!")
}

test(x, y, -5)
test("hi", "green", "luau")

let x = (3 - 5) * (1 - 5) - 3 * 8/2 + (7 * 1);
const a = x * 2;
y = y ^ 2;

j = 2;

// hi
/*
this is a block!
*/

// im green!
function test2() {
    // green
    /*
        increasingly green documentation.
        eco mode is a feature
    */
}

type test = {
    test: string,
    num: number,
    strliteral: "strliteral",
};

const test_value: test = {
    test: "hi",
    num: 1,
    strliteral: "strliteral"
};

function vec(x: string, y: number, t: x, z: "h") {

}

vec("a", 0, x, "h");

//if (true && false) {
//    let vvvvv: boolean = x == 1 || false;
//}]]
