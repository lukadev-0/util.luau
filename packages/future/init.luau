local Option = require("../option")
local env = require("../env")
local threadpool = require("../threadpool")

local task = env.libs.task

export type Future<T> = typeof(setmetatable(
	{} :: {
		_f: boolean,
		_v: T,
		_w: { thread },
		_c: { (T) -> () },
	},
	{} :: FutureImpl
))

export type FutureImpl = {
	__index: FutureImpl,

	new: <T>(value: T) -> Future<T>,
	never: () -> Future<any>,
	spawn: <T, U...>(f: (U...) -> T, U...) -> Future<T>,
	pending: <T>() -> (Future<T>, (T) -> ()),
	fn: <T, V...>(f: (V...) -> T) -> (V...) -> Future<T>,

	all: <T>(futures: { Future<T> }) -> Future<{ T }>,
	race: <T>(futures: { Future<T> }) -> Future<T>,

	isFinished: <T>(self: Future<T>) -> boolean,
	isPending: <T>(self: Future<T>) -> boolean,
	now: <T>(self: Future<T>) -> Option.Option<T>,
	await: <T>(self: Future<T>) -> T,
	after: <T>(self: Future<T>, f: (T) -> ()) -> (),
}

--[=[
  @class Future

  A future represents a value that does not exist yet, but will exist at some
  point in the future.

  Futures allow you to more easily compose asynchronous operations.
]=]
local Future = {} :: FutureImpl
Future.__index = Future

--[=[
  Creates a finished future with the given value.
]=]
function Future.new(value)
	local self = setmetatable({ _f = true, _v = value, _w = {}, _c = {} }, Future)
	return self
end

--[=[
  Creates a future that will never finish.
]=]
function Future.never()
	return setmetatable({ _f = false, _w = {}, _c = {} }, Future)
end

local function finish<T>(fut: Future<T>, value: T)
	fut._f = true
	fut._v = value

	for _, thread in fut._w do
		task.spawn(thread, value)
	end

	for _, callback in fut._c do
		callback(value)
	end
end

--[=[
	Creates a future and spawns the given function in a new thread, once the
	function finishes, the future resolves with the result of the function.
]=]
function Future.spawn(f, ...)
	local self = Future.never()

	-- selene: allow(shadowing)
	local function inner(self: Future<any>, f: (...any) -> any, ...)
		finish(self, f(...))
	end
	threadpool.spawn(inner, self, f, ...)

	return self
end

--[=[
	Creates a future that is pending, and returns the future and a function that
	can be used to resolve the future with a value.
]=]
function Future.pending()
	local fut = Future.never()
	return fut, function(value)
		finish(fut, value)
	end
end

--[=[
	Returns a function that, when called, will spawn the given function in a new
	thread and returns a future that resolves with the result of the function.
]=]
function Future.fn(f)
	return function(...)
		return Future.spawn(f, ...)
	end
end

--[=[
	Takes an array of futures and returns a new future that will finish once all
	of the given futures have finished. The future will resolve with an array
	containing the results of the given futures.
]=]
function Future.all(futures)
	-- selene: allow(shadowing)
	local function inner(futures: { Future<any> })
		local result = table.create(#futures)
		for _, fut: any in futures do
			table.insert(result, fut:await())
		end
		return result
	end

	return Future.spawn(inner, futures) :: any
end

--[=[
	Takes an array of futures and returns a new future that will finish once any
	of the given futures have finished. The future will resolve with the result
	of the first future to finish.

	The result of the other futures will be discarded.
]=]
function Future.race(futures)
	local self = Future.never()
	local done = false

	for _, fut: any in futures do
		fut:after(function(val)
			if done then
				return
			end

			done = true
			finish(self, val)
		end)
	end

	return self
end

--[=[
  Returns `true` if the future has finished, `false` otherwise.
]=]
function Future.isFinished(self)
	return self._f
end

--[=[
  Returns `true` if the future is still pending, `false` otherwise.
]=]
function Future.isPending(self)
	return not self._f
end

--[=[
	Returns the value of the future, if it has finished. If the future is still
	pending, the function will return `None`.
]=]
function Future.now(self)
	if self._f then
		return Option.Some(self._v :: any)
	else
		return Option.None
	end
end

--[=[
	Yields the current thread until the future has finished, then returns the
	value of the future.

	If the future has already finished, the function will return immediately.
]=]
function Future.await(self)
	if self._f then
		return self._v
	end

	local thread = coroutine.running()
	table.insert(self._w, thread)
	return coroutine.yield()
end

--[=[
	Calls the given callback once the future has finished. If the future has
	already finished, the callback will be called immediately.
]=]
function Future.after(self, f)
	if self._f then
		f(self._v)
	else
		table.insert(self._c, f)
	end
end

return Future
