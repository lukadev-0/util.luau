local libs = require("./libs")
local runtime = require("./runtime")

export type Runtime = runtime.Runtime
export type RuntimeDefinition = runtime.RuntimeDefinition

export type TaskLib = libs.TaskLib

local std = {}

local function detectRuntime(): Runtime?
	if _G.UTIL_TARGET == "roblox" or typeof(script) == "Instance" then
		return require("./default-runtimes/roblox")
	end

	if string.sub(_VERSION, 1, 5):lower() == "lune " then
		return require("./default-runtimes/lune")
	end

	return nil
end

local detectedRuntime = detectRuntime()
std.runtime = detectedRuntime

if detectedRuntime ~= nil then
	std.task = table.clone(detectedRuntime.libs.task)
else
	std.task = libs.defaultImplementation("task", libs.task)
end

function std.setRuntime(runtime: Runtime)
	std.runtime = runtime

	for libName, lib in runtime.libs do
		for k, v in lib :: any do
			std[libName][k] = v
		end
	end
end

std.defineRuntime = runtime.defineRuntime

return std
