export type TaskLib = {
	cancel: (thread) -> (),
	defer: <T...>(functionOrThread: thread | (T...) -> (), T...) -> thread,
	delay: <T...>(duration: number, functionOrThread: thread | (T...) -> (), T...) -> thread,
	spawn: <T...>(functionOrThread: thread | (T...) -> (), T...) -> thread,
	wait: (duration: number) -> number,
}

local NOT_IMPLEMENTED: any = function()
	error("Unsupported runtime, custom implementations required.", 2)
end

local taskLib = {}

function taskLib.default(): TaskLib
	return table.freeze({
		cancel = NOT_IMPLEMENTED,
		defer = NOT_IMPLEMENTED,
		delay = NOT_IMPLEMENTED,
		spawn = NOT_IMPLEMENTED,
		wait = NOT_IMPLEMENTED,
	})
end

function taskLib.roblox(): TaskLib
	return table.freeze({
		cancel = task.cancel,
		defer = task.defer :: any,
		delay = task.delay :: any,
		spawn = task.spawn :: any,
		wait = task.wait,
	})
end

function taskLib.lune(): TaskLib
	local task = require("@lune/task")
	return table.freeze({
		cancel = task.cancel,
		defer = task.defer,
		delay = task.delay,
		spawn = task.spawn,
		wait = task.wait,
	})
end

return taskLib
