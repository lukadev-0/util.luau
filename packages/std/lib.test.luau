local assertEq = require("@testing/assertEq")
local describe = require("@testing/describe")
local test = require("@testing/test")

local std = require("./lib")

describe("detectRuntime", function()
	test("detects lune runtime", function()
		assertEq(std.runtime ~= nil, true)

		assert(std.runtime ~= nil, "make Luau typechecker happy")
		assertEq(std.runtime.name, "lune")
	end)
end)

describe("setRuntime", function()
	test("sets the runtime", function()
		local luneRuntime = std.runtime
		assert(luneRuntime ~= nil, "should have runtime")

		local runtime = std.defineRuntime({ name = "test", libs = {} })

		local prevTask = std.task

		std.setRuntime(runtime)
		assertEq(std.runtime, runtime)
		assertEq(std.task, prevTask)
		assertEq(std.task.spawn, runtime.libs.task.spawn)

		std.setRuntime(luneRuntime)
	end)
end)

describe("defineRuntime", function()
	test("fills in missing libraries", function()
		local runtime = std.defineRuntime({ name = "test", libs = {} })

		local success, result = pcall(runtime.libs.task.spawn, function() end)
		assertEq(success, false)
		assertEq(result :: any, "'task.spawn' is not implemented by runtime 'test'")
	end)
end)
