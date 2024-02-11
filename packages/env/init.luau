local libs = require("./libs")
local runtime = require("./runtime")

export type Libs = libs.Libs
export type TaskLib = libs.TaskLib

type LibImplementor<T> = (lib: T) -> ()

local env = {} :: {
	runtime: string,
	libs: Libs,

	implementTask: LibImplementor<TaskLib>,
}

env.runtime = runtime.getRuntime()
env.libs = libs.createLibs(env.runtime)

local function libImplementor<T>(name: string): LibImplementor<T>
	return function(lib)
		setmetatable(env.libs[name], { __index = lib })
	end
end

env.implementTask = libImplementor("task")

return env
