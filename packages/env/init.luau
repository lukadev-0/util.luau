local libs = require("./libs")
local platform = require("./platform")

export type Platform = platform.Platform
export type Libs = libs.Libs
export type TaskLib = libs.TaskLib

local env = {} :: {
	platform: Platform,
	libs: Libs,
}

env.platform = platform.getPlatform()
env.libs = libs(env.platform)

return env
