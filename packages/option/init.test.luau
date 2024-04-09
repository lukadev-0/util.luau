local assertEq = require("@testing/assertEq")
local describe = require("@testing/describe")
local randomTuple = require("@testing/randomTuple")
local test = require("@testing/test")

local Option = require(".")

describe("Some", function()
	test("returns an option containing the given value", function()
		randomTuple(function(tuple, ...)
			local opt = Option.Some(...)
			tuple.assertEq(unpack(opt :: any))
		end)
	end)

	test("errors if no arguments are given", function()
		local success, err = pcall(Option.Some)
		assertEq(success, false)
		assertEq(err :: any, "Option.Some() called with no arguments")
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
		assertEq(Option.is(Option.Some(5, "hello")), true)
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
		assertEq(Option.Some(5, "hello"):isSome(), true)
	end)

	test("returns false if the option is None", function()
		assertEq(Option.None:isSome(), false)
	end)
end)

describe("isSomeAnd", function()
	test("returns true if the option is Some and the predicate is true", function()
		randomTuple(function(tuple, ...)
			assertEq(
				Option.Some(...):isSomeAnd(function(...)
					tuple.assertEq(...)
					return true
				end),
				true
			)
		end)
	end)

	test("returns false if the option is Some and the predicate is false", function()
		randomTuple(function(tuple, ...)
			assertEq(
				Option.Some(...):isSomeAnd(function(...)
					tuple.assertEq(...)
					return false
				end),
				false
			)
		end)
	end)

	test("returns false if the option is None", function()
		assertEq(
			Option.None:isSomeAnd(function()
				return true
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
		assertEq(Option.Some(5, "hello"):isNone(), false)
	end)
end)

describe("expect", function()
	test("returns the value if the option is Some", function()
		randomTuple(function(tuple, ...)
			tuple.assertEq(Option.Some(...):expect("option should be some"))
		end)
	end)

	test("errors if the option is None", function()
		local success, err = pcall(Option.None.expect, Option.None, "hello")
		assertEq(success, false)
		assertEq(err, "hello")
	end)
end)

describe("unwrap", function()
	test("returns the value if the option is Some", function()
		randomTuple(function(tuple, ...)
			tuple.assertEq(Option.Some(...):unwrap())
		end)
	end)

	test("errors if the option is None", function()
		local success, err = pcall(Option.None.unwrap, Option.None)
		assertEq(success, false)
		assertEq(err, "called `Option.unwrap()` on a `None` value")
	end)
end)

describe("unwrapOr", function()
	test("returns the value if the option is Some", function()
		randomTuple(function(tuple, ...)
			tuple.assertEq(Option.Some(...):unwrapOr(tuple.other()))
		end)
	end)

	test("returns the default value if the option is None", function()
		randomTuple(function(tuple, ...)
			tuple.assertEq(Option.None:unwrapOr(...))
		end)
	end)
end)

describe("unwrapOrElse", function()
	test("returns the value if the option is Some", function()
		randomTuple(function(tuple, ...)
			tuple.assertEq(Option.Some(...):unwrapOrElse(tuple.other))
		end)
	end)

	test("returns the default value if the option is None", function()
		randomTuple(function(tuple)
			tuple.assertEqOther(Option.None:unwrapOrElse(tuple.other))
		end)
	end)
end)

describe("map", function()
	test("returns None if the option is None", function()
		randomTuple(function(tuple)
			assertEq(Option.None:map(tuple.map), Option.None)
		end)
	end)

	test("returns Some if the option is Some", function()
		randomTuple(function(tuple, ...)
			assertEq(Option.Some(...):map(tuple.map), Option.Some(tuple.map(...)))
		end)
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

describe("mapOrRest", function()
	test("returns the default value if the option is None", function()
		randomTuple(function(tuple, ...)
			tuple.assertEq(Option.None:mapOrRest(tuple.map, ...))
		end)
	end)

	test("returns the result of the function if the option is Some", function()
		randomTuple(function(tuple, ...)
			tuple.assertEqMapped(Option.Some(...):mapOrRest(tuple.map, tuple.other()))
		end)
	end)
end)

describe("mapOrElse", function()
	test("returns the result of the default function if the option is None", function()
		randomTuple(function(tuple)
			tuple.assertEqOther(Option.None:mapOrElse(tuple.other, tuple.map))
		end)
	end)

	test("returns the result of the function if the option is Some", function()
		randomTuple(function(tuple, ...)
			tuple.assertEqMapped(Option.Some(...):mapOrElse(tuple.other, tuple.map))
		end)
	end)
end)

describe("andOpt", function()
	test("returns None if the option is None", function()
		randomTuple(function(_, ...)
			assertEq(Option.None:andOpt(Option.Some(...)), Option.None)
		end)
	end)

	test("returns None if the other option is None", function()
		randomTuple(function(_, ...)
			assertEq(Option.Some(...):andOpt(Option.None), Option.None)
		end)
	end)

	test("returns None if both options are none", function()
		assertEq(Option.None:andOpt(Option.None), Option.None)
	end)

	test("returns the other option if both options are Some", function()
		randomTuple(function(tuple, ...)
			assertEq(Option.Some(...):andOpt(Option.Some(tuple.other())), Option.Some(tuple.other()))
		end)
	end)
end)

describe("andThen", function()
	test("returns None if the option is None", function()
		randomTuple(function(tuple)
			assertEq(
				Option.None:andThen(function(...)
					return Option.Some(tuple.map(...))
				end),
				Option.None
			)
		end)
	end)

	test("returns None if the function returns None", function()
		randomTuple(function(_, ...)
			assertEq(
				Option.Some(...):andThen(function()
					return Option.None
				end),
				Option.None
			)
		end)
	end)

	test("returns Some if the function returns Some", function()
		randomTuple(function(tuple, ...)
			assertEq(
				Option.Some(...):andThen(function(...)
					return Option.Some(tuple.map(...))
				end),
				Option.Some(tuple.map(...))
			)
		end)
	end)
end)

describe("filter", function()
	test("returns None if the option is None", function()
		assertEq(
			Option.None:filter(function()
				return true
			end),
			Option.None
		)
	end)

	test("returns None if the predicate returns false", function()
		randomTuple(function(_, ...)
			assertEq(
				Option.Some(...):filter(function()
					return false
				end),
				Option.None
			)
		end)
	end)

	test("returns Some if the predicate returns true", function()
		randomTuple(function(_, ...)
			assertEq(
				Option.Some(...):filter(function()
					return true
				end),
				Option.Some(...)
			)
		end)
	end)
end)

describe("orOpt", function()
	test("returns the other option if the option is None", function()
		randomTuple(function(_, ...)
			assertEq(Option.None:orOpt(Option.Some(...)), Option.Some(...))
		end)
	end)

	test("returns the option if the other option is None", function()
		randomTuple(function(_, ...)
			assertEq(Option.Some(...):orOpt(Option.None), Option.Some(...))
		end)
	end)

	test("returns None if both options are none", function()
		assertEq(Option.None:andOpt(Option.None), Option.None)
	end)

	test("returns the option if both options are Some", function()
		randomTuple(function(tuple, ...)
			assertEq(Option.Some(...):orOpt(Option.Some(tuple.other())), Option.Some(...))
		end)
	end)
end)

describe("orElse", function()
	test("returns the result of the function if the option is None", function()
		randomTuple(function(tuple)
			assertEq(
				(Option.None :: Option.Option<number>):orElse(function()
					return Option.Some(tuple.other())
				end),
				Option.Some(tuple.other())
			)
		end)
	end)

	test("returns the option if the option is Some", function()
		randomTuple(function(tuple, ...)
			assertEq(
				Option.Some(...):orElse(function()
					return Option.Some(tuple)
				end),
				Option.Some(...)
			)
		end)
	end)
end)

describe("xor", function()
	test("returns None if both options are None", function()
		assertEq(Option.None:xor(Option.None), Option.None)
	end)

	test("returns Some if only one option is None", function()
		randomTuple(function(_, ...)
			assertEq(Option.None:xor(Option.Some(...)), Option.Some(...))
			assertEq(Option.Some(...):xor(Option.None), Option.Some(...))
		end)
	end)

	test("returns None if both options are Some", function()
		randomTuple(function(tuple, ...)
			assertEq(Option.Some(...):xor(Option.Some(tuple.other())), Option.None)
		end)
	end)
end)

describe("match", function()
	test("calls the Some and returns the result if the option is Some", function()
		randomTuple(function(tuple, ...)
			tuple.assertEqMapped(Option.Some(...):match({
				Some = tuple.map,
				None = tuple.other,
			}))
		end)
	end)

	test("calls the None and returns the result if the option is None", function()
		randomTuple(function(tuple)
			tuple.assertEqOther(Option.None:match({
				Some = tuple.map,
				None = tuple.other,
			}))
		end)
	end)
end)

describe("__tostring", function()
	test("returns a string with the value when Some", function()
		assertEq(tostring(Option.Some(5)), "Option::Some(5)")
		assertEq(tostring(Option.Some(5, "hello")), 'Option::Some(5, "hello")')
		assertEq(tostring(Option.Some("hello", true, 5, 20)), 'Option::Some("hello", true, 5, 20)')
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
		randomTuple(function(_, ...)
			assertEq(none == Option.Some(...), false)
			assertEq(Option.Some(...) == none, false)
		end)
	end)

	test("returns true if both options are Some and equal", function()
		randomTuple(function(_, ...)
			assertEq(Option.Some(...) == Option.Some(...), true)
		end)
	end)

	test("returns false if both options are Some and not equal", function()
		randomTuple(function(tuple, ...)
			assertEq(Option.Some(...) == Option.Some(tuple.other()), false)

			local a = { ... }
			randomTuple(function(_, ...)
				assertEq(Option.Some(unpack(a)) == Option.Some(...), false)
			end)
		end)
	end)
end)
