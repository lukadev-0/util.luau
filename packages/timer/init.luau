local Future = require("../future")
local std = require("../std")
local threadpool = require("../threadpool")

local task = std.task

local timer = {}

function timer.delay(duration: number): Future.Future<number>
	return Future.spawn(task.wait, duration)
end

function timer.interval<T...>(duration: number, f: (T...) -> (), ...: T...): () -> ()
	local function inner(duration: number, f: (T...) -> (), ...: T...)
		local nextTick = os.clock() + duration
		while true do
			task.wait(nextTick - os.clock())
			threadpool.spawn(f, ...)
			nextTick += duration
		end
	end

	local thread = task.spawn(inner, duration, f, ...)
	return function()
		task.cancel(thread)
	end
end

return timer
