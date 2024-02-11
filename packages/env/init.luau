local libs = require("./libs")
local platform = require("./platform")

export type Platform = platform.Platform
export type Libs = libs.Libs
export type TaskLib = libs.TaskLib

type LibImplementor<T> = (lib: T) -> ()

local env = {} :: {
	platform: Platform,
	libs: Libs,

	implementTask: LibImplementor<TaskLib>,
}

env.platform = platform.getPlatform()
env.libs = libs.createLibs(env.platform)

local function libImplementor<T>(name: string): LibImplementor<T>
	return function(lib)
		setmetatable(env.libs[name], { __index = lib })
	end
end

env.implementTask = libImplementor("task")

return env
