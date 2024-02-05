local threadpool = {}

local task = if _G.TARGET == "lune" then require("@lune/task") :: typeof(task) else task

local freeThreads: { thread } = {}

local function run<T...>(f: (T...) -> (), thread: thread, ...)
	f(...)
	table.insert(freeThreads, thread)
end

local function yielder()
	while true do
		run(coroutine.yield())
	end
end

--[=[
  Executes the given function in a separate thread, threads are pooled and reused.
]=]
function threadpool.spawn<T...>(f: (T...) -> (), ...: T...)
	local thread
	if #freeThreads > 0 then
		thread = freeThreads[#freeThreads]
		freeThreads[#freeThreads] = nil
	else
		thread = coroutine.create(yielder)
		coroutine.resume(thread)
	end

	task.spawn(thread, f, thread, ...)
end

return threadpool
