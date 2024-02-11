local platform = require("../platform")
local taskLib = require("./task")

export type TaskLib = taskLib.TaskLib

type Proxy<T> = typeof(setmetatable({}, { __index = ({} :: any) :: T }))

export type Libs = {
	task: Proxy<TaskLib>,
}

local function createProxy<T>(value: T): Proxy<T>
	return setmetatable({}, { __index = value })
end

local function getLib<T>(libMap: { lune: () -> T, roblox: () -> T, default: () -> T }, plat: platform.Platform): Proxy<T>
	if plat == "lune" then
		return createProxy(libMap.lune())
	elseif plat == "roblox" then
		return createProxy(libMap.roblox())
	else
		return createProxy(libMap.default())
	end
end

local libs = {}

function libs.createLibs(plat: platform.Platform): Libs
	return {
		task = getLib(taskLib, plat),
	}
end

return libs
