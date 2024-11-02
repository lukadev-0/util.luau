local stdio = require("@lune/stdio")

local assertEq = require("@testing/assertEq")
local describe = require("@testing/describe")
local test = require("@testing/test")

local Result = require(".")

describe("Ok", function()
	test("returns a result containing the given Ok value", function()
		local result = Result.Ok(5)
		assertEq(result._ok, true)
		assertEq((result :: any)._v, 5)
	end)
end)

describe("Err", function()
	test("returns a result containing the given Err value", function()
		local result = Result.Err("error")
		assertEq(result._ok, false)
		assertEq((result :: any)._e, "error")
	end)
end)

describe("try", function()
	test("returns an Ok value when the function succeeds", function()
		local result = Result.try(function(v)
			return v
		end, 5)

		assertEq(result, Result.Ok(5))
	end)

	test("returns an Err value when the function fails", function()
		local result = Result.try(function()
			error("hello")
		end)

		assertEq(result._ok, false)
		assertEq((result :: any)._e:match("hello"), "hello")
	end)
end)

describe("is", function()
	test("returns true when given a result", function()
		assertEq(Result.is(Result.Ok(5)), true)
		assertEq(Result.is(Result.Err("error")), true)
	end)

	test("returns false when given a non-result", function()
		assertEq(Result.is(5), false)
		assertEq(Result.is("error"), false)
	end)
end)

describe("isOk", function()
	test("returns true when given an Ok result", function()
		assertEq(Result.Ok(5):isOk(), true)
	end)

	test("returns false when given an Err result", function()
		assertEq(Result.Err("error"):isOk(), false)
	end)
end)

describe("isOkAnd", function()
	test("returns true when the option is Ok and the predicate is true", function()
		assertEq(
			Result.Ok(5):isOkAnd(function(v)
				return v == 5
			end),
			true
		)
	end)

	test("returns false when the option is Ok and the predicate is false", function()
		assertEq(
			Result.Ok(5):isOkAnd(function(v)
				return v == 10
			end),
			false
		)
	end)

	test("returns false when the option is Err", function()
		assertEq(
			Result.Err("error"):isOkAnd(function(v)
				return v == 5
			end),
			false
		)
	end)
end)

describe("isErr", function()
	test("returns true when given an `Err` result", function()
		assertEq(Result.Err("error"):isErr(), true)
	end)

	test("returns false when given an `Ok` result", function()
		assertEq(Result.Ok(5):isErr(), false)
	end)
end)

describe("isErrAnd", function()
	test("returns true when the option is Err and the predicate is true", function()
		assertEq(
			Result.Err("error"):isErrAnd(function(e)
				return e == "error"
			end),
			true
		)
	end)

	test("returns false when the option is Err and the predicate is false", function()
		assertEq(
			Result.Err("error"):isErrAnd(function(e)
				return e == "hello"
			end),
			false
		)
	end)

	test("returns false when the option is Ok", function()
		assertEq(
			Result.Ok(5):isErrAnd(function(e)
				return e == "error"
			end),
			false
		)
	end)
end)

describe("map", function()
	test("returns Err when the result is Err", function()
		local result = Result.Err("error"):map(function(v: number)
			return v * 2
		end)

		assertEq(result, Result.Err("error"))
	end)

	test("returns Ok when the result is Ok", function()
		local result = Result.Ok(5):map(function(v: number)
			return v * 2
		end)

		assertEq(result, Result.Ok(10))
	end)
end)

describe("mapOr", function()
	test("returns the default value when the result is Err", function()
		local result = Result.Err("error"):mapOr(5, function(v: number)
			return v * 2
		end)

		assertEq(result, 5)
	end)

	test("returns the mapped value when the result is Ok", function()
		local result = Result.Ok(5):mapOr(5, function(v: number)
			return v * 2
		end)

		assertEq(result, 10)
	end)
end)

describe("mapOrElse", function()
	test("returns the default value when the result is Err", function()
		local result = Result.Err("error"):mapOrElse(function(e: string)
			return e:upper() :: number | string
		end, function(v: number)
			return v * 2
		end)

		assertEq(result, "ERROR")
	end)

	test("returns the mapped value when the result is Ok", function()
		local result = Result.Ok(5):mapOrElse(function(e: string)
			return e:upper() :: number | string
		end, function(v: number)
			return v * 2
		end)

		assertEq(result, 10)
	end)
end)

describe("mapErr", function()
	test("returns Ok when the result is Ok", function()
		local result = Result.Ok(5):mapErr(function(e: string)
			return e:upper()
		end)

		assertEq(result, Result.Ok(5))
	end)

	test("returns the mapped Err when the result is Err", function()
		local result = Result.Err("error"):mapErr(function(e: string)
			return e:upper()
		end)

		assertEq(result, Result.Err("ERROR"))
	end)
end)

describe("expect", function()
	test("returns the value when the result is Ok", function()
		local result = Result.Ok(5):expect("error")

		assertEq(result, 5)
	end)

	test("throws an error when the result is Err", function()
		local ok, err = pcall(function()
			Result.Err("error"):expect("error")
		end)

		assertEq(ok, false)
		assertEq(err:match("error"), "error")
	end)
end)

describe("unwrap", function()
	test("returns the value when the result is Ok", function()
		local result = Result.Ok(5):unwrap()

		assertEq(result, 5)
	end)

	test("throws an error when the result is Err", function()
		local ok, err = pcall(function()
			Result.Err("error"):unwrap()
		end)

		assertEq(ok, false)
		assertEq(err:match("error"), "error")
	end)
end)

describe("expectErr", function()
	test("returns the error when the result is Err", function()
		local result = Result.Err("error"):expectErr("error")

		assertEq(result, "error")
	end)

	test("throws an error when the result is Ok", function()
		local ok, err = pcall(function()
			Result.Ok(5):expectErr("error")
		end)

		assertEq(ok, false)
		assertEq(err:match("error"), "error")
	end)
end)

describe("unwrapErr", function()
	test("returns the error when the result is Err", function()
		local result = Result.Err("error"):unwrapErr()

		assertEq(result, "error")
	end)

	test("throws an error when the result is Ok", function()
		local ok, err = pcall(function()
			Result.Ok(5):unwrapErr()
		end)

		assertEq(ok, false)
		assertEq(err:match("5"), "5")
	end)
end)

describe("andRes", function()
	test("returns the other result when the result is Ok", function()
		local resultA = Result.Ok(5):andRes(Result.Ok(10))
		assertEq(resultA, Result.Ok(10))

		local resultB = Result.Ok(5):andRes(Result.Err("error"))
		assertEq(resultB, Result.Err("error"))
	end)

	test("returns the Err when the result is Err", function()
		local result = Result.Err("error"):andRes(Result.Ok(10))
		assertEq(result, Result.Err("error"))
	end)
end)

describe("andThen", function()
	test("returns the other result when the result is Ok", function()
		local resultA = Result.Ok(5):andThen(function(v: number)
			return Result.Ok(v * 2)
		end)
		assertEq(resultA, Result.Ok(10))

		local resultB = Result.Ok(5):andThen(function(v: number)
			return Result.Err(v)
		end)
		assertEq(resultB, Result.Err(5))
	end)

	test("returns the Err when the result is Err", function()
		local result = Result.Err("error"):andThen(function(v: number)
			return Result.Ok(v * 2)
		end)
		assertEq(result, Result.Err("error"))
	end)
end)

describe("orRes", function()
	test("returns the Ok when the result is Ok", function()
		local result = Result.Ok(5):orRes(Result.Ok(10))
		assertEq(result, Result.Ok(5))
	end)

	test("returns the other result when the result is Err", function()
		local resultA = Result.Err("error"):orRes(Result.Ok(10))
		assertEq(resultA, Result.Ok(10))

		local resultB = Result.Err("error"):orRes(Result.Err(10))
		assertEq(resultB, Result.Err(10))
	end)
end)

describe("orElse", function()
	test("returns the Ok when the result is Ok", function()
		local result = Result.Ok(5):orElse(function(e: string)
			return Result.Err(e:upper())
		end)
		assertEq(result, Result.Ok(5))
	end)

	test("returns the other result when the result is Err", function()
		local resultA = Result.Err("error"):orElse(function(e: string)
			return Result.Err(e:upper())
		end)
		assertEq(resultA, Result.Err("ERROR"))

		local resultB = Result.Err("error"):orElse(function(e: string)
			return Result.Err(e:upper())
		end)
		assertEq(resultB, Result.Err("ERROR"))
	end)
end)

describe("unwrapOr", function()
	test("returns the value when the result is Ok", function()
		local result = Result.Ok(5):unwrapOr(10)
		assertEq(result, 5)
	end)

	test("returns the default value when the result is Err", function()
		local result = Result.Err("error"):unwrapOr(10)
		assertEq(result, 10)
	end)
end)

describe("unwrapOrElse", function()
	test("returns the value when the result is Ok", function()
		local result = Result.Ok(5):unwrapOrElse(function()
			return 10
		end)
		assertEq(result, 5)
	end)

	test("returns the default value when the result is Err", function()
		local result = Result.Err("error"):unwrapOrElse(function(e: string)
			return e:upper()
		end)
		assertEq(result, "ERROR")
	end)
end)

describe("match", function()
	test("returns the result of the Ok function when the result is Ok", function()
		local result: string | number = Result.Ok(5):match({
			Ok = function(v: number)
				return v * 2
			end,
			Err = function(e)
				return e:upper()
			end,
		})

		assertEq(result, 10)
	end)

	test("returns the result of the Err function when the result is Err", function()
		local result = Result.Err("error"):match({
			Ok = function(v: number)
				return (v * 2) :: string | number
			end,
			Err = function(e: string)
				return e:upper()
			end,
		})

		assertEq(result, "ERROR")
	end)
end)

describe("unpack", function()
	test("returns the value when the result is Ok", function()
		local value, error = Result.Ok(5):unpack()
		assertEq(value, 5)
		assertEq(error, nil)
	end)

	test("returns the error when the result is Err", function()
		local value, error = Result.Err("error"):unpack()
		assertEq(value, nil)
		assertEq(error, "error")
	end)
end)

describe("__tostring", function()
	test("returns a string with the value when Ok", function()
		assertEq(tostring(Result.Ok(5)), "Result::Ok(5)")
		assertEq(tostring(Result.Ok({ a = 5 })), `Result::Ok({stdio.format({ a = 5 })})`)
	end)

	test("returns a string with the error when Err", function()
		assertEq(tostring(Result.Err("error")), 'Result::Err("error")')
		assertEq(tostring(Result.Err({ a = 5 })), `Result::Err({stdio.format({ a = 5 })})`)
	end)
end)

describe("__eq", function()
	test("returns true when both results are Ok and have the same value", function()
		assertEq(Result.Ok(5) == Result.Ok(5), true)
	end)

	test("returns false when both results are Ok and have different values", function()
		assertEq(Result.Ok(5) == Result.Ok(10), false)
	end)

	test("returns true when both results are Err and have the same error", function()
		assertEq(Result.Err("error") == Result.Err("error"), true)
	end)

	test("returns false when both results are Err and have different errors", function()
		assertEq(Result.Err("error") == Result.Err("hello"), false)
	end)

	test("returns false when the results are different", function()
		local resultA: Result.Result<number, string> = Result.Ok(5)
		local resultB: Result.Result<number, string> = Result.Err("error")
		assertEq(resultA == resultB, false)
	end)
end)
