local assertEq = require("@testing/assertEq")
local describe = require("@testing/describe")
local test = require("@testing/test")

local Option = require(".")

describe("Some", function()
	test("returns an option containing the given value", function()
		local option = Option.Some(1)
		assertEq(option._s, true)
		assertEq(option._v, 1)
	end)
end)

describe("from", function()
	test("returns Some if the value is not nil", function()
		local option = Option.from(1)
		assertEq(option, Option.Some(1))
	end)

	test("returns None if the value is nil", function()
		local option = Option.from(nil)
		assertEq(option, Option.None)
	end)
end)

describe("is", function()
	test("returns true when given an option", function()
		assertEq(Option.is(Option.Some(5)), true)
		assertEq(Option.is(Option.None), true)
	end)

	test("returns false when given a non-option", function()
		assertEq(Option.is(5), false)
		assertEq(Option.is("hello"), false)
		assertEq(Option.is({}), false)
		assertEq(Option.is(function() end), false)
	end)
end)

describe("isSome", function()
	test("returns true if the option is Some", function()
		assertEq(Option.Some(5):isSome(), true)
	end)

	test("returns false if the option is None", function()
		assertEq(Option.None:isSome(), false)
	end)
end)

describe("isSomeAnd", function()
	test("returns true if the option is Some and the predicate is true", function()
		assertEq(
			Option.Some(5):isSomeAnd(function(value)
				return value == 5
			end),
			true
		)
	end)

	test("returns false if the option is Some and the predicate is false", function()
		assertEq(
			Option.Some(5):isSomeAnd(function(value)
				return value == 10
			end),
			false
		)
	end)

	test("returns false if the option is None", function()
		assertEq(
			Option.None:isSomeAnd(function(value)
				return value == 5
			end),
			false
		)
	end)
end)

describe("isNone", function()
	test("returns true if the option is None", function()
		assertEq(Option.None:isNone(), true)
	end)

	test("returns false if the option is Some", function()
		assertEq(Option.Some(5):isNone(), false)
	end)
end)

describe("expect", function()
	test("returns the value if the option is Some", function()
		assertEq(Option.Some(5):expect("hello"), 5)
	end)

	test("errors if the option is None", function()
		local success, err = pcall(Option.None.expect, Option.None, "hello")
		assertEq(success, false)
		assertEq(err, "hello")
	end)
end)

describe("unwrap", function()
	test("returns the value if the option is Some", function()
		assertEq(Option.Some(5):unwrap(), 5)
	end)

	test("errors if the option is None", function()
		local success, err = pcall(Option.None.unwrap, Option.None)
		assertEq(success, false)
		assertEq(err, "called `Option.unwrap()` on a `None` value")
	end)
end)

describe("unwrapOr", function()
	test("returns the value if the option is Some", function()
		assertEq(Option.Some(5):unwrapOr(10), 5)
	end)

	test("returns the default value if the option is None", function()
		assertEq((Option.None :: Option.Option<number>):unwrapOr(10), 10)
	end)
end)

describe("unwrapOrElse", function()
	test("returns the value if the option is Some", function()
		assertEq(
			Option.Some(5):unwrapOrElse(function()
				return 10
			end),
			5
		)
	end)

	test("returns the default value if the option is None", function()
		assertEq(
			(Option.None :: Option.Option<number>):unwrapOrElse(function()
				return 10
			end),
			10
		)
	end)
end)

describe("map", function()
	test("returns None if the option is None", function()
		assertEq(
			Option.None:map(function(value: number)
				return value + 1
			end),
			Option.None
		)
	end)

	test("returns Some if the option is Some", function()
		assertEq(
			Option.Some(5):map(function(value: number)
				return value + 1
			end),
			Option.Some(6)
		)
	end)
end)

describe("mapOr", function()
	test("returns the default value if the option is None", function()
		assertEq(
			Option.None:mapOr(10, function(value: number)
				return value + 1
			end),
			10
		)
	end)

	test("returns the result of the function if the option is Some", function()
		assertEq(
			Option.Some(5):mapOr(10, function(value: number)
				return value + 1
			end),
			6
		)
	end)
end)

describe("mapOrElse", function()
	test("returns the result of the default function if the option is None", function()
		assertEq(
			Option.None:mapOrElse(function()
				return 10
			end, function(value: number)
				return value + 1
			end),
			10
		)
	end)

	test("returns the result of the function if the option is Some", function()
		assertEq(
			Option.Some(5):mapOrElse(function()
				return 10
			end, function(value: number)
				return value + 1
			end),
			6
		)
	end)
end)

describe("andOpt", function()
	test("returns None if the option is None", function()
		assertEq(Option.None:andOpt(Option.Some(5)), Option.None)
	end)

	test("returns None if the other option is None", function()
		assertEq(Option.Some(5):andOpt(Option.None), Option.None)
	end)

	test("returns the other option if both options are Some", function()
		assertEq(Option.Some(5):andOpt(Option.Some(10)), Option.Some(10))
	end)
end)

describe("andThen", function()
	test("returns None if the option is None", function()
		assertEq(
			Option.None:andThen(function(value: number)
				return Option.Some(value + 1)
			end),
			Option.None
		)
	end)

	test("returns None if the function returns None", function()
		assertEq(
			Option.Some(5):andThen(function(_)
				return Option.None
			end),
			Option.None
		)
	end)

	test("returns Some if the function returns Some", function()
		assertEq(
			Option.Some(5):andThen(function(value: number)
				return Option.Some(value + 1)
			end),
			Option.Some(6)
		)
	end)
end)

describe("filter", function()
	test("returns None if the option is None", function()
		assertEq(
			Option.None:filter(function(value: number)
				return value > 5
			end),
			Option.None
		)
	end)

	test("returns None if the predicate returns false", function()
		assertEq(
			Option.Some(5):filter(function(value: number)
				return value > 5
			end),
			Option.None
		)
	end)

	test("returns Some if the predicate returns true", function()
		assertEq(
			Option.Some(10):filter(function(value: number)
				return value > 5
			end),
			Option.Some(10)
		)
	end)
end)

describe("orOpt", function()
	test("returns the other option if the option is None", function()
		assertEq((Option.None :: Option.Option<number>):orOpt(Option.Some(5)), Option.Some(5))
	end)

	test("returns the option if the other option is None", function()
		assertEq(Option.Some(5):orOpt(Option.None), Option.Some(5))
	end)

	test("returns the option if both options are Some", function()
		assertEq(Option.Some(5):orOpt(Option.Some(10)), Option.Some(5))
	end)
end)

describe("orElse", function()
	test("returns the result of the function if the option is None", function()
		assertEq(
			(Option.None :: Option.Option<number>):orElse(function()
				return Option.Some(5)
			end),
			Option.Some(5)
		)
	end)

	test("returns the option if the option is Some", function()
		assertEq(
			Option.Some(5):orElse(function()
				return Option.Some(10)
			end),
			Option.Some(5)
		)
	end)
end)

describe("xor", function()
	test("returns None if both options are None", function()
		assertEq(Option.None:xor(Option.None), Option.None)
	end)

	test("returns Some if only one option is None", function()
		assertEq((Option.None :: Option.Option<number>):xor(Option.Some(5)), Option.Some(5))
		assertEq(Option.Some(5):xor(Option.None), Option.Some(5))
	end)

	test("returns None if both options are Some", function()
		assertEq(Option.Some(5):xor(Option.Some(10)), Option.None)
	end)
end)

describe("match", function()
	test("calls the Some and returns the result if the option is Some", function()
		assertEq(
			Option.Some(5):match({
				Some = function(num: number)
					return num * 2
				end,
				None = function()
					return 0
				end,
			}),
			10
		)
	end)

	test("calls the None and returns the result if the option is None", function()
		assertEq(
			Option.None:match({
				Some = function(num: number)
					return num * 2
				end,
				None = function()
					return 0
				end,
			}),
			0
		)
	end)
end)

describe("__tostring", function()
	test("returns a string with the value when Some", function()
		assertEq(tostring(Option.Some(5)), "Option::Some(5)")
	end)

	test("returns a string when None", function()
		assertEq(tostring(Option.None), "Option::None")
	end)
end)

describe("__eq", function()
	local none: Option.Option<number> = Option.None

	test("returns true if both options are None", function()
		assertEq(none == none, true)
	end)

	test("returns false if only one option is None", function()
		assertEq(none == Option.Some(5), false)
		assertEq(Option.Some(5) == none, false)
	end)

	test("returns true if both options are Some and equal", function()
		assertEq(Option.Some(5) == Option.Some(5), true)
	end)

	test("returns false if both options are Some and not equal", function()
		assertEq(Option.Some(5) == Option.Some(10), false)
	end)
end)
