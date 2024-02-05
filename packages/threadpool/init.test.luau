local assertEq = require("@testing/assertEq")
local describe = require("@testing/describe")
local test = require("@testing/test")

local threadpool = require(".")

describe("spawn", function()
	test("executes the functions in a thread", function()
		local count = 0
		local function f(v)
			assertEq(v, 10)
			count += 1
			coroutine.yield()
		end

		for _ = 1, 10 do
			threadpool.spawn(f, 10)
		end

		assertEq(count, 10)
	end)

	test("reuses pooled threads", function()
		local threads: { [thread]: boolean } = {}
		local function f()
			threads[coroutine.running()] = true
			coroutine.yield()
		end

		for _ = 1, 10 do
			threadpool.spawn(f)
		end

		for thread in pairs(threads) do
			coroutine.resume(thread)
		end

		local function check()
			assertEq(threads[coroutine.running()], true)
		end

		for _ = 1, 10 do
			threadpool.spawn(check)
		end
	end)
end)
