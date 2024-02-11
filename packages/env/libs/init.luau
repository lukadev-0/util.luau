local platform = require("../platform")
local taskLib = require("./task")

export type TaskLib = taskLib.TaskLib

export type Libs = {
	task: TaskLib,
}

local function getLib<T>(libMap: { lune: () -> T, roblox: () -> T, default: () -> T }, plat: platform.Platform): T
	if plat == "lune" then
		return libMap.lune()
	elseif plat == "roblox" then
		return libMap.roblox()
	else
		return libMap.default()
	end
end

local function createLibs(plat: platform.Platform): Libs
	return {
		task = getLib(taskLib, plat),
	}
end

return createLibs
