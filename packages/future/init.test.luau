local assertEq = require("@testing/assertEq")
local describe = require("@testing/describe")
local test = require("@testing/test")

local task = require("@lune/task")

local Future = require(".")

describe("new", function()
	test("creates a finished future with the given value", function()
		local fut = Future.new(5)
		assertEq(fut._f, true)
		assertEq(fut._v, 5)
	end)
end)

describe("never", function()
	test("creates a pending future", function()
		local fut = Future.never()
		assertEq(fut._f, false)
		assertEq(fut._v, nil)
	end)
end)

describe("spawn", function()
	test("spawns the function and returns the result", function()
		local thread = coroutine.running()
		local spawned

		local fut = Future.spawn(function()
			spawned = coroutine.running()
			coroutine.yield()
			return 5
		end)

		assertEq(fut._f, false)
		assertEq(spawned ~= nil, true)
		assertEq(thread ~= spawned, true)
		task.spawn(spawned)
		assertEq(fut._f, true)
		assertEq(fut._v, 5)
	end)
end)

describe("pending", function()
	test("resolves when the resolve function is callled", function()
		local fut: Future.Future<number?>, resolve = Future.pending()
		assertEq(fut._f, false)
		assertEq(fut._v, nil)

		resolve(5)
		assertEq(fut._f, true)
		assertEq(fut._v, 5)
	end)
end)

describe("fn", function()
	test("creates a function that spawns a future", function()
		local f = Future.fn(function(a: number, b: number)
			return a + b
		end)

		local fut = f(1, 2)
		assertEq(fut._f, true)
		assertEq(fut._v, 3)
	end)
end)

describe("all", function()
	test("creates a future that resolves when all futures have resolved", function()
		local spawned = {}
		local function returnValue(value)
			spawned[value] = coroutine.running()
			coroutine.yield()
			return value
		end

		local futs = {}
		for i = 1, 10 do
			futs[i] = Future.spawn(returnValue, i)
		end

		local fut = Future.all(futs)
		for i = 1, 10 do
			assertEq(fut._f, false)
			task.spawn(spawned[i])

			if i < 10 then
				assertEq(fut._f, false)
			else
				assertEq(fut._f, true)
				for j = 1, 10 do
					assertEq(fut._v[j], j)
				end
			end
		end
	end)
end)

describe("race", function()
	test("resolves with the first future to resolve", function()
		local spawned = {}
		local function returnValue(value)
			spawned[value] = coroutine.running()
			coroutine.yield()
			return value
		end

		local random = math.random(1, 10)
		local futs = {}
		for i = 1, 10 do
			futs[i] = Future.spawn(returnValue, i)
		end

		local fut = Future.race(futs)
		assertEq(fut._f, false)
		task.spawn(spawned[random])
		assertEq(fut._f, true)
		assertEq(fut._v, random)

		for i = 1, 10 do
			if i ~= random then
				task.spawn(spawned[i])
				assertEq(fut._f, true)
				assertEq(fut._v, random)
			end
		end
	end)
end)

describe("isFinished", function()
	test("returns whether a future is finished", function()
		assertEq(Future.new(5):isFinished(), true)
		assertEq(Future.never():isFinished(), false)
	end)
end)

describe("isPending", function()
	test("returns whether a future is pending", function()
		assertEq(Future.new(5):isPending(), false)
		assertEq(Future.never():isPending(), true)
	end)
end)

describe("now", function()
	test("returns Some if the future is finished", function()
		assertEq(Future.new(5):now():unwrap(), 5)
	end)

	test("returns None if the future is pending", function()
		assertEq(Future.never():now():isNone(), true)
	end)
end)

describe("await", function()
	test("returns the value if the future is finished", function()
		assertEq(Future.new(5):await(), 5)
	end)

	test("yields if the future is pending", function()
		local done = false
		local spawned
		task.spawn(function()
			local fut = Future.spawn(function()
				spawned = coroutine.running()
				coroutine.yield()
				return 5
			end)

			assertEq(fut:await(), 5)
			done = true
		end)

		assertEq(done, false)
		task.spawn(spawned)
		assertEq(done, true)
	end)
end)

describe("after", function()
	test("calls the callback immediately if finished", function()
		local done = false
		Future.new(5):after(function(v)
			assertEq(v, 5)
			done = true
		end)

		assertEq(done, true)
	end)

	test("calls the callback once the future is finished", function()
		local done = false
		local spawned

		local fut = Future.spawn(function()
			spawned = coroutine.running()
			coroutine.yield()
			return 5
		end)

		fut:after(function(v)
			assertEq(v, 5)
			done = true
		end)

		assertEq(done, false)
		task.spawn(spawned)
		assertEq(done, true)
	end)
end)
